class_name GameBase
extends Node3D

# The shared frame for every game: camera, HUD wiring, pause, restart,
# sound, and the command-line hooks used by the tests and screenshots.
signal menu_requested

const SOUNDS := {
	"scoop": preload("res://assets/audio/scoop.wav"),
	"plop": preload("res://assets/audio/plop.wav"),
	"star": preload("res://assets/audio/star.wav"),
}
const ENGINE_LOOP := preload("res://assets/audio/diesel.wav")
var vehicle: Vehicle
var camera: FixedCamera
var hud: Hud
var players: Dictionary = {}
var engine_audio: AudioStreamPlayer
var muted := false
var stars := 0
var reset_count := 0
var test_flag := ""
var test_script := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_world()
	camera = FixedCamera.new()
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Hud.new()
	hud.vehicle = vehicle
	_configure_hud()
	canvas.add_child(hud)
	hud.action_requested.connect(_action)
	hud.direction_changed.connect(_steer)
	hud.pause_requested.connect(toggle_pause)
	hud.reset_requested.connect(reset_yard)
	hud.mute_requested.connect(toggle_mute)
	hud.menu_requested.connect(menu_requested.emit)
	_setup_audio()
	if not test_flag.is_empty() and has_flag(test_flag):
		var runner: Node = load(test_script).new()
		runner.set("game",self)
		add_child(runner)
	if has_flag("--capture") or has_flag("--capture-loaded"): _capture()

static func has_flag(flag: String) -> bool:
	return flag in OS.get_cmdline_user_args()

# Subclasses build their yard, vehicle and props here; `vehicle` must be set.
func _build_world() -> void:
	pass

func _configure_hud() -> void:
	pass

func _action() -> void:
	vehicle.action()

func _steer(direction: Vector2) -> void:
	vehicle.touch_direction = direction

func pointer_action(_screen_position: Vector2) -> void:
	pass

func _capture() -> void:
	pass

func _process(_delta: float) -> void:
	if engine_audio: engine_audio.volume_db = -38 if vehicle.moving else -80

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reset"):
		reset_yard()
	elif event.is_action_pressed("mute"):
		toggle_mute()

func _unhandled_input(event: InputEvent) -> void:
	# Touch arrives here as an emulated mouse press, so one branch covers both.
	if get_tree().paused: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_action(event.position)
		get_viewport().set_input_as_handled()

func ground_point(screen_position: Vector2) -> Variant:
	return Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(screen_position),camera.project_ray_normal(screen_position))

func in_yard(point: Vector3) -> bool:
	return absf(point.x)<12 and absf(point.z)<8.5

func _award_star(message: String) -> void:
	stars += 1
	hud.stars = stars
	hud.celebrate("Hooray!" if stars == 3 else message)
	_play_sound("star")

func toggle_pause() -> void:
	hud.release_buttons()
	vehicle.cancel_movement()
	get_tree().paused = not get_tree().paused

func reset_yard() -> void:
	reset_count += 1
	get_tree().paused = false
	hud.release_buttons()
	vehicle.reset_vehicle()
	stars = 0
	hud.stars = 0
	hud.celebration_time = 0
	for player in players.values(): player.stop()

func toggle_mute() -> void:
	muted = not muted
	hud.muted = muted
	AudioServer.set_bus_mute(0,muted)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud):
		hud.release_buttons()
		vehicle.cancel_movement()

func _setup_audio() -> void:
	if DisplayServer.get_name() == "headless": return
	# Pausable players stop with the tree; one player per chime so they overlap.
	for sound_name in SOUNDS:
		var player := AudioStreamPlayer.new()
		player.stream = SOUNDS[sound_name]
		player.volume_db = -16
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(player)
		players[sound_name] = player
	engine_audio = AudioStreamPlayer.new()
	engine_audio.stream = ENGINE_LOOP
	engine_audio.pitch_scale = 1.3
	engine_audio.volume_db = -80
	engine_audio.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(engine_audio)
	engine_audio.play()

func _play_sound(which: String) -> void:
	if players.has(which): players[which].play()

func _capture_screen(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("Preview saved: ",path)

func _exit_tree() -> void:
	_shutdown_audio()

func _shutdown_audio() -> void:
	if engine_audio:
		engine_audio.stop()
		engine_audio.stream = null
	for player in players.values():
		player.stop()
		player.stream = null
