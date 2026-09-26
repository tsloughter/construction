extends RigidBody3D

var delivered := false
var carried := false
var ever_carried := false
var settle_time := 0.0
var spawn_point := Vector3.ZERO
var rock_id := 0
var size_factor := 1.0

func _ready() -> void:
	spawn_point = global_position
	mass = 180.0 * size_factor
	collision_layer = 4
	collision_mask = 7
	continuous_cd = true
	linear_damp = .32
	angular_damp = 1.4
	var physics := PhysicsMaterial.new()
	physics.friction = .86
	physics.bounce = .08
	physics_material_override = physics
	var art := preload("res://assets/models/boulder.glb").instantiate() as Node3D
	add_child(art)
	art.scale = Vector3.ONE * size_factor
	var mesh_instance := _find_mesh(art)
	var collider := CollisionShape3D.new()
	var hull := mesh_instance.mesh.create_convex_shape()
	var scaled_points := hull.points
	for i in scaled_points.size():
		scaled_points[i] *= size_factor
	hull.points = scaled_points
	collider.shape = hull
	add_child(collider)
	add_to_group("boulders")

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_mesh(child)
		if found != null:
			return found
	return null

func attach_to_bucket() -> void:
	carried = true
	ever_carried = true
	delivered = false
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
	angular_velocity = Vector3(.3, .15, .2)

func reset_rock() -> void:
	carried = false
	ever_carried = false
	delivered = false
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
	if carried:
		return
	if global_position.y < -8 or absf(global_position.x) > 40 or absf(global_position.z) > 40:
		reset_rock()
	var p := global_position - Vector3(8,0,-8)
	# Stacked material counts too, provided the rigid body has actually settled.
	var in_zone := absf(p.x) < 2.8 and absf(p.z) < 2.8 and p.y < 3.5
	if in_zone and ever_carried and linear_velocity.length() < .45:
		settle_time += delta
		delivered = settle_time > 1.0
	else:
		settle_time = 0
		delivered = false
