extends Area2D

@export var counter_id: StringName = &"thermostat_level"
@export var target_value: int = 7
@export var prompt_text: String = "轻按 E 调整"
@export var complete_flag: StringName = &""
@export var console_color := Color(0.42, 0.78, 1.0)

var player_inside := false
var _prompt: Label
var _art: Sprite2D
var _dial_textures: Array[Texture2D] = []


func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 16
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 82.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_prompt = Label.new()
	_prompt.position = Vector2(-180, 76)
	_prompt.size = Vector2(360, 52)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.visible = false
	add_child(_prompt)
	_load_dial_art()
	_update_prompt()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if player_inside and event.is_action_pressed(&"interact"):
		increment()
		get_viewport().set_input_as_handled()


func increment() -> int:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return 0
	var current: int = int(game_state.get_counter(counter_id))
	if current < target_value:
		game_state.increment_counter(counter_id)
		current += 1
		get_node("/root/AudioManager").play_sfx(&"thermostat_click")
	if current >= target_value and not complete_flag.is_empty():
		game_state.set_flag(complete_flag)
	_update_prompt()
	queue_redraw()
	return current


func _draw() -> void:
	if is_instance_valid(_art):
		return
	draw_circle(Vector2.ZERO, 42.0, Color(console_color, 0.32))
	draw_arc(Vector2.ZERO, 30.0, -PI * 0.75, PI * 0.75, 18, console_color, 7.0)
	var game_state := get_node_or_null("/root/GameState")
	var value: int = int(game_state.get_counter(counter_id)) if game_state != null else 0
	var angle := lerpf(-PI * 0.75, PI * 0.75, float(value) / float(maxi(target_value, 1)))
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(angle) * 27.0, Color.WHITE, 4.0)


func _update_prompt() -> void:
	if _prompt == null:
		return
	var game_state := get_node_or_null("/root/GameState")
	var value: int = int(game_state.get_counter(counter_id)) if game_state != null else 0
	_prompt.text = "%s  %d/%d" % [prompt_text, value, target_value]
	_update_dial_art(value)


func _load_dial_art() -> void:
	var library := get_node_or_null("/root/AssetLibrary")
	if library == null:
		return
	for index in range(1, 9):
		var names: Array = ["env_thermostat_dial_%02d.png" % index]
		if index == 7:
			names.append("env_thermostat_dial_017png.png")
		var texture: Texture2D = library.get_first_texture(names)
		if texture != null:
			_dial_textures.append(texture)
	if _dial_textures.is_empty():
		return
	_art = Sprite2D.new()
	_art.name = "ThermostatArt"
	_art.z_index = 2
	add_child(_art)
	_update_dial_art(0)


func _update_dial_art(value: int) -> void:
	if not is_instance_valid(_art) or _dial_textures.is_empty():
		return
	_art.texture = _dial_textures[clampi(value, 0, _dial_textures.size() - 1)]
	var extent := maxf(_art.texture.get_size().x, _art.texture.get_size().y)
	_art.scale = Vector2.ONE * (112.0 / maxf(extent, 1.0))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		player_inside = true
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		player_inside = false
		_prompt.visible = false
