extends Area2D

const PIXEL_BURST := preload("res://scenes/gameplay/world_pixel_burst.gd")

signal collected(item_id: StringName)

@export var item_id: StringName = &"sample_pickup"
@export var display_name_myth: String = "遗落的微光"
@export var display_name_real: String = "未知物品"
@export var narrative_text_id: StringName = &"pickup_sample"
@export var counter_id: StringName = &""
@export var stat_id: StringName = &""
@export var stat_amount: int = 0
@export var pickup_color := Color(0.96, 0.75, 0.30)
@export var pickup_radius: float = 18.0

var is_collected: bool = false
var _using_art := false
var _art: Sprite2D
var _pulse_textures: Array[Texture2D] = []
var _pulse_time := 0.0


func _ready() -> void:
	add_to_group(&"pickup")
	collision_layer = 8
	collision_mask = 2
	_setup_art()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = pickup_radius + 10.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.item_collected.connect(_on_global_item_collected)
		if game_state.has_item(item_id):
			_retire_owned_pickup()
	queue_redraw()


func _process(delta: float) -> void:
	if _pulse_textures.size() <= 1 or not is_instance_valid(_art):
		return
	_pulse_time += delta
	var frame := int(_pulse_time / 0.48) % _pulse_textures.size()
	_art.texture = _pulse_textures[frame]


func _draw() -> void:
	if _using_art:
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -pickup_radius), Vector2(pickup_radius * 0.72, 0),
		Vector2(0, pickup_radius), Vector2(-pickup_radius * 0.72, 0)
	]), pickup_color)


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
	_art.name = "PickupArt"
	_art.texture = texture
	_art.z_index = 2
	var extent := maxf(texture.get_size().x, texture.get_size().y)
	_art.scale = Vector2.ONE * (pickup_radius * 2.1 / maxf(extent, 1.0))
	add_child(_art)
	_using_art = true
	_pulse_textures.append(texture)
	for alternate_name in _alternate_texture_names(item_id):
		var alternate: Texture2D = asset_library.get_texture(StringName(alternate_name))
		if alternate != null and alternate not in _pulse_textures:
			_pulse_textures.append(alternate)


func _alternate_texture_names(id: StringName) -> Array[String]:
	match id:
		&"corrupt_eye": return ["item_eye_of_decay_glow.png"]
		&"scarlet_ointment": return ["item_scarlet_ointment_flow.png"]
		&"sleeping_stone": return ["item_sleeping_stone_glow.png"]
	return []


func _texture_name_for_item(id: StringName) -> StringName:
	var key := str(id)
	if key == "corrupt_eye": return &"item_eye_of_decay_dormant.png"
	if key == "scarlet_ointment": return &"item_scarlet_ointment_still.png"
	if key == "frozen_heart": return &"item_heart_of_eternal_frost.png"
	if key == "golden_scale": return &"item_golden_cheese_rind.png"
	if key == "magnet_core": return &"item_magnet_core_intact.png"
	if key == "conductive_water": return &"item_conductive_condensation.png"
	if key == "aluminum_foil": return &"item_aluminum_foil_01.png"
	if key == "date_tablet": return &"clue_expiry_label_clean.png"
	if key == "flowerpot_receipt": return &"clue_flowerpot_plan_receipt.png"
	if key == "door_soil": return &"item_door_soil_01.png"
	if key == "compost_label": return &"clue_compostable_label_intact.png"
	if key == "barcode_fragment": return &"item_barcode_fragment_01.png"
	if key == "sale_tag_1": return &"item_sale_tag_a.png"
	if key == "sale_tag_2": return &"item_sale_tag_b.png"
	if key == "sale_tag_3": return &"item_sale_tag_c.png"
	if key == "milk_drop_1": return &"item_milk_drop_01.png"
	if key == "milk_drop_2": return &"item_milk_drop_02.png"
	if key == "milk_drop_3": return &"item_milk_drop_03.png"
	if key == "clean_water_1": return &"item_clean_condensation_01.png"
	if key == "clean_water_2": return &"item_clean_condensation_02.png"
	if key == "clean_water_3": return &"item_clean_condensation_03.png"
	if key == "frost_crystal_1": return &"item_frost_crystal_01.png"
	if key == "frost_crystal_2": return &"item_frost_crystal_02.png"
	if key == "frost_crystal_3": return &"item_frost_crystal_03.png"
	if key == "frost_crystal_4": return &"item_frost_crystal_04.png"
	if key == "sleeping_stone": return &"item_sleeping_stone_dormant.png"
	if key == "hongsan_label": return &"clue_hongshan_caitai_label_front.png"
	if key == "yellow_petals": return &"item_caitai_petals_01.png"
	if key == "clean_nutrient": return &"env_clean_compost_empty.png"
	if key == "black_water_core": return &"env_slime_pool_01.png"
	if key.begins_with("nutrient_"):
		var nutrient_index := clampi(key.get_slice("_", 1).to_int(), 1, 5)
		return StringName("item_nutrient_clump_%02d.png" % nutrient_index)
	if key.begins_with("sprout_nodule_"):
		var nodule_index := clampi(key.get_slice("_", 2).to_int(), 1, 3)
		return StringName("item_sprout_nodule_%s.png" % ["a", "b", "c"][nodule_index - 1])
	return &""


func collect() -> bool:
	if is_collected:
		return false
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return false
	is_collected = true
	if not game_state.collect_item(item_id):
		# A test harness or another trigger may already have granted this unique item.
		# Remove the world copy instead of leaving a visible, apparently broken pickup.
		_retire_owned_pickup()
		return true
	if not counter_id.is_empty():
		game_state.increment_counter(counter_id)
	if not stat_id.is_empty() and stat_amount != 0:
		game_state.add_stat(stat_id, stat_amount)
	var narrative := get_node_or_null("/root/NarrativeManager")
	if narrative != null and not narrative_text_id.is_empty():
		narrative.request_text(narrative_text_id)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"pickup")
	_spawn_pickup_burst()
	collected.emit(item_id)
	monitoring = false
	visible = false
	queue_free()
	return true


func _spawn_pickup_burst() -> void:
	var burst := PIXEL_BURST.new()
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.configure(pickup_color, 18, 165.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		collect()


func _on_global_item_collected(collected_id: StringName) -> void:
	if collected_id == item_id and not is_collected:
		is_collected = true
		_retire_owned_pickup()


func _retire_owned_pickup() -> void:
	monitoring = false
	monitorable = false
	visible = false
	call_deferred("queue_free")
