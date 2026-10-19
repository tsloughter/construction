class_name BulldozerGame
extends GameBase

# Push & fill: drive boulders into any open hole, or tap one for help.
var dozer: Bulldozer

func _build_world() -> void:
	test_flag = "--bulldozer-test"
	test_script = "res://tests/bulldozer_test.gd"
	var yard := DozerYard.new()
	yard.name = "ConstructionSite"
	yard.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(yard)
	dozer = Bulldozer.new()
	dozer.name = "Bulldozer"
	dozer.position = DozerLayout.START
	dozer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(dozer)
	vehicle = dozer
	for i in 3:
		var rock := PushBoulder.new()
		rock.name = "Pebble%d"%(i+1)
		rock.position = DozerLayout.SPAWNS[i]
		rock.rock_id = i
		rock.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(rock)
		rock.dropped_in_hole.connect(_on_rock_dropped.bind(rock))

func _configure_hud() -> void:
	hud.bulldozer_mode = true

func _on_rock_dropped(rock: PushBoulder) -> void:
	if rock.rewarded: return
	rock.rewarded = true
	_award_star("You filled a hole!")

func pointer_action(screen_position: Vector2) -> void:
	var nearest: PushBoulder
	var distance := 62.0
	for rock: PushBoulder in get_tree().get_nodes_in_group("boulders"):
		if rock.completed: continue
		var d := camera.unproject_position(rock.global_position).distance_to(screen_position)
		if d<distance:
			distance = d
			nearest = rock
	if nearest:
		dozer.push_rock(nearest)
		return
	var hit: Variant = ground_point(screen_position)
	if hit != null and in_yard(hit): dozer.go_to(hit)

func reset_yard() -> void:
	for hole: FillHole in get_tree().get_nodes_in_group("holes"): hole.reset_hole()
	super.reset_yard()
	for rock: PushBoulder in get_tree().get_nodes_in_group("boulders"): rock.reset_rock()

func _capture() -> void:
	await get_tree().create_timer(2).timeout
	var filled := has_flag("--capture-filled")
	if filled:
		dozer.action()
		await get_tree().create_timer(8).timeout
	await _capture_screen("res://screenshots/bulldozer-filled.png" if filled else "res://screenshots/bulldozer.png")
	_shutdown_audio()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()
