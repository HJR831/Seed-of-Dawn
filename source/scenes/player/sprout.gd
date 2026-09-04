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
var speed_modifiers: Dictionary = {}
var statuses: Dictionary = {}
var visual_route: StringName = &"neutral"
var visual_stage: int = 0
var _hard_collision_cooldown: float = 0.0


func _ready() -> void:
	local_light.texture = _create_radial_light_texture(128)
	trail.clear_points()
	trail.add_point(global_position)
	last_trail_point = global_position
	queue_redraw()


func _physics_process(delta: float) -> void:
	_hard_collision_cooldown = maxf(_hard_collision_cooldown - delta, 0.0)
	var direction := Vector2.ZERO
	if input_enabled:
		direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	var target_velocity := direction * max_speed * _combined_speed_multiplier()
	var rate := acceleration if not direction.is_zero_approx() else deceleration
	velocity = velocity.move_toward(target_velocity, rate * delta)

	var previous_position := global_position
	var impact_speed := velocity.length()
	move_and_slide()
	_handle_hard_collisions(impact_speed)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.add_distance(previous_position.distance_to(global_position))
	_update_trail()


func _draw() -> void:
	# 程序占位芽尖：紫色种子、亮色芽眼和两片小叶。
	var body_color := Color(0.36, 0.07, 0.58)
	var head_color := Color(0.72, 0.27, 0.96)
	if statuses.has(&"frost"):
		body_color = Color(0.25, 0.51, 0.72)
		head_color = Color(0.63, 0.87, 1.0)
	elif visual_route == &"milk" and visual_stage > 0:
		body_color = Color(0.72, 0.58, 0.24)
		head_color = Color(1.0, 0.91, 0.56)
	draw_circle(Vector2.ZERO, 18.0, body_color)
	draw_circle(Vector2(0, -3), 13.0, head_color)
	draw_circle(Vector2(4, -7), 4.0, Color(0.96, 0.82, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -13), Vector2(-25, -29), Vector2(-14, -4)
	]), Color(0.41, 0.75, 0.38))
	draw_colored_polygon(PackedVector2Array([
		Vector2(7, -13), Vector2(25, -25), Vector2(15, -2)
	]), Color(0.52, 0.88, 0.43))
	if statuses.has(&"frost"):
		for offset in [Vector2(-15, 8), Vector2(12, 10), Vector2(-3, -18)]:
			draw_colored_polygon(PackedVector2Array([
				offset + Vector2(-5, 4), offset + Vector2(0, -9), offset + Vector2(6, 4)
			]), Color(0.82, 0.95, 1.0, 0.9))


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func apply_status(status_id: StringName, amount: float) -> void:
	if amount <= 0.0:
		statuses.erase(status_id)
	else:
		statuses[status_id] = amount
	_update_status_visuals()


func set_visual_stage(route_id: StringName, stage: int) -> void:
	visual_route = route_id
	visual_stage = maxi(stage, 0)
	_update_status_visuals()


func add_temporary_speed_modifier(source: StringName, multiplier: float) -> void:
	speed_modifiers[source] = clampf(multiplier, 0.05, 2.0)


func remove_speed_modifier(source: StringName) -> void:
	speed_modifiers.erase(source)


func get_status_amount(status_id: StringName) -> float:
	return float(statuses.get(status_id, 0.0))


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


func _combined_speed_multiplier() -> float:
	var result := 1.0
	for multiplier in speed_modifiers.values():
		result *= float(multiplier)
	return clampf(result, 0.1, 1.75)


func _handle_hard_collisions(impact_speed: float) -> void:
	if get_slide_collision_count() == 0 or _hard_collision_cooldown > 0.0:
		return
	if impact_speed < 115.0:
		return
	_hard_collision_cooldown = 0.28
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.increment_counter(&"hard_collision_count")
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"hard_hit")
	local_light.energy = 3.4
	create_tween().tween_property(local_light, "energy", 2.4, 0.22)


func _update_status_visuals() -> void:
	if statuses.has(&"frost"):
		trail.default_color = Color(0.55, 0.82, 1.0)
		local_light.color = Color(0.62, 0.84, 1.0)
	elif visual_route == &"milk" and visual_stage > 0:
		trail.default_color = Color(1.0, 0.88, 0.48)
		local_light.color = Color(1.0, 0.86, 0.58)
	else:
		trail.default_color = Color(0.52, 0.16, 0.84)
		local_light.color = Color(0.72, 0.46, 1.0)
	queue_redraw()


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
