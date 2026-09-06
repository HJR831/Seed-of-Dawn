extends CanvasLayer

const MAP_CANVAS_SCRIPT := preload("res://scenes/ui/map_canvas.gd")
const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")

var _plan: Dictionary = {}
var _player: Node2D
var _minimap: Control
var _full_root: Control
var _full_map: Control
var _was_paused := false


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_minimap()
	_build_full_map()


func configure(plan: Dictionary, player: Node2D) -> void:
	_plan = plan
	_player = player
	_minimap.configure(plan, player, false)
	_full_map.configure(plan, player, true)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"world_map"):
		set_full_open(not is_full_open())
		get_viewport().set_input_as_handled()
	elif is_full_open() and event.is_action_pressed(&"pause"):
		set_full_open(false)
		get_viewport().set_input_as_handled()


func is_full_open() -> bool:
	return is_instance_valid(_full_root) and _full_root.visible


func set_full_open(opened: bool) -> void:
	if not is_instance_valid(_full_root) or _full_root.visible == opened:
		return
	if opened:
		var inventory := get_parent().get_node_or_null("InventoryPanel")
		if inventory != null and inventory.has_method("set_open"):
			inventory.set_open(false)
		_was_paused = get_tree().paused
		_full_root.visible = true
		_minimap.visible = false
		get_tree().paused = true
	else:
		_full_root.visible = false
		_minimap.visible = true
		get_tree().paused = _was_paused


func _build_minimap() -> void:
	var frame := Panel.new()
	frame.position = Vector2(22, 18)
	frame.size = Vector2(246, 246)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PIXEL_UI.apply_panel(frame, Color(0.015, 0.022, 0.052, 0.94), Color(0.28, 0.38, 0.54), 3)
	add_child(frame)
	_minimap = MAP_CANVAS_SCRIPT.new()
	_minimap.name = "MiniMapCanvas"
	_minimap.position = Vector2(26, 22)
	_minimap.size = Vector2(238, 238)
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_minimap)


func _build_full_map() -> void:
	_full_root = Control.new()
	_full_root.name = "WorldMapRoot"
	_full_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_full_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_full_root.visible = false
	add_child(_full_root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.008, 0.012, 0.028, 0.96)
	_full_root.add_child(shade)
	var map_frame := Panel.new()
	map_frame.position = Vector2(254, 49)
	map_frame.size = Vector2(772, 622)
	map_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PIXEL_UI.apply_panel(map_frame, Color(0.014, 0.024, 0.045, 0.98), Color(0.32, 0.43, 0.60), 5)
	_full_root.add_child(map_frame)
	_full_map = MAP_CANVAS_SCRIPT.new()
	_full_map.name = "WorldMapCanvas"
	_full_map.position = Vector2(260, 55)
	_full_map.size = Vector2(760, 610)
	_full_root.add_child(_full_map)
	var title := Label.new()
	title.position = Vector2(24, 24)
	title.size = Vector2(300, 54)
	title.text = "冰箱自底向上地图"
	title.add_theme_font_size_override("font_size", 30)
	PIXEL_UI.apply_title(title)
	_full_root.add_child(title)
	var legend := Label.new()
	legend.position = Vector2(26, 105)
	legend.size = Vector2(230, 400)
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.add_theme_font_size_override("font_size", 17)
	legend.text = "图例\n\n● 玩家\n◆ 准确位置\n○ 大致区域\n△ 方向\n● 已发现地标\n\n黑暗区域尚未探索。\n地图只记录你已经获得的知识。"
	_full_root.add_child(legend)
	var footer := Label.new()
	footer.position = Vector2(1000, 650)
	footer.size = Vector2(250, 32)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.text = "M / Esc 关闭"
	footer.add_theme_font_size_override("font_size", 17)
	_full_root.add_child(footer)
