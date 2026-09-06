extends CanvasLayer

signal completed(return_to_menu: bool)

const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")

const STEPS := [
	{"title": "第一步 · 让芽尖醒来", "body": "使用 W / A / S / D 或方向键移动。\n按 U 可以随时打开或关闭完整键位提示。\n你出生在冰箱最深处，地图会从底部一路向上展开。", "accent": Color(0.86, 0.50, 0.30)},
	{"title": "第二步 · 穿过生态层", "body": "按住 Shift 疾跑。\n疾跑会消耗芽体耐力，松开后会自动恢复；不同层级会留下不同颜色的像素轨迹。", "accent": Color(0.56, 0.76, 0.38)},
	{"title": "第三步 · 触碰与选择", "body": "靠近发光物品会自动拾取。\n对场景中的同伴、机关和出口按 E：短按与长按可能代表不同选择。", "accent": Color(0.60, 0.76, 0.96)},
	{"title": "第四步 · 蓄力与突破", "body": "在带有 [空格] 提示的薄膜、盒盖或结界前长按空格。\n蓄力条完成后，新的道路或结局入口会打开。", "accent": Color(0.76, 0.58, 1.0)},
	{"title": "第五步 · 记住你拿过什么", "body": "按 I 或 Tab 打开背包，点击任意道具查看图片、描述和效果。\n按 M 查看已探索的小地图。", "accent": Color(0.94, 0.72, 0.30)},
	{"title": "最后 · 向上生长", "body": "没有唯一的正确道路。\n收集遗物、帮助或吞噬同伴、完成仪式，再决定你要怎样迎接冰箱外的世界。", "accent": Color(0.88, 0.52, 0.94)},
]

var _root: Control
var _title: Label
var _body: Label
var _counter: Label
var _previous: Button
var _next: Button
var _skip: Button
var _step := 0
var _return_to_menu := false


func _ready() -> void:
	layer = 130
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false


func open(return_to_menu: bool = false) -> void:
	_return_to_menu = return_to_menu
	_step = 0
	_root.visible = true
	get_tree().paused = true
	_refresh()
	_next.grab_focus()


func close() -> void:
	_root.visible = false
	get_tree().paused = false
	var progress := get_node_or_null("/root/ProgressState")
	if progress != null and progress.has_method("mark_tutorial_seen"):
		progress.mark_tutorial_seen()
	completed.emit(_return_to_menu)


func is_open() -> bool:
	return is_instance_valid(_root) and _root.visible


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"skip_text"):
		if _step < STEPS.size() - 1:
			_step += 1
			_refresh()
		else:
			close()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	var step: Dictionary = STEPS[_step]
	_title.text = str(step["title"])
	_title.add_theme_color_override("font_color", step["accent"])
	_body.text = str(step["body"])
	_counter.text = "教程 %d / %d" % [_step + 1, STEPS.size()]
	_previous.disabled = _step == 0
	_next.text = "完成" if _step == STEPS.size() - 1 else "下一步"


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.006, 0.010, 0.028, 0.92)
	_root.add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(190, 104)
	panel.size = Vector2(900, 500)
	PIXEL_UI.apply_panel(panel, Color(0.015, 0.025, 0.058, 0.98), Color(0.50, 0.34, 0.76), 6)
	_root.add_child(panel)
	var eyebrow := Label.new()
	eyebrow.position = Vector2(240, 145)
	eyebrow.size = Vector2(800, 28)
	eyebrow.text = "生长者手册 · 快速入门"
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", Color(0.56, 0.68, 0.88))
	_root.add_child(eyebrow)
	_title = Label.new()
	_title.position = Vector2(240, 188)
	_title.size = Vector2(800, 50)
	_title.add_theme_font_size_override("font_size", 30)
	PIXEL_UI.apply_title(_title)
	_root.add_child(_title)
	_body = Label.new()
	_body.position = Vector2(250, 270)
	_body.size = Vector2(780, 150)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body.add_theme_font_size_override("font_size", 22)
	_body.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	_root.add_child(_body)
	_counter = Label.new()
	_counter.position = Vector2(250, 448)
	_counter.size = Vector2(180, 25)
	_counter.add_theme_font_size_override("font_size", 15)
	_counter.add_theme_color_override("font_color", Color(0.56, 0.66, 0.82))
	_root.add_child(_counter)
	_previous = Button.new()
	_previous.position = Vector2(550, 500)
	_previous.size = Vector2(150, 52)
	_previous.text = "上一步"
	_previous.add_theme_font_size_override("font_size", 18)
	PIXEL_UI.apply_button(_previous, Color(0.40, 0.56, 0.78))
	_previous.pressed.connect(func() -> void:
		_step = maxi(_step - 1, 0)
		_refresh()
	)
	_root.add_child(_previous)
	_next = Button.new()
	_next.position = Vector2(720, 500)
	_next.size = Vector2(180, 52)
	_next.text = "下一步"
	_next.add_theme_font_size_override("font_size", 18)
	PIXEL_UI.apply_button(_next, Color(0.68, 0.40, 0.92))
	_next.pressed.connect(func() -> void:
		if _step >= STEPS.size() - 1:
			close()
		else:
			_step += 1
			_refresh()
	)
	_root.add_child(_next)
	_skip = Button.new()
	_skip.position = Vector2(242, 500)
	_skip.size = Vector2(220, 52)
	_skip.text = "跳过教程"
	_skip.add_theme_font_size_override("font_size", 16)
	PIXEL_UI.apply_button(_skip, Color(0.42, 0.46, 0.60))
	_skip.pressed.connect(close)
	_root.add_child(_skip)
