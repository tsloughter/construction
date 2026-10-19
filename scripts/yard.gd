extends Node3D

const Geo = preload("res://scripts/geometry.gd")
const Play = preload("res://scripts/playground.gd")
var goal_star: MeshInstance3D
var block_mesh: Mesh
var time := 0.0
var dirt := Geo.material(Color("cbb388"))
var pale := Geo.material(Color("f5edd4"))
var slate := Geo.material(Color("546b7d"))
var navy := Geo.material(Color("354e68"))
var orange := Geo.material(Color("ea985b"))
var yellow := Geo.material(Color("efbc55"))
var teal := Geo.material(Color("65afa9"))
var blue := Geo.material(Color("91c4d6"))
var concrete := Geo.material(Color("b2c0ba"))
var timber := Geo.material(Color("bf9267"))

func _ready() -> void:
	var block_source := preload("res://assets/models/site_block.glb").instantiate()
	block_mesh = _find_mesh(block_source)
	block_source.free()
	_lighting()
	_ground()
	_delivery_bay()
	_perimeter()
	_container(Vector3(-8.0,0,-10.8))
	_office(Vector3(9.0,0,-10.8))
	_building_frame(Vector3(.6,0,-11.0))
	_crane(Vector3(-1.0,0,-12.2))
	_materials()
	_tree(Vector3(-18.5,0,-11.5),1.3)
	_tree(Vector3(18.5,0,-14),1.4)
	_tree(Vector3(18.5,0,7),.9)
	_cloud(Vector3(-10,7,-24),pale)
	_cloud(Vector3(13,8,-26),pale)

func _find_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D: return node.mesh
	for child in node.get_children():
		var mesh := _find_mesh(child)
		if mesh != null: return mesh
	return null

