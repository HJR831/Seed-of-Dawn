extends Node

signal effect_changed(effect_id: StringName, active: bool)
signal effect_charge_changed(effect_id: StringName, amount: int)

const TEMPORARY_EFFECTS := {
	&"growth_burst": 4.0,
}

var active_effects: Dictionary = {}
var effect_charges: Dictionary = {}
var _effect_expiry: Dictionary = {}
var _current_hazards: Dictionary = {}
var _player: Node
var _still_seconds := 0.0
var sprint_noise: int = 0
var _sprint_noise_clock := 0.0


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.run_reset.connect(_on_run_reset)
		game_state.item_collected.connect(_on_item_collected)


func _process(delta: float) -> void:
	var expired_effects: Array[StringName] = []
	for effect_id in _effect_expiry.keys():
		_effect_expiry[effect_id] = float(_effect_expiry[effect_id]) - delta
		if float(_effect_expiry[effect_id]) <= 0.0:
			expired_effects.append(StringName(effect_id))
	for effect_id in expired_effects:
		_effect_expiry.erase(effect_id)
		_deactivate(effect_id)
	if is_instance_valid(_player) and _player is CharacterBody2D and _player.velocity.length() < 5.0:
		_still_seconds += delta
	else:
		_still_seconds = maxf(_still_seconds - delta * 2.0, 0.0)
	var noise_eligible: bool = is_instance_valid(_player) and _player.has_method("is_sprinting") and _player.is_sprinting() and has_effect(&"scarlet_resistance") and _current_hazards.has(&"sticky")
	if noise_eligible:
		_sprint_noise_clock += delta
		if _sprint_noise_clock >= 2.0:
			_sprint_noise_clock = 0.0
			sprint_noise += 1
	else:
		_sprint_noise_clock = 0.0


func set_player(player: Node) -> void:
	_player = player
	_apply_all_player_effects()


func activate_item_effect(item_id: StringName) -> void:
	if item_id.is_empty():
		return
	match item_id:
		&"corrupt_eye":
			_activate(&"eldritch_sight", {"label": "旧神视域", "summary": "扩大弱光轮廓与隐藏线索感知范围"})
			_activate(&"attention", {"label": "旧神注视", "summary": "附近隐藏线索可能发出低声提示"})
		&"scarlet_ointment":
			_activate(&"scarlet_resistance", {"label": "猩红抗性", "summary": "赤柱与黏液区域影响减弱；区域内疾跑会增加独立噪音值"})
		&"frozen_heart":
			_activate(&"frost_immunity", {"label": "霜冻免疫", "summary": "免疫冰霜区域减速与环境寒冷消耗"})
		&"golden_scale":
			_activate(&"sun_guidance", {"label": "日之引导", "summary": "局部光照扩大，已发现地标短暂闪烁"})
		&"sleeping_stone":
			_activate(&"stasis_breath", {"label": "静止呼吸", "summary": "静止后环境危险影响逐渐下降"})
		&"black_water_core":
			_activate(&"black_blood", {"label": "大陆黑血", "summary": "黑水与黏液减速降低，但腐化不可逆"})
		&"milk_drop_1":
			_activate(&"milk_capacity_1", {"label": "乳白容量 I", "summary": "疾跑容量小幅增加"})
		&"milk_drop_2":
			_activate(&"milk_acceleration", {"label": "乳白加速", "summary": "转向和加速度提高"})
		&"milk_drop_3":
			_activate(&"milk_recovery", {"label": "乳白恢复", "summary": "疾跑体力恢复加快"})
		&"clean_water_1", &"clean_water_2", &"clean_water_3":
			add_effect_charge(&"purity_charge", 1)
		&"date_tablet":
			_activate(&"time_echo", {"label": "时间回声", "summary": "下一次压缩机节拍会获得额外预告"})
		&"flowerpot_receipt":
			_activate(&"garden_memory", {"label": "花盆记忆", "summary": "靠近播种点时显示轮廓"})
		&"sale_tag_1":
			_activate(&"barcode_pulse", {"label": "条码脉冲", "summary": "靠近条码终端时获得短促提示"})
		&"sale_tag_2":
			_activate(&"barcode_sector", {"label": "条码扇区", "summary": "小地图显示条码路线所在扇区"})
		&"sale_tag_3":
			_activate(&"barcode_mastery", {"label": "条码熟练", "summary": "条码终端蓄力时间降低"})
		&"door_soil":
			_activate(&"warm_scent", {"label": "暖风气味", "summary": "显示门外暖风的大致方向"})
		&"aluminum_foil":
			_activate(&"conductive_sense", {"label": "导电感知", "summary": "靠近 ROOT 节点时出现微弱电弧"})
		&"conductive_water":
			_activate(&"bridge_charge", {"label": "导电桥接", "summary": "ROOT 节点错误一次不会清空全部进度"})
		&"magnet_core":
			_activate(&"magnetic_pulse", {"label": "磁场脉冲", "summary": "靠近金属搁架时显示隐藏线路"})
		&"hongsan_label":
			_activate(&"cold_culture", {"label": "冷凉辨识", "summary": "进入根网层后显示菜薹根方向"})
		&"yellow_petals":
			_activate(&"living_root_sense", {"label": "活根感知", "summary": "暖光、钟声和可帮助对象更清楚"})
		&"sprout_nodule_1", &"sprout_nodule_2", &"sprout_nodule_3":
			add_effect_charge(&"downward_seed_charge", 1)
		&"clean_nutrient":
			_activate(&"sterile_growth", {"label": "无菌生长", "summary": "播种时稳定向下捷径并清除临时腐败视觉"})
		&"compost_label":
			_activate(&"cycle_notice", {"label": "轮回提示", "summary": "显示垃圾大陆清理顺序和可堆肥节点"})
		_:
			if str(item_id).begins_with("nutrient_"):
				_activate_temporary(&"growth_burst", {"label": "生长爆发", "summary": "短时间提高疾跑恢复"})
			elif str(item_id).begins_with("frost_crystal_"):
				_activate(&"frost_resonance", {"label": "霜毒共鸣", "summary": "霜化视觉与压缩机节拍逐步增强"})
	_apply_all_player_effects()


