extends Node

signal run_reset(run_number: int)
signal ending_reached(ending_id: StringName)

var run_number: int = 0
var current_ending: StringName = &""
var run_seconds: float = 0.0
var input_distance: float = 0.0


func _process(delta: float) -> void:
	if current_ending.is_empty():
		run_seconds += delta


func reset_run() -> void:
	run_number += 1
	current_ending = &""
	run_seconds = 0.0
	input_distance = 0.0
	run_reset.emit(run_number)


func add_distance(amount: float) -> void:
	input_distance += maxf(amount, 0.0)


func finish_run(ending_id: StringName) -> void:
	if not current_ending.is_empty():
		return
	current_ending = ending_id
	ending_reached.emit(ending_id)

