extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func _ready() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().physics_frame
	var level := main.get_node_or_null("FridgeLevel")
	if level == null:
		_fail("主场景未创建扩展关卡")
		return
	var bounds: Rect2 = level.get_world_bounds()
	if bounds.size.x < 2560.0 or bounds.size.y < 7200.0:
		_fail("扩展关卡尺寸不足：%s" % bounds.size)
		return
	if get_tree().get_nodes_in_group(&"stage_marker").size() < 5:
		_fail("扩展关卡缺少五段 Marker2D")
		return
	for node_path in [
		"CorruptEye", "ScarletOintment", "FrozenHeart", "MilkDrop1", "MilkDrop2", "MilkDrop3", "GoldenScale",
		"BottleCounterclockwiseRitual", "YellowCapRitual", "LightSwitchEntrance", "DragonShrineEntrance", "FinalLid"
	]:
		if level.get_node_or_null(node_path) == null:
			_fail("扩展关卡缺少节点：%s" % node_path)
			return
	var game_state := get_node("/root/GameState")
	var bottle_ritual := level.get_node("BottleCounterclockwiseRitual")
	var bottle_body := level.get_node("TitanBottle") as StaticBody2D
	var bottle_shape: RectangleShape2D = null
	for child in bottle_body.get_children():
		if child is CollisionShape2D:
			bottle_shape = child.shape as RectangleShape2D
			break
	if bottle_shape == null:
		_fail("赤柱缺少矩形碰撞体")
		return
	if bottle_ritual.radius <= bottle_shape.size.y * 0.5 + 24.0:
		_fail("赤柱上/下仪式标记仍与实体碰撞范围重合")
		return
	for checkpoint in [0, 1, 2, 3]:
		bottle_ritual.register_checkpoint(checkpoint)
	if not game_state.rituals.has(&"bottle_counterclockwise"):
		_fail("逆时针检查点没有完成赤柱仪式")
		return
	var cap_ritual := level.get_node("YellowCapRitual")
	for checkpoint in [0, 1, 2, 3]:
		cap_ritual.register_checkpoint(checkpoint)
	if not game_state.rituals.has(&"yellow_cap_loop"):
		_fail("顺时针检查点没有完成黄金瓶盖仪式")
		return
	var player := level.get_node_or_null("Sprout")
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null or camera.limit_right < 8192 or camera.limit_bottom < 8192:
		_fail("相机边界没有跟随扩展地图")
		return
	print("PHASE 13-20 MAP PASS: 大地图、阶段标记、两套隐藏配方和三个入口均已装载。")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	print("PHASE 13-20 MAP FAIL: %s" % message)
	get_tree().quit(1)
