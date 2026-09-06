class_name ProceduralMapGenerator
extends RefCounted

const WORLD_SIZE := Vector2(25600.0, 25600.0)
const CENTER := Vector2(12800.0, 12800.0)
const SPAWN := Vector2(12800.0, 23600.0)
const MAP_TOP := 1200.0
const MAP_BOTTOM := 24400.0
const OUTER_RADIUS := MAP_BOTTOM - MAP_TOP
const CHUNK_SIZE := 1280.0
const MAX_ATTEMPTS := 20
const PLAYER_RADIUS := 18.0
const PLAYABLE_X := Vector2(900.0, 24700.0)
# 七个自底向上的生态层：索引 0 在地图底部，索引 6 在顶部。
const LAYER_BOUNDS := [
	Vector2(22600.0, 24400.0), Vector2(19300.0, 22200.0), Vector2(15700.0, 18900.0),
	Vector2(12100.0, 15300.0), Vector2(8500.0, 11700.0), Vector2(4800.0, 8100.0),
	Vector2(1200.0, 4400.0),
]
const LAYER_DEPTHS := [1800.0, 4700.0, 8300.0, 11900.0, 15500.0, 19100.0, 24400.0]
const SECTOR_THEMES := [
	&"cracked_drawer", &"frost_vault", &"sauce_graveyard", &"root_nursery",
	&"barcode_warehouse", &"blackout_controls", &"landfill", &"condensation_garden",
	&"film_catacomb", &"quiet_compartment", &"forgotten_leftovers", &"warm_vent",
	&"compressor_shrine", &"sprout_colony", &"magnet_coil", &"outer_shell",
]

const LOCATION_SPECS := [
	[&"mother_potato", 0],
	[&"titan_bottle", 4], [&"yellow_cap", 2],
	[&"date_tablet", 1], [&"corrupt_eye", 1], [&"scarlet_ointment", 4], [&"frozen_heart", 5],
	[&"milk_drop_1", 1], [&"milk_drop_2", 3], [&"milk_drop_3", 5], [&"golden_scale", 4],
	[&"clean_water_1", 1], [&"clean_water_2", 2], [&"clean_water_3", 3],
	[&"door_soil", 3], [&"flowerpot_receipt", 4], [&"bottle_lever", 5],
	[&"companion_onion", 2], [&"companion_garlic", 3], [&"companion_ginger", 4], [&"root_network", 4],
	[&"sale_tag_1", 1], [&"sale_tag_2", 3], [&"sale_tag_3", 5],
	[&"nutrient_1", 1], [&"nutrient_2", 2], [&"nutrient_3", 3], [&"nutrient_4", 4], [&"nutrient_5", 5], [&"nutrient_6", 5],
	[&"frost_crystal_1", 3], [&"frost_crystal_2", 4], [&"frost_crystal_3", 5], [&"frost_crystal_4", 5],
	[&"sleeping_stone", 5], [&"thermostat", 5], [&"freezer_seed_loop", 6],
	[&"aluminum_foil", 2], [&"conductive_water", 3], [&"magnet_core", 5], [&"electric_sequence", 5],
	[&"final_unlock_marker", 6], [&"return_marker", 2],
	[&"final_lid", 6], [&"light_switch", 6], [&"dragon_shrine", 6], [&"warm_door_gap", 6],
	[&"root_network_exit", 5], [&"barcode_terminal", 6], [&"freezer_alcove", 6], [&"temperature_probe", 6],
	[&"hongsan_label", 2], [&"yellow_petals", 3], [&"hongsan_root", 4],
	[&"bell_source", 5], [&"warm_light", 6], [&"hongsan_link", 6],
	[&"sprout_nodule_1", 1], [&"sprout_nodule_2", 3], [&"sprout_nodule_3", 5],
	[&"clean_nutrient", 4], [&"planting_site_1", 2], [&"planting_site_2", 4], [&"planting_site_3", 6],
	[&"downward_trial", 2], [&"mother_soil", 0],
	[&"narrator_command_1", 1], [&"narrator_command_2", 2], [&"narrator_command_3", 3], [&"self_prune", 0],
	[&"compost_label", 2], [&"black_water_core", 4], [&"cleanup_zone", 6],
]

