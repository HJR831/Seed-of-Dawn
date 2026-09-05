extends Node

const PROGRESS_SCRIPT := preload("res://autoload/progress_state.gd")
const TEST_PATH := "user://save_roundtrip_test.cfg"


func _ready() -> void:
	var writer := PROGRESS_SCRIPT.new()
	add_child(writer)
	writer.unlocked_endings = {&"ending_01_food_failure": true, &"ending_03_milk_dragon": true}
	writer.run_count = 7
	writer.first_ending_seen = true
	writer.text_skip_unlocked = true
	if not writer.save_to_path(TEST_PATH):
		_fail("测试存档无法写入")
		return
	var reader := PROGRESS_SCRIPT.new()
	add_child(reader)
	if not reader.load_from_path(TEST_PATH):
		_fail("测试存档无法读回")
		return
	if reader.unlocked_count() != 2 or reader.run_count != 7 or not reader.is_ending_unlocked(&"ending_03_milk_dragon"):
		_fail("存档往返后永久进度不一致")
		return
	writer.queue_free()
	reader.queue_free()
	print("SAVE ROUNDTRIP PASS: 结局图鉴和跨局数据可持久化往返。")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	print("SAVE ROUNDTRIP FAIL: %s" % message)
	get_tree().quit(1)
