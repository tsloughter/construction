extends CharacterBody3D

signal interaction(message: String)
signal scooped
signal dropped

const BOOM_LENGTH := 3.1
const STICK_LENGTH := 3.0
const OPEN_ANGLE := 0.0
const CLOSED_ANGLE := -0.63
const DUMP_ANGLE := 1.05
const Geo = preload("res://scripts/geometry.gd")

var model: Node3D
var upper: Node3D
var boom: Node3D
var stick: Node3D
var bucket: Node3D
var socket: Node3D
var bucket_body: AnimatableBody3D
var held: RigidBody3D
var candidate: RigidBody3D
var reach := 3.9
var lift := 1.0
var target_reach := 3.9
var target_lift := 1.0
var curl := OPEN_ANGLE
var target_curl := OPEN_ANGLE
var drive_speed := 0.0
var moving := false
var busy := false
var controls_enabled := true
var interaction_serial := 0
var socket_last := Vector3.ZERO
var socket_velocity := Vector3.ZERO
var pickup_ring: Node3D
var track_parts: Array[Dictionary] = []
var left_track_phase := 0.0
var right_track_phase := 0.0
var dump_elapsed := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.45,1.05,4.15)
	collider.shape = shape
	collider.position.y = .61
	add_child(collider)
	model = preload("res://assets/models/excavator.glb").instantiate()
	add_child(model)
	upper = model.find_child("Upper",true,false)
	boom = model.find_child("Boom",true,false)
	stick = model.find_child("Stick",true,false)
	bucket = model.find_child("Bucket",true,false)
	socket = model.find_child("CarrySocket",true,false)
	_make_bucket_collision()
	_make_markings()
	_cache_treads(model)
	_solve_arm()
	socket_last = socket.global_position
	pickup_ring = Geo.ring(get_parent(),1.05,Color("b9dfc3"))
	pickup_ring.visible = false

func _make_bucket_collision() -> void:
	bucket_body = AnimatableBody3D.new()
	bucket_body.name = "BucketCollision"
	bucket_body.collision_layer = 2
	bucket_body.collision_mask = 4
	bucket_body.sync_to_physics = false
	bucket.add_child(bucket_body)
	# A hollow collision shape: floor, back, and two cheeks. The mouth stays open.
	for entry in [
		[Vector3(0,-.70,-.49),Vector3(1.65,.13,1.05)],
		[Vector3(0,-.24,.13),Vector3(1.65,.7,.13)],
		[Vector3(-.82,-.3,-.45),Vector3(.10,.67,1.05)],
		[Vector3(.82,-.3,-.45),Vector3(.10,.67,1.05)]]:
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = entry[1]
		shape.shape = bounds
		shape.position = entry[0]
		bucket_body.add_child(shape)

func _make_markings() -> void:
	var logo := Geo.label(upper,"EW / 240",Vector3(.4,.7,1.63),26,Color("273738"))
	logo.pixel_size = .009
	var badge := Geo.label(upper,"04",Vector3(1.51,.3,.65),24,Color("273738"))
	badge.rotation.y = PI/2
	for i in 4:
		var stripe := Geo.box(upper,Vector3(-.7+i*.23,.42,1.65),Vector3(.11,.2,.015),Geo.material(Color("263538")))
		stripe.rotation.z = -.4

func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("reverse","forward") if controls_enabled else 0.0
	var steering := Input.get_axis("steer_right","steer_left") if controls_enabled else 0.0
	var maximum_speed := 2.6 if held != null else 3.8
	drive_speed = move_toward(drive_speed, throttle*maximum_speed, delta*3.5)
	rotate_y(steering*delta*.68)
	velocity.x = -global_basis.z.x*drive_speed
	velocity.z = -global_basis.z.z*drive_speed
	velocity.y = -1.0 if is_on_floor() else velocity.y-9.8*delta
	move_and_slide()
	moving = absf(drive_speed) > .1 or absf(steering) > .1
	left_track_phase -= (drive_speed-steering*.9)*delta
	right_track_phase -= (drive_speed+steering*.9)*delta
	_animate_tracks()
	if controls_enabled:
		upper.rotation.y += Input.get_axis("slew_right","slew_left")*delta*.7
		if not busy:
			target_lift = clampf(target_lift+Input.get_axis("lower","raise")*delta*1.65, .88, 4.7)
			target_reach = clampf(target_reach+Input.get_axis("retract","extend")*delta*1.65, 1.8, 5.2)
			if Input.is_action_just_pressed("carry_pose"):
				target_lift = 2.6
				target_reach = 2.9
		if Input.is_action_just_pressed("scoop"):
			interact_bucket()
	lift = move_toward(lift,target_lift,delta*1.8)
	reach = move_toward(reach,target_reach,delta*1.8)
	curl = move_toward(curl,target_curl,delta*1.9)
	_solve_arm()
	socket_velocity = (socket.global_position-socket_last)/maxf(delta,.001)
	socket_last = socket.global_position
	if held != null:
		var seat := socket.global_position
		if target_curl == DUMP_ANGLE:
			dump_elapsed += delta
			var lip := bucket.global_position-upper.global_basis.z*1.38+Vector3(0,-.05,0)
			seat = seat.lerp(lip,smoothstep(.3,.85,dump_elapsed))
		held.global_position = held.global_position.lerp(seat, minf(delta*14,1))
		# Keep the rock's orientation stable while secured in the bucket.
	_update_candidate()

