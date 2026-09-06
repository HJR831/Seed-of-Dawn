extends CanvasLayer

const ITEM_DATA_PATH := "res://data/item_text.csv"
const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")
const CATEGORY_ORDER := {"relic": 0, "nutrient": 1, "clue": 2, "component": 3}
const CATEGORY_NAMES := {"relic": "遗物", "nutrient": "养分 / 液体", "clue": "线索", "component": "组件"}

var _entries: Dictionary = {}
var _root: Control
var _list: VBoxContainer
var _was_paused := false
var _refresh_queued := false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_entries()
	_build_ui()
	_root.visible = false
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.item_collected.connect(func(_id: StringName) -> void: _queue_refresh())
		game_state.counter_changed.connect(func(_id: StringName, _value: int) -> void: _queue_refresh())
	var guidance := get_node_or_null("/root/GuidanceDirector")
	if guidance != null:
		guidance.history_changed.connect(_queue_refresh)
	var effects := get_node_or_null("/root/ItemEffectDirector")
	if effects != null:
		effects.effect_changed.connect(func(_id: StringName, _active: bool) -> void: _queue_refresh())
		effects.effect_charge_changed.connect(func(_id: StringName, _amount: int) -> void: _queue_refresh())


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
		var map_panel := get_parent().get_node_or_null("MapPanel")
		if map_panel != null and map_panel.has_method("set_full_open"):
			map_panel.set_full_open(false)
		_was_paused = get_tree().paused
		_root.visible = true
		_refresh()
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
	PIXEL_UI.apply_panel(panel, Color(0.018, 0.027, 0.055, 0.98), Color(0.38, 0.30, 0.62), 5)
	panel.z_index = 1
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
	PIXEL_UI.apply_title(header)
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
	if not is_inside_tree() or not is_instance_valid(_list) or not _root.visible:
		return
	for child in _list.get_children():
		child.queue_free()
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or game_state.items.is_empty():
		var empty := Label.new()
		empty.text = "背包还是空的。继续探索生态环。"
		empty.add_theme_font_size_override("font_size", 21)
		_list.add_child(empty)
	else:
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
	_build_effect_summary()
	_build_guidance_history()


func _queue_refresh() -> void:
	if _refresh_queued or not is_instance_valid(_root) or not _root.visible:
		return
	_refresh_queued = true
	call_deferred("_deferred_refresh")


func _deferred_refresh() -> void:
	_refresh_queued = false
	_refresh()


func _build_effect_summary() -> void:
	var title := Label.new()
	title.text = "当前效果"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.90, 0.68, 0.35))
	PIXEL_UI.apply_title(title, Color(0.90, 0.68, 0.35))
	_list.add_child(title)
	var effects := get_node_or_null("/root/ItemEffectDirector")
	var summary: Array[Dictionary] = effects.get_effect_summary() if effects != null else []
	if summary.is_empty():
		var empty := Label.new()
		empty.text = "尚未激活特殊效果。"
		empty.add_theme_color_override("font_color", Color(0.58, 0.64, 0.74))
		_list.add_child(empty)
		return
	for entry in summary:
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(820, 34)
		line.add_theme_font_size_override("font_size", 17)
		line.text = "· %s：%s" % [str(entry.get("label", entry.get("effect_id", "状态"))), str(entry.get("summary", "已激活"))]
		_list.add_child(line)


func _build_guidance_history() -> void:
	var title := Label.new()
	title.text = "启示"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.70, 0.82, 1.0))
	PIXEL_UI.apply_title(title, Color(0.70, 0.82, 1.0))
	_list.add_child(title)
	var guidance := get_node_or_null("/root/GuidanceDirector")
	var history: Array[StringName] = guidance.get_history() if guidance != null else []
	if history.is_empty():
		var empty := Label.new()
		empty.text = "尚未获得可重读的启示。"
		empty.add_theme_color_override("font_color", Color(0.58, 0.64, 0.74))
		_list.add_child(empty)
		return
	var narrative := get_node_or_null("/root/NarrativeManager")
	for text_id in history:
		var entry: Dictionary = narrative.get_entry(text_id) if narrative != null else {}
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(820, 42)
		line.add_theme_font_size_override("font_size", 17)
		line.text = "· %s" % str(entry.get("zh_cn", text_id))
		_list.add_child(line)


func _build_item_row(item_id: StringName, entry: Dictionary) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(840, 92)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = false
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	PIXEL_UI.apply_button(button, Color(0.32, 0.45, 0.70))
	var myth := str(entry.get("myth_name", item_id))
	var progress_state := get_node_or_null("/root/ProgressState")
	var real := str(entry.get("real_name", ""))
	var name_text := myth
	if progress_state != null and progress_state.first_ending_seen and not real.is_empty():
		name_text += "  /  %s" % real
	var effect_text := ""
	var effects := get_node_or_null("/root/ItemEffectDirector")
	if effects != null and effects.has_method("get_item_effect_text"):
		effect_text = str(effects.get_item_effect_text(item_id))
	var description := str(entry.get("description", "尚无说明。"))
	button.text = "%s\n%s%s\n[点击查看详情]" % [name_text, description, ("\n" + effect_text) if not effect_text.is_empty() else ""]
	button.add_theme_font_size_override("font_size", 16)
	var asset_library := get_node_or_null("/root/AssetLibrary")
	if asset_library != null and asset_library.has_method("get_item_texture"):
		var texture: Texture2D = asset_library.get_item_texture(item_id)
		if texture != null:
			button.icon = texture
			button.add_theme_constant_override("icon_max_width", 68)
	button.pressed.connect(_on_item_pressed.bind(item_id))
	return button


func _on_item_pressed(item_id: StringName) -> void:
	var popup := get_tree().get_first_node_in_group(&"item_detail_popup")
	if popup != null and popup.has_method("show_item"):
		popup.show_item(item_id, true)


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
