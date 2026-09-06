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
		if plan.bounds.size.x < 25000.0 or int(plan.ring_count) != 7 or int(plan.sector_count) < 12 or int(plan.sector_count) > 16:
			failures.append("种子 %d 未生成 25600 七环和 12–16 扇区" % seed_value)
		if plan.route_lanes.size() != 3 or plan.sector_themes.size() != plan.sector_count or plan.spawn.y <= plan.center.y:
			failures.append("种子 %d 缺少三条自底向上路线、主题扇区或底部出生点" % seed_value)
		for lane_index in range(plan.route_lanes.size()):
			var lane: Array = plan.route_lanes[lane_index]
			if lane.is_empty(): continue
			var lane_x := float(lane[0].x)
			for gate_index in range(1, lane.size()):
				if absf(float(lane[gate_index].x) - lane_x) > 0.001 or float(lane[gate_index].y) >= float(lane[gate_index - 1].y):
					failures.append("种子 %d 的路线 %d 没有保持自底向上的垂直通道" % [seed_value, lane_index])
					break
		if plan.chunk_index.size() != plan.locations.size() + plan.regions.size():
			failures.append("种子 %d 的逻辑分块索引不完整" % seed_value)
		var repeated := Generator.generate(seed_value)
		if plan.locations != repeated.locations or plan.ring_gates != repeated.ring_gates:
			failures.append("种子 %d 无法复现" % seed_value)
		var signature := "%s:%s" % [plan.sector_count, plan.locations[&"final_lid"]]
		signatures[signature] = true
	if signatures.size() < 25:
		failures.append("100 个种子的布局变化不足：仅 %d 种签名" % signatures.size())
	if failures.is_empty():
		print("PROCEDURAL MAP PASS: 100 个 25600 自底向上七层种子的复现、三路线、分块、关键顺序、重叠与仪式净空均通过。")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
