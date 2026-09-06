class_name AssetDebugGallery
extends Control

signal closed

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")
const SECTIONS := [
	{"title": "冰箱垂直模块（六张必须全部显示）", "files": [
		"env_fridge_backplate_tile_01.png", "env_fridge_backplate_tile_02.png", "env_fridge_backplate_tile_03.png",
		"env_fridge_backplate_tile_04.png", "env_fridge_backplate_tile_05.png", "env_fridge_backplate_tile_06.png",
	]},
	{"title": "玩家与核心环境", "files": [
		"sprout_head_neutral.png", "sprout_trail_neutral.png", "env_mother_potato.png", "env_hot_sauce_bottle.png",
		"env_yellow_milk_cap_front.png", "env_plastic_film_intact.png", "env_final_lid_intact.png", "env_ritual_marks_counterclockwise.png",
		"env_slime_pool_01.png", "env_frost_sheet_01.png", "env_thermostat_circuit.png", "env_takeout_box.png",
	]},
	{"title": "关键道具与同伴", "files": [
		"item_eye_of_decay_glow.png", "item_scarlet_ointment_still.png", "item_heart_of_eternal_frost.png",
		"item_milk_drop_01.png", "item_golden_cheese_rind.png", "item_frost_crystal_01.png", "item_sleeping_stone_glow.png",
		"item_aluminum_foil_01.png", "item_conductive_condensation.png", "item_magnet_core_intact.png",
		"npc_onion_sprout.png", "npc_garlic_sprout.png", "npc_ginger_sprout.png", "npc_caitai_root_reived.png",
	]},
	{"title": "十二结局完整插画", "files": [
		"ending_01_full.png", "ending_02_full.png", "ending_03_full.png", "ending_04_full.png",
		"ending_05_full.png", "ending_06_full.png", "ending_07_full.png", "ending_08_full.png",
		"ending_09_full.png", "ending_10_full.png", "ending_11_full.png", "ending_12_full.png",
	]},
]

var _summary: Label
var _grid: GridContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 20
	_build_ui()
	visible = false


func set_open(opened: bool) -> void:
	visible = opened
	if opened:
		_refresh()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.004, 0.008, 0.020, 0.97)
	add_child(shade)
	var outer := Panel.new()
	outer.position = Vector2(18, 16)
	outer.size = Vector2(1244, 688)
	PIXEL_UI.apply_panel(outer, Color(0.015, 0.024, 0.047, 0.99), Color(0.32, 0.46, 0.65), 5)
	add_child(outer)
	var title := Label.new()
	title.position = Vector2(38, 28)
	title.size = Vector2(530, 38)
	title.text = "测试素材检查 · 运行时实际加载结果"
	title.add_theme_font_size_override("font_size", 24)
	PIXEL_UI.apply_title(title)
	add_child(title)
	_summary = Label.new()
	_summary.position = Vector2(570, 32)
	_summary.size = Vector2(510, 28)
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_summary.add_theme_font_size_override("font_size", 15)
	add_child(_summary)
	var close_button := Button.new()
	close_button.position = Vector2(1090, 26)
	close_button.size = Vector2(140, 38)
	close_button.text = "返回调试"
	PIXEL_UI.apply_button(close_button)
	close_button.pressed.connect(func() -> void: closed.emit())
	add_child(close_button)
	var program_note := Label.new()
	program_note.position = Vector2(40, 70)
	program_note.size = Vector2(1180, 48)
	program_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	program_note.text = "[PG] UI、粒子、状态覆盖层均为程序像素绘制，不读取 ui_ / vfx_ 图片。下方只检查仍参与游戏的角色、场景、道具与结局插画。"
	program_note.add_theme_color_override("font_color", Color(0.62, 0.86, 0.74))
	program_note.add_theme_font_size_override("font_size", 15)
	add_child(program_note)
	var feedback_row := HBoxContainer.new()
	feedback_row.position = Vector2(40, 116)
	feedback_row.size = Vector2(1180, 34)
	feedback_row.add_theme_constant_override("separation", 8)
	add_child(feedback_row)
	for entry in [["古神", &"eldritch_eye"], ["霜冻", &"eldritch_frost"], ["金光", &"golden_flash"], ["暖风", &"warm_wind"], ["ROOT", &"root_glitch"], ["花瓣", &"petal"], ["垃圾噪点", &"landfill_noise"]]:
		var button := Button.new()
		button.text = "VFX %s" % entry[0]
		button.custom_minimum_size = Vector2(132, 32)
		PIXEL_UI.apply_button(button)
		button.pressed.connect(_preview_feedback.bind(entry[1]))
		feedback_row.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(34, 158)
	scroll.size = Vector2(1212, 526)
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.custom_minimum_size = Vector2(1170, 0)
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)


func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var present := 0
	var total := 0
	for section in SECTIONS:
		var heading := Label.new()
		heading.text = str(section.title)
		heading.custom_minimum_size = Vector2(1170, 30)
		heading.add_theme_font_size_override("font_size", 18)
		PIXEL_UI.apply_title(heading, Color(0.72, 0.82, 1.0))
		_grid.add_child(heading)
		# Fill the remaining five grid columns so the next card starts a fresh row.
		for _index in range(5):
			_grid.add_child(Control.new())
		for raw_name in section.files:
			total += 1
			if _add_asset_card(str(raw_name)):
				present += 1
	_summary.text = "关键图片：%d / %d 已加载 · 缺失项显示 MISSING" % [present, total]


func _add_asset_card(file_name: String) -> bool:
	var library := get_node_or_null("/root/AssetLibrary")
	var texture: Texture2D = library.get_texture(StringName(file_name)) if library != null else null
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(187, 142)
	PIXEL_UI.apply_panel(card, Color(0.025, 0.038, 0.064, 0.98), Color(0.20, 0.30, 0.43), 2)
	_grid.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	card.add_child(content)
	if texture != null:
		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(170, 96)
		preview.texture = texture
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		content.add_child(preview)
	else:
		var missing := Label.new()
		missing.custom_minimum_size = Vector2(170, 96)
		missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		missing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		missing.text = "MISSING"
		missing.add_theme_font_size_override("font_size", 19)
		missing.add_theme_color_override("font_color", Color(1.0, 0.30, 0.32))
		content.add_child(missing)
	var name_label := Label.new()
	name_label.text = file_name
	name_label.tooltip_text = file_name
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.74, 0.81, 0.92))
	content.add_child(name_label)
	return texture != null


func _preview_feedback(feedback_id: StringName) -> void:
	var overlay := get_tree().get_first_node_in_group(&"guidance_overlay")
	if overlay != null and overlay.has_method("debug_play_feedback"):
		overlay.debug_play_feedback(feedback_id)
