extends CanvasLayer

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")
const ASSET_GALLERY := preload("res://scenes/ui/asset_debug_gallery.gd")
const POINT_TELEPORTER := preload("res://scenes/ui/asset_point_teleporter.gd")
const STAGE_POSITIONS := [
	Vector2(12800, 23200), Vector2(12800, 19600), Vector2(12800, 16000), Vector2(12800, 12800),
	Vector2(12800, 9000), Vector2(12800, 5200), Vector2(12800, 1800)
]

var _root_panel: PanelContainer
var _state_label: Label
var _update_elapsed: float = 0.0
var _asset_gallery
var _point_teleporter


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()
	_root_panel.visible = false


func unlock_and_open() -> void:
	## Called only after the F3 developer UID has been verified.
	if not OS.is_debug_build() or not is_instance_valid(_root_panel):
		return
	_root_panel.visible = true
	_refresh_state()


func _process(delta: float) -> void:
	if not _root_panel.visible:
		return
	_update_elapsed += delta
	if _update_elapsed >= 0.15:
		_update_elapsed = 0.0
		_refresh_state()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if is_instance_valid(_point_teleporter) and _point_teleporter.visible and event.is_action_pressed(&"pause"):
		_close_point_teleporter()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_asset_gallery) and _asset_gallery.visible and event.is_action_pressed(&"pause"):
		_close_asset_gallery()
		get_viewport().set_input_as_handled()
		return


