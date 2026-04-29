extends CharacterBody2D

const AttributeSystemScript := preload("res://attribute_system.gd")

signal projectile_requested(spawn_position: Vector2, direction: Vector2, damage: int, source_stats)
signal health_changed(current_health: int, max_health: int)
signal mana_changed(current_mana: int, max_mana: int)
signal died

@export var move_speed := 300.0
@export var movement_bounds := Rect2(-1000.0, -1000.0, 2000.0, 2000.0)
@export var max_health := 100
@export var max_mana := 0
@export var attack_damage := 1
@export var attack_interval := 0.4
@export var attack_range := 460.0
@export var invulnerability_time := 0.5
@export var jump_height := 26.0
@export var jump_takeoff_duration := 0.08
@export var jump_air_duration := 0.14
@export var jump_landing_duration := 0.08
@export var jump_max_duration := 0.3
@export var jump_forward_distance := 200.0
@export var jump_cooldown := 0.5
@export var landing_push_radius := 36.0
@export var landing_push_strength := 22.0

const TURN_STEP := PI / 4.0
const PROJECTILE_SPAWN_DISTANCE := 34.0
const ATTACK_RELEASE_FRAME := 3.0
const ATTACK_TOTAL_FRAMES := 6.0
const MIN_ATTACK_CYCLE := 0.05

const DRAW_ORDER_BASE := 2000
const DRAW_ORDER_MIN := 1
const DRAW_ORDER_MAX := 4095

@export var camera_target_visible_size := Vector2(1450.0, 820.0)
@export var min_camera_zoom := 0.68
@export var max_camera_zoom := 1.2
@export var enemy_push_min_distance := 54.0
@export var enemy_push_max_step := 12.0

@onready var visual_root: Node2D = $VisualRoot
@onready var camera: Camera2D = $Camera2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health := 0
var mana := 0
var attack_cooldown := 0.0
var damage_cooldown := 0.0
var is_dead := false
var is_jumping := false
var hero_data: HeroData
var current_model_root: Node2D
var current_hero_model: HeroModel
var controls_enabled := false
var tower_mode := false
var jump_elapsed := 0.0
var jump_phase := 0
var jump_cooldown_remaining := 0.0
var jump_key_was_pressed := false
var jump_total_elapsed := 0.0
var jump_start_position := Vector2.ZERO
var jump_target_position := Vector2.ZERO
var jump_travel_direction := Vector2.DOWN
var jump_collision_ignore_seconds := -1.0
var jump_collision_land_seconds := -1.0
var jump_motion_duration_override := -1.0
var jump_collision_ignore_applied := false
var jump_collision_land_applied := false
var facing_direction := Vector2.DOWN
var attack_in_progress := false
var attack_pending_projectile := false
var attack_elapsed := 0.0
var attack_fire_time := 0.0
var attack_direction := Vector2.DOWN
var attack_cycle_duration := 0.0
var combat_stats
var runtime_bonus_values: Dictionary = {}
var _enemy_query_frame := -1
var _enemy_query_nodes: Array = []
var runtime_progress_values: Dictionary = {
	"gold": 0.0,
	"exp": 0.0,
	"kill_count": 0.0,
	"level": 1.0,
}


