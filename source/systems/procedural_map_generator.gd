class_name ProceduralMapGenerator
extends RefCounted

const WORLD_SIZE := Vector2(8192.0, 8192.0)
const CENTER := Vector2(4096.0, 4096.0)
const OUTER_RADIUS := 3900.0
const MAX_ATTEMPTS := 20
const PLAYER_RADIUS := 18.0
const RING_LIMITS := [
	Vector2(120.0, 700.0),
	Vector2(980.0, 1650.0),
	Vector2(1900.0, 2550.0),
	Vector2(2860.0, 3350.0),
	Vector2(3460.0, 3660.0),
]

const LOCATION_SPECS := [
	[&"mother_potato", 0],
	[&"titan_bottle", 3], [&"yellow_cap", 2],
	[&"date_tablet", 1], [&"corrupt_eye", 1], [&"scarlet_ointment", 3], [&"frozen_heart", 3],
	[&"milk_drop_1", 1], [&"milk_drop_2", 2], [&"milk_drop_3", 3], [&"golden_scale", 2],
	[&"clean_water_1", 1], [&"clean_water_2", 1], [&"clean_water_3", 2],
	[&"door_soil", 2], [&"flowerpot_receipt", 2], [&"bottle_lever", 3],
	[&"companion_onion", 1], [&"companion_garlic", 1], [&"companion_ginger", 2], [&"root_network", 2],
	[&"sale_tag_1", 1], [&"sale_tag_2", 2], [&"sale_tag_3", 3],
	[&"nutrient_1", 1], [&"nutrient_2", 1], [&"nutrient_3", 2], [&"nutrient_4", 2], [&"nutrient_5", 3], [&"nutrient_6", 3],
	[&"frost_crystal_1", 2], [&"frost_crystal_2", 2], [&"frost_crystal_3", 3], [&"frost_crystal_4", 3],
	[&"sleeping_stone", 3], [&"thermostat", 3], [&"freezer_seed_loop", 4],
	[&"aluminum_foil", 1], [&"conductive_water", 2], [&"magnet_core", 3], [&"electric_sequence", 3],
	[&"final_unlock_marker", 4], [&"return_marker", 1],
	[&"final_lid", 4], [&"light_switch", 4], [&"dragon_shrine", 4], [&"warm_door_gap", 4],
	[&"root_network_exit", 3], [&"barcode_terminal", 4], [&"freezer_alcove", 4], [&"temperature_probe", 4],
]

