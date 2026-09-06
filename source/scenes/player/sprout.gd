extends CharacterBody2D

@export var max_speed: float = 190.0
@export var sprint_speed: float = 300.0
@export var sprint_capacity: float = 1.4
@export var sprint_regen_time: float = 1.6
@export var sprint_regen_delay: float = 0.65
@export var acceleration: float = 950.0
@export var deceleration: float = 1250.0
@export var trail_point_gap: float = 8.0
@export var max_trail_points: int = 700

const LAYER_PARTICLE_COLORS := [
	Color(0.86, 0.47, 0.26), # 出生层：土壤暖褐
	Color(0.58, 0.68, 0.22), # 腐败层：酸性黄绿
	Color(0.45, 0.78, 0.66), # 保鲜膜层：冷薄荷
	Color(0.35, 0.82, 0.48), # 根网层：生命绿
	Color(0.40, 0.70, 0.92), # 霜柜层：冰蓝
	Color(0.68, 0.52, 0.94), # 控制层：电紫
	Color(0.86, 0.82, 0.62), # 外壳层：冷白
]

@onready var trail: Line2D = $Trail
@onready var local_light: PointLight2D = $LocalLight

var input_enabled: bool = true
var last_trail_point := Vector2.INF
var speed_modifiers: Dictionary = {}
var statuses: Dictionary = {}
var visual_route: StringName = &"neutral"
var visual_stage: int = 0
var _hard_collision_cooldown: float = 0.0
var sprint_stamina: float = 1.0
var is_sprinting_now: bool = false
var _sprint_regen_delay_left: float = 0.0
var _effect_visual_state: Dictionary = {}
var _sprint_locks: Dictionary = {}
var _using_head_art := false
var _head_art: Sprite2D
var _visual_time := 0.0
var _current_layer_index := 0
signal sprint_changed(active: bool, ratio: float)


func _ready() -> void:
	var asset_library := get_node_or_null("/root/AssetLibrary")
	# Light, particles and state overlays are generated in code so their pixel
	# language stays consistent even when optional UI/VFX art is replaced.
	local_light.texture = _create_radial_light_texture(128)
	if asset_library != null:
		var head_texture: Texture2D = asset_library.get_texture(&"sprout_head_neutral.png")
		if head_texture != null:
			_head_art = Sprite2D.new()
			_head_art.name = "HeadArt"
			_head_art.texture = head_texture
			_head_art.position = Vector2(0.0, -4.0)
			_head_art.z_index = 2
			var extent := maxf(head_texture.get_size().x, head_texture.get_size().y)
			_head_art.scale = Vector2.ONE * (48.0 / maxf(extent, 1.0))
			add_child(_head_art)
			_using_head_art = true
	var trail_texture: Texture2D = asset_library.get_texture(&"sprout_trail_neutral.png") if asset_library != null else null
	if trail_texture != null:
		trail.texture = trail_texture
		trail.width = 22.0
	trail.clear_points()
	trail.add_point(global_position)
	last_trail_point = global_position
	sprint_stamina = sprint_capacity
	var effects := get_node_or_null("/root/ItemEffectDirector")
	if effects != null:
		effects.set_player(self)
		effects.effect_changed.connect(func(_effect_id: StringName, _active: bool) -> void: refresh_effect_parameters())
	queue_redraw()


