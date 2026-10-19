extends Control

signal action_requested
signal direction_changed(direction: Vector2)
signal pause_requested
signal reset_requested
signal menu_requested
signal mute_requested
const ToyButton = preload("res://scripts/toy_button.gd")
const INK := Color("35506a")
const CREAM := Color("fffaed")
const BOLD = preload("res://assets/fonts/Roboto-Bold.ttf")
const FONT = preload("res://assets/fonts/Roboto-Regular.ttf")
var vehicle
var bulldozer_mode := false
var loader_mode := false
var load_count := 0
var hauler_title := "little loader"
var hauler_action := "SCOOP"
var hauler_hint := ""
var hauler_icon := "scoop"
var home_button
var menu_button
var stars := 0
var celebration_time := 0.0
var happy_text := ""
var buttons: Array[Control] = []
var arrows: Dictionary = {}
var action_button
var pause_button
var resume_button
var reset_button
var mute_button
var muted := false
var ui_scale := 1.0
var ui_offset := Vector2.ZERO
var paused := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	for item in [["up",Vector2(116,735),Vector2(0,-1)],["left",Vector2(34,812),Vector2(-1,0)],["down",Vector2(116,812),Vector2(0,1)],["right",Vector2(198,812),Vector2(1,0)]]:
		var button = _button(item[1],Vector2(74,72),item[0],CREAM)
		arrows[item[0]] = button
		button.held_changed.connect(func(_held: bool): _emit_direction())
	action_button = _button(Vector2(1200,730),Vector2(192,149),"scoop",Color("ffcf69"))
	action_button.activated.connect(func(): action_requested.emit())
	pause_button = _button(Vector2(1340,38),Vector2(60,60),"pause",CREAM)
	pause_button.activated.connect(func(): pause_requested.emit())
	home_button = _button(Vector2(1260,38),Vector2(60,60),"home",CREAM)
	home_button.activated.connect(func(): menu_requested.emit())
	menu_button = _button(Vector2(675,528),Vector2(90,80),"home",Color("c8d8ef"))
	menu_button.activated.connect(func(): menu_requested.emit())
	resume_button = _button(Vector2(667,381),Vector2(106,92),"play",Color("b5dfb6"))
	resume_button.activated.connect(func(): pause_requested.emit())
	reset_button = _button(Vector2(525,528),Vector2(90,80),"reset",Color("ffdc86"))
	reset_button.activated.connect(func(): reset_requested.emit())
	mute_button = _button(Vector2(825,528),Vector2(90,80),"sound",Color("b5dced"))
	mute_button.activated.connect(func(): mute_requested.emit())

func _button(pos: Vector2, dimensions: Vector2, icon: String, color: Color) -> Control:
	var button := ToyButton.new()
	button.position = pos
	button.size = dimensions
	button.icon = icon
	button.color = color
	button.set_meta("home",pos)
	add_child(button)
	buttons.append(button)
	return button

func _emit_direction() -> void:
	var dir := Vector2(float(arrows.right.down)-float(arrows.left.down),float(arrows.down.down)-float(arrows.up.down))
	direction_changed.emit(dir.limit_length(1))

func release_buttons() -> void:
	for button in buttons: button.release()
	direction_changed.emit(Vector2.ZERO)

func celebrate(text: String) -> void:
	happy_text = text
	celebration_time = 3.2

func _process(delta: float) -> void:
	paused = get_tree().paused
	if not paused: celebration_time = maxf(0,celebration_time-delta)
	var view := get_viewport_rect().size
	ui_scale = minf(view.x/1440.0,view.y/900.0)
	ui_offset = (view-Vector2(1440,900)*ui_scale)/2
	for button in buttons:
		button.position = ui_offset+(button.get_meta("home") as Vector2)*ui_scale
		button.scale = Vector2.ONE*ui_scale
		button.queue_redraw()
	for button in arrows.values(): button.visible = not paused
	action_button.visible = not paused
	pause_button.visible = not paused
	home_button.visible = not paused
	menu_button.visible = paused
	resume_button.visible = paused
	reset_button.visible = paused
	mute_button.visible = paused
	mute_button.icon = "mute" if muted else "sound"
	action_button.icon = "push" if bulldozer_mode else ("drop" if vehicle.held != null else "scoop")
	if loader_mode:
		action_button.icon = hauler_icon
		action_button.pebble_color = Color("a97950")
	action_button.disabled = vehicle.busy
	action_button.color = Color("a5dbb2") if vehicle.held != null else Color("ffcf69")
	queue_redraw()

