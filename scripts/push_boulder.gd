class_name PushBoulder
extends Boulder

# Emitted once by the hole that swallowed this boulder.
signal dropped_in_hole

var completed := false

func _ready() -> void:
	super()
	mass = 4
	collision_mask = 14
	linear_damp = .9
	angular_damp = 1.6
	physics_material_override.friction = .45
	physics_material_override.bounce = .03

func _physics_process(_delta: float) -> void:
	if completed: return
	if position.y < -3 or absf(position.x)>11.5 or absf(position.z)>8:
		reset_rock()

func complete() -> void:
	completed = true
	freeze = true
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	dropped_in_hole.emit()

func reset_rock(clear_reward: bool = true) -> void:
	completed = false
	super(clear_reward)
	collision_mask = 14
