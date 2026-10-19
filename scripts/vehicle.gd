class_name Vehicle
extends CharacterBody3D

# Shared driving state for the three toy machines. Screen directions map
# straight onto the ground plane; there is no reversing or steering to learn.
var touch_direction := Vector2.ZERO
var busy := false
var moving := false
var drive_speed := 0.0
var wheels: Array[Node3D] = []

func has_load() -> bool:
	return false

func action() -> void:
	pass

func go_to(_point: Vector3) -> void:
	pass

func cancel_movement(release_touch: bool = true) -> void:
	if release_touch: touch_direction = Vector2.ZERO
	velocity = Vector3.ZERO
	moving = false

func reset_vehicle() -> void:
	cancel_movement()

func _input_direction() -> Vector2:
	var keys := Input.get_vector("left","right","up","down")
	return keys if keys.length() > .05 else touch_direction

func _drive(travel: Vector3, speed: float, delta: float) -> void:
	# Sliding up a rock leaves move_and_slide with an upward velocity; never
	# keep it, or the toy launches into the air instead of settling back down.
	velocity = Vector3(travel.x*speed,-1.0 if is_on_floor() else minf(0.0,velocity.y)-delta*9.8,travel.z*speed)
	move_and_slide()
	position.x = clampf(position.x,-Playground.DRIVE_X,Playground.DRIVE_X)
	position.z = clampf(position.z,-Playground.DRIVE_Z,Playground.DRIVE_Z)
	drive_speed = Vector2(velocity.x,velocity.z).length()

# Any Node3D with "wheel" in its name rolls; its local Y axis is the axle.
func _collect_wheels(node: Node) -> void:
	if node is Node3D and "wheel" in String(node.name).to_lower():
		wheels.append(node)
		return
	for child in node.get_children(): _collect_wheels(child)

func _spin_wheels(radius: float, delta: float) -> void:
	var forward := Vector2(velocity.x,velocity.z).dot(Vector2(-global_basis.z.x,-global_basis.z.z))
	for wheel in wheels:
		# The axle may point along either side of the body depending on the model.
		var axle := signf(wheel.global_basis.y.dot(global_basis.x))
		wheel.rotate_object_local(Vector3.UP,-axle*forward/radius*delta)

static func clamp_to_yard(point: Vector3) -> Vector3:
	return Vector3(clampf(point.x,-Playground.DRIVE_X,Playground.DRIVE_X),0,clampf(point.z,-Playground.DRIVE_Z,Playground.DRIVE_Z))
