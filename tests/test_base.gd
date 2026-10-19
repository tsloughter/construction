class_name GameTest
extends Node

# Shared harness for the in-engine suites: checks, frame waits and real
# viewport dispatch for mouse, touch and keyboard input.
var game
var suite_name := "TEST"
var failures: Array[String] = []
var checks := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	pass

func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition: print("PASS: ",description)
	else:
		failures.append(description)
		push_error("FAIL: "+description)

func _frames(count: int) -> void:
	for i in count: await get_tree().physics_frame

func _until(predicate: Callable, maximum: int = 900) -> bool:
	for i in maximum:
		if predicate.call():
			await _frames(3)
			return true
		await _frames(1)
	return false

func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(2)

func _mouse(pos: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = pos
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	get_viewport().push_input(event,true)
	await _frames(2)

func _click(pos: Vector2) -> void:
	await _mouse(pos,true)
	await _mouse(pos,false)

# On a device the engine emulates a mouse press from the first finger
# (emulate_mouse_from_touch); the harness synthesizes that same pair so the
# buttons and games see exactly what a real tablet tap delivers.
func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.device = InputEvent.DEVICE_ID_EMULATION
	mouse.position = pos
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = pressed
	get_viewport().push_input(mouse,true)
	var touch := InputEventScreenTouch.new()
	touch.index = index
	touch.position = pos
	touch.pressed = pressed
	get_viewport().push_input(touch,true)
	await _frames(2)

func _touch_tap(pos: Vector2, index: int = 0) -> void:
	await _touch(index,pos,true)
	await _touch(index,pos,false)

func _key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		get_viewport().push_input(event,true)
		await _frames(2)

func _finish() -> void:
	print("%s: %d checks, %d failures"%[suite_name,checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
