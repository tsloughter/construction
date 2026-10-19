class_name Geo
extends RefCounted

static func material(color: Color, roughness: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metal
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, collision: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	if collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		node.add_child(body)
		body.add_child(shape)
	return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, top: float = -1.0, segments: int = 16) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	return node

static func beam(parent: Node3D, a: Vector3, b: Vector3, width: float, mat: Material) -> MeshInstance3D:
	var node := box(parent, (a + b) * 0.5, Vector3(width, width, a.distance_to(b)), mat)
	if a.distance_to(b) > 0.001:
		node.look_at_from_position((a + b) * 0.5, b, Vector3.FORWARD if absf((b - a).normalized().y) > 0.99 else Vector3.UP)
	return node

static func label(parent: Node3D, text: String, pos: Vector3, size: int, color: Color) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font = preload("res://assets/fonts/Roboto-Bold.ttf")
	node.font_size = size
	node.pixel_size = 0.012
	node.modulate = color
	node.outline_size = 0
	parent.add_child(node)
	node.position = pos
	return node

static func star(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 10:
		var a := -PI/2+TAU*i/10
		var b := -PI/2+TAU*(i+1)/10
		var ra := radius if i%2 == 0 else radius*.46
		var rb := radius if (i+1)%2 == 0 else radius*.46
		surface.add_vertex(Vector3.ZERO)
		surface.add_vertex(Vector3(cos(b)*rb,-sin(b)*rb,0))
		surface.add_vertex(Vector3(cos(a)*ra,-sin(a)*ra,0))
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = mat
	parent.add_child(instance)
	instance.position = pos
	return instance

static func ring(parent: Node3D, radius: float, color: Color, segments: int = 40) -> Node3D:
	var node := Node3D.new()
	parent.add_child(node)
	var m := material(color)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in segments:
		var a := TAU * i / segments
		var b := TAU * (i + 0.7) / segments
		beam(node, Vector3(cos(a)*radius,0,sin(a)*radius), Vector3(cos(b)*radius,0,sin(b)*radius), .035, m)
	return node
