extends Node2D

signal ritual_completed(ritual_id: StringName)

@export var ritual_id: StringName = &"bottle_counterclockwise"
@export_enum("counterclockwise", "clockwise") var direction: String = "counterclockwise"
@export var radius: float = 230.0
@export var checkpoint_radius: float = 62.0
@export var step_timeout: float = 8.0
@export var success_text_id: StringName = &"ritual_complete"
@export var ring_color := Color(0.72, 0.28, 0.88, 0.42)

var _expected_index: int = 0
var _step_elapsed: float = 0.0
var _completed: bool = false
var _checkpoint_visuals: Array[Polygon2D] = []


func _ready() -> void:
	_build_checkpoints()
	queue_redraw()


func _process(delta: float) -> void:
	if _completed or _expected_index == 0:
		return
	_step_elapsed += delta
	if _step_elapsed > step_timeout:
		_reset_progress()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, ring_color, 3.0)


func register_checkpoint(index: int) -> void:
	if _completed:
		return
	if index != _expected_index:
		if index == 0:
			_reset_progress()
			_accept_step(0)
		else:
			_reset_progress()
		return
	_accept_step(index)


func _accept_step(index: int) -> void:
	_step_elapsed = 0.0
	_checkpoint_visuals[index].color = Color(0.95, 0.80, 1.0, 0.9)
	_expected_index += 1
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(StringName("ritual_step_%d" % index))
	if _expected_index < 4:
		return
	_completed = true
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.complete_ritual(ritual_id)
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null and not success_text_id.is_empty():
		narrative.request_text(success_text_id)
	ritual_completed.emit(ritual_id)


func _reset_progress() -> void:
	_expected_index = 0
	_step_elapsed = 0.0
	for visual in _checkpoint_visuals:
		visual.color = ring_color


func _build_checkpoints() -> void:
	var positions := [Vector2(0, -radius), Vector2(-radius, 0), Vector2(0, radius), Vector2(radius, 0)]
	if direction == "clockwise":
		positions = [Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0)]
	for index in range(positions.size()):
		var area := Area2D.new()
		area.position = positions[index]
		area.collision_layer = 16
		area.collision_mask = 2
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = checkpoint_radius
		collision.shape = shape
		area.add_child(collision)
		var marker := Polygon2D.new()
		marker.polygon = PackedVector2Array([Vector2(0, -16), Vector2(14, 10), Vector2(-14, 10)])
		marker.color = ring_color
		marker.rotation = index * PI * 0.5
		area.add_child(marker)
		_checkpoint_visuals.append(marker)
		area.body_entered.connect(_on_checkpoint_entered.bind(index))
		add_child(area)


func _on_checkpoint_entered(body: Node2D, index: int) -> void:
	if body.is_in_group(&"player"):
		register_checkpoint(index)
