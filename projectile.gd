extends Node2D

@export var speed := 560.0
@export var lifetime := 1.2
@export var damage := 1
@export var hit_radius := 16.0
@export var play_area := Rect2(-640.0, -360.0, 1280.0, 720.0)

@onready var body: Node2D = $Body

var direction := Vector2.UP
var source_stats


func _ready() -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.UP

	body.rotation = direction.angle() + PI / 2.0


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	var expanded_area := Rect2(play_area.position - Vector2.ONE * 80.0, play_area.size + Vector2.ONE * 160.0)
	if not expanded_area.has_point(global_position):
		queue_free()
		return

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue

		if global_position.distance_squared_to(enemy.global_position) <= hit_radius * hit_radius:
			if enemy.has_method("take_projectile_hit"):
				enemy.take_projectile_hit(damage, source_stats)
			else:
				enemy.take_damage(damage)
			queue_free()
			return
