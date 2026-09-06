extends Area2D

signal interaction_completed(item_id: StringName, action_id: StringName)

@export var item_id: StringName = &"sleeping_sprout"
@export var display_name_myth: String = "沉睡的先驱者"
@export var display_name_real: String = "蔫软的菜叶"
@export var interaction_type: StringName = &"living"
@export var short_action: StringName = &"nurture"
@export var hold_action: StringName = &"devour"
@export var state_delta: Dictionary = {}
@export var narrative_text_id: StringName = &"interact_sample"
@export var required_item: StringName = &""
@export var required_item_action: StringName = &""
@export var required_counter_id: StringName = &""
@export var required_counter_minimum: int = 0
@export var required_counter_action: StringName = &""
@export var completion_flag: StringName = &""
@export var completion_action: StringName = &""
@export var completion_counter_id: StringName = &""
@export var completion_counter_amount: int = 0
@export var consumed_after_use: bool = true
@export var short_press_seconds: float = 0.35
@export var hold_seconds: float = 0.8
@export var interaction_radius: float = 72.0
@export var object_color := Color(0.42, 0.66, 0.30)
@export var prompt_text: String = "轻按 E 帮助  /  长按 E 吸收"

var player_inside: bool = false
var is_completed: bool = false
var _press_seconds: float = 0.0
var _tracking_press: bool = false
var _hold_completed: bool = false
var _prompt: Label
var _bar: ProgressBar
var _player: Node
var _using_art := false
var _art: Sprite2D


func _ready() -> void:
	add_to_group(&"interactable")
	collision_layer = 8
	collision_mask = 2
	_setup_art()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = interaction_radius
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_prompt()
	queue_redraw()


func _process(delta: float) -> void:
	if is_completed or not player_inside:
		return
	if Input.is_action_just_pressed(&"interact"):
		_tracking_press = true
		_set_sprint_lock(true)
		_hold_completed = false
		_press_seconds = 0.0
	if _tracking_press and Input.is_action_pressed(&"interact"):
		_press_seconds += delta
		_bar.value = clampf(_press_seconds / maxf(hold_seconds, 0.01) * 100.0, 0.0, 100.0)
		if _press_seconds >= hold_seconds and not _hold_completed:
			_hold_completed = perform_hold_action()
			_tracking_press = false
			_set_sprint_lock(false)
			_press_seconds = 0.0
			_bar.value = 0.0
	if _tracking_press and Input.is_action_just_released(&"interact"):
		# Any release before the hold threshold is a short press. The old
		# short_press_seconds..hold_seconds gap silently discarded input.
		if not _hold_completed:
			perform_short_action()
		_tracking_press = false
		_set_sprint_lock(false)
		_press_seconds = 0.0
		_bar.value = 0.0


func _draw() -> void:
	if _using_art:
		return
	draw_circle(Vector2.ZERO, 19.0, object_color)
	draw_line(Vector2(-12, 3), Vector2(12, -5), Color(0.84, 0.96, 0.72), 4.0)


func _setup_art() -> void:
	var asset_library := get_node_or_null("/root/AssetLibrary")
	if asset_library == null:
		return
	var texture_name := _texture_name_for_item(item_id)
	if texture_name.is_empty():
		return
	var texture: Texture2D = asset_library.get_texture(texture_name)
	if texture == null:
		return
	_art = Sprite2D.new()
	_art.name = "InteractableArt"
	_art.texture = texture
	_art.z_index = 2
	var extent := maxf(texture.get_size().x, texture.get_size().y)
	_art.scale = Vector2.ONE * (58.0 / maxf(extent, 1.0))
	add_child(_art)
	_using_art = true


func _texture_name_for_item(id: StringName) -> StringName:
	match id:
		&"bottle_lever": return &"env_hot_sauce_bottle.png"
		&"companion_onion": return &"npc_onion_sleep.png"
		&"companion_garlic": return &"npc_garlic_sleep.png"
		&"companion_ginger": return &"npc_ginger_sleep.png"
		&"hongsan_root": return &"npc_caitai_root_sleep.png"
		&"planting_site_1", &"planting_site_2", &"planting_site_3": return &"env_clean_compost_empty.png"
		&"light_switch": return &"env_fridge_light_off.png"
		&"dragon_shrine": return &"env_dragon_yogurt_art.png"
		&"thermostat": return &"env_thermostat_dial_01.png"
		&"electric_sequence": return &"env_electric_node_dark.png"
		&"mother_soil": return &"env_mother_potato.png"
	return &""


