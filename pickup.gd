extends Node2D

signal collected(reward_type: StringName, amount: int)

@export var reward_type: StringName = &"gold"
@export var amount := 1
@export var float_duration := 0.22
@export var idle_delay := 0.12
@export var close_magnet_delay := 0.04
@export var magnet_range := 9999.0
@export var collect_range := 28.0
@export var base_speed := 145.0
@export var magnet_speed := 420.0
@export var max_magnet_speed := 1280.0

@onready var shadow: Polygon2D = $Shadow
@onready var orb: Polygon2D = $Orb

var player: Node2D
var launch_velocity := Vector2.ZERO
var elapsed := 0.0
var collecting := false
var bob_seed := 0.0


func _ready() -> void:
	bob_seed = randf() * TAU
	_update_visual()


func _process(delta: float) -> void:
	elapsed += delta

	if not is_instance_valid(player):
		global_position += launch_velocity * delta
		launch_velocity = launch_velocity.move_toward(Vector2.ZERO, delta * 180.0)
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var effective_idle_delay := close_magnet_delay if distance <= 180.0 else idle_delay
	var attract_active := elapsed >= effective_idle_delay and (magnet_range <= 0.0 or distance <= magnet_range)
	if attract_active:
		collecting = true
		var direction := to_player / maxf(distance, 0.001)
		var speed := magnet_speed + maxf(amount * 1.4, 0.0) + minf(distance * 1.55, 760.0)
		speed = clampf(speed, base_speed, max_magnet_speed)
		global_position += direction * speed * delta
	else:
		if elapsed <= float_duration:
			global_position += launch_velocity * delta
			launch_velocity = launch_velocity.move_toward(Vector2.ZERO, delta * 200.0)
		else:
			global_position.y += sin(elapsed * 3.6 + bob_seed) * 9.0 * delta

	if distance <= collect_range:
		collected.emit(reward_type, amount)
		queue_free()


func configure_pickup(p_type: StringName, p_amount: int, p_player: Node2D, impulse: Vector2 = Vector2.ZERO) -> void:
	reward_type = p_type
	amount = maxi(p_amount, 0)
	player = p_player
	launch_velocity = impulse
	if is_inside_tree():
		_update_visual()


func _update_visual() -> void:
	var main_color := Color(0.95, 0.81, 0.22, 1.0)
	var shadow_color := Color(0.35, 0.24, 0.08, 0.5)
	if reward_type == &"exp":
		main_color = Color(0.35, 0.88, 0.68, 1.0)
		shadow_color = Color(0.08, 0.28, 0.2, 0.5)

	orb.color = main_color
	shadow.color = shadow_color
	var size_scale := clampf(0.9 + log(float(maxi(amount, 1)) + 1.0) * 0.16, 0.9, 1.5)
	scale = Vector2.ONE * size_scale
