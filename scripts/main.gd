extends Node3D

signal menu_requested

const Vehicle = preload("res://scripts/excavator.gd")
const Rock = preload("res://scripts/boulder.gd")
const Yard = preload("res://scripts/yard.gd")
const CameraRig = preload("res://scripts/orbit_camera.gd")
const Hud = preload("res://scripts/hud.gd")
const Play = preload("res://scripts/playground.gd")
var vehicle
var camera: Camera3D
var hud
var sound: AudioStreamPlayer
var engine_audio: AudioStreamPlayer
var muted := false
var stars := 0
var reset_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	var yard := Yard.new()
	yard.name = "ConstructionSite"
	yard.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(yard)
	vehicle = Vehicle.new()
	vehicle.name = "Digger"
	vehicle.position = Play.START
	vehicle.rotation.y = -.48
	vehicle.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(vehicle)
	for i in 3:
		var rock := Rock.new()
		rock.name = "Pebble%d"%(i+1)
		rock.position = Play.SPAWNS[i]
		rock.rock_id = i
		rock.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(rock)
	camera = CameraRig.new()
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Hud.new()
	hud.vehicle = vehicle
	canvas.add_child(hud)
	hud.action_requested.connect(vehicle.action)
	hud.direction_changed.connect(func(direction: Vector2): vehicle.touch_direction = direction)
	hud.pause_requested.connect(toggle_pause)
	hud.reset_requested.connect(reset_yard)
	hud.mute_requested.connect(toggle_mute)
	hud.menu_requested.connect(func(): menu_requested.emit())
	vehicle.scooped.connect(func(): _play_sound("scoop"))
	vehicle.dropped.connect(func(): _play_sound("plop"))
	_setup_audio()
	if "--smoke-test" in OS.get_cmdline_user_args():
		var runner := preload("res://tests/gameplay_test.gd").new()
		runner.game = self
		add_child(runner)
	if "--capture" in OS.get_cmdline_user_args() or "--capture-loaded" in OS.get_cmdline_user_args():
		_capture_preview()

func _register_inputs() -> void:
	var bindings := {"up":[KEY_UP,KEY_W],"down":[KEY_DOWN,KEY_S],"left":[KEY_LEFT,KEY_A],"right":[KEY_RIGHT,KEY_D],"scoop":[KEY_SPACE],"pause":[KEY_ESCAPE],"reset":[KEY_R],"mute":[KEY_M]}
	for action in bindings:
		if InputMap.has_action(action): InputMap.erase_action(action)
		InputMap.add_action(action)
		for code in bindings[action]:
			var key := InputEventKey.new()
			key.physical_keycode = code
			InputMap.action_add_event(action,key)

func _process(_delta: float) -> void:
	if hud == null or get_tree().paused: return
	for rock in get_tree().get_nodes_in_group("boulders"):
		if rock.settled_in_garden and not rock.rewarded:
			rock.rewarded = true
			stars += 1
			hud.stars = stars
			hud.celebrate("Hooray!" if stars == 3 else "Lovely!")
			_play_sound("star")
	if engine_audio:
		engine_audio.volume_db = -80 if muted or not vehicle.moving else -38

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reset"):
		reset_yard()
	elif event.is_action_pressed("mute"):
		toggle_mute()

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_action(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		pointer_action(event.position)
		get_viewport().set_input_as_handled()

func pointer_action(screen_position: Vector2) -> void:
	if vehicle.busy: return
	# Generous screen-space hit targets, including the floating star itself.
	if vehicle.held == null:
		var closest
		var distance := 58.0
		for rock in get_tree().get_nodes_in_group("boulders"):
			if rock.carried: continue
			var d: float = camera.unproject_position(rock.global_position).distance_to(screen_position)
			if d<distance:
				distance = d
				closest = rock
		if closest != null:
			vehicle.collect(closest)
			return
	var hit: Variant = Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(screen_position),camera.project_ray_normal(screen_position))
	if hit == null: return
	var point: Vector3 = hit
	var goal_screen := camera.unproject_position(Play.DROP_CENTER+Vector3(0,2.35,-.3))
	var on_garden := Vector2(point.x-Play.DROP_CENTER.x,point.z-Play.DROP_CENTER.z).length()<Play.DROP_RADIUS
	if vehicle.held != null and (on_garden or goal_screen.distance_to(screen_position)<72):
		# Give each pebble a comfy spot; no precision dropping or pile balancing.
		var offset := [Vector3(-1.0,0,0),Vector3(.9,0,-.9),Vector3(.8,0,1.0)][vehicle.held.rock_id] as Vector3
		vehicle.drop_at(Play.DROP_CENTER+offset)
	elif absf(point.x)<12 and absf(point.z)<8.5:
		vehicle.go_to(point)

func toggle_pause() -> void:
	hud.release_buttons()
	vehicle.cancel_movement()
	get_tree().paused = not get_tree().paused
	if engine_audio: engine_audio.stream_paused = get_tree().paused
	if sound: sound.stream_paused = get_tree().paused

func reset_yard() -> void:
	reset_count += 1
	get_tree().paused = false
	hud.release_buttons()
	vehicle.reset_vehicle()
	for rock in get_tree().get_nodes_in_group("boulders"): rock.reset_rock()
	stars = 0
	hud.stars = 0
	hud.celebration_time = 0
	if engine_audio: engine_audio.stream_paused = false
	if sound:
		sound.stop()
		sound.stream_paused = false

func toggle_mute() -> void:
	muted = not muted
	hud.muted = muted
	if sound: sound.volume_db = -80 if muted else -16

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud):
		hud.release_buttons()
		vehicle.cancel_movement()

func _setup_audio() -> void:
	if DisplayServer.get_name() == "headless": return
	sound = AudioStreamPlayer.new()
	sound.volume_db = -16
	add_child(sound)
	engine_audio = AudioStreamPlayer.new()
	engine_audio.stream = load("res://assets/audio/diesel.wav")
	engine_audio.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	engine_audio.stream.loop_end = int(engine_audio.stream.get_length()*engine_audio.stream.mix_rate)
	engine_audio.pitch_scale = 1.3
	engine_audio.volume_db = -80
	add_child(engine_audio)
	engine_audio.play()

func _play_sound(which: String) -> void:
	if sound == null or muted: return
	sound.stream = load("res://assets/audio/"+which+".wav")
	sound.play()

func _capture_preview() -> void:
	await get_tree().create_timer(2.0).timeout
	var path := "res://screenshots/yard.png"
	if "--capture-loaded" in OS.get_cmdline_user_args():
		vehicle.collect(get_node("Pebble1"))
		await get_tree().create_timer(6.0).timeout
		path = "res://screenshots/carrying.png"
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("Preview saved: ",path)
	_shutdown_audio()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()

func _exit_tree() -> void:
	_shutdown_audio()

func _shutdown_audio() -> void:
	if engine_audio:
		engine_audio.stop()
		engine_audio.stream = null
	if sound:
		sound.stop()
		sound.stream = null
