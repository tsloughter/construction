extends CharacterBody3D

const Play = preload("res://scripts/playground.gd")
const Layout = preload("res://scripts/dozer_layout.gd")
const Geo = preload("res://scripts/geometry.gd")
enum Mode { IDLE, GO, APPROACH, PUSH }
var mode := Mode.IDLE
var busy := false
var moving := false
var drive_speed := 0.0
var touch_direction := Vector2.ZERO
var destination := Vector3.ZERO
var chosen
var hole
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
	marker = Geo.ring(get_parent(),.9,Color("fff3c6"),28)
	marker.visible = false

func _add_shape(dimensions: Vector3, at: Vector3) -> void:
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	collider.shape = box
	collider.position = at
	add_child(collider)

func _physics_process(delta: float) -> void:
	var keys := Input.get_vector("left","right","up","down")
	var direction := keys if keys.length()>.05 else touch_direction
	var travel := Vector3.ZERO
	if direction.length()>.05:
		cancel_movement(false)
		travel = Vector3(direction.x,0,direction.y).limit_length(1)
	elif mode == Mode.GO:
		travel = _toward(destination)
		if _flat_distance(destination,position)<.16: cancel_movement()
	elif mode in [Mode.APPROACH,Mode.PUSH]:
		assist_time += delta
		if not is_instance_valid(chosen) or chosen.completed or not is_instance_valid(hole) or hole.filled or assist_time>45:
			cancel_movement()
		elif mode == Mode.APPROACH:
			if not waypoints.is_empty():
				travel = _toward(waypoints[0])
				if _flat_distance(position,waypoints[0])<.2: waypoints.pop_front()
			else: mode = Mode.PUSH
		else:
			var push_direction: Vector3 = hole.global_position-chosen.global_position
			push_direction.y = 0
			push_direction = push_direction.normalized()
			var behind: Vector3 = chosen.global_position-push_direction*2.65
			travel = _toward(behind)
			# A small forward bias maintains contact with the broad blade.
			if _flat_distance(position,behind)<.65: travel = push_direction
	if travel.length()>.01:
		var yaw := atan2(-travel.x,-travel.z)
		rotation.y = lerp_angle(rotation.y,yaw,1-exp(-delta*10))
	velocity = Vector3(travel.x*2.8,-1 if is_on_floor() else velocity.y-delta*9.8,travel.z*2.8)
	# Physical impulses, never attachment: pebbles can roll away from the blade.
	for rock in get_tree().get_nodes_in_group("boulders"):
		if rock.completed: continue
		var local := to_local(rock.global_position)
		if absf(local.x)<2.25 and local.z< -1.65 and local.z> -3.2 and rock.position.y>-.25 and travel.dot(-global_basis.z)>.5:
			var forward := -global_basis.z
			var desired := forward*2.75-global_basis.x*local.x*.65
			var impulse: Vector3 = (desired-Vector3(rock.linear_velocity.x,0,rock.linear_velocity.z))*rock.mass*minf(1,delta*9)
			rock.apply_central_impulse(impulse)
	move_and_slide()
	for i in get_slide_collision_count():
		var contact := get_slide_collision(i)
		var rock := contact.get_collider() as RigidBody3D
		if rock and not rock.freeze and travel.length()>.01:
			var push := -contact.get_normal()
			push.y = 0
			if push.length()>.01 and push.dot(travel)>.1:
				rock.apply_central_impulse(push.normalized()*rock.mass*delta*12)
	position.x = clampf(position.x,-Play.DRIVE_X,Play.DRIVE_X)
	position.z = clampf(position.z,-Play.DRIVE_Z,Play.DRIVE_Z)
	drive_speed = Vector2(velocity.x,velocity.z).length()
	moving = travel.length()>.05
	marker.visible = is_instance_valid(chosen) and not chosen.completed
	if marker.visible: marker.global_position = Vector3(chosen.position.x,.06,chosen.position.z)
	if Input.is_action_just_pressed("scoop"): action()

func has_load() -> bool:
	return false

func _toward(point: Vector3) -> Vector3:
	var offset := point-position
	offset.y = 0
	return offset.normalized()*minf(1,offset.length()*3)

func _flat_distance(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()

func action() -> void:
	var nearest
	var distance := INF
	for rock in get_tree().get_nodes_in_group("boulders"):
		if not rock.completed and _flat_distance(position,rock.position)<distance:
			nearest = rock
			distance = _flat_distance(position,rock.position)
	if nearest: push_rock(nearest)

func push_rock(rock) -> void:
	if rock.completed: return
	cancel_movement()
	var distance := INF
	for target in get_tree().get_nodes_in_group("holes"):
		if not target.filled and _flat_distance(rock.position,target.global_position)<distance:
			hole = target
			distance = _flat_distance(rock.position,target.global_position)
	if hole == null: return
	chosen = rock
	var forward: Vector3 = hole.global_position-rock.position
	forward.y = 0
	forward = forward.normalized()
	var behind: Vector3 = rock.position-forward*3.4
	behind.y = 0
	behind.x = clampf(behind.x,-Play.DRIVE_X,Play.DRIVE_X)
	behind.z = clampf(behind.z,-Play.DRIVE_Z,Play.DRIVE_Z)
	# Approach around a rock when starting in front of it.
	var relative: Vector3 = position-rock.position
	if relative.dot(forward)>-2.4:
		var side := Vector3(forward.z,0,-forward.x)
		if relative.dot(side)<0: side = -side
		var flank: Vector3 = rock.position+side*3.8-forward*3.2
		flank.x = clampf(flank.x,-Play.DRIVE_X,Play.DRIVE_X)
		flank.z = clampf(flank.z,-Play.DRIVE_Z,Play.DRIVE_Z)
		flank.y = 0
		waypoints.append(flank)
	waypoints.append(behind)
	mode = Mode.APPROACH

func go_to(point: Vector3) -> void:
	cancel_movement()
	destination = Vector3(clampf(point.x,-Play.DRIVE_X,Play.DRIVE_X),0,clampf(point.z,-Play.DRIVE_Z,Play.DRIVE_Z))
	mode = Mode.GO

func cancel_movement(release_touch: bool = true) -> void:
	mode = Mode.IDLE
	chosen = null
	hole = null
	waypoints.clear()
	assist_time = 0
	if release_touch: touch_direction = Vector2.ZERO
	velocity = Vector3.ZERO
	moving = false

func reset_vehicle() -> void:
	cancel_movement()
	position = Layout.START
	rotation = Vector3.ZERO
