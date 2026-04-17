extends CharacterBody2D

const AttributeSystemScript := preload("res://attribute_system.gd")

const ENEMY_TYPE_NORMAL := 1
const ENEMY_TYPE_BOSS := 3
const DRAW_ORDER_BASE := 2000
const DRAW_ORDER_MIN := 1
const DRAW_ORDER_MAX := 4095
const DEFAULT_ATTACK_RADIUS_SUM := 50.0
static var _missing_model_warning_ids: Dictionary = {}
static var _missing_animator_warning_ids: Dictionary = {}

signal died(world_position: Vector2, reward_info: Dictionary)
signal damaged(world_position: Vector2, amount: int)
signal despawn_requested(enemy_node: Node2D)

@export var enemy_id: StringName = &"1"
@export var enemy_name: String = "Enemy"
@export var enemy_type: int = ENEMY_TYPE_NORMAL
@export var model_id: StringName = &"1010"

@export var move_speed := 110.0
@export var max_health := 3
@export var is_boss := false
@export var touch_damage := 10
@export var attack_trigger_distance := 82.0
@export var attack_reach := 88.0
@export var attack_interval := 0.7
@export var windup_time := 0.75
@export var recover_time := 0.35
@export var hit_flash_time := 0.12
@export var dissolve_duration := 1.5
@export var armor := 0.0
@export var magic_resist := 0.0
@export var exp_reward := 0
@export var gold_reward := 0
@export var skill_ids: Array[StringName] = []

@onready var body: Node2D = $Body
@onready var sprite: EnemySpriteAnimator = $Body/Sprite
@onready var attack_indicator: Node2D = $AttackIndicator
@onready var attack_indicator_fill: Polygon2D = $AttackIndicator/Fill
@onready var attack_indicator_outline: Line2D = $AttackIndicator/Outline
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

enum AttackState {
	CHASE,
	WINDUP,
	RECOVER,
	DEAD,
}

var player: Node2D
var health := 0
var attack_cooldown := 0.0
var hit_flash_remaining := 0.0
var attack_state := AttackState.CHASE
var state_timer := 0.0
var attack_direction := Vector2.DOWN
var death_elapsed := 0.0
var attack_anchor_position := Vector2.ZERO
var _model_configured := false
var _model_apply_pending := false
var _configured_model_id: StringName = &""
var _pool_mode := false
var _despawn_notified := false
var _active_in_world := true


func _ready() -> void:
	health = max_health
	_sync_enemy_groups()
	if not _pool_mode and not String(model_id).strip_edges().is_empty():
		_request_model_apply()
	_update_attack_indicator_shape()
	_set_attack_indicator_visible(false)
	_update_draw_order()


func apply_enemy_data(data: EnemyData) -> void:
	if data == null:
		return

	var previous_model_id: StringName = model_id
	enemy_id = data.enemy_id
	enemy_name = data.enemy_name
	enemy_type = data.enemy_type
	model_id = data.model_id

	max_health = maxi(1, data.max_health)
	health = max_health
	move_speed = maxf(0.0, data.move_speed)
	touch_damage = maxi(0, data.touch_damage)
	attack_interval = maxf(0.05, data.attack_interval)
	armor = data.armor
	magic_resist = data.magic_resist
	exp_reward = maxi(0, data.exp_reward)
	gold_reward = maxi(0, data.gold_reward)
	skill_ids = data.skill_ids.duplicate()
	is_boss = enemy_type == ENEMY_TYPE_BOSS

	if collision_shape != null and collision_shape.shape is CircleShape2D:
		var circle := collision_shape.shape as CircleShape2D
		circle.radius = maxf(1.0, data.collision_radius)
		collision_shape.shape = circle

	_sync_enemy_groups()
	var model_changed: bool = String(previous_model_id).strip_edges() != String(model_id).strip_edges()
	var model_ready_for_current_id: bool = _model_configured and String(_configured_model_id).strip_edges() == String(model_id).strip_edges()
	if model_changed or not model_ready_for_current_id:
		_model_configured = false
		if _active_in_world:
			visible = false
			if collision_shape != null:
				collision_shape.disabled = true
		_request_model_apply()
	else:
		sprite.set_motion_state(attack_direction, false)
	_update_attack_indicator_shape()


func set_forced_boss_state(enabled: bool) -> void:
	is_boss = enabled
	if enabled:
		enemy_type = ENEMY_TYPE_BOSS
	_sync_enemy_groups()


