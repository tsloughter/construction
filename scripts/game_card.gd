class_name GameCard
extends ToyButton

# One opening-screen picture: a live model preview with a big PLAY pill.
const BOLD = preload("res://assets/fonts/Roboto-Bold.ttf")
const EXCAVATOR_SCENE := preload("res://assets/models/excavator.glb")
const BULLDOZER_SCENE := preload("res://assets/models/bulldozer.glb")
const TITLES := {"excavator":"EXCAVATOR","bulldozer":"BULLDOZER","loader":"LOADER + TRUCK"}
const TAGLINES := {"excavator":"Scoop & carry","bulldozer":"Push & fill","loader":"Load & haul"}
var kind := "excavator"
var selected := false:
	set(value):
		if selected == value: return
		selected = value
		queue_redraw()
var _card := StyleBoxFlat.new()

func _ready() -> void:
	super()
	var container := SubViewportContainer.new()
	container.position = Vector2(18,72)
	container.size = Vector2(504,315)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(504,315)
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	# The preview never moves, so render it once instead of three shadowed worlds a frame.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	container.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("fff8ed")
	settings.ambient_light_energy = .3
	env.environment = settings
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-35,0)
	sun.light_energy = .4
	sun.shadow_enabled = true
	world.add_child(sun)
	var model: Node3D
	match kind:
		"loader": model = HaulerModel.new()
		"excavator": model = EXCAVATOR_SCENE.instantiate()
		_: model = BULLDOZER_SCENE.instantiate()
	world.add_child(model)
	model.rotation.y = .15 if kind != "excavator" else -.2
	if kind == "loader":
		model.position.x = -1.2
		model.scale = Vector3.ONE*.75
		var truck := HaulerModel.new()
		truck.kind = "truck"
		world.add_child(truck)
		truck.position = Vector3(1.6,0,.3)
		truck.scale = Vector3.ONE*.65
		truck.rotation.y = -.35
	if kind == "excavator":
		model.find_child("Boom",true,false).rotation.x = -.35
		model.find_child("Stick",true,false).rotation.x = .55
	Geo.cylinder(world,Vector3(0,-.12,0),3.6,.2,Geo.material(Color("dfc89a")),-1,64)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 7.2 if kind == "excavator" else 6.3
	world.add_child(cam)
	cam.position = Vector3(7,6,-10)
	cam.look_at(Vector3(0,1.0,-.4))
	cam.current = true

func _draw() -> void:
	var style := _card
	style.set_corner_radius_all(36)
	style.bg_color = Color("88afa6")
	draw_style_box(style,Rect2(Vector2(0,9),size))
	style.bg_color = Color("fff9e9") if not down else Color("f9efd6")
	style.border_color = Color("e3ab43") if selected else Color("f2e7cb")
	style.set_border_width_all(5 if selected else 2)
	draw_style_box(style,Rect2(Vector2.ZERO,size))
	_center(TITLES[kind],Vector2(270,51),25,INK)
	_center(TAGLINES[kind],Vector2(270,399),30,INK)
	style.set_border_width_all(0)
	style.set_corner_radius_all(23)
	style.bg_color = Color("b6dcb5") if kind == "excavator" else Color("ffd17b")
	draw_style_box(style,Rect2(153,425,234,60))
	draw_colored_polygon(PackedVector2Array([Vector2(210,441),Vector2(210,470),Vector2(235,455)]),INK)
	draw_string(BOLD,Vector2(253,465),"PLAY",HORIZONTAL_ALIGNMENT_LEFT,-1,27,INK)

func _center(text: String, pos: Vector2, font_size: int, tint: Color) -> void:
	draw_string(BOLD,pos-Vector2(BOLD.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,tint)
