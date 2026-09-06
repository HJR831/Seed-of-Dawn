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
const INVENTORY_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const ITEM_DETAIL_POPUP_SCENE := preload("res://scenes/ui/item_detail_popup.gd")
const MAP_PANEL_SCENE := preload("res://scenes/ui/map_panel.tscn")
const GUIDANCE_OVERLAY_SCENE := preload("res://scenes/ui/guidance_overlay.tscn")
const KEY_HINT_SCRIPT := preload("res://scenes/ui/key_hint_overlay.gd")
const SPRINT_METER_SCRIPT := preload("res://scenes/ui/sprint_meter_overlay.gd")
const ROUTE_FLAG_SCRIPT := preload("res://scenes/gameplay/route_flag_area.gd")
const COUNTER_CONSOLE_SCRIPT := preload("res://scenes/gameplay/counter_console.gd")
const SEQUENCE_CONSOLE_SCRIPT := preload("res://scenes/gameplay/sequence_console.gd")
const COMPRESSOR_IDLE_SCRIPT := preload("res://scenes/gameplay/compressor_idle_ritual.gd")
const STILLNESS_COMMAND_SCRIPT := preload("res://scenes/gameplay/stillness_command.gd")
const DIRECTIONAL_TRIAL_SCRIPT := preload("res://scenes/gameplay/directional_trial.gd")
const CHUNK_MANAGER_SCRIPT := preload("res://systems/world_chunk_manager.gd")
const MAP_TOP := 1200.0
const MAP_BOTTOM := 24400.0

var map_plan: Dictionary = {}
var player: CharacterBody2D
var ending_started := false
var stage_markers: Array[Marker2D] = []
var chunk_manager: Node
var _backplate_textures: Array[Texture2D] = []
var _bottle_texture: Texture2D
var _cap_texture: Texture2D
var _mother_texture: Texture2D


func _ready() -> void:
	var game_state := get_node("/root/GameState")
	map_plan = GeneratorScript.generate(game_state.run_seed)
	var asset_library := get_node_or_null("/root/AssetLibrary")
	if asset_library != null:
		for index in range(1, 7):
			var backplate: Texture2D = asset_library.get_texture(StringName("env_fridge_backplate_tile_%02d.png" % index))
			if backplate != null:
				_backplate_textures.append(backplate)
		_bottle_texture = asset_library.get_texture(&"env_hot_sauce_bottle.png")
		_cap_texture = asset_library.get_texture(&"env_yellow_milk_cap_front.png")
		_mother_texture = asset_library.get_texture(&"env_mother_potato.png")
	get_node("/root/MapKnowledgeManager").configure(map_plan)
	get_node("/root/GuidanceDirector").configure(map_plan)
	_build_darkness()
	_build_stage_markers()
	_build_world_collision()
	_spawn_player()
	_build_chunk_manager()
	_build_charge_barriers()
	_build_material_feedback()
	_build_pickups_and_interactions()
	_build_rituals()
	_build_route_mechanics()
	_build_ending_entrances()
	_build_world_labels()
	_build_narrative_and_ui()
	queue_redraw()


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	get_node("/root/MapKnowledgeManager").update_player_position(player.global_position)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("set_background_layer"):
		audio.set_background_layer(get_layer_index_for_position(player.global_position))


