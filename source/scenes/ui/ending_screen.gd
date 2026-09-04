extends CanvasLayer

signal restart_requested


func _ready() -> void:
	_build_screen()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart_run"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()


func _build_screen() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.91, 0.93, 0.96)
	add_child(backdrop)

	var cold_light := ColorRect.new()
	cold_light.position = Vector2(210, 70)
	cold_light.size = Vector2(860, 560)
	cold_light.color = Color(0.98, 0.99, 1.0, 0.82)
	add_child(cold_light)

	var potato := Polygon2D.new()
	potato.position = Vector2(640, 405)
	potato.polygon = PackedVector2Array([
		Vector2(-145, -85), Vector2(-70, -135), Vector2(55, -128),
		Vector2(145, -55), Vector2(128, 55), Vector2(35, 105),
		Vector2(-95, 92), Vector2(-155, 20)
	])
	potato.color = Color(0.43, 0.25, 0.13)
	add_child(potato)

	for offset in [Vector2(-75, -35), Vector2(10, -72), Vector2(76, -10), Vector2(-20, 38)]:
		var eye := Polygon2D.new()
		eye.position = potato.position + offset
		eye.polygon = PackedVector2Array([
			Vector2(-7, 0), Vector2(0, -5), Vector2(7, 0), Vector2(0, 5)
		])
		eye.color = Color(0.18, 0.10, 0.06)
		add_child(eye)

	var sprout_line := Line2D.new()
	sprout_line.width = 25.0
	sprout_line.default_color = Color(0.31, 0.05, 0.49)
	sprout_line.joint_mode = Line2D.LINE_JOINT_ROUND
	sprout_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	sprout_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	sprout_line.points = PackedVector2Array([
		Vector2(660, 330), Vector2(690, 250), Vector2(655, 175), Vector2(720, 105)
	])
	add_child(sprout_line)

	var title := Label.new()
	title.position = Vector2(150, 54)
	title.size = Vector2(980, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.10, 0.08, 0.13))
	title.text = "结局 01：生长成功，食用失败"
	add_child(title)

	var dialogue := Label.new()
	dialogue.position = Vector2(160, 520)
	dialogue.size = Vector2(960, 92)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue.add_theme_font_size_override("font_size", 26)
	dialogue.add_theme_color_override("font_color", Color(0.14, 0.11, 0.16))
	dialogue.text = "“……我什么时候买的这个土豆？”\n成长完成度：100%    可食用度：0%"
	add_child(dialogue)

	var restart_button := Button.new()
	restart_button.position = Vector2(490, 632)
	restart_button.size = Vector2(300, 58)
	restart_button.text = "再次发芽（R）"
	restart_button.add_theme_font_size_override("font_size", 23)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	add_child(restart_button)
	restart_button.grab_focus()