func _physics_process(delta: float) -> void:
	_visual_time += delta
	var level := get_parent()
	if level != null and level.has_method("get_layer_index_for_position"):
		_current_layer_index = clampi(int(level.get_layer_index_for_position(global_position)), 0, LAYER_PARTICLE_COLORS.size() - 1)
	_hard_collision_cooldown = maxf(_hard_collision_cooldown - delta, 0.0)
	var direction := Vector2.ZERO
	if input_enabled:
		direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	var effects := get_node_or_null("/root/ItemEffectDirector")
	var sprint_requested := input_enabled and not direction.is_zero_approx() and InputMap.has_action(&"sprint") and Input.is_action_pressed(&"sprint")
	var sprint_allowed: bool = _sprint_locks.is_empty() and (effects == null or not effects.has_method("is_sprint_allowed") or effects.is_sprint_allowed())
	var capacity := sprint_capacity
	if effects != null and effects.has_method("get_sprint_capacity_bonus"):
		capacity += float(effects.get_sprint_capacity_bonus())
	sprint_stamina = clampf(sprint_stamina, 0.0, capacity)
	var sprint_active: bool = sprint_requested and sprint_allowed and sprint_stamina > 0.02
	if sprint_active:
		sprint_stamina = maxf(sprint_stamina - delta, 0.0)
		_sprint_regen_delay_left = sprint_regen_delay
	else:
		_sprint_regen_delay_left = maxf(_sprint_regen_delay_left - delta, 0.0)
		if _sprint_regen_delay_left <= 0.0:
			var regen_multiplier := 1.0
			if effects != null and effects.has_method("get_sprint_regen_multiplier"):
				regen_multiplier = float(effects.get_sprint_regen_multiplier())
			sprint_stamina = minf(sprint_stamina + delta / maxf(sprint_regen_time, 0.01) * capacity * regen_multiplier, capacity)
	if sprint_active != is_sprinting_now:
		is_sprinting_now = sprint_active
		sprint_changed.emit(is_sprinting_now, get_sprint_ratio())
	var speed := max_speed
	if sprint_active:
		speed = sprint_speed
		if effects != null and effects.has_method("get_sprint_speed_multiplier"):
			speed *= float(effects.get_sprint_speed_multiplier())
	var acceleration_multiplier := 1.0
	if effects != null and effects.has_method("get_acceleration_multiplier"):
		acceleration_multiplier = float(effects.get_acceleration_multiplier())
	var target_velocity := direction * speed * _combined_speed_multiplier()
	var rate := acceleration * acceleration_multiplier if not direction.is_zero_approx() else deceleration
	velocity = velocity.move_toward(target_velocity, rate * delta)

	var previous_position := global_position
	var impact_speed := velocity.length()
	move_and_slide()
	_handle_hard_collisions(impact_speed)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.add_distance(previous_position.distance_to(global_position))
	_update_trail()
	if velocity.length_squared() > 16.0 or not statuses.is_empty() or visual_stage > 0 or not _effect_visual_state.is_empty():
		queue_redraw()


func _draw() -> void:
	# 正式芽尖素材存在时只绘制状态反馈，缺失时保留完整程序占位造型。
	if not _using_head_art:
		var body_color := Color(0.36, 0.07, 0.58)
		var head_color := Color(0.72, 0.27, 0.96)
		if statuses.has(&"frost"):
			body_color = Color(0.25, 0.51, 0.72)
			head_color = Color(0.63, 0.87, 1.0)
		elif visual_route == &"milk" and visual_stage > 0:
			body_color = Color(0.72, 0.58, 0.24)
			head_color = Color(1.0, 0.91, 0.56)
		elif visual_route == &"eldritch" and visual_stage > 0:
			body_color = Color(0.16, 0.015, 0.24)
			head_color = Color(0.50, 0.08, 0.70)
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
	if visual_route == &"eldritch":
		for index in range(mini(visual_stage, 3)):
			var eye_position := Vector2(-9.0 + index * 9.0, 5.0)
			draw_circle(eye_position, 3.5, Color(0.96, 0.66, 1.0))
			draw_circle(eye_position, 1.5, Color(0.06, 0.01, 0.08))
	if is_sprinting_now:
		var sprint_color := Color(1.0, 0.84, 0.32, 0.85)
		draw_arc(Vector2.ZERO, 28.0, -2.55, -0.60, 16, sprint_color, 3.0)
	if bool(_effect_visual_state.get("frost_immunity", false)):
		draw_arc(Vector2.ZERO, 23.0, 0.25, 2.85, 16, Color(0.52, 0.88, 1.0, 0.72), 2.0)
	_draw_pixel_particles()


