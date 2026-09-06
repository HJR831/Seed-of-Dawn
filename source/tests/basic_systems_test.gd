extends Node

const SPROUT_SCENE := preload("res://scenes/player/sprout.tscn")
const INTERACTABLE_SCENE := preload("res://scenes/gameplay/interactable.tscn")
const PICKUP_SCENE := preload("res://scenes/gameplay/pickup.tscn")
const STICKY_SCENE := preload("res://scenes/gameplay/sticky_area.tscn")
const FROST_SCENE := preload("res://scenes/gameplay/frost_area.tscn")
const ENDING_ENTRANCE_SCENE := preload("res://scenes/gameplay/ending_entrance.tscn")


func _ready() -> void:
	await _run_test()


func _run_test() -> void:
	var game_state := get_node("/root/GameState")
	var narrative := get_node("/root/NarrativeManager")
	game_state.reset_run()
	await get_tree().process_frame
	var effects := get_node("/root/ItemEffectDirector")
	if effects.has_effect(&"frost_immunity"):
		_fail("新回合没有清除上一回合临时道具效果")
		return
	game_state.collect_item(&"frozen_heart")
	if not effects.has_effect(&"frost_immunity"):
		_fail("永冻之心拾取后没有激活霜冻免疫")
		return
	if game_state.get_counter(&"frost_count") != 0:
		_fail("霜冻免疫错误修改了霜晶计数")
		return

	game_state.add_stat(&"noise", 2)
	game_state.add_stat(&"noise", -1)
	if game_state.noise != 1:
		_fail("GameState 行为值没有通过统一 API 正确更新")
		return
	if not game_state.collect_item(&"unique_test_item") or game_state.collect_item(&"unique_test_item"):
		_fail("GameState 未阻止同一道具重复计数")
		return
	game_state.increment_counter(&"milk_count", 2)
	game_state.complete_ritual(&"test_ritual")
	var snapshot: Dictionary = game_state.make_snapshot()
	if snapshot.counters.get(&"milk_count", 0) != 2 or not snapshot.rituals.has(&"test_ritual"):
		_fail("GameState 快照缺少计数器或仪式数据")
		return

	narrative.clear_queue()
	if not narrative.request_text(&"prologue") or not narrative.request_text(&"stage_rot") or not narrative.request_text(&"stage_final", 100):
		_fail("叙事文本没有进入队列")
		return
	if narrative.queued_count() != 3 or narrative.request_text(&"stage_rot"):
		_fail("叙事队列未串行计数或未阻止重复文本")
		return
	narrative.finish_current_text()
	if narrative.current_text_id() != &"stage_final":
		_fail("高优先级神谕没有排到普通提示之前")
		return
	narrative.finish_current_text()
	if narrative.current_text_id() != &"stage_rot":
		_fail("高优先级文本后没有恢复普通队列")
		return
	narrative.finish_current_text()
	if narrative.is_text_active():
		_fail("叙事队列清空后仍报告文本活跃")
		return

	game_state.reset_run()
	await get_tree().process_frame
	var interactable := INTERACTABLE_SCENE.instantiate()
	interactable.item_id = &"test_sleeper"
	interactable.narrative_text_id = &""
	add_child(interactable)
	await get_tree().process_frame
	if not interactable.perform_short_action() or interactable.perform_hold_action():
		_fail("通用交互没有执行一次性短按，或允许第二次计数")
		return
	if game_state.nurture != 1 or game_state.devour != 0:
		_fail("通用交互的短按/长按状态路由错误")
		return

	var pickup := PICKUP_SCENE.instantiate()
	pickup.item_id = &"test_pickup"
	pickup.narrative_text_id = &""
	add_child(pickup)
	await get_tree().process_frame
	if not pickup.collect() or pickup.collect() or not game_state.has_item(&"test_pickup"):
		_fail("拾取物未正确收集或发生重复收集")
		return

	var sprout := SPROUT_SCENE.instantiate()
	sprout.add_to_group(&"player")
	add_child(sprout)
	await get_tree().process_frame
	var sticky := STICKY_SCENE.instantiate()
	add_child(sticky)
	var frost := FROST_SCENE.instantiate()
	add_child(frost)
	var entrance := ENDING_ENTRANCE_SCENE.instantiate()
	add_child(entrance)
	await get_tree().process_frame
	entrance._on_body_entered(sprout)
	entrance._on_body_exited(sprout)
	if not sprout._sprint_locks.is_empty():
		_fail("离开结局入口后疾跑锁没有释放")
		return
	sticky._on_body_entered(sprout)
	if sprout.speed_modifiers.is_empty():
		_fail("黏液区域没有添加来源化减速")
		return
	sticky._on_body_exited(sprout)
	frost._on_body_entered(sprout)
	if not sprout.statuses.has(&"frost") or sprout.speed_modifiers.is_empty():
		_fail("冰霜区域没有同时添加霜化反馈与减速")
		return
	frost._on_body_exited(sprout)
	if sprout.statuses.has(&"frost") or not sprout.speed_modifiers.is_empty():
		_fail("离开材质区域后玩家状态没有恢复")
		return

	if game_state.get_counter(&"compressor_start_count") != 1:
		_fail("新一局没有记录一次明确的压缩机启动事件")
		return

	print("BASIC SYSTEMS PASS: 状态、去重、交互、文本队列、材质反馈与压缩机事件均正常。")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	print("BASIC SYSTEMS FAIL: %s" % message)
	get_tree().quit(1)