func _draw() -> void:
	if map_plan.is_empty():
		return
	var layer_colors := [Color(0.17, 0.11, 0.09), Color(0.12, 0.13, 0.10), Color(0.10, 0.15, 0.13), Color(0.075, 0.13, 0.15), Color(0.065, 0.11, 0.16), Color(0.055, 0.085, 0.14), Color(0.045, 0.06, 0.11)]
	var world_bounds: Rect2 = map_plan.bounds
	draw_rect(world_bounds, Color(0.006, 0.009, 0.020))
	var layer_bounds: Array = map_plan.get("layer_bounds", [])
	if not layer_bounds.is_empty():
		# The seven ecological layers intentionally stop short of the logical
		# world edge. Fill the top and bottom margins so the camera never reveals
		# the black base rectangle below the lowest layer.
		var bottom_layer: Vector2 = layer_bounds[0]
		var top_layer: Vector2 = layer_bounds[layer_bounds.size() - 1]
		var world_bottom := world_bounds.position.y + world_bounds.size.y
		if bottom_layer.y < world_bottom:
			var bottom_gap := Rect2(world_bounds.position.x, bottom_layer.y, world_bounds.size.x, world_bottom - bottom_layer.y)
			draw_rect(bottom_gap, layer_colors[0])
			if not _backplate_textures.is_empty():
				draw_texture_rect(_backplate_textures[0], bottom_gap, true, Color(0.82, 0.88, 1.0, 0.72))
		if top_layer.x > world_bounds.position.y:
			var top_gap := Rect2(world_bounds.position.x, world_bounds.position.y, world_bounds.size.x, top_layer.x - world_bounds.position.y)
			draw_rect(top_gap, layer_colors[layer_colors.size() - 1])
			if not _backplate_textures.is_empty():
				draw_texture_rect(_backplate_textures[(layer_colors.size() - 1) % _backplate_textures.size()], top_gap, true, Color(0.82, 0.88, 1.0, 0.72))
	for index in range(layer_bounds.size()):
		var layer_limit: Vector2 = layer_bounds[index]
		var layer_rect := Rect2(0.0, layer_limit.x, map_plan.bounds.size.x, layer_limit.y - layer_limit.x)
		draw_rect(layer_rect, layer_colors[index])
		if not _backplate_textures.is_empty():
			var tile := _backplate_textures[index % _backplate_textures.size()]
			draw_texture_rect(tile, layer_rect, true, Color(0.82, 0.88, 1.0, 0.72))
		# Ecological identity is a tint over the art, never an opaque cover.
		draw_rect(layer_rect, Color(layer_colors[index], 0.34))
		draw_line(Vector2(0.0, layer_limit.y), Vector2(map_plan.bounds.size.x, layer_limit.y), Color(0.42, 0.50, 0.66, 0.22), 4.0)
	for index in range(layer_bounds.size() - 1):
		var lower_layer: Vector2 = layer_bounds[index]
		var upper_layer: Vector2 = layer_bounds[index + 1]
		var transition_top := upper_layer.y
		var transition_bottom := lower_layer.x
		if transition_bottom > transition_top:
			# The generator keeps a 400px traversal seam between ecological layers.
			# It is playable space, not a void: fill it opaquely with a blended
			# palette so the world never exposes the black base rectangle.
			var transition_rect := Rect2(0.0, transition_top, map_plan.bounds.size.x, transition_bottom - transition_top)
			var transition_color: Color = layer_colors[index].lerp(layer_colors[index + 1], 0.5)
			draw_rect(transition_rect, transition_color)
			if not _backplate_textures.is_empty():
				var seam_tile := _backplate_textures[(index + layer_bounds.size()) % _backplate_textures.size()]
				draw_texture_rect(seam_tile, transition_rect, true, Color(0.70, 0.78, 0.92, 0.38))
			# Thin luminous guide lines preserve layer readability without making
			# an impassable-looking black wall.
			draw_line(Vector2(0.0, transition_top), Vector2(map_plan.bounds.size.x, transition_top), Color(0.52, 0.62, 0.78, 0.28), 2.0)
			draw_line(Vector2(0.0, transition_bottom), Vector2(map_plan.bounds.size.x, transition_bottom), Color(0.52, 0.62, 0.78, 0.28), 2.0)
	for index in range(int(map_plan.sector_count) + 1):
		var x: float = map_plan.bounds.size.x * float(index) / float(map_plan.sector_count)
		draw_line(Vector2(x, MAP_TOP), Vector2(x, MAP_BOTTOM), Color(0.24, 0.30, 0.42, 0.10), 5.0)
	for region_id in map_plan.regions:
		# The slime texture is self-contained; do not draw an additional green
		# region halo around it.
		if str(region_id).begins_with("rot"):
			continue
		var color := Color(0.42, 0.70, 1.0, 0.12)
		if str(region_id).begins_with("warm"): color = Color(1.0, 0.48, 0.18, 0.12)
		elif str(region_id).begins_with("root"): color = Color(0.28, 0.72, 0.36, 0.13)
		elif str(region_id).begins_with("landfill"): color = Color(0.42, 0.46, 0.12, 0.15)
		draw_circle(map_plan.regions[region_id], 220.0, color)
	var bottle := get_location(&"titan_bottle")
	if _bottle_texture != null:
		draw_texture_rect(_bottle_texture, Rect2(bottle - Vector2(110, 180), Vector2(220, 360)), false, Color.WHITE)
	else:
		draw_rect(Rect2(bottle - Vector2(110, 180), Vector2(220, 360)), Color(0.53, 0.10, 0.09, 0.94))
	if _cap_texture != null:
		draw_texture_rect(_cap_texture, Rect2(get_location(&"yellow_cap") - Vector2(75, 50), Vector2(150, 100)), false, Color.WHITE)
	else:
		draw_circle(get_location(&"yellow_cap"), 75.0, Color(0.94, 0.75, 0.16, 0.92))
	if _mother_texture != null:
		draw_texture_rect(_mother_texture, Rect2(get_location(&"mother_potato") - Vector2(110, 110), Vector2(220, 220)), false, Color.WHITE)
	else:
		draw_circle(get_location(&"mother_potato"), 110.0, Color(0.36, 0.20, 0.12, 0.92))


