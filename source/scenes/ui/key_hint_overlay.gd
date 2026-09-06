extends CanvasLayer

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")
const ICON_SIZE := Vector2(24, 24)

var _panel: PanelContainer


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()
	_panel.visible = false


func is_open() -> bool:
	return is_instance_valid(_panel) and _panel.visible


func set_open(opened: bool) -> void:
	if is_instance_valid(_panel):
		_panel.visible = opened


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"key_hints_toggle"):
		set_open(not is_open())
		get_viewport().set_input_as_handled()


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "KeyHints"
	_panel.position = Vector2(944, 18)
	_panel.size = Vector2(318, 204)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PIXEL_UI.apply_panel(_panel, Color(0.012, 0.020, 0.044, 0.92), Color(0.28, 0.38, 0.54), 3)
	add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	margin.add_child(content)
	var title := Label.new()
	title.text = "操作提示 · U 开关"
	title.add_theme_font_size_override("font_size", 18)
	PIXEL_UI.apply_title(title, Color(0.70, 0.84, 1.0))
	content.add_child(title)
	_add_row(content, "移动", ["ui_key_w.png", "ui_key_a.png", "ui_key_s.png", "ui_key_d.png"])
	_add_row(content, "互动", ["ui_key_e.png"])
	_add_row(content, "蓄力 / 确认", ["ui_key_space.png"])
	_add_row(content, "背包", ["ui_key_i.png", "ui_key_tab.png"])
	_add_row(content, "地图", ["ui_key_m.png"])
	_add_row(content, "暂停", ["ui_key_esc.png"])
	_add_row(content, "重开", ["ui_key_r.png"])


func _add_row(parent: VBoxContainer, label_text: String, key_files: Array[String]) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.custom_minimum_size = Vector2(0, 25)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(86, 24)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)
	for file_name in key_files:
		_add_key_icon(row, file_name)


func _add_key_icon(parent: HBoxContainer, file_name: String) -> void:
	var icon := TextureRect.new()
	var asset_library := get_node_or_null("/root/AssetLibrary")
	if asset_library != null:
		icon.texture = asset_library.get_texture(StringName(file_name))
	if icon.texture == null:
		var fallback := Label.new()
		fallback.text = file_name.trim_suffix(".png").trim_prefix("ui_key_").to_upper()
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.custom_minimum_size = Vector2(52, 24) if file_name == "ui_key_space.png" else ICON_SIZE
		fallback.add_theme_font_size_override("font_size", 12)
		parent.add_child(fallback)
		return
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(52, 24) if file_name == "ui_key_space.png" else ICON_SIZE
	icon.size = icon.custom_minimum_size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