func _build_panel() -> void:
	_root_panel = PanelContainer.new()
	_root_panel.position = Vector2(770, 8)
	_root_panel.size = Vector2(480, 704)
	PIXEL_UI.apply_panel(_root_panel, Color(0.012, 0.020, 0.044, 0.98), Color(0.30, 0.42, 0.60), 4)
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
	title.text = "TEST HARNESS · 本局状态"
	title.add_theme_font_size_override("font_size", 22)
	PIXEL_UI.apply_title(title)
	content.add_child(title)
	_state_label = Label.new()
	_state_label.custom_minimum_size = Vector2(430, 150)
	_state_label.add_theme_font_size_override("font_size", 13)
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
		PIXEL_UI.apply_button(button)
		teleports.add_child(button)
	var actions_title := Label.new()
	actions_title.text = "快速修改"
	content.add_child(actions_title)
	var actions := GridContainer.new()
	actions.columns = 3
	content.add_child(actions)
	_add_button(actions, "素材检查总览", _open_asset_gallery)
	_add_button(actions, "素材点传送", _open_point_teleporter)
	_add_button(actions, "VFX 古神", _preview_feedback.bind(&"eldritch_eye"))
	_add_button(actions, "VFX 霜冻", _preview_feedback.bind(&"eldritch_frost"))
	_add_button(actions, "+ 腐败之眼", _add_item.bind(&"corrupt_eye"))
	_add_button(actions, "+ 牛奶滴", _add_counter.bind(&"milk_count"))
	_add_button(actions, "+ 霜晶", _add_counter.bind(&"frost_count"))
	_add_button(actions, "+ 价签", _add_counter.bind(&"barcode_count"))
	_add_button(actions, "+ 噪音", _add_stat.bind(&"noise"))
	_add_button(actions, "+ 破坏", _add_stat.bind(&"destruction"))
	_add_button(actions, "完成测试仪式", _complete_ritual.bind(&"debug_ritual"))
	_add_button(actions, "给予古神配方", _grant_eldritch_recipe)
	_add_button(actions, "给予奶龙配方", _grant_milk_recipe)
	_add_button(actions, "给予真正破晓配方", _grant_true_dawn_recipe)
	_add_button(actions, "给予自治森林配方", _grant_forest_recipe)
	_add_button(actions, "给予无限增长配方", _grant_growth_recipe)
	_add_button(actions, "给予永冬配方", _grant_frost_recipe)
	_add_button(actions, "给予 ROOT 配方", _grant_root_recipe)
	_add_button(actions, "给予紫冠配方", _grant_purple_crown_recipe)
	_add_button(actions, "给予黑暗丰收配方", _grant_dark_harvest_recipe)
	_add_button(actions, "给予拒绝生长配方", _grant_stillness_recipe)
	_add_button(actions, "给予垃圾王配方", _grant_landfill_recipe)
	_add_button(actions, "到 01 盒盖出口", _teleport_location.bind(&"final_lid"))
	_add_button(actions, "到 02 伪太阳", _teleport_location.bind(&"light_switch"))
	_add_button(actions, "到 03 小龙旧像", _teleport_location.bind(&"dragon_shrine"))
	_add_button(actions, "到 04 暖门缝", _teleport_location.bind(&"warm_door_gap"))
	_add_button(actions, "到 05 根网出口", _teleport_location.bind(&"root_network_exit"))
	_add_button(actions, "到 06 条码终端", _teleport_location.bind(&"barcode_terminal"))
	_add_button(actions, "到 07 冷冻凹槽", _teleport_location.bind(&"freezer_alcove"))
	_add_button(actions, "到 08 温控探针", _teleport_location.bind(&"temperature_probe"))
	_add_button(actions, "到 09 紫冠连接", _teleport_location.bind(&"hongsan_link"))
	_add_button(actions, "到 10 母薯黑土", _teleport_location.bind(&"mother_soil"))
	_add_button(actions, "到 11 自我剪芽", _teleport_location.bind(&"self_prune"))
	_add_button(actions, "到 12 清理区域", _teleport_location.bind(&"cleanup_zone"))
	_add_button(actions, "同种子重开", _restart_with_seed.bind(true))
	_add_button(actions, "新种子重开", _restart_with_seed.bind(false))
	_add_button(actions, "重置本局", _reset_run)
	_add_button(actions, "清空结局图鉴", _clear_progress)
	_asset_gallery = ASSET_GALLERY.new()
	_asset_gallery.closed.connect(_close_asset_gallery)
	add_child(_asset_gallery)
	_point_teleporter = POINT_TELEPORTER.new()
	_point_teleporter.closed.connect(_close_point_teleporter)
	_point_teleporter.teleport_requested.connect(_teleport_asset_point)
	add_child(_point_teleporter)


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
		"seed %d · rings %d · sectors %d · attempt %d · fallback %s\n" +
		"ending entrances: 01–12\n" +
		"last failed attempt: %s"
	) % [
		game_state.devour, game_state.nurture, game_state.noise,
		game_state.destruction, game_state.corruption,
		game_state.get_counter(&"milk_count"), game_state.get_counter(&"frost_count"),
		game_state.get_counter(&"barcode_count"), game_state.get_counter(&"compressor_start_count"),
		game_state.get_counter(&"bottle_hit_count"), game_state.get_counter(&"lid_hit_count"),
		str(game_state.items.keys()), str(game_state.flags.keys()), str(game_state.rituals.keys()),
		game_state.run_seed, int(_generation_summary().get("ring_count", 0)), int(_generation_summary().get("sector_count", 0)), int(_generation_summary().get("attempt", 0)), str(_generation_summary().get("used_fallback", false)),
		str(game_state.has_flag(&"ending_attempt_failed"))
	]


func _teleport(index: int) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null:
		var level := get_parent()
		player.global_position = level.get_stage_marker_position(index) if level.has_method("get_stage_marker_position") else STAGE_POSITIONS[index]


func _teleport_exact(target_position: Vector2) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null:
		player.global_position = target_position


func _teleport_location(location_id: StringName) -> void:
	var level := get_parent()
	if level.has_method("get_location"):
		_teleport_exact(level.get_location(location_id))


func _add_item(item_id: StringName) -> void:
	get_node("/root/GameState").collect_item(item_id)


func _add_counter(counter_id: StringName) -> void:
	get_node("/root/GameState").increment_counter(counter_id)


func _add_stat(stat_id: StringName) -> void:
	get_node("/root/GameState").add_stat(stat_id, 1)


func _complete_ritual(ritual_id: StringName) -> void:
	get_node("/root/GameState").complete_ritual(ritual_id)