func get_world_bounds() -> Rect2:
	return map_plan.get("bounds", Rect2(Vector2.ZERO, Vector2(25600, 25600)))


func get_loaded_backplate_count() -> int:
	return _backplate_textures.size()


func get_layer_index_for_position(world_position: Vector2) -> int:
	return GeneratorScript.ring_index_for_position(world_position)


func get_stage_marker_position(index: int) -> Vector2:
	if stage_markers.is_empty():
		return map_plan.get("spawn", Vector2(12800, 12800))
	return stage_markers[clampi(index, 0, stage_markers.size() - 1)].global_position


func get_location(location_id: StringName) -> Vector2:
	return map_plan.get("locations", {}).get(location_id, map_plan.get("center", Vector2(12800, 12800)))


func get_generation_summary() -> Dictionary:
	var summary := {"seed": map_plan.get("requested_seed", 1), "actual_seed": map_plan.get("seed", 1), "sector_count": map_plan.get("sector_count", 0), "ring_count": map_plan.get("ring_count", 0), "attempt": map_plan.get("attempt", 0), "used_fallback": map_plan.get("used_fallback", false), "validation_errors": map_plan.get("validation_errors", [])}
	if is_instance_valid(chunk_manager):
		summary["chunks"] = chunk_manager.get_summary()
	return summary


func set_player_input_enabled(enabled: bool) -> void:
	if is_instance_valid(player) and player.has_method("set_input_enabled"):
		player.set_input_enabled(enabled)


func _build_darkness() -> void:
	var darkness := CanvasModulate.new()
	darkness.name = "Darkness"
	darkness.color = Color(0.31, 0.35, 0.50)
	add_child(darkness)


func _build_stage_markers() -> void:
	var layer_bounds: Array = map_plan.get("layer_bounds", [])
	var route_lanes: Array = map_plan.get("route_lanes", [])
	for index in range(layer_bounds.size()):
		var marker := Marker2D.new()
		marker.name = ["BirthMarker", "RotMarker", "FilmMarker", "NetworkMarker", "FrostMarker", "ControlMarker", "OuterMarker"][index]
		var layer_limit: Vector2 = layer_bounds[index]
		var x: float = map_plan.spawn.x
		if route_lanes.size() > 1 and index > 0:
			x = float(route_lanes[1][index - 1].x)
		marker.position = Vector2(x, (layer_limit.x + layer_limit.y) * 0.5)
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
	if player.has_signal("sprint_changed"):
		player.sprint_changed.connect(_on_sprint_changed)
	var effects := get_node_or_null("/root/ItemEffectDirector")
	if effects != null and effects.has_method("set_player"):
		effects.set_player(player)


func _on_sprint_changed(active: bool, _ratio: float) -> void:
	if active:
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.play_sfx(&"sprint")


