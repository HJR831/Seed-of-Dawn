extends Node2D

signal ending_requested(ending_id: StringName)

const WORLD_WIDTH := 1280.0
const WORLD_HEIGHT := 3300.0
const INNER_LEFT := 92.0
const INNER_RIGHT := 1188.0
const SPAWN_POSITION := Vector2(310.0, 3040.0)
const DEFAULT_ENDING_ID: StringName = &"ending_01_food_failure"

const SPROUT_SCENE := preload("res://scenes/player/sprout.tscn")
const BARRIER_SCENE := preload("res://scenes/gameplay/charge_barrier.tscn")
const STICKY_AREA_SCENE := preload("res://scenes/gameplay/sticky_area.tscn")
const FROST_AREA_SCENE := preload("res://scenes/gameplay/frost_area.tscn")
const PICKUP_SCENE := preload("res://scenes/gameplay/pickup.tscn")
const INTERACTABLE_SCENE := preload("res://scenes/gameplay/interactable.tscn")
const NARRATIVE_TRIGGER_SCENE := preload("res://scenes/gameplay/narrative_trigger.tscn")
const DIALOGUE_BOX_SCENE := preload("res://scenes/ui/dialogue_box.tscn")
const DEBUG_PANEL_SCENE := preload("res://scenes/ui/debug_panel.tscn")

var player: CharacterBody2D
var progress_label: Label
var stage_label: Label
var ending_started: bool = false


func _ready() -> void:
	_build_darkness()
	_build_world_collision()
	_build_world_labels()
	_spawn_player()
	_build_charge_barriers()
	_build_material_feedback()
	_build_interactions()
	_build_hud()
	_build_narrative()
	queue_redraw()


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var progress := clampf((SPAWN_POSITION.y - player.global_position.y) / (SPAWN_POSITION.y - 210.0), 0.0, 1.0)
	progress_label.text = "向破晓生长  %d%%" % roundi(progress * 100.0)
	stage_label.text = _stage_name_for_height(player.global_position.y)


func _draw() -> void:
	# 冰箱内壁与四个灰盒色区。正式美术到位后可直接替换。
	draw_rect(Rect2(0, 0, WORLD_WIDTH, WORLD_HEIGHT), Color(0.012, 0.018, 0.04))
	draw_rect(Rect2(INNER_LEFT, 0, INNER_RIGHT - INNER_LEFT, WORLD_HEIGHT), Color(0.075, 0.09, 0.13))
	draw_rect(Rect2(INNER_LEFT, 2450, INNER_RIGHT - INNER_LEFT, 850), Color(0.16, 0.12, 0.11, 0.88))
	draw_rect(Rect2(INNER_LEFT, 1550, INNER_RIGHT - INNER_LEFT, 900), Color(0.10, 0.13, 0.18, 0.82))
	draw_rect(Rect2(INNER_LEFT, 600, INNER_RIGHT - INNER_LEFT, 950), Color(0.075, 0.11, 0.16, 0.9))
	draw_rect(Rect2(INNER_LEFT, 0, INNER_RIGHT - INNER_LEFT, 600), Color(0.16, 0.18, 0.22, 0.95))

	# 程序占位污渍、霜晶和顶灯。
	for center in [Vector2(270, 2770), Vector2(480, 2880), Vector2(850, 2630), Vector2(1030, 2990)]:
		draw_circle(center, 72.0, Color(0.20, 0.30, 0.16, 0.64))
	for center in [Vector2(250, 1080), Vector2(980, 980), Vector2(1080, 720)]:
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -55), center + Vector2(28, 35), center + Vector2(-34, 24)
		]), Color(0.55, 0.78, 0.96, 0.75))
	draw_rect(Rect2(505, 32, 270, 82), Color(0.86, 0.92, 1.0, 0.92))


func set_player_input_enabled(enabled: bool) -> void:
	if is_instance_valid(player) and player.has_method("set_input_enabled"):
		player.set_input_enabled(enabled)


func _build_darkness() -> void:
	var darkness := CanvasModulate.new()
	darkness.name = "Darkness"
	darkness.color = Color(0.17, 0.18, 0.26)
	add_child(darkness)


func _spawn_player() -> void:
	player = SPROUT_SCENE.instantiate()
	player.name = "Sprout"
	player.add_to_group(&"player")
	player.global_position = SPAWN_POSITION
	add_child(player)