func _grant_eldritch_recipe() -> void:
	var game_state := get_node("/root/GameState")
	for item_id in [&"corrupt_eye", &"scarlet_ointment", &"frozen_heart"]:
		game_state.collect_item(item_id)
	game_state.complete_ritual(&"bottle_counterclockwise")
	game_state.increment_counter(&"compressor_start_count", maxi(3 - game_state.get_counter(&"compressor_start_count"), 0))
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null:
		player.set_visual_stage(&"eldritch", 3)


func _grant_milk_recipe() -> void:
	var game_state := get_node("/root/GameState")
	for item_id in [&"milk_drop_1", &"milk_drop_2", &"milk_drop_3", &"golden_scale"]:
		game_state.collect_item(item_id)
	game_state.increment_counter(&"milk_count", maxi(3 - game_state.get_counter(&"milk_count"), 0))
	game_state.complete_ritual(&"yellow_cap_loop")
	game_state.add_stat(&"corruption", -game_state.corruption)
	game_state.set_flag(&"touched_black_water", false)
	game_state.set_flag(&"touched_chili_oil", false)
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null:
		player.set_visual_stage(&"milk", 3)


func _grant_true_dawn_recipe() -> void:
	var game_state := get_node("/root/GameState")
	for item_id in [&"clean_water_1", &"clean_water_2", &"door_soil", &"flowerpot_receipt"]:
		game_state.collect_item(item_id)
	game_state.increment_counter(&"clean_water_count", maxi(2 - game_state.get_counter(&"clean_water_count"), 0))
	game_state.set_flag(&"bottle_lever")
	game_state.add_stat(&"devour", -game_state.devour)
	game_state.add_stat(&"corruption", -game_state.corruption)


func _grant_forest_recipe() -> void:
	var game_state := get_node("/root/GameState")
	for index in range(1, 4):
		game_state.collect_item(StringName("clean_water_%d" % index))
	game_state.increment_counter(&"clean_water_count", maxi(3 - game_state.get_counter(&"clean_water_count"), 0))
	for flag_id in [&"companion_onion_watered", &"companion_garlic_watered", &"companion_ginger_watered"]:
		game_state.set_flag(flag_id)
	game_state.complete_ritual(&"root_network_loop")
	game_state.add_stat(&"devour", -game_state.devour)


func _grant_growth_recipe() -> void:
	var game_state := get_node("/root/GameState")
	for index in range(1, 4):
		game_state.collect_item(StringName("sale_tag_%d" % index))
	game_state.increment_counter(&"barcode_count", maxi(3 - game_state.get_counter(&"barcode_count"), 0))
	for index in range(1, 7):
		game_state.collect_item(StringName("nutrient_%d" % index))
	game_state.optional_nutrients_total = 6
	game_state.optional_nutrients_eaten = 6
	game_state.add_stat(&"devour", maxi(6 - game_state.devour, 0))
	game_state.add_stat(&"nurture", -game_state.nurture)
	game_state.set_flag(&"returned_after_final_unlock")


func _grant_frost_recipe() -> void:
	var game_state := get_node("/root/GameState")
	for index in range(1, 5):
		game_state.collect_item(StringName("frost_crystal_%d" % index))
	game_state.collect_item(&"sleeping_stone")
	game_state.increment_counter(&"frost_count", maxi(4 - game_state.get_counter(&"frost_count"), 0))
	game_state.increment_counter(&"thermostat_level", maxi(7 - game_state.get_counter(&"thermostat_level"), 0))
	game_state.set_flag(&"frozen_full_cycle")
	game_state.complete_ritual(&"self_seed_loop")


func _grant_root_recipe() -> void:
	var game_state := get_node("/root/GameState")
	for item_id in [&"aluminum_foil", &"conductive_water", &"magnet_core"]:
		game_state.collect_item(item_id)
	game_state.complete_ritual(&"root_node_sequence")


func _grant_purple_crown_recipe() -> void:
	var game_state := get_node("/root/GameState")
	for item_id in [&"hongsan_label", &"yellow_petals", &"clean_water_1"]:
		game_state.collect_item(item_id)
	game_state.increment_counter(&"clean_water_count", maxi(1 - game_state.get_counter(&"clean_water_count"), 0))
	for flag_id in [&"hongsan_root_helped", &"heard_bell", &"faced_warm_light"]:
		game_state.set_flag(flag_id)
	game_state.set_flag(&"hongsan_root_devoured", false)
	game_state.increment_counter(&"thermostat_level", -game_state.get_counter(&"thermostat_level"))
	game_state.complete_ritual(&"purple_crown_connection")


