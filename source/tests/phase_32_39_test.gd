extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func _ready() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().physics_frame
	var level := main.get_node_or_null("FridgeLevel")
	if level == null:
		_fail("主场景没有生成最终大地图")
		return
	var bounds: Rect2 = level.get_world_bounds()
	if bounds.size.x < 25000.0 or bounds.size.y < 25000.0:
		_fail("最终地图小于 25000×25000")
		return
	if not level.has_method("get_loaded_backplate_count") or level.get_loaded_backplate_count() != 6:
		_fail("六张冰箱垂直背板没有全部加载")
		return
	var summary: Dictionary = level.get_generation_summary()
	if int(summary.get("ring_count", 0)) != 7 or int(summary.get("sector_count", 0)) < 12 or int(summary.get("sector_count", 0)) > 16:
		_fail("七环或 12–16 扇区摘要无效：%s" % summary)
		return
	for node_path in ["WorldChunkManager", "MapPanel", "GuidanceOverlay", "PurpleCrownEntrance", "MotherSoilEntrance", "SelfPruneEntrance", "ForcedCleanupEntrance", "HongsanRoot", "NarratorCommand1", "DownwardTrial"]:
		if level.get_node_or_null(node_path) == null:
			_fail("32–39 小时阶段缺少节点：%s" % node_path)
			return
	var debug_panel := level.get_node_or_null("DebugPanel")
	if debug_panel == null or not debug_panel.has_method("_open_asset_gallery"):
		_fail("F3 缺少素材检查总览")
		return
	debug_panel._open_asset_gallery()
	await get_tree().process_frame
	var gallery = debug_panel.get("_asset_gallery")
	if gallery == null or not gallery.visible:
		_fail("F3 素材检查总览无法打开")
		return
	debug_panel._close_asset_gallery()
	if not debug_panel.has_method("_open_point_teleporter"):
		_fail("F3 缺少全素材点传送")
		return
	debug_panel._open_point_teleporter()
	await get_tree().process_frame
	var point_teleporter = debug_panel.get("_point_teleporter")
	if point_teleporter == null or not point_teleporter.visible or point_teleporter.get_point_count() != 85:
		_fail("F3 没有覆盖全部生成地点与区域")
		return
	debug_panel._close_point_teleporter()
	var prune := level.get_node("SelfPruneEntrance")
	if prune.required_seconds > 0.9 or prune.required_seconds < 0.5 or prune.area_size.x > 520.0 or prune.area_size.y > 360.0 or prune.area_size.x < 420.0 or prune.area_size.y < 280.0:
		_fail("自我剪芽区域或持续时间没有保持在紧凑可完成范围")
		return
	var downward := level.get_node("DownwardTrial")
	if downward.required_seconds > 1.0 or downward.area_size.x > 560.0 or downward.area_size.y > 380.0:
		_fail("向下试炼区域或持续时间仍然过大")
		return
	var chunks: Dictionary = level.get_node("WorldChunkManager").get_summary()
	if int(chunks.get("active_count", 0)) != 25 or int(chunks.get("registered_count", 0)) < 6:
		_fail("玩家周围没有维持 5×5 活动逻辑块：%s" % chunks)
		return
	var knowledge := get_node("/root/MapKnowledgeManager")
	if get_node("/root/GuidanceDirector").get_rule_count() < 6:
		_fail("guidance_rules.csv 没有被 GuidanceDirector 加载")
		return
	if knowledge.discovered_cells.is_empty() or not knowledge.discovered_landmarks.has(&"mother_potato"):
		_fail("初始地图知识没有中心与出生格")
		return
	if not knowledge.markers.is_empty():
		_fail("未获得线索时小地图泄露隐藏目标")
		return
	var game_state := get_node("/root/GameState")
	var effects := get_node("/root/ItemEffectDirector")
	game_state.collect_item(&"corrupt_eye")
	if not effects.has_effect(&"eldritch_sight"):
		_fail("腐败之眼没有激活旧神视域")
		return
	if knowledge.has_marker(&"frozen_heart_revelation"):
		_fail("只获得腐败之眼时提前标记永冻之心")
		return
	game_state.collect_item(&"scarlet_ointment")
	if not effects.has_effect(&"scarlet_resistance") or effects.get_hazard_speed_multiplier(&"sticky", 0.45) < 0.70:
		_fail("猩红圣膏没有降低黏液区域影响")
		return
	if not knowledge.has_marker(&"frozen_heart_revelation"):
		_fail("获得猩红圣膏后没有标记永冻之心")
		return
	game_state.collect_item(&"frozen_heart")
	if not effects.has_effect(&"frost_immunity") or effects.get_hazard_speed_multiplier(&"frost", 0.65) != 1.0:
		_fail("永冻之心没有提供独立的霜冻免疫")
		return
	if knowledge.has_marker(&"frozen_heart_revelation"):
		_fail("取得永冻之心后旧标记没有清除")
		return
	var map_panel := level.get_node("MapPanel")
	map_panel.set_full_open(true)
	if not map_panel.is_full_open() or not get_tree().paused:
		_fail("M 键完整地图状态没有暂停玩法")
		return
	var inventory := level.get_node("InventoryPanel")
	inventory.set_open(true)
	if map_panel.is_full_open() or not inventory.is_open():
		_fail("完整地图与背包没有正确互斥")
		return
	inventory.set_open(false)
	main._start_new_run(39001)
	await get_tree().process_frame
	await get_tree().physics_frame
	game_state.collect_item(&"frozen_heart")
	game_state.collect_item(&"scarlet_ointment")
	if knowledge.has_marker(&"frozen_heart_revelation"):
		_fail("乱序取得遗物后重新显示过期标记")
		return
	main._start_new_run(39002)
	await get_tree().process_frame
	await get_tree().physics_frame
	game_state.collect_item(&"scarlet_ointment")
	if knowledge.has_marker(&"frozen_heart_revelation"):
		_fail("尚未得到腐败之眼时猩红圣膏提前标记目标")
		return
	game_state.collect_item(&"corrupt_eye")
	if not knowledge.has_marker(&"frozen_heart_revelation"):
		_fail("先取得猩红圣膏后补得腐败之眼时没有恢复合理提示")
		return
	game_state.collect_item(&"frozen_heart")
	game_state.collect_item(&"golden_scale")
	if not knowledge.has_marker(&"dragon_shrine_hint"):
		_fail("guidance_rules.csv 没有生成奶龙路线的扇区标记")
		return
	print("PHASE 32-39 PASS: 25600 自底向上七层地图、逻辑分块、知识小地图、动态提示和四条新路线均已装载。")
	get_tree().quit(0)


func _fail(message: String) -> void:
	get_tree().paused = false
	push_error(message)
	print("PHASE 32-39 FAIL: %s" % message)
	get_tree().quit(1)
