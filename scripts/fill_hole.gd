class_name FillHole
extends Node3D

static var STAR_WAITING := _star_material(Color("c8c6af"))
static var STAR_DONE := _star_material(Color("f4b839"))
static var PLUG := Geo.material(Color("9bc7a3"))
var filled := false
var plug: Node3D
var star: Node3D
var badge: MeshInstance3D

func _ready() -> void:
	add_to_group("holes")
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 64:
		var a := Vector3(cos(TAU*i/64),0,sin(TAU*i/64))*DozerLayout.RADIUS
		var b := Vector3(cos(TAU*(i+1)/64),0,sin(TAU*(i+1)/64))*DozerLayout.RADIUS
		for p in [a,b,b+Vector3.DOWN*1.9,a,b+Vector3.DOWN*1.9,a+Vector3.DOWN*1.9]: surface.add_vertex(p)
	surface.generate_normals()
	var wall := MeshInstance3D.new()
	wall.mesh = surface.commit()
	var mat := Geo.material(Color("98734f"))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	wall.material_override = mat
	add_child(wall)
	Geo.cylinder(self,Vector3(0,-1.85,0),DozerLayout.RADIUS,.1,Geo.material(Color("705b49")),-1,64)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = DozerLayout.RADIUS-.02
	torus.outer_radius = DozerLayout.RADIUS+.16
	torus.rings = 48
	torus.ring_segments = 8
	rim.mesh = torus
	rim.material_override = Geo.material(Color("f9dc86"))
	rim.position.y = .02
	add_child(rim)
	# One large star behind each hole provides a picture goal.
	badge = Geo.cylinder(self,Vector3(0,1.2,-2.06),.66,.06,Geo.material(Color("fff8e5")),-1,32)
	badge.rotation.x = PI/2
	star = Geo.star(self,Vector3(0,1.2,-2.0),.46,STAR_WAITING)
	# A sensor near the bottom reports a boulder that has really fallen in.
	var sensor := Area3D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 4
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.25
	cylinder.height = .6
	shape.shape = cylinder
	shape.position.y = -1.6
	sensor.add_child(shape)
	add_child(sensor)
	sensor.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var rock := body as PushBoulder
	if rock == null or filled or rock.completed: return
	# Physics state cannot change inside a physics callback; finish on the next idle frame.
	fill.call_deferred(rock)

func fill(rock: PushBoulder) -> void:
	if filled or rock.completed: return
	filled = true
	rock.complete()
	rock.global_position = global_position+Vector3(0,-.48,0)
	plug = Geo.cylinder(self,Vector3(0,-.23,0),DozerLayout.RADIUS,.3,PLUG,-1,64)
	var body := StaticBody3D.new()
	body.collision_layer = 8
	body.collision_mask = 4
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = DozerLayout.RADIUS
	cylinder.height = .3
	shape.shape = cylinder
	plug.add_child(body)
	body.add_child(shape)
	star.material_override = STAR_DONE
	star.scale = Vector3.ONE*1.15

func reset_hole() -> void:
	filled = false
	if is_instance_valid(plug):
		remove_child(plug)
		plug.queue_free()
	star.scale = Vector3.ONE
	star.material_override = STAR_WAITING

static func _star_material(color: Color) -> StandardMaterial3D:
	var m := Geo.material(color)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