func has_effect(effect_id: StringName) -> bool:
	return active_effects.has(effect_id)


func get_effect_value(effect_id: StringName, default_value: float = 0.0) -> float:
	return float(active_effects.get(effect_id, {}).get("value", default_value))


func get_sprint_noise() -> int:
	return sprint_noise


func add_effect_charge(effect_id: StringName, amount: int = 1) -> void:
	if effect_id.is_empty() or amount == 0:
		return
	var next_amount := maxi(int(effect_charges.get(effect_id, 0)) + amount, 0)
	effect_charges[effect_id] = next_amount
	effect_charge_changed.emit(effect_id, next_amount)


func consume_effect_charge(effect_id: StringName) -> bool:
	if int(effect_charges.get(effect_id, 0)) <= 0:
		return false
	add_effect_charge(effect_id, -1)
	return true


func get_effect_summary() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for effect_id in active_effects:
		var entry: Dictionary = active_effects[effect_id].duplicate(true)
		entry["effect_id"] = effect_id
		if _effect_expiry.has(effect_id):
			entry["remaining"] = maxf(float(_effect_expiry[effect_id]), 0.0)
		result.append(entry)
	for effect_id in effect_charges:
		if int(effect_charges[effect_id]) <= 0:
			continue
		result.append({"effect_id": effect_id, "label": _charge_label(effect_id), "summary": "剩余 %d 层" % int(effect_charges[effect_id]), "charge": int(effect_charges[effect_id])})
	return result


func get_item_effect_text(item_id: StringName) -> String:
	var descriptions := {
		&"corrupt_eye": "效果：扩大隐藏线索感知范围。",
		&"scarlet_ointment": "效果：减轻赤柱/黏液区域影响；区域内疾跑会增加独立噪音值。",
		&"frozen_heart": "效果：免疫冰霜区域减速，不影响霜晶计数。",
		&"golden_scale": "效果：扩大局部光照并短暂强调已发现地标。",
		&"sleeping_stone": "效果：静止后环境危险影响逐渐下降。",
		&"black_water_core": "效果：降低黑水/黏液减速；腐化不可逆。",
		&"clean_nutrient": "效果：播种时稳定向下捷径。",
		&"compost_label": "效果：显示垃圾大陆清理线索。",
	}
	if descriptions.has(item_id):
		return descriptions[item_id]
	if str(item_id).begins_with("milk_drop_"):
		return "效果：提升疾跑容量、加速度或恢复速度。"
	if str(item_id).begins_with("clean_water_"):
		return "效果：获得一层净化储备。"
	if str(item_id).begins_with("nutrient_"):
		return "效果：吸收后短暂提高生长与疾跑恢复。"
	if str(item_id).begins_with("frost_crystal_"):
		return "效果：增加霜毒共鸣；永冬路线计数 +1。"
	if str(item_id).begins_with("sale_tag_"):
		return "效果：逐步增强条码终端提示。"
	if str(item_id).begins_with("sprout_nodule_"):
		return "效果：获得一层向下播种储备。"
	return "效果：已记录到探索知识。"


