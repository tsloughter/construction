extends CharacterBody3D

const Model = preload("res://scripts/hauler_model.gd")
const Play = preload("res://scripts/playground.gd")
var kind := "loader"
var model
var active := false
var held = null
var busy := false
var moving := false
var drive_speed := 0.0
var touch_direction := Vector2.ZERO
var waypoints: Array[Vector3] = []
var final_yaw := 0.0
var navigating := false
signal action_requested
signal arrived
signal manual_takeover

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(2.5,1.4,3.6 if kind == "loader" else 4.3)
	shape.shape = bounds
	shape.position.y = .7
	add_child(shape)
	model = Model.new()
	model.kind = kind
	add_child(model)

func _physics_process(delta: float) -> void:
	var travel := Vector3.ZERO
	if active and not busy:
		var keys := Input.get_vector("left","right","up","down")
		var direction := keys if keys.length()>.05 else touch_direction
		if direction.length()>.05:
			if navigating:
				cancel_movement(false)
				manual_takeover.emit()
			travel = Vector3(direction.x,0,direction.y).limit_length(1)
		elif navigating:
			if not waypoints.is_empty():
				var offset := waypoints[0]-position
				offset.y = 0
				travel = offset.normalized()*minf(1,offset.length()*3)
				if offset.length()<.14: waypoints.pop_front()
			else:
				rotation.y = lerp_angle(rotation.y,final_yaw,1-exp(-delta*12))
				if absf(angle_difference(rotation.y,final_yaw))<.025:
					navigating = false
					arrived.emit()
	if travel.length()>.01:
		rotation.y = lerp_angle(rotation.y,atan2(-travel.x,-travel.z),1-exp(-delta*10))
	velocity = Vector3(travel.x*3.8,-1 if is_on_floor() else velocity.y-delta*9.8,travel.z*3.8)
	move_and_slide()
	position.x = clampf(position.x,-Play.DRIVE_X,Play.DRIVE_X)
	position.z = clampf(position.z,-Play.DRIVE_Z,Play.DRIVE_Z)
	if position.y< -2: position.y = 0
	drive_speed = Vector2(velocity.x,velocity.z).length()
	moving = travel.length()>.05
	if active and not busy and Input.is_action_just_pressed("scoop"): action()

func action() -> void:
	if not busy: action_requested.emit()

func go_to(point: Vector3) -> void:
	navigate([Vector3(clampf(point.x,-Play.DRIVE_X,Play.DRIVE_X),0,clampf(point.z,-Play.DRIVE_Z,Play.DRIVE_Z))],rotation.y)

func navigate(points: Array, yaw: float) -> void:
	cancel_movement()
	for point in points: waypoints.append(point)
	final_yaw = yaw
	navigating = true

func cancel_movement(release_touch: bool = true) -> void:
	waypoints.clear()
	navigating = false
	velocity = Vector3.ZERO
	moving = false
	if release_touch: touch_direction = Vector2.ZERO

func reset_vehicle() -> void:
	cancel_movement()
	busy = false
	held = null
	rotation = Vector3.ZERO
	model.set_load(0)
	if kind == "loader": model.set_lift(0)
	else: model.bed.rotation.x = 0
