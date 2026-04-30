extends CharacterBody2D
class_name Guardian

const WARRIOR_IDLE_TEXTURE := preload("res://Tiny Swords (Free Pack)/Units/Black Units/Warrior/Warrior_Idle.png")
const WARRIOR_RUN_TEXTURE := preload("res://Tiny Swords (Free Pack)/Units/Black Units/Warrior/Warrior_Run.png")
const WARRIOR_FRAME_SIZE := Vector2(192.0, 192.0)
const WARRIOR_IDLE_FRAMES := 8
const WARRIOR_RUN_FRAMES := 6
const WARRIOR_IDLE_FPS := 7.0
const WARRIOR_RUN_FPS := 10.0

@export var move_speed := 320.0
@export var movement_bounds := Rect2(-1000.0, -1000.0, 2000.0, 2000.0)
@export var clamp_to_movement_bounds := false
@export var use_camera_limits := false
@export var camera_target_visible_size := Vector2(1450.0, 820.0)
@export var min_camera_zoom := 0.68
@export var max_camera_zoom := 1.2

@onready var camera: Camera2D = $Camera2D
@onready var visual_root: Node2D = $VisualRoot
@onready var sprite: Sprite2D = $VisualRoot/Sprite

var controls_enabled := false
var facing_direction := Vector2.DOWN
var animation_name: StringName = &"idle"
var animation_frame := 0
var animation_elapsed := 0.0


func _ready() -> void:
	_apply_animation(&"idle", true)
	_apply_camera_limits()
	_update_camera_zoom()
	if not get_viewport().size_changed.is_connected(_update_camera_zoom):
		get_viewport().size_changed.connect(_update_camera_zoom)
	var window := get_window()
	if window != null and not window.size_changed.is_connected(_update_camera_zoom):
		window.size_changed.connect(_update_camera_zoom)


func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		_apply_animation(&"idle")
		_advance_animation(_delta)
		return

	var input_direction := _get_move_input()
	velocity = input_direction * move_speed
	move_and_slide()
	if clamp_to_movement_bounds:
		global_position = global_position.clamp(movement_bounds.position, movement_bounds.position + movement_bounds.size)

	if input_direction != Vector2.ZERO:
		facing_direction = input_direction
		sprite.flip_h = input_direction.x < -0.01
		_apply_animation(&"run")
	else:
		_apply_animation(&"idle")

	_advance_animation(_delta)
	z_index = clampi(2000 + int(round(global_position.y)), 1, 4095)


func configure(bounds: Rect2) -> void:
	movement_bounds = bounds
	if is_inside_tree():
		_apply_camera_limits()
		_update_camera_zoom()


func set_controls_enabled(is_enabled: bool) -> void:
	controls_enabled = is_enabled
	if not controls_enabled:
		velocity = Vector2.ZERO


func set_camera_enabled(is_enabled: bool) -> void:
	if camera != null:
		camera.enabled = is_enabled


func can_receive_enemy_damage() -> bool:
	return false


func receive_damage(_amount: int) -> void:
	pass


func _apply_animation(next_animation: StringName, force_restart := false) -> void:
	if sprite == null:
		return
	if not force_restart and animation_name == next_animation:
		return

	animation_name = next_animation
	animation_frame = 0
	animation_elapsed = 0.0
	sprite.region_enabled = true
	sprite.texture = WARRIOR_RUN_TEXTURE if animation_name == &"run" else WARRIOR_IDLE_TEXTURE
	_apply_animation_frame()


func _advance_animation(delta: float) -> void:
	if sprite == null:
		return
	var fps := WARRIOR_RUN_FPS if animation_name == &"run" else WARRIOR_IDLE_FPS
	var frame_count := WARRIOR_RUN_FRAMES if animation_name == &"run" else WARRIOR_IDLE_FRAMES
	animation_elapsed += delta
	var frame_duration := 1.0 / fps
	while animation_elapsed >= frame_duration:
		animation_elapsed -= frame_duration
		animation_frame = (animation_frame + 1) % frame_count
		_apply_animation_frame()


func _apply_animation_frame() -> void:
	if sprite == null:
		return
	sprite.region_rect = Rect2(Vector2(WARRIOR_FRAME_SIZE.x * float(animation_frame), 0.0), WARRIOR_FRAME_SIZE)


func _get_move_input() -> Vector2:
	var x := int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var y := int(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - int(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	var direction := Vector2(x, y)
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	return direction.normalized()


func _apply_camera_limits() -> void:
	if camera == null:
		return
	if not use_camera_limits:
		camera.limit_left = -10000000
		camera.limit_top = -10000000
		camera.limit_right = 10000000
		camera.limit_bottom = 10000000
		return
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