const REGION_SPECS := [
	[&"rot_slime_1", 1], [&"rot_slime_2", 1], [&"film_field", 2],
	[&"frost_field_1", 3], [&"frost_field_2", 3], [&"frost_field_3", 3],
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
	if bounds.size.x < 8192.0 or bounds.size.y < 8192.0:
		errors.append("地图逻辑边界小于 8192×8192")
	var sector_count := int(plan.get("sector_count", 0))
	if sector_count < 8 or sector_count > 12:
		errors.append("扇区数量不在 8–12 范围")
	var gates: Array = plan.get("ring_gates", [])
	if gates.size() != 3:
		errors.append("生态环门数量错误")
	else:
		for ring_gates in gates:
			if ring_gates.size() < 2:
				errors.append("生态环少于两条独立通路")
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
		if int(rings.get(id, -1)) != int(spec[1]):
			errors.append("生态环错误：%s" % id)
	for requirement in [
		[&"clean_water_1", &"warm_door_gap"], [&"door_soil", &"warm_door_gap"],
		[&"companion_onion", &"root_network_exit"], [&"sale_tag_3", &"barcode_terminal"],
		[&"sleeping_stone", &"freezer_alcove"], [&"magnet_core", &"temperature_probe"],
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
			if (locations[a_id] as Vector2).distance_to(locations[b_id]) < 100.0:
				errors.append("位置重叠：%s / %s" % [a_id, b_id])
	var regions: Dictionary = plan.get("regions", {})
	for region_id in regions:
		var region_position: Vector2 = regions[region_id]
		var radial_distance := region_position.distance_to(CENTER)
		for wall_radius in [900.0, 1800.0, 2700.0, OUTER_RADIUS]:
			if absf(radial_distance - wall_radius) < 260.0:
				errors.append("区域与环墙重叠：%s" % region_id)
		for location_id in locations:
			if region_position.distance_to(locations[location_id]) < 500.0:
				errors.append("区域与关键物品/入口重叠：%s / %s" % [region_id, location_id])
	return errors


static func _build_plan(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sector_count := rng.randi_range(8, 12)
	var rotation := rng.randf_range(0.0, TAU)
	var locations: Dictionary = {}
	var location_rings: Dictionary = {}
	for spec in LOCATION_SPECS:
		var id: StringName = spec[0]
		var ring_index: int = spec[1]
		locations[id] = _find_location(rng, ring_index, locations, id)
		location_rings[id] = ring_index
	var regions: Dictionary = {}
	for spec in REGION_SPECS:
		regions[spec[0]] = _find_location(rng, int(spec[1]), locations.merged(regions), spec[0], 520.0)
	var ring_gates: Array = []
	for ring_index in range(3):
		var first := wrapf(rotation + rng.randf_range(-0.45, 0.45) + ring_index * 1.7, 0.0, TAU)
		var second := wrapf(first + PI + rng.randf_range(-0.35, 0.35), 0.0, TAU)
		ring_gates.append([first, second])
	var wall_rects := _make_ring_walls(ring_gates)
	return {
		"seed": seed_value,
		"bounds": Rect2(Vector2.ZERO, WORLD_SIZE),
		"center": CENTER,
		"spawn": CENTER,
		"outer_radius": OUTER_RADIUS,
		"sector_count": sector_count,
		"rotation": rotation,
		"ring_gates": ring_gates,
		"wall_rects": wall_rects,
		"locations": locations,
		"location_rings": location_rings,
		"regions": regions,
		"ritual_clearance": {
			&"bottle_counterclockwise": {"entity_half_extent": 180.0, "checkpoint_radius": 270.0},
			&"yellow_cap_loop": {"entity_half_extent": 75.0, "checkpoint_radius": 210.0},
		},
	}


static func _find_location(rng: RandomNumberGenerator, ring_index: int, occupied: Dictionary, id: StringName, minimum_distance: float = 190.0) -> Vector2:
	var limits: Vector2 = RING_LIMITS[ring_index]
	if id == &"titan_bottle":
		limits = Vector2(3020.0, 3260.0)
	elif id == &"yellow_cap":
		limits = Vector2(2050.0, 2450.0)
	for _attempt in range(120):
		var radius := rng.randf_range(limits.x, limits.y)
		var wall_clearance := 270.0 if minimum_distance >= 500.0 else 82.0
		var too_close_to_wall := false
		for wall_radius in [900.0, 1800.0, 2700.0, OUTER_RADIUS]:
			if absf(radius - wall_radius) < wall_clearance:
				too_close_to_wall = true
				break
		if too_close_to_wall:
			continue
		var angle := rng.randf_range(0.0, TAU)
		var candidate := CENTER + Vector2.RIGHT.rotated(angle) * radius
		var valid := true
		for other_id in occupied:
			var required_distance := minimum_distance
			if other_id in [&"titan_bottle", &"yellow_cap"] or id in [&"titan_bottle", &"yellow_cap"]:
				required_distance = 470.0
			if candidate.distance_to(occupied[other_id]) < required_distance:
				valid = false
				break
		if valid:
			return candidate
	# Deterministic emergency slot; normal generation should never reach this branch.
	var fallback_angle := float(abs(hash(str(id))) % 6283) / 1000.0
	return CENTER + Vector2.RIGHT.rotated(fallback_angle) * lerpf(limits.x, limits.y, 0.5)


static func _make_ring_walls(ring_gates: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var radii := [900.0, 1800.0, 2700.0, OUTER_RADIUS]
	var segment_count := 64
	for ring_index in range(radii.size()):
		var radius: float = radii[ring_index]
		var segment_length := TAU * radius / float(segment_count) * 1.02
		for segment_index in range(segment_count):
			var angle := TAU * float(segment_index) / float(segment_count)
			if ring_index < 3 and _is_gate_angle(angle, ring_gates[ring_index]):
				continue
			result.append({
				"center": CENTER + Vector2.RIGHT.rotated(angle) * radius,
				"size": Vector2(segment_length, 46.0 if ring_index < 3 else 76.0),
				"rotation": angle + PI * 0.5,
				"ring": ring_index,
			})
	return result


static func _is_gate_angle(angle: float, gates: Array) -> bool:
	for gate_angle in gates:
		if absf(wrapf(angle - float(gate_angle) + PI, 0.0, TAU) - PI) < 0.16:
			return true
	return false
