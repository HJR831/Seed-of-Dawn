extends Node

signal ending_unlocked(ending_id: StringName)
signal progress_loaded
signal progress_cleared

const SAVE_VERSION := 1
const SAVE_PATH := "user://save_data.cfg"

var unlocked_endings: Dictionary = {}
var run_count: int = 0
var first_ending_seen: bool = false
var text_skip_unlocked: bool = false
var tutorial_seen: bool = false
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.9


func _ready() -> void:
	load_progress()


func unlock_ending(ending_id: StringName) -> void:
	if unlocked_endings.has(ending_id):
		return
	unlocked_endings[ending_id] = true
	first_ending_seen = true
	text_skip_unlocked = true
	_save_to_path(SAVE_PATH)
	ending_unlocked.emit(ending_id)


func is_ending_unlocked(ending_id: StringName) -> bool:
	return unlocked_endings.has(ending_id)


func unlocked_count() -> int:
	return unlocked_endings.size()


func record_run_started() -> void:
	run_count += 1
	_save_to_path(SAVE_PATH)


func clear_unlocked_endings() -> void:
	unlocked_endings.clear()
	first_ending_seen = false
	text_skip_unlocked = false
	tutorial_seen = false
	_save_to_path(SAVE_PATH)
	progress_cleared.emit()


func save_progress() -> bool:
	return _save_to_path(SAVE_PATH)


func load_progress() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var loaded := _load_from_path(SAVE_PATH)
	if loaded:
		progress_loaded.emit()
		return true
	_backup_corrupt_save()
	_reset_data()
	_save_to_path(SAVE_PATH)
	return false


func save_to_path(path: String) -> bool:
	return _save_to_path(path)


func load_from_path(path: String) -> bool:
	return _load_from_path(path)


func _save_to_path(path: String) -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("progress", "unlocked_ending_ids", PackedStringArray(unlocked_endings.keys()))
	config.set_value("progress", "run_count", run_count)
	config.set_value("progress", "first_ending_seen", first_ending_seen)
	config.set_value("progress", "text_skip_unlocked", text_skip_unlocked)
	config.set_value("progress", "tutorial_seen", tutorial_seen)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	var error := config.save(path)
	if error != OK:
		push_warning("ProgressState: 存档写入失败：%s" % error_string(error))
		return false
	return true


func _load_from_path(path: String) -> bool:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		push_warning("ProgressState: 存档读取失败：%s" % error_string(error))
		return false
	var version := int(config.get_value("meta", "save_version", 0))
	if version <= 0 or version > SAVE_VERSION:
		push_warning("ProgressState: 不支持的存档版本 %d" % version)
		return false
	_reset_data()
	var ending_ids: PackedStringArray = config.get_value("progress", "unlocked_ending_ids", PackedStringArray())
	for ending_id in ending_ids:
		unlocked_endings[StringName(ending_id)] = true
	run_count = maxi(int(config.get_value("progress", "run_count", 0)), 0)
	first_ending_seen = bool(config.get_value("progress", "first_ending_seen", false))
	text_skip_unlocked = bool(config.get_value("progress", "text_skip_unlocked", false))
	tutorial_seen = bool(config.get_value("progress", "tutorial_seen", false))
	master_volume = clampf(float(config.get_value("audio", "master", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music", 0.8)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx", 0.9)), 0.0, 1.0)
	_apply_audio_settings()
	return true


func _reset_data() -> void:
	unlocked_endings.clear()
	run_count = 0
	first_ending_seen = false
	text_skip_unlocked = false
	tutorial_seen = false
	master_volume = 1.0
	music_volume = 0.8
	sfx_volume = 0.9


func _apply_audio_settings() -> void:
	for bus_and_value in [[&"Master", master_volume], [&"Music", music_volume], [&"SFX", sfx_volume]]:
		var bus_index := AudioServer.get_bus_index(bus_and_value[0])
		if bus_index >= 0:
			AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(float(bus_and_value[1]), 0.0001)))


func mark_tutorial_seen() -> void:
	if tutorial_seen:
		return
	tutorial_seen = true
	_save_to_path(SAVE_PATH)


func _backup_corrupt_save() -> void:
	var absolute_source := ProjectSettings.globalize_path(SAVE_PATH)
	var absolute_backup := "%s.corrupt-%d" % [absolute_source, Time.get_unix_time_from_system()]
	var error := DirAccess.rename_absolute(absolute_source, absolute_backup)
	if error != OK:
		push_warning("ProgressState: 损坏存档备份失败：%s" % error_string(error))
