extends CanvasLayer

signal restart_requested

const ENDING_DATA_PATH := "res://data/ending_text.csv"
const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")

var _entries: Dictionary = {}


func _ready() -> void:
	_load_entries()
	var game_state := get_node_or_null("/root/GameState")
	var ending_id: StringName = game_state.current_ending if game_state != null else &"ending_01_food_failure"
	_build_screen(ending_id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart_run"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()


func _build_screen(ending_id: StringName) -> void:
	var entry: Dictionary = _entries.get(ending_id, _fallback_entry())
	var category := str(entry.get("category", "default"))
	var palette := _palette_for(category)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = palette[0]
	add_child(backdrop)
	var art_texture: Texture2D = null
	var asset_library := get_node_or_null("/root/AssetLibrary")
	if asset_library != null and asset_library.has_method("get_ending_texture"):
		art_texture = asset_library.get_ending_texture(ending_id)
	if art_texture != null:
		var art := TextureRect.new()
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.texture = art_texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate = Color(1.0, 1.0, 1.0, 0.92)
		add_child(art)
	else:
		_build_placeholder_card(ending_id, palette)
	var frame := Panel.new()
	frame.position = Vector2(70, 430)
	frame.size = Vector2(1140, 210)
	PIXEL_UI.apply_panel(frame, Color(palette[1], 0.88), Color(palette[2], 0.72), 5)
	add_child(frame)
	if art_texture == null:
		_build_ending_visual(category, palette)

	var title := Label.new()
	title.position = Vector2(130, 42)
	title.size = Vector2(1020, 62)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", palette[2])
	title.text = "结局 %s：%s" % [entry.get("index", "01"), entry.get("title", "生长成功，食用失败")]
	add_child(title)

	var dialogue := Label.new()
	dialogue.position = Vector2(175, 472)
	dialogue.size = Vector2(930, 126)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.add_theme_font_size_override("font_size", 24)
	dialogue.add_theme_color_override("font_color", palette[2])
	dialogue.text = _compose_text(entry)
	add_child(dialogue)

	var progress_state := get_node_or_null("/root/ProgressState")
	var gallery := Label.new()
	gallery.position = Vector2(40, 678)
	gallery.size = Vector2(320, 26)
	gallery.add_theme_font_size_override("font_size", 16)
	gallery.add_theme_color_override("font_color", palette[2])
	gallery.text = "结局图鉴  %d / 12" % (progress_state.unlocked_count() if progress_state != null else 1)
	add_child(gallery)

	var restart_button := Button.new()
	restart_button.position = Vector2(490, 625)
	restart_button.size = Vector2(300, 58)
	restart_button.text = "再次发芽（R）"
	restart_button.add_theme_font_size_override("font_size", 23)
	PIXEL_UI.apply_button(restart_button, palette[2])
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	add_child(restart_button)
	restart_button.grab_focus()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_ending_music"):
		audio.play_ending_music(category)
	_maybe_play_landfill_epilogue(ending_id)


func _build_placeholder_card(ending_id: StringName, palette: Array[Color]) -> void:
	var placeholder := Label.new()
	placeholder.position = Vector2(270, 205)
	placeholder.size = Vector2(740, 180)
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder.add_theme_font_size_override("font_size", 28)
	placeholder.add_theme_color_override("font_color", Color(palette[2], 0.88))
	var parts := str(ending_id).split("_")
	var index := parts[1] if parts.size() > 1 else "??"
	placeholder.text = "占位结局插画\nending_%s_full.png\n（待补充正式结局素材）" % index
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(placeholder)


func _maybe_play_landfill_epilogue(ending_id: StringName) -> void:
	if not should_play_landfill_epilogue(ending_id):
		return
	await get_tree().create_timer(8.0).timeout
	if not is_inside_tree():
		return
	var continuation := ColorRect.new()
	continuation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	continuation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continuation.color = Color(0.018, 0.025, 0.012, 0.97)
	continuation.modulate.a = 0.0
	add_child(continuation)
	var text := Label.new()
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 29)
	text.add_theme_color_override("font_color", Color(0.68, 0.82, 0.34))
	text.text = "垃圾车驶过雨夜。\n填埋场的黑暗里，无数紫色芽眼依次睁开。\n\n过去，深渊为你提供温床。\n现在，整个世界都是温床。"
	continuation.add_child(text)
	create_tween().tween_property(continuation, "modulate:a", 1.0, 0.8)


