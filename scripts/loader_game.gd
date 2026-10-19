extends "res://scripts/main.gd"

const Hauler = preload("res://scripts/hauler_vehicle.gd")
const LoaderYard = preload("res://scripts/loader_yard.gd")
const HaulerModel = preload("res://scripts/hauler_model.gd")
const LOADER_START := Vector3(-6,0,3)
const SCOOP_SPOT := Vector3(-7,0,-.1)
const LOAD_SPOT := Vector3(-3.35,0,-.2)
const DUMP_SPOT := Vector3(7,0,-5.5)
var loader
var truck
var yard
var bucket_full := false
var truck_load := 0
var deliveries := 0
var intent := ""
var animation := ""
var animation_time := 0.0
var transferred := false
var stream: Node3D
var capture_cycle := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	yard = LoaderYard.new()
	yard.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(yard)
	loader = _make_vehicle("loader",LOADER_START)
	truck = _make_vehicle("truck",LoaderYard.TRUCK)
	vehicle = loader
	loader.active = true
	camera = CameraRig.new()
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Hud.new()
	hud.vehicle = vehicle
	hud.loader_mode = true
	canvas.add_child(hud)
	hud.action_requested.connect(_action)
	hud.direction_changed.connect(func(direction: Vector2): vehicle.touch_direction = direction)
	hud.pause_requested.connect(toggle_pause)
	hud.reset_requested.connect(reset_yard)
	hud.mute_requested.connect(toggle_mute)
	hud.menu_requested.connect(func(): menu_requested.emit())
	stream = HaulerModel.dirt_clumps(self,Vector3.ZERO,Vector3(.22,.7,.22),8)
	stream.process_mode = Node.PROCESS_MODE_PAUSABLE
	stream.visible = false
	_setup_audio()
	_update_hud()
	capture_cycle = "--capture-cycle" in OS.get_cmdline_user_args()
	if "--loader-test" in OS.get_cmdline_user_args():
		var runner = load("res://tests/loader_test.gd").new()
		runner.game = self
		add_child(runner)
	if "--capture" in OS.get_cmdline_user_args(): _capture_loader()

func _make_vehicle(kind: String, at: Vector3):
	var machine := Hauler.new()
	machine.name = "Loader" if kind == "loader" else "DumpTruck"
	machine.kind = kind
	machine.position = at
	machine.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(machine)
	machine.action_requested.connect(_action)
	machine.arrived.connect(_arrived)
	machine.manual_takeover.connect(func(): intent = "")
	return machine

func _process(_delta: float) -> void:
	if hud == null: return
	_update_hud()
	if engine_audio: engine_audio.volume_db = -80 if muted or not vehicle.moving else -38

func _physics_process(delta: float) -> void:
	if get_tree().paused or animation.is_empty(): return
	animation_time += delta
	var t := clampf(animation_time/2.1,0,1)
	match animation:
		"scoop":
			loader.model.set_lift(smoothstep(.25,1,t)*.85)
			if t>.3 and not transferred:
				transferred = true
				bucket_full = true
				loader.loaded = true
				loader.model.set_load(1)
				_play_sound("scoop")
		"load":
			loader.model.set_lift(.85+sin(t*PI)*.15,sin(t*PI)*.85)
			_stream_between(loader.model.bucket.global_position,truck.model.cargo.global_position,t)
			if t>.5 and not transferred:
				transferred = true
				bucket_full = false
				loader.loaded = false
				truck_load += 1
				loader.model.set_load(0)
				truck.model.set_load(truck_load/3.0)
				_play_sound("plop")
		"dump":
			truck.model.bed.rotation.x = sin(t*PI)*1.0
			_stream_between(truck.model.bed.to_global(Vector3(0,.45,.3)),LoaderYard.DUMP+Vector3(0,.3,1),t)
			if t>.5 and not transferred:
				transferred = true
				truck_load = 0
				truck.model.set_load(0)
				deliveries += 1
				stars = mini(deliveries,3)
				hud.stars = stars
				yard.show_deliveries(deliveries)
				_play_sound("star")
	if t>=1: _finish_animation()