func _build_chunk_manager() -> void:
	chunk_manager = CHUNK_MANAGER_SCRIPT.new()
	chunk_manager.name = "WorldChunkManager"
	add_child(chunk_manager)
	chunk_manager.configure(map_plan, player)


func _build_world_collision() -> void:
	# 自底向上地图不再有环墙；只保留四条世界外缘碰撞，防止玩家离开 25600×25600 边界。
	var world_bounds := StaticBody2D.new()
	world_bounds.name = "WorldBounds"
	world_bounds.collision_layer = 1
	world_bounds.collision_mask = 0
	add_child(world_bounds)
	var edge_specs := [
		[Vector2(12800.0, -32.0), Vector2(25600.0, 64.0)],
		[Vector2(12800.0, 25632.0), Vector2(25600.0, 64.0)],
		[Vector2(-32.0, 12800.0), Vector2(64.0, 25600.0)],
		[Vector2(25632.0, 12800.0), Vector2(64.0, 25600.0)],
	]
	for edge in edge_specs:
		var collision := CollisionShape2D.new()
		collision.position = edge[0]
		var rectangle := RectangleShape2D.new()
		rectangle.size = edge[1]
		collision.shape = rectangle
		world_bounds.add_child(collision)
	var bottle := _create_static_rect(get_location(&"titan_bottle"), Vector2(220, 360), Color(0.53, 0.10, 0.09))
	bottle.name = "TitanBottle"
	var cap := _create_static_rect(get_location(&"yellow_cap"), Vector2(150, 100), Color(0.94, 0.75, 0.16))
	cap.name = "YellowBottleCap"


func _build_charge_barriers() -> void:
	_create_barrier("LowerPlasticFilm", map_plan.regions[&"film_field"], Vector2(520, 38), 1.0, false)
	_create_barrier("UpperPlasticFilm", get_location(&"bottle_lever") + Vector2(260, 0), Vector2(420, 38), 1.15, false)
	_create_barrier("OuterPlasticFilm", map_plan.regions[&"film_field_2"], Vector2(560, 38), 1.25, false)
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
	_create_sticky("RottenSlimeA", map_plan.regions[&"rot_slime_1"], Vector2(420, 260), Color(0.18, 0.34, 0.12, 0.72), &"touched_black_water", &"env_rotten_cucumber_intact.png")
	_create_sticky("RottenSlimeB", map_plan.regions[&"rot_slime_2"], Vector2(480, 240), Color(0.21, 0.32, 0.13, 0.66))
	_create_sticky("RottenSlimeC", map_plan.regions[&"rot_slime_3"], Vector2(520, 280), Color(0.25, 0.30, 0.10, 0.68))
	for index in range(1, 5):
		_create_frost("FrostPatch%d" % index, map_plan.regions[StringName("frost_field_%d" % index)], Vector2(430, 300))


func _create_sticky(zone_name: String, at_position: Vector2, size: Vector2, color: Color, flag_id: StringName = &"", object_texture_name: StringName = &"") -> void:
	var sticky := STICKY_AREA_SCENE.instantiate()
	sticky.name = zone_name
	sticky.position = at_position
	sticky.area_size = size
	sticky.area_color = color
	sticky.flag_on_enter = flag_id
	sticky.surface_texture_name = object_texture_name
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
	_spawn_pickup("CorruptEye", &"corrupt_eye", &"corrupt_eye", &"", Color(0.69, 0.12, 0.76), &"", &"corruption", 1)
	_spawn_pickup("ScarletOintment", &"scarlet_ointment", &"scarlet_ointment", &"", Color(0.94, 0.16, 0.10), &"", &"corruption", 1)
	_spawn_pickup("FrozenHeart", &"frozen_heart", &"frozen_heart", &"", Color(0.50, 0.88, 1.0), &"", &"corruption", 1)
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
	_spawn_pickup("HongsanLabel", &"hongsan_label", &"hongsan_label", &"purple_crown_label", Color(0.72, 0.38, 0.86))
	_spawn_pickup("YellowPetals", &"yellow_petals", &"yellow_petals", &"yellow_petals_found", Color(1.0, 0.78, 0.24))
	for index in range(1, 4):
		_spawn_pickup("SproutNodule%d" % index, StringName("sprout_nodule_%d" % index), StringName("sprout_nodule_%d" % index), &"sprout_nodule_found", Color(0.68, 0.42, 0.20))
	_spawn_pickup("CleanNutrient", &"clean_nutrient", &"clean_nutrient", &"clean_nutrient_found", Color(0.52, 0.78, 0.30))
	_spawn_pickup("CompostLabel", &"compost_label", &"compost_label", &"compost_label_found", Color(0.62, 0.72, 0.24))
	_spawn_pickup("BlackWaterCore", &"black_water_core", &"black_water_core", &"black_water_absorbed", Color(0.12, 0.20, 0.06), &"", &"corruption", 3)
	_build_bottle_lever()
	_build_companions()
	_build_phase_32_interactables()


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
	elif item_id == &"black_water_core":
		game_state.set_flag(&"black_water_absorbed")
	elif item_id == &"compost_label":
		game_state.set_flag(&"read_compost_label")


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
		companion.required_counter_action = &"nurture"
		companion.completion_flag = data[2]
		companion.completion_action = &"nurture"
		companion.narrative_text_id = &"companion_watered"
		companion.consumed_after_use = false
		companion.object_color = data[3]
		add_child(companion)


