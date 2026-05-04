extends Node2D

@export var speed := 560.0
@export var lifetime := 1.2
@export var damage := 1
@export var hit_radius := 16.0
@export var play_area := Rect2(-640.0, -360.0, 1280.0, 720.0)
@export var turn_speed := 12.0

@onready var body: Node2D = $Body

static var _enemy_query_frame := -1
static var _enemy_query_nodes: Array = []

var direction := Vector2.UP
var source_stats
var target: Node2D


func _ready() -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.UP

	body.rotation = direction.angle() + PI / 2.0


func _physics_process(delta: float) -> void:
	var previous_position := global_position
	if _is_valid_target(target):
		var desired_direction := (target.global_position - global_position).normalized()
		if desired_direction != Vector2.ZERO:
			direction = direction.slerp(desired_direction, clampf(turn_speed * delta, 0.0, 1.0)).normalized()
	global_position += direction * speed * delta
	body.rotation = direction.angle() + PI / 2.0
	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	var expanded_area := Rect2(play_area.position - Vector2.ONE * 80.0, play_area.size + Vector2.ONE * 160.0)
	if not expanded_area.has_point(global_position):
		queue_free()
		return

	if _is_valid_target(target):
		if _segment_distance_squared(previous_position, global_position, target.global_position) <= hit_radius * hit_radius:
			_hit_enemy(target)
		return

	for enemy in _get_enemy_nodes_for_current_physics_frame():
		if not is_instance_valid(enemy):
			continue

		if _segment_distance_squared(previous_position, global_position, enemy.global_position) <= hit_radius * hit_radius:
			_hit_enemy(enemy)
			return


func _get_enemy_nodes_for_current_physics_frame() -> Array:
	var current_frame: int = Engine.get_physics_frames()
	if _enemy_query_frame != current_frame:
		_enemy_query_frame = current_frame
		_enemy_query_nodes = get_tree().get_nodes_in_group("enemy")
	return _enemy_query_nodes


func _is_valid_target(candidate: Node2D) -> bool:
	return candidate != null and is_instance_valid(candidate) and candidate.is_inside_tree()


func _hit_enemy(enemy: Node2D) -> void:
	if enemy.has_method("take_projectile_hit"):
		enemy.take_projectile_hit(damage, source_stats)
	else:
		enemy.take_damage(damage)
	queue_free()


func _segment_distance_squared(a: Vector2, b: Vector2, point: Vector2) -> float:
	var segment := b - a
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_squared_to(b)
	var t := clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
	var closest := a + segment * t
	return point.distance_squared_to(closest)