func set_pool_mode(enabled: bool) -> void:
	_pool_mode = enabled
	if not _pool_mode and _active_in_world and not _model_configured and not String(model_id).strip_edges().is_empty():
		_request_model_apply()


func activate_from_pool(player_node: Node2D, spawn_position: Vector2) -> void:
	_active_in_world = true
	player = player_node
	global_position = spawn_position
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(true)
	set_physics_process(true)
	velocity = Vector2.ZERO
	health = max_health
	attack_state = AttackState.CHASE
	attack_cooldown = 0.0
	hit_flash_remaining = 0.0
	state_timer = 0.0
	death_elapsed = 0.0
	attack_anchor_position = global_position
	attack_direction = Vector2.DOWN
	_despawn_notified = false
	body.modulate = Color(1, 1, 1, 1)
	_set_attack_indicator_visible(false)
	if sprite != null and sprite.has_method("set_dissolve_progress"):
		sprite.set_dissolve_progress(0.0)
	if sprite != null and sprite.has_method("set_runtime_active"):
		sprite.call("set_runtime_active", true)
	if sprite != null and sprite.has_method("reset_runtime_state"):
		sprite.call("reset_runtime_state", attack_direction, true)
	_sync_enemy_groups()
	var model_ready_for_current_id: bool = _model_configured and String(_configured_model_id).strip_edges() == String(model_id).strip_edges()
	if model_ready_for_current_id:
		visible = true
		if collision_shape != null:
			collision_shape.disabled = false
		sprite.set_motion_state(attack_direction, false)
	elif not _model_apply_pending:
		visible = false
		if collision_shape != null:
			collision_shape.disabled = true
		_request_model_apply()
	_update_draw_order()


func deactivate_to_pool(hidden_position: Vector2 = Vector2(-20000.0, -20000.0)) -> void:
	_active_in_world = false
	visible = false
	set_process(false)
	set_physics_process(false)
	velocity = Vector2.ZERO
	attack_state = AttackState.DEAD
	attack_cooldown = 0.0
	hit_flash_remaining = 0.0
	state_timer = 0.0
	death_elapsed = 0.0
	_despawn_notified = false
	remove_from_group("enemy")
	remove_from_group("boss")
	if collision_shape != null:
		collision_shape.disabled = true
	_set_attack_indicator_visible(false)
	if sprite != null and sprite.has_method("set_dissolve_progress"):
		sprite.set_dissolve_progress(0.0)
	if sprite != null and sprite.has_method("set_runtime_active"):
		sprite.call("set_runtime_active", false)
	global_position = hidden_position


func _physics_process(delta: float) -> void:
	if not _model_configured:
		_request_model_apply()
		_set_attack_indicator_visible(false)
		if _active_in_world:
			visible = false
			if collision_shape != null:
				collision_shape.disabled = true
		return

	if attack_state == AttackState.DEAD:
		_process_death(delta)
		_update_draw_order()
		return

	attack_cooldown = max(attack_cooldown - delta, 0.0)
	hit_flash_remaining = max(hit_flash_remaining - delta, 0.0)

	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		sprite.set_motion_state(attack_direction, false)
		_update_visual_state()
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance_to_player: float = to_player.length()
	var direction: Vector2 = Vector2.ZERO if distance_to_player == 0.0 else to_player / distance_to_player
	var dynamic_trigger_distance: float = _compute_dynamic_attack_distance(attack_trigger_distance)

	match attack_state:
		AttackState.CHASE:
			var in_attack_range: bool = distance_to_player <= dynamic_trigger_distance
			if in_attack_range:
				velocity = Vector2.ZERO
				if direction != Vector2.ZERO:
					attack_direction = direction
				sprite.set_motion_state(attack_direction, false)
				if attack_cooldown <= 0.0:
					_start_windup(attack_direction)
			else:
				velocity = direction * move_speed
				sprite.set_motion_state(direction, direction != Vector2.ZERO)
			move_and_slide()
		AttackState.WINDUP:
			velocity = Vector2.ZERO
			global_position = attack_anchor_position
			state_timer = max(state_timer - delta, 0.0)
			sprite.set_motion_state(attack_direction, false)
			_update_windup_pose()
			if state_timer == 0.0:
				_perform_attack()
		AttackState.RECOVER:
			velocity = Vector2.ZERO
			global_position = attack_anchor_position
			state_timer = max(state_timer - delta, 0.0)
			sprite.set_motion_state(attack_direction, false)
			_update_recover_pose()
			if state_timer == 0.0:
				_finish_recover()

	_update_visual_state()
	_update_draw_order()


