extends Node

signal run_reset(run_number: int)
signal ending_reached(ending_id: StringName)
signal stat_changed(stat_id: StringName, value: int)
signal item_collected(item_id: StringName)
signal flag_changed(flag_id: StringName, value: bool)
signal ritual_changed(ritual_id: StringName, completed: bool)
signal counter_changed(counter_id: StringName, value: int)

const STAT_IDS: Array[StringName] = [
	&"devour", &"nurture", &"noise", &"destruction", &"corruption"
]

var run_number: int = 0
var current_ending: StringName = &""
var devour: int = 0
var nurture: int = 0
var noise: int = 0
var destruction: int = 0
var corruption: int = 0
var items: Dictionary = {}
var counters: Dictionary = {}
var flags: Dictionary = {}
var rituals: Dictionary = {}
var last_exit: StringName = &"none"
var run_seconds: float = 0.0
var input_distance: float = 0.0
var optional_nutrients_total: int = 0
var optional_nutrients_eaten: int = 0
var run_seed: int = 1


func _process(delta: float) -> void:
	if current_ending.is_empty():
		run_seconds += delta


func reset_run(seed_override: int = -1) -> void:
	run_number += 1
	if seed_override > 0:
		run_seed = seed_override
	else:
		run_seed = maxi(int((Time.get_ticks_usec() ^ hash(Time.get_datetime_string_from_system())) & 0x7fffffff), 1)
	current_ending = &""
	devour = 0
	nurture = 0
	noise = 0
	destruction = 0
	corruption = 0
	items.clear()
	counters.clear()
	flags.clear()
	rituals.clear()
	last_exit = &"none"
	run_seconds = 0.0
	input_distance = 0.0
	optional_nutrients_total = 0
	optional_nutrients_eaten = 0
	run_reset.emit(run_number)


func add_stat(stat_id: StringName, amount: int) -> void:
	if amount == 0 or stat_id not in STAT_IDS:
		return
	var next_value := maxi(get_stat(stat_id) + amount, 0)
	set(stat_id, next_value)
	stat_changed.emit(stat_id, next_value)


func get_stat(stat_id: StringName) -> int:
	if stat_id not in STAT_IDS:
		return 0
	return int(get(stat_id))


func collect_item(item_id: StringName) -> bool:
	if item_id.is_empty() or items.has(item_id):
		return false
	items[item_id] = true
	item_collected.emit(item_id)
	return true


func has_item(item_id: StringName) -> bool:
	return items.has(item_id)


func set_flag(flag_id: StringName, value: bool = true) -> void:
	if flag_id.is_empty() or bool(flags.get(flag_id, false)) == value:
		return
	flags[flag_id] = value
	flag_changed.emit(flag_id, value)


func has_flag(flag_id: StringName) -> bool:
	return bool(flags.get(flag_id, false))


func complete_ritual(ritual_id: StringName) -> void:
	if ritual_id.is_empty() or rituals.has(ritual_id):
		return
	rituals[ritual_id] = true
	ritual_changed.emit(ritual_id, true)


func increment_counter(counter_id: StringName, amount: int = 1) -> int:
	if counter_id.is_empty() or amount == 0:
		return int(counters.get(counter_id, 0))
	var next_value := maxi(int(counters.get(counter_id, 0)) + amount, 0)
	counters[counter_id] = next_value
	counter_changed.emit(counter_id, next_value)
	return next_value


func get_counter(counter_id: StringName) -> int:
	return int(counters.get(counter_id, 0))


func add_distance(amount: float) -> void:
	input_distance += maxf(amount, 0.0)


func finish_run(ending_id: StringName) -> void:
	if not current_ending.is_empty():
		return
	current_ending = ending_id
	ending_reached.emit(ending_id)


func make_snapshot() -> Dictionary:
	return {
		"devour": devour,
		"nurture": nurture,
		"noise": noise,
		"destruction": destruction,
		"corruption": corruption,
		"items": items.duplicate(true),
		"counters": counters.duplicate(true),
		"flags": flags.duplicate(true),
		"rituals": rituals.duplicate(true),
		"last_exit": last_exit,
		"run_seconds": run_seconds,
		"input_distance": input_distance,
		"optional_nutrients_total": optional_nutrients_total,
		"optional_nutrients_eaten": optional_nutrients_eaten,
		"run_seed": run_seed,
	}
