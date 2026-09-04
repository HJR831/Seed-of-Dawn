extends Area2D

@export var area_size := Vector2(250.0, 150.0)
@export_range(0.1, 1.0, 0.05) var speed_multiplier: float = 0.65
@export var area_color := Color(0.44, 0.72, 0.94, 0.58)

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
	for x in [-95.0, -28.0, 42.0, 98.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 18, area_size.y * 0.5), Vector2(x, area_size.y * 0.15),
			Vector2(x + 20, area_size.y * 0.5)
		]), Color(0.68, 0.88, 1.0, 0.8))


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player") or not body.has_method("apply_status"):
		return
	_affected_players[body] = true
	body.add_temporary_speed_modifier(StringName("frost_%d" % get_instance_id()), speed_multiplier)
	var frost_amount: float = body.get_status_amount(&"frost") if body.has_method("get_status_amount") else 0.0
	body.apply_status(&"frost", frost_amount + 1.0)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.increment_counter(&"frost_contacts")
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"frost_touch")


func _on_body_exited(body: Node2D) -> void:
	if not _affected_players.erase(body):
		return
	if body.has_method("remove_speed_modifier"):
		body.remove_speed_modifier(StringName("frost_%d" % get_instance_id()))
	if body.has_method("apply_status"):
		var frost_amount: float = body.get_status_amount(&"frost") if body.has_method("get_status_amount") else 1.0
		body.apply_status(&"frost", maxf(frost_amount - 1.0, 0.0))
