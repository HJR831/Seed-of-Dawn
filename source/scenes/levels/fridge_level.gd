extends Node2D

signal ending_requested(ending_id: StringName)

const EndingResolverScript := preload("res://systems/ending_resolver.gd")
const GeneratorScript := preload("res://systems/procedural_map_generator.gd")
const SPROUT_SCENE := preload("res://scenes/player/sprout.tscn")
const BARRIER_SCENE := preload("res://scenes/gameplay/charge_barrier.tscn")
const STICKY_AREA_SCENE := preload("res://scenes/gameplay/sticky_area.tscn")
const FROST_AREA_SCENE := preload("res://scenes/gameplay/frost_area.tscn")
const PICKUP_SCENE := preload("res://scenes/gameplay/pickup.tscn")
const INTERACTABLE_SCENE := preload("res://scenes/gameplay/interactable.tscn")
const NARRATIVE_TRIGGER_SCENE := preload("res://scenes/gameplay/narrative_trigger.tscn")
const RITUAL_TRACKER_SCENE := preload("res://scenes/gameplay/ritual_tracker.tscn")
const ENDING_ENTRANCE_SCENE := preload("res://scenes/gameplay/ending_entrance.tscn")
const DIALOGUE_BOX_SCENE := preload("res://scenes/ui/dialogue_box.tscn")
const DEBUG_PANEL_SCENE := preload("res://scenes/ui/debug_panel.tscn")
const INVENTORY_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const ROUTE_FLAG_SCRIPT := preload("res://scenes/gameplay/route_flag_area.gd")
const COUNTER_CONSOLE_SCRIPT := preload("res://scenes/gameplay/counter_console.gd")
const SEQUENCE_CONSOLE_SCRIPT := preload("res://scenes/gameplay/sequence_console.gd")
const COMPRESSOR_IDLE_SCRIPT := preload("res://scenes/gameplay/compressor_idle_ritual.gd")

var map_plan: Dictionary = {}
var player: CharacterBody2D
var progress_label: Label
var stage_label: Label
var seed_label: Label
var ending_started := false
var stage_markers: Array[Marker2D] = []


func _ready() -> void:
	var game_state := get_node("/root/GameState")
	map_plan = GeneratorScript.generate(game_state.run_seed)
	_build_darkness()
	_build_stage_markers()
	_build_world_collision()
	_spawn_player()
	_build_charge_barriers()
	_build_material_feedback()
	_build_pickups_and_interactions()
	_build_rituals()
	_build_route_mechanics()
	_build_ending_entrances()
	_build_world_labels()
	_build_hud()
	_build_narrative_and_ui()
	queue_redraw()


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var radius := player.global_position.distance_to(map_plan.center)
	var progress := clampf(radius / float(map_plan.outer_radius), 0.0, 1.0)
	progress_label.text = "向冰箱外壳生长  %d%%" % roundi(progress * 100.0)
	stage_label.text = _stage_name_for_radius(radius)


func _draw() -> void:
	if map_plan.is_empty():
		return
	var center: Vector2 = map_plan.center
	draw_rect(map_plan.bounds, Color(0.006, 0.009, 0.020))
	draw_circle(center, float(map_plan.outer_radius), Color(0.055, 0.070, 0.105))
	draw_circle(center, 3350.0, Color(0.060, 0.085, 0.130))
	draw_circle(center, 2700.0, Color(0.080, 0.115, 0.135))
	draw_circle(center, 1800.0, Color(0.105, 0.135, 0.120))
	draw_circle(center, 900.0, Color(0.170, 0.115, 0.090))
	for radius in [700.0, 1700.0, 2800.0, 3800.0]:
		draw_arc(center, radius, 0.0, TAU, 128, Color(0.30, 0.38, 0.52, 0.34), 4.0)
	for index in range(int(map_plan.sector_count)):
		var angle := float(map_plan.rotation) + TAU * float(index) / float(map_plan.sector_count)
		draw_line(center + Vector2.RIGHT.rotated(angle) * 720.0, center + Vector2.RIGHT.rotated(angle) * 3780.0, Color(0.24, 0.30, 0.42, 0.20), 5.0)
	for region_id in map_plan.regions:
		var color := Color(0.26, 0.46, 0.18, 0.16) if str(region_id).begins_with("rot") else Color(0.42, 0.70, 1.0, 0.12)
		draw_circle(map_plan.regions[region_id], 220.0, color)
	var bottle := get_location(&"titan_bottle")
	draw_rect(Rect2(bottle - Vector2(110, 180), Vector2(220, 360)), Color(0.53, 0.10, 0.09, 0.94))
	draw_circle(get_location(&"yellow_cap"), 75.0, Color(0.94, 0.75, 0.16, 0.92))
	draw_circle(center, 110.0, Color(0.36, 0.20, 0.12, 0.92))


