class_name OpeningMenu
extends Control

signal game_selected(kind: String)

const BOLD = preload("res://assets/fonts/Roboto-Bold.ttf")
const FONT = preload("res://assets/fonts/Roboto-Regular.ttf")
const INK := Color("35506a")
const KINDS := ["excavator","bulldozer","loader"]
var cards: Array[GameCard] = []
var selected := 0:
	set(value):
		selected = value
		for i in cards.size(): cards[i].selected = i == selected

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in KINDS.size():
		var card := GameCard.new()
		card.kind = KINDS[i]
		card.position = Vector2(45+i*460,272)
		card.size = Vector2(540,510)
		card.scale = Vector2.ONE*.8
		card.pressed.connect(game_selected.emit.bind(card.kind))
		card.mouse_entered.connect(func(): selected = i)
		add_child(card)
		cards.append(card)
	selected = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left"): selected = maxi(0,selected-1)
	elif event.is_action_pressed("right"): selected = mini(cards.size()-1,selected+1)
	elif event.is_action_pressed("ui_accept"): game_selected.emit(cards[selected].kind)
	elif event.is_action_pressed("menu_excavator"): game_selected.emit("excavator")
	elif event.is_action_pressed("menu_bulldozer"): game_selected.emit("bulldozer")
	elif event.is_action_pressed("menu_loader"): game_selected.emit("loader")
	else: return
	get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("bfe3d7"))
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
