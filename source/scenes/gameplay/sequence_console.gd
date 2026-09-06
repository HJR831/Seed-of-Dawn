extends Node2D

signal sequence_completed

@export var ritual_id: StringName = &"root_node_sequence"
@export var node_spacing: float = 150.0
@export var step_timeout: float = 5.0

const EXPECTED_SEQUENCE := [0, 1, 1, 2]

var _current_pad := -1
var _progress := 0
var _elapsed := 0.0
var _complete := false
var _labels: Array[Label] = []
var _sprites: Array[Sprite2D] = []
var _dark_texture: Texture2D
var _lit_texture: Texture2D
var _error_texture: Texture2D


func _ready() -> void:
	add_to_group(&"interactable")
	var library := get_node_or_null("/root/AssetLibrary")
	if library != null:
		_dark_texture = library.get_texture(&"env_electric_node_dark.png")
		_lit_texture = library.get_texture(&"env_electric_node_lit.png")
		_error_texture = library.get_texture(&"env_electric_node_error.png")
	for index in range(3):
		_build_pad(index)
	queue_redraw()


func _process(delta: float) -> void:
	if _complete or _progress == 0:
		return
	_elapsed += delta
	if _elapsed > step_timeout:
		_reset_sequence()


func _unhandled_input(event: InputEvent) -> void:
	if _current_pad >= 0 and event.is_action_pressed(&"interact"):
		register_node(_current_pad)
		get_viewport().set_input_as_handled()


func register_node(index: int) -> bool:
	if _complete:
		return true
	if index != EXPECTED_SEQUENCE[_progress]:
		_show_error(index)
		var effects := get_node_or_null("/root/ItemEffectDirector")
		if effects != null and effects.has_method("has_effect") and effects.has_effect(&"bridge_charge") and _progress > 0:
			_progress = maxi(_progress - 1, 0)
			_elapsed = 0.0
			_update_labels()
			get_node("/root/AudioManager").play_sfx(&"effect_warning")
			return false
		_reset_sequence()
		get_node("/root/AudioManager").play_sfx(&"ritual_error")
		return false
	_progress += 1
	_elapsed = 0.0
	get_node("/root/AudioManager").play_sfx(StringName("ritual_step_%d" % _progress))
	if _progress >= EXPECTED_SEQUENCE.size():
		_complete = true
		get_node("/root/GameState").complete_ritual(ritual_id)
		sequence_completed.emit()
	_update_labels()
	queue_redraw()
	return _complete


func _build_pad(index: int) -> void:
	var area := Area2D.new()
	area.position = Vector2((index - 1) * node_spacing, 0.0)
	area.collision_layer = 16
	area.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 58.0
	collision.shape = shape
	area.add_child(collision)
	var label := Label.new()
	label.position = Vector2(-48, -20)
	label.size = Vector2(96, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.text = ["I", "II", "III"][index]
	area.add_child(label)
	_labels.append(label)
	var sprite := Sprite2D.new()
	sprite.texture = _dark_texture
	sprite.z_index = -1
	if _dark_texture != null:
		var extent := maxf(_dark_texture.get_size().x, _dark_texture.get_size().y)
		sprite.scale = Vector2.ONE * (108.0 / maxf(extent, 1.0))
	area.add_child(sprite)
	_sprites.append(sprite)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group(&"player"):
			_current_pad = index
	)
	area.body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group(&"player") and _current_pad == index:
			_current_pad = -1
	)
	add_child(area)


func _draw() -> void:
	# The numbered pads and their state textures are the only visual cue.
	# Do not draw an extra circular interaction halo around them.
	pass


func _reset_sequence() -> void:
	_progress = 0
	_elapsed = 0.0
	_update_labels()


func _update_labels() -> void:
	for index in range(_labels.size()):
		_labels[index].modulate = Color(1.0, 0.88, 0.38) if _complete else Color.WHITE
		if index < _sprites.size() and is_instance_valid(_sprites[index]):
			_sprites[index].texture = _lit_texture if _complete or index == _current_pad and _progress > 0 else _dark_texture


func _show_error(index: int) -> void:
	if _error_texture == null or index < 0 or index >= _sprites.size():
		return
	_sprites[index].texture = _error_texture
	get_tree().create_timer(0.28).timeout.connect(func() -> void:
		if index < _sprites.size() and is_instance_valid(_sprites[index]):
			_sprites[index].texture = _dark_texture
	)