func get_world_bounds() -> Rect2:
	return map_plan.get("bounds", Rect2(Vector2.ZERO, Vector2(8192, 8192)))


func get_stage_marker_position(index: int) -> Vector2:
	if stage_markers.is_empty():
		return map_plan.get("spawn", Vector2(4096, 4096))
	return stage_markers[clampi(index, 0, stage_markers.size() - 1)].global_position


func get_location(location_id: StringName) -> Vector2:
	return map_plan.get("locations", {}).get(location_id, map_plan.get("center", Vector2(4096, 4096)))


func get_generation_summary() -> Dictionary:
	return {"seed": map_plan.get("requested_seed", 1), "actual_seed": map_plan.get("seed", 1), "sector_count": map_plan.get("sector_count", 0), "attempt": map_plan.get("attempt", 0), "used_fallback": map_plan.get("used_fallback", false), "validation_errors": map_plan.get("validation_errors", [])}


func set_player_input_enabled(enabled: bool) -> void:
	if is_instance_valid(player) and player.has_method("set_input_enabled"):
		player.set_input_enabled(enabled)


func _build_darkness() -> void:
	var darkness := CanvasModulate.new()
	darkness.name = "Darkness"
	darkness.color = Color(0.31, 0.35, 0.50)
	add_child(darkness)


func _build_stage_markers() -> void:
	var gate_angle: float = map_plan.ring_gates[0][0]
	var radii := [0.0, 1250.0, 2150.0, 3050.0, 3500.0]
	for index in range(radii.size()):
		var marker := Marker2D.new()
		marker.name = ["BirthMarker", "RotMarker", "FilmMarker", "FrostMarker", "OuterMarker"][index]
		marker.position = map_plan.center + Vector2.RIGHT.rotated(gate_angle) * radii[index]
		marker.add_to_group(&"stage_marker")
		add_child(marker)
		stage_markers.append(marker)


func _spawn_player() -> void:
	player = SPROUT_SCENE.instantiate()
	player.name = "Sprout"
	player.add_to_group(&"player")
	player.global_position = map_plan.spawn
	add_child(player)
	player.set_camera_limits(get_world_bounds())


func _build_world_collision() -> void:
	for wall_data in map_plan.wall_rects:
		_create_static_rect(wall_data.center, wall_data.size, Color(0.20, 0.25, 0.34), wall_data.rotation)
	var bottle := _create_static_rect(get_location(&"titan_bottle"), Vector2(220, 360), Color(0.53, 0.10, 0.09))
	bottle.name = "TitanBottle"
	var cap := _create_static_rect(get_location(&"yellow_cap"), Vector2(150, 100), Color(0.94, 0.75, 0.16))
	cap.name = "YellowBottleCap"


func _build_charge_barriers() -> void:
	_create_barrier("LowerPlasticFilm", map_plan.regions[&"film_field"], Vector2(520, 38), 1.0, false)
	_create_barrier("UpperPlasticFilm", get_location(&"bottle_lever") + Vector2(260, 0), Vector2(420, 38), 1.15, false)
	_create_barrier("FinalLid", get_location(&"final_lid"), Vector2(430, 58), 1.75, true)


func _create_barrier(barrier_name: String, at_position: Vector2, size: Vector2, hold_seconds: float, is_final: bool) -> void:
	var barrier := BARRIER_SCENE.instantiate()
	barrier.name = barrier_name
	barrier.position = at_position
	barrier.barrier_size = size
	barrier.required_hold_seconds = hold_seconds
	barrier.is_final_barrier = is_final
	barrier.barrier_color = Color(0.72, 0.88, 1.0, 0.42 if not is_final else 0.68)
	barrier.prompt_text = "[空格] 长按顶开最后苍穹" if is_final else "[空格] 长按撕裂虚空之茧"
	add_child(barrier)
	barrier.barrier_broken.connect(_on_barrier_broken)


func _on_barrier_broken(is_final: bool) -> void:
	if not is_final:
		get_node("/root/NarrativeManager").request_text(&"film_broken")
		return
	var result: Dictionary = EndingResolverScript.request_ending(&"top_lid", get_node("/root/GameState").make_snapshot())
	if bool(result.get("matched", false)):
		_request_ending(result.get("ending_id", &""), &"top_lid")


