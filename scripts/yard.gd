extends Node3D

const Geo = preload("res://scripts/geometry.gd")
const DELIVERY_CENTER := Vector3(8, 0, -8)
const DELIVERY_HALF := Vector2(3.3, 3.3)
var rng := RandomNumberGenerator.new()
var sand := Geo.material(Color("b8a684"))
var dark := Geo.material(Color("283c3e"))
var concrete := Geo.material(Color("a5a798"))
var cream := Geo.material(Color("ece5cd"))
var orange := Geo.material(Color("ed8a3c"))
var mint := Geo.material(Color("88c9bc"))

func _ready() -> void:
	rng.seed = 7281
	_make_lighting()
	_make_ground()
	_make_delivery()
	_make_fence()
	_make_buildings()
	_make_details()
	_make_backdrop()

func _make_lighting() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("6f979f")
	sky_mat.sky_horizon_color = Color("d1d4bd")
	sky_mat.ground_bottom_color = Color("8e927c")
	sky_mat.ground_horizon_color = Color("d1d4bd")
	sky_mat.energy_multiplier = .6
	sky.sky_material = sky_mat
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c9dfdc")
	settings.ambient_light_energy = 0.32
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	settings.fog_enabled = true
	settings.fog_light_color = Color("c4cdb9")
	settings.fog_density = 0.0035
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff0ce")
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 95
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)

