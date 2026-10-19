class_name HaulerVehicle
extends Vehicle

signal action_requested
signal arrived
signal manual_takeover

const WHEEL_RADIUS := .64
var kind := "loader"
var model: HaulerModel
var active := false
var loaded := false
var waypoints: Array[Vector3] = []
var final_yaw := 0.0
var navigating := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(2.5,1.4,3.6 if kind == "loader" else 4.3)
	shape.shape = bounds
	shape.position.y = .7
	add_child(shape)
	model = HaulerModel.new()
	model.kind = kind
	add_child(model)

func _physics_process(delta: float) -> void:
	var travel := Vector3.ZERO
	if active and not busy:
		var direction := _input_direction()
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
	_drive(travel,3.8,delta)
	if position.y< -2: position.y = 0
	moving = travel.length()>.05
	var forward_speed := Vector2(velocity.x,velocity.z).dot(Vector2(-global_basis.z.x,-global_basis.z.z))
	for wheel in model.wheels:
		wheel.rotate_object_local(Vector3.UP,-forward_speed/WHEEL_RADIUS*delta)
	if active and not busy and Input.is_action_just_pressed("scoop"): action()

func has_load() -> bool:
	return loaded

func action() -> void:
	if not busy: action_requested.emit()

func go_to(point: Vector3) -> void:
	navigate([Vehicle.clamp_to_yard(point)],rotation.y)

func navigate(points: Array, yaw: float) -> void:
	cancel_movement()
	waypoints.assign(points)
	final_yaw = yaw
	navigating = true

func cancel_movement(release_touch: bool = true) -> void:
	waypoints.clear()
	navigating = false
	super(release_touch)

func reset_vehicle() -> void:
	cancel_movement()
	busy = false
	loaded = false
	rotation = Vector3.ZERO
	model.set_load(0)
	if kind == "loader": model.set_lift(0)
	else: model.bed.rotation.x = 0
