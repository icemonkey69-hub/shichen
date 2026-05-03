extends Node2D

@export var speed := 460.0
@export var lifetime := 3.0
@export var damage := 1
@export var hit_radius := 18.0
@export var texture: Texture2D

@onready var sprite: Sprite2D = $Sprite

var direction := Vector2.RIGHT
var target: Node2D


func _ready() -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	if texture != null:
		sprite.texture = texture
	sprite.rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if not is_instance_valid(target):
		return
	if global_position.distance_squared_to(target.global_position) > hit_radius * hit_radius:
		return

	var can_hit_target := true
	if target.has_method("can_receive_enemy_damage"):
		can_hit_target = bool(target.call("can_receive_enemy_damage"))
	if can_hit_target and target.has_method("receive_damage"):
		target.receive_damage(damage)
	queue_free()
