extends Area2D

signal ending_requested(ending_id: StringName)

const EndingResolverScript := preload("res://systems/ending_resolver.gd")

@export var trigger_id: StringName = &"light_switch_hold"
@export_enum("hold", "idle") var activation_mode: String = "hold"
@export var required_seconds: float = 7.0
@export var area_size := Vector2(220.0, 180.0)
@export var prompt_text: String = "长按 E 扼住伪日"
@export var entrance_color := Color(0.92, 0.94, 1.0, 0.75)

var player_inside: bool = false
var _elapsed: float = 0.0
var _resolved: bool = false
var _cooldown: float = 0.0
var _prompt: Label
var _bar: ProgressBar
var _player: CharacterBody2D


func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = area_size
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_ui()
	queue_redraw()


func _process(delta: float) -> void:
	if _resolved or not player_inside:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	var active := false
	if activation_mode == "hold":
		active = Input.is_action_pressed(&"interact")
	elif is_instance_valid(_player):
		active = _player.velocity.length() < 5.0 and Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down").is_zero_approx()
	if active:
		_elapsed = minf(_elapsed + delta, required_seconds)
	else:
		_elapsed = maxf(_elapsed - delta * 2.0, 0.0)
	_bar.value = _elapsed / maxf(required_seconds, 0.01) * 100.0
	if _elapsed >= required_seconds and _cooldown <= 0.0:
		_try_resolve()


func _draw() -> void:
	draw_rect(Rect2(-area_size * 0.5, area_size), Color(entrance_color, 0.18), true)
	draw_rect(Rect2(Vector2(-40, -28), Vector2(80, 56)), entrance_color, true)


func _try_resolve() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var result: Dictionary = EndingResolverScript.request_ending(trigger_id, game_state.make_snapshot())
	if bool(result.get("matched", false)):
		_resolved = true
		_prompt.visible = false
		_bar.visible = false
		ending_requested.emit(result.get("ending_id", &""))
		return
	var missing: Array = result.get("missing", [])
	_prompt.text = str(missing[0]) if not missing.is_empty() else "仪式没有回应"
	_prompt.visible = true
	_elapsed = 0.0
	_bar.value = 0.0
	_cooldown = 2.0
	game_state.set_flag(&"ending_attempt_failed")


func _build_ui() -> void:
	_prompt = Label.new()
	_prompt.position = Vector2(-230, area_size.y * 0.5 + 18)
	_prompt.size = Vector2(460, 58)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.add_theme_font_size_override("font_size", 19)
	_prompt.text = prompt_text
	_prompt.visible = false
	_prompt.z_index = 15
	add_child(_prompt)
	_bar = ProgressBar.new()
	_bar.position = Vector2(-120, area_size.y * 0.5 + 80)
	_bar.size = Vector2(240, 14)
	_bar.show_percentage = false
	_bar.visible = false
	_bar.z_index = 15
	add_child(_bar)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	player_inside = true
	_player = body as CharacterBody2D
	_prompt.text = prompt_text
	_prompt.visible = true
	_bar.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body != _player:
		return
	player_inside = false
	_player = null
	_elapsed = 0.0
	_prompt.visible = false
	_bar.visible = false
	_bar.value = 0.0
