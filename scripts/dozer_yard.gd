extends "res://scripts/yard.gd"

const Layout = preload("res://scripts/dozer_layout.gd")
const Hole = preload("res://scripts/fill_hole.gd")

func _ground() -> void:
	# Layer 1 supports the vehicle everywhere. Rocks use the perforated layer 8.
	super._ground()
	var faces := PackedVector3Array()
	# Three adjacent square patches, each with a circular opening.
	for center in Layout.HOLES:
		var angles: Array[float] = []
		for i in 64: angles.append(TAU*i/64)
		for x in [-3.0,3.0]:
			for z in [-2.8,2.8]: angles.append(fposmod(atan2(z,x),TAU))
		angles.sort()
		for i in angles.size():
			var a := Vector3(cos(angles[i]),0,sin(angles[i]))
			var b := Vector3(cos(angles[(i+1)%angles.size()]),0,sin(angles[(i+1)%angles.size()]))
			var outer_a := a*minf(3.0/maxf(.0001,absf(a.x)),2.8/maxf(.0001,absf(a.z)))
			var outer_b := b*minf(3.0/maxf(.0001,absf(b.x)),2.8/maxf(.0001,absf(b.z)))
			for p in [a*Layout.RADIUS,outer_a,outer_b,a*Layout.RADIUS,outer_b,b*Layout.RADIUS]: faces.append(center+p)
	_rect(faces,-16.5,-9,-16.6,12.4)
	_rect(faces,9,16.5,-16.6,12.4)
	_rect(faces,-9,9,-16.6,-7.2)
	_rect(faces,-9,9,-1.6,12.4)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in faces:
		surface.set_normal(Vector3.UP)
		surface.add_vertex(p)
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	var mat := Geo.material(Color("cbb388"))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ground.material_override = mat
	add_child(ground)
	var body := StaticBody3D.new()
	body.collision_layer = 8
	body.collision_mask = 4
	var collider := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	for i in 3:
		var hole := Hole.new()
		hole.position = Layout.HOLES[i]
		hole.name = "Hole%d"%(i+1)
		add_child(hole)

func _base_ground() -> void:
	var support := Geo.box(self,Vector3(0,-.26,0),Vector3(160,.5,160),dirt,true)
	support.visible = false
	var grass := Geo.material(Color("7fa990"))
	for side in [-1,1]:
		Geo.box(self,Vector3(side*48.25,-.26,0),Vector3(63.5,.5,160),grass)
	Geo.box(self,Vector3(0,-.26,-48.3),Vector3(33,.5,63.4),grass)
	Geo.box(self,Vector3(0,-.26,46.2),Vector3(33,.5,67.6),grass)

func _rect(faces: PackedVector3Array, x0: float, x1: float, z0: float, z1: float) -> void:
	for p in [Vector3(x0,0,z0),Vector3(x1,0,z1),Vector3(x0,0,z1),Vector3(x0,0,z0),Vector3(x1,0,z0),Vector3(x1,0,z1)]: faces.append(p)

func _delivery_bay() -> void:
	pass

func _process(_delta: float) -> void:
	pass
