extends Area2D

@export var required_seconds := 2.0
@export var command_index := 1
@export var completion_counter: StringName = &"narrator_refusal_count"

var _player: CharacterBody2D
var _elapsed := 0.0
var _completed := false
var _prompt: Label


func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 115.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt = Label.new()
	_prompt.position = Vector2(-230, 120)
	_prompt.size = Vector2(460, 58)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.visible = false
	add_child(_prompt)
	queue_redraw()


func _process(delta: float) -> void:
	if _completed or not is_instance_valid(_player):
		return
	var no_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down").is_zero_approx()
	if no_input and _player.velocity.length() < 5.0:
		_elapsed += delta
	else:
		_elapsed = 0.0
	_prompt.text = "旁白命令 %d：保持不动以拒绝  %d%%" % [command_index, roundi(clampf(_elapsed / required_seconds, 0.0, 1.0) * 100.0)]
	if _elapsed >= required_seconds:
		_completed = true
		get_node("/root/GameState").increment_counter(completion_counter)
		get_node("/root/NarrativeManager").request_text(&"narrator_command_refused")
		_prompt.text = "你拒绝了这次生长命令"


func _draw() -> void:
	draw_circle(Vector2.ZERO, 108.0, Color(0.72, 0.76, 0.82, 0.08))
	draw_arc(Vector2.ZERO, 108.0, 0.0, TAU, 36, Color(0.72, 0.76, 0.82, 0.42), 2.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player = body as CharacterBody2D
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_elapsed = 0.0
		_prompt.visible = false