func _ready() -> void:
	if hero_data != null:
		_load_model_for_hero()
		_apply_hero_visuals()

	health = max_health
	mana = max_mana
	_apply_camera_limits()
	_update_camera_zoom()
	if not get_viewport().size_changed.is_connected(_update_camera_zoom):
		get_viewport().size_changed.connect(_update_camera_zoom)
	var window := get_window()
	if window != null and not window.size_changed.is_connected(_update_camera_zoom):
		window.size_changed.connect(_update_camera_zoom)
	_sync_jump_key_state()
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		_update_model_animation(Vector2.ZERO)
		_update_draw_order()
		return

	if tower_mode:
		velocity = Vector2.ZERO
		if not visible:
			_update_model_animation(Vector2.ZERO)
			_update_draw_order()
			return
		attack_cooldown = max(attack_cooldown - delta, 0.0)
		damage_cooldown = max(damage_cooldown - delta, 0.0)
		_process_attack(delta, Vector2.ZERO)
		_update_model_animation(Vector2.ZERO)
		_try_attack()
		_update_visual_state()
		_update_draw_order()
		return

	if not controls_enabled:
		velocity = Vector2.ZERO
		_update_model_animation(Vector2.ZERO)
		_update_draw_order()
		return

	attack_cooldown = max(attack_cooldown - delta, 0.0)
	damage_cooldown = max(damage_cooldown - delta, 0.0)
	jump_cooldown_remaining = max(jump_cooldown_remaining - delta, 0.0)

	var input_direction := _get_move_input()
	_handle_jump_input(input_direction)

	if is_jumping:
		velocity = Vector2.ZERO
		move_and_slide()
		_process_jump(delta)
		_update_model_animation(Vector2.ZERO)
		_update_visual_state()
		_update_draw_order()
		return

	var bounds_end := movement_bounds.position + movement_bounds.size
	velocity = input_direction * move_speed
	move_and_slide()
	global_position = global_position.clamp(movement_bounds.position, bounds_end)

	if input_direction != Vector2.ZERO:
		facing_direction = input_direction
		_update_facing(input_direction)

	_process_attack(delta, input_direction)
	_update_model_animation(input_direction)
	_try_attack()
	_apply_enemy_push_around_player()
	_update_visual_state()
	_update_draw_order()


func configure(bounds: Rect2) -> void:
	movement_bounds = bounds
	if is_inside_tree():
		_apply_camera_limits()
		_update_camera_zoom()


func set_controls_enabled(is_enabled: bool) -> void:
	if tower_mode:
		controls_enabled = false
		velocity = Vector2.ZERO
		_sync_jump_key_state()
		return
	controls_enabled = is_enabled
	if not controls_enabled:
		velocity = Vector2.ZERO
	_sync_jump_key_state()


func set_tower_mode(is_enabled: bool) -> void:
	tower_mode = is_enabled
	if tower_mode:
		controls_enabled = false
		velocity = Vector2.ZERO
		is_jumping = false
		_cancel_attack(false)
	if camera != null:
		camera.enabled = not tower_mode


func apply_hero_data(data: HeroData) -> void:
	if data == null:
		return

	hero_data = data
	runtime_bonus_values.clear()
	runtime_progress_values = {
		"gold": 0.0,
		"exp": 0.0,
		"kill_count": 0.0,
		"level": 1.0,
	}
	_rebuild_combat_stats(false)
	is_dead = false
	attack_cooldown = 0.0
	damage_cooldown = 0.0
	is_jumping = false
	attack_in_progress = false
	attack_pending_projectile = false
	attack_elapsed = 0.0
	attack_fire_time = 0.0
	attack_direction = Vector2.DOWN
	attack_cycle_duration = 0.0
	jump_elapsed = 0.0
	jump_phase = 0
	jump_cooldown_remaining = 0.0
	jump_key_was_pressed = false
	jump_total_elapsed = 0.0
	jump_start_position = Vector2.ZERO
	jump_target_position = Vector2.ZERO
	jump_travel_direction = Vector2.DOWN
	jump_collision_ignore_seconds = -1.0
	jump_collision_land_seconds = -1.0
	jump_motion_duration_override = -1.0
	jump_collision_ignore_applied = false
	jump_collision_land_applied = false
	facing_direction = Vector2.DOWN
	visual_root.rotation = 0.0
	_load_model_for_hero()

	if is_inside_tree():
		_apply_hero_visuals()
	_sync_jump_key_state()

	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)


func get_combat_stats():
	return combat_stats


func get_bonus_values() -> Dictionary:
	return runtime_bonus_values.duplicate(true)


func set_bonus_values(values: Dictionary, preserve_resources: bool = true) -> void:
	runtime_bonus_values.clear()
	for raw_key in values.keys():
		_set_bonus_value_internal(StringName(String(raw_key)), float(values[raw_key]))
	_rebuild_combat_stats(preserve_resources)