func _build_phase_32_interactables() -> void:
	var hongsan := INTERACTABLE_SCENE.instantiate()
	hongsan.name = "HongsanRoot"
	hongsan.position = get_location(&"hongsan_root")
	hongsan.item_id = &"hongsan_root"
	hongsan.required_counter_id = &"clean_water_count"
	hongsan.required_counter_minimum = 1
	hongsan.required_counter_action = &"nurture"
	hongsan.completion_flag = &"hongsan_root_helped"
	hongsan.completion_action = &"nurture"
	hongsan.narrative_text_id = &"hongsan_helped"
	hongsan.consumed_after_use = false
	hongsan.object_color = Color(0.62, 0.30, 0.78)
	hongsan.prompt_text = "轻按 E 分享净水  /  长按 E 吞噬紫根"
	hongsan.interaction_completed.connect(_on_hongsan_interaction)
	add_child(hongsan)
	for index in range(1, 4):
		var planting := INTERACTABLE_SCENE.instantiate()
		planting.name = "PlantingSite%d" % index
		planting.position = get_location(StringName("planting_site_%d" % index))
		planting.item_id = StringName("planting_site_%d" % index)
		planting.required_item = StringName("sprout_nodule_%d" % index)
		planting.short_action = StringName("plant_site_%d" % index)
		planting.hold_action = StringName("plant_site_%d" % index)
		planting.completion_counter_id = &"planted_site_count"
		planting.completion_counter_amount = 1
		planting.narrative_text_id = &"planting_site_complete"
		planting.object_color = Color(0.56, 0.34, 0.16)
		planting.prompt_text = "按 E 将芽眼结节种入黑土"
		add_child(planting)


func _on_hongsan_interaction(_item_id: StringName, action_id: StringName) -> void:
	if action_id == &"devour":
		get_node("/root/GameState").set_flag(&"hongsan_root_devoured")
	else:
		var knowledge := get_node("/root/MapKnowledgeManager")
		knowledge.clear_marker(&"hongsan_root_hint")
		knowledge.add_or_update_marker(&"bell_direction", {"target_id": &"bell_source", "reveal_mode": "direction", "color": Color(0.84, 0.62, 1.0), "icon_id": &"bell", "priority": 55})