func take_damage(amount: int) -> void:
	if attack_state == AttackState.DEAD:
		return

	health = max(health - amount, 0)
	hit_flash_remaining = hit_flash_time
	if sprite != null and sprite.has_method("play_hit"):
		sprite.play_hit()
	damaged.emit(global_position, amount)

	if health == 0:
		_start_death()


func take_projectile_hit(raw_damage: int, source_stats) -> void:
	if attack_state == AttackState.DEAD:
		return

	var final_damage := raw_damage
	if source_stats != null:
		final_damage = int(ceil(AttributeSystemScript.calculate_basic_attack_damage(source_stats, armor)))
	final_damage = max(final_damage, 1)
	take_damage(final_damage)


func _update_visual_state() -> void:
	if attack_state == AttackState.DEAD:
		return

	if hit_flash_remaining > 0.0:
		body.modulate = Color(1, 0.75, 0.75, 1)
		return

	if attack_state == AttackState.WINDUP:
		body.modulate = Color(1, 0.82, 0.82, 1)
		return

	body.modulate = Color(1, 1, 1, 1)


func _start_windup(direction: Vector2) -> void:
	attack_state = AttackState.WINDUP
	state_timer = windup_time
	attack_direction = direction if direction != Vector2.ZERO else Vector2.DOWN
	attack_anchor_position = global_position
	_set_attack_indicator_visible(true)
	sprite.start_attack_preview(attack_direction)
	_update_windup_pose()


func _perform_attack() -> void:
	attack_state = AttackState.RECOVER
	state_timer = recover_time
	attack_cooldown = attack_interval
	_set_attack_indicator_visible(false)
	sprite.play_attack_hit(attack_direction)

	if not is_instance_valid(player):
		return

	var distance_to_player := global_position.distance_to(player.global_position)
	var dynamic_reach_distance: float = _compute_dynamic_attack_distance(attack_reach)
	var can_hit_player := true
	if player.has_method("can_receive_enemy_damage"):
		can_hit_player = player.call("can_receive_enemy_damage")
	if distance_to_player <= dynamic_reach_distance and can_hit_player and player.has_method("receive_damage"):
		player.receive_damage(touch_damage)


func _finish_recover() -> void:
	attack_state = AttackState.CHASE
	sprite.stop_attack(attack_direction)


func _update_windup_pose() -> void:
	var progress := 1.0 - state_timer / windup_time
	attack_indicator.rotation = attack_direction.angle() + PI / 2.0
	attack_indicator.scale = Vector2.ONE
	_update_attack_indicator_fill(progress)
	sprite.set_attack_preview_progress(attack_direction, progress)


func _update_recover_pose() -> void:
	var progress := 1.0 - state_timer / recover_time
	sprite.set_attack_recover_progress(attack_direction, progress)


func _compute_dynamic_attack_distance(base_distance: float) -> float:
	var self_radius: float = _get_collision_radius()
	var player_radius: float = _get_player_collision_radius()
	var edge_padding: float = maxf(base_distance - DEFAULT_ATTACK_RADIUS_SUM, 0.0)
	return self_radius + player_radius + edge_padding


func _get_collision_radius() -> float:
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		return maxf((collision_shape.shape as CircleShape2D).radius, 1.0)
	return 16.0


func _get_player_collision_radius() -> float:
	if not is_instance_valid(player):
		return 34.0

	for child in player.get_children():
		if child is CollisionShape2D:
			var player_shape: CollisionShape2D = child as CollisionShape2D
			if player_shape.shape is CircleShape2D:
				return maxf((player_shape.shape as CircleShape2D).radius, 1.0)
	return 34.0


func _set_attack_indicator_visible(visible_state: bool) -> void:
	attack_indicator.visible = visible_state
	if visible_state:
		_update_attack_indicator_fill(0.0)


func _update_attack_indicator_shape() -> void:
	var body_radius := 18.0
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		body_radius = (collision_shape.shape as CircleShape2D).radius

	var start_offset := body_radius * 0.9
	var end_offset := _compute_dynamic_attack_distance(attack_reach)
	var half_width := maxf(body_radius * 0.95, end_offset * 0.32)
	var shape_points := PackedVector2Array([
		Vector2(0.0, -start_offset),
		Vector2(half_width, -end_offset),
		Vector2(-half_width, -end_offset),
	])
	attack_indicator_fill.polygon = shape_points
	attack_indicator_outline.points = shape_points


