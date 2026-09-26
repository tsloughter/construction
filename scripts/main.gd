extends Node3D

const Vehicle = preload("res://scripts/excavator.gd")
const Rock = preload("res://scripts/boulder.gd")
const Yard = preload("res://scripts/yard.gd")
const CameraRig = preload("res://scripts/orbit_camera.gd")
const Hud = preload("res://scripts/hud.gd")

var vehicle
var camera
var hud
var engine_audio: AudioStreamPlayer
var hydraulics_audio: AudioStreamPlayer
var muted := false
var delivered_count := 0
var reset_count := 0

func _ready() -> void:
	_register_inputs()
	var yard := Yard.new()
	yard.name = "QuarryYard"
	add_child(yard)
	vehicle = Vehicle.new()
	vehicle.name = "Excavator"
	add_child(vehicle)
	var spawns := [Vector3(.35,.8,-5.0),Vector3(-3,.9,-10),Vector3(1,.9,-15)]
	for i in spawns.size():
		var rock := Rock.new()
		rock.name = "Boulder%d"%(i+1)
		rock.position = spawns[i]
		rock.rock_id = i
		rock.size_factor = [1.0,.9,1.05][i]
		add_child(rock)
	camera = CameraRig.new()
	camera.name = "OrbitCamera"
	camera.target = vehicle
	add_child(camera)
	var canvas := CanvasLayer.new()
	canvas.name = "Interface"
	add_child(canvas)
	hud = Hud.new()
	hud.vehicle = vehicle
	hud.game = self
	canvas.add_child(hud)
	vehicle.interaction.connect(hud.toast)
	hud.reset_requested.connect(reset_yard)
	hud.pause_requested.connect(toggle_pause)
	_setup_audio()
	# A deterministic physics integration test, exercised by the test launcher.
	if "--smoke-test" in OS.get_cmdline_user_args():
		var runner := preload("res://tests/gameplay_test.gd").new()
		runner.game = self
		add_child(runner)
	if "--capture" in OS.get_cmdline_user_args():
		_capture_preview()

func _register_inputs() -> void:
	var bindings := {
		"forward":KEY_W,"reverse":KEY_S,"steer_left":KEY_A,"steer_right":KEY_D,
		"slew_left":KEY_Q,"slew_right":KEY_E,"raise":KEY_UP,"lower":KEY_DOWN,
		"retract":KEY_LEFT,"extend":KEY_RIGHT,"scoop":KEY_SPACE,"carry_pose":KEY_B,
		"camera":KEY_C,"focus":KEY_F,"help":KEY_TAB,"reset":KEY_R,"pause":KEY_ESCAPE,"mute":KEY_M}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = bindings[action]
		InputMap.action_add_event(action,key)

func _process(_delta: float) -> void:
	if hud == null: return
	var count := 0
	for rock in get_tree().get_nodes_in_group("boulders"):
		if rock.delivered: count += 1
	if count > delivered_count:
		hud.toast("Material delivered. %d of 3 boulders in the bay."%count)
	delivered_count = count
	hud.total_delivered = count
	if engine_audio != null:
		engine_audio.pitch_scale = .8+absf(vehicle.drive_speed)*.09
		engine_audio.volume_db = -80 if muted else (-28 if vehicle.moving else -36)
		hydraulics_audio.volume_db = -80 if muted else (-31 if vehicle.busy or absf(vehicle.lift-vehicle.target_lift)>.04 or absf(vehicle.reach-vehicle.target_reach)>.04 else -80)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("reset"):
		reset_yard()
	if event.is_action_pressed("mute"):
		muted = not muted
		hud.toast("Machine audio muted" if muted else "Machine audio on")

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	camera.release_mouse()
	# Keep this node receiving pause/reset input, but pause the simulation children.
	process_mode = Node.PROCESS_MODE_ALWAYS
	vehicle.process_mode = Node.PROCESS_MODE_PAUSABLE
	camera.process_mode = Node.PROCESS_MODE_PAUSABLE
	for rock in get_tree().get_nodes_in_group("boulders"):
		rock.process_mode = Node.PROCESS_MODE_PAUSABLE
	if engine_audio:
		engine_audio.stream_paused = get_tree().paused
		hydraulics_audio.stream_paused = get_tree().paused

func reset_yard() -> void:
	reset_count += 1
	if get_tree().paused: toggle_pause()
	vehicle.reset_vehicle()
	for rock in get_tree().get_nodes_in_group("boulders"):
		rock.reset_rock()
	hud.elapsed = 0
	hud.complete_time = 0
	delivered_count = 0
	hud.total_delivered = 0
	hud.toast("Fresh shift. The first boulder is lined up with your bucket.")

func _setup_audio() -> void:
	# Headless validation has no audio device; avoid dummy-driver loop playback.
	if DisplayServer.get_name() == "headless": return
	engine_audio = AudioStreamPlayer.new()
	engine_audio.stream = load("res://assets/audio/diesel.wav")
	engine_audio.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	engine_audio.stream.loop_end = int(engine_audio.stream.get_length()*engine_audio.stream.mix_rate)
	engine_audio.volume_db = -36
	add_child(engine_audio)
	engine_audio.play()
	hydraulics_audio = AudioStreamPlayer.new()
	hydraulics_audio.stream = load("res://assets/audio/hydraulics.wav")
	hydraulics_audio.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	hydraulics_audio.stream.loop_end = int(hydraulics_audio.stream.get_length()*hydraulics_audio.stream.mix_rate)
	hydraulics_audio.volume_db = -80
	add_child(hydraulics_audio)
	hydraulics_audio.play()

func _capture_preview() -> void:
	await get_tree().create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://screenshots/yard.png")
	print("Preview saved to screenshots/yard.png")
	print("Rendered FPS: ",Engine.get_frames_per_second())
	get_tree().quit()

func _exit_tree() -> void:
	if engine_audio != null:
		engine_audio.stop()
		hydraulics_audio.stop()
