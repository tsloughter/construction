extends Node

var game
var failures: Array[String] = []
var checks := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition: print("PASS: ",description)
	else:
		failures.append(description)
		push_error("FAIL: "+description)

func _frames(count: int) -> void:
	for i in count: await get_tree().physics_frame

func _until(predicate: Callable, maximum: int = 900) -> bool:
	for i in maximum:
		if predicate.call():
			await _frames(3)
			return true
		await _frames(1)
	return false

func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(2)

func _run() -> void:
	await _frames(90)
	var v = game.vehicle
	var rock = game.get_node("Pebble1")
	var camera_start: Transform3D = game.camera.global_transform
	_check(v.boom != null and v.bucket != null and v.socket != null,"Toy Blender model has functional arm pivots")
	var start: Vector3 = v.position
	Input.action_press("right")
	await _frames(60)
	Input.action_release("right")
	await _frames(4)
	_check(v.position.x>start.x+2.5 and absf(v.position.z-start.z)<.1,"Right arrow moves right on screen without tank steering")
	start = v.position
	Input.action_press("up")
	await _frames(45)
	Input.action_release("up")
	await _frames(4)
	_check(v.position.z<start.z-1.8,"Up arrow moves toward the top of the sandbox")
	_check(v.drive_speed<.01,"Releasing a direction stops the toy immediately")
	_check(game.camera.global_transform == camera_start,"Camera stays fixed through direction changes")
	game.reset_yard()
	await _frames(60)
	# Real GUI dispatch for both mouse and touch, including releases outside.
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = game.hud.arrows.right.get_global_rect().get_center()
	mouse.pressed = true
	get_viewport().push_input(mouse,true)
	await _frames(30)
	_check(v.touch_direction.x>.9,"Mouse press activates the large direction button")
	mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = Vector2(700,200)
	mouse.pressed = false
	get_viewport().push_input(mouse,true)
	await _frames(4)
	_check(v.touch_direction == Vector2.ZERO,"Mouse release outside a button never sticks")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = game.hud.arrows.left.get_global_rect().get_center()
	touch.pressed = true
	get_viewport().push_input(touch,true)
	await _frames(12)
	_check(v.touch_direction.x<-.9,"Touch press activates a direction button")
	touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(800,100)
	touch.pressed = false
	get_viewport().push_input(touch,true)
	await _frames(4)
	_check(v.touch_direction == Vector2.ZERO,"Touch release outside a button never sticks")
	game.reset_yard()
	await _frames(60)
	rock = v.candidate
	await _tap("scoop")
	var picked := await _until(func(): return v.held == rock and v.mode == v.Mode.IDLE)
	_check(picked,"One Space press approaches, aligns, scoops, and lifts the nearest pebble")
	if not picked:
		print("Pickup state: ",v.mode," machine ",v.position," rock ",rock.position," socket ",v.socket.global_position)
		_finish()
		return
	_check(rock.freeze and rock.carried and rock.position.distance_to(v.socket.global_position)<.1,"Load is stable in the automatically raised bucket")
	Input.action_press("left")
	await _frames(30)
	Input.action_release("left")
	await _frames(8)
	_check(rock.position.distance_to(v.socket.global_position)<.1,"Pebble stays in the scoop during automatic steering")
	await _tap("scoop")
	await _until(func(): return v.held == null and v.mode == v.Mode.IDLE)
	await _frames(180)
	_check(not rock.freeze and not rock.carried and rock.position.y<1,"One Space press drops a real physics pebble anywhere")
	_check(game.stars == 0,"Free play drops need no goal and do not create a false reward")
	game.reset_yard()
	await _frames(60)
	for i in 3:
		var pebble = game.get_node("Pebble%d"%(i+1))
		game.pointer_action(game.camera.unproject_position(pebble.global_position)+Vector2(22,0))
		picked = await _until(func(): return v.held == pebble and v.mode == v.Mode.IDLE)
		_check(picked,"Generous click target collects pebble %d with no arm controls"%(i+1))
		if not picked:
			print("Pickup state: ",v.mode," machine ",v.position," rock ",pebble.position," socket ",v.socket.global_position)
			_finish()
			return
		game.pointer_action(game.camera.unproject_position(game.Play.DROP_CENTER+Vector3(0,2.35,-.3)))
		var delivered := await _until(func(): return pebble.rewarded,1200)
		_check(delivered,"Clicking the star carries and gently drops pebble %d into the garden"%(i+1))
		if not delivered:
			print("Drop state: ",v.mode," machine ",v.position," rock ",pebble.position)
			_finish()
			return
		await _until(func(): return v.mode == v.Mode.IDLE)
	_check(game.stars == 3,"Three different pebbles earn three celebration stars")
	# Collected stars never disappear or multiply when a child replays a pebble.
	game.pointer_action(game.camera.unproject_position(rock.global_position))
	await _until(func(): return v.held == rock and v.mode == v.Mode.IDLE)
	_check(game.stars == 3,"Picking a pebble up again never takes away a star")
	await _tap("scoop")
	await _until(func(): return v.mode == v.Mode.IDLE)
	await _frames(150)
	_check(game.stars == 3,"Repeated delivery cannot award duplicate stars")
	game.reset_yard()
	await _frames(60)
	game.pointer_action(game.camera.unproject_position(game.get_node("Pebble3").position))
	await _frames(6)
	Input.action_press("down")
	await _frames(8)
	Input.action_release("down")
	_check(v.mode == v.Mode.IDLE,"Arrow input can take over from click-to-drive")
	game.reset_yard()
	await _frames(60)
	await _tap("scoop")
	await _until(func(): return v.busy)
	game.toggle_pause()
	var paused_socket: Vector3 = v.socket.global_position
	await _frames(10)
	_check(get_tree().paused and v.socket.global_position == paused_socket,"Pause freezes an automatic scoop")
	game.reset_yard()
	await _frames(120)
	_check(not get_tree().paused and not v.busy and v.held == null and not rock.freeze,"Restart safely clears a paused scoop and restores free play")
	_check(game.stars == 0,"Restart clears the three keepsake stars")
	rock.position = Vector3(30,-5,30)
	await _frames(60)
	_check(rock.position.distance_to(rock.spawn_point)<1,"A lost pebble quietly returns to the sandbox")
	Input.action_press("right")
	await _frames(420)
	Input.action_release("right")
	_check(v.position.x<=game.Play.DRIVE_X+.01,"Holding an arrow cannot drive out of the sandbox")
	game.toggle_mute()
	_check(game.muted and game.hud.muted,"Parent sound toggle updates audio and its picture button")
	_finish()

func _finish() -> void:
	print("LITTLE DIGGER TEST: %d checks, %d failures"%[checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
