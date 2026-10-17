extends Node

const Menu = preload("res://scripts/opening_menu.gd")
const ExcavatorGame = preload("res://scripts/main.gd")
const BulldozerGame = preload("res://scripts/bulldozer_game.gd")
var active_game
var menu
var menu_layer: CanvasLayer
var current_mode := "menu"
var muted := false
var switching := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if "--smoke-test" in args or "--excavator" in args or "--capture-loaded" in args:
		start_game("excavator")
	elif "--bulldozer" in args or "--bulldozer-test" in args:
		start_game("bulldozer")
	else:
		show_menu()
		if "--capture" in args: _capture_menu()
		if "--menu-test" in args:
			var runner = load("res://tests/menu_test.gd").new()
			runner.app = self
			add_child(runner)

func _clear() -> void:
	get_tree().paused = false
	for action in ["up","down","left","right","scoop"]:
		if InputMap.has_action(action): Input.action_release(action)
	if is_instance_valid(active_game):
		muted = active_game.muted
		active_game.hud.release_buttons()
		active_game._shutdown_audio()
		remove_child(active_game)
		active_game.queue_free()
	active_game = null
	if is_instance_valid(menu_layer):
		remove_child(menu_layer)
		menu_layer.queue_free()
	menu_layer = null
	menu = null

func start_game(kind: String) -> void:
	_clear()
	current_mode = kind
	active_game = BulldozerGame.new() if kind == "bulldozer" else ExcavatorGame.new()
	add_child(active_game)
	if muted: active_game.toggle_mute()
	active_game.menu_requested.connect(_request_menu)
	switching = false

func show_menu() -> void:
	_clear()
	current_mode = "menu"
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)
	menu = Menu.new()
	menu_layer.add_child(menu)
	menu.game_selected.connect(_request_game)
	switching = false

func _request_game(kind: String) -> void:
	if switching: return
	switching = true
	start_game.call_deferred(kind)

func _request_menu() -> void:
	if switching: return
	switching = true
	show_menu.call_deferred()

func _capture_menu() -> void:
	await get_tree().create_timer(2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://screenshots/opening.png")
	get_tree().quit()
