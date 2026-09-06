extends Area2D

@export var required_seconds := 2.5
@export var area_size := Vector2(260.0, 200.0)
@export var completion_flag: StringName = &"sustained_downward"

var _player: CharacterBody2D
var _elapsed := 0.0
var _prompt: Label


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
	_prompt = Label.new()
	_prompt.position = Vector2(-240, 120)
	_prompt.size = Vector2(480, 54)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.text = "持续向下，让根须选择黑暗"
	_prompt.visible = false
	add_child(_prompt)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	if Input.is_action_pressed(&"move_down"):
		_elapsed += delta
	else:
		_elapsed = maxf(_elapsed - delta, 0.0)
	_prompt.text = "持续向下，让根须选择黑暗  %d%%" % roundi(clampf(_elapsed / required_seconds, 0.0, 1.0) * 100.0)
	if _elapsed >= required_seconds:
		get_node("/root/GameState").set_flag(completion_flag)
		_prompt.text = "根须记住了向下的方向"


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-70, -60), Vector2(70, -60), Vector2(0, 75)]), Color(0.70, 0.45, 0.18, 0.34))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player = body as CharacterBody2D
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_elapsed = 0.0
		_prompt.visible = false
