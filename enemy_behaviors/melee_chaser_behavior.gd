extends "res://enemy_behaviors/enemy_behavior.gd"
class_name EnemyMeleeChaserBehavior

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
	enemy._set_attack_indicator_visible(false)
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
	var direction: Vector2 = Vector2.ZERO if distance_to_player == 0.0 else to_player / distance_to_player
	var dynamic_trigger_distance: float = enemy._compute_dynamic_attack_distance(enemy.attack_trigger_distance)

	match enemy.attack_state:
		STATE_CHASE:
			var in_attack_range: bool = distance_to_player <= dynamic_trigger_distance
			if in_attack_range:
				enemy.velocity = Vector2.ZERO
				if direction != Vector2.ZERO:
					enemy.attack_direction = direction
				enemy.sprite.set_motion_state(enemy.attack_direction, false)
				if enemy.attack_cooldown <= 0.0:
					_start_windup(enemy.attack_direction)
			else:
				enemy.velocity = direction * enemy.move_speed
				enemy.sprite.set_motion_state(direction, direction != Vector2.ZERO)
			enemy.move_and_slide()
		STATE_WINDUP:
			enemy.velocity = Vector2.ZERO
			enemy.global_position = enemy.attack_anchor_position
			enemy.state_timer = max(enemy.state_timer - delta, 0.0)
			enemy.sprite.set_motion_state(enemy.attack_direction, false)
			_update_windup_pose()
			if enemy.state_timer == 0.0:
				_perform_attack()
		STATE_RECOVER:
			enemy.velocity = Vector2.ZERO
			enemy.global_position = enemy.attack_anchor_position
			enemy.state_timer = max(enemy.state_timer - delta, 0.0)
			enemy.sprite.set_motion_state(enemy.attack_direction, false)
			_update_recover_pose()
			if enemy.state_timer == 0.0:
				_finish_recover()


func on_deactivated() -> void:
	if enemy == null:
		return
	enemy._set_attack_indicator_visible(false)


func _start_windup(direction: Vector2) -> void:
	enemy.attack_state = STATE_WINDUP
	enemy.state_timer = enemy.windup_time
	enemy.attack_direction = direction if direction != Vector2.ZERO else Vector2.DOWN
	enemy.attack_anchor_position = enemy.global_position
	enemy._set_attack_indicator_visible(true)
	enemy.sprite.start_attack_preview(enemy.attack_direction)
	_update_windup_pose()


func _perform_attack() -> void:
	enemy.attack_state = STATE_RECOVER
	enemy.state_timer = enemy.recover_time
	enemy.attack_cooldown = enemy.attack_interval
	enemy._set_attack_indicator_visible(false)
	enemy.sprite.play_attack_hit(enemy.attack_direction)

	if not is_instance_valid(enemy.player):
		return

	var distance_to_player := enemy.global_position.distance_to(enemy.player.global_position)
	var dynamic_reach_distance: float = enemy._compute_dynamic_attack_distance(enemy.attack_reach)
	var can_hit_player := true
	if enemy.player.has_method("can_receive_enemy_damage"):
		can_hit_player = enemy.player.call("can_receive_enemy_damage")
	if distance_to_player <= dynamic_reach_distance and can_hit_player and enemy.player.has_method("receive_damage"):
		enemy.player.receive_damage(enemy.touch_damage)


func _finish_recover() -> void:
	enemy.attack_state = STATE_CHASE
	enemy.sprite.stop_attack(enemy.attack_direction)


func _update_windup_pose() -> void:
	var progress: float = 1.0 - enemy.state_timer / enemy.windup_time
	enemy.attack_indicator.rotation = enemy.attack_direction.angle() + PI / 2.0
	enemy.attack_indicator.scale = Vector2.ONE
	enemy._update_attack_indicator_fill(progress)
	enemy.sprite.set_attack_preview_progress(enemy.attack_direction, progress)


func _update_recover_pose() -> void:
	var progress: float = 1.0 - enemy.state_timer / enemy.recover_time
	enemy.sprite.set_attack_recover_progress(enemy.attack_direction, progress)