const REGION_SPECS := [
	[&"rot_slime_1", 1], [&"rot_slime_2", 2], [&"rot_slime_3", 4],
	[&"film_field", 3], [&"film_field_2", 5],
	[&"frost_field_1", 4], [&"frost_field_2", 5], [&"frost_field_3", 5], [&"frost_field_4", 6],
	[&"warm_draft", 6], [&"root_bed", 4], [&"landfill_field", 5],
]


static func generate(seed_value: int) -> Dictionary:
	var normalized_seed := seed_value if seed_value > 0 else 1
	for attempt in range(MAX_ATTEMPTS):
		var attempt_seed := normalized_seed + attempt * 104729
		var plan := _build_plan(attempt_seed)
		var errors := validate_plan(plan)
		if errors.is_empty():
			plan["requested_seed"] = normalized_seed
			plan["attempt"] = attempt + 1
			plan["used_fallback"] = false
			plan["validation_errors"] = []
			return plan
	var fallback := _build_plan(20260117)
	fallback["requested_seed"] = normalized_seed
	fallback["attempt"] = MAX_ATTEMPTS
	fallback["used_fallback"] = true
	fallback["validation_errors"] = validate_plan(fallback)
	return fallback


static func validate_plan(plan: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var bounds: Rect2 = plan.get("bounds", Rect2())
	if bounds.size.x < 25000.0 or bounds.size.y < 25000.0:
		errors.append("最终地图逻辑边界小于 25000×25000")
	if int(plan.get("ring_count", 0)) != 7:
		errors.append("生态层数量不是七层")
	var sector_count := int(plan.get("sector_count", 0))
	if sector_count < 12 or sector_count > 16:
		errors.append("扇区数量不在 12–16 范围")
	var layer_bounds: Array = plan.get("layer_bounds", [])
	if layer_bounds.size() != 7:
		errors.append("自底向上的七个生态层数据错误")
	else:
		for layer_index in range(layer_bounds.size()):
			var bounds_for_layer: Vector2 = layer_bounds[layer_index]
			if bounds_for_layer.x >= bounds_for_layer.y:
				errors.append("生态层 %d 的上下边界错误" % layer_index)
	var gates: Array = plan.get("ring_gates", [])
	if gates.size() != 6:
		errors.append("六个层间过渡数据错误")
	else:
		for transition in gates:
			if transition.size() < 3:
				errors.append("层间开放通行带少于三条")
	var route_lanes: Array = plan.get("route_lanes", [])
	if route_lanes.size() != 3:
		errors.append("中心到外缘的独立路线不足三条")
	else:
		for lane in route_lanes:
			if lane.size() != 6:
				errors.append("垂直路线没有穿过全部六个层间过渡")
	var themes: Array = plan.get("sector_themes", [])
	if themes.size() != sector_count:
		errors.append("主题扇区数量与扇区数不一致")
	var locations: Dictionary = plan.get("locations", {})
	var rings: Dictionary = plan.get("location_rings", {})
	for spec in LOCATION_SPECS:
		var id: StringName = spec[0]
		if not locations.has(id):
			errors.append("缺少位置：%s" % id)
			continue
		var position: Vector2 = locations[id]
		if not bounds.has_point(position):
			errors.append("位置越界：%s" % id)
		var expected_layer := int(spec[1])
		if int(rings.get(id, -1)) != expected_layer:
			errors.append("生态层错误：%s" % id)
		elif layer_bounds.size() == 7:
			var layer_limit: Vector2 = layer_bounds[expected_layer]
			if position.y < layer_limit.x or position.y > layer_limit.y:
				errors.append("位置没有生成在自底向上生态层：%s" % id)
	for requirement in [
		[&"clean_water_1", &"warm_door_gap"], [&"door_soil", &"warm_door_gap"],
		[&"companion_onion", &"root_network_exit"], [&"sale_tag_3", &"barcode_terminal"],
		[&"sleeping_stone", &"freezer_alcove"], [&"magnet_core", &"temperature_probe"],
		[&"hongsan_label", &"hongsan_link"], [&"yellow_petals", &"hongsan_link"],
		[&"sprout_nodule_1", &"planting_site_3"],
	]:
		if int(rings.get(requirement[0], 99)) >= int(rings.get(requirement[1], -1)):
			errors.append("关键物品没有生成在入口之前：%s" % requirement[0])
	var clearance: Dictionary = plan.get("ritual_clearance", {})
	for ritual_id in clearance:
		var entry: Dictionary = clearance[ritual_id]
		var free_space := float(entry.get("checkpoint_radius", 0.0)) - float(entry.get("entity_half_extent", 0.0))
		if free_space < PLAYER_RADIUS + 32.0:
			errors.append("仪式净空不足：%s" % ritual_id)
	var ids := locations.keys()
	for a_index in range(ids.size()):
		for b_index in range(a_index + 1, ids.size()):
			var a_id: StringName = ids[a_index]
			var b_id: StringName = ids[b_index]
			if (locations[a_id] as Vector2).distance_to(locations[b_id]) < 150.0:
				errors.append("位置重叠：%s / %s" % [a_id, b_id])
	var regions: Dictionary = plan.get("regions", {})
	for region_id in regions:
		var region_position: Vector2 = regions[region_id]
		for location_id in locations:
			if region_position.distance_to(locations[location_id]) < 580.0:
				errors.append("区域与关键物品/入口重叠：%s / %s" % [region_id, location_id])
	var chunk_index: Dictionary = plan.get("chunk_index", {})
	if chunk_index.size() != locations.size() + regions.size():
		errors.append("逻辑分块索引没有覆盖全部位置与区域")
	return errors


static func ring_index_for_position(position: Vector2) -> int:
	var nearest_index := 0
	var nearest_distance := INF
	for index in range(LAYER_BOUNDS.size()):
		var layer_limit: Vector2 = LAYER_BOUNDS[index]
		if position.y >= layer_limit.x and position.y <= layer_limit.y:
			return index
		var layer_center := (layer_limit.x + layer_limit.y) * 0.5
		var distance := absf(position.y - layer_center)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index
	return nearest_index


static func sector_index_for_position(position: Vector2, sector_count: int, rotation: float) -> int:
	var normalized_x := clampf(position.x / WORLD_SIZE.x, 0.0, 0.999999)
	return clampi(floori(normalized_x * float(sector_count)), 0, sector_count - 1)


static func chunk_key_for_position(position: Vector2) -> StringName:
	return StringName("%d:%d" % [floori(position.x / CHUNK_SIZE), floori(position.y / CHUNK_SIZE)])


static func _build_plan(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sector_count := rng.randi_range(12, 16)
	var rotation := 0.0
	var locations: Dictionary = {}
	var location_rings: Dictionary = {}
	for spec in LOCATION_SPECS:
		var id: StringName = spec[0]
		var ring_index: int = spec[1]
		locations[id] = _find_location(rng, ring_index, locations, id)
		location_rings[id] = ring_index
	var regions: Dictionary = {}
	for spec in REGION_SPECS:
		regions[spec[0]] = _find_location(rng, int(spec[1]), locations.merged(regions), spec[0], 640.0)
	var route_lanes := _make_route_lanes(rng, sector_count, rotation)
	var ring_gates: Array = []
	for ring_index in range(6):
		var gates_for_ring: Array[float] = []
		for lane in route_lanes:
			gates_for_ring.append(float(lane[ring_index].x))
		ring_gates.append(gates_for_ring)
	var landmarks := _make_landmarks(rng, locations)
	var sector_themes := _make_sector_themes(rng, sector_count)
	var chunk_index: Dictionary = {}
	for id in locations:
		chunk_index[id] = chunk_key_for_position(locations[id])
	for id in regions:
		chunk_index[id] = chunk_key_for_position(regions[id])
	return {
		"seed": seed_value, "bounds": Rect2(Vector2.ZERO, WORLD_SIZE), "center": CENTER,
		"map_center": CENTER, "spawn": SPAWN, "outer_radius": OUTER_RADIUS, "ring_count": 7,
		"layer_bounds": LAYER_BOUNDS.duplicate(), "ring_radii": LAYER_DEPTHS.duplicate(), "sector_count": sector_count, "rotation": rotation,
		"sector_themes": sector_themes, "ring_gates": ring_gates, "route_lanes": route_lanes,
		"wall_rects": [], "locations": locations, "location_rings": location_rings,
		"regions": regions, "landmarks": landmarks, "chunk_size": CHUNK_SIZE, "chunk_index": chunk_index,
		"ritual_clearance": {
			&"bottle_counterclockwise": {"entity_half_extent": 180.0, "checkpoint_radius": 270.0},
			&"yellow_cap_loop": {"entity_half_extent": 75.0, "checkpoint_radius": 210.0},
			&"root_network_loop": {"entity_half_extent": 80.0, "checkpoint_radius": 230.0},
			&"self_seed_loop": {"entity_half_extent": 60.0, "checkpoint_radius": 190.0},
		},
	}


static func _make_route_lanes(rng: RandomNumberGenerator, sector_count: int, rotation: float) -> Array:
	var lanes: Array = []
	var base_x := rng.randf_range(5200.0, 7200.0)
	for lane_index in range(3):
		var lane: Array = []
		var lane_x := base_x + float(lane_index) * 6400.0
		for ring_index in range(6):
			var next_layer := ring_index + 1
			var layer_center_y: float = (LAYER_BOUNDS[ring_index].x + LAYER_BOUNDS[ring_index].y) * 0.5
			var next_center_y: float = (LAYER_BOUNDS[next_layer].x + LAYER_BOUNDS[next_layer].y) * 0.5
			var transition_y: float = (layer_center_y + next_center_y) * 0.5
			lane.append({"ring": ring_index, "x": lane_x, "y": transition_y, "sector": clampi(floori(lane_x / WORLD_SIZE.x * float(sector_count)), 0, sector_count - 1)})
		lanes.append(lane)
	return lanes


static func _make_sector_themes(rng: RandomNumberGenerator, sector_count: int) -> Array[StringName]:
	var pool := SECTOR_THEMES.duplicate()
	for index in range(pool.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = pool[index]
		pool[index] = pool[swap_index]
		pool[swap_index] = value
	var result: Array[StringName] = []
	for index in range(sector_count):
		result.append(pool[index])
	return result


static func _make_landmarks(rng: RandomNumberGenerator, occupied: Dictionary) -> Dictionary:
	var landmarks: Dictionary = {}
	var merged := occupied.duplicate()
	for ring_index in range(1, 7):
		var id := StringName("landmark_ring_%d" % ring_index)
		var position := _find_location(rng, ring_index, merged, id, 720.0)
		landmarks[id] = position
		merged[id] = position
	return landmarks


static func _find_location(rng: RandomNumberGenerator, ring_index: int, occupied: Dictionary, id: StringName, minimum_distance: float = 260.0) -> Vector2:
	if id == &"mother_potato": return SPAWN
	var limits: Vector2 = LAYER_BOUNDS[ring_index]
	for _attempt in range(220):
		var candidate := Vector2(rng.randf_range(PLAYABLE_X.x, PLAYABLE_X.y), rng.randf_range(limits.x, limits.y))
		var valid := true
		for other_id in occupied:
			var required_distance := minimum_distance
			if other_id in [&"titan_bottle", &"yellow_cap"] or id in [&"titan_bottle", &"yellow_cap"]:
				required_distance = maxf(required_distance, 560.0)
			if candidate.distance_to(occupied[other_id]) < required_distance:
				valid = false
				break
		if valid: return candidate
	var fallback_x := lerpf(PLAYABLE_X.x, PLAYABLE_X.y, float(abs(hash("%s:%d" % [id, rng.seed])) % 1000) / 1000.0)
	return Vector2(fallback_x, (limits.x + limits.y) * 0.5)