func _build_material_feedback() -> void:
	_create_sticky("RottenSlimeA", map_plan.regions[&"rot_slime_1"], Vector2(420, 260), Color(0.18, 0.34, 0.12, 0.72), &"touched_black_water")
	_create_sticky("RottenSlimeB", map_plan.regions[&"rot_slime_2"], Vector2(480, 240), Color(0.21, 0.32, 0.13, 0.66))
	for index in range(1, 4):
		_create_frost("FrostPatch%d" % index, map_plan.regions[StringName("frost_field_%d" % index)], Vector2(430, 300))


func _create_sticky(zone_name: String, at_position: Vector2, size: Vector2, color: Color, flag_id: StringName = &"") -> void:
	var sticky := STICKY_AREA_SCENE.instantiate()
	sticky.name = zone_name
	sticky.position = at_position
	sticky.area_size = size
	sticky.area_color = color
	sticky.flag_on_enter = flag_id
	add_child(sticky)


func _create_frost(zone_name: String, at_position: Vector2, size: Vector2) -> void:
	var frost := FROST_AREA_SCENE.instantiate()
	frost.name = zone_name
	frost.position = at_position
	frost.area_size = size
	add_child(frost)


func _build_pickups_and_interactions() -> void:
	get_node("/root/GameState").optional_nutrients_total = 6
	_spawn_pickup("DateTablet", &"date_tablet", &"date_tablet", &"pickup_date_tablet", Color(0.91, 0.77, 0.48))
	_spawn_pickup("CorruptEye", &"corrupt_eye", &"corrupt_eye", &"relic_corrupt_eye", Color(0.69, 0.12, 0.76), &"", &"corruption", 1)
	_spawn_pickup("ScarletOintment", &"scarlet_ointment", &"scarlet_ointment", &"relic_scarlet_ointment", Color(0.94, 0.16, 0.10), &"", &"corruption", 1)
	_spawn_pickup("FrozenHeart", &"frozen_heart", &"frozen_heart", &"relic_frozen_heart", Color(0.50, 0.88, 1.0), &"", &"corruption", 1)
	for index in range(1, 4):
		_spawn_pickup("MilkDrop%d" % index, StringName("milk_drop_%d" % index), StringName("milk_drop_%d" % index), &"milk_drop_found", Color(0.96, 0.97, 0.86), &"milk_count")
	_spawn_pickup("GoldenScale", &"golden_scale", &"golden_scale", &"golden_scale_found", Color(1.0, 0.72, 0.12))
	for index in range(1, 4):
		_spawn_pickup("CleanWater%d" % index, StringName("clean_water_%d" % index), StringName("clean_water_%d" % index), &"clean_water_found", Color(0.55, 0.90, 1.0), &"clean_water_count")
	_spawn_pickup("DoorSoil", &"door_soil", &"door_soil", &"door_soil_found", Color(0.58, 0.36, 0.18))
	_spawn_pickup("FlowerpotReceipt", &"flowerpot_receipt", &"flowerpot_receipt", &"flowerpot_receipt_found", Color(0.92, 0.88, 0.68))
	for index in range(1, 4):
		_spawn_pickup("SaleTag%d" % index, StringName("sale_tag_%d" % index), StringName("sale_tag_%d" % index), &"sale_tag_found", Color(1.0, 0.42, 0.28), &"barcode_count")
	for index in range(1, 7):
		_spawn_pickup("Nutrient%d" % index, StringName("nutrient_%d" % index), StringName("nutrient_%d" % index), &"nutrient_absorbed", Color(0.50, 0.70, 0.24), &"nutrient_count", &"devour", 1)
	for index in range(1, 5):
		_spawn_pickup("FrostCrystal%d" % index, StringName("frost_crystal_%d" % index), StringName("frost_crystal_%d" % index), &"frost_crystal_found", Color(0.66, 0.91, 1.0), &"frost_count")
	_spawn_pickup("SleepingStone", &"sleeping_stone", &"sleeping_stone", &"sleeping_stone_found", Color(0.42, 0.78, 0.96))
	_spawn_pickup("AluminumFoil", &"aluminum_foil", &"aluminum_foil", &"root_component_found", Color(0.82, 0.86, 0.92))
	_spawn_pickup("ConductiveWater", &"conductive_water", &"conductive_water", &"root_component_found", Color(0.42, 0.82, 0.94))
	_spawn_pickup("MagnetCore", &"magnet_core", &"magnet_core", &"root_component_found", Color(0.88, 0.50, 0.32))
	_build_bottle_lever()
	_build_companions()


