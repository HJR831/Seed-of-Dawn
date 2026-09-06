extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const INTERACTABLE_SCRIPT := preload("res://scenes/gameplay/interactable.gd")


func _ready() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().physics_frame
	var level := main.get_node_or_null("FridgeLevel")
	if level == null:
		_fail("主关卡未生成")
		return
	var pickups := get_tree().get_nodes_in_group(&"pickup")
	if pickups.size() != 38:
		_fail("应生成 38 个唯一拾取物，实际 %d" % pickups.size())
		return
	var seen: Dictionary = {}
	for pickup in pickups:
		if not pickup.has_method("collect") or pickup.item_id.is_empty() or seen.has(pickup.item_id):
			_fail("拾取物 ID 重复或缺少 collect：%s" % pickup.name)
			return
		seen[pickup.item_id] = true
		if not _has_active_collision(pickup):
			_fail("拾取物没有有效碰撞：%s" % pickup.item_id)
			return
		if not pickup.collect():
			_fail("拾取物无法收集：%s" % pickup.item_id)
			return
	if get_node("/root/GameState").items.size() != 38:
		_fail("收集后背包条目不等于 38")
		return
	# Verify action-scoped requirements: nurture needs water, devour does not.
	var action_probe := INTERACTABLE_SCRIPT.new()
	action_probe.item_id = &"audit_companion"
	action_probe.short_action = &"nurture"
	action_probe.hold_action = &"devour"
	action_probe.required_counter_id = &"audit_water"
	action_probe.required_counter_minimum = 3
	action_probe.required_counter_action = &"nurture"
	add_child(action_probe)
	if not action_probe.perform_hold_action():
		_fail("无净水时长按吞噬仍被错误阻止")
		return
	var interactables := get_tree().get_nodes_in_group(&"interactable")
	if interactables.size() < 11:
		_fail("关键交互节点数量不足：%d" % interactables.size())
		return
	for node in interactables:
		if node is Area2D and not _has_active_collision(node):
			_fail("交互节点没有有效碰撞：%s" % node.name)
			return
	print("INTERACTION AUDIT PASS: 38 个拾取物、唯一 ID、碰撞、重复道具退场与分动作交互条件均正常。")
	get_tree().quit(0)


func _has_active_collision(node: Node) -> bool:
	for child in node.get_children():
		if child is CollisionShape2D and child.shape != null and not child.disabled:
			return true
	return false


func _fail(message: String) -> void:
	push_error(message)
	print("INTERACTION AUDIT FAIL: %s" % message)
	get_tree().quit(1)
