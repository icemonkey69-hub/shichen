extends Node2D
class_name EnemySpriteAnimator

const Model3DActorAnimatorScript := preload("res://model3d_actor_animator.gd")

@export var visual_offset := Vector2(0, -8)
@export var display_scale := Model3DActorAnimatorScript.DEFAULT_SPRITE_SCALE

var _last_direction := Vector2.DOWN
var _dead := false
var _attack_locked := false
var _model3d_actor: Node = null
var _configured_model_id: StringName = &""


func _ready() -> void:
	scale = Vector2.ONE
	position = Vector2.ZERO
	_ensure_model3d_actor()
	if _model3d_actor != null:
		_model3d_actor.visible = false


func configure_model_id(model_id: StringName) -> bool:
	var requested_model_id := StringName(String(model_id).strip_edges())
	_ensure_model3d_actor()
	if _model3d_actor == null:
		return false
	if _model3d_actor != null and String(_configured_model_id).strip_edges() == String(requested_model_id).strip_edges():
		if _model3d_actor.has_method("ensure_model_ready"):
			_model3d_actor.call("ensure_model_ready")
		_dead = false
		_attack_locked = false
		_model3d_actor.visible = true
		return true

	var configured: bool = bool(_model3d_actor.configure_model_id(requested_model_id))
	if configured and _model3d_actor.has_method("ensure_model_ready"):
		_model3d_actor.call("ensure_model_ready")
	if not configured:
		_configured_model_id = &""
		return false
	_configured_model_id = requested_model_id
	_dead = false
	_attack_locked = false
	_last_direction = Vector2.DOWN
	scale = Vector2.ONE
	position = Vector2.ZERO
	_model3d_actor.visible = true
	return configured


func ensure_model_ready() -> void:
	if _model3d_actor != null and _model3d_actor.has_method("ensure_model_ready"):
		_model3d_actor.call("ensure_model_ready")


func set_motion_state(direction: Vector2, _is_moving: bool) -> void:
	if _dead or _attack_locked:
		return
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_forward_to_model3d(&"set_motion_state", [direction, _is_moving])


func play_death() -> void:
	_dead = true
	_attack_locked = false
	_forward_to_model3d(&"play_death", [])


func start_attack_preview(direction: Vector2) -> void:
	if _dead:
		return
	_attack_locked = true
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_forward_to_model3d(&"start_attack_preview", [direction])


func set_attack_preview_progress(direction: Vector2, _progress: float) -> void:
	start_attack_preview(direction)
	_forward_to_model3d(&"set_attack_preview_progress", [direction, _progress])


func play_attack_hit(direction: Vector2) -> void:
	start_attack_preview(direction)
	_forward_to_model3d(&"play_attack_hit", [direction])


func set_attack_recover_progress(direction: Vector2, _progress: float) -> void:
	start_attack_preview(direction)
	_forward_to_model3d(&"set_attack_recover_progress", [direction, _progress])


func stop_attack(direction: Vector2) -> void:
	if _dead:
		return
	_attack_locked = false
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_forward_to_model3d(&"stop_attack", [direction])


func set_dissolve_progress(_progress: float) -> void:
	_forward_to_model3d(&"set_dissolve_progress", [_progress])


func play_hit() -> void:
	if _dead:
		return
	_forward_to_model3d(&"play_hit", [])


func set_stunned(_enabled: bool) -> void:
	if _dead:
		return
	_forward_to_model3d(&"set_stunned", [_enabled])


func play_spawn() -> void:
	if _dead:
		return
	_forward_to_model3d(&"play_spawn", [])


func set_runtime_active(_enabled: bool) -> void:
	if _model3d_actor == null or not is_instance_valid(_model3d_actor):
		return
	if _model3d_actor.has_method("set_runtime_active"):
		_model3d_actor.call("set_runtime_active", _enabled)
	if not _enabled:
		_model3d_actor.visible = false


func reset_runtime_state(default_direction: Vector2 = Vector2.DOWN, _force_idle: bool = true) -> void:
	_dead = false
	_attack_locked = false
	_last_direction = default_direction.normalized() if default_direction != Vector2.ZERO else Vector2.DOWN
	_forward_to_model3d(&"reset_runtime_state", [_last_direction, _force_idle])


func _ensure_model3d_actor() -> void:
	if _model3d_actor != null and is_instance_valid(_model3d_actor):
		_model3d_actor.visual_offset = visual_offset
		_model3d_actor.display_scale = display_scale
		return

	var actor := Model3DActorAnimatorScript.new()
	if actor == null:
		return

	_model3d_actor = actor
	_model3d_actor.name = "Model3DActor"
	_model3d_actor.visual_offset = visual_offset
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
