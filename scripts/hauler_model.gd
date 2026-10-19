class_name HaulerModel
extends Node3D

# Original toy vehicles built from the same rounded block as the job-site props.
var kind := "loader"
var arm: Node3D
var bucket: Node3D
var bed: Node3D
var cargo: Node3D
var wheels: Array[Node3D] = []
var block_mesh: Mesh
var yellow := Geo.material(Color("efbc55"))
var orange := Geo.material(Color("e99a50"))
var teal := Geo.material(Color("65afa9"))
var dark := Geo.material(Color("354e68"))
var glass := Geo.material(Color("a6dce7"))
var dirt := Geo.material(Color("a97950"))

func _ready() -> void:
	var source := preload("res://assets/models/site_block.glb").instantiate()
	block_mesh = _mesh(source)
	source.free()
	_block(self,Vector3(0,.7,0),Vector3(2.15,.48,3.35),dark)
	for x in [-1.17,1.17]:
		for z in ([-1.05,1.05] if kind == "loader" else [-1.3,.7,1.6]):
			var wheel := Geo.cylinder(self,Vector3(x,.65,z),.64,.42,dark,-1,24)
			wheel.rotation.z = PI/2
			wheels.append(wheel)
			var hub := Geo.cylinder(self,Vector3(x+signf(x)*.23,.65,z),.30,.035,yellow,-1,24)
			hub.rotation.z = PI/2
	if kind == "loader": _loader()
	else: _truck()

func _mesh(node: Node) -> Mesh:
	if node is MeshInstance3D: return node.mesh
	for child in node.get_children():
		var result := _mesh(child)
		if result: return result
	return null

func _block(parent: Node3D, at: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = block_mesh
	part.material_override = mat
	parent.add_child(part)
	part.position = at
	part.scale = dimensions
	return part

func _beam(parent: Node3D, a: Vector3, b: Vector3, width: float, mat: Material) -> void:
	var part := _block(parent,(a+b)*.5,Vector3(width,width,a.distance_to(b)),mat)
	part.quaternion = Quaternion(Vector3.FORWARD,(b-a).normalized())

func _cab(at: Vector3, color: Material) -> void:
	_block(self,at,Vector3(1.8,1.45,1.4),color)
	_block(self,at+Vector3(0,.16,-.73),Vector3(1.48,.78,.08),glass)
	for x in [-.93,.93]:
		_block(self,at+Vector3(x,.16,0),Vector3(.08,.78,1.1),glass)
	for x in [-.34,.34]:
		var eye := Geo.cylinder(self,at+Vector3(x,.22,-.79),.17,.045,Geo.material(Color("fffaed")),-1,20)
		eye.rotation.x = PI/2
		var pupil := Geo.cylinder(self,at+Vector3(x,.21,-.82),.085,.035,dark,-1,16)
		pupil.rotation.x = PI/2
	_block(self,at+Vector3(0,-.09,-.79),Vector3(.32,.065,.04),dark)
	_block(self,at+Vector3(0,.8,0),Vector3(2.06,.19,1.65),color)
	Geo.cylinder(self,at+Vector3(.5,1.01,.1),.16,.23,orange)

func _loader() -> void:
	_block(self,Vector3(0,1.12,.8),Vector3(2.2,.65,1.8),yellow)
	_cab(Vector3(0,1.97,.05),yellow)
	arm = Node3D.new()
	add_child(arm)
	arm.position = Vector3(0,1.0,-.1)
	for x in [-.85,.85]:
		_beam(arm,Vector3(x,0,0),Vector3(x,-.5,-2.3),.23,yellow)
		_beam(arm,Vector3(x,.15,-.2),Vector3(x,-.24,-1.55),.10,dark)
	bucket = Node3D.new()
	arm.add_child(bucket)
	bucket.position = Vector3(0,-.5,-2.3)
	_block(bucket,Vector3(0,0,-.35),Vector3(2.6,.16,1.25),orange)
	_block(bucket,Vector3(0,.39,.22),Vector3(2.6,.85,.18),yellow)
	for x in [-1.22,1.22]:
		_block(bucket,Vector3(x,.28,-.35),Vector3(.16,.65,1.25),yellow)
	for x in [-.95,-.48,0,.48,.95]:
		_block(bucket,Vector3(x,-.01,-1.04),Vector3(.24,.13,.32),dark)
	cargo = dirt_clumps(bucket,Vector3(0,.25,-.34),Vector3(.9,.32,.36),12)
	cargo.visible = false

func _truck() -> void:
	_cab(Vector3(0,1.83,-1.35),teal)
	_block(self,Vector3(0,1.03,-2.13),Vector3(2.3,.42,.3),teal)
	for x in [-.78,.78]:
		_block(self,Vector3(x,1.2,-2.31),Vector3(.35,.24,.07),Geo.material(Color("fff1b8")))
	bed = Node3D.new()
	add_child(bed)
	bed.position = Vector3(0,1.19,1.95)
	_block(bed,Vector3(0,0,-1.35),Vector3(2.65,.19,2.9),orange)
	for x in [-1.3,1.3]:
		_block(bed,Vector3(x,.55,-1.35),Vector3(.17,1.14,2.9),yellow)
		for z in [-2.4,-1.4,-.4]:
			_block(bed,Vector3(x*1.075,.5,z),Vector3(.13,.8,.13),orange)
	_block(bed,Vector3(0,.55,-2.8),Vector3(2.6,1.14,.16),yellow)
	# Short tail lip leaves a visible opening for the tipped dirt.
	_block(bed,Vector3(0,.18,.08),Vector3(2.6,.4,.16),yellow)
	cargo = dirt_clumps(bed,Vector3(0,.33,-1.35),Vector3(1.05,.55,1.15),24)
	cargo.visible = false

static func dirt_clumps(parent: Node3D, at: Vector3, dimensions: Vector3, count: int) -> Node3D:
	var cluster := Node3D.new()
	parent.add_child(cluster)
	cluster.position = at
	var mat := Geo.material(Color("a97950"))
	for i in count:
		var clump := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1
		mesh.height = 2
		mesh.radial_segments = 12
		mesh.rings = 6
		clump.mesh = mesh
		clump.material_override = mat
		cluster.add_child(clump)
		var angle := i*2.39996
		var radius := sqrt(float(i)/count)
		clump.position = Vector3(cos(angle)*radius*dimensions.x,dimensions.y*(1-radius*.7),sin(angle)*radius*dimensions.z)
		clump.scale = Vector3(.48,.36,.44)*(.75+float(i%4)*.12)
	return cluster

func set_load(amount: float) -> void:
	cargo.visible = amount>0
	cargo.scale.y = maxf(.15,amount)

func set_lift(amount: float, tip: float = 0) -> void:
	if not arm: return
	arm.rotation.x = amount*.95
	bucket.rotation.x = -amount*.55-tip
