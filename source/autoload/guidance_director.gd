extends Node

const GUIDANCE_DATA_PATH := "res://data/guidance_rules.csv"

signal guidance_issued(text_id: StringName, presentation: StringName, feedback_id: StringName)
signal history_changed

var history: Array[StringName] = []
var _configured := false
var _rules: Dictionary = {}
var _last_rule_seconds: Dictionary = {}
var adaptive_enabled := true
var _seconds_without_progress := 0.0


func _ready() -> void:
	_load_rules()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.item_collected.connect(_on_item_collected)
		game_state.counter_changed.connect(_on_counter_changed)
		game_state.flag_changed.connect(_on_flag_changed)
		game_state.run_reset.connect(_on_run_reset)
	var knowledge := get_node_or_null("/root/MapKnowledgeManager")
	if knowledge != null:
		knowledge.cell_discovered.connect(func(_ring: int, _sector: int) -> void: _mark_progress())


func _process(delta: float) -> void:
	if not _configured or not adaptive_enabled or get_tree().paused:
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not game_state.current_ending.is_empty():
		return
	_seconds_without_progress += delta
	if _seconds_without_progress < 90.0:
		return
	_seconds_without_progress = 0.0
	var knowledge := get_node_or_null("/root/MapKnowledgeManager")
	if knowledge != null and not knowledge.markers.is_empty():
		issue(&"adaptive_known_goal", &"dialogue", &"soft_pulse")


func configure(_plan: Dictionary) -> void:
	_configured = true


func issue(text_id: StringName, presentation: StringName = &"dialogue", feedback_id: StringName = &"", priority: int = 50) -> void:
	if text_id.is_empty():
		return
	if text_id not in history:
		history.append(text_id)
		history_changed.emit()
	if presentation == &"dialogue":
		var narrative := get_node_or_null("/root/NarrativeManager")
		if narrative != null:
			narrative.request_text(text_id, priority)
	guidance_issued.emit(text_id, presentation, feedback_id)


func get_history() -> Array[StringName]:
	return history.duplicate()


func get_rule_count() -> int:
	return _rules.size()


func _on_item_collected(item_id: StringName) -> void:
	if not _configured:
		return
	_mark_progress()
	var knowledge := get_node_or_null("/root/MapKnowledgeManager")
	if knowledge != null:
		knowledge.clear_markers_for_target(item_id)
	if _apply_data_rules(StringName("item:%s" % item_id)):
		return
	match item_id:
		&"corrupt_eye":
			var game_state := get_node("/root/GameState")
			if game_state.has_item(&"scarlet_ointment") and not game_state.has_item(&"frozen_heart"):
				issue(&"god_eye_after_ointment", &"center", &"eldritch_eye")
				_reveal_frozen_heart(knowledge)
			else:
				issue(&"god_watching", &"center", &"eldritch_eye")
		&"scarlet_ointment":
			var game_state := get_node("/root/GameState")
			if game_state.has_item(&"frozen_heart"):
				issue(&"god_ointment_late", &"center", &"eldritch_pulse")
			elif not game_state.has_item(&"corrupt_eye"):
				issue(&"god_ointment_waits", &"center", &"eldritch_pulse")
			else:
				issue(&"god_points_heart", &"center", &"eldritch_pulse")
				_reveal_frozen_heart(knowledge)
		&"frozen_heart":
			if knowledge != null:
				knowledge.clear_marker(&"frozen_heart_revelation")
			issue(&"god_favors", &"center", &"eldritch_frost")
		_:
			if str(item_id).begins_with("sprout_nodule_"):
				issue(&"sprout_nodule_found", &"dialogue", &"root_tug")
			elif item_id in [&"aluminum_foil", &"conductive_water", &"magnet_core"]:
				_try_reveal_root_probe()


func _on_counter_changed(counter_id: StringName, value: int) -> void:
	if not _configured:
		return
	if counter_id != &"ending_attempt_failed_count":
		_mark_progress()
	if counter_id == &"barcode_count" and value >= 3:
		_add_marker(&"barcode_terminal_hint", &"barcode_terminal", "sector", Color(1.0, 0.30, 0.22), &"barcode")
		issue(&"guide_barcode_complete", &"dialogue", &"corporate_scan")
	elif counter_id == &"ending_attempt_failed_count" and value == 2:
		issue(&"adaptive_entrance_hint", &"dialogue", &"soft_pulse")


