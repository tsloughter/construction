extends "res://tests/gameplay_test.gd"

var app

func _mouse(pos: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = pos
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
		await _frames(2)

func _key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		get_viewport().push_input(event,true)
		await _frames(2)

func _run() -> void:
	await _frames(20)
	_check(app.current_mode == "menu" and app.menu.cards.size() == 3,"Opening screen offers three illustrated games")
	await _mouse(app.menu.cards[0].get_global_rect().get_center())
	await _frames(30)
	_check(app.current_mode == "excavator" and app.active_game.vehicle.has_method("collect"),"Clicking the excavator picture opens the original game")
	_check(get_tree().get_nodes_in_group("boulders").size() == 3,"Excavator game has its own three pebbles")
	await _mouse(app.active_game.hud.home_button.get_global_rect().get_center())
	await _frames(20)
	_check(app.current_mode == "menu" and get_tree().get_nodes_in_group("boulders").is_empty(),"Home returns to the chooser and removes the old world")
	await _key(KEY_RIGHT)
	await _key(KEY_ENTER)
	await _frames(30)
	_check(app.current_mode == "bulldozer" and app.active_game.vehicle.has_method("push_rock"),"Keyboard selection opens the bulldozer game")
	_check(get_tree().get_nodes_in_group("holes").size() == 3 and get_tree().get_nodes_in_group("boulders").size() == 3,"Bulldozer starts with an independent yard")
	app.active_game.toggle_mute()
	app.active_game.toggle_pause()
	await _frames(5)
	await _mouse(app.active_game.hud.menu_button.get_global_rect().get_center())
	await _frames(20)
	_check(app.current_mode == "menu" and not get_tree().paused,"Home from the pause menu unpauses the chooser")
	_check(get_tree().get_nodes_in_group("holes").is_empty(),"Switching games removes all old hole physics")
	var pos: Vector2 = app.menu.cards[0].get_global_rect().get_center()
	for pressed in [true,false]:
		var touch := InputEventScreenTouch.new()
		touch.position = pos
		touch.index = 1
		touch.pressed = pressed
		get_viewport().push_input(touch,true)
		await _frames(2)
	await _frames(20)
	_check(app.current_mode == "excavator","Touch selection launches a game")
	_check(app.active_game.muted and app.active_game.hud.muted,"Sound preference survives switching games")
	_check(app.active_game.stars == 0 and get_tree().get_nodes_in_group("boulders").size() == 3,"Returning to a game starts a fresh playable round")
	await _mouse(app.active_game.hud.home_button.get_global_rect().get_center())
	await _frames(20)
	await _key(KEY_RIGHT)
	await _key(KEY_RIGHT)
	await _key(KEY_ENTER)
	await _frames(30)
	_check(app.current_mode == "loader" and app.active_game.truck_load == 0,"Keyboard navigation reaches the third loader and truck game")
	_check(app.active_game.muted and get_tree().get_nodes_in_group("boulders").is_empty(),"Third mode preserves sound preference and cleans up the previous world")
	app.active_game.toggle_pause()
	await _frames(4)
	await _mouse(app.active_game.hud.menu_button.get_global_rect().get_center())
	await _frames(20)
	_check(app.current_mode == "menu" and not get_tree().paused,"Loader pause-menu home safely returns to the chooser")
	var loader_pos: Vector2 = app.menu.cards[2].get_global_rect().get_center()
	for pressed in [true,false]:
		var touch := InputEventScreenTouch.new()
		touch.position = loader_pos
		touch.index = 2
		touch.pressed = pressed
		get_viewport().push_input(touch,true)
		await _frames(2)
	await _frames(20)
	_check(app.current_mode == "loader","Touching the third vehicle picture starts load and haul")
	await _mouse(app.active_game.hud.home_button.get_global_rect().get_center())
	await _frames(20)
	await _key(KEY_3)
	await _frames(20)
	_check(app.current_mode == "loader" and app.active_game.deliveries == 0,"Number 3 starts a fresh loader round")
	_finish()

func _finish() -> void:
	print("GAME MENU TEST: %d checks, %d failures"%[checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
