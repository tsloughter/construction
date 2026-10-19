class_name Vehicle
extends CharacterBody3D

# Shared driving state for the three toy machines. Screen directions map
# straight onto the ground plane; there is no reversing or steering to learn.
var touch_direction := Vector2.ZERO
var busy := false
var moving := false
var drive_speed := 0.0

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

static func clamp_to_yard(point: Vector3) -> Vector3:
	return Vector3(clampf(point.x,-Playground.DRIVE_X,Playground.DRIVE_X),0,clampf(point.z,-Playground.DRIVE_Z,Playground.DRIVE_Z))
