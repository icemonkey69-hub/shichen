extends Node2D
class_name GrassTerrain

@export var play_area := Rect2(-1024.0, -1024.0, 2048.0, 2048.0)
@export var boss_spawn_offset := Vector2(760.0, -680.0)
@export var show_bounds := false


func _ready() -> void:
	_disable_tilemap_collision()
	queue_redraw()


func get_play_area() -> Rect2:
	return play_area


func get_spawn_position() -> Vector2:
	return play_area.position + play_area.size * 0.5


func get_boss_spawn_position() -> Vector2:
	return get_spawn_position() + boss_spawn_offset


func _draw() -> void:
	if not show_bounds:
		return
	draw_rect(play_area, Color(0.7, 1.0, 0.55, 0.65), false, 3.0)


func _disable_tilemap_collision() -> void:
	for child in get_children():
		if child is TileMapLayer:
			child.set("collision_enabled", false)
