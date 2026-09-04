extends Node

signal text_started(entry: Dictionary)
signal text_finished(text_id: StringName)
signal queue_cleared

const NARRATIVE_DATA_PATH := "res://data/narrative_text.csv"

var _entries: Dictionary = {}
var _queue: Array[StringName] = []
var _seen_this_run: Dictionary = {}
var _current_id: StringName = &""


func _ready() -> void:
	_load_csv()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.run_reset.connect(_on_run_reset)


func request_text(text_id: StringName) -> bool:
	if not _entries.has(text_id):
		push_warning("NarrativeManager: 未找到文本 ID：%s" % text_id)
		return false
	var entry: Dictionary = _entries[text_id]
	if bool(entry.get("once_per_run", true)) and _seen_this_run.has(text_id):
		return false
	if text_id == _current_id or text_id in _queue:
		return false
	_seen_this_run[text_id] = true
	_queue.append(text_id)
	_try_start_next()
	return true


func finish_current_text() -> void:
	if _current_id.is_empty():
		return
	var finished_id := _current_id
	_current_id = &""
	text_finished.emit(finished_id)
	_try_start_next()


func clear_queue() -> void:
	_queue.clear()
	_current_id = &""
	queue_cleared.emit()


func is_text_active() -> bool:
	return not _current_id.is_empty()


func queued_count() -> int:
	return _queue.size() + (0 if _current_id.is_empty() else 1)


func get_entry(text_id: StringName) -> Dictionary:
	return _entries.get(text_id, {}).duplicate(true)


func _try_start_next() -> void:
	if not _current_id.is_empty() or _queue.is_empty():
		return
	_current_id = _queue.pop_front()
	text_started.emit((_entries[_current_id] as Dictionary).duplicate(true))


func _load_csv() -> void:
	_entries.clear()
	var file := FileAccess.open(NARRATIVE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("NarrativeManager: 无法读取 %s" % NARRATIVE_DATA_PATH)
		return
	var headers := file.get_csv_line()
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.is_empty() or values[0].strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index in range(mini(headers.size(), values.size())):
			row[headers[index].strip_edges()] = values[index]
		var text_id := StringName(str(row.get("text_id", "")))
		if text_id.is_empty():
			continue
		row["text_id"] = text_id
		row["duration"] = float(row.get("duration", "3.0"))
		row["once_per_run"] = str(row.get("once_per_run", "true")).to_lower() != "false"
		_entries[text_id] = row


func _on_run_reset(_run_number: int) -> void:
	_queue.clear()
	_seen_this_run.clear()
	_current_id = &""
	queue_cleared.emit()
