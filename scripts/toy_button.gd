extends Control

signal activated
signal held_changed(held: bool)
var icon := "up"
var color := Color("ffffff")
var down := false
var touch_id := -1
var disabled := false
var pebble_color := Color("cd9feb")
const INK := Color("35506a")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _gui_input(event: InputEvent) -> void:
	if disabled: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_set_down(event.pressed)
		if event.pressed: activated.emit()
		accept_event()
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			_set_down(true)
			activated.emit()
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			_set_down(false)
		accept_event()

func _input(event: InputEvent) -> void:
	# Releases outside the button must never leave a direction held down.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_set_down(false)
	if event is InputEventScreenTouch and not event.pressed and event.index == touch_id:
		touch_id = -1
		_set_down(false)

func release() -> void:
	touch_id = -1
	_set_down(false)

func _set_down(value: bool) -> void:
	if down == value: return
	down = value
	held_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var face := Rect2(Vector2(0,5 if down else 0),size-Vector2(0,7))
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(int(minf(size.x,size.y)*.27))
	style.bg_color = color.darkened(.17)
	draw_style_box(style,Rect2(Vector2(0,7),size-Vector2(0,7)))
	style.bg_color = color.darkened(.04) if down else color
	draw_style_box(style,face)
	var center := face.get_center()
	var unit := minf(size.x,size.y)*.27
	if icon in ["up","down","left","right"]:
		var angle := {"up":0.0,"right":PI/2,"down":PI,"left":-PI/2}[icon] as float
		var points := PackedVector2Array()
		for p in [Vector2(0,-1),Vector2(1,.0),Vector2(.42,0),Vector2(.42,.85),Vector2(-.42,.85),Vector2(-.42,0),Vector2(-1,0)]:
			points.append(center+p.rotated(angle)*unit)
		draw_colored_polygon(points,INK)
	elif icon in ["scoop","drop"]:
		# A bucket and a pebble, with an arrow into or out of the scoop.
		var c := center+Vector2(0,unit*.25)
		draw_polyline(PackedVector2Array([c+Vector2(-1,-.2)*unit,c+Vector2(-.65,.6)*unit,c+Vector2(.65,.6)*unit,c+Vector2(1,-.2)*unit]),INK,6,true)
		draw_circle(c+Vector2(0,-.12)*unit,unit*.3,pebble_color)
		var direction := 1.0 if icon == "scoop" else -1.0
		var top := center+Vector2(0,-unit*.90)
		draw_line(top+Vector2(0,-unit*.32),top+Vector2(0,unit*.32),INK,5,true)
		var tip := top+Vector2(0,direction*unit*.32)
		draw_polyline(PackedVector2Array([tip+Vector2(-.25,-direction*.25)*unit,tip,tip+Vector2(.25,-direction*.25)*unit]),INK,5,true)
	elif icon == "truck":
		draw_style_box(_pill(INK,4),Rect2(center+Vector2(-1.15,-.4)*unit,Vector2(1.5,.7)*unit))
		draw_rect(Rect2(center+Vector2(.4,-.2)*unit,Vector2(.65,.5)*unit),INK)
		for x in [-.7,.7]: draw_circle(center+Vector2(x,.48)*unit,unit*.25,INK)
		draw_line(center+Vector2(-.9,-.65)*unit,center+Vector2(.15,-1.0)*unit,INK,5,true)
	elif icon == "home":
		draw_colored_polygon(PackedVector2Array([center+Vector2(-1,0)*unit,center+Vector2(0,-.9)*unit,center+Vector2(1,0)*unit]),INK)
		draw_rect(Rect2(center+Vector2(-.65,-.05)*unit,Vector2(1.3,.9)*unit),INK)
		draw_rect(Rect2(center+Vector2(-.2,.3)*unit,Vector2(.4,.55)*unit),color)
	elif icon == "push":
		draw_circle(center+Vector2(.5,0)*unit,unit*.45,Color("cd9feb"))
		draw_line(center+Vector2(-1.15,-.55)*unit,center+Vector2(-1.15,.55)*unit,INK,7,true)
		draw_line(center+Vector2(-1.1,0)*unit,center+Vector2(-.15,0)*unit,INK,5,true)
		draw_polyline(PackedVector2Array([center+Vector2(-.45,-.25)*unit,center+Vector2(-.15,0)*unit,center+Vector2(-.45,.25)*unit]),INK,5,true)
	elif icon == "pause":
		for x in [-.35,.35]: draw_style_box(_pill(INK,4),Rect2(center+Vector2(x*unit-4,-unit*.65),Vector2(8,unit*1.3)))
	elif icon == "play":
		draw_colored_polygon(PackedVector2Array([center+Vector2(-.5,-.8)*unit,center+Vector2(.8,0)*unit,center+Vector2(-.5,.8)*unit]),INK)
	elif icon == "reset":
		draw_arc(center,unit*.7,.0,PI*1.7,30,INK,5,true)
		draw_colored_polygon(PackedVector2Array([center+Vector2(.7,-.1)*unit,center+Vector2(.3,.25)*unit,center+Vector2(1.03,.25)*unit]),INK)
	elif icon == "sound" or icon == "mute":
		draw_colored_polygon(PackedVector2Array([center+Vector2(-.8,-.3)*unit,center+Vector2(-.3,-.3)*unit,center+Vector2(.2,-.8)*unit,center+Vector2(.2,.8)*unit,center+Vector2(-.3,.3)*unit,center+Vector2(-.8,.3)*unit]),INK)
		if icon == "sound": draw_arc(center+Vector2(-.2,0)*unit,unit, -.65,.65,16,INK,4,true)
		else: draw_line(center+Vector2(.5,-.5)*unit,center+Vector2(1,.5)*unit,INK,4,true)

func _pill(c: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	return s
