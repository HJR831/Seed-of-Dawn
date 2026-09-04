extends SceneTree

const REQUIRED_RESOURCES := [
	"res://scenes/main/main.tscn",
	"res://scenes/levels/fridge_level.tscn",
	"res://scenes/player/sprout.tscn",
	"res://scenes/gameplay/charge_barrier.tscn",
	"res://scenes/gameplay/sticky_area.tscn",
	"res://scenes/gameplay/frost_area.tscn",
	"res://scenes/gameplay/pickup.tscn",
	"res://scenes/gameplay/interactable.tscn",
	"res://scenes/gameplay/narrative_trigger.tscn",
	"res://scenes/ui/dialogue_box.tscn",
	"res://scenes/ui/debug_panel.tscn",
	"res://scenes/ui/ending_screen.tscn",
]

const REQUIRED_SCRIPTS := [
	"res://autoload/game_state.gd",
	"res://autoload/audio_manager.gd",
	"res://autoload/narrative_manager.gd",
	"res://scenes/player/sprout.gd",
	"res://scenes/gameplay/charge_barrier.gd",
	"res://scenes/gameplay/sticky_area.gd",
	"res://scenes/gameplay/frost_area.gd",
	"res://scenes/gameplay/pickup.gd",
	"res://scenes/gameplay/interactable.gd",
	"res://scenes/gameplay/narrative_trigger.gd",
	"res://scenes/ui/dialogue_box.gd",
	"res://scenes/ui/debug_panel.gd",
	"res://tests/basic_systems_test.gd",
]


func _init() -> void:
	_run_test()


func _run_test() -> void:
	var failures: Array[String] = []
	for script_path in REQUIRED_SCRIPTS:
		if load(script_path) == null:
			failures.append("脚本无法加载：%s" % script_path)
	for resource_path in REQUIRED_RESOURCES:
		if not ResourceLoader.exists(resource_path):
			failures.append("缺少资源：%s" % resource_path)
			continue
		var packed_scene := load(resource_path) as PackedScene
		if packed_scene == null:
			failures.append("场景无法加载：%s" % resource_path)
			continue
		var instance := packed_scene.instantiate()
		if instance == null:
			failures.append("场景无法实例化：%s" % resource_path)
		else:
			instance.free()

	if failures.is_empty():
		print("SMOKE TEST PASS: 基础系统场景及其脚本均可加载和实例化。")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("SMOKE TEST FAIL: %d 个问题。" % failures.size())
		quit(1)
