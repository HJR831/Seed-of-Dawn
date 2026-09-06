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
	"res://scenes/gameplay/ritual_tracker.tscn",
	"res://scenes/gameplay/ending_entrance.tscn",
	"res://scenes/ui/dialogue_box.tscn",
	"res://scenes/ui/debug_panel.tscn",
	"res://scenes/ui/ending_screen.tscn",
	"res://scenes/ui/inventory_panel.tscn",
	"res://scenes/ui/map_panel.tscn",
	"res://scenes/ui/guidance_overlay.tscn",
	"res://tests/phase_20_endings_flow_test.tscn",
	"res://tests/phase_32_39_test.tscn",
	"res://tests/phase_32_endings_flow_test.tscn",
]

const REQUIRED_SCRIPTS := [
	"res://autoload/game_state.gd",
	"res://autoload/audio_manager.gd",
	"res://autoload/narrative_manager.gd",
	"res://autoload/map_knowledge_manager.gd",
	"res://autoload/guidance_director.gd",
	"res://autoload/item_effect_director.gd",
	"res://scenes/player/sprout.gd",
	"res://scenes/gameplay/charge_barrier.gd",
	"res://scenes/gameplay/sticky_area.gd",
	"res://scenes/gameplay/frost_area.gd",
	"res://scenes/gameplay/pickup.gd",
	"res://scenes/gameplay/interactable.gd",
	"res://scenes/gameplay/narrative_trigger.gd",
	"res://scenes/gameplay/ritual_tracker.gd",
	"res://scenes/gameplay/ending_entrance.gd",
	"res://systems/ending_ids.gd",
	"res://systems/ending_resolver.gd",
	"res://systems/procedural_map_generator.gd",
	"res://scenes/gameplay/route_flag_area.gd",
	"res://scenes/gameplay/counter_console.gd",
	"res://scenes/gameplay/sequence_console.gd",
	"res://scenes/gameplay/compressor_idle_ritual.gd",
	"res://scenes/gameplay/stillness_command.gd",
	"res://scenes/gameplay/directional_trial.gd",
	"res://scenes/ui/inventory_panel.gd",
	"res://scenes/ui/map_canvas.gd",
	"res://scenes/ui/map_panel.gd",
	"res://scenes/ui/guidance_overlay.gd",
	"res://systems/world_chunk_manager.gd",
	"res://scenes/ui/dialogue_box.gd",
	"res://scenes/ui/debug_panel.gd",
	"res://tests/basic_systems_test.gd",
	"res://tests/ending_resolver_test.gd",
	"res://tests/phase_13_20_test.gd",
	"res://tests/save_roundtrip_test.gd",
	"res://tests/ending_screen_test.gd",
	"res://tests/procedural_map_test.gd",
	"res://tests/phase_20_32_test.gd",
	"res://tests/phase_20_endings_flow_test.gd",
	"res://tests/phase_32_39_test.gd",
	"res://tests/phase_32_endings_flow_test.gd",
]


func _init() -> void:
	_run_test()


func _run_test() -> void:
	var failures: Array[String] = []
	for script_path in REQUIRED_SCRIPTS:
		var script := load(script_path) as Script
		if script == null or not script.can_instantiate():
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