func _stream_between(from: Vector3, to: Vector3, t: float) -> void:
	stream.visible = t>.22 and t<.8
	var fall := fmod(t*5,1.0)
	stream.global_position = from.lerp(to,fall)
	stream.global_position.y += sin(fall*PI)*.3

func _action() -> void:
	if vehicle.busy or get_tree().paused: return
	if vehicle == loader:
		if bucket_full: load_truck()
		else: scoop_dirt()
	elif truck_load == 3: drive_to_dump()
	else: return_truck()

func scoop_dirt() -> void:
	if vehicle != loader or vehicle.busy or bucket_full: return
	intent = "scoop"
	loader.model.set_lift(0)
	_navigate(loader,[SCOOP_SPOT] if _distance(loader.position,SCOOP_SPOT)<1.25 else [Vector3(-6,0,3),Vector3(-7,0,2),SCOOP_SPOT],0)

func load_truck() -> void:
	if vehicle != loader or vehicle.busy or not bucket_full or truck_load>=3: return
	intent = "load"
	_navigate(loader,[LOAD_SPOT] if _distance(loader.position,LOAD_SPOT)<1.25 else [Vector3(-6,0,3),Vector3(-3.35,0,3),LOAD_SPOT],-PI/2)

func drive_to_dump() -> void:
	if vehicle != truck or vehicle.busy or truck_load != 3: return
	intent = "dump"
	if _distance(truck.position,DUMP_SPOT)<1.25:
		_navigate(truck,[DUMP_SPOT],0)
	else:
		_navigate(truck,[Vector3(3.6,0,2.8),Vector3(7,0,2.8),DUMP_SPOT],0)

func return_truck() -> void:
	if vehicle != truck or vehicle.busy or truck_load != 0: return
	intent = "return"
	_navigate(truck,[Vector3(7,0,2.8),Vector3(0,0,2.8),LoaderYard.TRUCK],0)

func _navigate(machine, points: Array, yaw: float) -> void:
	# If free driving left us across the parked vehicle, go around its outside
	# and use the broad entrance lane before joining the normal approach.
	var other = truck if machine == loader else loader
	var start := Vector2(machine.position.x,machine.position.z)
	var first := Vector2(points[0].x,points[0].z)
	var obstacle := Vector2(other.position.x,other.position.z)
	var segment := first-start
	if segment.length_squared()>.01:
		var along := clampf((obstacle-start).dot(segment)/segment.length_squared(),0,1)
		if (start+segment*along).distance_to(obstacle)<3.8:
			var side := -1.0 if start.x<obstacle.x else 1.0
			var outside := clampf(obstacle.x+side*5.7,-9,9)
			points = [Vector3(outside,0,start.y),Vector3(outside,0,4.8),Vector3(first.x,0,4.8)]+points
	machine.navigate(points,yaw)

func _arrived() -> void:
	var job := intent
	intent = ""
	if job == "return":
		_switch_vehicle(loader)
		loader.model.set_lift(0)
		hud.celebrate("Ready for more dirt!")
	elif job in ["scoop","load","dump"]:
		animation = job
		animation_time = 0
		transferred = false
		vehicle.busy = true

func _finish_animation() -> void:
	var finished := animation
	animation = ""
	vehicle.busy = false
	stream.visible = false
	if finished == "load":
		loader.model.set_lift(.85)
		if truck_load == 3:
			_switch_vehicle(truck)
			hud.celebrate("Truck full! Let's go!")
		else: hud.celebrate("A bucketful of dirt!")
	elif finished == "dump":
		truck.model.bed.rotation.x = 0
		hud.celebrate("Hooray! You delivered!")

func _switch_vehicle(next) -> void:
	hud.release_buttons()
	vehicle.cancel_movement()
	vehicle.active = false
	vehicle = next
	vehicle.active = true
	hud.vehicle = vehicle

