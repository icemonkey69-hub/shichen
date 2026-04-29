extends Node2D
class_name BattleTerrain

@export var play_area := Rect2(-1000.0, -1000.0, 2000.0, 2000.0)
@export var boss_spawn_offset := Vector2.ZERO
@export var tile_width := 128.0
@export var tile_height := 64.0
@export var show_bounds := false

@onready var spawn_marker: Marker2D = get_node_or_null("出生点") as Marker2D
@onready var bounds_line: Line2D = get_node_or_null("场地边界") as Line2D


func _ready() -> void:
	z_as_relative = false
	z_index = -100
	_sync_bounds_line()
	queue_redraw()


func get_play_area() -> Rect2:
	return play_area


func get_spawn_position() -> Vector2:
	if spawn_marker != null:
		return spawn_marker.global_position
	return play_area.position + play_area.size * 0.5


func get_boss_spawn_position() -> Vector2:
	return play_area.position + play_area.size * 0.5 + boss_spawn_offset


func _draw() -> void:
	draw_rect(play_area.grow(256.0), Color(0.145, 0.245, 0.18, 1.0), true)
	_draw_isometric_grass_tiles()
	_draw_landmarks()
	_draw_spawn_marker()


func _draw_isometric_grass_tiles() -> void:
	var half_w := tile_width * 0.5
	var half_h := tile_height * 0.5
	var limit := int(ceil(maxf(play_area.size.x / tile_width, play_area.size.y / tile_height))) + 12

	for y in range(-limit, limit + 1):
		for x in range(-limit, limit + 1):
			var center := Vector2((x - y) * half_w, (x + y) * half_h)
			if not play_area.grow(tile_width).has_point(center):
				continue
			var shade := 0.018 if (x + y) % 2 == 0 else -0.006
			var tile_color := Color(0.18 + shade, 0.34 + shade, 0.20 + shade, 1.0)
			var points := PackedVector2Array([
				center + Vector2(0.0, -half_h),
				center + Vector2(half_w, 0.0),
				center + Vector2(0.0, half_h),
				center + Vector2(-half_w, 0.0),
			])
			draw_colored_polygon(points, tile_color)
			draw_polyline(points + PackedVector2Array([points[0]]), Color(0.07, 0.15, 0.10, 0.28), 1.0, true)

	draw_line(Vector2(play_area.position.x, 0.0), Vector2(play_area.position.x + play_area.size.x, 0.0), Color(0.42, 0.74, 0.40, 0.65), 3.0)
	draw_line(Vector2(0.0, play_area.position.y), Vector2(0.0, play_area.position.y + play_area.size.y), Color(0.42, 0.74, 0.40, 0.65), 3.0)


func _draw_landmarks() -> void:
	_draw_dirt_patch(Vector2(-360, 120), Vector2(330, 150), -0.16)
	_draw_dirt_patch(Vector2(410, -210), Vector2(260, 120), 0.25)
	_draw_dirt_patch(Vector2(250, 430), Vector2(420, 135), -0.08)

	for point in [Vector2(-640, -280), Vector2(-520, -340), Vector2(620, 260), Vector2(710, 210), Vector2(-180, 520), Vector2(530, -560)]:
		_draw_grass_clump(point)

	for point in [Vector2(-780, 420), Vector2(-720, 470), Vector2(820, -130), Vector2(880, -90), Vector2(120, -620)]:
		_draw_stone(point)


func _draw_dirt_patch(center: Vector2, size: Vector2, tilt: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(-size.x * 0.55, -size.y * 0.10).rotated(tilt),
		center + Vector2(-size.x * 0.22, -size.y * 0.48).rotated(tilt),
		center + Vector2(size.x * 0.45, -size.y * 0.36).rotated(tilt),
		center + Vector2(size.x * 0.58, size.y * 0.10).rotated(tilt),
		center + Vector2(size.x * 0.18, size.y * 0.48).rotated(tilt),
		center + Vector2(-size.x * 0.48, size.y * 0.28).rotated(tilt),
	])
	draw_colored_polygon(points, Color(0.34, 0.24, 0.14, 0.85))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.20, 0.13, 0.08, 0.5), 2.0, true)


func _draw_grass_clump(center: Vector2) -> void:
	for i in range(5):
		var offset := Vector2(cos(float(i) * 1.7) * 18.0, sin(float(i) * 1.3) * 10.0)
		draw_circle(center + offset, 18.0 - float(i % 2) * 4.0, Color(0.10, 0.39 + float(i) * 0.015, 0.18, 0.92))
	draw_circle(center + Vector2(4, -6), 12.0, Color(0.24, 0.55, 0.22, 0.72))


func _draw_stone(center: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(-20, -10),
		center + Vector2(-4, -22),
		center + Vector2(20, -12),
		center + Vector2(24, 9),
		center + Vector2(2, 22),
		center + Vector2(-22, 10),
	])
	draw_colored_polygon(points, Color(0.36, 0.42, 0.39, 1.0))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.14, 0.18, 0.16, 0.65), 2.0, true)
	draw_line(center + Vector2(-8, -12), center + Vector2(10, -2), Color(0.58, 0.65, 0.60, 0.5), 2.0)


func _draw_spawn_marker() -> void:
	var center := Vector2.ZERO
	draw_circle(center, 10.0, Color(0.96, 0.78, 0.25, 0.95))
	draw_arc(center, 22.0, 0.0, TAU, 32, Color(0.96, 0.78, 0.25, 0.55), 3.0)


func _sync_bounds_line() -> void:
	if bounds_line == null:
		return
	var min_corner := play_area.position
	var max_corner := play_area.position + play_area.size
	bounds_line.visible = show_bounds
	bounds_line.points = PackedVector2Array([
		min_corner,
		Vector2(max_corner.x, min_corner.y),
		max_corner,
		Vector2(min_corner.x, max_corner.y),
	])
