extends CanvasLayer

## Shared item presentation used by both world pickups and the inventory.
## The first version of the game only showed a short toast; this panel keeps
## the pixel-art texture on the left and the myth/real description on the right.

const ITEM_DATA_PATH := "res://data/item_text.csv"
const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")

var _entries: Dictionary = {}
var _root: Control
var _panel: Panel
var _art: TextureRect
var _myth_label: Label
var _real_label: Label
var _description_label: Label
var _effect_label: Label
var _hint_label: Label
var _close_button: Button
var _hide_token := 0
var _pending_items: Array[StringName] = []
var _presentation_waiting := false


func _ready() -> void:
	layer = 86
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"item_detail_popup")
	_load_entries()
	_build_ui()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.item_collected.connect(_on_item_collected)


func _unhandled_input(event: InputEvent) -> void:
	if not is_popup_visible() or not event.is_action_pressed(&"pause"):
		return
	close()
	get_viewport().set_input_as_handled()


func is_popup_visible() -> bool:
	return is_instance_valid(_root) and _root.visible


func show_item(item_id: StringName, hold_open: bool = false) -> void:
	if not is_instance_valid(_root):
		return
	var entry: Dictionary = _entries.get(item_id, {})
	var asset_library := get_node_or_null("/root/AssetLibrary")
	var texture: Texture2D = asset_library.get_item_texture(item_id) if asset_library != null and asset_library.has_method("get_item_texture") else null
	_art.texture = texture
	_art.visible = texture != null
	_myth_label.text = str(entry.get("myth_name", item_id))
	var real_name := str(entry.get("real_name", ""))
	_real_label.text = "现实记录：%s" % real_name if not real_name.is_empty() else ""
	_real_label.visible = not real_name.is_empty()
	_description_label.text = str(entry.get("description", "尚无说明。"))
	var effects := get_node_or_null("/root/ItemEffectDirector")
	var effect_text := str(effects.get_item_effect_text(item_id)) if effects != null and effects.has_method("get_item_effect_text") else ""
	_effect_label.text = effect_text
	_effect_label.visible = not effect_text.is_empty()
	_hint_label.text = "点击关闭 · I / Tab 查看完整背包" if hold_open else "已收入背包 · I / Tab 查看完整背包"
	_close_button.visible = hold_open
	_root.visible = true
	_root.modulate.a = 1.0
	_hide_token += 1
	var current_token := _hide_token
	if not hold_open:
		await get_tree().create_timer(4.8).timeout
		if current_token == _hide_token and is_inside_tree():
			close()


func close() -> void:
	_hide_token += 1
	if is_instance_valid(_root):
		_root.visible = false
	_try_show_pending_item()


func _on_item_collected(item_id: StringName) -> void:
	_pending_items.append(item_id)
	_try_show_pending_item()


func _try_show_pending_item() -> void:
	if _pending_items.is_empty() or is_popup_visible():
		return
	if _presentation_is_busy():
		_schedule_presentation_retry()
		return
	var item_id: StringName = _pending_items.pop_front() as StringName
	show_item(item_id, false)


func _presentation_is_busy() -> bool:
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null and narrative.has_method("queued_count") and int(narrative.queued_count()) > 0:
		return true
	var guidance: Node = get_tree().get_first_node_in_group(&"guidance_overlay")
	return guidance != null and guidance.has_method("is_active") and guidance.is_active()


func _schedule_presentation_retry() -> void:
	if _presentation_waiting:
		return
	_presentation_waiting = true
	var timer := get_tree().create_timer(0.08, true)
	timer.timeout.connect(func() -> void:
		_presentation_waiting = false
		_try_show_pending_item()
	, CONNECT_ONE_SHOT)


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "ItemDetailRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	_panel = Panel.new()
	_panel.position = Vector2(210, 215)
	_panel.size = Vector2(860, 270)
	PIXEL_UI.apply_panel(_panel, Color(0.012, 0.020, 0.046, 0.97), Color(0.72, 0.46, 0.92), 5)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel)
	_art = TextureRect.new()
	_art.position = Vector2(238, 246)
	_art.size = Vector2(190, 190)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_art)
	_myth_label = Label.new()
	_myth_label.position = Vector2(460, 245)
	_myth_label.size = Vector2(540, 38)
	_myth_label.add_theme_font_size_override("font_size", 27)
	PIXEL_UI.apply_title(_myth_label, Color(0.90, 0.72, 1.0))
	_root.add_child(_myth_label)
	_real_label = Label.new()
	_real_label.position = Vector2(460, 286)
	_real_label.size = Vector2(540, 28)
	_real_label.add_theme_font_size_override("font_size", 17)
	_real_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.86))
	_root.add_child(_real_label)
	_description_label = Label.new()
	_description_label.position = Vector2(460, 326)
	_description_label.size = Vector2(540, 66)
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override("font_size", 19)
	_description_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	_root.add_child(_description_label)
	_effect_label = Label.new()
	_effect_label.position = Vector2(460, 398)
	_effect_label.size = Vector2(540, 32)
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect_label.add_theme_font_size_override("font_size", 16)
	_effect_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.35))
	_root.add_child(_effect_label)
	_hint_label = Label.new()
	_hint_label.position = Vector2(238, 454)
	_hint_label.size = Vector2(690, 24)
	_hint_label.add_theme_font_size_override("font_size", 15)
	_hint_label.add_theme_color_override("font_color", Color(0.54, 0.64, 0.78))
	_root.add_child(_hint_label)
	_close_button = Button.new()
	_close_button.position = Vector2(984, 238)
	_close_button.size = Vector2(58, 40)
	_close_button.text = "×"
	_close_button.add_theme_font_size_override("font_size", 24)
	PIXEL_UI.apply_button(_close_button, Color(0.72, 0.46, 0.92))
	_close_button.pressed.connect(close)
	_root.add_child(_close_button)


func _load_entries() -> void:
	var file := FileAccess.open(ITEM_DATA_PATH, FileAccess.READ)
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
