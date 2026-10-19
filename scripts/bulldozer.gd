class_name Bulldozer
extends Vehicle

enum Mode { IDLE, GO, APPROACH, PUSH }
# Far enough behind a rock that the blade's corner clears it while the
# bulldozer turns to face it, so a turn never flings the rock away.
const STANDOFF := 4.2
const ASSIST_LIMIT := 45.0
# Turning is capped so the broad blade sweeps gently through a nearby rock
# instead of flinging it across the yard.
const TURN_RATE := 4.0
const WHEEL_RADIUS := .34
var mode := Mode.IDLE
var destination := Vector3.ZERO
var chosen: PushBoulder
var hole: FillHole
var waypoints: Array[Vector3] = []
var marker: Node3D
var model: Node3D
var assist_time := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 5
	_add_shape(Vector3(2.85,1.0,3.15),Vector3(0,.55,0))
	_add_shape(Vector3(3.85,.9,.35),Vector3(0,.55,-2.05))
	model = preload("res://assets/models/bulldozer.glb").instantiate()
	add_child(model)
	_collect_wheels(model)
	marker = Geo.ring(self,.9,Color("fff3c6"),28)
	marker.top_level = true
	marker.visible = false

func _add_shape(dimensions: Vector3, at: Vector3) -> void:
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	collider.shape = box
	collider.position = at
	add_child(collider)

func _physics_process(delta: float) -> void:
	var direction := _input_direction()
	var travel := Vector3.ZERO
	if direction.length()>.05:
		cancel_movement(false)
		travel = Vector3(direction.x,0,direction.y).limit_length(1)
	elif mode == Mode.GO:
		travel = _toward(destination)
		if _flat_distance(destination,position)<.16: cancel_movement()
	elif mode in [Mode.APPROACH,Mode.PUSH]:
		assist_time += delta
		if not is_instance_valid(chosen) or chosen.completed or not is_instance_valid(hole) or hole.filled or assist_time>ASSIST_LIMIT:
			cancel_movement()
		elif mode == Mode.APPROACH:
			if not waypoints.is_empty():
				travel = _toward(waypoints[0])
				if _flat_distance(position,waypoints[0])<.2: waypoints.pop_front()
			else: mode = Mode.PUSH
		else:
			var push_direction := hole.global_position-chosen.global_position
			push_direction.y = 0
			push_direction = push_direction.normalized()
			var relative := position-chosen.global_position
			relative.y = 0
			if relative.dot(push_direction)>-1.2:
				# The rock slipped beside or behind the blade: line up again from behind.
				_replan()
			else:
				var behind := chosen.global_position-push_direction*2.65
				travel = _toward(behind)
				# A small forward bias maintains contact with the broad blade.
				if _flat_distance(position,behind)<.65: travel = push_direction
	if travel.length()>.01:
		var yaw := atan2(-travel.x,-travel.z)
		var eased := lerp_angle(rotation.y,yaw,1-exp(-delta*10))
		rotation.y = rotate_toward(rotation.y,eased,delta*TURN_RATE)
	# Physical impulses, never attachment: pebbles can roll away from the blade.
	for rock: PushBoulder in get_tree().get_nodes_in_group("boulders"):
		if rock.completed: continue
		var local := to_local(rock.global_position)
		if absf(local.x)<2.25 and local.z< -1.65 and local.z> -3.2 and rock.position.y>-.25 and travel.dot(-global_basis.z)>.5:
			var forward := -global_basis.z
			var desired := forward*2.75-global_basis.x*local.x*.65
			var impulse := (desired-Vector3(rock.linear_velocity.x,0,rock.linear_velocity.z))*rock.mass*minf(1,delta*9)
			rock.apply_central_impulse(impulse)
	_drive(travel,2.8,delta)
	for i in get_slide_collision_count():
		var contact := get_slide_collision(i)
		var rock := contact.get_collider() as RigidBody3D
		if rock and not rock.freeze and travel.length()>.01:
			var push := -contact.get_normal()
			push.y = 0
			if push.length()>.01 and push.dot(travel)>.1:
				rock.apply_central_impulse(push.normalized()*rock.mass*delta*12)
	moving = travel.length()>.05
	_spin_wheels(WHEEL_RADIUS,delta)
	marker.visible = is_instance_valid(chosen) and not chosen.completed
	if marker.visible: marker.global_position = Vector3(chosen.position.x,.06,chosen.position.z)
	if Input.is_action_just_pressed("scoop"): action()

func _toward(point: Vector3) -> Vector3:
	var offset := point-position
	offset.y = 0
	return offset.normalized()*minf(1,offset.length()*3)

func _flat_distance(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()

func action() -> void:
	var nearest: PushBoulder
	var distance := INF
	for rock: PushBoulder in get_tree().get_nodes_in_group("boulders"):
		if not rock.completed and _flat_distance(position,rock.position)<distance:
			nearest = rock
			distance = _flat_distance(position,rock.position)
	if nearest: push_rock(nearest)

func push_rock(rock: PushBoulder) -> void:
	if rock.completed: return
	cancel_movement()
	var distance := INF
	for target: FillHole in get_tree().get_nodes_in_group("holes"):
		if not target.filled and _flat_distance(rock.position,target.global_position)<distance:
			hole = target
			distance = _flat_distance(rock.position,target.global_position)
	if hole == null: return
	chosen = rock
	var forward := hole.global_position-rock.position
	forward.y = 0
	forward = forward.normalized()
	var behind := Vehicle.clamp_to_yard(rock.position-forward*STANDOFF)
	# Approach around a rock when starting in front of it.
	var relative := position-rock.position
	if relative.dot(forward)>-2.4:
		var side := Vector3(forward.z,0,-forward.x)
		if relative.dot(side)<0: side = -side
		waypoints.append(Vehicle.clamp_to_yard(rock.position+side*STANDOFF-forward*3.2))
	waypoints.append(behind)
	mode = Mode.APPROACH

func _replan() -> void:
	# Keep the assist clock running so re-planning cannot extend help forever.
	var elapsed := assist_time
	var rock := chosen
	push_rock(rock)
	assist_time = elapsed

func go_to(point: Vector3) -> void:
	cancel_movement()
	destination = Vehicle.clamp_to_yard(point)
	mode = Mode.GO

func cancel_movement(release_touch: bool = true) -> void:
	mode = Mode.IDLE
	chosen = null
	hole = null
	waypoints.clear()
	assist_time = 0
	super(release_touch)

func reset_vehicle() -> void:
	cancel_movement()
	position = DozerLayout.START
	rotation = Vector3.ZERO