func perform_short_action() -> bool:
	return _complete_action(short_action)


func perform_hold_action() -> bool:
	return _complete_action(hold_action)


func _complete_action(action_id: StringName) -> bool:
	if is_completed:
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	if not required_item.is_empty() and _requirement_applies(required_item_action, action_id) and not game_state.has_item(required_item):
		var narrative := get_node_or_null("/root/NarrativeManager")
		if narrative != null:
			narrative.request_text(&"interaction_missing_item")
		return false
	if not required_counter_id.is_empty() and _requirement_applies(required_counter_action, action_id) and game_state.get_counter(required_counter_id) < required_counter_minimum:
		var narrative := get_node_or_null("/root/NarrativeManager")
		if narrative != null:
			narrative.request_text(&"interaction_missing_item")
		return false
	match action_id:
		&"nurture", &"devour", &"noise", &"destruction", &"corruption":
			game_state.add_stat(action_id, int(state_delta.get(action_id, 1)))
		&"collect":
			game_state.collect_item(item_id)
		_:
			game_state.set_flag(action_id)
	if not completion_flag.is_empty() and (completion_action.is_empty() or completion_action == action_id):
		game_state.set_flag(completion_flag)
	if not completion_counter_id.is_empty() and completion_counter_amount != 0:
		game_state.increment_counter(completion_counter_id, completion_counter_amount)
	game_state.set_flag(StringName("interacted_%s" % item_id))
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null and not narrative_text_id.is_empty():
		narrative.request_text(narrative_text_id)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"interact_hold" if action_id == hold_action else &"interact_short")
	interaction_completed.emit(item_id, action_id)
	_apply_completed_art(action_id)
	is_completed = true
	_prompt.visible = false
	_bar.visible = false
	monitoring = false
	if consumed_after_use:
		modulate = Color(0.35, 0.35, 0.35, 0.35)
	else:
		modulate = Color(0.7, 0.85, 0.7, 1.0)
	return true


func _requirement_applies(required_action: StringName, action_id: StringName) -> bool:
	return required_action.is_empty() or required_action == action_id


func _apply_completed_art(action_id: StringName) -> void:
	if not is_instance_valid(_art):
		return
	var texture_name := &""
	match item_id:
		&"companion_onion": texture_name = &"npc_onion_sprout.png"
		&"companion_garlic": texture_name = &"npc_garlic_sprout.png"
		&"companion_ginger": texture_name = &"npc_ginger_sprout.png"
		&"hongsan_root": texture_name = &"npc_caitai_root_dry.png" if action_id == &"devour" else &"npc_caitai_root_revived.png"
		&"planting_site_1", &"planting_site_2", &"planting_site_3": texture_name = &"env_clean_compost_planted.png"
		&"light_switch": texture_name = &"env_fridge_light_on.png"
		&"electric_sequence": texture_name = &"env_electric_node_lit.png"
	if texture_name.is_empty():
		return
	var asset_library := get_node_or_null("/root/AssetLibrary")
	var texture: Texture2D = asset_library.get_texture(texture_name) if asset_library != null else null
	if texture != null:
		_art.texture = texture
		var extent := maxf(texture.get_size().x, texture.get_size().y)
		_art.scale = Vector2.ONE * (58.0 / maxf(extent, 1.0))


func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.position = Vector2(-180, 42)
	_prompt.size = Vector2(360, 32)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.text = prompt_text
	_prompt.visible = false
	_prompt.z_index = 12
	add_child(_prompt)
	_bar = ProgressBar.new()
	_bar.position = Vector2(-90, 76)
	_bar.size = Vector2(180, 12)
	_bar.show_percentage = false
	_bar.visible = false
	_bar.z_index = 12
	add_child(_bar)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and not is_completed:
		_player = body
		player_inside = true
		_prompt.visible = true
		_bar.visible = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_set_sprint_lock(false)
	_player = null
	player_inside = false
	_tracking_press = false
	_press_seconds = 0.0
	_prompt.visible = false
	_bar.visible = false
	_bar.value = 0.0


func _set_sprint_lock(locked: bool) -> void:
	if is_instance_valid(_player) and _player.has_method("set_sprint_lock"):
		_player.set_sprint_lock(&"long_interaction", locked)
