extends Control

signal reset_requested
signal pause_requested

const INK := Color("172d30")
const PAPER := Color("f1efdf")
const MUTED := Color("99aaa5")
const MINT := Color("b5ddc5")
const AMBER := Color("efb65b")
const REGULAR = preload("res://assets/fonts/Roboto-Regular.ttf")
const BOLD = preload("res://assets/fonts/Roboto-Bold.ttf")
const MONO = preload("res://assets/fonts/SourceCodePro-Medium.otf")

var vehicle
var game
var show_help := false
var message := ""
var message_time := 0.0
var total_delivered := 0
var elapsed := 0.0
var paused := false
var ui_scale := Vector2.ONE
var was_complete := false
var complete_time := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	paused = get_tree().paused
	if not paused:
		elapsed += delta
		message_time = maxf(0,message_time-delta)
		if total_delivered == 3:
			complete_time += delta
	queue_redraw()

func toast(text: String) -> void:
	message = text
	message_time = 5.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("help"):
		show_help = not show_help
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position / ui_scale
		if Rect2(1255,30,150,32).has_point(p):
			pause_requested.emit()
		if paused:
			if Rect2(510,465,420,52).has_point(p): pause_requested.emit()
			if Rect2(510,531,420,48).has_point(p): reset_requested.emit()

