class_name EndingResolver
extends RefCounted

const EndingIdsScript := preload("res://systems/ending_ids.gd")


static func request_ending(trigger_id: StringName, snapshot: Dictionary) -> Dictionary:
	var missing: Array[String] = []
	match trigger_id:
		&"top_lid":
			return _success(EndingIdsScript.FOOD_FAILURE)
		&"light_switch_hold":
			_require_item(snapshot, &"corrupt_eye", "腐败之眼仍未归位", missing)
			_require_item(snapshot, &"scarlet_ointment", "猩红圣膏仍未归位", missing)
			_require_item(snapshot, &"frozen_heart", "永冻之心仍未归位", missing)
			_require_ritual(snapshot, &"bottle_counterclockwise", "还未逆行盘绕赤色巨柱", missing)
			_require_counter(snapshot, &"compressor_start_count", 3, "还未听见第三次深渊呼吸", missing)
			return _finish(EndingIdsScript.LORD_OF_SPROUTS, missing)
		&"dragon_shrine_idle":
			_require_counter(snapshot, &"milk_count", 3, "白母仍少一滴泪", missing)
			_require_item(snapshot, &"golden_scale", "日之金鳞尚未归位", missing)
			_require_ritual(snapshot, &"yellow_cap_loop", "黄金卵壳尚未完成环绕", missing)
			if int(snapshot.get("corruption", 0)) > 0:
				missing.append("腐败与辣油已经污染乳白圣液")
			var flags: Dictionary = snapshot.get("flags", {})
			if bool(flags.get(&"touched_black_water", false)) or bool(flags.get(&"touched_chili_oil", false)):
				missing.append("幼龙不会在腐败或辛辣的痕迹中降生")
			return _finish(EndingIdsScript.MILK_DRAGON, missing)
		&"warm_door_gap":
			_require_counter(snapshot, &"clean_water_count", 2, "还需要两滴干净冷凝水", missing)
			_require_item(snapshot, &"door_soil", "暖风中仍缺少一粒门外之土", missing)
			_require_item(snapshot, &"flowerpot_receipt", "还未读到花盆计划的小票背面", missing)
			_require_flag(snapshot, &"bottle_lever", "还未让玻璃瓶成为通向侧面的杠杆", missing)
			if int(snapshot.get("corruption", 0)) > 0 or int(snapshot.get("devour", 0)) > 0:
				missing.append("芽体仍带着吞噬或腐败的痕迹")
			return _finish(EndingIdsScript.TRUE_DAWN, missing)
		&"root_network_complete":
			_require_counter(snapshot, &"clean_water_count", 3, "三名沉睡者各需要一滴水", missing)
			for companion_id in [&"companion_onion_watered", &"companion_garlic_watered", &"companion_ginger_watered"]:
				_require_flag(snapshot, companion_id, "还有一位沉睡者没有回应", missing)
			_require_ritual(snapshot, &"root_network_loop", "三片区域尚未被根系连成回环", missing)
			if int(snapshot.get("devour", 0)) > 0:
				missing.append("被吞噬的同伴无法加入自治森林")
			return _finish(EndingIdsScript.AUTONOMOUS_FOREST, missing)
		&"barcode_terminal":
			_require_counter(snapshot, &"barcode_count", 3, "季度报表仍缺少价签", missing)
			var total := int(snapshot.get("optional_nutrients_total", 0))
			var eaten := int(snapshot.get("optional_nutrients_eaten", 0))
			if total < 6 or eaten < total:
				missing.append("本纪元增长目标尚未完成")
			_require_flag(snapshot, &"returned_after_final_unlock", "终点解锁后仍未回头搜刮", missing)
			if int(snapshot.get("nurture", 0)) > 0:
				missing.append("共享行为不符合无限增长指标")
			return _finish(EndingIdsScript.INFINITE_GROWTH_INC, missing)
		&"freezer_alcove":
			_require_counter(snapshot, &"frost_count", 4, "寒冷尚未凝成四枚霜晶", missing)
			_require_item(snapshot, &"sleeping_stone", "冻豌豆深处的眠石仍未苏醒", missing)
			_require_counter(snapshot, &"thermostat_level", 7, "温控尚未抵达第七格", missing)
			_require_flag(snapshot, &"frozen_full_cycle", "还未静止度过一次完整压缩机周期", missing)
			_require_ritual(snapshot, &"self_seed_loop", "根须还没有绕成胚种", missing)
			return _finish(EndingIdsScript.ETERNAL_WINTER_SEED, missing)
		&"temperature_probe":
			_require_item(snapshot, &"aluminum_foil", "ROOT 缺少雷引", missing)
			_require_item(snapshot, &"conductive_water", "ROOT 缺少流动之镜", missing)
			_require_item(snapshot, &"magnet_core", "ROOT 缺少方向之核", missing)
			_require_ritual(snapshot, &"root_node_sequence", "电气节点仍显示 ACCESS DENIED", missing)
			return _finish(EndingIdsScript.ROOT_ACCESS, missing)
		_:
			return {"matched": false, "ending_id": &"", "missing": ["这里没有结局入口"]}


static func _require_item(snapshot: Dictionary, item_id: StringName, hint: String, missing: Array[String]) -> void:
	var items: Dictionary = snapshot.get("items", {})
	if not bool(items.get(item_id, false)):
		missing.append(hint)


static func _require_ritual(snapshot: Dictionary, ritual_id: StringName, hint: String, missing: Array[String]) -> void:
	var rituals: Dictionary = snapshot.get("rituals", {})
	if not bool(rituals.get(ritual_id, false)):
		missing.append(hint)


static func _require_counter(snapshot: Dictionary, counter_id: StringName, minimum: int, hint: String, missing: Array[String]) -> void:
	var counters: Dictionary = snapshot.get("counters", {})
	if int(counters.get(counter_id, 0)) < minimum:
		missing.append(hint)


static func _require_flag(snapshot: Dictionary, flag_id: StringName, hint: String, missing: Array[String]) -> void:
	var flags: Dictionary = snapshot.get("flags", {})
	if not bool(flags.get(flag_id, false)):
		missing.append(hint)


static func _finish(ending_id: StringName, missing: Array[String]) -> Dictionary:
	if missing.is_empty():
		return _success(ending_id)
	return {"matched": false, "ending_id": &"", "missing": missing}


static func _success(ending_id: StringName) -> Dictionary:
	return {"matched": true, "ending_id": ending_id, "missing": []}
