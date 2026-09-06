extends Node

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")

const LEVEL_SCENE := preload("res://scenes/levels/fridge_level.tscn")
const ENDING_SCREEN_SCENE := preload("res://scenes/ui/ending_screen.tscn")
const MAIN_MENU_SCRIPT := preload("res://scenes/ui/main_menu.gd")
const TUTORIAL_SCRIPT := preload("res://scenes/ui/tutorial_overlay.gd")
const DEBUG_AUTH_SCRIPT := preload("res://scenes/ui/debug_auth.gd")

const ACTION_KEYS := {
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"interact": [KEY_E],
	&"charge": [KEY_SPACE],
	&"restart_run": [KEY_R],
	&"pause": [KEY_ESCAPE],
	&"inventory": [KEY_I, KEY_TAB],
	&"sprint": [KEY_SHIFT],
	&"world_map": [KEY_M],
	&"key_hints_toggle": [KEY_U],
	&"skip_text": [KEY_ENTER, KEY_SPACE],
	&"debug_toggle": [KEY_F3],
}

var current_level: Node
var ending_screen: CanvasLayer
var pause_overlay: Control
var main_menu: CanvasLayer
var tutorial_overlay: CanvasLayer
var debug_auth: CanvasLayer
var debug_unlocked := false
var _is_test_harness := false


func _enter_tree() -> void:
	_ensure_input_actions()


func _ready() -> void:
	_is_test_harness = get_tree().current_scene != self
	_apply_global_theme()
	_build_pause_overlay()
	_build_debug_auth()
	_start_new_run()
	if not _is_test_harness:
		_build_front_end()


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(main_menu) and main_menu.has_method("is_menu_visible") and main_menu.is_menu_visible():
		return
	if is_instance_valid(tutorial_overlay) and tutorial_overlay.has_method("is_open") and tutorial_overlay.is_open():
		return
	if event.is_action_pressed(&"debug_toggle"):
		if debug_unlocked:
			_open_debug_panel()
		elif is_instance_valid(debug_auth):
			debug_auth.open()
		get_viewport().set_input_as_handled()
		return
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


func _apply_global_theme() -> void:
	var font := PIXEL_UI.get_font()
	if font == null:
		return
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 18
	get_tree().root.theme = theme


func _build_front_end() -> void:
	main_menu = MAIN_MENU_SCRIPT.new()
	main_menu.name = "MainMenu"
	add_child(main_menu)
	main_menu.start_requested.connect(_on_menu_start)
	main_menu.tutorial_requested.connect(_on_menu_tutorial)
	main_menu.exit_requested.connect(_on_menu_exit)
	tutorial_overlay = TUTORIAL_SCRIPT.new()
	tutorial_overlay.name = "TutorialOverlay"
	add_child(tutorial_overlay)
	tutorial_overlay.completed.connect(_on_tutorial_completed)
	current_level.set_player_input_enabled(false)
	get_tree().paused = true
	main_menu.show_menu()


func _build_debug_auth() -> void:
	debug_auth = DEBUG_AUTH_SCRIPT.new()
	debug_auth.name = "DebugAuth"
	add_child(debug_auth)
	debug_auth.authorized.connect(_on_debug_authorized)


func _on_debug_authorized() -> void:
	debug_unlocked = true
	_open_debug_panel()


func _open_debug_panel() -> void:
	if not is_instance_valid(current_level):
		return
	var panel := current_level.get_node_or_null("DebugPanel")
	if panel != null and panel.has_method("unlock_and_open"):
		panel.unlock_and_open()


func _on_menu_start() -> void:
	if is_instance_valid(main_menu):
		main_menu.hide_menu()
	if is_instance_valid(current_level):
		current_level.set_player_input_enabled(true)
	get_tree().paused = false
	var progress := get_node_or_null("/root/ProgressState")
	if progress != null and not bool(progress.tutorial_seen) and is_instance_valid(tutorial_overlay):
		current_level.set_player_input_enabled(false)
		tutorial_overlay.open(false)


func _on_menu_tutorial() -> void:
	if is_instance_valid(main_menu):
		main_menu.hide_menu()
	if is_instance_valid(current_level):
		current_level.set_player_input_enabled(false)
	if is_instance_valid(tutorial_overlay):
		tutorial_overlay.open(true)


func _on_tutorial_completed(return_to_menu: bool) -> void:
	if return_to_menu:
		if is_instance_valid(current_level):
			current_level.set_player_input_enabled(false)
		get_tree().paused = true
		if is_instance_valid(main_menu):
			main_menu.show_menu()
		return
	if is_instance_valid(current_level):
		current_level.set_player_input_enabled(true)
	get_tree().paused = false


func _on_menu_exit() -> void:
	get_tree().quit()


func _start_new_run(seed_override: int = -1) -> void:
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
		game_state.reset_run(seed_override)
	var progress_state := get_node_or_null("/root/ProgressState")
	if progress_state != null:
		progress_state.record_run_started()
	current_level = LEVEL_SCENE.instantiate()
	add_child(current_level)
	current_level.ending_requested.connect(_on_ending_requested)


func _on_ending_requested(ending_id: StringName) -> void:
	if is_instance_valid(ending_screen):
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.finish_run(ending_id)
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null:
		narrative.clear_queue()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.stop_all()
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
	var pause_panel := Panel.new()
	pause_panel.position = Vector2(340, 170)
	pause_panel.size = Vector2(600, 380)
	PIXEL_UI.apply_panel(pause_panel, Color(0.018, 0.027, 0.055, 0.98), Color(0.44, 0.31, 0.68), 6)
	pause_overlay.add_child(pause_panel)

	var text := Label.new()
	text.text = "已暂停\n\n按 Esc 继续"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 34)
	PIXEL_UI.apply_title(text)
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(text)