func merge_bonus_values(values: Dictionary, preserve_resources: bool = true) -> void:
	for raw_key in values.keys():
		_set_bonus_value_internal(StringName(String(raw_key)), float(values[raw_key]))
	_rebuild_combat_stats(preserve_resources)


func set_bonus_value(stat_id: StringName, value: float, preserve_resources: bool = true) -> void:
	_set_bonus_value_internal(stat_id, value)
	_rebuild_combat_stats(preserve_resources)


func add_bonus_value(stat_id: StringName, delta: float, preserve_resources: bool = true) -> void:
	var stat_key := StringName(String(stat_id))
	var next_value := float(runtime_bonus_values.get(stat_key, 0.0)) + delta
	_set_bonus_value_internal(stat_key, next_value)
	_rebuild_combat_stats(preserve_resources)


func clear_bonus_values(preserve_resources: bool = true) -> void:
	runtime_bonus_values.clear()
	_rebuild_combat_stats(preserve_resources)


func sync_runtime_progress(current_gold: int, current_exp: int, current_kill_count: int, current_level: int) -> void:
	var previous_level := int(round(float(runtime_progress_values.get("level", 1.0))))
	runtime_progress_values["gold"] = float(current_gold)
	runtime_progress_values["exp"] = float(current_exp)
	runtime_progress_values["kill_count"] = float(current_kill_count)
	runtime_progress_values["level"] = float(current_level)

	if combat_stats == null:
		return

	if current_level != previous_level:
		_rebuild_combat_stats(true)
		return

	_apply_runtime_progress_to_stats()


func _rebuild_combat_stats(preserve_resources: bool) -> void:
	if hero_data == null:
		return

	var previous_health := health
	var previous_mana := mana
	combat_stats = AttributeSystemScript.build_hero_stats(hero_data, runtime_bonus_values, runtime_progress_values)
	max_health = combat_stats.get_stat_int(&"max_health", hero_data.starting_max_health)
	max_mana = combat_stats.get_stat_int(&"max_mana", hero_data.starting_max_mana)
	attack_damage = int(round(AttributeSystemScript.calculate_basic_attack_damage(combat_stats)))
	move_speed = combat_stats.get_stat(&"move_speed", hero_data.starting_move_speed)
	attack_interval = combat_stats.get_stat(&"final_attack_interval", hero_data.starting_attack_interval)
	attack_range = combat_stats.get_stat(&"attack_range", hero_data.starting_attack_range)

	if preserve_resources:
		health = clampi(previous_health, 0, max_health)
		mana = clampi(previous_mana, 0, max_mana)
	else:
		health = max_health
		mana = max_mana

	if not attack_in_progress:
		attack_cooldown = minf(attack_cooldown, maxf(attack_interval, MIN_ATTACK_CYCLE))

	_apply_runtime_progress_to_stats()
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)


func _set_bonus_value_internal(stat_id: StringName, value: float) -> void:
	var key_text := String(stat_id).strip_edges()
	if key_text.is_empty():
		return

	var key := StringName(key_text)
	if absf(value) < 0.0001:
		runtime_bonus_values.erase(key)
	else:
		runtime_bonus_values[key] = value


func _apply_runtime_progress_to_stats() -> void:
	if combat_stats == null:
		return

	for raw_key in runtime_progress_values.keys():
		combat_stats.set_stat(StringName(String(raw_key)), float(runtime_progress_values[raw_key]))


func receive_damage(amount: int) -> void:
	if is_dead or is_jumping or damage_cooldown > 0.0:
		return

	var reduced_damage := amount
	if combat_stats != null:
		reduced_damage = int(ceil(AttributeSystemScript.calculate_incoming_damage(
			float(amount),
			&"physical",
			combat_stats.get_stat(&"armor"),
			combat_stats.get_stat(&"magic_resist")
		)))
	reduced_damage = max(reduced_damage, 1)
	health = max(health - reduced_damage, 0)
	damage_cooldown = invulnerability_time
	health_changed.emit(health, max_health)

	if health == 0:
		is_dead = true
		_cancel_attack(false)
		velocity = Vector2.ZERO
		if current_hero_model != null:
			current_hero_model.play_death()
		died.emit()

	_update_visual_state()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	var next_health := clampi(health + amount, 0, max_health)
	if next_health == health:
		return
	health = next_health
	health_changed.emit(health, max_health)


