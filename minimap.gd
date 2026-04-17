extends Control
class_name Minimap

@export var play_area := Rect2(-1000.0, -1000.0, 2000.0, 2000.0)
@export var background_color := Color(0.03, 0.03, 0.03, 0.88)
@export var border_color := Color(1, 1, 1, 0.95)
@export var player_color := Color(1, 1, 1, 1)
@export var enemy_color := Color(0.92, 0.2, 0.2, 0.95)
@export var boss_color := Color(1.0, 0.58, 0.14, 1.0)
@export var border_width := 2.0
@export var padding := 8.0
@export var player_radius := 3.2
@export var enemy_radius := 2.4
@export var boss_radius := 4.2

var player: Node2D


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var area_size := size
	draw_rect(Rect2(Vector2.ZERO, area_size), background_color, true)
	draw_rect(Rect2(Vector2.ZERO, area_size), border_color, false, border_width)

	if play_area.size.x <= 0.0 or play_area.size.y <= 0.0:
		return

	for enemy_node in get_tree().get_nodes_in_group("enemy"):
		var enemy := enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue

		var marker_pos := _world_to_minimap(enemy.global_position)
		if bool(enemy.get("is_boss")):
			_draw_boss_marker(marker_pos)
		else:
			draw_circle(marker_pos, enemy_radius, enemy_color)

	if player != null and is_instance_valid(player):
		draw_circle(_world_to_minimap(player.global_position), player_radius, player_color)


func _world_to_minimap(world_position: Vector2) -> Vector2:
	var inner_size := Vector2(
		maxf(size.x - padding * 2.0, 1.0),
		maxf(size.y - padding * 2.0, 1.0)
	)
	var normalized := Vector2(
		(world_position.x - play_area.position.x) / play_area.size.x,
		(world_position.y - play_area.position.y) / play_area.size.y
	)
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)
	return Vector2(
		padding + normalized.x * inner_size.x,
		padding + normalized.y * inner_size.y
	)


func _draw_boss_marker(marker_pos: Vector2) -> void:
	var points := PackedVector2Array([
		marker_pos + Vector2(0.0, -boss_radius),
		marker_pos + Vector2(boss_radius, 0.0),
		marker_pos + Vector2(0.0, boss_radius),
		marker_pos + Vector2(-boss_radius, 0.0),
	])
	draw_colored_polygon(points, boss_color)