func should_play_landfill_epilogue(ending_id: StringName) -> bool:
	var game_state := get_node_or_null("/root/GameState")
	return ending_id == &"ending_12_landfill_king" and game_state != null and game_state.has_flag(&"read_compost_label")


func _build_ending_visual(category: String, palette: Array[Color]) -> void:
	match category:
		"eldritch":
			var eye := Polygon2D.new()
			eye.position = Vector2(640, 285)
			eye.polygon = PackedVector2Array([Vector2(-230, 0), Vector2(-100, -100), Vector2(100, -100), Vector2(230, 0), Vector2(100, 100), Vector2(-100, 100)])
			eye.color = palette[2]
			add_child(eye)
			var pupil := Polygon2D.new()
			pupil.position = eye.position
			pupil.polygon = PackedVector2Array([Vector2(0, -82), Vector2(46, 0), Vector2(0, 82), Vector2(-46, 0)])
			pupil.color = palette[0]
			add_child(pupil)
		"comedy":
			var dragon := Polygon2D.new()
			dragon.position = Vector2(640, 300)
			dragon.polygon = PackedVector2Array([Vector2(-135, 70), Vector2(-115, -65), Vector2(-55, -120), Vector2(0, -75), Vector2(65, -125), Vector2(125, -55), Vector2(145, 70), Vector2(0, 120)])
			dragon.color = palette[2]
			add_child(dragon)
			for x in [-48.0, 48.0]:
				var eye := Polygon2D.new()
				eye.position = dragon.position + Vector2(x, -12)
				eye.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -9), Vector2(8, 0), Vector2(0, 9)])
				eye.color = palette[0]
				add_child(eye)
		"warm":
			var sun := Polygon2D.new()
			sun.position = Vector2(640, 280)
			sun.polygon = PackedVector2Array([Vector2(0, -120), Vector2(105, -55), Vector2(125, 65), Vector2(0, 128), Vector2(-120, 65), Vector2(-105, -55)])
			sun.color = palette[2]
			add_child(sun)
		"symbiosis":
			for offset in [Vector2(-180, 40), Vector2(-60, -40), Vector2(70, 20), Vector2(185, -45)]:
				var leaf := Polygon2D.new()
				leaf.position = Vector2(640, 290) + offset
				leaf.polygon = PackedVector2Array([Vector2(0, -70), Vector2(48, 0), Vector2(0, 72), Vector2(-48, 0)])
				leaf.color = palette[2]
				add_child(leaf)
		"corporate":
			for index in range(4):
				var bar := ColorRect.new()
				bar.position = Vector2(420 + index * 115, 390 - index * 65)
				bar.size = Vector2(72, 70 + index * 65)
				bar.color = palette[2]
				add_child(bar)
		"frost":
			var crystal := Polygon2D.new()
			crystal.position = Vector2(640, 290)
			crystal.polygon = PackedVector2Array([Vector2(0, -150), Vector2(92, -40), Vector2(58, 120), Vector2(0, 160), Vector2(-58, 120), Vector2(-92, -40)])
			crystal.color = palette[2]
			add_child(crystal)
		"root":
			for index in range(5):
				var node := Polygon2D.new()
				node.position = Vector2(420 + index * 110, 290 + sin(index) * 90)
				node.polygon = PackedVector2Array([Vector2(0, -28), Vector2(28, 0), Vector2(0, 28), Vector2(-28, 0)])
				node.color = palette[2]
				add_child(node)
				if index > 0:
					var wire := Line2D.new()
					wire.width = 8.0
					wire.default_color = palette[2]
					wire.add_point(Vector2(420 + (index - 1) * 110, 290 + sin(index - 1) * 90))
					wire.add_point(node.position)
					add_child(wire)
		"crown":
			for index in range(5):
				var petal := Polygon2D.new()
				petal.position = Vector2(640, 300) + Vector2.RIGHT.rotated(TAU * index / 5.0) * 105.0
				petal.rotation = TAU * index / 5.0 + PI * 0.5
				petal.polygon = PackedVector2Array([Vector2(0, -58), Vector2(35, 10), Vector2(0, 58), Vector2(-35, 10)])
				petal.color = palette[2]
				add_child(petal)
		"harvest":
			for index in range(3):
				var root := Line2D.new()
				root.width = 14.0
				root.default_color = palette[2]
				root.add_point(Vector2(500 + index * 140, 190))
				root.add_point(Vector2(470 + index * 170, 410))
				add_child(root)
		"stillness":
			var seed := Polygon2D.new()
			seed.position = Vector2(640, 300)
			seed.polygon = PackedVector2Array([Vector2(0, -95), Vector2(70, -20), Vector2(45, 80), Vector2(0, 112), Vector2(-45, 80), Vector2(-70, -20)])
			seed.color = palette[2]
			add_child(seed)
		"landfill":
			for index in range(7):
				var block := ColorRect.new()
				block.position = Vector2(430 + index * 65, 350 - (index % 3) * 58)
				block.size = Vector2(88, 70)
				block.rotation = (-0.16 + index * 0.05)
				block.color = palette[2].darkened(float(index) * 0.045)
				add_child(block)
		_:
			var potato := Polygon2D.new()
			potato.position = Vector2(640, 300)
			potato.polygon = PackedVector2Array([Vector2(-150, -70), Vector2(-75, -130), Vector2(70, -120), Vector2(155, -40), Vector2(130, 80), Vector2(10, 120), Vector2(-130, 75)])
			potato.color = Color(0.43, 0.25, 0.13)
			add_child(potato)


