extends Camera3D

var target: Node3D
var yaw := .90
var pitch := .54
var distance := 17.5
var target_distance := 17.5
var orbiting := false
var overview := false
var focus_point := Vector3(0,1,-1.7)

func _ready() -> void:
	current = true
	fov = 48
	near = .1
	far = 250

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			orbiting = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if orbiting else Input.MOUSE_MODE_VISIBLE
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = clampf(target_distance-1.0,8,26)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = clampf(target_distance+1.0,8,26)
	if event is InputEventMouseMotion and orbiting:
		yaw -= event.relative.x*.006
		pitch = clampf(pitch+event.relative.y*.004,.2,1.2)
	if event.is_action_pressed("camera"):
		overview = not overview
	if event.is_action_pressed("focus"):
		yaw = .90+target.rotation.y
		pitch = .54
		target_distance = 17.5
		overview = false

func _process(delta: float) -> void:
	if target == null: return
	var desired_focus: Vector3 = target.global_position+Vector3(0,1.1,0)-target.upper.global_basis.z*1.8
	if overview:
		desired_focus = Vector3(0,0,-5)
	focus_point = focus_point.lerp(desired_focus,1-exp(-delta*5))
	distance = lerpf(distance,36.0 if overview else target_distance,1-exp(-delta*5))
	var view_pitch := .93 if overview else pitch
	var offset := Vector3(sin(yaw)*cos(view_pitch),sin(view_pitch),cos(yaw)*cos(view_pitch))*distance
	global_position = focus_point+offset
	look_at(focus_point)

func release_mouse() -> void:
	orbiting = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
