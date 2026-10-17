extends "res://scripts/boulder.gd"

var completed := false

func _ready() -> void:
	super._ready()
	mass = 4
	collision_mask = 14
	linear_damp = .9
	angular_damp = 1.6
	physics_material_override.friction = .45
	physics_material_override.bounce = .03

func _physics_process(_delta: float) -> void:
	if completed: return
	for hole in get_tree().get_nodes_in_group("holes"):
		if hole.filled: continue
		var offset := Vector2(global_position.x-hole.global_position.x,global_position.z-hole.global_position.z)
		if offset.length()<1.25 and global_position.y<-.58:
			hole.fill(self)
			return
	if position.y < -3 or absf(position.x)>11.5 or absf(position.z)>8:
		reset_rock()

func reset_rock(_clear_reward: bool = true) -> void:
	completed = false
	super.reset_rock()
	collision_mask = 14
