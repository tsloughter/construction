class_name GameApp
extends Node

# Switches between the opening picture screen and one independent game world.
var active_game: GameBase
var menu: OpeningMenu
var menu_layer: CanvasLayer
var current_mode := "menu"
var muted := false
var switching := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameBase.has_flag("--smoke-test") or GameBase.has_flag("--excavator") or GameBase.has_flag("--capture-loaded"):
		start_game("excavator")
	elif GameBase.has_flag("--bulldozer") or GameBase.has_flag("--bulldozer-test"):
		start_game("bulldozer")
	elif GameBase.has_flag("--loader") or GameBase.has_flag("--loader-test"):
		start_game("loader")
	else:
		show_menu()
		if GameBase.has_flag("--capture"): _capture_menu()
		if GameBase.has_flag("--menu-test"):
			var runner: Node = load("res://tests/menu_test.gd").new()
			runner.set("app",self)
			add_child(runner)

func _clear() -> void:
	get_tree().paused = false
	for action in ["up","down","left","right","scoop"]: Input.action_release(action)
	if is_instance_valid(active_game):
		muted = active_game.muted
		active_game.hud.release_buttons()
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
	match kind:
		"loader": active_game = LoaderGame.new()
		"bulldozer": active_game = BulldozerGame.new()
		_: active_game = ExcavatorGame.new()
	add_child(active_game)
	if muted: active_game.toggle_mute()
	active_game.menu_requested.connect(_request_menu)
	switching = false

func show_menu() -> void:
	_clear()
	current_mode = "menu"
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)
	menu = OpeningMenu.new()
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