func _on_flag_changed(flag_id: StringName, value: bool) -> void:
	if not _configured or not value:
		return
	_mark_progress()
	var knowledge := get_node_or_null("/root/MapKnowledgeManager")
	match flag_id:
		&"hongsan_root_helped":
			if knowledge != null:
				knowledge.clear_marker(&"hongsan_root_hint")
			_add_marker(&"bell_direction", &"bell_source", "direction", Color(0.84, 0.62, 1.0), &"bell")
		&"heard_bell":
			if knowledge != null:
				knowledge.clear_marker(&"bell_direction")
			_add_marker(&"warm_light_direction", &"warm_light", "direction", Color(1.0, 0.66, 0.26), &"warm_light")
			issue(&"bell_heard", &"dialogue", &"golden_flash")
		&"faced_warm_light":
			if knowledge != null:
				knowledge.clear_marker(&"warm_light_direction")
			_add_marker(&"hongsan_link_hint", &"hongsan_link", "approximate", Color(0.76, 0.42, 0.90), &"petal")


func _try_reveal_root_probe() -> void:
	var game_state := get_node("/root/GameState")
	if game_state.has_item(&"aluminum_foil") and game_state.has_item(&"conductive_water") and game_state.has_item(&"magnet_core"):
		_add_marker(&"temperature_probe_hint", &"temperature_probe", "sector", Color(0.94, 0.74, 0.22), &"root")
		issue(&"guide_root_scan", &"center", &"root_glitch")


func _reveal_frozen_heart(knowledge: Node) -> void:
	if knowledge != null:
		knowledge.add_or_update_marker(&"frozen_heart_revelation", {"target_id": &"frozen_heart", "reveal_mode": "exact", "icon_id": &"heart", "color": Color(0.66, 0.38, 1.0), "priority": 90})


func _add_marker(marker_id: StringName, target_id: StringName, mode: String, color: Color, icon_id: StringName) -> void:
	var knowledge := get_node_or_null("/root/MapKnowledgeManager")
	if knowledge != null:
		knowledge.add_or_update_marker(marker_id, {"target_id": target_id, "reveal_mode": mode, "color": color, "icon_id": icon_id, "priority": 50})


func _apply_data_rules(event_id: StringName) -> bool:
	var applied := false
	for rule_id in _rules:
		var rule: Dictionary = _rules[rule_id]
		if StringName(rule.get("event_id", &"")) != event_id:
			continue
		var now_seconds := Time.get_ticks_msec() / 1000.0
		var cooldown := float(rule.get("cooldown", 0.0))
		if cooldown > 0.0 and now_seconds - float(_last_rule_seconds.get(rule_id, -100000.0)) < cooldown:
			continue
		_last_rule_seconds[rule_id] = now_seconds
		applied = true
		var knowledge := get_node_or_null("/root/MapKnowledgeManager")
		var clear_rule := StringName(rule.get("clear_rule", &""))
		if knowledge != null and not clear_rule.is_empty():
			knowledge.clear_marker(clear_rule)
		var target_id := StringName(rule.get("marker_target", &""))
		if knowledge != null and not target_id.is_empty():
			knowledge.add_or_update_marker(StringName("%s_hint" % target_id), {
				"target_id": target_id,
				"reveal_mode": str(rule.get("marker_mode", "direction")),
				"color": _feedback_color(StringName(rule.get("feedback_id", &""))),
				"icon_id": StringName(rule.get("feedback_id", &"marker")),
				"priority": int(rule.get("priority", 50)),
			})
		issue(StringName(rule.get("text_id", &"")), StringName(rule.get("presentation", &"dialogue")), StringName(rule.get("feedback_id", &"")), int(rule.get("priority", 50)))
	return applied


func _feedback_color(feedback_id: StringName) -> Color:
	match feedback_id:
		&"golden_flash": return Color(1.0, 0.78, 0.20)
		&"warm_wind": return Color(1.0, 0.56, 0.22)
		&"frost": return Color(0.52, 0.86, 1.0)
		&"petal": return Color(0.76, 0.42, 0.90)
		&"landfill_noise": return Color(0.62, 0.72, 0.24)
		_: return Color(0.82, 0.46, 1.0)


func _load_rules() -> void:
	_rules.clear()
	var file := FileAccess.open(GUIDANCE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("GuidanceDirector: 无法读取 %s" % GUIDANCE_DATA_PATH)
		return
	var headers := file.get_csv_line()
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.is_empty() or values[0].strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index in range(mini(headers.size(), values.size())):
			row[headers[index].strip_edges()] = values[index]
		var rule_id := StringName(str(row.get("rule_id", "")))
		if not rule_id.is_empty():
			_rules[rule_id] = row


func _on_run_reset(_run_number: int) -> void:
	history.clear()
	_last_rule_seconds.clear()
	_configured = false
	_seconds_without_progress = 0.0
	history_changed.emit()


func _mark_progress() -> void:
	_seconds_without_progress = 0.0
