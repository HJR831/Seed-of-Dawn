extends Area2D

signal collected(item_id: StringName)

@export var item_id: StringName = &"sample_pickup"
@export var display_name_myth: String = "遗落的微光"
@export var display_name_real: String = "未知物品"
@export var narrative_text_id: StringName = &"pickup_sample"
@export var counter_id: StringName = &""
@export var stat_id: StringName = &""
@export var stat_amount: int = 0
@export var pickup_color := Color(0.96, 0.75, 0.30)
@export var pickup_radius: float = 18.0

var is_collected: bool = false


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = pickup_radius + 10.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, pickup_radius + 7.0, Color(pickup_color, 0.18))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -pickup_radius), Vector2(pickup_radius * 0.72, 0),
		Vector2(0, pickup_radius), Vector2(-pickup_radius * 0.72, 0)
	]), pickup_color)


func collect() -> bool:
	if is_collected:
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.collect_item(item_id):
		return false
	is_collected = true
	if not counter_id.is_empty():
		game_state.increment_counter(counter_id)
	if not stat_id.is_empty() and stat_amount != 0:
		game_state.add_stat(stat_id, stat_amount)
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null and not narrative_text_id.is_empty():
		narrative.request_text(narrative_text_id)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"pickup")
	collected.emit(item_id)
	monitoring = false
	visible = false
	queue_free()
	return true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		collect()
