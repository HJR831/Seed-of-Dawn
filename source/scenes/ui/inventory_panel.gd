extends CanvasLayer

const ITEM_DATA_PATH := "res://data/item_text.csv"
const CATEGORY_ORDER := {"relic": 0, "nutrient": 1, "clue": 2, "component": 3}
const CATEGORY_NAMES := {"relic": "遗物", "nutrient": "养分 / 液体", "clue": "线索", "component": "组件"}

var _entries: Dictionary = {}
var _root: Control
var _list: VBoxContainer
var _was_paused := false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_entries()
	_build_ui()
	_root.visible = false
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.item_collected.connect(func(_id: StringName) -> void: _refresh())
		game_state.counter_changed.connect(func(_id: StringName, _value: int) -> void: _refresh())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"inventory"):
		set_open(not is_open())
		get_viewport().set_input_as_handled()
	elif is_open() and event.is_action_pressed(&"pause"):
		set_open(false)
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return is_instance_valid(_root) and _root.visible


func set_open(opened: bool) -> void:
	if not is_instance_valid(_root) or _root.visible == opened:
		return
	if opened:
		_was_paused = get_tree().paused
		_refresh()
		_root.visible = true
		get_tree().paused = true
	else:
		_root.visible = false
		get_tree().paused = _was_paused


func entry_count() -> int:
	var game_state := get_node_or_null("/root/GameState")
	return game_state.items.size() if game_state != null else 0


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "InventoryRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.008, 0.012, 0.025, 0.86)
	_root.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(170, 70)
	panel.size = Vector2(940, 580)
	_root.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var header := Label.new()
	header.text = "本局背包"
	header.add_theme_font_size_override("font_size", 32)
	content.add_child(header)
	var hint := Label.new()
	hint.text = "I / Tab / Esc 关闭 · 本局重开后物品清空"
	hint.add_theme_color_override("font_color", Color(0.66, 0.72, 0.84))
	hint.add_theme_font_size_override("font_size", 17)
	content.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(880, 450)
	content.add_child(scroll)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(850, 0)
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)


func _refresh() -> void:
	if not is_instance_valid(_list):
		return
	for child in _list.get_children():
		child.queue_free()
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or game_state.items.is_empty():
		var empty := Label.new()
		empty.text = "背包还是空的。继续探索生态环。"
		empty.add_theme_font_size_override("font_size", 21)
		_list.add_child(empty)
		return
	var ids: Array = game_state.items.keys()
	ids.sort_custom(_sort_item_ids)
	var last_category := ""
	for raw_id in ids:
		var item_id := StringName(raw_id)
		var entry: Dictionary = _entries.get(item_id, {})
		var category := str(entry.get("category", "component"))
		if category != last_category:
			last_category = category
			var category_label := Label.new()
			category_label.text = CATEGORY_NAMES.get(category, "其他")
			category_label.add_theme_font_size_override("font_size", 22)
			category_label.add_theme_color_override("font_color", Color(0.82, 0.62, 1.0))
			_list.add_child(category_label)
		_list.add_child(_build_item_row(item_id, entry))


func _build_item_row(item_id: StringName, entry: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(840, 74)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	var myth := str(entry.get("myth_name", item_id))
	var progress_state := get_node_or_null("/root/ProgressState")
	var real := str(entry.get("real_name", ""))
	var name_text := myth
	if progress_state != null and progress_state.first_ending_seen and not real.is_empty():
		name_text += "  /  %s" % real
	label.text = "%s\n%s" % [name_text, str(entry.get("description", "尚无说明。"))]
	margin.add_child(label)
	return row


func _sort_item_ids(a: Variant, b: Variant) -> bool:
	var a_entry: Dictionary = _entries.get(StringName(a), {})
	var b_entry: Dictionary = _entries.get(StringName(b), {})
	var a_category := str(a_entry.get("category", "component"))
	var b_category := str(b_entry.get("category", "component"))
	var a_order := int(CATEGORY_ORDER.get(a_category, 99))
	var b_order := int(CATEGORY_ORDER.get(b_category, 99))
	if a_order == b_order:
		return str(a) < str(b)
	return a_order < b_order


func _load_entries() -> void:
	var file := FileAccess.open(ITEM_DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var headers := file.get_csv_line()
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.is_empty() or values[0].strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index in range(mini(headers.size(), values.size())):
			row[headers[index].strip_edges()] = values[index]
		_entries[StringName(values[0])] = row

