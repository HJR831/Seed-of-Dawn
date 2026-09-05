extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func _ready() -> void:
	_run_test()


func _run_test() -> void:
	var watchdog := get_tree().create_timer(12.0)
	watchdog.timeout.connect(func() -> void:
		if not get_tree().root.is_queued_for_deletion():
			_fail("流程测试超过 8 秒仍未结束")
	)

	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	var level := main.get_node_or_null("FridgeLevel")
	var player := main.get_node_or_null("FridgeLevel/Sprout") as CharacterBody2D
	if level == null or player == null:
		_fail("主场景未生成灰盒关卡或玩家")
		return

	var starting_y := player.global_position.y
	Input.action_press(&"move_up")
	await get_tree().create_timer(0.35).timeout
	Input.action_release(&"move_up")
	if player.global_position.y >= starting_y - 10.0:
		_fail("按住向上后玩家没有移动")
		return
	var trail := player.get_node_or_null("Trail") as Line2D
	if trail == null or trail.get_point_count() <= 1:
		_fail("玩家移动后 Line2D 芽体没有增长")
		return
	var local_light := player.get_node_or_null("LocalLight") as PointLight2D
	if local_light == null or local_light.texture == null:
		_fail("玩家局部光照没有生成径向纹理")
		return
	get_node("/root/NarrativeManager").clear_queue()

	# 将芽尖放进最终盒盖感应范围，模拟持续蓄力。
	player.global_position = level.get_location(&"final_lid")
	await get_tree().physics_frame
	Input.action_press(&"charge")
	await get_tree().create_timer(2.15).timeout
	Input.action_release(&"charge")
	await get_tree().create_timer(0.8).timeout

	var ending_screen := main.get_node_or_null("EndingScreen")
	if ending_screen == null:
		_fail("长按盒盖后没有进入默认结局")
		return
	var progress_state := get_node("/root/ProgressState")
	if not progress_state.is_ending_unlocked(&"ending_01_food_failure"):
		_fail("默认结局没有写入永久图鉴")
		return

	ending_screen.restart_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame

	if main.get_node_or_null("EndingScreen") != null:
		_fail("重新开始后结局画面没有关闭")
		return
	if main.get_node_or_null("FridgeLevel/Sprout") == null:
		_fail("重新开始后没有重新生成玩家")
		return
	if not progress_state.is_ending_unlocked(&"ending_01_food_failure"):
		_fail("重新开始后永久图鉴被错误清空")
		return
	if get_node("/root/GameState").current_ending != &"":
		_fail("重新开始后本局结局状态没有清空")
		return
	var ambience := get_node_or_null("/root/AudioManager/AmbiencePlayer") as AudioStreamPlayer
	if ambience == null or not ambience.playing:
		_fail("结局后重新开始没有恢复压缩机环境声")
		return

	print("GAMEPLAY FLOW PASS: 移动、Line2D、局部光照、盒盖蓄力、默认结局和重新开始均正常。")
	get_tree().quit(0)


func _fail(message: String) -> void:
	Input.action_release(&"charge")
	push_error(message)
	print("GAMEPLAY FLOW FAIL: %s" % message)
	get_tree().quit(1)
