extends CharacterBody3D

signal scooped
signal dropped

const Geo = preload("res://scripts/geometry.gd")
const Play = preload("res://scripts/playground.gd")
enum Mode { IDLE, GO, FACE, LOWER, CURL, LIFT, LOWER_DROP, TIP, FINISH_DROP }
var mode := Mode.IDLE
var model: Node3D
var upper: Node3D
var boom: Node3D
var stick: Node3D
var bucket: Node3D
var socket: Node3D
var held
var candidate
var chosen
var busy := false
var touch_direction := Vector2.ZERO
var drive_speed := 0.0
var moving := false
var reach := 2.5
var lift := 1.7
var curl := 0.0
var target_reach := 2.5
var target_lift := 1.7
var target_curl := 0.0
var destination := Vector3.ZERO
var focus_point := Vector3.ZERO
var next_job := ""
var desired_yaw := 0.0
var phase_time := 0.0
var marker: Node3D
var move_marker: Node3D
var wheels: Array[Node3D] = []

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.3,1.0,3.4)
	collider.shape = shape
	collider.position.y = .55
	add_child(collider)
	model = preload("res://assets/models/excavator.glb").instantiate()
	add_child(model)
	upper = model.find_child("Upper",true,false)
	boom = model.find_child("Boom",true,false)
	stick = model.find_child("Stick",true,false)
	bucket = model.find_child("Bucket",true,false)
	socket = model.find_child("CarrySocket",true,false)
	_cache_wheels(model)
	marker = Geo.ring(get_parent(),1.08,Color("618f91"),32)
	move_marker = Geo.ring(get_parent(),.55,Color("ffffff"),24)
	move_marker.visible = false
	_solve_arm()

func _physics_process(delta: float) -> void:
	var keys := Input.get_vector("left","right","up","down")
	var direction := keys if keys.length() > .05 else touch_direction
	var travel := Vector3.ZERO
	# Direction means direction on the screen. No reversing/steering distinction.
	if direction.length() > .05 and mode in [Mode.IDLE,Mode.GO]:
		mode = Mode.IDLE
		next_job = ""
		chosen = null
		move_marker.visible = false
		travel = Vector3(direction.x,0,direction.y).limit_length(1)
	elif mode == Mode.GO:
		var offset := destination-global_position
		offset.y = 0
		if offset.length() < .12:
			move_marker.visible = false
			if next_job == "":
				mode = Mode.IDLE
			else:
				_begin_face()
		else:
			travel = offset.normalized()*minf(1,offset.length()*2)
	if travel.length() > .01:
		desired_yaw = atan2(-travel.x,-travel.z)
		rotation.y = lerp_angle(rotation.y,desired_yaw,1-exp(-delta*8))
	velocity.x = travel.x*3.0
	velocity.z = travel.z*3.0
	velocity.y = -1.0 if is_on_floor() else velocity.y-delta*9.8
	move_and_slide()
	position.x = clampf(position.x,-Play.DRIVE_X,Play.DRIVE_X)
	position.z = clampf(position.z,-Play.DRIVE_Z,Play.DRIVE_Z)
	drive_speed = Vector2(velocity.x,velocity.z).length()
	moving = drive_speed > .05
	for wheel in wheels:
		wheel.rotate_object_local(Vector3.UP,drive_speed*delta*1.3)
	phase_time += delta
	_step_job(delta)
	lift = move_toward(lift,target_lift,delta*2.4)
	reach = move_toward(reach,target_reach,delta*2.8)
	curl = move_toward(curl,target_curl,delta*2.8)
	_solve_arm()
	if held != null:
		var seat := socket.global_position
		if mode == Mode.TIP:
			seat = seat.lerp(_lip_position(),smoothstep(.12,.60,phase_time))
		held.global_position = held.global_position.lerp(seat,minf(1,delta*18))
	busy = mode not in [Mode.IDLE,Mode.GO]
	_update_candidate()
	if Input.is_action_just_pressed("scoop"):
		action()

func has_load() -> bool:
	return held != null

func _step_job(delta: float) -> void:
	match mode:
		Mode.FACE:
			rotation.y = lerp_angle(rotation.y,desired_yaw,1-exp(-delta*10))
			if absf(angle_difference(rotation.y,desired_yaw)) < .025:
				var d := global_position.distance_to(Vector3(focus_point.x,global_position.y,focus_point.z))
				target_reach = clampf(sqrt(maxf(.1,d*d-.35*.35))-1.05,1.7,4.9)
				target_curl = 0
				target_lift = maxf(.84,chosen.global_position.y+.18) if next_job == "pick" else 1.2
				mode = Mode.LOWER if next_job == "pick" else Mode.LOWER_DROP
		Mode.LOWER:
			if _arm_arrived():
				if not is_instance_valid(chosen) or chosen.global_position.distance_to(socket.global_position)>1.5:
					mode = Mode.IDLE
					return
				held = chosen
				held.attach_to_bucket()
				target_curl = -.35
				mode = Mode.CURL
				phase_time = 0
		Mode.CURL:
			if phase_time > .42:
				target_lift = 2.2
				target_reach = 2.3
				mode = Mode.LIFT
		Mode.LIFT:
			if _arm_arrived():
				mode = Mode.IDLE
				scooped.emit()
		Mode.LOWER_DROP:
			if _arm_arrived():
				mode = Mode.TIP
				target_curl = .95
				phase_time = 0
		Mode.TIP:
			if phase_time > .68:
				var rock = held
				held = null
				rock.global_position = _lip_position()
				rock.release_from_bucket(-global_basis.z*.3)
				mode = Mode.FINISH_DROP
				phase_time = 0
				dropped.emit()
		Mode.FINISH_DROP:
			if phase_time > .40:
				target_lift = 1.7
				target_reach = 2.5
				target_curl = 0
				mode = Mode.IDLE

