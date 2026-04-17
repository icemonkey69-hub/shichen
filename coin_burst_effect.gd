extends Node2D

@export var lifetime := 0.42

var elapsed := 0.0
var particles: Array[Dictionary] = []


func _ready() -> void:
	z_index = 12
	if particles.is_empty():
		_configure_default_particles()
	queue_redraw()


func configure_burst(particle_count: int = 8, burst_scale: float = 1.0) -> void:
	particles.clear()
	var count := maxi(particle_count, 1)
	for i in count:
		var angle := (TAU / float(count)) * float(i) + randf_range(-0.25, 0.25)
		var speed := randf_range(70.0, 124.0) * burst_scale
		var radius := randf_range(2.5, 4.8) * minf(1.4, 0.85 + burst_scale * 0.12)
		particles.append({
			"position": Vector2.ZERO,
			"velocity": Vector2.RIGHT.rotated(angle) * speed + Vector2(0, -36.0),
			"radius": radius,
		})
	if is_inside_tree():
		queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	for particle in particles:
		particle["position"] = Vector2(particle["position"]) + Vector2(particle["velocity"]) * delta
		particle["velocity"] = Vector2(particle["velocity"]) * 0.9 + Vector2(0, 180.0 * delta)

	queue_redraw()
	if elapsed >= lifetime:
		queue_free()


func _draw() -> void:
	var alpha := clampf(1.0 - elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	for particle in particles:
		var particle_position := Vector2(particle["position"])
		var radius := float(particle["radius"])
		draw_circle(particle_position + Vector2(0, 1.5), radius + 0.8, Color(0.24, 0.15, 0.04, 0.42 * alpha))
		draw_circle(particle_position, radius, Color(0.97, 0.83, 0.21, 0.96 * alpha))
		draw_circle(particle_position + Vector2(-radius * 0.18, -radius * 0.18), radius * 0.38, Color(1.0, 0.96, 0.7, 0.75 * alpha))


func _configure_default_particles() -> void:
	configure_burst()