func _build_world_collision() -> void:
	_create_static_rect(Vector2(46, WORLD_HEIGHT * 0.5), Vector2(92, WORLD_HEIGHT), Color(0.19, 0.22, 0.29))
	_create_static_rect(Vector2(1234, WORLD_HEIGHT * 0.5), Vector2(92, WORLD_HEIGHT), Color(0.19, 0.22, 0.29))
	_create_static_rect(Vector2(640, 3260), Vector2(1096, 80), Color(0.22, 0.16, 0.14))

	# 错落搁板，始终留出至少 230 像素的通道。
	_create_static_rect(Vector2(470, 2460), Vector2(760, 44), Color(0.24, 0.30, 0.36))
	_create_static_rect(Vector2(820, 2020), Vector2(736, 42), Color(0.27, 0.34, 0.41))
	_create_static_rect(Vector2(410, 1450), Vector2(630, 46), Color(0.20, 0.28, 0.36))

	# “泰坦巨柱”占位辣酱瓶。
	_create_static_rect(Vector2(660, 1090), Vector2(170, 520), Color(0.50, 0.13, 0.12))
	# 顶部包装块，形成通往盒盖的弯曲路径。
	_create_static_rect(Vector2(340, 620), Vector2(430, 52), Color(0.28, 0.31, 0.38))
	_create_static_rect(Vector2(980, 470), Vector2(350, 52), Color(0.28, 0.31, 0.38))


func _build_charge_barriers() -> void:
	var film := BARRIER_SCENE.instantiate()
	film.name = "PlasticFilm"
	film.position = Vector2(640, 1740)
	film.barrier_size = Vector2(1096, 34)
	film.required_hold_seconds = 0.9
	film.barrier_color = Color(0.70, 0.88, 1.0, 0.38)
	film.prompt_text = "[空格] 长按撕裂虚空之茧"
	add_child(film)
	film.barrier_broken.connect(_on_barrier_broken)

	var lid := BARRIER_SCENE.instantiate()
	lid.name = "FinalLid"
	lid.position = Vector2(640, 205)
	lid.barrier_size = Vector2(1096, 54)
	lid.required_hold_seconds = 1.75
	lid.barrier_color = Color(0.86, 0.92, 1.0, 0.64)
	lid.prompt_text = "[空格] 长按顶开最后苍穹"
	lid.is_final_barrier = true
	add_child(lid)
	lid.barrier_broken.connect(_on_barrier_broken)


func _on_barrier_broken(is_final: bool) -> void:
	if not is_final:
		var narrative := get_node_or_null("/root/NarrativeManager")
		if narrative != null:
			narrative.request_text(&"film_broken")
		return
	if ending_started:
		return
	ending_started = true
	set_player_input_enabled(false)
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null:
		narrative.clear_queue()
	await get_tree().create_timer(0.45).timeout
	ending_requested.emit(DEFAULT_ENDING_ID)


func _build_material_feedback() -> void:
	var sticky := STICKY_AREA_SCENE.instantiate()
	sticky.name = "RottenSlime"
	sticky.position = Vector2(780, 2820)
	sticky.area_size = Vector2(420, 230)
	add_child(sticky)

	var frost := FROST_AREA_SCENE.instantiate()
	frost.name = "FrostPatch"
	frost.position = Vector2(1010, 1120)
	frost.area_size = Vector2(260, 230)
	add_child(frost)


func _build_interactions() -> void:
	var clue := PICKUP_SCENE.instantiate()
	clue.name = "DateTabletPickup"
	clue.position = Vector2(230, 2670)
	clue.item_id = &"date_tablet"
	clue.display_name_myth = "古代数字石片"
	clue.display_name_real = "褪色日期贴纸"
	clue.narrative_text_id = &"pickup_date_tablet"
	clue.pickup_color = Color(0.91, 0.77, 0.48)
	add_child(clue)

	var sleeper := INTERACTABLE_SCENE.instantiate()
	sleeper.name = "SleepingSprout"
	sleeper.position = Vector2(980, 2640)
	sleeper.item_id = &"sleeping_sprout"
	sleeper.display_name_myth = "沉睡的先驱者"
	sleeper.display_name_real = "蔫软的菜叶"
	sleeper.short_action = &"nurture"
	sleeper.hold_action = &"devour"
	sleeper.narrative_text_id = &"interact_sample"
	add_child(sleeper)