func _arm_arrived() -> bool:
	return absf(lift-target_lift)<.04 and absf(reach-target_reach)<.04

func _lip_position() -> Vector3:
	return bucket.global_position-global_basis.z*1.35+Vector3(0,-.1,0)

func _solve_arm() -> void:
	var y := lift-(position.y+1.81)
	var d := clampf(Vector2(reach,y).length(),.3,6.04)
	boom.rotation.x = atan2(y,reach)+acos(clampf((d*d+3.1*3.1-9)/(2*d*3.1),-1,1))
	stick.rotation.x = -acos(clampf((d*d-3.1*3.1-9)/(2*3.1*3),-1,1))
	bucket.rotation.x = curl-boom.rotation.x-stick.rotation.x

func _update_candidate() -> void:
	candidate = null
	var nearest := INF
	if held == null and mode == Mode.IDLE:
		for rock in get_tree().get_nodes_in_group("boulders"):
			if rock.carried: continue
			# Prefer an uncollected rock, but allow endless play with all of them.
			var distance: float = global_position.distance_to(rock.global_position)+(30 if rock.rewarded else 0)
			if distance<nearest:
				candidate = rock
				nearest = distance
	marker.visible = candidate != null or (chosen != null and next_job == "pick" and mode != Mode.IDLE and held == null)
	var marked = candidate if candidate != null else chosen
	if marker.visible and is_instance_valid(marked):
		marker.global_position = Vector3(marked.position.x,.055,marked.position.z)
		var pulse := 1.0+.05*sin(Time.get_ticks_msec()*.004)
		marker.scale = Vector3(pulse,1,pulse)

func action() -> void:
	if busy: return
	if held != null:
		move_marker.visible = false
		next_job = "drop"
		mode = Mode.LOWER_DROP
		target_lift = 1.2
		target_reach = 2.5
		target_curl = 0
	elif candidate != null:
		collect(candidate)

func collect(rock) -> void:
	if busy or held != null or not is_instance_valid(rock): return
	chosen = rock
	next_job = "pick"
	_plan_approach(rock.global_position)

func drop_at(point: Vector3) -> void:
	if busy or held == null: return
	next_job = "drop"
	chosen = null
	_plan_approach(point)

func _plan_approach(point: Vector3) -> void:
	focus_point = point
	var away := global_position-point
	away.y = 0
	if away.length() < .2: away = Vector3.BACK
	destination = _clamp_ground(point+away.normalized()*4.05)
	if global_position.distance_to(destination)<.2:
		_begin_face()
	else:
		mode = Mode.GO
		move_marker.visible = true
		move_marker.global_position = Vector3(destination.x,.06,destination.z)

func _begin_face() -> void:
	if next_job == "pick":
		if not is_instance_valid(chosen):
			mode = Mode.IDLE
			return
		focus_point = chosen.global_position
	var offset := focus_point-global_position
	offset.y = 0
	desired_yaw = atan2(-offset.x,-offset.z)+atan2(.35,maxf(.5,offset.length()))
	mode = Mode.FACE

func go_to(point: Vector3) -> void:
	if busy: return
	destination = _clamp_ground(point)
	next_job = ""
	chosen = null
	mode = Mode.GO
	move_marker.visible = true
	move_marker.global_position = destination+Vector3(0,.06,0)

func _clamp_ground(point: Vector3) -> Vector3:
	return Vector3(clampf(point.x,-Play.DRIVE_X,Play.DRIVE_X),0,clampf(point.z,-Play.DRIVE_Z,Play.DRIVE_Z))

func cancel_movement() -> void:
	touch_direction = Vector2.ZERO
	if mode == Mode.GO:
		mode = Mode.IDLE
		move_marker.visible = false
	velocity = Vector3.ZERO

func reset_vehicle() -> void:
	held = null
	chosen = null
	candidate = null
	mode = Mode.IDLE
	busy = false
	next_job = ""
	touch_direction = Vector2.ZERO
	position = Play.START
	rotation = Vector3(0,-.48,0)
	velocity = Vector3.ZERO
	drive_speed = 0
	lift = 1.7
	reach = 2.5
	curl = 0
	target_lift = lift
	target_reach = reach
	target_curl = curl
	move_marker.visible = false
	_solve_arm()

func _cache_wheels(node: Node) -> void:
	if "wheel" in String(node.name) and node is Node3D:
		wheels.append(node)
	for child in node.get_children(): _cache_wheels(child)
