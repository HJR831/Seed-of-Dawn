extends Node

signal ending_unlocked(ending_id: StringName)

var unlocked_endings: Dictionary = {}


func unlock_ending(ending_id: StringName) -> void:
	if unlocked_endings.has(ending_id):
		return
	unlocked_endings[ending_id] = true
	ending_unlocked.emit(ending_id)


func is_ending_unlocked(ending_id: StringName) -> bool:
	return unlocked_endings.has(ending_id)


func unlocked_count() -> int:
	return unlocked_endings.size()


func clear_unlocked_endings() -> void:
	unlocked_endings.clear()
