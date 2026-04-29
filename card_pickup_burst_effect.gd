extends Node2D

@export var lifetime := 0.34

var elapsed := 0.0
var burst_scale := 1.0
var shard_angles: PackedFloat32Array = []


func _ready() -> void:
	z_index = 18
	if shard_angles.is_empty():
		configure_burst()
	queue_redraw()


func configure_burst(scale_value: float = 1.0, shard_count: int = 7) -> void:
	burst_scale = maxf(scale_value, 0.5)
	shard_angles.clear()
	var safe_count: int = maxi(shard_count, 4)
	for index in safe_count:
		var angle: float = (TAU / float(safe_count)) * float(index) + randf_range(-0.18, 0.18)
		shard_angles.append(angle)
	if is_inside_tree():
		queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()


func _draw() -> void:
	var progress: float = clampf(elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	var alpha: float = 1.0 - progress
	var ring_radius: float = lerpf(10.0, 34.0, progress) * burst_scale
	var inner_radius: float = lerpf(6.0, 18.0, progress) * burst_scale
	var center_glow_radius: float = lerpf(11.0, 4.0, progress) * burst_scale

	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, Color(1.0, 0.93, 0.64, 0.82 * alpha), 2.4)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 40, Color(1.0, 0.82, 0.32, 0.55 * alpha), 1.6)
	draw_circle(Vector2.ZERO, center_glow_radius, Color(1.0, 0.95, 0.72, 0.22 * alpha))

	for angle in shard_angles:
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var distance: float = lerpf(6.0, 26.0, progress) * burst_scale
		var shard_center: Vector2 = direction * distance
		var tangent: Vector2 = Vector2(-direction.y, direction.x)
		var shard_length: float = lerpf(10.0, 4.0, progress) * burst_scale
		var shard_width: float = lerpf(3.4, 1.2, progress) * burst_scale
		var points := PackedVector2Array([
			shard_center + direction * shard_length,
			shard_center - direction * shard_length * 0.25 + tangent * shard_width,
			shard_center - direction * shard_length * 0.25 - tangent * shard_width,
		])
		draw_colored_polygon(points, Color(1.0, 0.9, 0.54, 0.9 * alpha))
