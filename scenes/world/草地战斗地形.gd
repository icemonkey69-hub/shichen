extends Node2D
class_name GrassBattleTerrain

@export var play_area := Rect2(96.0, 96.0, 1344.0, 704.0)
@export var show_bounds := false

@onready var tower_spawn_marker: Marker2D = get_node("塔出生点") as Marker2D
@onready var boss_spawn_marker: Marker2D = get_node("Boss出生点") as Marker2D
@onready var enemy_spawn_root: Node = get_node("普通怪刷怪点")

var enemy_spawn_marker_bag: Array[Marker2D] = []


func _ready() -> void:
	queue_redraw()


func get_play_area() -> Rect2:
	return play_area


func get_spawn_position() -> Vector2:
	return get_tower_spawn_position()


func get_tower_spawn_position() -> Vector2:
	return tower_spawn_marker.global_position


func get_boss_spawn_position() -> Vector2:
	return boss_spawn_marker.global_position


func get_enemy_spawn_position(_avoid_rect := Rect2()) -> Vector2:
	var marker := _take_random_enemy_spawn_marker()
	if marker == null:
		push_error("草地战斗地形要求 `普通怪刷怪点` 下至少有一个 Marker2D。")
		return Vector2.ZERO
	return marker.global_position


func _draw() -> void:
	if not show_bounds:
		return
	draw_rect(play_area, Color(0.85, 1.0, 0.55, 0.72), false, 3.0)


func _get_enemy_spawn_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	for child in enemy_spawn_root.get_children():
		if child is Marker2D:
			markers.append(child)
	return markers


func _take_random_enemy_spawn_marker() -> Marker2D:
	if enemy_spawn_marker_bag.is_empty():
		enemy_spawn_marker_bag = _get_enemy_spawn_markers()
	if enemy_spawn_marker_bag.is_empty():
		return null
	var index := randi() % enemy_spawn_marker_bag.size()
	var marker := enemy_spawn_marker_bag[index]
	enemy_spawn_marker_bag.remove_at(index)
	return marker
