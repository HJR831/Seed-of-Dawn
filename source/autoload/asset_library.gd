extends Node

## Runtime asset access for the flat program/image and program/audio imports.
## Missing files intentionally return null so gameplay can keep its procedural fallback.

const IMAGE_ROOT := "res://assets/image/"
const AUDIO_ROOT := "res://assets/audio/"

const ITEM_TEXTURES := {
	&"date_tablet": &"clue_expiry_label_clean.png",
	&"corrupt_eye": &"item_eye_of_decay_dormant.png",
	&"scarlet_ointment": &"item_scarlet_ointment_still.png",
	&"frozen_heart": &"item_heart_of_eternal_frost.png",
	&"golden_scale": &"item_golden_cheese_rind.png",
	&"magnet_core": &"item_magnet_core_intact.png",
	&"conductive_water": &"item_conductive_condensation.png",
	&"aluminum_foil": &"item_aluminum_foil_01.png",
	&"flowerpot_receipt": &"clue_flowerpot_plan_receipt.png",
	&"door_soil": &"item_door_soil_01.png",
	&"compost_label": &"clue_compostable_label_intact.png",
	&"barcode_fragment": &"item_barcode_fragment_01.png",
	&"sale_tag_1": &"item_sale_tag_a.png",
	&"sale_tag_2": &"item_sale_tag_b.png",
	&"sale_tag_3": &"item_sale_tag_c.png",
	&"milk_drop_1": &"item_milk_drop_01.png",
	&"milk_drop_2": &"item_milk_drop_02.png",
	&"milk_drop_3": &"item_milk_drop_03.png",
	&"clean_water_1": &"item_clean_condensation_01.png",
	&"clean_water_2": &"item_clean_condensation_02.png",
	&"clean_water_3": &"item_clean_condensation_03.png",
	&"sleeping_stone": &"item_sleeping_stone_dormant.png",
	&"hongsan_label": &"clue_hongshan_caitai_label_front.png",
	&"yellow_petals": &"item_caitai_petals_01.png",
	&"clean_nutrient": &"env_clean_compost_empty.png",
	&"black_water_core": &"env_slime_pool_01.png",
}

var _texture_cache: Dictionary = {}
var _audio_cache: Dictionary = {}


func get_texture(file_name: StringName) -> Texture2D:
	var key := str(file_name)
	if key.is_empty():
		return null
	if _texture_cache.has(key):
		return _texture_cache[key] as Texture2D
	var path := IMAGE_ROOT + key
	if not ResourceLoader.exists(path):
		_texture_cache[key] = null
		return null
	var texture := load(path) as Texture2D
	_texture_cache[key] = texture
	return texture


func get_first_texture(file_names: Array) -> Texture2D:
	for raw_name in file_names:
		var texture := get_texture(StringName(str(raw_name)))
		if texture != null:
			return texture
	return null


func get_item_texture(item_id: StringName) -> Texture2D:
	var direct: StringName = ITEM_TEXTURES.get(item_id, &"")
	if not direct.is_empty():
		var texture := get_texture(direct)
		if texture != null:
			return texture
	var key := str(item_id)
	if key.begins_with("nutrient_"):
		return get_texture(StringName("item_nutrient_clump_%02d.png" % clampi(key.get_slice("_", 1).to_int(), 1, 5)))
	if key.begins_with("frost_crystal_"):
		return get_texture(StringName("item_frost_crystal_%02d.png" % clampi(key.get_slice("_", 2).to_int(), 1, 4)))
	if key.begins_with("sprout_nodule_"):
		return get_texture(StringName("item_sprout_nodule_%s.png" % ["a", "b", "c"][clampi(key.get_slice("_", 2).to_int(), 1, 3) - 1]))
	return null


func get_ending_texture(ending_id: StringName) -> Texture2D:
	var parts := str(ending_id).split("_")
	if parts.size() >= 2 and parts[1].is_valid_int():
		var index := clampi(int(parts[1]), 1, 12)
		var texture := get_texture(StringName("ending_%02d_full.png" % index))
		if texture != null:
			return texture
		# A few delivered assets are older single-scene illustrations. They are
		# useful as a better fallback than a blank card until the full image arrives.
		var legacy_names := [
			"ending_%02d_toxic_potato.png" % index,
			"ending_%02d_city_fridge_eye.png" % index,
			"ending_%02d_eldritch_tentacles.png" % index,
		]
		return get_first_texture(legacy_names)
	return null


func get_audio(folder: StringName, file_name: StringName) -> AudioStream:
	var key := "%s/%s" % [str(folder), str(file_name)]
	if _audio_cache.has(key):
		return _audio_cache[key] as AudioStream
	var path := "%s%s/%s" % [AUDIO_ROOT, str(folder), str(file_name)]
	if not ResourceLoader.exists(path):
		_audio_cache[key] = null
		return null
	var stream := load(path) as AudioStream
	_audio_cache[key] = stream
	return stream


func has_texture(file_name: StringName) -> bool:
	return get_texture(file_name) != null
