extends SceneTree

const Generator := preload("res://systems/procedural_map_generator.gd")


func _init() -> void:
	var failures: Array[String] = []
	var signatures: Dictionary = {}
	for seed_value in range(1, 101):
		var plan := Generator.generate(seed_value)
		var errors := Generator.validate_plan(plan)
		if not errors.is_empty():
			failures.append("种子 %d 验证失败：%s" % [seed_value, errors])
		if bool(plan.get("used_fallback", true)):
			failures.append("种子 %d 意外使用后备布局" % seed_value)
		var repeated := Generator.generate(seed_value)
		if plan.locations != repeated.locations or plan.ring_gates != repeated.ring_gates:
			failures.append("种子 %d 无法复现" % seed_value)
		var signature := "%s:%s" % [plan.sector_count, plan.locations[&"final_lid"]]
		signatures[signature] = true
	if signatures.size() < 25:
		failures.append("100 个种子的布局变化不足：仅 %d 种签名" % signatures.size())
	if failures.is_empty():
		print("PROCEDURAL MAP PASS: 100 个种子的复现、连通约束、关键顺序、重叠与仪式净空均通过。")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