func pointer_action(screen_position: Vector2) -> void:
	if vehicle.busy: return
	if vehicle == loader:
		if _near_screen(LoaderYard.DIRT+Vector3(0,.8,0),screen_position,90):
			scoop_dirt()
			return
		if _near_screen(truck.position+Vector3(0,1.4,.5),screen_position,100):
			load_truck()
			return
	else:
		if truck_load == 3 and (_near_screen(LoaderYard.DUMP+Vector3(0,2.35,.6),screen_position,85) or _near_screen(LoaderYard.DUMP,screen_position,90)):
			drive_to_dump()
			return
		if truck_load == 0 and _near_screen(LoaderYard.TRUCK,screen_position,100):
			return_truck()
			return
	var hit: Variant = Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(screen_position),camera.project_ray_normal(screen_position))
	if hit != null and absf(hit.x)<12 and absf(hit.z)<8.5:
		intent = ""
		vehicle.go_to(hit)

func _near_screen(point: Vector3, screen: Vector2, radius: float) -> bool:
	return camera.unproject_position(point).distance_to(screen)<radius

func _distance(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()

func _update_hud() -> void:
	hud.load_count = truck_load
	hud.hauler_title = "little loader" if vehicle == loader else "little truck"
	if vehicle == loader:
		hud.hauler_action = "LOAD" if bucket_full else "SCOOP"
		hud.hauler_hint = "Tap the truck to load the dirt." if bucket_full else "Tap the dirt pile to scoop."
		hud.hauler_icon = "drop" if bucket_full else "scoop"
	elif truck_load == 3:
		hud.hauler_action = "DUMP"
		hud.hauler_hint = "Drive the truck. Tap the star to dump!"
		hud.hauler_icon = "truck"
	else:
		hud.hauler_action = "RETURN"
		hud.hauler_hint = "Tap the loading pad for another load."
		hud.hauler_icon = "reset"

func _notification(what: int) -> void:
	# An automated render may lose focus while the test runner is working.
	if capture_cycle: return
	super._notification(what)

func toggle_pause() -> void:
	intent = ""
	super.toggle_pause()

func reset_yard() -> void:
	intent = ""
	animation = ""
	animation_time = 0
	bucket_full = false
	truck_load = 0
	deliveries = 0
	loader.reset_vehicle()
	truck.reset_vehicle()
	loader.position = LOADER_START
	truck.position = LoaderYard.TRUCK
	_switch_vehicle(loader)
	yard.show_deliveries(0)
	stream.visible = false
	super.reset_yard()
	_update_hud()

func _capture_loader() -> void:
	await get_tree().create_timer(2).timeout
	await _save_capture("loader")
	if capture_cycle:
		for i in 3:
			_action()
			await _capture_wait_idle()
			if i == 0: await _save_capture("loader-scooped")
			_action()
			if i == 0:
				if not await _capture_wait_animation("load"): return
				await get_tree().create_timer(1.1).timeout
				await _save_capture("loader-loading")
			await _capture_wait_idle()
		await _save_capture("loader-full-truck")
		_action()
		if not await _capture_wait_animation("dump"): return
		await get_tree().create_timer(.9).timeout
		await _save_capture("loader-tipping")
		await _capture_wait_idle()
		await _save_capture("loader-delivered")
	_shutdown_audio()
	get_tree().quit()

func _capture_wait_idle() -> void:
	for i in 3000:
		if not vehicle.navigating and animation.is_empty(): return
		await get_tree().physics_frame
	push_error("Capture timed out during hauling")
	get_tree().quit(1)

func _capture_wait_animation(job: String) -> bool:
	for i in 3000:
		if animation == job: return true
		await get_tree().physics_frame
	push_error("Capture timed out waiting for "+job)
	get_tree().quit(1)
	return false

func _save_capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://screenshots/"+label+".png")
