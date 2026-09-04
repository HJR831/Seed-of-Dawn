extends CanvasLayer

@export var characters_per_second: float = 32.0

var _panel: ColorRect
var _speaker_label: Label
var _text_label: Label
var _full_text: String = ""
var _visible_float: float = 0.0
var _display_elapsed: float = 0.0
var _display_duration: float = 3.0
var _typing: bool = false
var _active: bool = false


func _ready() -> void:
	layer = 60
	_build_ui()
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null:
		narrative.text_started.connect(_on_text_started)
		narrative.queue_cleared.connect(_hide)


func _process(delta: float) -> void:
	if not _active:
		return
	if _typing:
		_visible_float += characters_per_second * delta
		_text_label.visible_characters = mini(floori(_visible_float), _full_text.length())
		if _text_label.visible_characters >= _full_text.length():
			_typing = false
			_display_elapsed = 0.0
	else:
		_display_elapsed += delta
		if _display_elapsed >= _display_duration:
			_finish()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not event.is_action_pressed(&"skip_text"):
		return
	if _typing:
		_typing = false
		_text_label.visible_characters = -1
		_display_elapsed = 0.0
	else:
		_finish()
	get_viewport().set_input_as_handled()


func _on_text_started(entry: Dictionary) -> void:
	_full_text = str(entry.get("zh_cn", ""))
	_display_duration = maxf(float(entry.get("duration", 3.0)), 0.25)
	_speaker_label.text = str(entry.get("speaker", "神谕"))
	_text_label.text = _full_text
	_text_label.visible_characters = 0
	_visible_float = 0.0
	_display_elapsed = 0.0
	_typing = true
	_active = true
	_panel.visible = true
	_speaker_label.visible = true
	_text_label.visible = true


func _finish() -> void:
	if not _active:
		return
	_active = false
	_hide()
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null:
		narrative.finish_current_text()


func _hide() -> void:
	_active = false
	if is_instance_valid(_panel):
		_panel.visible = false
		_speaker_label.visible = false
		_text_label.visible = false


func _build_ui() -> void:
	_panel = ColorRect.new()
	_panel.position = Vector2(150, 540)
	_panel.size = Vector2(980, 132)
	_panel.color = Color(0.015, 0.022, 0.052, 0.91)
	add_child(_panel)
	_speaker_label = Label.new()
	_speaker_label.position = Vector2(184, 556)
	_speaker_label.size = Vector2(900, 28)
	_speaker_label.add_theme_font_size_override("font_size", 17)
	_speaker_label.add_theme_color_override("font_color", Color(0.70, 0.55, 0.94))
	add_child(_speaker_label)
	_text_label = Label.new()
	_text_label.position = Vector2(184, 590)
	_text_label.size = Vector2(900, 62)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 22)
	_text_label.add_theme_color_override("font_color", Color(0.90, 0.93, 1.0))
	add_child(_text_label)
	_hide()