func _compose_text(entry: Dictionary) -> String:
	var lines: Array[String] = []
	for key in ["line_1", "line_2", "line_3", "subtitle"]:
		var value := str(entry.get(key, "")).strip_edges()
		if not value.is_empty():
			lines.append(value)
	return "\n".join(lines)


func _palette_for(category: String) -> Array[Color]:
	match category:
		"eldritch": return [Color(0.025, 0.008, 0.05), Color(0.12, 0.025, 0.18), Color(0.82, 0.42, 1.0)]
		"comedy": return [Color(0.98, 0.86, 0.40), Color(1.0, 0.94, 0.68), Color(0.35, 0.20, 0.08)]
		"warm": return [Color(0.20, 0.09, 0.04), Color(0.42, 0.20, 0.08), Color(1.0, 0.74, 0.34)]
		"symbiosis": return [Color(0.02, 0.12, 0.07), Color(0.05, 0.25, 0.13), Color(0.48, 0.94, 0.52)]
		"corporate": return [Color(0.07, 0.08, 0.11), Color(0.16, 0.18, 0.23), Color(1.0, 0.30, 0.22)]
		"frost": return [Color(0.025, 0.10, 0.18), Color(0.10, 0.28, 0.42), Color(0.70, 0.93, 1.0)]
		"root": return [Color(0.015, 0.025, 0.02), Color(0.04, 0.10, 0.07), Color(0.94, 0.76, 0.24)]
		"crown": return [Color(0.09, 0.025, 0.12), Color(0.24, 0.06, 0.28), Color(0.86, 0.52, 0.94)]
		"harvest": return [Color(0.035, 0.025, 0.015), Color(0.13, 0.085, 0.035), Color(0.72, 0.48, 0.20)]
		"stillness": return [Color(0.035, 0.045, 0.055), Color(0.11, 0.13, 0.15), Color(0.76, 0.82, 0.84)]
		"landfill": return [Color(0.07, 0.075, 0.035), Color(0.18, 0.20, 0.08), Color(0.70, 0.78, 0.27)]
		_: return [Color(0.91, 0.93, 0.96), Color(0.98, 0.99, 1.0), Color(0.10, 0.08, 0.13)]


func _load_entries() -> void:
	var file := FileAccess.open(ENDING_DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var headers := file.get_csv_line()
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.is_empty() or values[0].strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index in range(mini(headers.size(), values.size())):
			row[headers[index].strip_edges()] = values[index]
		_entries[StringName(values[0])] = row


func _fallback_entry() -> Dictionary:
	return {"index": "01", "title": "生长成功，食用失败", "category": "default", "line_1": "……我什么时候买的这个土豆？", "subtitle": "成长完成度：100%    可食用度：0%"}
