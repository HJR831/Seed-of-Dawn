class_name SproutMapCanvas
extends Control

var plan: Dictionary = {}
var player: Node2D
var full_mode := false


func configure(plan_value: Dictionary, player_value: Node2D, is_full: bool) -> void:
	plan = plan_value
	player = player_value
	full_mode = is_full
	queue_redraw()


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	if plan.is_empty():
		return
	var rect := Rect2(Vector2(8, 8), size - Vector2(16, 16))
	draw_rect(rect.grow(8.0), Color(0.015, 0.022, 0.052, 0.96), true)
	draw_rect(rect, Color(0.045, 0.060, 0.092, 0.96), true)
	var knowledge := get_node_or_null("/root/MapKnowledgeManager")
	if knowledge == null:
		return
	var config: Dictionary = knowledge.get_config()
	var layer_bounds: Array = config.get("layer_bounds", [])
	var sector_count := maxi(int(config.get("sector_count", 1)), 1)
	for key in knowledge.discovered_cells:
		var parts := str(key).split(":")
		if parts.size() != 2:
			continue
		var ring := int(parts[0])
		var sector := int(parts[1])
		_draw_discovered_cell(rect, layer_bounds, ring, sector, sector_count)
	for layer_limit in layer_bounds:
		var y := rect.position.y + float(layer_limit.y) / 25600.0 * rect.size.y
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.42, 0.50, 0.66, 0.30), 1.2 if not full_mode else 2.0)
	for sector in range(1, sector_count):
		var x := rect.position.x + float(sector) / float(sector_count) * rect.size.x
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.30, 0.38, 0.52, 0.16), 1.0)
	for landmark_id in knowledge.discovered_landmarks:
		var world_position: Vector2 = plan.get("landmarks", {}).get(landmark_id, plan.get("spawn", Vector2.ZERO))
		if landmark_id == &"mother_potato":
			world_position = plan.get("spawn", Vector2.ZERO)
		var point := _to_local_map(world_position, rect)
		draw_circle(point, 4.0 if not full_mode else 7.0, Color(0.42, 0.92, 0.55))
	for marker in knowledge.get_visible_markers():
		var marker_position: Vector2 = knowledge.get_marker_display_position(marker)
		var point := _to_local_map(marker_position, rect)
		var color: Color = marker.get("color", Color(0.82, 0.46, 1.0))
		var mode := str(marker.get("reveal_mode", "direction"))
		if mode == "direction":
			point.x = clampf(point.x, rect.position.x + 8.0, rect.end.x - 8.0)
			point.y = clampf(point.y, rect.position.y + 8.0, rect.end.y - 8.0)
			draw_colored_polygon(PackedVector2Array([point + Vector2(0, -7), point + Vector2(7, 7), point + Vector2(-7, 7)]), color)
		elif mode == "sector":
			draw_circle(point, 10.0 if full_mode else 7.0, Color(color, 0.30))
			draw_circle(point, 5.0, color, false, 2.0)
		elif mode == "approximate":
			draw_circle(point, 16.0 if full_mode else 10.0, Color(color, 0.22))
			draw_arc(point, 16.0 if full_mode else 10.0, 0.0, TAU, 24, color, 2.0)
		else:
			draw_colored_polygon(PackedVector2Array([point + Vector2(0, -8), point + Vector2(7, 0), point + Vector2(0, 8), point + Vector2(-7, 0)]), color)
	if is_instance_valid(player):
		var player_point := _to_local_map(player.global_position, rect)
		draw_circle(player_point, 6.0 if not full_mode else 9.0, Color(1.0, 0.90, 0.38))
		draw_line(player_point, player_point + player.velocity.normalized() * (13.0 if not full_mode else 20.0), Color.WHITE, 2.0)
	draw_rect(rect, Color(0.72, 0.78, 0.94, 0.75), false, 2.0)


func _draw_discovered_cell(rect: Rect2, layer_bounds: Array, ring: int, sector: int, sector_count: int) -> void:
	if layer_bounds.is_empty():
		return
	var layer_limit: Vector2 = layer_bounds[clampi(ring, 0, layer_bounds.size() - 1)]
	var left := rect.position.x + float(sector) / float(sector_count) * rect.size.x
	var right := rect.position.x + float(sector + 1) / float(sector_count) * rect.size.x
	var top := rect.position.y + layer_limit.x / 25600.0 * rect.size.y
	var bottom := rect.position.y + layer_limit.y / 25600.0 * rect.size.y
	draw_rect(Rect2(left, top, right - left, bottom - top), Color(0.16, 0.23, 0.32, 0.80), true)


func _to_local_map(world_position: Vector2, rect: Rect2) -> Vector2:
	return rect.position + Vector2(clampf(world_position.x / 25600.0, 0.0, 1.0), clampf(world_position.y / 25600.0, 0.0, 1.0)) * rect.size
