class_name PixelFeedbackOverlay
extends Control

## Full-screen programmatic pixel VFX. No UI/particle/overlay texture is used.

var _feedback_id: StringName = &""
var _elapsed := 0.0
var _duration := 0.0
var _particles: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func play_feedback(feedback_id: StringName, duration: float = 0.72) -> void:
	_feedback_id = feedback_id
	_elapsed = 0.0
	_duration = maxf(duration, 0.2)
	_particles.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash(str(feedback_id))) ^ Time.get_ticks_msec()
	var palette := _palette_for(feedback_id)
	var viewport_size := get_viewport_rect().size
	for index in range(30):
		var angle := rng.randf_range(0.0, TAU)
		var speed := rng.randf_range(70.0, 240.0)
		var origin := viewport_size * 0.5
		if feedback_id in [&"eldritch_eye", &"eldritch_pulse", &"root_glitch"]:
			origin += Vector2(rng.randf_range(-90.0, 90.0), rng.randf_range(-50.0, 50.0))
		else:
			origin = Vector2(rng.randf_range(24.0, viewport_size.x - 24.0), rng.randf_range(24.0, viewport_size.y - 24.0))
		_particles.append({
			"position": origin,
			"velocity": Vector2.RIGHT.rotated(angle) * speed,
			"size": rng.randi_range(3, 9) * 2,
			"color": palette[index % palette.size()],
			"spin": -1.0 if index % 2 == 0 else 1.0,
		})
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	for particle in _particles:
		particle.position = Vector2(particle.position) + Vector2(particle.velocity) * delta
		if _feedback_id in [&"petal", &"landfill_noise"]:
			particle.velocity = Vector2(particle.velocity) + Vector2(0.0, 70.0) * delta
	if _elapsed >= _duration:
		visible = false
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if _duration <= 0.0:
		return
	var ratio := clampf(_elapsed / _duration, 0.0, 1.0)
	var fade := pow(1.0 - ratio, 1.6)
	var viewport_size := size
	var base_color := _palette_for(_feedback_id)[0]
	# Stepped edge overlay and sparse scanlines keep the effect visibly pixel-based.
	for step in range(5):
		var inset := float(step * 12)
		var alpha := fade * (0.10 - step * 0.014)
		draw_rect(Rect2(inset, inset, viewport_size.x - inset * 2.0, 8.0), Color(base_color, alpha))
		draw_rect(Rect2(inset, viewport_size.y - inset - 8.0, viewport_size.x - inset * 2.0, 8.0), Color(base_color, alpha))
		draw_rect(Rect2(inset, inset, 8.0, viewport_size.y - inset * 2.0), Color(base_color, alpha))
		draw_rect(Rect2(viewport_size.x - inset - 8.0, inset, 8.0, viewport_size.y - inset * 2.0), Color(base_color, alpha))
	for y in range(0, int(viewport_size.y), 12):
		draw_rect(Rect2(0, y, viewport_size.x, 2), Color(base_color, fade * 0.025))
	_draw_signature(viewport_size * 0.5, fade)
	for index in range(_particles.size()):
		var particle := _particles[index]
		var particle_size := float(particle.size) * (0.65 + fade * 0.35)
		var color := Color(particle.color, fade * 0.90)
		var at := Vector2(particle.position).snapped(Vector2(2, 2))
		if _feedback_id in [&"petal", &"eldritch_eye", &"eldritch_pulse"]:
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -particle_size), at + Vector2(particle_size * 0.65, 0), at + Vector2(0, particle_size), at + Vector2(-particle_size * 0.65, 0)]), color)
		else:
			draw_rect(Rect2(at - Vector2.ONE * particle_size * 0.5, Vector2.ONE * particle_size), color)


func _draw_signature(center: Vector2, fade: float) -> void:
	match _feedback_id:
		&"eldritch_eye", &"eldritch_pulse":
			var eye_color := Color(0.72, 0.28, 0.96, fade * 0.34)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-190, 0), center + Vector2(-72, -58), center + Vector2(72, -58), center + Vector2(190, 0), center + Vector2(72, 58), center + Vector2(-72, 58)]), eye_color)
			draw_rect(Rect2(center + Vector2(-14, -54), Vector2(28, 108)), Color(0.05, 0.01, 0.08, fade * 0.75))
		&"eldritch_frost":
			for x in range(0, int(size.x), 48):
				var height := 18.0 + float((x / 48) % 4) * 9.0
				draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 20, 0), Vector2(x + 10, height)]), Color(0.70, 0.91, 1.0, fade * 0.48))
		&"golden_flash", &"warm_wind":
			for index in range(12):
				var direction := Vector2.RIGHT.rotated(TAU * index / 12.0)
				var start := center + direction * 80.0
				draw_line(start.snapped(Vector2(4, 4)), (center + direction * 240.0).snapped(Vector2(4, 4)), Color(1.0, 0.74, 0.24, fade * 0.36), 8.0)
		&"root_glitch":
			for index in range(9):
				var y := 120.0 + index * 54.0
				var offset := float((index * 79 + int(_elapsed * 1000.0)) % 260)
				draw_rect(Rect2(offset, y, 240.0, 8.0), Color(0.34, 1.0, 0.58, fade * 0.45))
		&"landfill_noise":
			for index in range(20):
				var x := float((index * 97 + int(_elapsed * 170.0)) % maxi(int(size.x), 1))
				var y := float((index * 53 + int(_elapsed * 80.0)) % maxi(int(size.y), 1))
				draw_rect(Rect2(x, y, 14, 8), Color(0.56, 0.64, 0.18, fade * 0.38))


func _palette_for(feedback_id: StringName) -> Array[Color]:
	match feedback_id:
		&"eldritch_eye", &"eldritch_pulse": return [Color(0.54, 0.08, 0.72), Color(0.92, 0.55, 1.0), Color(0.12, 0.01, 0.18)]
		&"eldritch_frost": return [Color(0.48, 0.74, 1.0), Color(0.82, 0.96, 1.0), Color(0.22, 0.48, 0.78)]
		&"golden_flash": return [Color(1.0, 0.72, 0.18), Color(1.0, 0.92, 0.50), Color(0.84, 0.42, 0.08)]
		&"warm_wind": return [Color(1.0, 0.42, 0.16), Color(1.0, 0.76, 0.36), Color(0.66, 0.16, 0.06)]
		&"root_glitch": return [Color(0.28, 0.96, 0.52), Color(0.82, 1.0, 0.48), Color(0.03, 0.16, 0.08)]
		&"petal": return [Color(0.74, 0.32, 0.86), Color(1.0, 0.72, 0.34), Color(0.46, 0.12, 0.58)]
		&"landfill_noise": return [Color(0.42, 0.52, 0.13), Color(0.72, 0.66, 0.22), Color(0.20, 0.25, 0.06)]
		_: return [Color(0.58, 0.31, 0.82), Color(0.82, 0.64, 1.0), Color(0.18, 0.08, 0.28)]
