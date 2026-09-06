extends Node

signal knowledge_reset
signal cell_discovered(ring_index: int, sector_index: int)
signal landmark_discovered(landmark_id: StringName)
signal marker_changed(marker_id: StringName, visible: bool)

var discovered_cells: Dictionary = {}
var discovered_landmarks: Dictionary = {}
var markers: Dictionary = {}
var _center := Vector2.ZERO
var _spawn := Vector2.ZERO
var _outer_radius := 1.0
var _ring_radii: Array = []
var _layer_bounds: Array = []
var _sector_count := 1
var _rotation := 0.0
var _target_positions: Dictionary = {}
var _landmark_positions: Dictionary = {}


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.run_reset.connect(_on_run_reset)


func configure(plan: Dictionary) -> void:
	_center = plan.get("map_center", plan.get("center", Vector2.ZERO))
	_spawn = plan.get("spawn", _center)
	_outer_radius = maxf(float(plan.get("outer_radius", 1.0)), 1.0)
	_ring_radii = plan.get("ring_radii", []).duplicate()
	_layer_bounds = plan.get("layer_bounds", []).duplicate()
	_sector_count = maxi(int(plan.get("sector_count", 1)), 1)
	_rotation = float(plan.get("rotation", 0.0))
	_target_positions = plan.get("locations", {}).duplicate(true)
	_landmark_positions = plan.get("landmarks", {}).duplicate(true)
	discover_position(_spawn)
	discover_landmark(&"mother_potato", _spawn)


func discover_position(world_position: Vector2) -> bool:
	var ring := get_ring_index(world_position)
	var sector := get_sector_index(world_position)
	var key := StringName("%d:%d" % [ring, sector])
	if discovered_cells.has(key):
		return false
	discovered_cells[key] = true
	cell_discovered.emit(ring, sector)
	return true


func update_player_position(world_position: Vector2) -> void:
	discover_position(world_position)
	for landmark_id in _landmark_positions:
		if not discovered_landmarks.has(landmark_id) and world_position.distance_to(_landmark_positions[landmark_id]) <= 720.0:
			discover_landmark(landmark_id, _landmark_positions[landmark_id])


func discover_landmark(landmark_id: StringName, world_position: Vector2 = Vector2.INF) -> bool:
	if landmark_id.is_empty() or discovered_landmarks.has(landmark_id):
		return false
	if world_position != Vector2.INF:
		_landmark_positions[landmark_id] = world_position
	discovered_landmarks[landmark_id] = true
	landmark_discovered.emit(landmark_id)
	return true


func add_or_update_marker(marker_id: StringName, data: Dictionary) -> bool:
	if marker_id.is_empty():
		return false
	var target_id := StringName(data.get("target_id", &""))
	if not data.has("world_position") and not _target_positions.has(target_id):
		return false
	var marker := data.duplicate(true)
	marker["id"] = marker_id
	marker["target_id"] = target_id
	if not marker.has("world_position"):
		marker["world_position"] = _target_positions[target_id]
	marker["reveal_mode"] = str(marker.get("reveal_mode", "direction"))
	marker["color"] = marker.get("color", Color(0.82, 0.46, 1.0))
	markers[marker_id] = marker
	marker_changed.emit(marker_id, true)
	return true


func clear_marker(marker_id: StringName) -> bool:
	if not markers.erase(marker_id):
		return false
	marker_changed.emit(marker_id, false)
	return true


func clear_markers_for_target(target_id: StringName) -> void:
	for marker_id in markers.keys():
		if StringName(markers[marker_id].get("target_id", &"")) == target_id:
			clear_marker(marker_id)


func has_marker(marker_id: StringName) -> bool:
	return markers.has(marker_id)


func get_visible_markers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for marker in markers.values():
		result.append((marker as Dictionary).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 0)) < int(b.get("priority", 0)))
	return result


func get_marker_display_position(marker: Dictionary) -> Vector2:
	var target: Vector2 = marker.get("world_position", _center)
	var mode := str(marker.get("reveal_mode", "direction"))
	var direction := (target - _spawn).normalized()
	if mode == "direction":
		return _spawn + direction * _outer_radius
	if mode == "sector":
		var ring := get_ring_index(target)
		var sector := get_sector_index(target)
		var x := (float(sector) + 0.5) / float(_sector_count) * 25600.0
		var y := _spawn.y
		if _layer_bounds.size() == 7:
			var layer_limit: Vector2 = _layer_bounds[ring]
			y = (layer_limit.x + layer_limit.y) * 0.5
		return Vector2(x, y)
	if mode == "approximate":
		var offset_angle := float(abs(hash(str(marker.get("id", "marker")))) % 6283) / 1000.0
		return target + Vector2.RIGHT.rotated(offset_angle) * 480.0
	return target


func get_ring_index(world_position: Vector2) -> int:
	var nearest_index := 0
	var nearest_distance := INF
	for index in range(_layer_bounds.size()):
		var layer_limit: Vector2 = _layer_bounds[index]
		if world_position.y >= layer_limit.x and world_position.y <= layer_limit.y:
			return index
		var layer_center := (layer_limit.x + layer_limit.y) * 0.5
		var distance := absf(world_position.y - layer_center)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index
	return nearest_index


func get_sector_index(world_position: Vector2) -> int:
	var normalized_x := clampf(world_position.x / 25600.0, 0.0, 0.999999)
	return clampi(floori(normalized_x * float(_sector_count)), 0, _sector_count - 1)


func world_to_map(world_position: Vector2, map_rect: Rect2) -> Vector2:
	var normalized := Vector2(world_position.x / 25600.0, world_position.y / 25600.0)
	return map_rect.position + normalized * map_rect.size


func get_config() -> Dictionary:
	return {"center": _center, "spawn": _spawn, "outer_radius": _outer_radius, "ring_radii": _ring_radii.duplicate(), "layer_bounds": _layer_bounds.duplicate(), "sector_count": _sector_count, "rotation": _rotation}


func _on_run_reset(_run_number: int) -> void:
	discovered_cells.clear()
	discovered_landmarks.clear()
	markers.clear()
	_target_positions.clear()
	_landmark_positions.clear()
	knowledge_reset.emit()
