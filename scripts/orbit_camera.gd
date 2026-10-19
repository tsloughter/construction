class_name FixedCamera
extends Camera3D

# A fixed view: screen directions always match the movement buttons.
func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	keep_aspect = Camera3D.KEEP_WIDTH
	size = 36.8
	near = .1
	far = 160
	position = Vector3(0,26,27)
	look_at(Vector3(0,0,-2.4))
	current = true
