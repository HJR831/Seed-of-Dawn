extends CanvasLayer

## F3 is intentionally gated behind the developer UID so the test harness is
## available to the team in Godot without becoming part of normal play.

signal authorized

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")
const DEVELOPER_UID := "wutiaowu831"

var _overlay: Control
var _uid_edit: LineEdit
var _status: Label
var _was_paused := false


func _ready() -> void:
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_overlay.visible = false


func is_open() -> bool:
	return is_instance_valid(_overlay) and _overlay.visible


func open() -> void:
	if not is_instance_valid(_overlay) or _overlay.visible:
		return
	_was_paused = get_tree().paused
	_overlay.visible = true
	_status.text = "请输入开发者 UID 后按 Enter"
	_uid_edit.clear()
	get_tree().paused = true
	call_deferred("_focus_input")


func close() -> void:
	if not is_instance_valid(_overlay):
		return
	_overlay.visible = false
	get_tree().paused = _was_paused


func _focus_input() -> void:
	if is_instance_valid(_uid_edit) and is_open():
		_uid_edit.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		_try_authorize()
		get_viewport().set_input_as_handled()


func _try_authorize() -> void:
	if _uid_edit.text.strip_edges() != DEVELOPER_UID:
		_status.text = "UID 不正确，请重新输入"
		_uid_edit.select_all()
		_uid_edit.grab_focus()
		return
	close()
	authorized.emit()


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "DebugAuthOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.004, 0.008, 0.018, 0.84)
	_overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(390, 238)
	panel.size = Vector2(500, 244)
	PIXEL_UI.apply_panel(panel, Color(0.014, 0.024, 0.050, 0.99), Color(0.56, 0.34, 0.76), 4)
	_overlay.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = "开发者调试入口"
	title.add_theme_font_size_override("font_size", 27)
	PIXEL_UI.apply_title(title)
	content.add_child(title)
	var prompt := Label.new()
	prompt.text = "F3 已按下 · 输入开发者 UID"
	prompt.add_theme_font_size_override("font_size", 16)
	content.add_child(prompt)
	_uid_edit = LineEdit.new()
	_uid_edit.placeholder_text = "Developer UID"
	_uid_edit.custom_minimum_size = Vector2(0, 42)
	_uid_edit.secret = false
	_uid_edit.text_submitted.connect(func(_text: String) -> void: _try_authorize())
	content.add_child(_uid_edit)
	_status = Label.new()
	_status.text = "请输入开发者 UID 后按 Enter"
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color(0.70, 0.78, 0.92))
	content.add_child(_status)
	var cancel := Label.new()
	cancel.text = "Esc 取消"
	cancel.add_theme_font_size_override("font_size", 13)
	cancel.add_theme_color_override("font_color", Color(0.56, 0.62, 0.76))
	content.add_child(cancel)