func _build_rituals() -> void:
	_create_ritual("BottleCounterclockwiseRitual", get_location(&"titan_bottle"), &"bottle_counterclockwise", "counterclockwise", 270.0, &"ritual_bottle_complete", Color(0.72, 0.28, 0.88, 0.42))
	_create_ritual("YellowCapRitual", get_location(&"yellow_cap"), &"yellow_cap_loop", "clockwise", 210.0, &"ritual_cap_complete", Color(1.0, 0.75, 0.18, 0.48))
	_create_ritual("RootNetworkRitual", get_location(&"root_network"), &"root_network_loop", "clockwise", 230.0, &"root_network_complete", Color(0.32, 0.84, 0.48, 0.50))
	_create_ritual("SelfSeedRitual", get_location(&"freezer_seed_loop"), &"self_seed_loop", "counterclockwise", 190.0, &"self_seed_loop_complete", Color(0.55, 0.86, 1.0, 0.52))
	_create_ritual("PurpleCrownConnectionRitual", get_location(&"hongsan_link"), &"purple_crown_connection", "clockwise", 220.0, &"purple_link_complete", Color(0.76, 0.42, 0.90, 0.52))


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
	_create_route_flag("TutorialCompleteMarker", get_location(&"narrator_command_1"), &"tutorial_complete")
	_create_route_flag("BellMarker", get_location(&"bell_source"), &"heard_bell", &"hongsan_root_helped", &"", 0, &"bell_heard")
	_create_route_flag("WarmLightMarker", get_location(&"warm_light"), &"faced_warm_light", &"heard_bell")
	_create_route_flag("ReturnToStartMarker", map_plan.spawn, &"returned_to_start", &"", &"narrator_refusal_count", 3, &"self_prune_ready")
	_create_route_flag("ReturnToMotherMarker", get_location(&"mother_soil"), &"returned_to_mother", &"", &"planted_site_count", 3, &"returned_to_mother")
	for index in range(1, 4):
		var command = STILLNESS_COMMAND_SCRIPT.new()
		command.name = "NarratorCommand%d" % index
		command.position = get_location(StringName("narrator_command_%d" % index))
		command.command_index = index
		add_child(command)
	var downward = DIRECTIONAL_TRIAL_SCRIPT.new()
	downward.name = "DownwardTrial"
	downward.position = get_location(&"downward_trial")
	downward.required_seconds = 0.9
	downward.area_size = Vector2(520.0, 340.0)
	add_child(downward)


func _create_route_flag(node_name: String, at_position: Vector2, flag_id: StringName, required_flag: StringName = &"", required_counter_id: StringName = &"", required_counter_minimum: int = 0, narrative_text_id: StringName = &"") -> void:
	var area = ROUTE_FLAG_SCRIPT.new()
	area.name = node_name
	area.position = at_position
	area.flag_id = flag_id
	area.required_flag = required_flag
	area.required_counter_id = required_counter_id
	area.required_counter_minimum = required_counter_minimum
	area.narrative_text_id = narrative_text_id
	add_child(area)


func _build_ending_entrances() -> void:
	_create_entrance("LightSwitchEntrance", &"light_switch", &"light_switch_hold", "hold", 7.0, "长按 E 七秒，让伪太阳失明", Color(0.92, 0.94, 1.0, 0.75))
	_create_entrance("DragonShrineEntrance", &"dragon_shrine", &"dragon_shrine_idle", "idle", 3.0, "旧像凝视着蜷缩不动的根须", Color(1.0, 0.78, 0.25, 0.78))
	_create_entrance("WarmDoorEntrance", &"warm_door_gap", &"warm_door_gap", "hold", 1.5, "暖风从侧面的缝隙吹来", Color(1.0, 0.62, 0.28, 0.82))
	_create_entrance("RootNetworkEntrance", &"root_network_exit", &"root_network_complete", "hold", 1.2, "让养分流过完整根网", Color(0.36, 0.90, 0.50, 0.80))
	_create_entrance("BarcodeTerminalEntrance", &"barcode_terminal", &"barcode_terminal", "hold", 1.2, "芽尖扫描季度增长报表", Color(1.0, 0.30, 0.24, 0.82))
	_create_entrance("FreezerAlcoveEntrance", &"freezer_alcove", &"freezer_alcove", "idle", 1.2, "在凹槽中停止伸长", Color(0.54, 0.86, 1.0, 0.82))
	_create_entrance("TemperatureProbeEntrance", &"temperature_probe", &"temperature_probe", "hold", 2.0, "钻入温控探针，索取 ROOT 权限", Color(0.95, 0.72, 0.18, 0.82))
	_create_entrance("PurpleCrownEntrance", &"hongsan_link", &"hongsan_root_link", "hold", 1.8, "把紫色根须连接到暖光", Color(0.76, 0.42, 0.90, 0.84))
	_create_entrance("MotherSoilEntrance", &"mother_soil", &"mother_soil", "hold", 1.8, "把三扇门带回母薯黑土", Color(0.66, 0.42, 0.18, 0.84))
	_create_entrance("SelfPruneEntrance", &"self_prune", &"self_prune", "hold_down", 0.8, "持续向下，收起今天的芽尖", Color(0.74, 0.78, 0.82, 0.82), Vector2(480.0, 320.0))
	_create_entrance("ForcedCleanupEntrance", &"cleanup_zone", &"forced_cleanup", "hold", 1.5, "让外部世界注意这片垃圾王国", Color(0.62, 0.70, 0.22, 0.84))