func get_active_status_text(max_items: int = 4) -> String:
	var lines: Array[String] = []
	for hazard_id in _current_hazards:
		if lines.size() >= max_items:
			break
		var hazard_name := "冰霜" if hazard_id == &"frost" else "黏液"
		var multiplier := get_hazard_speed_multiplier(hazard_id, 0.65 if hazard_id == &"frost" else 0.45)
		var source := "霜冻区域" if hazard_id == &"frost" else "腐败黑水"
		lines.append("%s %s减速 ×%.2f（来源：%s）" % [_hazard_icon(hazard_id), hazard_name, multiplier, source])
	if sprint_noise > 0 and lines.size() < max_items:
		lines.append("✦ 疾跑噪音：猩红圣膏（独立值 %d）" % sprint_noise)
	var summary := get_effect_summary()
	for entry in summary:
		if lines.size() >= max_items:
			break
		var suffix := str(entry.get("summary", "已激活"))
		if entry.has("remaining"):
			suffix += "（%.1fs）" % float(entry["remaining"])
		lines.append("%s：%s" % [entry.get("label", entry.get("effect_id", "状态")), suffix])
	return "\n".join(lines)


func has_hazard_immunity(hazard_id: StringName) -> bool:
	return hazard_id == &"frost" and has_effect(&"frost_immunity")


func get_hazard_speed_multiplier(hazard_id: StringName, base_multiplier: float) -> float:
	if has_hazard_immunity(hazard_id):
		return 1.0
	var multiplier := base_multiplier
	if hazard_id == &"sticky":
		if has_effect(&"scarlet_resistance"):
			multiplier = maxf(multiplier, 0.70)
		if has_effect(&"black_blood"):
			multiplier = maxf(multiplier, 0.60)
	if has_effect(&"stasis_breath") and _still_seconds >= 1.0:
		multiplier = maxf(multiplier, 0.82)
	return multiplier


func is_sprint_allowed() -> bool:
	return not has_effect(&"sprint_disabled")


func get_sprint_speed_multiplier() -> float:
	return 1.0


func get_sprint_capacity_bonus() -> float:
	return 0.12 if has_effect(&"milk_capacity_1") else 0.0


func get_sprint_regen_multiplier() -> float:
	var result := 1.0
	if has_effect(&"milk_recovery"):
		result += 0.15
	if has_effect(&"growth_burst"):
		result += 0.10
	return result


func get_acceleration_multiplier() -> float:
	return 1.12 if has_effect(&"milk_acceleration") else 1.0


func get_interaction_time_multiplier(interaction_id: StringName) -> float:
	if interaction_id == &"barcode_terminal" and has_effect(&"barcode_mastery"):
		return 0.80
	if interaction_id == &"bottle_lever" and has_effect(&"scarlet_resistance"):
		return 0.85
	return 1.0


func get_light_multiplier() -> float:
	return 1.20 if has_effect(&"eldritch_sight") or has_effect(&"sun_guidance") else 1.0


func enter_hazard(hazard_id: StringName) -> void:
	_current_hazards[hazard_id] = int(_current_hazards.get(hazard_id, 0)) + 1


func leave_hazard(hazard_id: StringName) -> void:
	if not _current_hazards.has(hazard_id):
		return
	var next_amount := int(_current_hazards[hazard_id]) - 1
	if next_amount <= 0:
		_current_hazards.erase(hazard_id)
	else:
		_current_hazards[hazard_id] = next_amount


func _on_item_collected(item_id: StringName) -> void:
	activate_item_effect(item_id)


func _on_run_reset(_run_number: int) -> void:
	active_effects.clear()
	effect_charges.clear()
	_effect_expiry.clear()
	_current_hazards.clear()
	_still_seconds = 0.0
	_sprint_noise_clock = 0.0
	sprint_noise = 0
	_apply_all_player_effects()
	effect_changed.emit(&"run_reset", false)


func _activate(effect_id: StringName, data: Dictionary) -> void:
	if active_effects.has(effect_id):
		return
	active_effects[effect_id] = data.duplicate(true)
	effect_changed.emit(effect_id, true)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"effect_unlock")


func _activate_temporary(effect_id: StringName, data: Dictionary) -> void:
	_activate(effect_id, data)
	_effect_expiry[effect_id] = float(TEMPORARY_EFFECTS.get(effect_id, 3.0))


func _deactivate(effect_id: StringName) -> void:
	if not active_effects.erase(effect_id):
		return
	effect_changed.emit(effect_id, false)
	_apply_all_player_effects()


func _apply_all_player_effects() -> void:
	if not is_instance_valid(_player) or not _player.is_inside_tree():
		return
	if _player.has_method("set_effect_visual_state"):
		_player.set_effect_visual_state({
			"eldritch_sight": has_effect(&"eldritch_sight"),
			"sun_guidance": has_effect(&"sun_guidance"),
			"frost_immunity": has_effect(&"frost_immunity"),
			"growth_burst": has_effect(&"growth_burst"),
		})
	if _player.has_method("refresh_effect_parameters"):
		_player.refresh_effect_parameters()


func _charge_label(effect_id: StringName) -> String:
	match effect_id:
		&"purity_charge": return "净化储备"
		&"downward_seed_charge": return "向下播种"
	return str(effect_id)


func _hazard_icon(hazard_id: StringName) -> String:
	return "◇" if hazard_id == &"frost" else "≈"