func _spawn_pickup(node_name: String, location_id: StringName, item_id: StringName, text_id: StringName, color: Color, counter_id: StringName = &"", stat_id: StringName = &"", stat_amount: int = 0) -> void:
	var pickup := PICKUP_SCENE.instantiate()
	pickup.name = node_name
	pickup.position = get_location(location_id)
	pickup.item_id = item_id
	pickup.narrative_text_id = text_id
	pickup.pickup_color = color
	pickup.counter_id = counter_id
	pickup.stat_id = stat_id
	pickup.stat_amount = stat_amount
	pickup.collected.connect(_on_pickup_collected)
	add_child(pickup)


func _on_pickup_collected(item_id: StringName) -> void:
	if not is_instance_valid(player):
		return
	var game_state := get_node("/root/GameState")
	if str(item_id).begins_with("milk_drop_"):
		var count: int = int(game_state.get_counter(&"milk_count"))
		if game_state.corruption == 0:
			player.set_visual_stage(&"milk", count)
		get_node("/root/AudioManager").play_sfx([&"milk_do", &"milk_re", &"milk_mi"][clampi(count - 1, 0, 2)])
	elif item_id in [&"corrupt_eye", &"scarlet_ointment", &"frozen_heart"]:
		var relic_count := 0
		for relic_id in [&"corrupt_eye", &"scarlet_ointment", &"frozen_heart"]:
			if game_state.has_item(relic_id):
				relic_count += 1
		player.set_visual_stage(&"eldritch", relic_count)
	elif str(item_id).begins_with("nutrient_"):
		game_state.optional_nutrients_eaten += 1
	elif str(item_id).begins_with("frost_crystal_"):
		player.set_visual_stage(&"frost", game_state.get_counter(&"frost_count"))


func _build_bottle_lever() -> void:
	var lever := INTERACTABLE_SCENE.instantiate()
	lever.name = "BottleLever"
	lever.position = get_location(&"bottle_lever")
	lever.item_id = &"bottle_lever"
	lever.short_action = &"bottle_lever"
	lever.hold_action = &"bottle_lever"
	lever.completion_flag = &"bottle_lever"
	lever.narrative_text_id = &"bottle_lever_complete"
	lever.consumed_after_use = false
	lever.object_color = Color(0.92, 0.48, 0.24)
	add_child(lever)


func _build_companions() -> void:
	for data in [["OnionCompanion", &"companion_onion", &"companion_onion_watered", Color(0.62, 0.40, 0.78)], ["GarlicCompanion", &"companion_garlic", &"companion_garlic_watered", Color(0.88, 0.88, 0.70)], ["GingerCompanion", &"companion_ginger", &"companion_ginger_watered", Color(0.68, 0.42, 0.20)]]:
		var companion := INTERACTABLE_SCENE.instantiate()
		companion.name = data[0]
		companion.position = get_location(data[1])
		companion.item_id = data[1]
		companion.required_counter_id = &"clean_water_count"
		companion.required_counter_minimum = 3
		companion.completion_flag = data[2]
		companion.completion_action = &"nurture"
		companion.narrative_text_id = &"companion_watered"
		companion.consumed_after_use = false
		companion.object_color = data[3]
		add_child(companion)


func _build_rituals() -> void:
	_create_ritual("BottleCounterclockwiseRitual", get_location(&"titan_bottle"), &"bottle_counterclockwise", "counterclockwise", 270.0, &"ritual_bottle_complete", Color(0.72, 0.28, 0.88, 0.42))
	_create_ritual("YellowCapRitual", get_location(&"yellow_cap"), &"yellow_cap_loop", "clockwise", 210.0, &"ritual_cap_complete", Color(1.0, 0.75, 0.18, 0.48))
	_create_ritual("RootNetworkRitual", get_location(&"root_network"), &"root_network_loop", "clockwise", 230.0, &"root_network_complete", Color(0.32, 0.84, 0.48, 0.50))
	_create_ritual("SelfSeedRitual", get_location(&"freezer_seed_loop"), &"self_seed_loop", "counterclockwise", 190.0, &"self_seed_loop_complete", Color(0.55, 0.86, 1.0, 0.52))


