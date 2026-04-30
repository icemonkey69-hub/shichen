extends Node2D
class_name GrassBattleTerrain

@export var play_area := Rect2(96.0, 96.0, 1344.0, 704.0)
@export var disable_tilemap_collision := true
@export var show_bounds := false

@onready var tower_spawn_marker: Marker2D = get_node("塔出生点") as Marker2D
@onready var boss_spawn_marker: Marker2D = get_node("Boss出生点") as Marker2D
@onready var enemy_spawn_root: Node = get_node("普通怪刷怪点")


func _ready() -> void:
	if disable_tilemap_collision:
		_disable_tilemap_collision()
	queue_redraw()


func get_play_area() -> Rect2:
	return play_area


func get_spawn_position() -> Vector2:
	return get_tower_spawn_position()


func get_tower_spawn_position() -> Vector2:
	return tower_spawn_marker.global_position


func get_boss_spawn_position() -> Vector2:
	return boss_spawn_marker.global_position


func get_enemy_spawn_position(avoid_rect := Rect2()) -> Vector2:
	var markers := _get_enemy_spawn_markers()
	if markers.is_empty():
		push_error("草地战斗地形要求 `普通怪刷怪点` 下至少有一个 Marker2D。")
		return Vector2.ZERO

	var candidates: Array[Marker2D] = []
	for marker in markers:
		if not avoid_rect.has_point(marker.global_position):
			candidates.append(marker)

	if candidates.is_empty():
		candidates = markers

	return candidates[randi() % candidates.size()].global_position


func _draw() -> void:
	if not show_bounds:
		return
	draw_rect(play_area, Color(0.85, 1.0, 0.55, 0.72), false, 3.0)


func _disable_tilemap_collision() -> void:
	for child in get_children():
		if child is TileMapLayer:
			child.set("collision_enabled", false)


func _get_enemy_spawn_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	for child in enemy_spawn_root.get_children():
		if child is Marker2D:
			markers.append(child)
	return markers
