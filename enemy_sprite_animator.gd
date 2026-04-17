extends Node2D
class_name EnemySpriteAnimator

const Model3DProfileCatalogScript := preload("res://model3d_profile_catalog.gd")
const Model3DActorAnimatorScript := preload("res://model3d_actor_animator.gd")

@export var visual_offset := Vector2(0, -8)
@export var display_scale := 1.0

var _last_direction := Vector2.DOWN
var _dead := false
var _attack_locked := false
var _model3d_actor: Model3DActorAnimator


func _ready() -> void:
	scale = Vector2.ONE
	position = Vector2.ZERO
	_ensure_model3d_actor()
	if _model3d_actor != null:
		_model3d_actor.visible = false


func configure_model_id(model_id: StringName) -> bool:
	var model_key := StringName(String(model_id).strip_edges())
	if not Model3DProfileCatalogScript.has_profile(model_key):
		return false

	_ensure_model3d_actor()
	if _model3d_actor == null:
		return false

	var configured: bool = _model3d_actor.configure_model_id(model_key)
	if not configured:
		return false

	_dead = false
	_attack_locked = false
	_last_direction = Vector2.DOWN
	scale = Vector2.ONE
	position = Vector2.ZERO
	_model3d_actor.visible = true
	return true


func set_motion_state(direction: Vector2, is_moving: bool) -> void:
	if _dead or _attack_locked:
		return
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_forward_to_model3d(&"set_motion_state", [direction, is_moving])


func play_death() -> void:
	_dead = true
	_attack_locked = false
	_forward_to_model3d(&"play_death", [])


func start_attack_preview(direction: Vector2) -> void:
	if _dead:
		return
	_attack_locked = true
	_forward_to_model3d(&"start_attack_preview", [direction])


func set_attack_preview_progress(direction: Vector2, progress: float) -> void:
	if _dead:
		return
	_attack_locked = true
	_forward_to_model3d(&"set_attack_preview_progress", [direction, progress])


func play_attack_hit(direction: Vector2) -> void:
	if _dead:
		return
	_attack_locked = true
	_forward_to_model3d(&"play_attack_hit", [direction])


func set_attack_recover_progress(direction: Vector2, progress: float) -> void:
	if _dead:
		return
	_attack_locked = true
	_forward_to_model3d(&"set_attack_recover_progress", [direction, progress])


func stop_attack(direction: Vector2) -> void:
	if _dead:
		return
	_attack_locked = false
	_forward_to_model3d(&"stop_attack", [direction])


func set_dissolve_progress(progress: float) -> void:
	_forward_to_model3d(&"set_dissolve_progress", [progress])


func play_hit() -> void:
	if _dead:
		return
	_forward_to_model3d(&"play_hit", [])


func set_stunned(enabled: bool) -> void:
	if _dead:
		return
	_forward_to_model3d(&"set_stunned", [enabled])


func play_spawn() -> void:
	if _dead:
		return
	_forward_to_model3d(&"play_spawn", [])


func set_runtime_active(enabled: bool) -> void:
	if _model3d_actor == null or not is_instance_valid(_model3d_actor):
		return
	if _model3d_actor.has_method("set_runtime_active"):
		_model3d_actor.call("set_runtime_active", enabled)
	if not enabled:
		_model3d_actor.visible = false


func reset_runtime_state(default_direction: Vector2 = Vector2.DOWN, force_idle: bool = true) -> void:
	_dead = false
	_attack_locked = false
	if default_direction != Vector2.ZERO:
		_last_direction = default_direction.normalized()
	else:
		_last_direction = Vector2.DOWN
	_forward_to_model3d(&"reset_runtime_state", [_last_direction, force_idle])


func _ensure_model3d_actor() -> void:
	if _model3d_actor != null and is_instance_valid(_model3d_actor):
		_model3d_actor.display_offset = visual_offset
		_model3d_actor.display_scale = display_scale
		return

	var actor := Model3DActorAnimatorScript.new()
	if actor == null:
		return

	_model3d_actor = actor
	_model3d_actor.name = "Model3DActor"
	_model3d_actor.display_offset = visual_offset
	_model3d_actor.display_scale = display_scale
	_model3d_actor.visible = false
	add_child(_model3d_actor)


func _forward_to_model3d(method_name: StringName, args: Array) -> void:
	if _model3d_actor == null or not is_instance_valid(_model3d_actor):
		return
	if not _model3d_actor.has_method(method_name):
		return
	_model3d_actor.visible = true
	_model3d_actor.callv(method_name, args)
