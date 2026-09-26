extends Node

var game
var failures: Array[String] = []
var checks := 0

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(2)

func _run() -> void:
	await _frames(100)
	var v = game.vehicle
	var first = game.get_node("Boulder1")
	_check(v.upper != null and v.boom != null and v.bucket != null, "Blender hierarchy has all articulated pivots")
	_check(v.socket.global_position.distance_to(Vector3(.35,.8,-5.0)) < .3, "IK places bucket socket at the starter boulder")
	print("Initial bucket: ",v.bucket.global_position," socket: ",v.socket.global_position," rock: ",first.global_position)
	_check(v.candidate == first, "Starter boulder is inside the open bucket's scoop region")
	_check(first.global_position.y > .3 and first.global_position.y < 1.3, "Loose boulder rests on ground / bucket collision")
	await _tap("scoop")
	await _frames(60)
	_check(v.held == first and first.freeze and first.carried, "Space curls bucket and secures the boulder")
	if v.held != first:
		_finish()
		return
	await _tap("carry_pose")
	await _frames(95)
	_check(first.global_position.y > 1.6, "Travel pose lifts the boulder above the tracks")
	_check(first.global_position.distance_to(v.socket.global_position) < .08, "Carried boulder stays seated in bucket")
	var start_yaw: float = v.upper.rotation.y
	Input.action_press("slew_left")
	await _frames(30)
	Input.action_release("slew_left")
	_check(v.upper.rotation.y > start_yaw+.2, "Q slews the cab and arm independently")
	_check(first.global_position.distance_to(v.socket.global_position) < .2, "Load follows the swinging upper body")
	Input.action_press("slew_right")
	await _frames(30)
	Input.action_release("slew_right")
	var start_pos: Vector3 = v.position
	await _drive_to(Vector3(8,0,-3.15))
	await _turn_to(0.0)
	await _frames(50)
	_check(v.position.distance_to(start_pos) > 6, "WASD drives and turns a loaded excavator to the bay")
	_check(first.global_position.distance_to(v.socket.global_position) < .12, "Load remains secured after transport")
	print("Drop pose vehicle: ",v.position," yaw: ",v.rotation.y," bucket: ",v.bucket.global_position)
	await _tap("scoop")
	await _frames(60)
	_check(v.held == null and not first.freeze and not first.carried, "Tipping releases a dynamic rigid body")
	await _frames(200)
	_check(first.global_position.y < 1.3 and first.global_position.y > .2, "Released rock falls and settles on the yard")
	_check(first.delivered and game.delivered_count == 1, "Settled delivery counts once in the objective")
	# Repeat through the actual controls to exercise the full three-rock objective.
	for index in [2,3]:
		var rock = game.get_node("Boulder%d"%index)
		var pickup_position: Vector3 = rock.global_position+Vector3(-.35,0,5.0)
		pickup_position.y = 0
		await _drive_to(pickup_position)
		await _turn_to(0.0)
		v.target_reach = 3.9
		v.target_lift = .90
		await _frames(130)
		print("Pickup ",index,": bucket ",v.bucket.global_position," rock ",rock.global_position)
		_check(v.candidate == rock,"Boulder %d can be reached after transport"%index)
		await _tap("scoop")
		await _frames(60)
		_check(v.held == rock,"Boulder %d scoops successfully"%index)
		if v.held == null:
			_finish()
			return
		await _tap("carry_pose")
		await _frames(90)
		await _drive_to(Vector3(7.0+index*.55,0,-3.15))
		await _turn_to(0)
		await _tap("scoop")
		await _frames(100)
		# Contact with an existing pile may roll a rock before it settles.
		for step in 900:
			if rock.delivered: break
			await _frames(1)
		print("Delivered ",index,": vehicle ",v.position," rock ",rock.global_position," velocity ",rock.linear_velocity)
		_check(rock.delivered,"Boulder %d lands and settles in the bay"%index)
	for step in 900:
		if game.delivered_count == 3: break
		await _frames(1)
	_check(game.delivered_count == 3,"All three delivered rocks complete the shift")
	var old: Vector3 = v.position
	game.toggle_pause()
	await get_tree().create_timer(.1,true).timeout
	_check(get_tree().paused and v.position == old, "Pause freezes the machine")
	game.toggle_pause()
	game.reset_yard()
	await _frames(100)
	_check(game.delivered_count == 0 and not first.delivered and not first.ever_carried, "Reset clears delivered state")
	_check(v.position.distance_to(Vector3.ZERO) < .2 and v.held == null, "Reset restores excavator and load state")
	_check(v.candidate == first, "Reset restores a scoopable starter rock")
	# Reset during a pending scoop invalidates its delayed callback.
	await _tap("scoop")
	game.reset_yard()
	await _frames(100)
	_check(v.held == null and not v.busy and not first.freeze, "Reset cancels in-flight bucket interaction safely")
	# Empty-space scoops must never attract a distant boulder.
	v.global_position = Vector3(15,0,14)
	await _frames(5)
	await _tap("scoop")
	_check(v.held == null, "Distant boulders cannot be scooped")
	game.reset_yard()
	await _frames(100)
	# Extreme reach/height requests still produce a finite arm within link limits.
	v.target_reach = 5.2
	v.target_lift = 4.7
	await _frames(150)
	_check(v.bucket.global_position.is_finite() and v.boom.global_position.distance_to(v.bucket.global_position) <= 6.11, "Arm IK safely clamps unreachable extremes")
	_finish()

func _drive_to(destination: Vector3) -> void:
	var v = game.vehicle
	for i in 900:
		var offset: Vector3 = destination-v.position
		offset.y = 0
		if offset.length() < .32: break
		var desired := atan2(-offset.x,-offset.z)
		var error := wrapf(desired-v.rotation.y,-PI,PI)
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		if absf(error) > .035:
			Input.action_press("steer_left" if error>0 else "steer_right",clampf(absf(error)*2,0,1))
		if absf(error) < .35:
			Input.action_press("forward",clampf(offset.length()*.5,.15,.8))
		else:
			Input.action_release("forward")
		await _frames(1)
	Input.action_release("forward")
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	await _frames(50)

func _turn_to(angle: float) -> void:
	var v = game.vehicle
	for i in 500:
		var error := wrapf(angle-v.rotation.y,-PI,PI)
		if absf(error)<.02: break
		Input.action_release("steer_left")
		Input.action_release("steer_right")
		Input.action_press("steer_left" if error>0 else "steer_right")
		await _frames(1)
	Input.action_release("steer_left")
	Input.action_release("steer_right")

func _finish() -> void:
	print("GAMEPLAY TEST: %d checks, %d failures"%[checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
