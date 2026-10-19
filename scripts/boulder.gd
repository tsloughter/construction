class_name Boulder
extends RigidBody3D

# Reports once when the pebble has come to rest inside the material bay.
signal settled

var carried := false
var ever_carried := false
var rewarded := false
var settled_in_garden := false
var settle_time := 0.0
var spawn_point := Vector3.ZERO
var rock_id := 0

func _ready() -> void:
	spawn_point = global_position
	mass = 10
	collision_layer = 4
	collision_mask = 7
	continuous_cd = true
	linear_damp = 1.4
	angular_damp = 2.6
	var physics := PhysicsMaterial.new()
	physics.friction = .9
	physics.bounce = .12
	physics_material_override = physics
	var art := preload("res://assets/models/boulder.glb").instantiate() as Node3D
	add_child(art)
	var mesh_instance := _find_mesh(art)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Playground.COLORS[rock_id]
	mat.roughness = .9
	mesh_instance.material_override = mat
	var collider := CollisionShape3D.new()
	collider.shape = mesh_instance.mesh.create_convex_shape()
	add_child(collider)
	add_to_group("boulders")

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D: return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_mesh(child)
		if found != null: return found
	return null

func attach_to_bucket() -> void:
	carried = true
	ever_carried = true
	settled_in_garden = false
	settle_time = 0
	freeze = true
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func release_from_bucket(launch_velocity: Vector3) -> void:
	carried = false
	collision_layer = 4
	collision_mask = 7
	freeze = false
	sleeping = false
	linear_velocity = launch_velocity
	angular_velocity = Vector3(.1,.2,.1)

func reset_rock(clear_reward: bool = true) -> void:
	carried = false
	if clear_reward:
		rewarded = false
		ever_carried = false
	settled_in_garden = false
	settle_time = 0
	freeze = true
	global_position = spawn_point
	global_rotation = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 4
	collision_mask = 7
	freeze = false
	sleeping = false

func _physics_process(delta: float) -> void:
	if carried: return
	# A lost toy quietly comes back. Children never need a recovery command.
	if position.y < -3 or absf(position.x)>11.5 or absf(position.z)>8.0:
		reset_rock(false)
	var offset := Vector2(position.x-Playground.DROP_CENTER.x,position.z-Playground.DROP_CENTER.z)
	if ever_carried and offset.length()<Playground.DROP_RADIUS and position.y<3 and linear_velocity.length()<.5:
		settle_time += delta
		if not settled_in_garden and settle_time>.4:
			settled_in_garden = true
			settled.emit()
	else:
		settle_time = 0
		settled_in_garden = false
