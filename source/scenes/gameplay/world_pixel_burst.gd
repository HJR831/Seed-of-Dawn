class_name WorldPixelBurst
extends Node2D

## Short-lived world-space particles made entirely from snapped rectangles and
## diamonds. Used for pickups and barrier breaks; no particle texture is needed.

var _particles: Array[Dictionary] = []
var _elapsed := 0.0
var _duration := 0.62


func configure(color: Color, count: int = 18, force: float = 150.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec() ^ int(global_position.x * 17.0 + global_position.y * 31.0)
	for index in range(count):
		var angle := TAU * float(index) / float(maxi(count, 1)) + rng.randf_range(-0.18, 0.18)
		_particles.append({
			"position": Vector2.ZERO,
			"velocity": Vector2.RIGHT.rotated(angle) * rng.randf_range(force * 0.45, force),
			"size": float(rng.randi_range(2, 5) * 2),
			"color": color.lightened(rng.randf_range(0.0, 0.28)),
			"diamond": index % 3 == 0,
		})
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	for particle in _particles:
		particle.position = Vector2(particle.position) + Vector2(particle.velocity) * delta
		particle.velocity = Vector2(particle.velocity) * pow(0.08, delta)
	if _elapsed >= _duration:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var fade := clampf(1.0 - _elapsed / _duration, 0.0, 1.0)
	for particle in _particles:
		var at := Vector2(particle.position).snapped(Vector2(2, 2))
		var pixel_size := float(particle.size)
		var color := Color(particle.color, fade)
		if bool(particle.diamond):
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -pixel_size), at + Vector2(pixel_size, 0), at + Vector2(0, pixel_size), at + Vector2(-pixel_size, 0)]), color)
		else:
			draw_rect(Rect2(at - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), color)
