extends CanvasLayer

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")
const PIXEL_FEEDBACK := preload("res://scenes/ui/pixel_feedback_overlay.gd")

var _root: Control
var _label: Label
var _flash: Control
var _token := 0


func _ready() -> void:
	layer = 65
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"guidance_overlay")
	_build_ui()
	var director := get_node_or_null("/root/GuidanceDirector")
	if director != null:
		director.guidance_issued.connect(_on_guidance_issued)


func _on_guidance_issued(text_id: StringName, presentation: StringName, feedback_id: StringName) -> void:
	_play_feedback(feedback_id)
	if presentation != &"center":
		return
	var narrative := get_node_or_null("/root/NarrativeManager")
	var entry: Dictionary = narrative.get_entry(text_id) if narrative != null else {}
	var text_value := str(entry.get("zh_cn", text_id))
	_token += 1
	var current_token := _token
	_label.text = text_value
	_root.visible = true
	_root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, 0.20)
	tween.tween_interval(maxf(float(entry.get("duration", 3.0)), 1.5))
	tween.tween_property(_root, "modulate:a", 0.0, 0.35)
	await tween.finished
	if current_token == _token:
		_root.visible = false


func _play_feedback(feedback_id: StringName) -> void:
	if feedback_id.is_empty():
		return
	_flash.play_feedback(feedback_id)


func debug_play_feedback(feedback_id: StringName) -> void:
	_play_feedback(feedback_id)


func is_active() -> bool:
	return is_instance_valid(_root) and _root.visible


func _build_ui() -> void:
	_flash = PIXEL_FEEDBACK.new()
	add_child(_flash)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	var panel := Panel.new()
	panel.position = Vector2(190, 270)
	panel.size = Vector2(900, 150)
	PIXEL_UI.apply_panel(panel, Color(0.025, 0.008, 0.052, 0.94), Color(0.60, 0.30, 0.80), 5)
	_root.add_child(panel)
	_label = Label.new()
	_label.position = Vector2(225, 290)
	_label.size = Vector2(830, 110)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 29)
	_label.add_theme_color_override("font_color", Color(0.88, 0.68, 1.0))
	PIXEL_UI.apply_title(_label, Color(0.88, 0.68, 1.0))
	_root.add_child(_label)
