extends SceneTree

const Resolver := preload("res://systems/ending_resolver.gd")
const EndingIdsScript := preload("res://systems/ending_ids.gd")


func _init() -> void:
	var failures: Array[String] = []
	_expect(&"top_lid", _snapshot(), EndingIdsScript.FOOD_FAILURE, failures)

	var eldritch := _snapshot()
	eldritch.items = {&"corrupt_eye": true, &"scarlet_ointment": true, &"frozen_heart": true}
	eldritch.rituals = {&"bottle_counterclockwise": true}
	eldritch.counters = {&"compressor_start_count": 3}
	_expect(&"light_switch_hold", eldritch, EndingIdsScript.LORD_OF_SPROUTS, failures)
	for missing_item in [&"corrupt_eye", &"scarlet_ointment", &"frozen_heart"]:
		var incomplete := eldritch.duplicate(true)
		incomplete.items.erase(missing_item)
		_expect_failure(&"light_switch_hold", incomplete, "古神路线缺少 %s 时仍触发" % missing_item, failures)
	var early_breath := eldritch.duplicate(true)
	early_breath.counters[&"compressor_start_count"] = 2
	_expect_failure(&"light_switch_hold", early_breath, "第二次压缩机启动时提前触发古神结局", failures)

	var dragon := _snapshot()
	dragon.items = {&"golden_scale": true}
	dragon.rituals = {&"yellow_cap_loop": true}
	dragon.counters = {&"milk_count": 3}
	_expect(&"dragon_shrine_idle", dragon, EndingIdsScript.MILK_DRAGON, failures)
	var missing_scale := dragon.duplicate(true)
	missing_scale.items.clear()
	_expect_failure(&"dragon_shrine_idle", missing_scale, "奶龙路线缺少日之金鳞时仍触发", failures)
	var short_milk := dragon.duplicate(true)
	short_milk.counters[&"milk_count"] = 2
	_expect_failure(&"dragon_shrine_idle", short_milk, "只有两滴奶时仍触发奶龙结局", failures)
	var corrupted := dragon.duplicate(true)
	corrupted.corruption = 1
	_expect_failure(&"dragon_shrine_idle", corrupted, "吸收腐败物后仍触发奶龙结局", failures)
	var touched_oil := dragon.duplicate(true)
	touched_oil.flags = {&"touched_chili_oil": true}
	_expect_failure(&"dragon_shrine_idle", touched_oil, "接触辣油后仍触发奶龙结局", failures)

	var dawn := _snapshot()
	dawn.items = {&"clean_water_1": true, &"clean_water_2": true, &"door_soil": true, &"flowerpot_receipt": true}
	dawn.counters = {&"clean_water_count": 2}
	dawn.flags = {&"bottle_lever": true}
	_expect(&"warm_door_gap", dawn, EndingIdsScript.TRUE_DAWN, failures)
	var spoiled_dawn := dawn.duplicate(true)
	spoiled_dawn.corruption = 1
	_expect_failure(&"warm_door_gap", spoiled_dawn, "带腐败痕迹仍触发真正破晓", failures)

	var forest := _snapshot()
	forest.counters = {&"clean_water_count": 3}
	forest.flags = {&"companion_onion_watered": true, &"companion_garlic_watered": true, &"companion_ginger_watered": true}
	forest.rituals = {&"root_network_loop": true}
	_expect(&"root_network_complete", forest, EndingIdsScript.AUTONOMOUS_FOREST, failures)

	var growth := _snapshot()
	growth.counters = {&"barcode_count": 3}
	growth.flags = {&"returned_after_final_unlock": true}
	growth.optional_nutrients_total = 6
	growth.optional_nutrients_eaten = 6
	growth.devour = 6
	_expect(&"barcode_terminal", growth, EndingIdsScript.INFINITE_GROWTH_INC, failures)

	var winter := _snapshot()
	winter.items = {&"sleeping_stone": true}
	winter.counters = {&"frost_count": 4, &"thermostat_level": 7}
	winter.flags = {&"frozen_full_cycle": true}
	winter.rituals = {&"self_seed_loop": true}
	_expect(&"freezer_alcove", winter, EndingIdsScript.ETERNAL_WINTER_SEED, failures)

	var root_access := _snapshot()
	root_access.items = {&"aluminum_foil": true, &"conductive_water": true, &"magnet_core": true}
	root_access.rituals = {&"root_node_sequence": true}
	_expect(&"temperature_probe", root_access, EndingIdsScript.ROOT_ACCESS, failures)
	var incomplete_root := root_access.duplicate(true)
	incomplete_root.items.erase(&"magnet_core")
	_expect_failure(&"temperature_probe", incomplete_root, "缺少磁芯仍触发 ROOT 权限", failures)

	# 唯一入口消解冲突：即使携带两套配方，顶盖仍只回退到默认结局。
	var conflict := eldritch.duplicate(true)
	conflict.items[&"golden_scale"] = true
	conflict.rituals[&"yellow_cap_loop"] = true
	conflict.counters[&"milk_count"] = 3
	_expect(&"top_lid", conflict, EndingIdsScript.FOOD_FAILURE, failures)

	if failures.is_empty():
		print("ENDING RESOLVER PASS: 前八结局正向、缺条件和冲突测试均通过。")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _snapshot() -> Dictionary:
	return {"items": {}, "rituals": {}, "counters": {}, "flags": {}, "corruption": 0, "devour": 0, "nurture": 0, "optional_nutrients_total": 0, "optional_nutrients_eaten": 0}


func _expect(trigger_id: StringName, snapshot: Dictionary, expected: StringName, failures: Array[String]) -> void:
	var result: Dictionary = Resolver.request_ending(trigger_id, snapshot)
	if not bool(result.get("matched", false)) or result.get("ending_id", &"") != expected:
		failures.append("%s 未返回 %s：%s" % [trigger_id, expected, result])


func _expect_failure(trigger_id: StringName, snapshot: Dictionary, message: String, failures: Array[String]) -> void:
	if bool(Resolver.request_ending(trigger_id, snapshot).get("matched", false)):
		failures.append(message)
