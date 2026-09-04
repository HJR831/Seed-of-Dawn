extends CanvasLayer

const STAGE_POSITIONS := [
	Vector2(310, 3040), Vector2(940, 2180), Vector2(980, 1280), Vector2(640, 390)
]

var _root_panel: PanelContainer
var _state_label: Label
var _update_elapsed: float = 0.0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()
	_root_panel.visible = false


func _process(delta: float) -> void:
	if not _root_panel.visible:
		return
	_update_elapsed += delta
	if _update_elapsed >= 0.15:
		_update_elapsed = 0.0
		_refresh_state()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event.is_action_pressed(&"debug_toggle"):
		return
	_root_panel.visible = not _root_panel.visible
	if _root_panel.visible:
		_refresh_state()
	get_viewport().set_input_as_handled()


func _build_panel() -> void:
	_root_panel = PanelContainer.new()
	_root_panel.position = Vector2(770, 70)
	_root_panel.size = Vector2(480, 575)
	add_child(_root_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	_root_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var title := Label.new()
	title.text = "DEBUG · 本局状态（F3 关闭）"
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)
	_state_label = Label.new()
	_state_label.custom_minimum_size = Vector2(430, 215)
	_state_label.add_theme_font_size_override("font_size", 16)
	content.add_child(_state_label)
	var teleport_title := Label.new()
	teleport_title.text = "快速传送"
	content.add_child(teleport_title)
	var teleports := HBoxContainer.new()
	content.add_child(teleports)
	for index in range(STAGE_POSITIONS.size()):
		var button := Button.new()
		button.text = str(index + 1)
		button.pressed.connect(_teleport.bind(index))
		teleports.add_child(button)
	var actions_title := Label.new()
	actions_title.text = "快速修改"
	content.add_child(actions_title)
	var actions := GridContainer.new()
	actions.columns = 2
	content.add_child(actions)
	_add_button(actions, "+ 腐败之眼", _add_item.bind(&"corrupt_eye"))
	_add_button(actions, "+ 牛奶滴", _add_counter.bind(&"milk_count"))
	_add_button(actions, "+ 霜晶", _add_counter.bind(&"frost_count"))
	_add_button(actions, "+ 价签", _add_counter.bind(&"barcode_count"))
	_add_button(actions, "+ 噪音", _add_stat.bind(&"noise"))
	_add_button(actions, "+ 破坏", _add_stat.bind(&"destruction"))
	_add_button(actions, "完成测试仪式", _complete_ritual.bind(&"debug_ritual"))
	_add_button(actions, "重置本局", _reset_run)
	_add_button(actions, "清空结局图鉴", _clear_progress)


func _refresh_state() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		_state_label.text = "GameState 不可用"
		return
	_state_label.text = (
		"devour %d  nurture %d  noise %d\n" +
		"destruction %d  corruption %d\n" +
		"milk %d  frost %d  barcode %d\n" +
		"compressor %d  bottle hits %d  lid hits %d\n" +
		"items: %s\nflags: %s\nrituals: %s\n" +
		"nearby trigger: 基础阶段未接入结局入口\nlast failure: —"
	) % [
		game_state.devour, game_state.nurture, game_state.noise,
		game_state.destruction, game_state.corruption,
		game_state.get_counter(&"milk_count"), game_state.get_counter(&"frost_count"),
		game_state.get_counter(&"barcode_count"), game_state.get_counter(&"compressor_start_count"),
		game_state.get_counter(&"bottle_hit_count"), game_state.get_counter(&"lid_hit_count"),
		str(game_state.items.keys()), str(game_state.flags.keys()), str(game_state.rituals.keys())
	]


func _teleport(index: int) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null:
		player.global_position = STAGE_POSITIONS[index]


func _add_item(item_id: StringName) -> void:
	get_node("/root/GameState").collect_item(item_id)


func _add_counter(counter_id: StringName) -> void:
	get_node("/root/GameState").increment_counter(counter_id)


func _add_stat(stat_id: StringName) -> void:
	get_node("/root/GameState").add_stat(stat_id, 1)


func _complete_ritual(ritual_id: StringName) -> void:
	get_node("/root/GameState").complete_ritual(ritual_id)


func _reset_run() -> void:
	var main_scene := get_tree().current_scene
	if main_scene != null and main_scene.has_method("_start_new_run"):
		main_scene.call_deferred("_start_new_run")
	else:
		get_node("/root/GameState").reset_run()


func _clear_progress() -> void:
	get_node("/root/ProgressState").clear_unlocked_endings()


func _add_button(parent: Control, label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(205, 34)
	button.pressed.connect(callback)
	parent.add_child(button)
