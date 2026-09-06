extends StaticBody2D

const PIXEL_BURST := preload("res://scenes/gameplay/world_pixel_burst.gd")

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
var art_visual: Sprite2D
var _state_textures: Array[Texture2D] = []


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
	var asset_library := get_node_or_null("/root/AssetLibrary")
	if asset_library != null:
		var texture_names: Array = [
			"env_final_lid_intact.png", "env_final_lid_strain_01.png", "env_final_lid_strain_02.png", "env_final_lid_strain_03.png", "env_final_lid_open.png"
		] if is_final_barrier else [
			"env_plastic_film_intact.png", "env_plastic_film_stretch_01.png", "env_plastic_film_stretch_02.png",
			"env_plastic_film_crack_01.png", "env_plastic_film_crack_02.png", "env_plastic_film_crack_03.png"
		]
		for file_name in texture_names:
			var state_texture: Texture2D = asset_library.get_texture(StringName(file_name))
			if state_texture != null:
				_state_textures.append(state_texture)
		var texture: Texture2D = _state_textures[0] if not _state_textures.is_empty() else null
		if texture != null:
			art_visual = Sprite2D.new()
			art_visual.name = "BarrierArt"
			art_visual.texture = texture
			art_visual.z_index = 4
			_fit_art_texture(texture, 1.0)
			art_visual.modulate = Color(1.0, 1.0, 1.0, barrier_color.a)
			add_child(art_visual)


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
	if is_instance_valid(art_visual):
		if _state_textures.size() > 1:
			var visible_state_count := _state_textures.size() - 1
			var state_index := clampi(floori(ratio * float(visible_state_count)), 0, visible_state_count - 1)
			art_visual.texture = _state_textures[state_index]
		_fit_art_texture(art_visual.texture, lerpf(1.0, 0.35, ratio))
		art_visual.modulate.a = lerpf(barrier_color.a, 1.0, ratio)
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
	var burst := PIXEL_BURST.new()
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.configure(barrier_color, 26, 245.0)
	prompt.visible = false
	solid_collision.set_deferred("disabled", true)
	sensor.set_deferred("monitoring", false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "position", Vector2(0.0, -90.0), 0.32)
	tween.tween_property(visual, "modulate:a", 0.0, 0.32)
	if is_instance_valid(art_visual):
		if not _state_textures.is_empty():
			art_visual.texture = _state_textures[_state_textures.size() - 1]
			_fit_art_texture(art_visual.texture, 1.0)
		tween.tween_property(art_visual, "position", Vector2(0.0, -90.0), 0.32)
		tween.tween_property(art_visual, "modulate:a", 0.0, 0.32)
	await tween.finished
	barrier_broken.emit(is_final_barrier)
	if not is_final_barrier:
		queue_free()


func _fit_art_texture(texture: Texture2D, height_multiplier: float) -> void:
	if not is_instance_valid(art_visual) or texture == null:
		return
	var texture_size := texture.get_size()
	art_visual.scale = Vector2(
		barrier_size.x / maxf(texture_size.x, 1.0),
		barrier_size.y / maxf(texture_size.y, 1.0) * height_multiplier
	)


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
