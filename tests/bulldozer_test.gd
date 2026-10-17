extends "res://tests/gameplay_test.gd"

func _run() -> void:
	await _frames(90)
	var v = game.vehicle
	var rock = game.get_node("Pebble1")
	_check(v.model != null,"Blender bulldozer model loads")
	_check(get_tree().get_nodes_in_group("holes").size() == 3,"Three distinct holes are available")
	var camera_start: Transform3D = game.camera.global_transform
	var rock_start: Vector3 = rock.position
	Input.action_press("up")
	await _frames(90)
	_check(rock.position.z<rock_start.z-1,"Driving the broad blade into a boulder physically pushes it")
	_check(not rock.freeze,"A pushed boulder remains a free physics body")
	var filled := await _until(func(): return rock.completed,360)
	Input.action_release("up")
	await _frames(10)
	_check(filled,"Direct driving pushes the boulder down into a real hole")
	_check(rock.position.y<0 and game.stars == 1,"A fallen boulder earns one star")
	_check(v.position.y>-.2,"The bulldozer stays supported above the holes")
	_check(game.camera.global_transform == camera_start,"The bulldozer camera stays fixed")
	_check(not v.moving,"Releasing the direction stops the bulldozer")
	for i in [1,2]:
		var pebble = game.get_node("Pebble%d"%(i+1))
		game.pointer_action(game.camera.unproject_position(pebble.position)+Vector2(20,0))
		filled = await _until(func(): return pebble.completed,2400)
		_check(filled,"Tap assist lines up and pushes boulder %d into an open hole"%(i+1))
		if not filled:
			print("ASSIST DEBUG: ",v.mode," vehicle ",v.position," rock ",pebble.position," waypoints ",v.waypoints)
			_finish()
			return
	await _frames(100)
	_check(game.stars == 3 and game.hud.stars == 3,"All three filled holes earn three stars without duplicates")
	v.action()
	await _frames(30)
	_check(v.mode == v.Mode.IDLE and game.stars == 3,"Push after completion is harmless and free driving continues")
	game.reset_yard()
	await _frames(60)
	_check(game.stars == 0 and not rock.completed and not rock.freeze,"Restart restores all boulders and clears stars")
	_check(get_tree().get_nodes_in_group("holes").all(func(h): return not h.filled),"Restart reopens all holes")
	await _tap("scoop")
	_check(v.mode != v.Mode.IDLE,"Space starts the optional push assist")
	Input.action_press("right")
	await _frames(12)
	Input.action_release("right")
	_check(v.mode == v.Mode.IDLE,"Direct arrows immediately take over from push assist")
	game.reset_yard()
	await _frames(30)
	v.action()
	await _frames(30)
	game.toggle_pause()
	var before: Vector3 = v.position
	var before_rock: Vector3 = rock.position
	await _frames(30)
	_check(get_tree().paused and before == v.position and before_rock == rock.position,"Pause freezes the vehicle and physics boulders")
	game.reset_yard()
	await _frames(30)
	_check(not get_tree().paused and v.mode == v.Mode.IDLE,"Restart during a paused push safely clears the assist")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = game.hud.arrows.right.get_global_rect().get_center()
	touch.pressed = true
	get_viewport().push_input(touch,true)
	await _frames(20)
	_check(v.touch_direction.x>.9,"Bulldozer touch direction button drives")
	touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(800,100)
	touch.pressed = false
	get_viewport().push_input(touch,true)
	await _frames(4)
	_check(v.touch_direction == Vector2.ZERO and not v.moving,"Releasing touch outside the button stops")
	rock.position = Vector3(30,-5,30)
	await _frames(60)
	_check(rock.position.distance_to(rock.spawn_point)<1,"A lost boulder quietly returns")
	Input.action_press("right")
	await _frames(420)
	Input.action_release("right")
	_check(v.position.x<=game.Play.DRIVE_X+.01,"Driving limits keep the bulldozer on screen")
	game.reset_yard()
	await _frames(45)
	v.action()
	filled = await _until(func(): return rock.completed,900)
	_check(filled,"A reopened hole can be filled again after restart")
	# Children can move a rock away from its starting lane before asking for help.
	for setup in [[Vector3(-3,.85,2.8),Vector3(5,0,-1)],[Vector3(5,.85,3.5),Vector3(-5,0,-5)]]:
		game.reset_yard()
		rock.freeze = true
		rock.position = setup[0]
		rock.freeze = false
		v.position = setup[1]
		await _frames(45)
		v.push_rock(rock)
		filled = await _until(func(): return rock.completed,2700)
		_check(filled,"Assist handles a displaced boulder from a different approach")
		if not filled: print("DISPLACED DEBUG: ",v.mode," vehicle ",v.position," rock ",rock.position)
	game.toggle_mute()
	_check(game.muted and game.hud.muted,"Bulldozer sound toggle works")
	_finish()

func _finish() -> void:
	print("BULLDOZER TEST: %d checks, %d failures"%[checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