func _build_narrative() -> void:
	add_child(DIALOGUE_BOX_SCENE.instantiate())
	add_child(DEBUG_PANEL_SCENE.instantiate())
	_create_narrative_trigger(&"prologue", Vector2(310, 3040), Vector2(360, 220))
	_create_narrative_trigger(&"stage_rot", Vector2(640, 2900), Vector2(1000, 180))
	_create_narrative_trigger(&"stage_film", Vector2(640, 2200), Vector2(1000, 180))
	_create_narrative_trigger(&"stage_frost", Vector2(640, 1320), Vector2(1000, 180))
	_create_narrative_trigger(&"stage_final", Vector2(640, 430), Vector2(1000, 160))


func _create_narrative_trigger(text_id: StringName, at_position: Vector2, size: Vector2) -> void:
	var trigger := NARRATIVE_TRIGGER_SCENE.instantiate()
	trigger.name = "Narrative_%s" % text_id
	trigger.position = at_position
	trigger.text_id = text_id
	trigger.trigger_size = size
	add_child(trigger)


func _build_world_labels() -> void:
	_create_world_label("腐土深渊 / 被遗忘的蔬菜盒", Vector2(170, 3120), Color(0.70, 0.78, 0.66))
	_create_world_label("虚空之茧 / 透明保鲜膜", Vector2(650, 1810), Color(0.72, 0.86, 1.0))
	_create_world_label("泰坦巨柱 / 辣酱瓶", Vector2(740, 1340), Color(1.0, 0.55, 0.46))
	_create_world_label("神圣破晓 / 外卖盒盖", Vector2(470, 300), Color(0.94, 0.96, 1.0))


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	canvas.layer = 30
	add_child(canvas)

	var panel := ColorRect.new()
	panel.position = Vector2(22, 18)
	panel.size = Vector2(410, 105)
	panel.color = Color(0.015, 0.022, 0.055, 0.82)
	canvas.add_child(panel)

	progress_label = Label.new()
	progress_label.position = Vector2(42, 32)
	progress_label.size = Vector2(380, 34)
	progress_label.add_theme_font_size_override("font_size", 23)
	progress_label.text = "向破晓生长  0%"
	canvas.add_child(progress_label)

	stage_label = Label.new()
	stage_label.position = Vector2(42, 69)
	stage_label.size = Vector2(380, 30)
	stage_label.add_theme_font_size_override("font_size", 18)
	stage_label.add_theme_color_override("font_color", Color(0.68, 0.75, 0.92))
	stage_label.text = "黑暗中的苏醒"
	canvas.add_child(stage_label)

	var controls := Label.new()
	controls.position = Vector2(438, 24)
	controls.size = Vector2(820, 44)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_theme_font_size_override("font_size", 19)
	controls.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))
	controls.text = "WASD / 方向键：生长    E：互动    Space：蓄力/跳字    F3：调试"
	canvas.add_child(controls)

	var build_tag := Label.new()
	build_tag.position = Vector2(940, 678)
	build_tag.size = Vector2(318, 28)
	build_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	build_tag.add_theme_font_size_override("font_size", 15)
	build_tag.add_theme_color_override("font_color", Color(0.48, 0.52, 0.65))
	build_tag.text = "GRAYBOX 7–13H  ·  基础系统"
	canvas.add_child(build_tag)


func _create_static_rect(center: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	body.name = "Obstacle"

	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	body.add_child(collision)

	var polygon := Polygon2D.new()
	var half := size * 0.5
	polygon.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	polygon.color = color
	body.add_child(polygon)
	add_child(body)
	return body


func _create_world_label(text_value: String, at_position: Vector2, color: Color) -> void:
	var label := Label.new()
	label.position = at_position
	label.size = Vector2(450, 42)
	label.text = text_value
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", color)
	label.z_index = 4
	add_child(label)


func _stage_name_for_height(y: float) -> String:
	if y > 2450.0:
		return "第一幕：腐土深渊"
	if y > 1550.0:
		return "第二幕：虚空之茧"
	if y > 600.0:
		return "第三幕：泰坦巨柱与霜毒"
	return "终幕：神圣破晓"
