extends Area2D

@export var area_size := Vector2(300.0, 180.0)
@export_range(0.1, 1.0, 0.05) var speed_multiplier: float = 0.45
@export var area_color := Color(0.18, 0.34, 0.12, 0.72)
@export var flag_on_enter: StringName = &""

var _affected_players: Dictionary = {}


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = area_size
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-area_size * 0.5, area_size), area_color, true)
	for offset in [Vector2(-90, -18), Vector2(15, 30), Vector2(92, -36)]:
		draw_circle(offset, 13.0, Color(0.42, 0.56, 0.25, 0.55), false, 3.0)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player") or not body.has_method("add_temporary_speed_modifier"):
		return
	_affected_players[body] = true
	body.add_temporary_speed_modifier(StringName("sticky_%d" % get_instance_id()), speed_multiplier)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and not flag_on_enter.is_empty():
		game_state.set_flag(flag_on_enter)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"sticky_enter")


func _on_body_exited(body: Node2D) -> void:
	if not _affected_players.erase(body):
		return
	if body.has_method("remove_speed_modifier"):
		body.remove_speed_modifier(StringName("sticky_%d" % get_instance_id()))
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"sticky_exit")
