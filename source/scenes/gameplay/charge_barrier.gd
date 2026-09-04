extends StaticBody2D

signal barrier_broken(is_final: bool)

@export var barrier_size := Vector2(920.0, 38.0)
@export var barrier_color := Color(0.72, 0.86, 0.96, 0.42)
@export var required_hold_seconds: float = 1.1
@export var is_final_barrier: bool = false
@export var prompt_text: String = "[空格] 长按撕裂透明结界"

var charge_seconds: float = 0.0
var player_inside: bool = false
var is_broken: bool = false
var solid_collision: CollisionShape2D
var sensor: Area2D
var visual: Polygon2D
var prompt: Label


func _ready() -> void:
	_build_collision()
	_build_visual()
	_build_sensor()
	_build_prompt()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if is_broken:
		return

	var narrative := get_node_or_null("/root/NarrativeManager")
	var text_is_active: bool = narrative != null and narrative.is_text_active()
	if player_inside and not text_is_active and Input.is_action_pressed(&"charge"):
		charge_seconds = minf(charge_seconds + delta, required_hold_seconds)
	else:
		charge_seconds = maxf(charge_seconds - delta * 1.6, 0.0)

	_update_feedback()
	if charge_seconds >= required_hold_seconds:
		_break_barrier()


func _build_collision() -> void:
	solid_collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = barrier_size
	solid_collision.shape = shape
	add_child(solid_collision)


func _build_visual() -> void:
	visual = Polygon2D.new()
	visual.polygon = _rectangle_polygon(barrier_size)
	visual.color = barrier_color
	visual.z_index = 3
	add_child(visual)


func _build_sensor() -> void:
	sensor = Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var sensor_collision := CollisionShape2D.new()
	var sensor_shape := RectangleShape2D.new()
	sensor_shape.size = Vector2(barrier_size.x, barrier_size.y + 210.0)
	sensor_collision.shape = sensor_shape
	sensor.add_child(sensor_collision)
	add_child(sensor)
	sensor.body_entered.connect(_on_body_entered)
	sensor.body_exited.connect(_on_body_exited)


func _build_prompt() -> void:
	prompt = Label.new()
	prompt.position = Vector2(-320.0, 54.0)
	prompt.size = Vector2(640.0, 56.0)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0))
	prompt.text = prompt_text
	prompt.visible = false
	prompt.z_index = 10
	add_child(prompt)


func _update_feedback() -> void:
	var ratio := charge_seconds / maxf(required_hold_seconds, 0.01)
	visual.scale.y = lerpf(1.0, 0.35, ratio)
	visual.modulate = Color(1.0, 1.0, 1.0, lerpf(0.72, 1.0, ratio))
	if player_inside:
		prompt.text = "%s  %d%%" % [prompt_text, roundi(ratio * 100.0)]


func _break_barrier() -> void:
	if is_broken:
		return
	is_broken = true
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.increment_counter(&"film_broken_count" if not is_final_barrier else &"lid_open_count")
		if not is_final_barrier:
			game_state.add_stat(&"destruction", 1)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"barrier_break")
	prompt.visible = false
	solid_collision.set_deferred("disabled", true)
	sensor.set_deferred("monitoring", false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "position", Vector2(0.0, -90.0), 0.32)
	tween.tween_property(visual, "modulate:a", 0.0, 0.32)
	await tween.finished
	barrier_broken.emit(is_final_barrier)
	if not is_final_barrier:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		player_inside = true
		prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		player_inside = false
		prompt.visible = false


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
