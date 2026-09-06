class_name AssetPointTeleporter
extends Control

signal closed
signal teleport_requested(world_position: Vector2, point_id: StringName)

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")
const LAYER_NAMES := ["01 出生与母薯", "02 腐败抽屉", "03 薄膜与冷凝", "04 根网温床", "05 泰坦与污染", "06 霜柜控制", "07 外壳与结局"]

var _level: Node
var _grid: GridContainer
var _summary: Label
var _point_count := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 21
	_build_ui()
	visible = false


func configure(level: Node) -> void:
	_level = level
	_refresh()


func set_open(opened: bool) -> void:
	visible = opened
	if opened:
		_refresh()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.004, 0.008, 0.020, 0.97)
	add_child(shade)
	var outer := Panel.new()
	outer.position = Vector2(18, 16)
	outer.size = Vector2(1244, 688)
	PIXEL_UI.apply_panel(outer, Color(0.015, 0.024, 0.047, 0.99), Color(0.34, 0.52, 0.62), 5)
	add_child(outer)
	var title := Label.new()
	title.position = Vector2(38, 28)
	title.size = Vector2(570, 38)
	title.text = "测试素材点传送 · 全部生成位置与区域"
	title.add_theme_font_size_override("font_size", 24)
	PIXEL_UI.apply_title(title, Color(0.64, 0.88, 0.94))
	add_child(title)
	_summary = Label.new()
	_summary.position = Vector2(610, 32)
	_summary.size = Vector2(460, 28)
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_summary.add_theme_font_size_override("font_size", 15)
	add_child(_summary)
	var close_button := Button.new()
	close_button.position = Vector2(1090, 26)
	close_button.size = Vector2(140, 38)
	close_button.text = "返回调试"
	PIXEL_UI.apply_button(close_button, Color(0.38, 0.72, 0.78))
	close_button.pressed.connect(func() -> void: closed.emit())
	add_child(close_button)
	var help := Label.new()
	help.position = Vector2(40, 72)
	help.size = Vector2(1160, 30)
	help.text = "点击后传送到目标旁的安全观察位，不会立刻吃掉道具；拾取物、交互物、仪式、结局入口和危险区域均使用当前 Seed 的实际坐标。"
	help.add_theme_color_override("font_color", Color(0.66, 0.76, 0.86))
	help.add_theme_font_size_override("font_size", 15)
	add_child(help)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(34, 108)
	scroll.size = Vector2(1212, 576)
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.custom_minimum_size = Vector2(1170, 0)
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 7)
	scroll.add_child(_grid)


func _refresh() -> void:
	if not is_instance_valid(_grid):
		return
	for child in _grid.get_children():
		child.queue_free()
	if not is_instance_valid(_level):
		_summary.text = "关卡不可用"
		return
	var plan_value = _level.get("map_plan")
	var plan: Dictionary = plan_value if plan_value is Dictionary else {}
	var locations: Dictionary = plan.get("locations", {})
	var location_layers: Dictionary = plan.get("location_rings", {})
	var regions: Dictionary = plan.get("regions", {})
	var entries_by_layer: Array[Array] = [[], [], [], [], [], [], []]
	for point_id in locations:
		var layer := clampi(int(location_layers.get(point_id, 0)), 0, 6)
		entries_by_layer[layer].append({"id": point_id, "position": locations[point_id], "kind": "地点"})
	for region_id in regions:
		var position: Vector2 = regions[region_id]
		var layer := clampi(int(_level.call("get_layer_index_for_position", position)), 0, 6)
		entries_by_layer[layer].append({"id": region_id, "position": position, "kind": "区域"})
	var total := 0
	for layer in range(entries_by_layer.size()):
		entries_by_layer[layer].sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.id) < str(b.id))
		_add_heading("L%s · %s · %d 点" % [layer + 1, LAYER_NAMES[layer], entries_by_layer[layer].size()])
		for entry in entries_by_layer[layer]:
			total += 1
			_add_point_button(entry)
		_fill_row(entries_by_layer[layer].size())
	_summary.text = "%d 个可传送素材/玩法点 · Seed %d" % [total, int(plan.get("requested_seed", 0))]
	_point_count = total


func get_point_count() -> int:
	return _point_count


func _add_heading(text_value: String) -> void:
	var heading := Label.new()
	heading.text = text_value
	heading.custom_minimum_size = Vector2(1170, 30)
	heading.add_theme_font_size_override("font_size", 18)
	PIXEL_UI.apply_title(heading, Color(0.66, 0.84, 0.96))
	_grid.add_child(heading)
	for _index in range(3):
		_grid.add_child(Control.new())


func _add_point_button(entry: Dictionary) -> void:
	var point_id := StringName(entry.id)
	var point_position := Vector2(entry.position)
	var inspect_offset := Vector2(310.0, 0.0) if entry.kind == "区域" else Vector2(130.0, 0.0)
	var inspect_position := point_position + inspect_offset
	if inspect_position.x > 25380.0:
		inspect_position = point_position - inspect_offset
	inspect_position.x = clampf(inspect_position.x, 120.0, 25480.0)
	inspect_position.y = clampf(inspect_position.y, 120.0, 25480.0)
	var button := Button.new()
	button.text = "%s · %s" % [str(entry.kind), str(point_id)]
	button.tooltip_text = "%s\n素材坐标 %s\n观察位 %s" % [point_id, point_position, inspect_position]
	button.custom_minimum_size = Vector2(284, 34)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	PIXEL_UI.apply_button(button, Color(0.40, 0.68, 0.76) if entry.kind == "区域" else Color(0.58, 0.36, 0.78))
	button.pressed.connect(func() -> void: teleport_requested.emit(inspect_position, point_id))
	_grid.add_child(button)


func _fill_row(item_count: int) -> void:
	var remainder := item_count % 4
	if remainder == 0:
		return
	for _index in range(4 - remainder):
		_grid.add_child(Control.new())
