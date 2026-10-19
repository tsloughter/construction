extends Control

signal game_selected(kind: String)
const Card = preload("res://scripts/game_card.gd")
const BOLD = preload("res://assets/fonts/Roboto-Bold.ttf")
const FONT = preload("res://assets/fonts/Roboto-Regular.ttf")
const INK := Color("35506a")
var cards: Array[Control] = []
var selected := 0
var content: Control
var ui_scale := 1.0
var ui_offset := Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	for i in 3:
		var card := Card.new()
		card.kind = ["excavator","bulldozer","loader"][i]
		card.position = Vector2(45+i*460,272)
		card.size = Vector2(540,510)
		card.scale = Vector2.ONE*.8
		card.activated.connect(func(): game_selected.emit(card.kind))
		card.mouse_entered.connect(func(): selected = i)
		content.add_child(card)
		cards.append(card)

func _process(_delta: float) -> void:
	var view := get_viewport_rect().size
	ui_scale = minf(view.x/1440.0,view.y/900.0)
	ui_offset = (view-Vector2(1440,900)*ui_scale)/2
	content.position = ui_offset
	content.scale = Vector2.ONE*ui_scale
	for i in 3:
		cards[i].selected = i == selected
		cards[i].queue_redraw()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_LEFT,KEY_A: selected = maxi(0,selected-1)
			KEY_RIGHT,KEY_D: selected = mini(2,selected+1)
			KEY_ENTER,KEY_KP_ENTER,KEY_SPACE: game_selected.emit(cards[selected].kind)
			KEY_1: game_selected.emit("excavator")
			KEY_2: game_selected.emit("bulldozer")
			KEY_3: game_selected.emit("loader")
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(get_viewport_rect(),Color("bfe3d7"))
	draw_set_transform(ui_offset,0,Vector2.ONE*ui_scale)
	draw_circle(Vector2(20,840),270,Color("afd6bd"))
	draw_circle(Vector2(1470,55),255,Color("d3ebde"))
	_center("little builders",Vector2(720,142),74,BOLD)
	_center("What shall we drive?",Vector2(720,209),30,FONT)
	_center("Choose a picture and play together",Vector2(720,851),22,FONT)
	# Playful bolts around the title echo the little construction vehicles.
	for p in [Vector2(391,111),Vector2(1049,111)]:
		draw_circle(p,13,Color("f2c75e"))
		draw_circle(p,5,Color("f9e8b1"))

func _center(text: String, pos: Vector2, font_size: int, font: Font) -> void:
	draw_string(font,pos-Vector2(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,INK)