func _create_ritual(node_name: String, at_position: Vector2, ritual_id: StringName, direction: String, radius: float, text_id: StringName, color: Color) -> void:
	var ritual := RITUAL_TRACKER_SCENE.instantiate()
	ritual.name = node_name
	ritual.position = at_position
	ritual.ritual_id = ritual_id
	ritual.direction = direction
	ritual.radius = radius
	ritual.success_text_id = text_id
	ritual.ring_color = color
	add_child(ritual)


func _build_route_mechanics() -> void:
	var thermostat = COUNTER_CONSOLE_SCRIPT.new()
	thermostat.name = "ThermostatConsole"
	thermostat.position = get_location(&"thermostat")
	thermostat.counter_id = &"thermostat_level"
	thermostat.target_value = 7
	thermostat.complete_flag = &"thermostat_seventh"
	thermostat.prompt_text = "轻按 E 将寒冷推向第七格"
	add_child(thermostat)
	var sequence = SEQUENCE_CONSOLE_SCRIPT.new()
	sequence.name = "RootNodeSequence"
	sequence.position = get_location(&"electric_sequence")
	add_child(sequence)
	var idle_ritual = COMPRESSOR_IDLE_SCRIPT.new()
	idle_ritual.name = "CompressorIdleRitual"
	idle_ritual.position = get_location(&"freezer_seed_loop")
	add_child(idle_ritual)
	_create_route_flag("FinalUnlockMarker", get_location(&"final_unlock_marker"), &"final_route_unlocked")
	_create_route_flag("ReturnMarker", get_location(&"return_marker"), &"returned_after_final_unlock", &"final_route_unlocked")


func _create_route_flag(node_name: String, at_position: Vector2, flag_id: StringName, required_flag: StringName = &"") -> void:
	var area = ROUTE_FLAG_SCRIPT.new()
	area.name = node_name
	area.position = at_position
	area.flag_id = flag_id
	area.required_flag = required_flag
	add_child(area)


func _build_ending_entrances() -> void:
	_create_entrance("LightSwitchEntrance", &"light_switch", &"light_switch_hold", "hold", 7.0, "长按 E 七秒，让伪太阳失明", Color(0.92, 0.94, 1.0, 0.75))
	_create_entrance("DragonShrineEntrance", &"dragon_shrine", &"dragon_shrine_idle", "idle", 3.0, "旧像凝视着蜷缩不动的根须", Color(1.0, 0.78, 0.25, 0.78))
	_create_entrance("WarmDoorEntrance", &"warm_door_gap", &"warm_door_gap", "hold", 1.5, "暖风从侧面的缝隙吹来", Color(1.0, 0.62, 0.28, 0.82))
	_create_entrance("RootNetworkEntrance", &"root_network_exit", &"root_network_complete", "hold", 1.2, "让养分流过完整根网", Color(0.36, 0.90, 0.50, 0.80))
	_create_entrance("BarcodeTerminalEntrance", &"barcode_terminal", &"barcode_terminal", "hold", 1.2, "芽尖扫描季度增长报表", Color(1.0, 0.30, 0.24, 0.82))
	_create_entrance("FreezerAlcoveEntrance", &"freezer_alcove", &"freezer_alcove", "idle", 1.2, "在凹槽中停止伸长", Color(0.54, 0.86, 1.0, 0.82))
	_create_entrance("TemperatureProbeEntrance", &"temperature_probe", &"temperature_probe", "hold", 2.0, "钻入温控探针，索取 ROOT 权限", Color(0.95, 0.72, 0.18, 0.82))


func _create_entrance(node_name: String, location_id: StringName, trigger_id: StringName, mode: String, seconds: float, prompt: String, color: Color) -> void:
	var entrance := ENDING_ENTRANCE_SCENE.instantiate()
	entrance.name = node_name
	entrance.position = get_location(location_id)
	entrance.trigger_id = trigger_id
	entrance.activation_mode = mode
	entrance.required_seconds = seconds
	entrance.prompt_text = prompt
	entrance.entrance_color = color
	entrance.ending_requested.connect(_on_special_ending_requested)
	add_child(entrance)


func _on_special_ending_requested(ending_id: StringName) -> void:
	_request_ending(ending_id, &"special_entrance")


func _request_ending(ending_id: StringName, exit_id: StringName) -> void:
	if ending_started or ending_id.is_empty():
		return
	ending_started = true
	var game_state := get_node("/root/GameState")
	game_state.last_exit = exit_id
	set_player_input_enabled(false)
	get_node("/root/NarrativeManager").clear_queue()
	await get_tree().create_timer(0.4).timeout
	ending_requested.emit(ending_id)