func restore_mana(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	var next_mana := clampi(mana + amount, 0, max_mana)
	if next_mana == mana:
		return
	mana = next_mana
	mana_changed.emit(mana, max_mana)


func respawn(respawn_position: Vector2, invulnerability: float = 1.5) -> void:
	if hero_data == null:
		return

	is_dead = false
	is_jumping = false
	velocity = Vector2.ZERO
	global_position = respawn_position.clamp(movement_bounds.position, movement_bounds.position + movement_bounds.size)
	health = max_health
	mana = max_mana
	damage_cooldown = maxf(invulnerability, invulnerability_time)
	attack_cooldown = 0.0
	attack_in_progress = false
	attack_pending_projectile = false
	attack_elapsed = 0.0
	attack_fire_time = 0.0
	attack_cycle_duration = 0.0
	jump_elapsed = 0.0
	jump_phase = 0
	jump_cooldown_remaining = 0.0
	jump_key_was_pressed = false
	jump_total_elapsed = 0.0
	jump_start_position = Vector2.ZERO
	jump_target_position = Vector2.ZERO
	jump_travel_direction = Vector2.DOWN
	jump_collision_ignore_seconds = -1.0
	jump_collision_land_seconds = -1.0
	jump_motion_duration_override = -1.0
	jump_collision_ignore_applied = false
	jump_collision_land_applied = false
	if collision_shape != null:
		collision_shape.disabled = false

	_load_model_for_hero()
	_apply_hero_visuals()
	_update_facing(facing_direction)
	_update_model_animation(Vector2.ZERO)
	_update_visual_state()
	_sync_jump_key_state()
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)