func _block(pos: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = block_mesh
	instance.material_override = mat
	add_child(instance)
	instance.position = pos
	instance.scale = dimensions
	return instance

func _ground() -> void:
	# The work area is level with the surrounding land, with an open road entrance.
	_base_ground()
	var road := Geo.material(Color("829394"))
	Geo.box(self,Vector3(0,.012,11.8),Vector3(100,.035,5),road)
	Geo.box(self,Vector3(-3,.025,8.7),Vector3(5,.026,5),road)
	for i in 27:
		_block(Vector3(-39+i*3,.041,11.8),Vector3(1.4,.018,.12),pale)
	# Broad painted lanes and subtle tread marks make this read as a work yard.
	var worn := Geo.material(Color("bca57e"))
	for x in [-4.2,-1.8]:
		for i in 12:
			_block(Vector3(x,.02,7.7-i*.38),Vector3(.62,.016,.12),worn)
	for x in [-11.2,11.2]:
		for i in 7:
			_block(Vector3(x,.04,-6+i*1.8),Vector3(.1,.02,.6),pale)
	# A large entrance arrow painted on the road.
	_block(Vector3(-3,.06,9.1),Vector3(.24,.025,1.5),pale)
	for side in [-1,1]:
		Geo.beam(self,Vector3(-3,.065,8.3),Vector3(-3+side*.65,.065,8.95),.20,pale)

func _base_ground() -> void:
	Geo.box(self,Vector3(0,-.26,0),Vector3(160,.5,160),Geo.material(Color("7fa990")),true)
	Geo.box(self,Vector3(0,-.006,-2.1),Vector3(33,.03,29),dirt)

func _delivery_bay() -> void:
	# Same radius, star and game rules; now a painted material bay on a slab.
	var p := Play.DROP_CENTER
	_block(p+Vector3(0,.025,0),Vector3(7.35,.065,7.25),concrete)
	Geo.cylinder(self,p+Vector3(0,.068,0),Play.DROP_RADIUS,.018,Geo.material(Color("72c2a3")),-1,64)
	var ring := Geo.ring(self,Play.DROP_RADIUS-.2,Color("eaf5d8"),36)
	ring.position = p+Vector3(0,.09,0)
	for side in [-1,1]:
		for i in 6:
			_block(p+Vector3(side*3.45,.072,-2.9+i*1.15),Vector3(.11,.025,.65),pale)
			_block(p+Vector3(-2.9+i*1.15,.072,side*3.4),Vector3(.65,.025,.11),pale)
	goal_star = Geo.star(self,p+Vector3(0,2.35,-.3),.85,Geo.material(Color("ffdc63")))
	goal_star.rotation_degrees.x = -25
	# Cones sit behind the drive area, so automated carrying needs no path puzzle.
	_cone(Vector3(3.2,0,-8.6))
	_cone(Vector3(9,0,-8.6))

func _perimeter() -> void:
	# Friendly blue rails, with a broad open entrance along the road.
	for side in [-1,1]:
		for i in 9:
			var z := -15.5+i*2.7
			_block(Vector3(side*16,.66,z),Vector3(.16,1.32,.16),slate)
			if i<8:
				for h in [.4,.95]:
					_block(Vector3(side*16,h,z+1.35),Vector3(.1,.1,2.7),blue)
	for i in 12:
		_block(Vector3(-15.5+i*2.8,.66,-17),Vector3(.16,1.32,.16),slate)
		if i<11:
			for h in [.4,.95]:
				_block(Vector3(-14.1+i*2.8,h,-17),Vector3(2.8,.1,.1),blue)
	for x in [-11.8,8.0,13.0]:
		_barrier(Vector3(x,0,8.25))
	_cone(Vector3(-6.3,0,9.5))
	_cone(Vector3(.2,0,9.5))

func _container(p: Vector3) -> void:
	_block(p+Vector3(0,1.35,0),Vector3(6.6,2.7,3.5),teal)
	_block(p+Vector3(0,2.72,0),Vector3(6.85,.18,3.7),blue)
	for i in 16:
		_block(p+Vector3(-3.05+i*.4,1.4,1.78),Vector3(.075,2.34,.10),teal)
	for x in [-3.2,3.2]:
		_block(p+Vector3(x,1.4,1.81),Vector3(.12,2.55,.10),blue)
	_block(p+Vector3(0,1.57,1.87),Vector3(4.6,.61,.07),pale)
	var text := Geo.label(self,"LITTLE BUILDERS",p+Vector3(0,1.56,1.925),24,Color("35506a"))
	text.pixel_size = .0095
	# Side doors and chunky locking bars.
	for z in [-.82,.82]:
		_block(p+Vector3(3.35,1.3,z),Vector3(.09,2.4,1.56),blue)
		_block(p+Vector3(3.42,1.3,z),Vector3(.08,1.85,.08),pale)

func _office(p: Vector3) -> void:
	_block(p+Vector3(0,1.25,0),Vector3(5.8,2.5,3.3),pale)
	_block(p+Vector3(0,2.61,0),Vector3(6.15,.25,3.65),teal)
	_block(p+Vector3(1.6,1.05,1.69),Vector3(1.1,2.0,.13),teal)
	_block(p+Vector3(1.96,1.05,1.79),Vector3(.12,.13,.09),yellow)
	for x in [-1.85,-.1]:
		_block(p+Vector3(x,1.35,1.69),Vector3(1.4,1.0,.14),blue)
		_block(p+Vector3(x,1.35,1.78),Vector3(.07,1.03,.04),pale)
	_block(p+Vector3(0,2.17,2),Vector3(6.0,.16,1.2),orange)
	for x in [-2.7,2.7]:
		_block(p+Vector3(x,1.02,2.45),Vector3(.1,2.04,.1),teal)
	var text := Geo.label(self,"SITE OFFICE",p+Vector3(-.5,2.3,1.74),17,Color("35506a"))
	text.pixel_size = .01
	_block(p+Vector3(1.6,.08,2.15),Vector3(1.65,.2,1.1),concrete)

func _building_frame(p: Vector3) -> void:
	_block(p+Vector3(0,.08,0),Vector3(6.4,.24,4.1),concrete)
	for x in [-2.65,2.65]:
		for z in [-1.55,1.55]:
			_block(p+Vector3(x,1.5,z),Vector3(.3,3,.3),timber)
	for z in [-1.55,1.55]:
		_block(p+Vector3(0,3,z),Vector3(5.65,.3,.3),yellow)
		Geo.beam(self,p+Vector3(-2.65,3,z),p+Vector3(0,4.4,z),.22,timber)
		Geo.beam(self,p+Vector3(2.65,3,z),p+Vector3(0,4.4,z),.22,timber)
	_block(p+Vector3(0,4.4,0),Vector3(.24,.24,3.5),timber)
	_block(p+Vector3(-2.65,.55,0),Vector3(.26,.9,3.2),orange)

func _crane(p: Vector3) -> void:
	var first_piece := get_child_count()
	_block(p+Vector3(0,.25,0),Vector3(2.6,.5,2.1),slate)
	for x in [-.38,.38]:
		_block(p+Vector3(x,3.6,0),Vector3(.20,7.2,.20),yellow)
	for i in 8:
		var y := .4+i*.85
		_block(p+Vector3(0,y,0),Vector3(.85,.14,.14),orange)
		Geo.beam(self,p+Vector3(-.35,y,0),p+Vector3(.35,y+.8,0),.095,orange)
	for h in [6.8,7.55]:
		_block(p+Vector3(1.8,h,0),Vector3(10,.19,.4),yellow)
	for i in 10:
		var x := -3.0+i
		Geo.beam(self,p+Vector3(x,6.8,0),p+Vector3(x+.9,7.55,0),.11,orange)
	_block(p+Vector3(-2.9,6.62,0),Vector3(1.4,.9,1.2),blue)
	_block(p+Vector3(.6,6.45,.2),Vector3(1.2,.9,1.05),teal)
	_block(p+Vector3(.6,6.45,.76),Vector3(.8,.5,.06),blue)
	Geo.beam(self,p+Vector3(5.8,6.8,0),p+Vector3(5.8,3.9,0),.055,navy)
	Geo.cylinder(self,p+Vector3(5.8,3.72,0),.19,.35,orange)
	# A short rounded hook: background detail, not another control to learn.
	var hook := Geo.cylinder(self,p+Vector3(5.8,3.40,0),.23,.12,navy,-1,16)
	hook.rotation.x = PI/2
	# Compress its height to keep the whole toy crane visible in the fixed view.
	var pieces := get_children().slice(first_piece)
	var crane := Node3D.new()
	crane.name = "ToyCrane"
	add_child(crane)
	for piece in pieces: piece.reparent(crane)
	crane.scale.y = .72

func _materials() -> void:
	# Soft, oversized pipes beside the container.
	for i in 3:
		var p := Vector3(-13.4+i*.87,.53,-6.8)
		var pipe := Geo.cylinder(self,p,.42,2.5,concrete,-1,24)
		pipe.rotation.x = PI/2
		var opening := Geo.cylinder(self,p+Vector3(0,0,1.26),.29,.025,slate,-1,24)
		opening.rotation.x = PI/2
	# Timber bundle and a small pallet of bricks on the right margin.
	for y in 3:
		for x in 3:
			_block(Vector3(13.2+x*.42,.16+y*.24,2.9),Vector3(.36,.2,3.4),timber)
	for z in [1.75,4.05]:
		_block(Vector3(13.62,.36,z),Vector3(1.29,.8,.07),blue)
	_block(Vector3(13.8,.10,-4.0),Vector3(2.1,.2,1.7),timber)
	for y in 3:
		for x in 3:
			for z in 2:
				_block(Vector3(13.12+x*.67,.32+y*.30,-4.4+z*.78),Vector3(.59,.25,.65),orange)
	# Dirt heaps outside the driving space have the same smooth toy silhouette.
	for p in [Vector3(-13.4,0,3.5),Vector3(13.6,0,6.5)]:
		_ball(p,Vector3(1.8,.9,1.3),Geo.material(Color("bfa477")))
		_ball(p+Vector3(.8,.1,.1),Vector3(1.0,.65,.9),dirt)
	# A pair of familiar construction drums.
	for x in [-14.1,-12.9]:
		Geo.cylinder(self,Vector3(x,.58,-9.2),.4,1.16,orange,-1,24)
		for y in [.25,.88]:
			Geo.cylinder(self,Vector3(x,y,-9.2),.415,.085,pale,-1,24)
	# Two short floodlights round out the real-site setting.
	for p in [Vector3(-15,0,-11),Vector3(15,0,-9)]:
		_block(p+Vector3(0,2.15,0),Vector3(.16,4.3,.16),slate)
		_block(p+Vector3(0,4.1,0),Vector3(1.45,.14,.14),slate)
		for x in [-.46,.46]:
			_block(p+Vector3(x,4,.14),Vector3(.65,.38,.2),pale)

func _cone(p: Vector3) -> void:
	_block(p+Vector3(0,.07,0),Vector3(.64,.14,.64),navy)
	Geo.cylinder(self,p+Vector3(0,.44,0),.25,.76,orange,.055,24)
	Geo.cylinder(self,p+Vector3(0,.48,0),.164,.15,pale,.125,24)

func _barrier(p: Vector3) -> void:
	for x in [-1.3,1.3]:
		_block(p+Vector3(x,.4,0),Vector3(.15,.8,.15),slate)
		_block(p+Vector3(x,.07,0),Vector3(.32,.14,.9),slate)
	_block(p+Vector3(0,.86,0),Vector3(3.35,.52,.22),pale)
	for i in 5:
		var stripe := _block(p+Vector3(-1.26+i*.63,.86,.125),Vector3(.28,.51,.035),orange)
		stripe.rotation.z = -.35
func _lighting() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("bfe4db")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("fff8ed")
	settings.ambient_light_energy = .28
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-65,-28,0)
	sun.light_color = Color("fff5df")
	sun.light_energy = .40
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	add_child(sun)

