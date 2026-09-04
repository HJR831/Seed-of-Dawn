extends Area2D

signal interaction_completed(item_id: StringName, action_id: StringName)

@export var item_id: StringName = &"sleeping_sprout"
@export var display_name_myth: String = "沉睡的先驱者"
@export var display_name_real: String = "蔫软的菜叶"
@export var interaction_type: StringName = &"living"
@export var short_action: StringName = &"nurture"
@export var hold_action: StringName = &"devour"
@export var state_delta: Dictionary = {}
@export var narrative_text_id: StringName = &"interact_sample"
@export var required_item: StringName = &""
@export var consumed_after_use: bool = true
@export var short_press_seconds: float = 0.35
@export var hold_seconds: float = 0.8
@export var interaction_radius: float = 72.0
@export var object_color := Color(0.42, 0.66, 0.30)

var player_inside: bool = false
var is_completed: bool = false
var _press_seconds: float = 0.0
var _tracking_press: bool = false
var _hold_completed: bool = false
var _prompt: Label
var _bar: ProgressBar


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = interaction_radius
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_prompt()
	queue_redraw()


func _process(delta: float) -> void:
	if is_completed or not player_inside:
		return
	if Input.is_action_just_pressed(&"interact"):
		_tracking_press = true
		_hold_completed = false
		_press_seconds = 0.0
	if _tracking_press and Input.is_action_pressed(&"interact"):
		_press_seconds += delta
		_bar.value = clampf(_press_seconds / maxf(hold_seconds, 0.01) * 100.0, 0.0, 100.0)
		if _press_seconds >= hold_seconds and not _hold_completed:
			_hold_completed = perform_hold_action()
			_tracking_press = false
	if _tracking_press and Input.is_action_just_released(&"interact"):
		if _press_seconds <= short_press_seconds:
			perform_short_action()
		_tracking_press = false
		_press_seconds = 0.0
		_bar.value = 0.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, 28.0, Color(object_color, 0.32))
	draw_circle(Vector2.ZERO, 19.0, object_color)
	draw_line(Vector2(-12, 3), Vector2(12, -5), Color(0.84, 0.96, 0.72), 4.0)


func perform_short_action() -> bool:
	return _complete_action(short_action)


func perform_hold_action() -> bool:
	return _complete_action(hold_action)


func _complete_action(action_id: StringName) -> bool:
	if is_completed:
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	if not required_item.is_empty() and not game_state.has_item(required_item):
		var narrative := get_node_or_null("/root/NarrativeManager")
		if narrative != null:
			narrative.request_text(&"interaction_missing_item")
		return false
	match action_id:
		&"nurture", &"devour", &"noise", &"destruction", &"corruption":
			game_state.add_stat(action_id, int(state_delta.get(action_id, 1)))
		&"collect":
			game_state.collect_item(item_id)
		_:
			game_state.set_flag(action_id)
	game_state.set_flag(StringName("interacted_%s" % item_id))
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null and not narrative_text_id.is_empty():
		narrative.request_text(narrative_text_id)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"interact_hold" if action_id == hold_action else &"interact_short")
	interaction_completed.emit(item_id, action_id)
	is_completed = true
	_prompt.visible = false
	_bar.visible = false
	monitoring = false
	if consumed_after_use:
		modulate = Color(0.35, 0.35, 0.35, 0.35)
	else:
		modulate = Color(0.7, 0.85, 0.7, 1.0)
	return true


func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.position = Vector2(-180, 42)
	_prompt.size = Vector2(360, 32)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.text = "轻按 E 帮助  /  长按 E 吸收"
	_prompt.visible = false
	_prompt.z_index = 12
	add_child(_prompt)
	_bar = ProgressBar.new()
	_bar.position = Vector2(-90, 76)
	_bar.size = Vector2(180, 12)
	_bar.show_percentage = false
	_bar.visible = false
	_bar.z_index = 12
	add_child(_bar)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and not is_completed:
		player_inside = true
		_prompt.visible = true
		_bar.visible = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	player_inside = false
	_tracking_press = false
	_press_seconds = 0.0
	_prompt.visible = false
	_bar.visible = false
	_bar.value = 0.0