func _draw() -> void:
	draw_set_transform(ui_offset,0,Vector2.ONE*ui_scale)
	_panel(Rect2(25,26,324,104),Color(CREAM,.94),24)
	_text(hauler_title if loader_mode else ("little dozer" if bulldozer_mode else "little digger"),Vector2(42,80),42,INK,BOLD)
	_text(("Truck: %d / 3 bucketfuls"%load_count) if loader_mode else "Let's build something!",Vector2(44,111),18,INK)
	# Three stars are keepsakes, not a countdown or a score to lose.
	_panel(Rect2(976,35,257,73),CREAM,28)
	for i in 3:
		_star(Vector2(1023+i*80,69),23,Color("efb741") if i<stars else Color("dfdfc8"))
	if not paused:
		_text("MOVE",Vector2(201,777),15,INK,BOLD)
		_text(hauler_action if loader_mode else ("PUSH" if bulldozer_mode else ("DROP" if vehicle.held != null else "SCOOP")),Vector2(1255,713),23,INK,BOLD)
		_panel(Rect2(410,805,620,70),CREAM,26)
		_text(hauler_hint if loader_mode else ("Push rocks into the holes!" if bulldozer_mode else "Tap a rock. Tap the star."),Vector2(540 if loader_mode else 558,834),20 if loader_mode else 23,INK,BOLD)
		_text("Drive with arrows. Tap a rock for help." if bulldozer_mode else "Or use the arrow keys + Space",Vector2(586,859),15,INK)
		draw_circle(Vector2(450,839),15,Color("a97950") if loader_mode else Color("cd9feb"))
		draw_line(Vector2(475,839),Vector2(497,839),INK,3,true)
		draw_line(Vector2(488,831),Vector2(497,839),INK,3,true)
		draw_line(Vector2(488,847),Vector2(497,839),INK,3,true)
		_star(Vector2(523,839),17,Color("edb64b"))
		if vehicle.busy:
			for i in 3:
				draw_circle(Vector2(1273+i*20,891),4,Color(INK,.35+.65*(.5+.5*sin(Time.get_ticks_msec()*.005-i))))
	if celebration_time>0 and not paused:
		var alpha := minf(1.0,celebration_time)
		_panel(Rect2(555,148,330,62),Color(CREAM,alpha),25)
		_center_text(happy_text,Vector2(720,190),30,Color(INK,alpha),BOLD)
		if stars>0:
			var age := 3.2-celebration_time
			for i in 24:
				var x := 580+fmod(i*91.0,280)+sin(i*2.1)*age*35
				var y := 154+age*80+i%4*16
				var c := [Color("efb741"),Color("e89795"),Color("7bbaa1"),Color("9da4dc")][i%4] as Color
				draw_circle(Vector2(x,y),4,Color(c,alpha))
	if paused:
		draw_rect(Rect2(0,0,1440,900),Color("35506a88"))
		_panel(Rect2(480,264,480,397),CREAM,32)
		_center_text("Taking a little break",Vector2(720,324),30,INK,BOLD)
		_center_text("Keep playing",Vector2(720,506),21,INK,BOLD)
		_center_text("Start again",Vector2(570,640),17,INK)
		_center_text("Choose game",Vector2(720,640),17,INK)
		_center_text("Sound",Vector2(870,640),17,INK)

func _star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var a := -PI/2+TAU*i/10
		points.append(center+Vector2(cos(a),sin(a))*radius*(1 if i%2==0 else .46))
	draw_colored_polygon(points,color)

func _panel(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style,rect)

func _text(text: String, pos: Vector2, size: int, color: Color, font: Font = FONT) -> void:
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _center_text(text: String, pos: Vector2, size: int, color: Color, font: Font = FONT) -> void:
	_text(text,pos-Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0),size,color,font)
