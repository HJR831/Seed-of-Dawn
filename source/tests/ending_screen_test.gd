extends Node

const ENDING_SCREEN_SCENE := preload("res://scenes/ui/ending_screen.tscn")

const CASES := {
	&"ending_01_food_failure": "生长成功，食用失败",
	&"ending_02_lord_of_sprouts": "万芽之主",
	&"ending_03_milk_dragon": "奶龙降生",
	&"ending_04_true_dawn": "真正的破晓",
	&"ending_05_autonomous_forest": "保鲜层自治森林",
	&"ending_06_infinite_growth_inc": "无限增长有限公司",
	&"ending_07_eternal_winter_seed": "永冬胚种",
	&"ending_08_root_access": "ROOT 权限",
	&"ending_09_purple_crown": "紫冠的新芽",
	&"ending_10_dark_harvest": "不见天日的丰收",
	&"ending_11_not_growing_today": "今天不长",
	&"ending_12_landfill_king": "垃圾大陆之王",
}


func _ready() -> void:
	var game_state := get_node("/root/GameState")
	for ending_id in CASES:
		game_state.current_ending = ending_id
		var screen := ENDING_SCREEN_SCENE.instantiate()
		add_child(screen)
		await get_tree().process_frame
		if not _contains_text(screen, CASES[ending_id]):
			_fail("通用结局画面未加载标题：%s" % CASES[ending_id])
			return
		remove_child(screen)
		screen.queue_free()
		await get_tree().process_frame
	game_state.current_ending = &"ending_12_landfill_king"
	game_state.set_flag(&"read_compost_label")
	var compost_screen := ENDING_SCREEN_SCENE.instantiate()
	add_child(compost_screen)
	await get_tree().process_frame
	if not compost_screen.should_play_landfill_epilogue(&"ending_12_landfill_king") or compost_screen.should_play_landfill_epilogue(&"ending_01_food_failure"):
		_fail("可堆肥标签没有只为结局 12 开启八秒后二段")
		return
	remove_child(compost_screen)
	compost_screen.queue_free()
	print("ENDING SCREEN PASS: 十二个结局共用画面能正确加载各自数据。")
	get_tree().quit(0)


func _contains_text(root: Node, expected: String) -> bool:
	for child in root.get_children():
		if child is Label and expected in child.text:
			return true
		if _contains_text(child, expected):
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	print("ENDING SCREEN FAIL: %s" % message)
	get_tree().quit(1)