func _draw() -> void:
	ui_scale = get_viewport_rect().size / Vector2(1440,900)
	draw_set_transform(Vector2.ZERO,0,ui_scale)
	# Wordmark and field-test tag.
	draw_style_box(_style(INK,.94,6),Rect2(30,29,38,38))
	for i in 3:
		draw_line(Vector2(40,42+i*7),Vector2(58-i*4,42+i*7),AMBER,3)
	_text("EARTHWORK",Vector2(81,56),28,INK,BOLD)
	_text("CONSTRUCTION PLAYGROUND",Vector2(32,91),11,INK,MONO)
	_text("04",Vector2(32,153),42,INK,BOLD)
	draw_line(Vector2(89,119),Vector2(89,153),Color(INK,.4),1)
	_text("QUARRY YARD",Vector2(105,132),12,INK,BOLD)
	_text("Operator field test / 01",Vector2(105,153),12,INK,REGULAR)
	_panel(Rect2(1255,30,150,32),INK,.84,5)
	_text("ESC  PAUSE",Vector2(1282,51),12,PAPER,MONO)
	# Brief and objective progress.
	_panel(Rect2(1060,85,345,173),INK,.96,9)
	_text("THE FIRST SHIFT",Vector2(1082,113),11,AMBER,MONO)
	_text("Make room for progress.",Vector2(1082,145),22,PAPER,BOLD)
	_text("Move the 3 boulders into the marked bay.",Vector2(1082,171),13,Color("b9c8bc"))
	for i in 3:
		draw_style_box(_style(MINT if i<total_delivered else Color("405455"),1,2),Rect2(1082+i*100,195,89,4))
	_text("%02d / 03  DELIVERED"%total_delivered,Vector2(1082,232),12,MINT,MONO)
	_text("%02d:%02d"%[int(elapsed)/60,int(elapsed)%60],Vector2(1333,232),12,MUTED,MONO)
	_draw_map()
	# Vehicle instrument strip at lower left.
	_panel(Rect2(30,638,230,116),INK,.90,8)
	_text("EW–240  /  EXCAVATOR",Vector2(48,663),11,AMBER,MONO)
	_text("%04.1f"%(absf(vehicle.drive_speed)*3.6),Vector2(46,708),34,PAPER,MONO)
	_text("KM/H",Vector2(161,706),11,MUTED,MONO)
	var state := "LOAD SECURED" if vehicle.held != null else "BUCKET EMPTY"
	draw_circle(Vector2(52,734),3.5,MINT if vehicle.held != null else MUTED)
	_text(state,Vector2(65,738),10,MINT if vehicle.held != null else MUTED,MONO)
	# Contextual main action.
	var action_text := "Position the bucket"
	var action_sub := "Arrow keys adjust height and reach"
	var ready: bool = vehicle.candidate != null
	if vehicle.held != null:
		action_text = "Tip the boulder"
		action_sub = "Drive to the mint bay, then release"
	elif ready:
		action_text = "Scoop the boulder"
		action_sub = "Bucket in position. Ready when you are."
	elif vehicle.busy:
		action_text = "Hydraulics moving…"
		action_sub = "Keep the bucket clear"
	_panel(Rect2(487,670,466,83),MINT if ready or vehicle.held != null else PAPER,.97,8)
	_key("SPACE",Vector2(506,690),70,INK,MINT if ready or vehicle.held != null else PAPER)
	_text(action_text,Vector2(594,703),20,INK,BOLD)
	_text(action_sub,Vector2(594,729),12,INK)
	if message_time > 0:
		var width := REGULAR.get_string_size(message,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+36
		_panel(Rect2(720-width/2,613,width,35),INK,.93,6)
		_text(message,Vector2(738-width/2,636),14,PAPER)
	# Continuous control legend keeps the first minute self-explanatory.
	_panel(Rect2(30,784,1375,85),INK,.95,9)
	_control_group(Vector2(52,803),"W A S D","Drive / steer")
	_control_group(Vector2(252,803),"Q / E","Swing cab")
	_control_group(Vector2(428,803),"↑ ↓","Raise / lower")
	_control_group(Vector2(625,803),"← →","Reach in / out")
	_control_group(Vector2(826,803),"B","Travel pose")
	_control_group(Vector2(991,803),"RMB","Orbit · wheel zoom")
	draw_line(Vector2(1222,800),Vector2(1222,851),Color("435456"),1)
	_text("TAB  GUIDE",Vector2(1243,820),11,PAPER,MONO)
	_text("R  RESET YARD",Vector2(1243,845),11,MUTED,MONO)
	if total_delivered == 3:
		_panel(Rect2(447,170,546,93),MINT,.98,8)
		_text("SHIFT COMPLETE",Vector2(474,201),12,INK,MONO)
		_text("Good work. The yard is clear.",Vector2(474,236),26,INK,BOLD)
	if show_help:
		_draw_help()
	if paused:
		_draw_pause()

func _draw_map() -> void:
	_panel(Rect2(1215,278,190,215),INK,.86,8)
	_text("YARD PLAN",Vector2(1233,302),10,MUTED,MONO)
	var map_rect := Rect2(1230,315,160,156)
	for i in 5:
		draw_line(Vector2(map_rect.position.x+i*40,map_rect.position.y),Vector2(map_rect.position.x+i*40,map_rect.end.y),Color("354d4b"),1)
		draw_line(Vector2(map_rect.position.x,map_rect.position.y+i*39),Vector2(map_rect.end.x,map_rect.position.y+i*39),Color("354d4b"),1)
	var origin := Vector2(1310,406)
	var drop := origin+Vector2(8,-8)*3.05
	draw_rect(Rect2(drop-Vector2(10,10),Vector2(20,20)),Color("5f8b7d"),true)
	draw_rect(Rect2(drop-Vector2(10,10),Vector2(20,20)),MINT,false,1)
	for rock in get_tree().get_nodes_in_group("boulders"):
		if rock.carried: continue
		var p: Vector2 = origin+Vector2(rock.position.x,rock.position.z)*3.05
		draw_circle(p,3,MINT if rock.delivered else PAPER)
	var pos: Vector2 = origin+Vector2(vehicle.position.x,vehicle.position.z)*3.05
	var forward: Vector3 = -vehicle.global_basis.z
	var dir := Vector2(forward.x,forward.z)
	var side := Vector2(-dir.y,dir.x)
	draw_colored_polygon(PackedVector2Array([pos+dir*7,pos-dir*5+side*4,pos-dir*5-side*4]),AMBER)
	_text("N",Vector2(1376,304),10,AMBER,MONO)

func _draw_help() -> void:
	_panel(Rect2(345,240,750,352),INK,.98,12)
	_text("OPERATOR'S QUICK GUIDE",Vector2(377,277),12,AMBER,MONO)
	_text("A small machine. A proper day's work.",Vector2(377,316),27,PAPER,BOLD)
	var lines := [
		["01", "Line up", "WASD moves the tracks. Q / E swings the upper body."],
		["02", "Scoop", "Use arrows to place the open bucket around a rock. Press Space."],
		["03", "Carry", "Press B for travel height, then drive to the mint delivery bay."],
		["04", "Drop", "Position the bucket over the bay and press Space again."]]
	for i in lines.size():
		var y := 359.0+i*48
		_text(lines[i][0],Vector2(380,y),12,AMBER,MONO)
		_text(lines[i][1],Vector2(420,y),15,PAPER,BOLD)
		_text(lines[i][2],Vector2(503,y),12,MUTED)
	_text("C  OVERVIEW      F  REFOCUS      M  MUTE      TAB  CLOSE",Vector2(377,565),11,MINT,MONO)

func _draw_pause() -> void:
	draw_rect(Rect2(0,0,1440,900),Color(INK,.65))
	_panel(Rect2(470,284,500,339),INK,.99,12)
	_text("TAKE A BREATHER",Vector2(510,329),12,AMBER,MONO)
	_text("Shift paused.",Vector2(510,381),38,PAPER,BOLD)
	_text("Your machine and materials are right where you left them.",Vector2(510,417),13,MUTED)
	_panel(Rect2(510,465,420,52),MINT,1,5)
	_text("RESUME SHIFT  /  ESC",Vector2(617,497),13,INK,MONO)
	_panel(Rect2(510,531,420,48),Color("344a4a"),1,5)
	_text("RESET YARD  /  R",Vector2(636,561),12,PAPER,MONO)

func _control_group(pos: Vector2, key: String, caption: String) -> void:
	_text(key,pos+Vector2(0,12),14,PAPER,MONO)
	_text(caption,pos+Vector2(0,42),12,MUTED)

func _key(text: String, pos: Vector2, width: float, background: Color, foreground: Color) -> void:
	_panel(Rect2(pos,Vector2(width,42)),background,1,5)
	var text_width := MONO.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	_text(text,pos+Vector2((width-text_width)/2,26),13,foreground,MONO)

func _text(text: String, pos: Vector2, size: int, color: Color, font: Font = REGULAR) -> void:
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _panel(rect: Rect2, color: Color, alpha: float, radius: int) -> void:
	draw_style_box(_style(color,alpha,radius),rect)

func _style(color: Color, alpha: float, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color,alpha)
	style.set_corner_radius_all(radius)
	return style