func _solve_arm() -> void:
	# Analytic two-link IK. The elbow-up solution keeps the boom recognizable.
	var y := lift - (position.y + 1.81)
	var d := clampf(Vector2(reach,y).length(),.3,BOOM_LENGTH+STICK_LENGTH-.06)
	var direction := atan2(y,reach)
	var shoulder := acos(clampf((d*d+BOOM_LENGTH*BOOM_LENGTH-STICK_LENGTH*STICK_LENGTH)/(2*d*BOOM_LENGTH),-1,1))
	var elbow := acos(clampf((d*d-BOOM_LENGTH*BOOM_LENGTH-STICK_LENGTH*STICK_LENGTH)/(2*BOOM_LENGTH*STICK_LENGTH),-1,1))
	boom.rotation.x = direction+shoulder
	stick.rotation.x = -elbow
	# Level the bucket independently of both arm joints, then add its curl.
	bucket.rotation.x = curl-boom.rotation.x-stick.rotation.x

func _update_candidate() -> void:
	candidate = null
	var nearest := 1.5
	if held == null and not busy:
		for rock in get_tree().get_nodes_in_group("boulders"):
			if rock.carried: continue
			var p: Vector3 = bucket.to_local(rock.global_position)
			# Include a rock's radius: its surface can meet the teeth before its
			# center enters the bucket. This prevents the lip pushing it out of reach.
			if absf(p.x) < 1.08 and p.z < -.20 and p.z > -2.05 and p.y > -.95 and p.y < .35:
				var distance: float = rock.global_position.distance_to(socket.global_position)
				if distance < nearest and rock.linear_velocity.length() < 3:
					candidate = rock
					nearest = distance
	if pickup_ring != null:
		pickup_ring.visible = candidate != null
		if candidate != null:
			pickup_ring.global_position = Vector3(candidate.global_position.x,.05,candidate.global_position.z)

func interact_bucket() -> void:
	if busy: return
	interaction_serial += 1
	var serial := interaction_serial
	if held != null:
		busy = true
		dump_elapsed = 0.0
		target_curl = DUMP_ANGLE
		interaction.emit("Tipping bucket…")
		await get_tree().create_timer(.90,false).timeout
		if serial != interaction_serial: return
		var rock := held
		held = null
		# Clear the lip before enabling dynamics to avoid an explosive overlap.
		var out := -upper.global_basis.z
		rock.global_position = bucket.global_position+out*1.38+Vector3(0,-.05,0)
		rock.release_from_bucket(velocity*0.7+out*.75+Vector3(0,-.3,0))
		interaction.emit("Boulder released. Let it settle in the marked bay.")
		dropped.emit()
		await get_tree().create_timer(.55,false).timeout
		if serial != interaction_serial: return
		target_curl = OPEN_ANGLE
		busy = false
	elif candidate != null:
		busy = true
		held = candidate
		candidate = null
		held.attach_to_bucket()
		target_curl = CLOSED_ANGLE
		interaction.emit("Bucket secured. Lift the arm or press B for travel height.")
		scooped.emit()
		await get_tree().create_timer(.65,false).timeout
		if serial != interaction_serial: return
		busy = false
	else:
		interaction.emit("Bring the open bucket around a boulder. Use arrows to adjust the arm.")

func reset_vehicle() -> void:
	interaction_serial += 1
	held = null
	candidate = null
	busy = false
	global_position = Vector3.ZERO
	global_rotation = Vector3.ZERO
	upper.rotation = Vector3.ZERO
	drive_speed = 0
	velocity = Vector3.ZERO
	reach = 3.9
	target_reach = reach
	lift = 1.0
	target_lift = lift
	curl = OPEN_ANGLE
	target_curl = curl
	_solve_arm()
	socket_last = socket.global_position

func _cache_treads(node: Node) -> void:
	# Export names retain a numeric suffix; both the shoe and grip share a phase.
	var label := String(node.name)
	if node is Node3D and ("tread" in label or "trackgrip" in label or "track grip" in label):
		var index := int(label.right(2))
		track_parts.append({"node":node,"index":index,"left":label.begins_with("Left"),"grip":"grip" in label})
	for child in node.get_children():
		_cache_treads(child)

func _animate_tracks() -> void:
	var circumference := 6.0+TAU*.42
	for part in track_parts:
		var phase: float = left_track_phase if part.left else right_track_phase
		var t := fposmod(part.index/42.0*circumference+phase,circumference)
		var z: float
		var y: float
		var angle := 0.0
		if t < 3.0:
			z = -1.5+t
			y = .98
		elif t < 3.0+PI*.42:
			angle = (t-3.0)/.42
			z = 1.5+.42*sin(angle)
			y = .56+.42*cos(angle)
		elif t < 6.0+PI*.42:
			z = 1.5-(t-3.0-PI*.42)
			y = .14
			angle = PI
		else:
			angle = PI+(t-6.0-PI*.42)/.42
			z = -1.5+.42*sin(angle)
			y = .56+.42*cos(angle)
		if part.grip:
			y += .055*cos(angle)
			z += .055*sin(angle)
		part.node.position.y = y
		part.node.position.z = z
		part.node.rotation.x = -angle
