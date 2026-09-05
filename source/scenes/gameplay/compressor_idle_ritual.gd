extends Area2D

@export var required_seconds: float = 12.0
@export var completion_flag: StringName = &"frozen_full_cycle"

var _player: CharacterBody2D
var _still_seconds := 0.0
var _prompt: Label


func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 150.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt = Label.new()
	_prompt.position = Vector2(-220, 150)
	_prompt.size = Vector2(440, 54)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.text = "保持静止，听完一次完整呼吸"
	_prompt.visible = false
	add_child(_prompt)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var no_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down").is_zero_approx()
	if no_input and _player.velocity.length() < 5.0:
		_still_seconds += delta
	else:
		_still_seconds = 0.0
	_prompt.text = "保持静止，听完一次完整呼吸  %d%%" % roundi(clampf(_still_seconds / required_seconds, 0.0, 1.0) * 100.0)
	if _still_seconds >= required_seconds:
		get_node("/root/GameState").set_flag(completion_flag)
		_prompt.text = "完整的寒冷周期已经过去"


func _draw() -> void:
	draw_circle(Vector2.ZERO, 145.0, Color(0.40, 0.72, 1.0, 0.10))
	draw_arc(Vector2.ZERO, 145.0, 0.0, TAU, 48, Color(0.62, 0.86, 1.0, 0.55), 3.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player = body as CharacterBody2D
		_still_seconds = 0.0
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_still_seconds = 0.0
		_prompt.visible = false
