extends "res://tests/gameplay_test.gd"

func _click(point: Vector3) -> void:
	var pos: Vector2 = game.camera.unproject_position(point)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = pos
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event,true)
		await _frames(2)

func _wait_idle() -> bool:
	return await _until(func(): return not game.vehicle.navigating and game.animation.is_empty(),1500)

func _fill_truck() -> bool:
	for i in 3:
		await _tap("scoop")
		if not await _wait_idle(): return false
		if not game.bucket_full: return false
		await _tap("scoop")
		if not await _wait_idle(): return false
	return game.truck_load == 3 and game.vehicle == game.truck

func _run() -> void:
	await _frames(60)
	_check(game.vehicle == game.loader and game.loader.model.bucket != null and game.truck.model.bed != null,"Loader and dump truck have distinct working models")
	var camera_start: Transform3D = game.camera.global_transform
	var start: Vector3 = game.loader.position
	Input.action_press("right")
	await _frames(25)
	Input.action_release("right")
	await _frames(4)
	_check(game.loader.position.x>start.x+1 and not game.loader.moving,"Arrows drive and release stops the loader")
	_check(game.truck.position.distance_to(game.LoaderYard.TRUCK)<.1,"Parked truck stays put while the loader is driven")
	game.reset_yard()
	await _frames(10)
	await _click(game.LoaderYard.DIRT+Vector3(0,.8,0))
	var done := await _wait_idle()
	_check(done and game.bucket_full and game.loader.model.cargo.visible,"Clicking dirt drives over, scoops and raises a visible bucketful")
	if not done: return _debug_finish()
	_check(game.loader.model.arm.get_child(0).global_position.distance_to(game.loader.model.arm.global_position)<3,"Loader arm stays attached to its pivot while raised")
	var cargo_parent = game.loader.model.cargo.get_parent()
	Input.action_press("left")
	await _frames(12)
	Input.action_release("left")
	await _frames(4)
	_check(game.bucket_full and game.loader.model.cargo.get_parent() == cargo_parent,"Dirt stays secured inside the bucket while driving")
	await _click(game.truck.position+Vector3(0,1.4,.5))
	done = await _wait_idle()
	_check(done and not game.bucket_full and game.truck_load == 1 and game.truck.model.cargo.visible,"Clicking the truck tips the raised bucket into its bed")
	_check(game.stars == 0 and game.vehicle == game.loader,"Partial loading keeps control of the loader and awards no delivery star")
	for i in 2:
		await _tap("scoop")
		done = await _wait_idle()
		_check(done and game.bucket_full,"Space scoops the next bucketful")
		if not done: return _debug_finish()
		await _tap("scoop")
		done = await _wait_idle()
		_check(done and game.truck_load == i+2,"Space carries and tips a bucketful into the truck")
		if not done: return _debug_finish()
	_check(game.vehicle == game.truck and game.truck.active and not game.loader.active,"Three bucketfuls fill the truck and transfer driving control")
	var parked: Vector3 = game.loader.position
	start = game.truck.position
	Input.action_press("right")
	await _frames(30)
	Input.action_release("right")
	await _frames(4)
	_check(game.truck.position.x>start.x+1 and game.loader.position.distance_to(parked)<.05,"The player drives the full truck independently of the parked loader")
	_check(game.truck_load == 3 and game.deliveries == 0,"Driving a full truck keeps its load until an actual dump")
	await _click(game.LoaderYard.DUMP+Vector3(0,2.35,.6))
	done = await _until(func(): return game.animation == "dump",1500)
	_check(done and game.truck.position.distance_to(game.DUMP_SPOT)<.2,"Tapping the star drives the loaded truck to a separate dumping bay")
	if not done: return _debug_finish()
	await _frames(35)
	_check(game.truck.model.bed.rotation.x>.5,"The truck bed visibly lifts to tip its load")
	game.toggle_pause()
	var bed_angle: float = game.truck.model.bed.rotation.x
	await _frames(30)
	_check(bed_angle == game.truck.model.bed.rotation.x,"Pause freezes tipping mid-animation")
	game.toggle_pause()
	done = await _wait_idle()
	_check(done and game.truck_load == 0 and game.deliveries == 1 and game.stars == 1,"Dumping empties the truck and earns one delivery star")
	_check(game.yard.delivered_pile.visible and game.truck.model.bed.rotation.x == 0,"Delivered dirt stays in the bay and the empty bed lowers")
	await _frames(180)
	_check(game.stars == 1 and game.deliveries == 1,"A completed dump cannot award duplicate rewards")
	await _tap("scoop")
	done = await _wait_idle()
	_check(done and game.vehicle == game.loader and game.truck.position.distance_to(game.LoaderYard.TRUCK)<.2,"Return assistance parks the empty truck and restores loader control")
	if not done: return _debug_finish()
	for round_index in 2:
		done = await _fill_truck()
		_check(done,"A returned truck can be filled again")
		if not done: return _debug_finish()
		await _tap("scoop")
		done = await _wait_idle()
		_check(done and game.deliveries == round_index+2,"Repeated hauling delivers another full load")
		if not done: return _debug_finish()
		await _tap("scoop")
		if not await _wait_idle(): return _debug_finish()
	_check(game.stars == 3 and game.hud.stars == 3,"Three completed truck deliveries earn all keepsake stars")
	_check(game.camera.global_transform == camera_start,"The camera stays fixed through both vehicle controls")
	game.reset_yard()
	await _frames(10)
	await _tap("scoop")
	await _frames(10)
	Input.action_press("right")
	await _frames(10)
	Input.action_release("right")
	_check(not game.loader.navigating and game.intent.is_empty(),"Arrows cancel assistance immediately without a stale scoop")
	await _tap("scoop")
	done = await _until(func(): return game.animation == "scoop")
	_check(done,"Scoop animation can be started again after taking over")
	game.toggle_pause()
	game.reset_yard()
	await _frames(150)
	_check(not get_tree().paused and game.animation.is_empty() and not game.bucket_full and game.truck_load == 0,"Restart during a paused scoop clears all pending cargo changes")
	_check(game.stars == 0 and game.deliveries == 0 and not game.yard.delivered_pile.visible,"Restart clears rewards and the dumped dirt pile")
	game.loader.position = Vector3(7,0,-5)
	done = await _fill_truck()
	_check(done,"Assistance routes a displaced loader around the parked truck")
	if not done: return _debug_finish()
	game.truck.position = Vector3(-8,0,-5)
	await _tap("scoop")
	done = await _wait_idle()
	_check(done and game.deliveries == 1,"A truck driven across the yard can route around the loader to dump")
	if not done: return _debug_finish()
	game.reset_yard()
	await _frames(10)
	# The inherited HUD routes touch movement to whichever vehicle is active.
	for pressed in [true,false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = game.hud.arrows.left.get_global_rect().get_center() if pressed else Vector2(700,200)
		touch.pressed = pressed
		get_viewport().push_input(touch,true)
		await _frames(12)
		_check(game.vehicle.touch_direction.x<-.9 if pressed else game.vehicle.touch_direction == Vector2.ZERO,"Touch direction presses and releases outside safely")
	Input.action_press("left")
	await _frames(300)
	Input.action_release("left")
	_check(game.loader.position.x>=-game.Play.DRIVE_X-.01,"Driving limits keep the loader in view")
	game.toggle_mute()
	_check(game.muted and game.hud.muted,"Loader game shares the parent sound controls")
	_finish()

func _debug_finish() -> void:
	_check(false,"Hauling sequence completed within the time limit")
	print("HAUL DEBUG: intent ",game.intent," animation ",game.animation," vehicle ",game.vehicle.kind," position ",game.vehicle.position," waypoints ",game.vehicle.waypoints)
	_finish()

func _finish() -> void:
	print("LOADER TEST: %d checks, %d failures"%[checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
