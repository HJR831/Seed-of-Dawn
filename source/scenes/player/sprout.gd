extends CharacterBody2D

@export var max_speed: float = 190.0
@export var acceleration: float = 950.0
@export var deceleration: float = 1250.0
@export var trail_point_gap: float = 8.0
@export var max_trail_points: int = 700

@onready var trail: Line2D = $Trail
@onready var local_light: PointLight2D = $LocalLight

var input_enabled: bool = true
var last_trail_point := Vector2.INF


func _ready() -> void:
	local_light.texture = _create_radial_light_texture(128)
	trail.clear_points()
	trail.add_point(global_position)
	last_trail_point = global_position
	queue_redraw()


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if input_enabled:
		direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	var target_velocity := direction * max_speed
	var rate := acceleration if not direction.is_zero_approx() else deceleration
	velocity = velocity.move_toward(target_velocity, rate * delta)

	var previous_position := global_position
	move_and_slide()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.add_distance(previous_position.distance_to(global_position))
	_update_trail()


func _draw() -> void:
	# 程序占位芽尖：紫色种子、亮色芽眼和两片小叶。
	draw_circle(Vector2.ZERO, 18.0, Color(0.36, 0.07, 0.58))
	draw_circle(Vector2(0, -3), 13.0, Color(0.72, 0.27, 0.96))
	draw_circle(Vector2(4, -7), 4.0, Color(0.96, 0.82, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -13), Vector2(-25, -29), Vector2(-14, -4)
	]), Color(0.41, 0.75, 0.38))
	draw_colored_polygon(PackedVector2Array([
		Vector2(7, -13), Vector2(25, -25), Vector2(15, -2)
	]), Color(0.52, 0.88, 0.43))


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func get_head_position() -> Vector2:
	return global_position


func get_trail_points() -> PackedVector2Array:
	return trail.points


func _update_trail() -> void:
	if global_position.distance_to(last_trail_point) < trail_point_gap:
		return
	trail.add_point(global_position)
	last_trail_point = global_position
	if trail.get_point_count() > max_trail_points:
		trail.remove_point(0)


func _create_radial_light_texture(size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) * 0.5
	var radius := float(size) * 0.5
	for y in range(size):
		for x in range(size):
			var distance_ratio := Vector2(x, y).distance_to(center) / radius
			var strength := pow(clampf(1.0 - distance_ratio, 0.0, 1.0), 2.2)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, strength))
	return ImageTexture.create_from_image(image)