func _create_entrance(node_name: String, location_id: StringName, trigger_id: StringName, mode: String, seconds: float, prompt: String, color: Color, custom_area_size: Vector2 = Vector2(220.0, 180.0)) -> void:
	var entrance := ENDING_ENTRANCE_SCENE.instantiate()
	entrance.name = node_name
	entrance.position = get_location(location_id)
	entrance.trigger_id = trigger_id
	entrance.activation_mode = mode
	entrance.required_seconds = seconds
	entrance.area_size = custom_area_size
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
	# Keep the test harness available to Godot debug runs without exposing a
	# developer panel or debug shortcut in the release/player build.
	if OS.is_debug_build():
		var debug_scene := load("res://scenes/ui/debug_panel.tscn") as PackedScene
		if debug_scene != null:
			add_child(debug_scene.instantiate())
	add_child(INVENTORY_SCENE.instantiate())
	add_child(ITEM_DETAIL_POPUP_SCENE.new())
	var map_panel := MAP_PANEL_SCENE.instantiate()
	add_child(map_panel)
	map_panel.configure(map_plan, player)
	add_child(KEY_HINT_SCRIPT.new())
	add_child(SPRINT_METER_SCRIPT.new())
	add_child(GUIDANCE_OVERLAY_SCENE.instantiate())
	_create_narrative_trigger(&"prologue", map_plan.spawn, Vector2(420, 300))
	for index in range(1, 5):
		_create_narrative_trigger([&"stage_rot", &"stage_film", &"stage_frost", &"stage_final"][index - 1], get_stage_marker_position(index), Vector2(420, 300))


func _create_narrative_trigger(text_id: StringName, at_position: Vector2, size: Vector2) -> void:
	var trigger := NARRATIVE_TRIGGER_SCENE.instantiate()
	trigger.position = at_position
	trigger.text_id = text_id
	trigger.trigger_size = size
	add_child(trigger)


func _build_world_labels() -> void:
	_register_world_label("泰坦赤柱 · 逆行者之环", get_location(&"titan_bottle") + Vector2(-250, 230), Color(1.0, 0.52, 0.43))
	_register_world_label("黄金卵壳 · 绕行成形", get_location(&"yellow_cap") + Vector2(-240, 130), Color(1.0, 0.80, 0.28))
	_register_world_label("盒盖出口 · Space 长按蓄力", get_location(&"final_lid") + Vector2(-290, 110), Color(0.76, 0.88, 1.0))
	_register_world_label("向上仍有道路", map_plan.spawn + Vector2(-250, -420), Color(0.76, 0.70, 0.90))
	var landmark_names := ["破裂抽屉", "酱料墓地", "根网温床", "霜柜", "失电控制区", "外壳裂谷"]
	var landmark_index := 0
	for landmark_id in map_plan.get("landmarks", {}):
		_register_world_label(landmark_names[landmark_index], map_plan.landmarks[landmark_id] + Vector2(-150, 90), Color(0.54, 0.68, 0.82))
		landmark_index += 1


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


func _register_world_label(text_value: String, at_position: Vector2, color: Color) -> void:
	var label := Label.new()
	label.position = at_position
	label.size = Vector2(620, 42)
	label.text = text_value
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.z_index = 4
	add_child(label)
	if is_instance_valid(chunk_manager):
		chunk_manager.register_streamable(label, at_position)