func _process(delta: float) -> void:
	# Yards without a floating goal star (the bulldozer site) have nothing to animate.
	if goal_star == null: return
	time += delta
	goal_star.position.y = 2.35+sin(time*1.8)*.13
	goal_star.rotation.z = sin(time*1.2)*.10

func _tree(p: Vector3, scale_factor: float) -> void:
	var trunk := Geo.material(Color("be8e69"))
	var leaf := Geo.material(Color("59ad8d"))
	var light := Geo.material(Color("83c59a"))
	Geo.cylinder(self,p+Vector3(0,1,0)*scale_factor,.28*scale_factor,2.8*scale_factor,trunk)
	_ball(p+Vector3(0,3.1,0)*scale_factor,Vector3(1.6,1.8,1.6)*scale_factor,leaf)
	_ball(p+Vector3(-.8,3.3,.2)*scale_factor,Vector3(1.2,1.3,1.2)*scale_factor,light)

func _cloud(p: Vector3, mat: Material) -> void:
	for i in 4:
		_ball(p+Vector3((i-1.5)*1.1,sin(i)*.3,0),Vector3(1.05,.7,.8),mat)

func _ball(pos: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 24
	mesh.rings = 12
	instance.mesh = mesh
	instance.material_override = mat
	add_child(instance)
	instance.position = pos
	instance.scale = dimensions
	return instance
