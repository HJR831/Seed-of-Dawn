extends Area2D

signal ending_requested(ending_id: StringName)

const EndingResolverScript := preload("res://systems/ending_resolver.gd")
const PIXEL_UI := preload("res://scenes/ui/pixel_ui_theme.gd")

@export var trigger_id: StringName = &"light_switch_hold"
@export_enum("hold", "idle", "hold_down") var activation_mode: String = "hold"
@export var required_seconds: float = 7.0
@export var area_size := Vector2(220.0, 180.0)
@export var prompt_text: String = "长按 E 扼住伪日"
@export var entrance_color := Color(0.92, 0.94, 1.0, 0.75)

var player_inside: bool = false
var _elapsed: float = 0.0
var _resolved: bool = false
var _cooldown: float = 0.0
var _prompt: Label
var _bar: ProgressBar
var _player: CharacterBody2D
var _art: Sprite2D


func _ready() -> void:
	add_to_group(&"material_point")
	collision_layer = 16
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = area_size
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_art()
	_build_ui()
	queue_redraw()


func _process(delta: float) -> void:
	if _resolved or not player_inside:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	var active := false
	if activation_mode == "hold":
		active = Input.is_action_pressed(&"interact")
	elif activation_mode == "hold_down":
		active = Input.is_action_pressed(&"move_down")
	elif is_instance_valid(_player):
		active = _player.velocity.length() < 5.0 and Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down").is_zero_approx()
	if active:
		var required := required_seconds
		var effects := get_node_or_null("/root/ItemEffectDirector")
		if effects != null and effects.has_method("get_interaction_time_multiplier"):
			required *= float(effects.get_interaction_time_multiplier(trigger_id))
		_elapsed = minf(_elapsed + delta, required)
	else:
		_elapsed = maxf(_elapsed - delta * 2.0, 0.0)
	var display_required := required_seconds
	var display_effects := get_node_or_null("/root/ItemEffectDirector")
	if display_effects != null and display_effects.has_method("get_interaction_time_multiplier"):
		display_required *= float(display_effects.get_interaction_time_multiplier(trigger_id))
	_bar.value = _elapsed / maxf(display_required, 0.01) * 100.0
	if _elapsed >= display_required and _cooldown <= 0.0:
		_try_resolve()


func _draw() -> void:
	# The entrance art itself identifies the interaction point. The collision
	# area stays active but no extra rectangle is drawn around it.
	pass


func _setup_art() -> void:
	var library := get_node_or_null("/root/AssetLibrary")
	if library == null:
		return
	var texture_name := &""
	match trigger_id:
		&"light_switch_hold": texture_name = &"env_fridge_light_off.png"
		&"dragon_shrine_idle": texture_name = &"env_dragon_yogurt_art.png"
		&"root_network_complete": texture_name = &"env_root_node_connected.png"
		&"barcode_terminal": texture_name = &"clue_supermarket_sale_tag.png"
		&"freezer_alcove": texture_name = &"env_freezer_recess.png"
		&"temperature_probe": texture_name = &"env_thermostat_circuit.png"
		&"hongsan_root_link": texture_name = &"npc_caitai_root_revived.png"
		&"mother_soil": texture_name = &"env_mother_potato.png"
		&"self_prune": texture_name = &"clue_old_sprout_withered.png"
		&"forced_cleanup": texture_name = &"env_trash_bag_open.png"
	if texture_name.is_empty():
		return
	var texture: Texture2D = library.get_texture(texture_name)
	if texture == null:
		return
	_art = Sprite2D.new()
	_art.name = "EntranceArt"
	_art.texture = texture
	_art.z_index = 2
	var extent := maxf(texture.get_size().x, texture.get_size().y)
	_art.scale = Vector2.ONE * (minf(area_size.x, area_size.y) * 0.58 / maxf(extent, 1.0))
	add_child(_art)


func _try_resolve() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var result: Dictionary = EndingResolverScript.request_ending(trigger_id, game_state.make_snapshot())
	if bool(result.get("matched", false)):
		_resolved = true
		_set_sprint_lock(false)
		_prompt.visible = false
		_bar.visible = false
		ending_requested.emit(result.get("ending_id", &""))
		return
	var missing: Array = result.get("missing", [])
	_prompt.text = str(missing[0]) if not missing.is_empty() else "仪式没有回应"
	_prompt.visible = true
	_elapsed = 0.0
	_bar.value = 0.0
	_cooldown = 2.0
	game_state.set_flag(&"ending_attempt_failed")
	game_state.increment_counter(&"ending_attempt_failed_count")


func _build_ui() -> void:
	_prompt = Label.new()
	_prompt.position = Vector2(-230, area_size.y * 0.5 + 18)
	_prompt.size = Vector2(460, 58)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.add_theme_font_size_override("font_size", 19)
	_prompt.text = prompt_text
	_prompt.visible = false
	_prompt.z_index = 15
	add_child(_prompt)
	_bar = ProgressBar.new()
	_bar.position = Vector2(-120, area_size.y * 0.5 + 80)
	_bar.size = Vector2(240, 14)
	_bar.show_percentage = false
	PIXEL_UI.apply_progress(_bar, entrance_color)
	_bar.visible = false
	_bar.z_index = 15
	add_child(_bar)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	player_inside = true
	_player = body as CharacterBody2D
	_set_sprint_lock(true)
	_prompt.text = prompt_text
	_prompt.visible = true
	_bar.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body != _player:
		return
	player_inside = false
	_set_sprint_lock(false)
	_player = null
	_elapsed = 0.0
	_prompt.visible = false
	_bar.visible = false
	_bar.value = 0.0


func _set_sprint_lock(locked: bool) -> void:
	if is_instance_valid(_player) and _player.has_method("set_sprint_lock"):
		_player.set_sprint_lock(&"ending_entrance", locked)
