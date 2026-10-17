extends "res://scripts/main.gd"

const Dozer = preload("res://scripts/bulldozer.gd")
const PushRock = preload("res://scripts/push_boulder.gd")
const DozerYard = preload("res://scripts/dozer_yard.gd")
const Layout = preload("res://scripts/dozer_layout.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	var yard := DozerYard.new()
	yard.name = "ConstructionSite"
	yard.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(yard)
	vehicle = Dozer.new()
	vehicle.name = "Bulldozer"
	vehicle.position = Layout.START
	vehicle.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(vehicle)
	for i in 3:
		var rock := PushRock.new()
		rock.name = "Pebble%d"%(i+1)
		rock.position = Layout.SPAWNS[i]
		rock.rock_id = i
		rock.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(rock)
	camera = CameraRig.new()
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Hud.new()
	hud.vehicle = vehicle
	hud.bulldozer_mode = true
	canvas.add_child(hud)
	hud.action_requested.connect(vehicle.action)
	hud.direction_changed.connect(func(direction: Vector2): vehicle.touch_direction = direction)
	hud.pause_requested.connect(toggle_pause)
	hud.reset_requested.connect(reset_yard)
	hud.mute_requested.connect(toggle_mute)
	hud.menu_requested.connect(func(): menu_requested.emit())
	_setup_audio()
	if "--bulldozer-test" in OS.get_cmdline_user_args():
		var runner = load("res://tests/bulldozer_test.gd").new()
		runner.game = self
		add_child(runner)
	if "--capture" in OS.get_cmdline_user_args(): _capture_dozer()

func _process(_delta: float) -> void:
	if hud == null or get_tree().paused: return
	for rock in get_tree().get_nodes_in_group("boulders"):
		if rock.completed and not rock.rewarded:
			rock.rewarded = true
			stars += 1
			hud.stars = stars
			hud.celebrate("Hooray!" if stars == 3 else "You filled a hole!")
			_play_sound("star")
	if engine_audio: engine_audio.volume_db = -80 if muted or not vehicle.moving else -38

func pointer_action(screen_position: Vector2) -> void:
	var nearest
	var distance := 62.0
	for rock in get_tree().get_nodes_in_group("boulders"):
		if rock.completed: continue
		var d := camera.unproject_position(rock.global_position).distance_to(screen_position)
		if d<distance:
			distance = d
			nearest = rock
	if nearest:
		vehicle.push_rock(nearest)
		return
	var hit: Variant = Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(screen_position),camera.project_ray_normal(screen_position))
	if hit != null and absf(hit.x)<12 and absf(hit.z)<8.5: vehicle.go_to(hit)

func reset_yard() -> void:
	for hole in get_tree().get_nodes_in_group("holes"): hole.reset_hole()
	super.reset_yard()

func _capture_dozer() -> void:
	await get_tree().create_timer(2).timeout
	if "--capture-filled" in OS.get_cmdline_user_args():
		vehicle.action()
		await get_tree().create_timer(8).timeout
	await RenderingServer.frame_post_draw
	var path := "res://screenshots/bulldozer-filled.png" if "--capture-filled" in OS.get_cmdline_user_args() else "res://screenshots/bulldozer.png"
	get_viewport().get_texture().get_image().save_png(path)
	_shutdown_audio()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()