func _update_attack_indicator_fill(progress: float) -> void:
	var clamped := clampf(progress, 0.0, 1.0)
	var body_radius := 18.0
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		body_radius = (collision_shape.shape as CircleShape2D).radius

	var start_offset := body_radius * 0.9
	var dynamic_reach: float = _compute_dynamic_attack_distance(attack_reach)
	var current_end := lerpf(start_offset, dynamic_reach, clamped)
	var current_half_width := lerpf(0.0, maxf(body_radius * 0.95, dynamic_reach * 0.32), clamped)
	attack_indicator_fill.polygon = PackedVector2Array([
		Vector2(0.0, -start_offset),
		Vector2(current_half_width, -current_end),
		Vector2(-current_half_width, -current_end),
	])
	attack_indicator_fill.modulate = Color(1.0, 0.98 - clamped * 0.08, 0.98 - clamped * 0.08, 0.22 + clamped * 0.58)


func _start_death() -> void:
	attack_state = AttackState.DEAD
	death_elapsed = 0.0
	_despawn_notified = false
	velocity = Vector2.ZERO
	attack_cooldown = 0.0
	state_timer = 0.0
	body.modulate = Color(1, 1, 1, 1)
	_set_attack_indicator_visible(false)
	remove_from_group("enemy")
	remove_from_group("boss")
	if collision_shape != null:
		collision_shape.disabled = true
	sprite.play_death()
	died.emit(global_position, _build_reward_info())


func _process_death(delta: float) -> void:
	death_elapsed += delta
	var dissolve_t := clampf(death_elapsed / dissolve_duration, 0.0, 1.0)
	sprite.set_dissolve_progress(dissolve_t)
	if dissolve_t >= 1.0 and not _despawn_notified:
		_despawn_notified = true
		if _pool_mode:
			despawn_requested.emit(self)
			return
		queue_free()


func _sync_enemy_groups() -> void:
	add_to_group("enemy")
	remove_from_group("boss")
	if is_boss:
		add_to_group("boss")


func _request_model_apply() -> void:
	if not is_inside_tree():
		return
	if String(model_id).strip_edges().is_empty():
		return
	if _model_apply_pending:
		return
	_model_apply_pending = true
	call_deferred("_apply_model_from_id")


func _apply_model_from_id() -> void:
	if not is_inside_tree():
		_model_apply_pending = false
		return
	_model_apply_pending = false
	_model_configured = false
	if _active_in_world:
		visible = false
		if collision_shape != null:
			collision_shape.disabled = true
	if sprite == null:
		return

	var target_model_id: String = String(model_id).strip_edges()
	if target_model_id.is_empty():
		return

	if not sprite.has_method("configure_model_id"):
		var animator_model_key: String = target_model_id
		if not _missing_animator_warning_ids.has(animator_model_key):
			_missing_animator_warning_ids[animator_model_key] = true
			push_warning("Enemy sprite animator missing configure_model_id for model_id=%s." % animator_model_key)
		return

	var configured_3d: bool = bool(sprite.call("configure_model_id", model_id))
	if not configured_3d:
		var model_key: String = target_model_id
		if not _missing_model_warning_ids.has(model_key):
			_missing_model_warning_ids[model_key] = true
			push_warning("Enemy 3D profile missing or invalid for model_id=%s." % model_key)
		return
	_model_configured = true
	_configured_model_id = model_id
	if sprite != null and sprite.has_method("set_runtime_active"):
		sprite.call("set_runtime_active", _active_in_world)
	if sprite != null and sprite.has_method("reset_runtime_state"):
		sprite.call("reset_runtime_state", attack_direction, true)
	if _active_in_world:
		visible = true
		if collision_shape != null:
			collision_shape.disabled = false
	sprite.set_motion_state(attack_direction, false)
	if sprite.has_method("play_spawn"):
		sprite.play_spawn()


func ensure_model_ready() -> void:
	var model_ready_for_current_id: bool = _model_configured and String(_configured_model_id).strip_edges() == String(model_id).strip_edges()
	if model_ready_for_current_id:
		return
	_apply_model_from_id()


func _build_reward_info() -> Dictionary:
	return {
		"enemy_id": String(enemy_id),
		"enemy_name": enemy_name,
		"enemy_type": enemy_type,
		"gold": gold_reward,
		"exp": exp_reward,
	}


func _update_draw_order() -> void:
	z_as_relative = false
	var order_value: int = DRAW_ORDER_BASE + int(round(global_position.y))
	z_index = clampi(order_value, DRAW_ORDER_MIN, DRAW_ORDER_MAX)