func _draw_pixel_particles() -> void:
	var active := velocity.length_squared() > 64.0 or not statuses.is_empty() or visual_stage > 0 or not _effect_visual_state.is_empty()
	if not active:
		return
	var color: Color = LAYER_PARTICLE_COLORS[_current_layer_index]
	if statuses.has(&"frost") or bool(_effect_visual_state.get("frost_immunity", false)):
		color = color.lerp(Color(0.68, 0.91, 1.0), 0.68)
	elif visual_route == &"milk" and visual_stage > 0:
		color = color.lerp(Color(1.0, 0.86, 0.38), 0.68)
	elif visual_route == &"eldritch" and visual_stage > 0:
		color = color.lerp(Color(0.72, 0.20, 0.88), 0.68)
	color.a = 0.80
	var particle_count := 12 if is_sprinting_now else 8
	var move_direction := velocity.normalized()
	var side_direction := Vector2(-move_direction.y, move_direction.x)
	for index in range(particle_count):
		var phase := fmod(_visual_time * (0.8 + index * 0.07) + index * 0.73, 1.0)
		var at := Vector2.ZERO
		if velocity.length_squared() > 64.0:
			var spread := sin(float(index) * 2.4 + _visual_time * 5.0) * (8.0 + phase * 9.0)
			at = -move_direction * (20.0 + phase * (46.0 if is_sprinting_now else 30.0)) + side_direction * spread
		else:
			var angle := TAU * float(index) / float(particle_count) + _visual_time * (0.35 if index % 2 == 0 else -0.28)
			at = Vector2.RIGHT.rotated(angle) * (22.0 + phase * 18.0) + Vector2(0, phase * 8.0)
		at = at.snapped(Vector2(2, 2))
		# Bigger stepped pixels and a bright core keep the trail readable at the
		# camera's gameplay scale. Every layer still owns its distinct hue.
		var pixel_size := 10.0 if index % 3 == 0 else 7.0
		var alpha := color.a * (1.0 - phase * 0.72)
		draw_rect(Rect2(at - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), Color(color, alpha))
		if index % 2 == 0:
			var core_size := 3.0 if not is_sprinting_now else 4.0
			draw_rect(Rect2(at - Vector2.ONE * core_size * 0.5, Vector2.ONE * core_size), Color(color.lightened(0.34), minf(alpha + 0.18, 1.0)))


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		is_sprinting_now = false
		sprint_changed.emit(false, get_sprint_ratio())


func set_sprint_lock(source: StringName, locked: bool) -> void:
	if source.is_empty():
		return
	if locked:
		_sprint_locks[source] = true
	else:
		_sprint_locks.erase(source)
	if not _sprint_locks.is_empty() and is_sprinting_now:
		is_sprinting_now = false
		sprint_changed.emit(false, get_sprint_ratio())


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


func is_sprinting() -> bool:
	return is_sprinting_now


func get_sprint_ratio() -> float:
	var effects := get_node_or_null("/root/ItemEffectDirector")
	var capacity := sprint_capacity
	if effects != null and effects.has_method("get_sprint_capacity_bonus"):
		capacity += float(effects.get_sprint_capacity_bonus())
	return clampf(sprint_stamina / maxf(capacity, 0.01), 0.0, 1.0)


func set_effect_visual_state(state: Dictionary) -> void:
	_effect_visual_state = state.duplicate(true)
	_update_status_visuals()


func refresh_effect_parameters() -> void:
	_update_status_visuals()
	queue_redraw()


func set_camera_limits(bounds: Rect2) -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = roundi(bounds.position.x)
	camera.limit_top = roundi(bounds.position.y)
	camera.limit_right = roundi(bounds.end.x)
	camera.limit_bottom = roundi(bounds.end.y)


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
		game_state.add_stat(&"noise", 1)
		var collider := get_slide_collision(0).get_collider()
		if collider is Node and collider.name == &"TitanBottle":
			game_state.increment_counter(&"bottle_hit_count")
			game_state.add_stat(&"destruction", 1)
		elif collider is Node and collider.name == &"FinalLid":
			game_state.increment_counter(&"lid_hit_count")
			game_state.add_stat(&"destruction", 1)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"hard_hit")
	local_light.energy = 3.4
	create_tween().tween_property(local_light, "energy", 2.4, 0.22)


func _update_status_visuals() -> void:
	if not is_inside_tree():
		return
	if statuses.has(&"frost"):
		trail.default_color = Color(0.55, 0.82, 1.0)
		local_light.color = Color(0.62, 0.84, 1.0)
	elif visual_route == &"milk" and visual_stage > 0:
		trail.default_color = Color(1.0, 0.88, 0.48)
		local_light.color = Color(1.0, 0.86, 0.58)
	elif visual_route == &"eldritch" and visual_stage > 0:
		trail.default_color = Color(0.40, 0.03, 0.58)
		local_light.color = Color(0.68, 0.18, 0.84)
	else:
		trail.default_color = Color(0.52, 0.16, 0.84)
		local_light.color = Color(0.72, 0.46, 1.0)
	var effects := get_node_or_null("/root/ItemEffectDirector")
	var light_multiplier := 1.0
	if effects != null and effects.has_method("get_light_multiplier"):
		light_multiplier = float(effects.get_light_multiplier())
	local_light.energy = 2.4 * light_multiplier
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
