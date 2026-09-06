extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const CASES := [
	["_grant_purple_crown_recipe", "PurpleCrownEntrance", &"ending_09_purple_crown"],
	["_grant_dark_harvest_recipe", "MotherSoilEntrance", &"ending_10_dark_harvest"],
	["_grant_stillness_recipe", "SelfPruneEntrance", &"ending_11_not_growing_today"],
	["_grant_landfill_recipe", "ForcedCleanupEntrance", &"ending_12_landfill_king"],
]


func _ready() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	for index in range(CASES.size()):
		var level := main.get_node_or_null("FridgeLevel")
		var debug_panel := level.get_node_or_null("DebugPanel") if level != null else null
		if debug_panel == null:
			_fail("第 %d 条路线缺少 DebugPanel" % (index + 9))
			return
		debug_panel.call(CASES[index][0])
		var entrance := level.get_node_or_null(CASES[index][1])
		if entrance == null:
			_fail("缺少入口：%s" % CASES[index][1])
			return
		entrance._try_resolve()
		await get_tree().create_timer(0.55).timeout
		var expected: StringName = CASES[index][2]
		if get_node("/root/GameState").current_ending != expected or main.get_node_or_null("EndingScreen") == null:
			_fail("入口 %s 没有完整进入 %s" % [CASES[index][1], expected])
			return
		if not get_node("/root/ProgressState").is_ending_unlocked(expected):
			_fail("结局没有写入图鉴：%s" % expected)
			return
		if index < CASES.size() - 1:
			main._start_new_run(39010 + index)
			await get_tree().process_frame
			await get_tree().physics_frame
	print("PHASE 32 ENDINGS FLOW PASS: 结局 09–12 均能从调试配方经实际入口进入结算并写入图鉴。")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	print("PHASE 32 ENDINGS FLOW FAIL: %s" % message)
	get_tree().quit(1)
