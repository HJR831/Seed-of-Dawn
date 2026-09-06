extends CanvasLayer

signal start_requested
signal tutorial_requested
signal exit_requested

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")

var _root: Control
var _start_button: Button
var _tutorial_button: Button
var _hint: Label


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not is_menu_visible():
		return
	if event.is_action_pressed(&"pause"):
		exit_requested.emit()
		get_viewport().set_input_as_handled()


func is_menu_visible() -> bool:
	return is_instance_valid(_root) and _root.visible


func show_menu() -> void:
	if is_instance_valid(_root):
		_root.visible = true
		_start_button.grab_focus()


func hide_menu() -> void:
	if is_instance_valid(_root):
		_root.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "MainMenuRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var library := get_node_or_null("/root/AssetLibrary")
	background.texture = library.get_texture(&"ui_main_menu_background.png") if library != null else null
	background.modulate = Color(0.72, 0.78, 1.0, 0.82)
	_root.add_child(background)
	var veil := ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.008, 0.012, 0.035, 0.42)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(veil)
	var left_panel := Panel.new()
	left_panel.position = Vector2(70, 74)
	left_panel.size = Vector2(650, 572)
	PIXEL_UI.apply_panel(left_panel, Color(0.012, 0.018, 0.045, 0.86), Color(0.40, 0.28, 0.64), 5)
	_root.add_child(left_panel)
	var logo := TextureRect.new()
	logo.position = Vector2(124, 112)
	logo.size = Vector2(540, 210)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.texture = library.get_first_texture([&"ui_logo.png", &"ui_logo_dark.png"]) if library != null else null
	_root.add_child(logo)
	var title := Label.new()
	title.position = Vector2(120, 320)
	title.size = Vector2(550, 55)
	title.text = "没有黎明的冰箱"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	PIXEL_UI.apply_title(title, Color(0.84, 0.72, 1.0))
	_root.add_child(title)
	var subtitle := Label.new()
	subtitle.position = Vector2(130, 385)
	subtitle.size = Vector2(530, 58)
	subtitle.text = "向上生长，穿过七层生态与遗忘。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.64, 0.72, 0.88))
	_root.add_child(subtitle)
	_start_button = _make_button("开始游戏", Vector2(850, 278), Color(0.68, 0.40, 0.92))
	_start_button.pressed.connect(start_requested.emit)
	_tutorial_button = _make_button("新手教程", Vector2(850, 358), Color(0.38, 0.70, 0.92))
	_tutorial_button.pressed.connect(tutorial_requested.emit)
	var exit_button := _make_button("退出游戏", Vector2(850, 438), Color(0.82, 0.38, 0.45))
	exit_button.pressed.connect(exit_requested.emit)
	_hint = Label.new()
	_hint.position = Vector2(820, 532)
	_hint.size = Vector2(370, 45)
	_hint.text = "WASD 移动 · Shift 疾跑 · E 交互 · I / Tab 背包"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Color(0.68, 0.76, 0.90))
	_root.add_child(_hint)
	var version := Label.new()
	version.position = Vector2(76, 676)
	version.size = Vector2(500, 24)
	version.text = "A PIXEL MYTH OF REFRIGERATED GROWTH"
	version.add_theme_font_size_override("font_size", 13)
	version.add_theme_color_override("font_color", Color(0.46, 0.54, 0.70))
	_root.add_child(version)


func _make_button(text_value: String, at: Vector2, accent: Color) -> Button:
	var button := Button.new()
	button.position = at
	button.size = Vector2(360, 58)
	button.text = text_value
	button.add_theme_font_size_override("font_size", 22)
	PIXEL_UI.apply_button(button, accent)
	_root.add_child(button)
	return button
