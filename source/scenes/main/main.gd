extends Node

const LEVEL_SCENE := preload("res://scenes/levels/fridge_level.tscn")
const ENDING_SCREEN_SCENE := preload("res://scenes/ui/ending_screen.tscn")

const ACTION_KEYS := {
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"interact": [KEY_E],
	&"charge": [KEY_SPACE],
	&"restart_run": [KEY_R],
	&"pause": [KEY_ESCAPE],
	&"skip_text": [KEY_ENTER, KEY_SPACE],
	&"debug_toggle": [KEY_F3],
}

var current_level: Node
var ending_screen: CanvasLayer
var pause_overlay: Control


func _enter_tree() -> void:
	_ensure_input_actions()


func _ready() -> void:
	_build_pause_overlay()
	_start_new_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and ending_screen == null:
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _ensure_input_actions() -> void:
	for action in ACTION_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if not InputMap.action_get_events(action).is_empty():
			continue
		for key_code in ACTION_KEYS[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = key_code
			InputMap.action_add_event(action, key_event)


func _start_new_run() -> void:
	get_tree().paused = false
	pause_overlay.visible = false

	if is_instance_valid(ending_screen):
		remove_child(ending_screen)
		ending_screen.queue_free()
	ending_screen = null

	if is_instance_valid(current_level):
		remove_child(current_level)
		current_level.queue_free()

	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.reset_run()
	current_level = LEVEL_SCENE.instantiate()
	add_child(current_level)
	current_level.ending_requested.connect(_on_ending_requested)


func _on_ending_requested(ending_id: StringName) -> void:
	if is_instance_valid(ending_screen):
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.finish_run(ending_id)
	var progress_state := get_node_or_null("/root/ProgressState")
	if progress_state != null:
		progress_state.unlock_ending(ending_id)

	if current_level.has_method("set_player_input_enabled"):
		current_level.set_player_input_enabled(false)

	ending_screen = ENDING_SCREEN_SCENE.instantiate()
	add_child(ending_screen)
	ending_screen.restart_requested.connect(_start_new_run)


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_overlay.visible = get_tree().paused


func _build_pause_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PauseLayer"
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	pause_overlay = Control.new()
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	layer.add_child(pause_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.015, 0.035, 0.86)
	pause_overlay.add_child(shade)

	var text := Label.new()
	text.text = "已暂停\n\n按 Esc 继续"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 34)
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(text)