func _build_narrative_and_ui() -> void:
	add_child(DIALOGUE_BOX_SCENE.instantiate())
	add_child(DEBUG_PANEL_SCENE.instantiate())
	add_child(INVENTORY_SCENE.instantiate())
	_create_narrative_trigger(&"prologue", map_plan.center, Vector2(420, 300))
	for index in range(1, 5):
		_create_narrative_trigger([&"stage_rot", &"stage_film", &"stage_frost", &"stage_final"][index - 1], get_stage_marker_position(index), Vector2(420, 300))


func _create_narrative_trigger(text_id: StringName, at_position: Vector2, size: Vector2) -> void:
	var trigger := NARRATIVE_TRIGGER_SCENE.instantiate()
	trigger.position = at_position
	trigger.text_id = text_id
	trigger.trigger_size = size
	add_child(trigger)


func _build_world_labels() -> void:
	_create_world_label("泰坦赤柱 · 逆行者之环", get_location(&"titan_bottle") + Vector2(-250, 230), Color(1.0, 0.52, 0.43))
	_create_world_label("黄金卵壳 · 绕行成形", get_location(&"yellow_cap") + Vector2(-240, 130), Color(1.0, 0.80, 0.28))
	_create_world_label("三环之外仍有道路", map_plan.center + Vector2(-250, -420), Color(0.76, 0.70, 0.90))


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	canvas.layer = 30
	add_child(canvas)
	var panel := ColorRect.new()
	panel.position = Vector2(22, 18)
	panel.size = Vector2(500, 132)
	panel.color = Color(0.015, 0.022, 0.055, 0.84)
	canvas.add_child(panel)
	progress_label = Label.new()
	progress_label.position = Vector2(42, 30)
	progress_label.size = Vector2(460, 32)
	progress_label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(progress_label)
	stage_label = Label.new()
	stage_label.position = Vector2(42, 66)
	stage_label.size = Vector2(460, 28)
	stage_label.add_theme_font_size_override("font_size", 18)
	stage_label.add_theme_color_override("font_color", Color(0.68, 0.75, 0.92))
	canvas.add_child(stage_label)
	seed_label = Label.new()
	seed_label.position = Vector2(42, 98)
	seed_label.size = Vector2(460, 25)
	seed_label.add_theme_font_size_override("font_size", 15)
	seed_label.add_theme_color_override("font_color", Color(0.52, 0.60, 0.74))
	seed_label.text = "RUN SEED %d · %d 扇区" % [map_plan.requested_seed, map_plan.sector_count]
	canvas.add_child(seed_label)
	var controls := Label.new()
	controls.position = Vector2(535, 26)
	controls.size = Vector2(720, 44)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_theme_font_size_override("font_size", 17)
	controls.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))
	controls.text = "移动 WASD/方向键 · E 互动 · Space 蓄力 · I/Tab 背包 · F3 调试"
	canvas.add_child(controls)
	var build_tag := Label.new()
	build_tag.position = Vector2(875, 678)
	build_tag.size = Vector2(380, 28)
	build_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	build_tag.add_theme_font_size_override("font_size", 15)
	build_tag.add_theme_color_override("font_color", Color(0.48, 0.52, 0.65))
	build_tag.text = "GRAYBOX 20–32H · SEEDED RADIAL MAP"
	canvas.add_child(build_tag)


func _create_static_rect(center: Vector2, size: Vector2, color: Color, body_rotation: float = 0.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center
	body.rotation = body_rotation
	body.collision_layer = 1
	body.collision_mask = 0
	body.name = "Obstacle"
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	body.add_child(collision)
	var polygon := Polygon2D.new()
	var half := size * 0.5
	polygon.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	polygon.color = color
	body.add_child(polygon)
	add_child(body)
	return body


func _create_world_label(text_value: String, at_position: Vector2, color: Color) -> void:
	var label := Label.new()
	label.position = at_position
	label.size = Vector2(620, 42)
	label.text = text_value
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.z_index = 4
	add_child(label)


func _stage_name_for_radius(radius: float) -> String:
	if radius < 700.0:
		return "核心：母薯安全区"
	if radius < 1700.0:
		return "第一环：腐土与现实线索"
	if radius < 2800.0:
		return "第二环：保鲜膜与沉睡者"
	if radius < 3800.0:
		return "第三环：赤柱、霜毒与线路"
	return "外壳：终局出口"
