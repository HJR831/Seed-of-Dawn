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
	print("ENDING SCREEN PASS: 前八个结局共用画面能正确加载各自数据。")
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
