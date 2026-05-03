extends "res://enemy_behaviors/enemy_behavior.gd"
class_name EnemyRangedAttackerBehavior

const STATE_CHASE := 0
const STATE_WINDUP := 1
const STATE_RECOVER := 2
const STATE_DEAD := 3


func reset_state() -> void:
	if enemy == null:
		return
	enemy.attack_state = STATE_CHASE
	enemy.attack_cooldown = 0.0
	enemy.state_timer = 0.0
	enemy.attack_anchor_position = enemy.global_position
	enemy.attack_direction = Vector2.DOWN
	if enemy.sprite != null:
		enemy.sprite.stop_attack(enemy.attack_direction)


func physics_process(delta: float) -> void:
	if enemy == null or enemy.attack_state == STATE_DEAD:
		return

	if not is_instance_valid(enemy.player):
		enemy.velocity = Vector2.ZERO
		enemy.sprite.set_motion_state(enemy.attack_direction, false)
		return

	var to_player: Vector2 = enemy.player.global_position - enemy.global_position
	var distance_to_player: float = to_player.length()
	var direction: Vector2 = Vector2.ZERO if distance_to_player <= 0.001 else to_player / distance_to_player
	var attack_distance: float = enemy._compute_dynamic_attack_distance(enemy.attack_trigger_distance)

	match enemy.attack_state:
		STATE_CHASE:
			if distance_to_player <= attack_distance:
				enemy.velocity = Vector2.ZERO
				if direction != Vector2.ZERO:
					enemy.attack_direction = direction
				enemy.sprite.set_motion_state(enemy.attack_direction, false)
				if enemy.attack_cooldown <= 0.0:
					_start_windup(enemy.attack_direction)
			else:
				enemy.velocity = enemy.get_chase_velocity_to_target(enemy.player.global_position, enemy.move_speed, attack_distance)
				var move_direction := enemy.velocity.normalized() if enemy.velocity.length_squared() > 0.001 else direction
				enemy.sprite.set_motion_state(move_direction, move_direction != Vector2.ZERO)
			enemy.move_and_slide()
		STATE_WINDUP:
			enemy.velocity = Vector2.ZERO
			enemy.global_position = enemy.attack_anchor_position
			enemy.state_timer = max(enemy.state_timer - delta, 0.0)
			enemy.sprite.set_motion_state(enemy.attack_direction, false)
			enemy.sprite.set_attack_preview_progress(enemy.attack_direction, 1.0 - enemy.state_timer / enemy.windup_time)
			if enemy.state_timer == 0.0:
				_perform_attack()
		STATE_RECOVER:
			enemy.velocity = Vector2.ZERO
			enemy.global_position = enemy.attack_anchor_position
			enemy.state_timer = max(enemy.state_timer - delta, 0.0)
			enemy.sprite.set_motion_state(enemy.attack_direction, false)
			enemy.sprite.set_attack_recover_progress(enemy.attack_direction, 1.0 - enemy.state_timer / enemy.recover_time)
			if enemy.state_timer == 0.0:
				_finish_recover()


func on_deactivated() -> void:
	pass


func _start_windup(direction: Vector2) -> void:
	enemy.attack_state = STATE_WINDUP
	enemy.state_timer = enemy.windup_time
	enemy.attack_direction = direction if direction != Vector2.ZERO else Vector2.DOWN
	enemy.attack_anchor_position = enemy.global_position
	enemy.sprite.start_attack_preview(enemy.attack_direction)


func _perform_attack() -> void:
	enemy.attack_state = STATE_RECOVER
	enemy.state_timer = enemy.recover_time
	enemy.attack_cooldown = enemy.attack_interval
	enemy.sprite.play_attack_hit(enemy.attack_direction)
	enemy.spawn_enemy_projectile(enemy.attack_direction)


func _finish_recover() -> void:
	enemy.attack_state = STATE_CHASE
	enemy.sprite.stop_attack(enemy.attack_direction)
