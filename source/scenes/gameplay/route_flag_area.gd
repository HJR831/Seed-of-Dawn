extends Area2D

@export var flag_id: StringName = &"route_flag"
@export var required_flag: StringName = &""
@export var area_size := Vector2(260.0, 220.0)
@export var visible_marker: bool = false


func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = area_size
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	if visible_marker:
		draw_rect(Rect2(-area_size * 0.5, area_size), Color(0.45, 0.82, 0.62, 0.12), true)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	if not required_flag.is_empty() and not game_state.has_flag(required_flag):
		return
	game_state.set_flag(flag_id)

