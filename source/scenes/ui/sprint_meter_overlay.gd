extends CanvasLayer

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")

var _bar: ProgressBar
var _state_label: Label
var _player: Node


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(_player):
		return
	var ratio := float(_player.get_sprint_ratio()) if _player.has_method("get_sprint_ratio") else 1.0
	_bar.value = clampf(ratio, 0.0, 1.0)
	var active: bool = _player.has_method("is_sprinting") and _player.is_sprinting()
	_state_label.text = "疾跑中" if active else "按住 Shift 疾跑"
	_state_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38) if active else Color(0.72, 0.78, 0.90))


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "SprintMeter"
	panel.position = Vector2(934, 674)
	panel.size = Vector2(328, 42)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PIXEL_UI.apply_panel(panel, Color(0.012, 0.020, 0.044, 0.92), Color(0.52, 0.40, 0.22), 2)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var icon := Label.new()
	icon.text = "SHIFT"
	icon.custom_minimum_size = Vector2(54, 22)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 11)
	row.add_child(icon)
	_state_label = Label.new()
	_state_label.text = "按住 Shift 疾跑"
	_state_label.custom_minimum_size = Vector2(112, 22)
	_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_state_label.add_theme_font_size_override("font_size", 13)
	row.add_child(_state_label)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(124, 17)
	_bar.max_value = 1.0
	_bar.value = 1.0
	_bar.show_percentage = false
	PIXEL_UI.apply_progress(_bar, Color(0.98, 0.68, 0.24))
	row.add_child(_bar)
