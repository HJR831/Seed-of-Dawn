extends Area2D

@export var area_size := Vector2(300.0, 180.0)
@export_range(0.1, 1.0, 0.05) var speed_multiplier: float = 0.45
@export var area_color := Color(0.18, 0.34, 0.12, 0.72)
@export var flag_on_enter: StringName = &""
@export var surface_texture_name: StringName = &""

var _affected_players: Dictionary = {}
var _surface_textures: Array[Texture2D] = []
var _surface_object_texture: Texture2D
var _animation_time := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	var asset_library := get_node_or_null("/root/AssetLibrary")
	if asset_library != null:
		for index in range(1, 6):
			var texture: Texture2D = asset_library.get_texture(StringName("env_slime_pool_%02d.png" % index))
			if texture != null:
				_surface_textures.append(texture)
		if not surface_texture_name.is_empty():
			_surface_object_texture = asset_library.get_texture(surface_texture_name)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = area_size
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func _process(delta: float) -> void:
	if _surface_textures.size() > 1 and is_visible_in_tree():
		_animation_time += delta
		queue_redraw()


func _draw() -> void:
	if not _surface_textures.is_empty():
		var frame := int(_animation_time / 0.32) % _surface_textures.size()
		draw_texture_rect(_surface_textures[frame], Rect2(-area_size * 0.5, area_size), false, Color(1.0, 1.0, 1.0, 0.72))
		if _surface_object_texture != null:
			draw_texture_rect(_surface_object_texture, Rect2(Vector2(-140.0, -104.0), Vector2(280.0, 208.0)), false, Color(1.0, 1.0, 1.0, 0.92))
		return
	for offset in [Vector2(-90, -18), Vector2(15, 30), Vector2(92, -36)]:
		draw_circle(offset, 13.0, Color(0.42, 0.56, 0.25, 0.55), false, 3.0)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player") or not body.has_method("add_temporary_speed_modifier"):
		return
	_affected_players[body] = true
	var effects := get_node_or_null("/root/ItemEffectDirector")
	var effective_multiplier := speed_multiplier
	if effects != null and effects.has_method("get_hazard_speed_multiplier"):
		effective_multiplier = float(effects.get_hazard_speed_multiplier(&"sticky", speed_multiplier))
	body.add_temporary_speed_modifier(StringName("sticky_%d" % get_instance_id()), effective_multiplier)
	if effects != null and effects.has_method("enter_hazard"):
		effects.enter_hazard(&"sticky")
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and not flag_on_enter.is_empty():
		game_state.set_flag(flag_on_enter)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"sticky_enter")


func _on_body_exited(body: Node2D) -> void:
	if not _affected_players.erase(body):
		return
	if body.has_method("remove_speed_modifier"):
		body.remove_speed_modifier(StringName("sticky_%d" % get_instance_id()))
	var effects := get_node_or_null("/root/ItemEffectDirector")
	if effects != null and effects.has_method("leave_hazard"):
		effects.leave_hazard(&"sticky")
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"sticky_exit")