func _make_ground() -> void:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
varying vec3 world;
void vertex(){world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
  float grain = hash(floor(world.xz * 19.0));
  float patches = sin(world.x*.23+sin(world.z*.3))*cos(world.z*.19)*.012;
  ALBEDO = vec3(.32,.265,.18) + grain*.02 + patches;
  ROUGHNESS = .94;
}"""
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = shader
	Geo.box(self, Vector3(0,-.28,0), Vector3(220,.5,220), ground_mat, true)
	# Track scars and a worn haul road.
	var road := Geo.material(Color("696551"))
	Geo.box(self, Vector3(-8,-.014,4), Vector3(5,.015,34), road)
	for x in [-1.3,1.3]:
		for i in 75:
			Geo.box(self, Vector3(x,.001,2.5+i*.22), Vector3(.78,.013,.085), road)
	for i in 14:
		Geo.box(self, Vector3(-8,.009,18-i*2.3), Vector3(.11,.012,.9), cream)
	# Curbs at the edge of the working apron.
	for i in 13:
		Geo.box(self, Vector3(-4.9,.08,15-i*2.2), Vector3(.17,.19,1.8), concrete)

func _make_delivery() -> void:
	Geo.box(self, DELIVERY_CENTER + Vector3(0,-.008,0), Vector3(7,.025,7), Geo.material(Color("818e83")))
	for side in [-1,1]:
		for i in 7:
			Geo.box(self, DELIVERY_CENTER+Vector3(side*3.3,.014,-2.9+i*.96), Vector3(.09,.024,.60), mint)
			Geo.box(self, DELIVERY_CENTER+Vector3(-2.9+i*.96,.014,side*3.3), Vector3(.60,.024,.09), mint)
	for i in 6:
		var stripe := Geo.box(self, DELIVERY_CENTER+Vector3(-2.6+i*1.03,.012,0), Vector3(.028,.016,5.4), Geo.material(Color("91a294")))
		stripe.rotation.y = .3
	var ground_label := Geo.label(self, "MATERIAL DROP", DELIVERY_CENTER + Vector3(0,.055,2.3), 34, Color("d6e7d5"))
	ground_label.rotation_degrees.x = -90
	var sign := Node3D.new()
	add_child(sign)
	sign.position = DELIVERY_CENTER + Vector3(0,0,-4.2)
	for x in [-1.0,1.0]:
		Geo.box(sign,Vector3(x,1.2,0),Vector3(.1,2.4,.1),dark)
	Geo.box(sign,Vector3(0,2.25,0),Vector3(3.0,.85,.15),dark)
	Geo.label(sign,"02  /  MATERIAL DROP",Vector3(0,2.3,.087),22,Color("cde3d5"))
	for p in [Vector3(-3.8,0,-3.8),Vector3(3.8,0,-3.8),Vector3(-3.8,0,3.8),Vector3(3.8,0,3.8)]:
		_cone(DELIVERY_CENTER+p)

func _make_fence() -> void:
	var wire := Geo.material(Color("68736b"),.9,.2)
	for side in [-1,1]:
		for i in 21:
			var z := -25.0+i*2.5
			Geo.box(self, Vector3(side*23,1.1,z), Vector3(.07,2.2,.07),dark)
			if i < 20:
				for h in [.35,.9,1.45,2.0]:
					Geo.box(self,Vector3(side*23,h,z+1.25),Vector3(.025,.025,2.5),wire)
	for i in 19:
		Geo.box(self,Vector3(-22.5+i*2.5,1.1,-25),Vector3(.07,2.2,.07),dark)
		for h in [.35,.9,1.45,2.0]:
			Geo.box(self,Vector3(-21.25+i*2.5,h,-25),Vector3(2.5,.025,.025),wire)
	# Invisible perimeter colliders keep the prototype in its yard.
	for p in [Vector3(-23,1,0),Vector3(23,1,0)]:
		var wall := Geo.box(self,p,Vector3(.2,3,52),dark,true)
		wall.visible = false
	for z in [-25,25]:
		var wall := Geo.box(self,Vector3(0,1,z),Vector3(46,3,.2),dark,true)
		wall.visible = false

func _make_buildings() -> void:
	var teal := Geo.material(Color("3e6465"),.8,.2)
	var rust := Geo.material(Color("a96345"))
	for info in [[Vector3(-15,1.4,-16),teal],[Vector3(-15,1.4,-21),rust]]:
		var p: Vector3 = info[0]
		Geo.box(self,p,Vector3(10,2.8,3.8),info[1],true)
		for i in 31:
			Geo.box(self,p+Vector3(-4.8+i*.32,0,1.94),Vector3(.055,2.62,.06),info[1])
		for x in [-4.9,4.9]:
			Geo.box(self,p+Vector3(x,0,1.96),Vector3(.12,2.8,.09),dark)
		Geo.box(self,p+Vector3(0,1.45,0),Vector3(10.15,.15,3.95),info[1])
	Geo.label(self,"EARTHWORK",Vector3(-15,1.8,-14.03),44,Color("dbdfc8"))
	Geo.label(self,"SITE 04   /   EQUIPMENT & MATERIALS",Vector3(-15,1.13,-14.02),13,Color("c0cdbf"))
	# Office with a striped awning.
	Geo.box(self,Vector3(17,1.3,-19),Vector3(7,2.6,4),cream,true)
	Geo.box(self,Vector3(17,2.7,-19),Vector3(7.5,.22,4.4),dark)
	Geo.box(self,Vector3(19,1.13,-16.94),Vector3(1.1,2.2,.12),teal)
	for x in [14.8,16.6]:
		Geo.box(self,Vector3(x,1.5,-16.93),Vector3(1.2,1,.13),dark)
	Geo.label(self,"SITE OFFICE",Vector3(17,2.3,-16.84),23,Color("253d3c"))
	Geo.box(self,Vector3(17,2.45,-16.3),Vector3(7.2,.12,1.5),orange)
	for x in [13.6,20.4]:
		Geo.box(self,Vector3(x,1.2,-15.7),Vector3(.08,2.4,.08),dark)

func _make_details() -> void:
	for p in [Vector3(-4,0,7),Vector3(-4,0,11),Vector3(-4,0,15),Vector3(16,0,-9)]:
		_cone(p)
	# Timber stacks.
	var wood := Geo.material(Color("af8151"))
	for i in 4:
		for j in 3:
			Geo.box(self,Vector3(15+j*.5,.16+i*.22,8),Vector3(.43,.18,3.7),wood,true)
	for z in [6.6,9.4]:
		Geo.box(self,Vector3(15.5,.48,z),Vector3(1.55,1.0,.045),dark)
	# Concrete culvert pipes.
	for i in 4:
		var pipe := Geo.cylinder(self,Vector3(-16+i*1.6,.72,-7.5),.69,3,concrete,.69,24)
		pipe.rotation.x = PI/2
		var hole := Geo.cylinder(self,Vector3(-16+i*1.6,.72,-5.985),.51,.016,dark,.51,24)
		hole.rotation.x = PI/2
	# Floodlights.
	for p in [Vector3(-20,0,9),Vector3(19,0,-1),Vector3(-4,0,-22)]:
		Geo.box(self,p+Vector3(0,3.7,0),Vector3(.16,7.4,.16),dark)
		Geo.box(self,p+Vector3(0,7.35,0),Vector3(2,.12,.12),dark)
		for x in [-.65,.65]:
			Geo.box(self,p+Vector3(x,7.1,.1),Vector3(.7,.42,.24),cream)
	# Gravel flecks and low vegetation, away from the playable center.
	var rock_mat := Geo.material(Color("8c8977"))
	for i in 210:
		var p := Vector3(rng.randf_range(-22,22),.025,rng.randf_range(-24,22))
		if p.distance_to(DELIVERY_CENTER) < 5: continue
		var pebble := Geo.box(self,p,Vector3(rng.randf_range(.04,.16),.05,rng.randf_range(.04,.22)),rock_mat)
		pebble.rotation.y = rng.randf()*TAU
	var grass := Geo.material(Color("737d57"))
	for i in 60:
		var p := Vector3(rng.randf_range(20,22)*(-1 if i%2 else 1),0,rng.randf_range(-24,23))
		for j in 3:
			var blade := Geo.box(self,p+Vector3(j*.11,.13,0),Vector3(.055,rng.randf_range(.17,.4),.05),grass)
			blade.rotation.z = rng.randf_range(-.5,.5)

func _make_backdrop() -> void:
	var hill_mat := Geo.material(Color("8b9580"))
	var far_mat := Geo.material(Color("9faa94"))
	for i in 22:
		var angle := TAU*i/22
		var distance := rng.randf_range(65,91)
		var hill := Geo.cylinder(self,Vector3(cos(angle)*distance,0,sin(angle)*distance),rng.randf_range(19,33),rng.randf_range(12,23),far_mat,0,5)
		hill.rotation.y = rng.randf()*TAU
	for p in [Vector3(-17,0,18),Vector3(17,0,19),Vector3(15,0,-24)]:
		var mound := Geo.cylinder(self,p,4.5,3.0,sand,1.5,9)
		mound.rotation.y = .4
	for i in 12:
		var p := Vector3(-35+i*6,0,-39-rng.randf()*8)
		Geo.cylinder(self,p+Vector3(0,1.3,0),.19,2.6,dark)
		Geo.cylinder(self,p+Vector3(0,4.3,0),2.2,5,hill_mat,0,6)

func _cone(p: Vector3) -> void:
	Geo.box(self,p+Vector3(0,.06,0),Vector3(.55,.12,.55),dark)
	Geo.cylinder(self,p+Vector3(0,.4,0),.23,.68,orange,.055)
	Geo.cylinder(self,p+Vector3(0,.49,0),.147,.14,cream,.113)
