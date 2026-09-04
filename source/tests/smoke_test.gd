extends SceneTree

const REQUIRED_RESOURCES := [
	"res://scenes/main/main.tscn",
	"res://scenes/levels/fridge_level.tscn",
	"res://scenes/player/sprout.tscn",
	"res://scenes/gameplay/charge_barrier.tscn",
	"res://scenes/ui/ending_screen.tscn",
]


func _init() -> void:
	_run_test()


func _run_test() -> void:
	var failures: Array[String] = []
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
		print("SMOKE TEST PASS: 五个核心场景及其脚本均可加载和实例化。")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("SMOKE TEST FAIL: %d 个问题。" % failures.size())
		quit(1)
