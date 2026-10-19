class_name ExcavatorGame
extends GameBase

# Scoop & carry: tap a pebble, then tap the star. The arm works by itself.
var digger: Excavator

func _build_world() -> void:
	test_flag = "--smoke-test"
	test_script = "res://tests/gameplay_test.gd"
	var yard := Yard.new()
	yard.name = "ConstructionSite"
	yard.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(yard)
	digger = Excavator.new()
	digger.name = "Digger"
	digger.position = Playground.START
	digger.rotation.y = Excavator.START_YAW
	digger.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(digger)
	vehicle = digger
	for i in 3:
		var rock := Boulder.new()
		rock.name = "Pebble%d"%(i+1)
		rock.position = Playground.SPAWNS[i]
		rock.rock_id = i
		rock.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(rock)
		rock.settled.connect(_on_rock_settled.bind(rock))
	digger.scooped.connect(_play_sound.bind("scoop"))
	digger.dropped.connect(_play_sound.bind("plop"))

func _on_rock_settled(rock: Boulder) -> void:
	# Stars are keepsakes: a pebble delivered twice still counts once.
	if rock.rewarded: return
	rock.rewarded = true
	_award_star("Lovely!")

func pointer_action(screen_position: Vector2) -> void:
	if digger.busy: return
	# Generous screen-space hit targets, including the floating star itself.
	if digger.held == null:
		var closest: Boulder
		var distance := 58.0
		for rock: Boulder in get_tree().get_nodes_in_group("boulders"):
			if rock.carried: continue
			var d := camera.unproject_position(rock.global_position).distance_to(screen_position)
			if d<distance:
				distance = d
				closest = rock
		if closest != null:
			digger.collect(closest)
			return
	var hit: Variant = ground_point(screen_position)
	if hit == null: return
	var point: Vector3 = hit
	var goal_screen := camera.unproject_position(Playground.DROP_CENTER+Vector3(0,2.35,-.3))
	var on_garden := Vector2(point.x-Playground.DROP_CENTER.x,point.z-Playground.DROP_CENTER.z).length()<Playground.DROP_RADIUS
	if digger.held != null and (on_garden or goal_screen.distance_to(screen_position)<72):
		# Give each pebble a comfy spot; no precision dropping or pile balancing.
		var offset := [Vector3(-1.0,0,0),Vector3(.9,0,-.9),Vector3(.8,0,1.0)][digger.held.rock_id] as Vector3
		digger.drop_at(Playground.DROP_CENTER+offset)
	elif in_yard(point):
		digger.go_to(point)

func reset_yard() -> void:
	super.reset_yard()
	for rock: Boulder in get_tree().get_nodes_in_group("boulders"): rock.reset_rock()

func _capture() -> void:
	await get_tree().create_timer(2.0).timeout
	var path := "res://screenshots/yard.png"
	if has_flag("--capture-loaded"):
		digger.collect(get_node("Pebble1"))
		await get_tree().create_timer(6.0).timeout
		path = "res://screenshots/carrying.png"
	await _capture_screen(path)
	_shutdown_audio()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()
