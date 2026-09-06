class_name WorldChunkManager
extends Node

signal active_chunks_changed(active_count: int)

var chunk_size := 1280.0
var active_radius := 2
var current_chunk := Vector2i.ZERO
var active_chunks: Dictionary = {}
var _player: Node2D
var _registered: Dictionary = {}


func configure(plan: Dictionary, player: Node2D) -> void:
	chunk_size = maxf(float(plan.get("chunk_size", 1280.0)), 320.0)
	_player = player
	_update_active_chunks(true)


func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		_update_active_chunks(false)


func register_streamable(node: CanvasItem, world_position: Vector2) -> void:
	var key := get_chunk_key(world_position)
	if not _registered.has(key):
		_registered[key] = []
	_registered[key].append(node)
	_apply_node_state(node, active_chunks.has(key))


func get_chunk_key(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / chunk_size), floori(world_position.y / chunk_size))


func get_summary() -> Dictionary:
	return {"chunk_size": chunk_size, "current_chunk": current_chunk, "active_count": active_chunks.size(), "registered_count": _registered.size()}


func _update_active_chunks(force: bool) -> void:
	var next_chunk := get_chunk_key(_player.global_position)
	if not force and next_chunk == current_chunk:
		return
	current_chunk = next_chunk
	active_chunks.clear()
	for y in range(current_chunk.y - active_radius, current_chunk.y + active_radius + 1):
		for x in range(current_chunk.x - active_radius, current_chunk.x + active_radius + 1):
			active_chunks[Vector2i(x, y)] = true
	for key in _registered:
		for node in _registered[key]:
			if is_instance_valid(node):
				_apply_node_state(node, active_chunks.has(key))
	active_chunks_changed.emit(active_chunks.size())


func _apply_node_state(node: CanvasItem, active: bool) -> void:
	node.visible = active
	if node is Node:
		node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
