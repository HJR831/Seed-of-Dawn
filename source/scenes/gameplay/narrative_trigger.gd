extends Area2D

@export var text_id: StringName = &"prologue"
@export var trigger_size := Vector2(900.0, 180.0)
@export var once: bool = true

var _triggered: bool = false


func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = trigger_size
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player") or (once and _triggered):
		return
	_triggered = true
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null:
		narrative.request_text(text_id)
