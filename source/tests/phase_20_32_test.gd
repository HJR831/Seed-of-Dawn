extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func _ready() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().physics_frame
	var level := main.get_node_or_null("FridgeLevel")
	if level == null:
		_fail("主场景没有生成自底向上的垂直关卡")
		return
	var bounds: Rect2 = level.get_world_bounds()
	if bounds.size.x < 8192.0 or bounds.size.y < 8192.0:
		_fail("最终逻辑地图小于 8192×8192")
		return
	var summary: Dictionary = level.get_generation_summary()
	if int(summary.get("sector_count", 0)) < 8 or not summary.get("validation_errors", []).is_empty():
		_fail("随机地图摘要无效：%s" % summary)
		return
	for node_path in ["InventoryPanel", "WarmDoorEntrance", "RootNetworkEntrance", "BarcodeTerminalEntrance", "FreezerAlcoveEntrance", "TemperatureProbeEntrance", "ThermostatConsole", "RootNodeSequence", "CompressorIdleRitual"]:
		if level.get_node_or_null(node_path) == null:
			_fail("20–32 小时阶段缺少节点：%s" % node_path)
			return
	var game_state := get_node("/root/GameState")
	game_state.collect_item(&"door_soil")
	var inventory := level.get_node("InventoryPanel")
	inventory.set_open(true)
	if not inventory.is_open() or inventory.entry_count() != 1 or not get_tree().paused:
		_fail("物品栏没有显示本局物品或没有暂停玩法")
		return
	inventory.set_open(false)
	if get_tree().paused:
		_fail("关闭物品栏后游戏仍暂停")
		return
	var thermostat := level.get_node("ThermostatConsole")
	for _step in range(7):
		thermostat.increment()
	if game_state.get_counter(&"thermostat_level") != 7:
		_fail("温控旋钮没有抵达第七格")
		return
	var sequence := level.get_node("RootNodeSequence")
	for node_index in [0, 1, 1, 2]:
		sequence.register_node(node_index)
	if not game_state.rituals.has(&"root_node_sequence"):
		_fail("ROOT 节点节拍没有完成")
		return
	print("PHASE 20-32 PASS: 25600 自底向上地图、背包、五条新入口、温控与 ROOT 节拍均已装载。")
	get_tree().quit(0)


func _fail(message: String) -> void:
	get_tree().paused = false
	push_error(message)
	print("PHASE 20-32 FAIL: %s" % message)
	get_tree().quit(1)