func _grant_dark_harvest_recipe() -> void:
	var game_state := get_node("/root/GameState")
	for item_id in [&"sprout_nodule_1", &"sprout_nodule_2", &"sprout_nodule_3", &"clean_nutrient"]:
		game_state.collect_item(item_id)
	game_state.increment_counter(&"planted_site_count", maxi(3 - game_state.get_counter(&"planted_site_count"), 0))
	game_state.increment_counter(&"lid_open_count", -game_state.get_counter(&"lid_open_count"))
	game_state.set_flag(&"returned_to_mother")
	game_state.set_flag(&"sustained_downward")


func _grant_stillness_recipe() -> void:
	var game_state := get_node("/root/GameState")
	game_state.set_flag(&"tutorial_complete")
	game_state.set_flag(&"returned_to_start")
	game_state.increment_counter(&"narrator_refusal_count", maxi(3 - game_state.get_counter(&"narrator_refusal_count"), 0))
	game_state.add_stat(&"devour", -game_state.devour)
	game_state.add_stat(&"destruction", -game_state.destruction)
	game_state.optional_nutrients_eaten = 0


func _grant_landfill_recipe() -> void:
	var game_state := get_node("/root/GameState")
	game_state.increment_counter(&"bottle_hit_count", maxi(3 - game_state.get_counter(&"bottle_hit_count"), 0))
	game_state.increment_counter(&"lid_hit_count", maxi(3 - game_state.get_counter(&"lid_hit_count"), 0))
	game_state.increment_counter(&"film_broken_count", maxi(3 - game_state.get_counter(&"film_broken_count"), 0))
	game_state.add_stat(&"noise", maxi(6 - game_state.noise, 0))
	game_state.add_stat(&"destruction", maxi(5 - game_state.destruction, 0))
	game_state.add_stat(&"corruption", maxi(3 - game_state.corruption, 0))
	game_state.add_stat(&"nurture", -game_state.nurture)
	game_state.set_flag(&"black_water_absorbed")


func _generation_summary() -> Dictionary:
	var level := get_parent()
	return level.get_generation_summary() if level.has_method("get_generation_summary") else {}


func _restart_with_seed(same_seed: bool) -> void:
	var main_scene := get_tree().current_scene
	if main_scene != null and main_scene.has_method("_start_new_run"):
		main_scene.call_deferred("_start_new_run", get_node("/root/GameState").run_seed if same_seed else -1)


func _reset_run() -> void:
	var main_scene := get_tree().current_scene
	if main_scene != null and main_scene.has_method("_start_new_run"):
		main_scene.call_deferred("_start_new_run")
	else:
		get_node("/root/GameState").reset_run()


func _clear_progress() -> void:
	get_node("/root/ProgressState").clear_unlocked_endings()


func _open_asset_gallery() -> void:
	_root_panel.visible = false
	_asset_gallery.set_open(true)


func _close_asset_gallery() -> void:
	_asset_gallery.set_open(false)
	_root_panel.visible = true
	_refresh_state()


func _open_point_teleporter() -> void:
	_root_panel.visible = false
	_point_teleporter.configure(get_parent())
	_point_teleporter.set_open(true)


func _close_point_teleporter() -> void:
	_point_teleporter.set_open(false)
	_root_panel.visible = true
	_refresh_state()


func _teleport_asset_point(world_position: Vector2, _point_id: StringName) -> void:
	_teleport_exact(world_position)
	_point_teleporter.set_open(false)
	_root_panel.visible = false


func _preview_feedback(feedback_id: StringName) -> void:
	var overlay := get_tree().get_first_node_in_group(&"guidance_overlay")
	if overlay != null and overlay.has_method("debug_play_feedback"):
		overlay.debug_play_feedback(feedback_id)


func _add_button(parent: Control, label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(136, 28)
	PIXEL_UI.apply_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