func _get_move_input() -> Vector2:
	var x := int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var y := int(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - int(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	var direction := Vector2(x, y)

	if direction == Vector2.ZERO:
		return Vector2.ZERO

	return direction.normalized()


func _sync_jump_key_state() -> void:
	jump_key_was_pressed = Input.is_physical_key_pressed(KEY_SPACE)


func _try_attack() -> void:
	if attack_in_progress or attack_cooldown > 0.0 or is_jumping or velocity != Vector2.ZERO:
		return

	var enemy: Node2D = _get_nearest_enemy()
	if enemy == null:
		return

	var to_enemy: Vector2 = enemy.global_position - global_position
	if to_enemy.length_squared() > attack_range * attack_range:
		return

	var direction: Vector2 = to_enemy.normalized()
	facing_direction = direction
	_update_facing(direction)
	_start_attack(direction)


func _get_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D = null
	var nearest_distance_squared: float = INF

	for enemy_node in _get_enemy_nodes_for_current_physics_frame():
		var enemy := enemy_node as Node2D
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue

		var distance_squared: float = global_position.distance_squared_to(enemy.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_enemy = enemy

	return nearest_enemy


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	if current_hero_model != null and not current_hero_model.rotate_with_facing:
		visual_root.rotation = 0.0
		return

	visual_root.rotation = round(Vector2.UP.angle_to(direction) / TURN_STEP) * TURN_STEP


func _update_model_animation(input_direction: Vector2) -> void:
	if current_hero_model == null:
		return
	if is_jumping:
		return

	current_hero_model.set_motion_state(input_direction, input_direction != Vector2.ZERO)


func _start_attack(direction: Vector2) -> void:
	attack_in_progress = true
	attack_pending_projectile = true
	attack_elapsed = 0.0
	attack_cycle_duration = maxf(attack_interval, MIN_ATTACK_CYCLE)
	attack_cooldown = attack_cycle_duration
	attack_direction = direction
	var hit_ratio := ATTACK_RELEASE_FRAME / ATTACK_TOTAL_FRAMES

	if current_hero_model != null:
		var timing_variant: Variant = current_hero_model.play_attack(direction, attack_cycle_duration)
		if timing_variant is Dictionary:
			var timing: Dictionary = timing_variant as Dictionary
			hit_ratio = clampf(float(timing.get("hit_ratio", hit_ratio)), 0.0, 1.0)

	attack_fire_time = attack_cycle_duration * hit_ratio


func _process_attack(delta: float, input_direction: Vector2) -> void:
	if not attack_in_progress:
		return

	if input_direction != Vector2.ZERO:
		_cancel_attack(attack_pending_projectile)
		return

	attack_elapsed += delta
	if attack_pending_projectile and attack_elapsed >= attack_fire_time:
		attack_pending_projectile = false
		projectile_requested.emit(
			global_position + attack_direction * PROJECTILE_SPAWN_DISTANCE,
			attack_direction,
			attack_damage,
			combat_stats.duplicate_stats() if combat_stats != null else null
		)

	if attack_elapsed >= attack_cycle_duration:
		attack_in_progress = false
		attack_elapsed = 0.0
		attack_fire_time = 0.0
		attack_cycle_duration = 0.0


func _cancel_attack(refund_cooldown: bool) -> void:
	if not attack_in_progress and not attack_pending_projectile:
		return

	attack_in_progress = false
	attack_pending_projectile = false
	attack_elapsed = 0.0
	attack_fire_time = 0.0
	attack_cycle_duration = 0.0
	if refund_cooldown:
		attack_cooldown = 0.0

	if current_hero_model != null:
		current_hero_model.cancel_attack()


func can_receive_enemy_damage() -> bool:
	return not is_dead


func _handle_jump_input(input_direction: Vector2) -> void:
	var jump_pressed := Input.is_physical_key_pressed(KEY_SPACE)
	var just_pressed := jump_pressed and not jump_key_was_pressed
	jump_key_was_pressed = jump_pressed

	if not just_pressed or is_jumping or jump_cooldown_remaining > 0.0:
		return
	if attack_in_progress or is_dead or not controls_enabled:
		return

	_start_jump(input_direction if input_direction != Vector2.ZERO else facing_direction)


func _start_jump(direction: Vector2) -> void:
	is_jumping = true
	jump_elapsed = 0.0
	jump_phase = 0
	jump_total_elapsed = 0.0
	jump_cooldown_remaining = jump_cooldown
	_load_jump_motion_config()
	_cancel_attack(true)
	jump_collision_ignore_applied = false
	jump_collision_land_applied = false
	if jump_collision_ignore_seconds <= 0.0:
		_set_jump_collision_disabled(true)
		jump_collision_ignore_applied = true
	else:
		_set_jump_collision_disabled(false)
	velocity = Vector2.ZERO
	var travel_direction: Vector2 = direction
	if travel_direction == Vector2.ZERO:
		travel_direction = facing_direction
	if travel_direction == Vector2.ZERO:
		travel_direction = Vector2.DOWN
	jump_travel_direction = travel_direction.normalized()
	facing_direction = jump_travel_direction
	_update_facing(facing_direction)
	jump_start_position = global_position
	var bounds_end := movement_bounds.position + movement_bounds.size
	jump_target_position = (jump_start_position + jump_travel_direction * maxf(jump_forward_distance, 0.0)).clamp(
		movement_bounds.position,
		bounds_end
	)
	if current_hero_model != null:
		current_hero_model.start_jump(facing_direction)


func _process_jump(delta: float) -> void:
	var phase_durations: PackedFloat32Array = _get_jump_phase_durations()
	if phase_durations.size() < 3:
		return

	if current_hero_model != null:
		current_hero_model.set_jump_direction(jump_travel_direction)

	jump_elapsed += delta
	jump_total_elapsed += delta
	_update_jump_collision_window()
	var total_duration: float = phase_durations[0] + phase_durations[1] + phase_durations[2]
	var travel_t: float = clampf(jump_total_elapsed / maxf(total_duration, 0.001), 0.0, 1.0)
	global_position = jump_start_position.lerp(jump_target_position, travel_t)

	if jump_phase == 0:
		var ascent_t := clampf(jump_elapsed / phase_durations[0], 0.0, 1.0)
		_set_jump_visual_height(-jump_height * sin(ascent_t * PI / 2.0))
		if jump_elapsed >= phase_durations[0]:
			jump_phase = 1
			jump_elapsed = 0.0
			if current_hero_model != null and current_hero_model.has_method("set_jump_phase"):
				current_hero_model.set_jump_phase(1)
	elif jump_phase == 1:
		_set_jump_visual_height(-jump_height)
		if jump_elapsed >= phase_durations[1]:
			jump_phase = 2
			jump_elapsed = 0.0
			if current_hero_model != null and current_hero_model.has_method("set_jump_phase"):
				current_hero_model.set_jump_phase(2)
	elif jump_phase == 2:
		var landing_t := clampf(jump_elapsed / phase_durations[2], 0.0, 1.0)
		_set_jump_visual_height(-jump_height * (1.0 - landing_t))
		if jump_elapsed >= phase_durations[2]:
			_finish_jump()


func _finish_jump() -> void:
	is_jumping = false
	jump_elapsed = 0.0
	jump_phase = 0
	jump_total_elapsed = 0.0
	jump_collision_ignore_seconds = -1.0
	jump_collision_land_seconds = -1.0
	jump_motion_duration_override = -1.0
	jump_collision_ignore_applied = false
	jump_collision_land_applied = false
	global_position = jump_target_position
	_set_jump_visual_height(0.0)
	_set_jump_collision_disabled(false)
	_push_overlapping_enemies()
	if current_hero_model != null:
		current_hero_model.stop_jump(facing_direction, false)


func _get_jump_phase_durations() -> PackedFloat32Array:
	var takeoff: float = maxf(jump_takeoff_duration, 0.02)
	var air: float = maxf(jump_air_duration, 0.02)
	var landing: float = maxf(jump_landing_duration, 0.02)
	var total: float = takeoff + air + landing
	var max_total: float = maxf(jump_max_duration, 0.06)
	if jump_motion_duration_override > 0.0:
		max_total = maxf(jump_motion_duration_override, 0.06)
	if total > max_total:
		var duration_scale: float = max_total / total
		takeoff *= duration_scale
		air *= duration_scale
		landing *= duration_scale
	return PackedFloat32Array([takeoff, air, landing])


func _load_jump_motion_config() -> void:
	jump_collision_ignore_seconds = -1.0
	jump_collision_land_seconds = -1.0
	jump_motion_duration_override = -1.0
	if current_hero_model == null or not current_hero_model.has_method("get_jump_motion_config"):
		return
	var config: Variant = current_hero_model.call("get_jump_motion_config")
	if config is not Dictionary:
		return
	var jump_config := config as Dictionary
	jump_collision_ignore_seconds = float(jump_config.get("ignore_collision_seconds", -1.0))
	jump_collision_land_seconds = float(jump_config.get("land_seconds", -1.0))
	jump_motion_duration_override = float(jump_config.get("duration_seconds", -1.0))


func _update_jump_collision_window() -> void:
	if jump_collision_ignore_seconds >= 0.0 and not jump_collision_ignore_applied and jump_total_elapsed >= jump_collision_ignore_seconds:
		_set_jump_collision_disabled(true)
		jump_collision_ignore_applied = true
	if jump_collision_land_seconds >= 0.0 and not jump_collision_land_applied and jump_total_elapsed >= jump_collision_land_seconds:
		_set_jump_collision_disabled(false)
		jump_collision_land_applied = true


func _set_jump_collision_disabled(disabled: bool) -> void:
	if collision_shape != null:
		collision_shape.set_deferred("disabled", disabled)


func _set_jump_visual_height(offset_y: float) -> void:
	if current_hero_model != null:
		current_hero_model.set_visual_height(offset_y)


func _push_overlapping_enemies() -> void:
	for enemy_node in _get_enemy_nodes_for_current_physics_frame():
		var enemy := enemy_node as Node2D
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue

		var to_enemy: Vector2 = enemy.global_position - global_position
		var distance: float = to_enemy.length()
		if distance >= landing_push_radius:
			continue

		var push_direction: Vector2 = to_enemy.normalized() if distance > 0.001 else Vector2.RIGHT.rotated(randf() * TAU)
		var push_amount: float = landing_push_strength + (landing_push_radius - distance)
		enemy.global_position += push_direction * push_amount


func _apply_camera_limits() -> void:
	var bounds_end := movement_bounds.position + movement_bounds.size
	camera.limit_left = int(movement_bounds.position.x)
	camera.limit_top = int(movement_bounds.position.y)
	camera.limit_right = int(bounds_end.x)
	camera.limit_bottom = int(bounds_end.y)


func _update_camera_zoom() -> void:
	if camera == null:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var zoom_x := camera_target_visible_size.x / viewport_size.x
	var zoom_y := camera_target_visible_size.y / viewport_size.y
	var adaptive_zoom := clampf(minf(zoom_x, zoom_y), min_camera_zoom, max_camera_zoom)
	camera.zoom = Vector2.ONE * adaptive_zoom


func _update_visual_state() -> void:
	if current_model_root == null:
		return

	if is_dead:
		current_model_root.modulate = Color(1, 1, 1, 1)
		return

	if damage_cooldown > 0.0:
		var blink_on := int(Time.get_ticks_msec() / 70.0) % 2 == 0
		var tint := Color(1, 0.65, 0.65, 1) if blink_on else Color(1, 1, 1, 1)
		current_model_root.modulate = tint
		return

	current_model_root.modulate = Color(1, 1, 1, 1)


func _apply_hero_visuals() -> void:
	if hero_data == null or current_model_root == null:
		return

	if current_hero_model != null:
		current_hero_model.apply_colors(hero_data.body_color, hero_data.accent_color)


func _load_model_for_hero() -> void:
	if hero_data == null:
		return

	for child in visual_root.get_children():
		child.queue_free()

	current_model_root = null
	current_hero_model = null

	var instance := HeroModelCatalog.instantiate_model(hero_data.model_id)
	if instance == null:
		push_warning("Missing hero model for model_id: %s" % String(hero_data.model_id))
		return

	if instance is not Node2D:
		push_warning("Hero model scene root must inherit Node2D: %s" % String(hero_data.model_id))
		return

	current_model_root = instance as Node2D
	visual_root.add_child(current_model_root)
	current_hero_model = current_model_root as HeroModel

	if current_hero_model != null:
		_apply_collision_radius(current_hero_model.collision_radius)

	_update_draw_order()


func _apply_collision_radius(radius: float) -> void:
	if collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius


func _update_draw_order() -> void:
	z_as_relative = false
	var order_value: int = DRAW_ORDER_BASE + int(round(global_position.y))
	z_index = clampi(order_value, DRAW_ORDER_MIN, DRAW_ORDER_MAX)


func _apply_enemy_push_around_player() -> void:
	if is_dead:
		return

	var min_distance: float = maxf(enemy_push_min_distance, 1.0)
	var max_step: float = maxf(enemy_push_max_step, 0.0)
	if max_step <= 0.0:
		return

	for enemy_node in _get_enemy_nodes_for_current_physics_frame():
		var enemy: Node2D = enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue

		var to_enemy: Vector2 = enemy.global_position - global_position
		var distance: float = to_enemy.length()
		if distance >= min_distance:
			continue

		var push_dir: Vector2 = to_enemy.normalized() if distance > 0.001 else Vector2.RIGHT.rotated(randf() * TAU)
		var penetration: float = min_distance - distance
		var push_step: float = minf(penetration, max_step)
		enemy.global_position += push_dir * push_step


func _get_enemy_nodes_for_current_physics_frame() -> Array:
	var current_frame: int = Engine.get_physics_frames()
	if _enemy_query_frame != current_frame:
		_enemy_query_frame = current_frame
		_enemy_query_nodes = get_tree().get_nodes_in_group("enemy")
	return _enemy_query_nodes
