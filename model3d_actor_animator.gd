extends Node2D
class_name Model3DActorAnimator

const Model3DProfileCatalogScript := preload("res://model3d_profile_catalog.gd")
const Model3DActionCatalogScript := preload("res://model3d_action_catalog.gd")
const Model3DToonOutlineShader := preload("res://assets/shaders/model3d_toon_outline.gdshader")
const PACK_ANIMATION_DIRS: Dictionary = {
	"skeletons": "res://combat_visual_editor/KayKit_Skeletons_1.1_FREE/Animations/gltf/Rig_Medium",
	"adventurers": "res://combat_visual_editor/KayKit_Adventurers_2.0_FREE/Animations/gltf/Rig_Medium",
}
const SHARED_MEDIUM_ANIMATIONS_DIR := "res://combat_visual_editor/KayKit_Character_Animations_1.1/Animations/gltf/Rig_Medium"
const UNIFIED_PACK_ID := "all_in_one"

static var _animation_library_cache: Dictionary = {}
static var _missing_attack_animation_warnings: Dictionary = {}

const RIGHT_HAND_BONE_HINTS := [
	"handslot.r",
	"handslot_r",
	"hand.r",
	"hand_r",
	"r_hand",
	"rhand",
	"righthand",
	"right hand",
	"mixamorig:righthand",
	"bip001rhand",
]
const LEFT_HAND_BONE_HINTS := [
	"handslot.l",
	"handslot_l",
	"hand.l",
	"hand_l",
	"l_hand",
	"lhand",
	"lefthand",
	"left hand",
	"mixamorig:lefthand",
	"bip001lhand",
]
const PROFILE_HAT_NODE_HINTS := ["hat", "hood", "cap", "mask", "helm", "helmet"]
const PROFILE_HAIR_NODE_HINTS := ["hair", "beard", "brow", "mustache", "mohawk"]
const PROFILE_SKIN_NODE_HINTS := ["head", "face", "skin", "ear", "nose", "jaw", "skull", "neck", "hand"]
const PROFILE_CLOTH_NODE_HINTS := ["body", "cloak", "cape", "robe", "cloth", "coat", "armor", "torso", "leg", "pants", "skirt", "shoulder", "boot", "shoe"]
const PROFILE_EYE_NODE_HINTS := ["eye", "eyes", "pupil"]
const PROFILE_SKELETON_BONE_NODE_HINTS := ["arm", "leg", "body", "head", "jaw", "skull", "spine", "rib", "pelvis", "hand", "foot"]
const PROFILE_HAT_COLOR_PRESETS := {
	"default": Color(1.0, 1.0, 1.0, 1.0),
	"blue": Color(0.45, 0.72, 1.18, 1.0),
	"green": Color(0.52, 1.12, 0.62, 1.0),
	"red": Color(1.22, 0.48, 0.48, 1.0),
	"purple": Color(0.92, 0.62, 1.22, 1.0),
}
const PROFILE_HAIR_COLOR_PRESETS := {
	"default": Color(1.0, 1.0, 1.0, 1.0),
	"blonde": Color(1.20, 1.02, 0.58, 1.0),
	"brown": Color(0.58, 0.38, 0.24, 1.0),
	"white": Color(1.15, 1.15, 1.15, 1.0),
	"blue": Color(0.52, 0.74, 1.20, 1.0),
}
const PROFILE_SKIN_COLOR_PRESETS := {
	"default": Color(1.0, 1.0, 1.0, 1.0),
	"light": Color(1.18, 1.03, 0.95, 1.0),
	"warm": Color(1.12, 0.90, 0.76, 1.0),
	"deep": Color(0.76, 0.56, 0.44, 1.0),
	"cold": Color(0.84, 0.86, 0.94, 1.0),
}
const PROFILE_CLOTH_COLOR_PRESETS := {
	"default": Color(1.0, 1.0, 1.0, 1.0),
	"navy": Color(0.58, 0.72, 1.20, 1.0),
	"olive": Color(0.66, 0.90, 0.54, 1.0),
	"wine": Color(1.08, 0.56, 0.68, 1.0),
	"golden": Color(1.06, 0.98, 0.66, 1.0),
}
const SELECTION_PREVIEW_CAMERA_DISTANCE := 4.3
const SELECTION_PREVIEW_CAMERA_TARGET_RATIO := 0.54
const SELECTION_PREVIEW_CAMERA_EYE_Y_OFFSET := 0.32

@export var viewport_size: Vector2i = Vector2i(180, 180)
@export var display_scale := 1.0
@export var display_offset := Vector2(0.0, -8.0)
@export var showcase_spin_speed := 0.0
@export var camera_fov := 42.0
@export var enable_toon_shading := true
@export var toon_steps := 4.0
@export var enable_outline := true
@export var outline_color := Color(0.06, 0.06, 0.08, 1.0)
@export var outline_size := 1.0
@export var enable_pixelate_sampling := false
@export var pixel_size := 2.0
@export var key_light_energy := 1.25
@export var fill_light_energy := 0.95
@export var key_light_rotation := Vector3(-40.0, 10.0, 0.0)
@export var fill_light_rotation := Vector3(-18.0, -125.0, 0.0)
@export var enable_key_shadows := false

var _sub_viewport: SubViewport
var _display_sprite: Sprite2D
var _world_root: Node3D
var _model_pivot: Node3D
var _camera: Camera3D
var _world_environment: WorldEnvironment
var _key_light: DirectionalLight3D
var _fill_light: DirectionalLight3D

var _profile_id: StringName = &""
var _profile: Dictionary = {}
var _state_animation_overrides: Dictionary = {}
var _state_animation_specs: Dictionary = {}
var _state_sequence_cursor: Dictionary = {}
var _state_last_clip: Dictionary = {}
var _state_active_sequence_group: Dictionary = {}
var _state_last_sequence_group: Dictionary = {}
var _character_root: Node3D
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D

var _attack_entries: Array[Dictionary] = []
var _attack_cursor := 0
var _active_attack_data: Dictionary = {}
var _active_attack_phase_index := -1
var _active_attack_speed_scale := 1.0

var _idle_animation := ""
var _run_animation := ""
var _hit_animation := ""
var _stun_animation := ""
var _death_animation := ""
var _jump_animation := ""
var _spawn_animation := ""
var _victory_animation := ""
var _default_attack_animation := ""

var _profile_anim_speed := 1.0
var _attack_locked := false
var _attack_lock_remaining := 0.0
var _is_dead := false
var _showcase_enabled := false
var _stun_enabled := false
var _current_animation := ""
var _active_state := ""
var _idle_random_cycle_elapsed := 0.0
var _selection_preview_victory_once_active := false
var _last_direction := Vector2.DOWN
var _last_is_moving := false
var _jump_height_offset := 0.0
var _jump_state_clips: PackedStringArray = PackedStringArray()
var _jump_state_active := false
var _jump_phase_index := -1
var _shader_missing_warning_emitted := false


func _ready() -> void:
	_ensure_runtime_nodes()
	_apply_display_transform()
	call_deferred("_apply_postprocess_material")
	set_process(true)


func _process(delta: float) -> void:
	if _showcase_enabled and not _is_dead and _model_pivot != null and absf(showcase_spin_speed) > 0.0001:
		_model_pivot.rotate_y(delta * showcase_spin_speed)

	if _attack_locked and _attack_lock_remaining > 0.0:
		_attack_lock_remaining = maxf(_attack_lock_remaining - delta, 0.0)
		if _attack_lock_remaining == 0.0:
			_attack_locked = false
			_active_attack_phase_index = -1
			_active_attack_speed_scale = _profile_anim_speed
			if not _is_dead:
				set_motion_state(_last_direction, _last_is_moving)

	_maintain_state_playback(delta)


func _maintain_state_playback(delta: float) -> void:
	if _animation_player == null:
		return
	if _active_state.is_empty():
		return
	if _attack_locked:
		return
	if _jump_state_active:
		return

	if _is_dead:
		if _active_state != "death":
			_play_state_animation("death", true)
			return
		if not _animation_player.is_playing() or _animation_player.speed_scale <= 0.0:
			_play_state_animation("death", true)
		return

	if _stun_enabled:
		if _active_state != "stun":
			_play_state_animation("stun", true)
			return
		if not _animation_player.is_playing() or _animation_player.speed_scale <= 0.0:
			_play_state_animation("stun", true)
		return

	if _active_state == "victory":
		if _selection_preview_victory_once_active:
			if not _animation_player.is_playing() or _animation_player.speed_scale <= 0.0:
				_selection_preview_victory_once_active = false
				_play_state_animation("idle", true)
			return
		if not _animation_player.is_playing() or _animation_player.speed_scale <= 0.0:
			_play_state_animation("victory", true)
		return

	if _active_state == "spawn" or _active_state == "hit":
		if _animation_player.is_playing() and _animation_player.speed_scale > 0.0:
			return

	if _showcase_enabled and _active_state == "idle" and _is_random_idle_state():
		_idle_random_cycle_elapsed += maxf(delta, 0.0)
		if _idle_random_cycle_elapsed >= 2.2:
			_idle_random_cycle_elapsed = 0.0
			_play_state_animation("idle", true)
			return

	if _last_is_moving:
		if _active_state != "move":
			_play_state_animation("move", true)
			return
		if not _animation_player.is_playing() or _animation_player.speed_scale <= 0.0:
			_play_state_animation("move", true)
		return

	if _active_state != "idle":
		_play_state_animation("idle", true)
		return
	if not _animation_player.is_playing() or _animation_player.speed_scale <= 0.0:
		_play_state_animation("idle", true)


func _is_random_idle_state() -> bool:
	var spec_variant: Variant = _state_animation_specs.get("idle", {})
	if spec_variant is not Dictionary:
		return false
	var spec: Dictionary = spec_variant as Dictionary
	var mode: String = String(spec.get("mode", "single")).to_lower()
	return mode == "random" or mode == "random_sequence"


func configure_model_id(model_id: StringName) -> bool:
	_ensure_runtime_nodes()
	var profile: Dictionary = Model3DProfileCatalogScript.get_profile(model_id)
	if profile.is_empty():
		return false

	_profile_id = model_id
	_profile = profile
	_rebuild_character_from_profile()
	return _character_root != null


func apply_profile_overrides(overrides: Dictionary) -> void:
	if overrides.is_empty():
		return
	if _profile.is_empty():
		return

	var merged_profile: Dictionary = _profile.duplicate(true)
	for raw_key in overrides.keys():
		var key_text: String = String(raw_key).strip_edges()
		if key_text.is_empty():
			continue
		var value: Variant = overrides[raw_key]
		if value == null:
			merged_profile.erase(key_text)
		else:
			merged_profile[key_text] = value

	_profile = merged_profile
	_rebuild_character_from_profile()


func set_motion_state(direction: Vector2, is_moving: bool) -> void:
	if _is_dead or _attack_locked or _stun_enabled or _jump_state_active:
		return

	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_last_is_moving = is_moving
	_update_facing(_last_direction)
	_enter_locomotion_state(false)


func play_attack(direction: Vector2, attack_duration: float) -> Dictionary:
	if _is_dead or _stun_enabled or _jump_state_active:
		return {}

	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_update_facing(_last_direction)
	_active_attack_data = _select_attack_entry()
	_active_attack_phase_index = -1
	var clip_length: float = float(_active_attack_data.get("length", 0.0))

	var speed_scale := _profile_anim_speed
	if attack_duration > 0.01 and clip_length > 0.01:
		speed_scale = _profile_anim_speed * (clip_length / attack_duration)
	_active_attack_speed_scale = speed_scale
	var started := false
	if _play_attack_phase_by_index(0, speed_scale):
		_active_state = "attack"
		started = true
	_attack_locked = true
	_attack_lock_remaining = maxf(attack_duration, 0.05)
	return _build_attack_timing_payload(attack_duration, started)


func cancel_attack() -> void:
	_attack_locked = false
	_attack_lock_remaining = 0.0
	_active_attack_phase_index = -1
	_active_attack_speed_scale = _profile_anim_speed
	if not _is_dead:
		_enter_locomotion_state(true)


func get_attack_timing() -> Dictionary:
	return _build_attack_timing_payload(maxf(_attack_lock_remaining, 0.0), _attack_locked)


func start_attack_preview(direction: Vector2) -> void:
	if _is_dead or _stun_enabled or _jump_state_active:
		return

	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_update_facing(_last_direction)
	_active_attack_data = _select_attack_entry()
	_active_attack_phase_index = -1
	_active_attack_speed_scale = _profile_anim_speed
	if _play_attack_phase_by_index(0, _profile_anim_speed):
		_active_state = "attack"
		_seek_attack_absolute_time(0.0)
		_set_animation_speed(0.0)
	_attack_locked = true
	_attack_lock_remaining = 0.0


func set_attack_preview_progress(direction: Vector2, progress: float) -> void:
	if _is_dead:
		return

	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_update_facing(_last_direction)
	if _active_attack_data.is_empty():
		_active_attack_data = _select_attack_entry()

	var hit_second: float = float(_active_attack_data.get("hit_second", 0.0))
	_seek_attack_absolute_time(clampf(progress, 0.0, 1.0) * maxf(hit_second, 0.0))
	_set_animation_speed(0.0)


func play_attack_hit(direction: Vector2) -> void:
	if _is_dead or _stun_enabled or _jump_state_active:
		return

	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_update_facing(_last_direction)
	if _active_attack_data.is_empty():
		_active_attack_data = _select_attack_entry()

	_seek_attack_absolute_time(float(_active_attack_data.get("hit_second", 0.0)))
	_set_animation_speed(0.0)


func set_attack_recover_progress(direction: Vector2, progress: float) -> void:
	if _is_dead or _jump_state_active:
		return

	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_update_facing(_last_direction)
	if _active_attack_data.is_empty():
		_active_attack_data = _select_attack_entry()

	var hit_second: float = float(_active_attack_data.get("hit_second", 0.0))
	var clip_length: float = float(_active_attack_data.get("length", hit_second))
	var target_time: float = lerpf(hit_second, clip_length, clampf(progress, 0.0, 1.0))
	_seek_attack_absolute_time(target_time)
	_set_animation_speed(0.0)


func stop_attack(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_attack_locked = false
	_attack_lock_remaining = 0.0
	_active_attack_phase_index = -1
	_active_attack_speed_scale = _profile_anim_speed
	_enter_locomotion_state(true)


func play_death() -> void:
	_is_dead = true
	_stun_enabled = false
	_attack_locked = false
	_attack_lock_remaining = 0.0
	if not _play_state_animation("death", true):
		_set_animation_speed(0.0)


func play_victory() -> void:
	if _is_dead or _stun_enabled:
		return
	if not _play_state_animation("victory", true):
		_play_state_animation("idle", true)


func play_hit() -> void:
	if _is_dead or _stun_enabled:
		return
	if _play_state_animation("hit", true):
		return
	_enter_locomotion_state(true)


func set_stunned(enabled: bool) -> void:
	if _is_dead:
		return
	_stun_enabled = enabled
	if _stun_enabled:
		if not _play_state_animation("stun", true):
			_play_state_animation("idle", true)
		return
	_enter_locomotion_state(true)


func play_spawn() -> void:
	if _is_dead:
		return
	if _play_state_animation("spawn", true):
		return
	_play_state_animation("idle", true)


func apply_selection_preview_preset() -> void:
	_ensure_runtime_nodes()
	_set_runtime_viewport_size(Vector2i(maxi(viewport_size.x, 320), maxi(viewport_size.y, 320)))
	if _display_sprite != null:
		_display_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	camera_fov = 44.0
	if _camera != null:
		_camera.fov = camera_fov
	key_light_energy = 1.2
	fill_light_energy = 0.92
	key_light_rotation = Vector3(-38.0, 8.0, 0.0)
	fill_light_rotation = Vector3(-18.0, -128.0, 0.0)
	enable_key_shadows = false
	_apply_lighting_preset()
	_fit_character_in_fixed_preview_frame()


func start_showcase() -> void:
	_showcase_enabled = true
	_selection_preview_victory_once_active = false
	if not _is_dead:
		_last_is_moving = false
		_play_state_animation("idle", true)


func play_selection_preview_intro() -> void:
	_showcase_enabled = true
	_last_is_moving = false
	_selection_preview_victory_once_active = false
	if _is_dead:
		return
	if _play_state_animation("victory", true):
		_selection_preview_victory_once_active = true
		return
	_play_state_animation("idle", true)


func stop_showcase() -> void:
	_showcase_enabled = false
	_selection_preview_victory_once_active = false


func set_showcase_spin_speed(speed: float) -> void:
	showcase_spin_speed = speed


func rotate_preview(delta_yaw: float) -> void:
	if _model_pivot == null:
		return
	_model_pivot.rotate_y(delta_yaw)


func start_jump(direction: Vector2) -> void:
	if _is_dead:
		return
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_update_facing(_last_direction)
	_last_is_moving = false
	_set_jump_state(true)
	_play_jump_phase(0)


func set_jump_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	_last_direction = direction.normalized()
	_update_facing(_last_direction)


func set_jump_phase(phase_index: int) -> void:
	if _is_dead:
		return
	_set_jump_state(true)
	_play_jump_phase(phase_index)


func stop_jump(direction: Vector2, is_moving: bool) -> void:
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_set_jump_state(false)
	_jump_phase_index = -1
	_last_is_moving = is_moving
	_update_facing(_last_direction)
	_enter_locomotion_state(true)


func reset_runtime_state(default_direction: Vector2 = Vector2.DOWN, force_idle: bool = true) -> void:
	_is_dead = false
	_stun_enabled = false
	_attack_locked = false
	_attack_lock_remaining = 0.0
	_active_attack_data.clear()
	_active_attack_phase_index = -1
	_active_attack_speed_scale = _profile_anim_speed
	_active_state = ""
	_idle_random_cycle_elapsed = 0.0
	_selection_preview_victory_once_active = false
	_jump_height_offset = 0.0
	_jump_state_active = false
	_jump_phase_index = -1
	_apply_display_transform()

	if default_direction != Vector2.ZERO:
		_last_direction = default_direction.normalized()
	else:
		_last_direction = Vector2.DOWN
	_last_is_moving = false

	if _display_sprite != null:
		_display_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_display_sprite.scale = Vector2.ONE * display_scale

	_update_facing(_last_direction)
	if force_idle:
		_play_state_animation("idle", true)


func set_visual_height(offset_y: float) -> void:
	_jump_height_offset = offset_y
	_apply_display_transform()


func set_dissolve_progress(progress: float) -> void:
	if _display_sprite == null:
		return
	var clamped := clampf(progress, 0.0, 1.0)
	_display_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - clamped)
	var dissolve_scale := lerpf(1.0, 0.65, clamped)
	_display_sprite.scale = Vector2.ONE * display_scale * dissolve_scale


func _ensure_runtime_nodes() -> void:
	if _sub_viewport != null:
		return

	_sub_viewport = SubViewport.new()
	_sub_viewport.name = "Model3DViewport"
	_sub_viewport.size = viewport_size
	_sub_viewport.transparent_bg = true
	_sub_viewport.own_world_3d = true
	_sub_viewport.disable_3d = false
	_sub_viewport.msaa_3d = Viewport.MSAA_2X
	_sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_sub_viewport)

	_world_root = Node3D.new()
	_world_root.name = "WorldRoot"
	_sub_viewport.add_child(_world_root)

	_world_environment = WorldEnvironment.new()
	_world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.66, 0.69, 0.74, 1.0)
	environment.ambient_light_energy = 0.88
	_world_environment.environment = environment
	_world_root.add_child(_world_environment)

	_model_pivot = Node3D.new()
	_model_pivot.name = "ModelPivot"
	_world_root.add_child(_model_pivot)

	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.current = true
	_camera.fov = camera_fov
	_camera.near = 0.03
	_camera.far = 64.0
	_camera.position = Vector3(0.0, 1.15, 3.25)
	_camera.look_at_from_position(_camera.position, Vector3(0.0, 0.95, 0.0), Vector3.UP)
	_world_root.add_child(_camera)

	_key_light = DirectionalLight3D.new()
	_key_light.name = "KeyLight"
	_world_root.add_child(_key_light)

	_fill_light = DirectionalLight3D.new()
	_fill_light.name = "FillLight"
	_world_root.add_child(_fill_light)
	_apply_lighting_preset()

	_display_sprite = Sprite2D.new()
	_display_sprite.name = "Display"
	_display_sprite.centered = true
	_display_sprite.texture = _sub_viewport.get_texture()
	_display_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_display_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	add_child(_display_sprite)
	call_deferred("_apply_postprocess_material")


func _apply_display_transform() -> void:
	position = display_offset + Vector2(0.0, _jump_height_offset)
	if _display_sprite != null:
		_display_sprite.scale = Vector2.ONE * display_scale


func _set_runtime_viewport_size(new_size: Vector2i) -> void:
	if _sub_viewport == null:
		return
	var clamped_size := Vector2i(maxi(new_size.x, 64), maxi(new_size.y, 64))
	if _sub_viewport.size == clamped_size:
		return
	_sub_viewport.size = clamped_size
	if _display_sprite != null:
		_display_sprite.texture = _sub_viewport.get_texture()
	_apply_postprocess_material()


func _apply_lighting_preset() -> void:
	if _key_light != null:
		_key_light.light_energy = key_light_energy
		_key_light.rotation_degrees = key_light_rotation
		_key_light.shadow_enabled = enable_key_shadows
		_key_light.light_color = Color(1.0, 0.98, 0.95, 1.0)

	if _fill_light != null:
		_fill_light.light_energy = fill_light_energy
		_fill_light.rotation_degrees = fill_light_rotation
		_fill_light.shadow_enabled = false
		_fill_light.light_color = Color(0.86, 0.9, 1.0, 1.0)


func _apply_postprocess_material() -> void:
	if not is_inside_tree():
		return
	if _display_sprite == null:
		return
	if Model3DToonOutlineShader == null:
		if not _shader_missing_warning_emitted:
			_shader_missing_warning_emitted = true
			push_warning("Model3D toon shader missing: res://assets/shaders/model3d_toon_outline.gdshader")
		return

	var shader_material := _display_sprite.material as ShaderMaterial
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		_display_sprite.material = shader_material

	if shader_material.shader != Model3DToonOutlineShader:
		shader_material.shader = Model3DToonOutlineShader
	if shader_material.shader == null:
		return
	var source_texture: Texture2D = _display_sprite.texture
	if source_texture == null and _sub_viewport != null:
		source_texture = _sub_viewport.get_texture()
	if source_texture != null:
		shader_material.set_shader_parameter("source_tex", source_texture)
	var safe_viewport_size: Vector2 = Vector2(
		float(maxi(viewport_size.x, 1)),
		float(maxi(viewport_size.y, 1))
	)
	if _sub_viewport != null:
		safe_viewport_size = Vector2(
			float(maxi(_sub_viewport.size.x, 1)),
			float(maxi(_sub_viewport.size.y, 1))
		)
	shader_material.set_shader_parameter("source_pixel_size", Vector2(1.0 / safe_viewport_size.x, 1.0 / safe_viewport_size.y))
	shader_material.set_shader_parameter("enable_toon", enable_toon_shading)
	shader_material.set_shader_parameter("toon_steps", maxf(toon_steps, 1.0))
	shader_material.set_shader_parameter("enable_outline", enable_outline)
	shader_material.set_shader_parameter("outline_color", outline_color)
	shader_material.set_shader_parameter("outline_size", maxf(outline_size, 0.0))
	shader_material.set_shader_parameter("enable_pixelate", enable_pixelate_sampling)
	shader_material.set_shader_parameter("pixel_size", maxf(pixel_size, 1.0))


func set_runtime_active(enabled: bool) -> void:
	if _sub_viewport == null:
		return
	if enabled:
		_sub_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	else:
		_sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _rebuild_character_from_profile() -> void:
	_clear_model_pivot_children()
	_character_root = null
	_animation_player = null
	_skeleton = null
	_attack_entries.clear()
	_attack_cursor = 0
	_active_attack_data.clear()
	_active_attack_phase_index = -1
	_active_attack_speed_scale = _profile_anim_speed
	_state_animation_specs.clear()
	_state_sequence_cursor.clear()
	_state_last_clip.clear()
	_state_active_sequence_group.clear()
	_state_last_sequence_group.clear()
	_current_animation = ""
	_active_state = ""
	_idle_random_cycle_elapsed = 0.0
	_selection_preview_victory_once_active = false
	_is_dead = false
	_stun_enabled = false
	_attack_locked = false
	_attack_lock_remaining = 0.0
	_jump_height_offset = 0.0
	_jump_state_clips = PackedStringArray()
	_jump_state_active = false
	_jump_phase_index = -1
	_apply_display_transform()
	_state_animation_overrides = Model3DActionCatalogScript.get_profile_actions(_profile_id)

	var character_path := String(_profile.get("character_path", "")).strip_edges()
	if character_path.is_empty():
		push_warning("Model3D profile missing character_path: %s" % String(_profile_id))
		return
	if not ResourceLoader.exists(character_path):
		push_warning("Model3D character path not found: %s" % character_path)
		return

	var packed := load(character_path) as PackedScene
	if packed == null:
		push_warning("Model3D character scene invalid: %s" % character_path)
		return

	var instance := packed.instantiate()
	var node3d := _coerce_to_node3d(instance)
	if node3d == null:
		push_warning("Model3D character root must include Node3D: %s" % character_path)
		return

	_character_root = node3d
	_model_pivot.add_child(_character_root)

	var visual_scale := maxf(float(_profile.get("scale", 1.0)), 0.01)
	_character_root.scale = Vector3.ONE * visual_scale

	_animation_player = _find_animation_player(_character_root)
	_skeleton = _find_first_skeleton(_character_root)
	_profile_anim_speed = maxf(float(_profile.get("speed", 1.0)), 0.01)
	_setup_runtime_animation_player()
	if _animation_player == null or _animation_player.get_animation_list().is_empty():
		push_warning("Model3D animator has no playable animations for profile_id=%s character_path=%s" % [
			String(_profile_id),
			String(_profile.get("character_path", "")),
		])

	_apply_profile_style_colors()
	_attach_weapons_from_profile()
	_apply_mesh_render_preset()
	_prepare_animation_cache()
	_attack_entries = _build_attack_entries(_profile)
	if _attack_entries.is_empty() and not _default_attack_animation.is_empty():
		_attack_entries.append({
			"animation_name": _default_attack_animation,
			"release_animation_name": _default_attack_animation,
			"phase_animation_names": PackedStringArray([_default_attack_animation]),
			"phase_lengths": PackedFloat32Array([maxf(_get_animation_length(_default_attack_animation), 0.1)]),
			"release_phase_index": 0,
			"release_hit_second": 0.08,
			"hit_second": 0.08,
		})

	_fit_character_in_view()
	_play_state_animation("idle", true)
	_update_facing(_last_direction)


func _clear_model_pivot_children() -> void:
	if _model_pivot == null:
		return
	for child in _model_pivot.get_children():
		_model_pivot.remove_child(child)
		child.queue_free()


func _attach_weapons_from_profile() -> void:
	if _character_root == null:
		return

	var right_weapon_path := String(_profile.get("right_weapon_path", _profile.get("weapon_path", ""))).strip_edges()
	var left_weapon_path := String(_profile.get("left_weapon_path", "")).strip_edges()

	_attach_weapon_to_character(
		right_weapon_path,
		false,
		Vector3(
			float(_profile.get("weapon_tune_pos_x", 0.0)),
			float(_profile.get("weapon_tune_pos_y", 0.0)),
			float(_profile.get("weapon_tune_pos_z", 0.0))
		),
		Vector3(
			float(_profile.get("weapon_tune_rot_x", 0.0)),
			float(_profile.get("weapon_tune_rot_y", 0.0)),
			float(_profile.get("weapon_tune_rot_z", 0.0))
		)
	)
	_attach_weapon_to_character(
		left_weapon_path,
		true,
		Vector3(
			float(_profile.get("left_weapon_tune_pos_x", 0.0)),
			float(_profile.get("left_weapon_tune_pos_y", 0.0)),
			float(_profile.get("left_weapon_tune_pos_z", 0.0))
		),
		Vector3(
			float(_profile.get("left_weapon_tune_rot_x", 0.0)),
			float(_profile.get("left_weapon_tune_rot_y", 0.0)),
			float(_profile.get("left_weapon_tune_rot_z", 0.0))
		)
	)


func _attach_weapon_to_character(path: String, prefer_left_hand: bool, tune_pos: Vector3, tune_rot: Vector3) -> void:
	if path.is_empty():
		return
	if not ResourceLoader.exists(path):
		push_warning("Model3D weapon path not found: %s" % path)
		return

	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Model3D weapon scene invalid: %s" % path)
		return

	var instance := packed.instantiate()
	if instance is not Node3D:
		push_warning("Model3D weapon root must inherit Node3D: %s" % path)
		instance.queue_free()
		return

	var weapon_root := instance as Node3D
	weapon_root.set_meta("exclude_preview_bounds", true)
	var mounted := false
	if _skeleton != null:
		var hand_bone := _find_hand_bone_name(_skeleton, prefer_left_hand)
		if not hand_bone.is_empty():
			var attach := BoneAttachment3D.new()
			attach.name = "WeaponSocket_%s" % ("L" if prefer_left_hand else "R")
			attach.bone_name = hand_bone
			attach.set_meta("exclude_preview_bounds", true)
			_skeleton.add_child(attach)
			attach.add_child(weapon_root)
			mounted = true

	if not mounted:
		_character_root.add_child(weapon_root)

	weapon_root.position = tune_pos
	weapon_root.rotation_degrees = tune_rot


func _prepare_animation_cache() -> void:
	_state_animation_specs["idle"] = _build_state_animation_spec("idle", [["idle"], ["standing"], ["stand"], ["breath"]], false)
	_state_animation_specs["move"] = _build_state_animation_spec("move", [["running"], ["walking"], ["run"], ["walk"]], false)
	_state_animation_specs["hit"] = _build_state_animation_spec("hit", [["hit"], ["hurt"], ["damage"]], false)
	_state_animation_specs["stun"] = _build_state_animation_spec("stun", [["stun"], ["dizzy"], ["frozen"]], false)
	_state_animation_specs["death"] = _build_state_animation_spec("death", [["death"], ["die"], ["inactive"], ["floor"]], true)
	_state_animation_specs["jump"] = _build_state_animation_spec("jump", [["jump"], ["leap"], ["air"]], true)
	_state_animation_specs["spawn"] = _build_state_animation_spec("spawn", [["spawn"], ["awaken"], ["appear"]], false)
	_state_animation_specs["victory"] = _build_state_animation_spec("victory", [["cheer"], ["taunt"], ["victory"]], false)

	_idle_animation = _first_clip_name(_state_animation_specs.get("idle", {}))
	_run_animation = _first_clip_name(_state_animation_specs.get("move", {}))
	_hit_animation = _first_clip_name(_state_animation_specs.get("hit", {}))
	_stun_animation = _first_clip_name(_state_animation_specs.get("stun", {}))
	_death_animation = _first_clip_name(_state_animation_specs.get("death", {}))
	_jump_animation = _first_clip_name(_state_animation_specs.get("jump", {}))
	_spawn_animation = _first_clip_name(_state_animation_specs.get("spawn", {}))
	_victory_animation = _first_clip_name(_state_animation_specs.get("victory", {}))
	if _jump_animation.is_empty():
		_jump_animation = _pick_animation_name([["jump"], ["dodge"]])
	_jump_state_clips = _extract_jump_state_clips()
	_default_attack_animation = _pick_animation_name([
		["attack"],
		["shoot"],
		["cast"],
		["throw"],
		["stab"],
		["slice"],
	])


func _build_state_animation_spec(state_key: String, fallback_keywords: Array, prefer_sequence: bool) -> Dictionary:
	var configured_variant: Variant = _state_animation_overrides.get(state_key, null)
	var configured_spec: Dictionary = _coerce_override_to_state_spec(state_key, configured_variant, prefer_sequence)
	if not configured_spec.is_empty():
		return configured_spec

	var fallback_name: String = _pick_animation_name(fallback_keywords)
	if fallback_name.is_empty():
		return {}
	return {
		"mode": "single",
		"clips": PackedStringArray([fallback_name]),
	}


func _coerce_override_to_state_spec(state_key: String, raw_override: Variant, prefer_sequence: bool) -> Dictionary:
	if raw_override == null:
		return {}

	if raw_override is String:
		var raw_text: String = String(raw_override).strip_edges()
		if raw_text.is_empty():
			return {}
		return _parse_state_animation_spec(state_key, raw_text, prefer_sequence)

	if raw_override is Dictionary:
		var override_dict: Dictionary = raw_override as Dictionary
		var mode: String = String(override_dict.get("mode", "")).strip_edges().to_lower()
		if mode == "random_sequence":
			var sequences: Array[PackedStringArray] = _coerce_sequences_from_override(state_key, override_dict.get("sequences", []))
			return _build_random_sequence_spec(sequences)

		var clips: PackedStringArray = _coerce_clip_list_from_override(state_key, override_dict.get("clips", []))
		if clips.is_empty():
			var fallback_text: String = String(override_dict.get("text", "")).strip_edges()
			if fallback_text.is_empty():
				return {}
			return _parse_state_animation_spec(state_key, fallback_text, prefer_sequence)

		if mode != "single" and mode != "random" and mode != "sequence":
			if clips.size() <= 1:
				mode = "single"
			else:
				mode = "sequence" if prefer_sequence else "random"
		if clips.size() <= 1 and mode != "sequence":
			mode = "single"
		return {
			"mode": mode,
			"clips": clips,
		}

	if raw_override is Array or raw_override is PackedStringArray:
		var override_clips: PackedStringArray = _coerce_clip_list_from_override(state_key, raw_override)
		if override_clips.is_empty():
			return {}
		var override_mode: String = "single" if override_clips.size() <= 1 else ("sequence" if prefer_sequence else "random")
		return {
			"mode": override_mode,
			"clips": override_clips,
		}

	var coerced_text: String = String(raw_override).strip_edges()
	if coerced_text.is_empty():
		return {}
	return _parse_state_animation_spec(state_key, coerced_text, prefer_sequence)


func _coerce_sequences_from_override(state_key: String, raw_value: Variant) -> Array[PackedStringArray]:
	var sequences: Array[PackedStringArray] = []
	if raw_value is Array:
		var raw_array: Array = raw_value as Array
		for raw_sequence in raw_array:
			var clips: PackedStringArray = _coerce_clip_list_from_override(state_key, raw_sequence)
			if not clips.is_empty():
				sequences.append(clips)
		return sequences

	if raw_value is PackedStringArray:
		var direct_sequence: PackedStringArray = _coerce_clip_list_from_override(state_key, raw_value)
		if not direct_sequence.is_empty():
			sequences.append(direct_sequence)
		return sequences

	if raw_value is String:
		var raw_text: String = String(raw_value).strip_edges()
		if raw_text.is_empty():
			return sequences
		var normalized_text: String = raw_text.replace("->", ">").replace("=>", ">")
		var group_texts: Array[String] = _split_tokens(normalized_text, "|")
		for group_text in group_texts:
			var group_tokens: Array[String] = []
			if group_text.contains(">"):
				group_tokens = _split_tokens(group_text, ">")
			else:
				group_tokens = _split_state_tokens(group_text)
			var group_clips: PackedStringArray = _collect_valid_clips(state_key, group_tokens)
			if not group_clips.is_empty():
				sequences.append(group_clips)
		return sequences

	return sequences


func _coerce_clip_list_from_override(state_key: String, raw_value: Variant) -> PackedStringArray:
	var tokens: Array[String] = []
	if raw_value is PackedStringArray:
		var packed_tokens: PackedStringArray = raw_value as PackedStringArray
		for raw_token in packed_tokens:
			var token: String = String(raw_token).strip_edges()
			if token.is_empty():
				continue
			tokens.append(token)
	elif raw_value is Array:
		var raw_array: Array = raw_value as Array
		for raw_token in raw_array:
			var token: String = String(raw_token).strip_edges()
			if token.is_empty():
				continue
			tokens.append(token)
	elif raw_value is String:
		var raw_text: String = String(raw_value).strip_edges()
		if raw_text.contains(">"):
			tokens = _split_tokens(raw_text, ">")
		else:
			tokens = _split_state_tokens(raw_text)
	else:
		var coerced_text: String = String(raw_value).strip_edges()
		if not coerced_text.is_empty():
			tokens.append(coerced_text)

	return _collect_valid_clips(state_key, tokens)


func _parse_state_animation_spec(state_key: String, raw_text: String, prefer_sequence: bool) -> Dictionary:
	var normalized_text: String = raw_text.replace("->", ">").replace("=>", ">")
	if normalized_text.is_empty():
		return {}

	var group_texts: Array[String] = _split_tokens(normalized_text, "|")
	if group_texts.size() > 1:
		var sequences: Array[PackedStringArray] = []
		for group_text in group_texts:
			var chain_tokens: Array[String] = []
			if group_text.contains(">"):
				chain_tokens = _split_tokens(group_text, ">")
			else:
				chain_tokens = _split_state_tokens(group_text)
			var valid_group: PackedStringArray = _collect_valid_clips(state_key, chain_tokens)
			if not valid_group.is_empty():
				sequences.append(valid_group)
		return _build_random_sequence_spec(sequences)

	var mode: String = "single"
	var tokens: Array[String] = []
	if normalized_text.contains(">"):
		mode = "sequence"
		tokens = _split_tokens(normalized_text, ">")
	else:
		tokens = _split_state_tokens(normalized_text)
		if tokens.size() > 1:
			mode = "sequence" if prefer_sequence else "random"

	var valid_clips: PackedStringArray = _collect_valid_clips(state_key, tokens)
	if valid_clips.is_empty():
		return {}
	if valid_clips.size() <= 1 and mode != "sequence":
		mode = "single"
	return {
		"mode": mode,
		"clips": valid_clips,
	}


func _build_random_sequence_spec(sequences: Array[PackedStringArray]) -> Dictionary:
	if sequences.is_empty():
		return {}
	if sequences.size() == 1:
		var only_sequence: PackedStringArray = sequences[0]
		if only_sequence.size() <= 1:
			return {
				"mode": "single",
				"clips": only_sequence,
			}
		return {
			"mode": "sequence",
			"clips": only_sequence,
		}
	return {
		"mode": "random_sequence",
		"sequences": sequences,
	}


func _collect_valid_clips(state_key: String, tokens: Array[String]) -> PackedStringArray:
	var valid_clips: PackedStringArray = PackedStringArray()
	for token in tokens:
		var requested_name: String = token.strip_edges()
		if requested_name.is_empty():
			continue
		var resolved_name: String = _resolve_animation_name(requested_name)
		if not resolved_name.is_empty():
			valid_clips.append(resolved_name)
		else:
			push_warning("Model3D action missing for profile_id=%s state=%s animation=%s" % [
				String(_profile_id),
				state_key,
				requested_name,
			])
	return valid_clips


func _split_state_tokens(text: String) -> Array[String]:
	var normalized: String = text
	normalized = normalized.replace(";", ",")
	normalized = normalized.replace("|", ",")
	normalized = normalized.replace("/", ",")
	normalized = normalized.replace("\\", ",")
	normalized = normalized.replace("+", ",")
	normalized = normalized.replace("&", ",")

	var tokens: Array[String] = _split_tokens(normalized, ",")
	if tokens.size() <= 1 and normalized.contains(" "):
		var by_space: Array[String] = _split_tokens(normalized, " ")
		if by_space.size() > 1:
			return by_space
	return tokens


func _split_tokens(text: String, delimiter: String) -> Array[String]:
	var raw_parts: PackedStringArray = text.split(delimiter, false)
	var result: Array[String] = []
	for raw_part in raw_parts:
		var token: String = String(raw_part).strip_edges()
		if token.is_empty():
			continue
		result.append(token)
	return result


func _first_clip_name(spec_value: Variant) -> String:
	if spec_value is not Dictionary:
		return ""
	var spec: Dictionary = spec_value as Dictionary
	var mode: String = String(spec.get("mode", "single")).to_lower()
	if mode == "random_sequence":
		var raw_sequences: Variant = spec.get("sequences", [])
		if raw_sequences is Array:
			var sequences: Array = raw_sequences as Array
			if not sequences.is_empty():
				var first_sequence: Variant = sequences[0]
				if first_sequence is PackedStringArray:
					var sequence_clips: PackedStringArray = first_sequence as PackedStringArray
					if not sequence_clips.is_empty():
						return String(sequence_clips[0])
				if first_sequence is Array:
					var sequence_array: Array = first_sequence as Array
					if not sequence_array.is_empty():
						return String(sequence_array[0])
		return ""

	var raw_clips: Variant = spec.get("clips", PackedStringArray())
	if raw_clips is PackedStringArray:
		var clips: PackedStringArray = raw_clips as PackedStringArray
		if not clips.is_empty():
			return String(clips[0])
	elif raw_clips is Array:
		var clip_array: Array = raw_clips as Array
		if not clip_array.is_empty():
			return String(clip_array[0])
	return ""

func _build_attack_entries(profile: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var raw_plan: Variant = profile.get("attack_plan", [])
	if raw_plan is Array:
		for raw_entry in raw_plan:
			if raw_entry is not Dictionary:
				continue
			var entry := raw_entry as Dictionary
			var release_raw_name: String = String(entry.get("release_animation_name", entry.get("animation_name", ""))).strip_edges()
			var release_name: String = _resolve_animation_name(release_raw_name)
			if release_name.is_empty():
				_warn_missing_attack_animation(release_raw_name)
				continue
			var windup_raw_name: String = String(entry.get("windup_animation_name", "")).strip_edges()
			var recover_raw_name: String = String(entry.get("recover_animation_name", "")).strip_edges()
			var windup_name: String = _resolve_animation_name(windup_raw_name)
			var recover_name: String = _resolve_animation_name(recover_raw_name)
			if not windup_raw_name.is_empty() and windup_name.is_empty():
				_warn_missing_attack_animation(windup_raw_name)
			if not recover_raw_name.is_empty() and recover_name.is_empty():
				_warn_missing_attack_animation(recover_raw_name)

			var phase_names: PackedStringArray = PackedStringArray()
			var phase_lengths: PackedFloat32Array = PackedFloat32Array()
			var release_phase_index := 0
			var windup_length := 0.0
			var total_length := 0.0

			if not windup_name.is_empty():
				var windup_length_value: float = maxf(_get_animation_length(windup_name), 0.1)
				phase_names.append(windup_name)
				phase_lengths.append(windup_length_value)
				windup_length += windup_length_value
				total_length += windup_length_value

			release_phase_index = phase_names.size()
			var release_length: float = maxf(_get_animation_length(release_name), 0.1)
			phase_names.append(release_name)
			phase_lengths.append(release_length)
			total_length += release_length

			if not recover_name.is_empty():
				var recover_length: float = maxf(_get_animation_length(recover_name), 0.1)
				phase_names.append(recover_name)
				phase_lengths.append(recover_length)
				total_length += recover_length

			var release_hit_second: float = clampf(_extract_hit_second(entry, release_length), 0.0, release_length)
			var hit_second: float = clampf(windup_length + release_hit_second, 0.0, maxf(total_length, 0.1))
			entries.append({
				"animation_name": release_name,
				"release_animation_name": release_name,
				"windup_animation_name": windup_name,
				"recover_animation_name": recover_name,
				"phase_animation_names": phase_names,
				"phase_lengths": phase_lengths,
				"release_phase_index": release_phase_index,
				"release_hit_second": release_hit_second,
				"length": maxf(total_length, 0.1),
				"hit_second": hit_second,
			})

	if entries.is_empty():
		var fallback_raw_name: String = String(profile.get("animation_name", "")).strip_edges()
		var fallback_animation_name: String = _resolve_animation_name(fallback_raw_name)
		if not fallback_animation_name.is_empty():
			var fallback_length: float = maxf(_get_animation_length(fallback_animation_name), 0.1)
			entries.append({
				"animation_name": fallback_animation_name,
				"release_animation_name": fallback_animation_name,
				"phase_animation_names": PackedStringArray([fallback_animation_name]),
				"phase_lengths": PackedFloat32Array([fallback_length]),
				"release_phase_index": 0,
				"release_hit_second": minf(0.1, fallback_length),
				"length": fallback_length,
				"hit_second": minf(0.1, fallback_length),
			})
	return entries


func _extract_hit_second(entry: Dictionary, fallback_length: float = 0.0) -> float:
	var raw_hit_seconds: Variant = entry.get("hit_seconds", [])
	if raw_hit_seconds is Array:
		var hit_seconds := raw_hit_seconds as Array
		if not hit_seconds.is_empty():
			return maxf(float(hit_seconds[0]), 0.0)

	var raw_hit_frames: Variant = entry.get("hit_frames", [])
	if raw_hit_frames is Array:
		var hit_frames := raw_hit_frames as Array
		if not hit_frames.is_empty():
			var fps := maxf(float(entry.get("fps", 30.0)), 1.0)
			return maxf(float(hit_frames[0]) / fps, 0.0)

	return minf(0.1, maxf(fallback_length, 0.1))


func _select_attack_entry() -> Dictionary:
	var selected: Dictionary = {}
	if not _attack_entries.is_empty():
		for attempt in _attack_entries.size():
			var index := (_attack_cursor + attempt) % _attack_entries.size()
			var candidate: Dictionary = _attack_entries[index]
			var candidate_phase_names: PackedStringArray = _extract_phase_animation_names(candidate)
			if candidate_phase_names.is_empty():
				var candidate_animation: String = String(candidate.get("release_animation_name", candidate.get("animation_name", ""))).strip_edges()
				_warn_missing_attack_animation(candidate_animation)
				continue
			var release_index: int = clampi(int(candidate.get("release_phase_index", 0)), 0, candidate_phase_names.size() - 1)
			var release_animation_name: String = String(candidate_phase_names[release_index]).strip_edges()
			if release_animation_name.is_empty() or not _has_animation(release_animation_name):
				_warn_missing_attack_animation(release_animation_name)
				continue
			selected = candidate.duplicate(true)
			_attack_cursor = index + 1
			break

	if selected.is_empty():
		selected = {
			"animation_name": _default_attack_animation,
			"hit_second": 0.1,
		}

	var phase_animation_names: PackedStringArray = _extract_phase_animation_names(selected)
	if phase_animation_names.is_empty():
		var fallback_release_name: String = _resolve_animation_name(String(selected.get("release_animation_name", selected.get("animation_name", ""))).strip_edges())
		if not fallback_release_name.is_empty():
			phase_animation_names.append(fallback_release_name)
	var release_phase_index: int = 0
	if not phase_animation_names.is_empty():
		release_phase_index = clampi(int(selected.get("release_phase_index", 0)), 0, phase_animation_names.size() - 1)
	var phase_lengths: PackedFloat32Array = _extract_phase_lengths(selected, phase_animation_names)

	var windup_length := 0.0
	var total_length := 0.0
	for i in range(phase_lengths.size()):
		var phase_length_value: float = maxf(float(phase_lengths[i]), 0.1)
		total_length += phase_length_value
		if i < release_phase_index:
			windup_length += phase_length_value
	var release_length: float = 0.1
	if release_phase_index >= 0 and release_phase_index < phase_lengths.size():
		release_length = maxf(float(phase_lengths[release_phase_index]), 0.1)

	var release_hit_second: float = clampf(float(selected.get("release_hit_second", _extract_hit_second(selected, release_length))), 0.0, release_length)
	var hit_second: float = clampf(float(selected.get("hit_second", windup_length + release_hit_second)), 0.0, maxf(total_length, 0.1))

	var release_animation_name: String = ""
	if not phase_animation_names.is_empty() and release_phase_index >= 0 and release_phase_index < phase_animation_names.size():
		release_animation_name = String(phase_animation_names[release_phase_index]).strip_edges()
	selected["animation_name"] = release_animation_name
	selected["release_animation_name"] = release_animation_name
	selected["phase_animation_names"] = phase_animation_names
	selected["phase_lengths"] = phase_lengths
	selected["release_phase_index"] = release_phase_index
	selected["release_hit_second"] = release_hit_second
	selected["length"] = maxf(total_length, 0.1)
	selected["hit_second"] = hit_second
	return selected


func _extract_phase_animation_names(entry: Dictionary) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var raw_phase_names: Variant = entry.get("phase_animation_names", PackedStringArray())
	if raw_phase_names is PackedStringArray:
		var packed_names: PackedStringArray = raw_phase_names as PackedStringArray
		for raw_name in packed_names:
			var resolved_name: String = _resolve_animation_name(String(raw_name).strip_edges())
			if resolved_name.is_empty():
				continue
			result.append(resolved_name)
	elif raw_phase_names is Array:
		var names_array: Array = raw_phase_names as Array
		for raw_name in names_array:
			var resolved_name: String = _resolve_animation_name(String(raw_name).strip_edges())
			if resolved_name.is_empty():
				continue
			result.append(resolved_name)

	if result.is_empty():
		var windup_name: String = _resolve_animation_name(String(entry.get("windup_animation_name", "")).strip_edges())
		var release_name: String = _resolve_animation_name(String(entry.get("release_animation_name", entry.get("animation_name", ""))).strip_edges())
		var recover_name: String = _resolve_animation_name(String(entry.get("recover_animation_name", "")).strip_edges())
		if not windup_name.is_empty():
			result.append(windup_name)
		if not release_name.is_empty():
			result.append(release_name)
		if not recover_name.is_empty():
			result.append(recover_name)
	return result


func _extract_phase_lengths(entry: Dictionary, phase_animation_names: PackedStringArray) -> PackedFloat32Array:
	var phase_lengths: PackedFloat32Array = PackedFloat32Array()
	var raw_lengths: Variant = entry.get("phase_lengths", PackedFloat32Array())
	if raw_lengths is PackedFloat32Array:
		var packed_lengths: PackedFloat32Array = raw_lengths as PackedFloat32Array
		for raw_length in packed_lengths:
			phase_lengths.append(maxf(float(raw_length), 0.1))
	elif raw_lengths is Array:
		var lengths_array: Array = raw_lengths as Array
		for raw_length in lengths_array:
			phase_lengths.append(maxf(float(raw_length), 0.1))

	if phase_lengths.size() != phase_animation_names.size():
		phase_lengths = PackedFloat32Array()
		for phase_name in phase_animation_names:
			phase_lengths.append(maxf(_get_animation_length(String(phase_name)), 0.1))
	return phase_lengths


func _warn_missing_attack_animation(animation_name: String) -> void:
	var profile_key: String = String(_profile.get("profile_id", _profile_id)).strip_edges()
	if profile_key.is_empty():
		profile_key = "<unknown>"
	var anim_key: String = animation_name.strip_edges()
	if anim_key.is_empty():
		anim_key = "<empty>"
	var warning_key: String = "%s::%s" % [profile_key, anim_key]
	if _missing_attack_animation_warnings.has(warning_key):
		return
	_missing_attack_animation_warnings[warning_key] = true
	push_warning("Model3D attack animation missing for profile_id=%s animation=%s" % [profile_key, anim_key])


func _build_attack_timing_payload(attack_duration: float, started: bool) -> Dictionary:
	if _active_attack_data.is_empty():
		return {
			"started": started,
			"hit_ratio": 0.5,
			"hit_second": 0.0,
			"clip_length": 0.0,
			"attack_duration": maxf(attack_duration, 0.0),
		}

	var clip_length: float = maxf(float(_active_attack_data.get("length", 0.0)), 0.01)
	var hit_second: float = clampf(float(_active_attack_data.get("hit_second", 0.0)), 0.0, clip_length)
	var hit_ratio: float = clampf(hit_second / clip_length, 0.0, 1.0)
	return {
		"started": started,
		"hit_ratio": hit_ratio,
		"hit_second": hit_second,
		"clip_length": clip_length,
		"attack_duration": maxf(attack_duration, 0.0),
	}


func _play_attack_phase_by_index(phase_index: int, speed_scale: float) -> bool:
	if _active_attack_data.is_empty():
		return false
	var phase_names: PackedStringArray = _extract_phase_animation_names(_active_attack_data)
	if phase_names.is_empty():
		return false
	if phase_index < 0 or phase_index >= phase_names.size():
		return false
	var target_index: int = phase_index
	var phase_animation_name: String = String(phase_names[target_index]).strip_edges()
	if phase_animation_name.is_empty():
		return false
	if not _play_animation(phase_animation_name, speed_scale, true):
		return false
	_active_attack_phase_index = target_index
	return true


func _seek_attack_absolute_time(target_time: float) -> void:
	if _active_attack_data.is_empty():
		return
	var phase_names: PackedStringArray = _extract_phase_animation_names(_active_attack_data)
	if phase_names.is_empty():
		return
	var phase_lengths: PackedFloat32Array = _extract_phase_lengths(_active_attack_data, phase_names)
	if phase_lengths.is_empty():
		return

	var total_length: float = 0.0
	for phase_length in phase_lengths:
		total_length += maxf(float(phase_length), 0.1)
	var clamped_time: float = clampf(target_time, 0.0, maxf(total_length, 0.0))

	var selected_phase_index: int = phase_lengths.size() - 1
	var selected_phase_local_time: float = maxf(float(phase_lengths[selected_phase_index]), 0.1)
	var cursor := 0.0
	for i in range(phase_lengths.size()):
		var phase_length_value: float = maxf(float(phase_lengths[i]), 0.1)
		var phase_end_time: float = cursor + phase_length_value
		if clamped_time <= phase_end_time or i == phase_lengths.size() - 1:
			selected_phase_index = i
			selected_phase_local_time = clampf(clamped_time - cursor, 0.0, phase_length_value)
			break
		cursor = phase_end_time

	if _active_attack_phase_index != selected_phase_index:
		if not _play_attack_phase_by_index(selected_phase_index, _profile_anim_speed):
			return
		_active_state = "attack"
	_set_animation_time(selected_phase_local_time)


func _update_facing(direction: Vector2) -> void:
	if _model_pivot == null:
		return
	if direction == Vector2.ZERO:
		return
	var safe_direction := direction.normalized()
	var yaw := atan2(safe_direction.x, safe_direction.y)
	_model_pivot.rotation.y = yaw


func _play_animation(animation_name: String, speed_scale: float, restart: bool) -> bool:
	if _animation_player == null:
		return false
	var resolved_name: String = _resolve_animation_name(animation_name)
	if resolved_name.is_empty():
		return false
	if not restart and _current_animation == resolved_name:
		_set_animation_speed(speed_scale)
		return true

	_animation_player.speed_scale = speed_scale
	_animation_player.play(resolved_name)
	_current_animation = resolved_name
	return true


func _bind_animation_player_events() -> void:
	if _animation_player == null:
		return
	if not _animation_player.animation_finished.is_connected(_on_animation_finished):
		_animation_player.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(_animation_name: StringName) -> void:
	if _active_state.is_empty():
		return
	if _active_state == "attack" and _attack_locked:
		var next_phase_index: int = _active_attack_phase_index + 1
		if _play_attack_phase_by_index(next_phase_index, _active_attack_speed_scale):
			return
		return
	if _attack_locked:
		return

	if _active_state == "death":
		_play_state_animation("death", true)
		return

	if _is_dead:
		return

	if _stun_enabled:
		_play_state_animation("stun", true)
		return

	match _active_state:
		"spawn", "hit":
			_enter_locomotion_state(true)
		"jump":
			if _jump_state_active:
				_set_animation_speed(0.0)
			else:
				_enter_locomotion_state(true)
		"idle":
			if not _last_is_moving:
				_play_state_animation("idle", true)
		"move":
			if _last_is_moving:
				_play_state_animation("move", true)
			else:
				_play_state_animation("idle", true)
		"stun":
			_play_state_animation("stun", true)
		"victory":
			if _selection_preview_victory_once_active:
				_selection_preview_victory_once_active = false
				_play_state_animation("idle", true)
			else:
				_play_state_animation("victory", true)


func _set_jump_state(enabled: bool) -> void:
	_jump_state_active = enabled
	if enabled:
		_attack_locked = false
		_attack_lock_remaining = 0.0
		_active_attack_phase_index = -1
		_active_attack_speed_scale = _profile_anim_speed


func _play_jump_phase(phase_index: int) -> void:
	if _animation_player == null:
		return
	var resolved_phase: int = maxi(phase_index, 0)
	_jump_phase_index = resolved_phase

	if _jump_state_clips.is_empty():
		if not _jump_animation.is_empty():
			if _play_animation(_jump_animation, _profile_anim_speed, true):
				_active_state = "jump"
		elif _play_state_animation("jump", true):
			_active_state = "jump"
		return

	var clip_index: int = mini(resolved_phase, _jump_state_clips.size() - 1)
	var clip_name: String = String(_jump_state_clips[clip_index]).strip_edges()
	if clip_name.is_empty():
		return
	if _play_animation(clip_name, _profile_anim_speed, true):
		_active_state = "jump"
		_idle_random_cycle_elapsed = 0.0


func _extract_jump_state_clips() -> PackedStringArray:
	var spec_variant: Variant = _state_animation_specs.get("jump", {})
	if spec_variant is not Dictionary:
		return PackedStringArray()
	var spec: Dictionary = spec_variant as Dictionary
	var mode: String = String(spec.get("mode", "single")).to_lower()
	if mode == "random_sequence":
		var raw_sequences: Variant = spec.get("sequences", [])
		if raw_sequences is Array:
			var sequences: Array = raw_sequences as Array
			if not sequences.is_empty():
				return _coerce_sequence_clips(sequences[0])
		return PackedStringArray()
	return _coerce_sequence_clips(spec.get("clips", PackedStringArray()))


func _enter_locomotion_state(force_restart: bool) -> void:
	if _last_is_moving and _play_state_animation("move", force_restart):
		return
	_play_state_animation("idle", force_restart)


func _play_state_animation(state_key: String, force_restart: bool) -> bool:
	if _animation_player == null:
		return false

	if not force_restart and _active_state == state_key and _has_animation(_current_animation):
		_set_animation_speed(_profile_anim_speed)
		return true

	var spec_variant: Variant = _state_animation_specs.get(state_key, {})
	if spec_variant is not Dictionary:
		return false
	var spec: Dictionary = spec_variant as Dictionary
	var entering_state: bool = _active_state != state_key
	if entering_state:
		_state_sequence_cursor[state_key] = 0
		_state_active_sequence_group.erase(state_key)
	var clip_name := _pick_clip_for_state(state_key, spec)
	if clip_name.is_empty():
		return false

	var played := _play_animation(clip_name, _profile_anim_speed, true)
	if played:
		_active_state = state_key
		_idle_random_cycle_elapsed = 0.0
	return played


func _pick_clip_for_state(state_key: String, spec: Dictionary) -> String:
	var mode: String = String(spec.get("mode", "single")).to_lower()
	if mode == "random_sequence":
		var raw_sequences: Variant = spec.get("sequences", [])
		if raw_sequences is not Array:
			return ""
		var sequences: Array = raw_sequences as Array
		if sequences.is_empty():
			return ""

		var selected_group_index: int = _resolve_random_sequence_group_index(state_key, sequences.size())
		var raw_selected_sequence: Variant = sequences[selected_group_index]
		var selected_sequence: PackedStringArray = _coerce_sequence_clips(raw_selected_sequence)
		if selected_sequence.is_empty():
			return ""

		var cursor: int = int(_state_sequence_cursor.get(state_key, 0))
		var index: int
		if state_key == "death":
			index = mini(maxi(cursor, 0), selected_sequence.size() - 1)
			_state_sequence_cursor[state_key] = mini(index + 1, selected_sequence.size() - 1)
		else:
			index = posmod(cursor, selected_sequence.size())
			_state_sequence_cursor[state_key] = (index + 1) % selected_sequence.size()
		return String(selected_sequence[index])

	var clips: PackedStringArray = _coerce_sequence_clips(spec.get("clips", PackedStringArray()))
	if clips.is_empty():
		return ""

	if mode == "sequence":
		var cursor: int = int(_state_sequence_cursor.get(state_key, 0))
		var index: int
		if state_key == "death":
			index = mini(maxi(cursor, 0), clips.size() - 1)
			_state_sequence_cursor[state_key] = mini(index + 1, clips.size() - 1)
		else:
			index = posmod(cursor, clips.size())
			_state_sequence_cursor[state_key] = (index + 1) % clips.size()
		return String(clips[index])

	if mode == "random":
		if clips.size() == 1:
			return String(clips[0])

		var picked_index: int = randi_range(0, clips.size() - 1)
		var picked: String = String(clips[picked_index])
		var previous: String = String(_state_last_clip.get(state_key, ""))
		if picked == previous:
			for offset in range(clips.size()):
				var candidate: String = String(clips[(picked_index + offset) % clips.size()])
				if candidate != previous:
					picked = candidate
					break
		_state_last_clip[state_key] = picked
		return picked

	return String(clips[0])


func _coerce_sequence_clips(raw_sequence: Variant) -> PackedStringArray:
	var clips: PackedStringArray = PackedStringArray()
	if raw_sequence is PackedStringArray:
		clips = raw_sequence as PackedStringArray
	elif raw_sequence is Array:
		var raw_array: Array = raw_sequence as Array
		for raw_clip in raw_array:
			var clip_name: String = String(raw_clip).strip_edges()
			if clip_name.is_empty():
				continue
			clips.append(clip_name)
	return clips


func _resolve_random_sequence_group_index(state_key: String, group_count: int) -> int:
	var cached_index: int = int(_state_active_sequence_group.get(state_key, -1))
	if cached_index >= 0 and cached_index < group_count:
		return cached_index

	if group_count <= 1:
		_state_active_sequence_group[state_key] = 0
		_state_last_sequence_group[state_key] = 0
		return 0

	var picked_index: int = randi_range(0, group_count - 1)
	var previous_index: int = int(_state_last_sequence_group.get(state_key, -1))
	if picked_index == previous_index:
		picked_index = (picked_index + 1 + randi_range(0, group_count - 2)) % group_count
	_state_active_sequence_group[state_key] = picked_index
	_state_last_sequence_group[state_key] = picked_index
	return picked_index


func _set_animation_time(seconds: float) -> void:
	if _animation_player == null:
		return
	_animation_player.seek(maxf(seconds, 0.0), true)


func _set_animation_speed(speed_scale: float) -> void:
	if _animation_player == null:
		return
	_animation_player.speed_scale = speed_scale


func _has_animation(animation_name: String) -> bool:
	return not _resolve_animation_name(animation_name).is_empty()


func _get_animation_length(animation_name: String) -> float:
	var resolved_name: String = _resolve_animation_name(animation_name)
	if _animation_player == null or resolved_name.is_empty():
		return 0.0
	var animation: Animation = _animation_player.get_animation(resolved_name)
	if animation == null:
		return 0.0
	return maxf(animation.length, 0.0)


func _resolve_animation_name(animation_name: String) -> String:
	if _animation_player == null:
		return ""

	var requested_name: String = animation_name.strip_edges()
	if requested_name.is_empty():
		return ""
	if _animation_player.has_animation(requested_name):
		return requested_name

	var requested_lower: String = requested_name.to_lower()
	var requested_leaf: String = _extract_animation_leaf(requested_name)
	var requested_leaf_lower: String = requested_leaf.to_lower()
	var requested_key: String = _normalize_animation_key(requested_name)
	var requested_leaf_key: String = _normalize_animation_key(requested_leaf)
	for raw_name in _animation_player.get_animation_list():
		var candidate: String = String(raw_name)
		var candidate_lower: String = candidate.to_lower()
		if candidate_lower == requested_lower:
			return candidate
		var candidate_leaf: String = _extract_animation_leaf(candidate)
		var candidate_leaf_lower: String = candidate_leaf.to_lower()
		if candidate_leaf_lower == requested_lower or candidate_lower == requested_leaf_lower:
			return candidate
		var candidate_key: String = _normalize_animation_key(candidate)
		var candidate_leaf_key: String = _normalize_animation_key(candidate_leaf)
		if candidate_key == requested_key or candidate_leaf_key == requested_key:
			return candidate
		if not requested_leaf_key.is_empty() and (candidate_key == requested_leaf_key or candidate_leaf_key == requested_leaf_key):
			return candidate
		if not requested_lower.is_empty() and candidate_lower.contains(requested_lower):
			return candidate
		if not requested_leaf_lower.is_empty() and candidate_lower.contains(requested_leaf_lower):
			return candidate
		if not requested_key.is_empty() and candidate_key.contains(requested_key):
			return candidate

	return ""


func _extract_animation_leaf(animation_name: String) -> String:
	var leaf: String = animation_name.strip_edges()
	var separators: Array[String] = ["/", "\\", "|", ":"]
	for separator in separators:
		var parts: PackedStringArray = leaf.split(separator, false)
		if parts.size() > 1:
			leaf = String(parts[parts.size() - 1]).strip_edges()
	return leaf


func _normalize_animation_key(animation_name: String) -> String:
	var normalized: String = animation_name.strip_edges().to_lower()
	if normalized.is_empty():
		return ""
	normalized = normalized.replace(" ", "")
	normalized = normalized.replace("_", "")
	normalized = normalized.replace("-", "")
	normalized = normalized.replace(".", "")
	normalized = normalized.replace("(", "")
	normalized = normalized.replace(")", "")
	return normalized


func _pick_animation_name(keyword_groups: Array) -> String:
	if _animation_player == null:
		return ""
	var animation_names := _animation_player.get_animation_list()
	if animation_names.is_empty():
		return ""

	for raw_group in keyword_groups:
		if raw_group is not Array:
			continue
		var group := raw_group as Array
		for raw_name in animation_names:
			var animation_name := String(raw_name)
			var lowered := animation_name.to_lower()
			var matched := true
			for raw_token in group:
				var token := String(raw_token).to_lower()
				if token.is_empty():
					continue
				if not lowered.contains(token):
					matched = false
					break
			if matched:
				return animation_name

	return ""


func _coerce_to_node3d(node: Node) -> Node3D:
	if node is Node3D:
		return node as Node3D
	var nested := _find_first_node3d(node)
	if nested == null:
		return null
	var wrapper := Node3D.new()
	wrapper.name = "ModelWrapper"
	wrapper.add_child(node)
	return wrapper


func _find_first_node3d(node: Node) -> Node3D:
	if node == null:
		return null
	if node is Node3D:
		return node as Node3D
	for child in node.get_children():
		var found := _find_first_node3d(child)
		if found != null:
			return found
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer:
		var player := node as AnimationPlayer
		if player.get_animation_list().size() > 0:
			return player
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _setup_runtime_animation_player() -> void:
	if _character_root == null:
		return

	var runtime_library := _get_or_build_runtime_animation_library()
	if runtime_library == null:
		_bind_animation_player_events()
		return

	var runtime_player := AnimationPlayer.new()
	runtime_player.name = "RuntimeAnimationPlayer"
	runtime_player.root_node = NodePath("..")
	runtime_player.add_animation_library("", runtime_library)
	_character_root.add_child(runtime_player)
	_animation_player = runtime_player
	_bind_animation_player_events()


func _get_or_build_runtime_animation_library() -> AnimationLibrary:
	var cache_key := _build_runtime_animation_cache_key()
	var cached_variant: Variant = _animation_library_cache.get(cache_key, null)
	if cached_variant is AnimationLibrary:
		return cached_variant as AnimationLibrary

	var merged_library := AnimationLibrary.new()
	_merge_animations_from_player(_animation_player, merged_library)

	var animation_scene_paths: PackedStringArray = _resolve_animation_scene_paths_for_profile()
	for scene_path in animation_scene_paths:
		_merge_animations_from_scene(scene_path, merged_library)

	if merged_library.get_animation_list().is_empty():
		return null

	_animation_library_cache[cache_key] = merged_library
	return merged_library


func _build_runtime_animation_cache_key() -> String:
	var profile_id := String(_profile.get("profile_id", _profile_id)).strip_edges()
	var character_path := String(_profile.get("character_path", "")).strip_edges()
	var pack_id := String(_profile.get("pack_id", "")).strip_edges().to_lower()
	var use_extra := bool(_profile.get("use_extra_animation_pack", false))
	return "%s|%s|%s|%s" % [profile_id, character_path, pack_id, str(use_extra)]


func _resolve_animation_scene_paths_for_profile() -> PackedStringArray:
	var paths: PackedStringArray = []
	var pack_id := String(_profile.get("pack_id", "")).strip_edges().to_lower()
	var use_extra := bool(_profile.get("use_extra_animation_pack", false))

	var target_dirs: PackedStringArray = []
	if PACK_ANIMATION_DIRS.has(pack_id) and pack_id != UNIFIED_PACK_ID:
		target_dirs.append(String(PACK_ANIMATION_DIRS[pack_id]))
	else:
		for raw_dir in PACK_ANIMATION_DIRS.values():
			target_dirs.append(String(raw_dir))

	if use_extra and _dir_exists(SHARED_MEDIUM_ANIMATIONS_DIR):
		target_dirs.append(SHARED_MEDIUM_ANIMATIONS_DIR)

	for dir_path in target_dirs:
		var files := _collect_animation_scene_files(dir_path)
		for scene_path in files:
			if not paths.has(scene_path):
				paths.append(scene_path)

	paths.sort()
	return paths


func _merge_animations_from_scene(scene_path: String, target_library: AnimationLibrary) -> void:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return

	var instance := scene.instantiate()
	if instance == null:
		return

	var players := _find_animation_players(instance)
	for player_node in players:
		var player := player_node as AnimationPlayer
		_merge_animations_from_player(player, target_library)

	instance.queue_free()


func _merge_animations_from_player(player: AnimationPlayer, target_library: AnimationLibrary) -> void:
	if player == null or target_library == null:
		return

	for raw_name in player.get_animation_list():
		var animation_name := String(raw_name)
		if animation_name.is_empty() or target_library.has_animation(animation_name):
			continue
		var source_animation := player.get_animation(animation_name)
		if source_animation == null:
			continue
		var copied := source_animation.duplicate(true) as Animation
		if copied != null:
			target_library.add_animation(animation_name, copied)


func _find_animation_players(root: Node) -> Array:
	var players: Array = []
	if root is AnimationPlayer:
		players.append(root)

	for child in root.get_children():
		players.append_array(_find_animation_players(child))

	return players


func _collect_animation_scene_files(root_dir: String) -> PackedStringArray:
	var files: PackedStringArray = []
	if not _dir_exists(root_dir):
		return files

	var pending: Array[String] = [root_dir]
	while not pending.is_empty():
		var current_dir: String = pending.pop_back()
		var dir := DirAccess.open(current_dir)
		if dir == null:
			continue
		dir.list_dir_begin()
		while true:
			var entry := dir.get_next()
			if entry.is_empty():
				break
			if entry.begins_with("."):
				continue
			var full_path := current_dir.path_join(entry)
			if dir.current_is_dir():
				pending.append(full_path)
			elif _is_animation_scene_file(entry):
				files.append(full_path)
		dir.list_dir_end()

	files.sort()
	return files


func _is_animation_scene_file(file_name: String) -> bool:
	var ext := file_name.get_extension().to_lower()
	return ext == "glb" or ext == "gltf" or ext == "tscn"


func _dir_exists(dir_path: String) -> bool:
	return DirAccess.open(dir_path) != null


func _fit_character_in_view() -> void:
	if _character_root == null or _camera == null:
		return

	var initial_bounds: AABB = _compute_character_bounds(_character_root, false)
	var initial_center: Vector3 = initial_bounds.position + initial_bounds.size * 0.5
	var ground_y: float = initial_bounds.position.y
	_character_root.position = Vector3(-initial_center.x, -ground_y, -initial_center.z)

	var bounds: AABB = _compute_character_bounds(_character_root, false)
	var model_height: float = maxf(bounds.size.y, 0.6)
	var model_width: float = maxf(maxf(bounds.size.x, bounds.size.z), 0.6)
	var target: Vector3 = Vector3(0.0, clampf(model_height * 0.52, 0.45, 2.8), 0.0)

	var aspect: float = float(maxi(viewport_size.x, 1)) / float(maxi(viewport_size.y, 1))
	var half_vfov: float = deg_to_rad(clampf(_camera.fov, 10.0, 120.0) * 0.5)
	var half_hfov: float = atan(tan(half_vfov) * maxf(aspect, 0.1))
	var half_height: float = maxf(model_height * 0.58, 0.45)
	var half_width: float = maxf(model_width * 0.72, 0.45)
	var dist_v: float = half_height / maxf(tan(half_vfov), 0.05)
	var dist_h: float = half_width / maxf(tan(half_hfov), 0.05)
	var distance: float = maxf(maxf(dist_v, dist_h) * 1.28, 3.2)

	_camera.near = 0.03
	_camera.far = maxf(distance * 10.0, 64.0)
	_camera.position = target + Vector3(0.0, maxf(model_height * 0.2, 0.28), distance)
	_camera.look_at_from_position(_camera.position, target, Vector3.UP)
	_apply_lighting_preset()


func _fit_character_in_fixed_preview_frame() -> void:
	if _character_root == null or _camera == null:
		return

	var initial_bounds: AABB = _compute_character_bounds(_character_root, false)
	var initial_center: Vector3 = initial_bounds.position + initial_bounds.size * 0.5
	var ground_y: float = initial_bounds.position.y
	_character_root.position = Vector3(-initial_center.x, -ground_y, -initial_center.z)

	var body_bounds: AABB = _compute_character_bounds(_character_root, false)

	var centered: Vector3 = body_bounds.position + body_bounds.size * 0.5
	var body_ground_y: float = body_bounds.position.y
	_character_root.position = Vector3(-centered.x, -body_ground_y, -centered.z)
	body_bounds = _compute_character_bounds(_character_root, false)

	var body_target_y: float = body_bounds.position.y + body_bounds.size.y * SELECTION_PREVIEW_CAMERA_TARGET_RATIO
	var target_y: float = clampf(body_target_y, 0.72, 1.6)
	var eye_y: float = target_y + SELECTION_PREVIEW_CAMERA_EYE_Y_OFFSET
	var target := Vector3(0.0, target_y, 0.0)
	var eye_position := Vector3(0.0, eye_y, SELECTION_PREVIEW_CAMERA_DISTANCE)
	_camera.near = 0.03
	_camera.far = 64.0
	_camera.position = eye_position
	_camera.look_at_from_position(eye_position, target, Vector3.UP)
	_apply_lighting_preset()


func _compute_character_bounds(root: Node3D, include_weapon_meshes: bool = true) -> AABB:
	var meshes: Array[MeshInstance3D] = _collect_mesh_instances(root, include_weapon_meshes)
	var has_bounds := false
	var merged := AABB(Vector3(-0.3, 0.0, -0.3), Vector3(0.6, 1.6, 0.6))

	for mesh_instance in meshes:
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var local_aabb: AABB = mesh_instance.get_aabb()
		var local_center: Vector3 = local_aabb.position + local_aabb.size * 0.5
		var local_extents: Vector3 = local_aabb.size * 0.5
		var world_center: Vector3 = mesh_instance.to_global(local_center)
		var center_in_root: Vector3 = root.to_local(world_center)
		var world_scale: Vector3 = mesh_instance.global_transform.basis.get_scale()
		var scaled_extents := Vector3(
			local_extents.x * absf(world_scale.x),
			local_extents.y * absf(world_scale.y),
			local_extents.z * absf(world_scale.z)
		)
		var aabb_in_root := AABB(center_in_root - scaled_extents, scaled_extents * 2.0)
		if has_bounds:
			merged = merged.merge(aabb_in_root)
		else:
			merged = aabb_in_root
			has_bounds = true

	return merged


func _collect_mesh_instances(root: Node, include_weapon_meshes: bool = true) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	_collect_mesh_instances_recursive(root, include_weapon_meshes, false, result)
	return result


func _collect_mesh_instances_recursive(node: Node, include_weapon_meshes: bool, branch_excluded: bool, output: Array[MeshInstance3D]) -> void:
	if node == null:
		return

	var current_excluded: bool = branch_excluded
	if not include_weapon_meshes and _node_excluded_from_preview_bounds(node):
		current_excluded = true

	if node is MeshInstance3D and not current_excluded:
		output.append(node as MeshInstance3D)

	for child in node.get_children():
		_collect_mesh_instances_recursive(child, include_weapon_meshes, current_excluded, output)


func _node_excluded_from_preview_bounds(node: Node) -> bool:
	if node == null:
		return false
	if node.has_meta("exclude_preview_bounds"):
		return bool(node.get_meta("exclude_preview_bounds"))
	return String(node.name).begins_with("WeaponSocket_")


func _apply_profile_style_colors() -> void:
	if _character_root == null:
		return

	var hair_key: String = String(_profile.get("hair_preset_key", "default")).strip_edges().to_lower()
	var skin_key: String = String(_profile.get("skin_preset_key", "default")).strip_edges().to_lower()
	var cloth_key: String = String(_profile.get("cloth_preset_key", "default")).strip_edges().to_lower()
	var hat_key: String = String(_profile.get("hat_preset_key", "default")).strip_edges().to_lower()

	var hair_color: Color = _resolve_profile_style_color(hair_key, String(_profile.get("hair_tint_html", "")), PROFILE_HAIR_COLOR_PRESETS)
	var skin_color: Color = _resolve_profile_style_color(skin_key, String(_profile.get("skin_tint_html", "")), PROFILE_SKIN_COLOR_PRESETS)
	var cloth_color: Color = _resolve_profile_style_color(cloth_key, String(_profile.get("cloth_tint_html", "")), PROFILE_CLOTH_COLOR_PRESETS)
	var hat_color: Color = _resolve_profile_style_color(hat_key, String(_profile.get("hat_tint_html", "")), PROFILE_HAT_COLOR_PRESETS)

	var use_hair_tint: bool = _should_apply_profile_tint(hair_key, hair_color)
	var use_skin_tint: bool = _should_apply_profile_tint(skin_key, skin_color)
	var use_cloth_tint: bool = _should_apply_profile_tint(cloth_key, cloth_color)
	var use_hat_tint: bool = _should_apply_profile_tint(hat_key, hat_color)

	var character_path_lower: String = String(_profile.get("character_path", "")).to_lower()
	var is_skeleton_character: bool = character_path_lower.contains("kaykit_skeletons") or character_path_lower.contains("skeleton_")
	for mesh_instance in _collect_mesh_instances(_character_root, false):
		if mesh_instance == null:
			continue
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue

		var mesh_name: String = String(mesh_instance.name)
		var tint_color := Color.WHITE
		var use_tint := false
		if _profile_mesh_name_contains_hints(mesh_name, PROFILE_EYE_NODE_HINTS):
			use_tint = false
		elif is_skeleton_character and _profile_mesh_name_contains_hints(mesh_name, PROFILE_SKELETON_BONE_NODE_HINTS) and use_skin_tint:
			tint_color = skin_color
			use_tint = true
		elif _profile_mesh_name_contains_hints(mesh_name, PROFILE_HAT_NODE_HINTS) and use_hat_tint:
			tint_color = hat_color
			use_tint = true
		elif _profile_mesh_name_contains_hints(mesh_name, PROFILE_HAIR_NODE_HINTS) and use_hair_tint:
			tint_color = hair_color
			use_tint = true
		elif _profile_mesh_name_contains_hints(mesh_name, PROFILE_SKIN_NODE_HINTS) and use_skin_tint:
			tint_color = skin_color
			use_tint = true
		elif _profile_mesh_name_contains_hints(mesh_name, PROFILE_CLOTH_NODE_HINTS) and use_cloth_tint:
			if not (is_skeleton_character and _profile_mesh_name_contains_hints(mesh_name, PROFILE_SKELETON_BONE_NODE_HINTS)):
				tint_color = cloth_color
				use_tint = true

		for i in range(mesh.get_surface_count()):
			if not use_tint:
				mesh_instance.set_surface_override_material(i, null)
				continue
			var base_material := mesh.surface_get_material(i)
			if base_material == null:
				base_material = mesh_instance.get_active_material(i)
			mesh_instance.set_surface_override_material(i, _create_tinted_material(base_material, tint_color))


func _resolve_profile_style_color(preset_key: String, tint_html: String, preset_map: Dictionary) -> Color:
	var safe_key: String = preset_key.strip_edges().to_lower()
	if safe_key.is_empty():
		safe_key = "default"
	var fallback_color := Color.WHITE
	if preset_map.has(safe_key):
		fallback_color = preset_map[safe_key]
	elif preset_map.has("default"):
		fallback_color = preset_map["default"]
	var raw_tint: String = tint_html.strip_edges()
	if raw_tint.is_empty():
		return fallback_color
	return Color.from_string(raw_tint, fallback_color)


func _should_apply_profile_tint(preset_key: String, tint_color: Color) -> bool:
	var safe_key: String = preset_key.strip_edges().to_lower()
	if safe_key.is_empty():
		safe_key = "default"
	return safe_key != "default" or not tint_color.is_equal_approx(Color.WHITE)


func _profile_mesh_name_contains_hints(mesh_name: String, hints: Array) -> bool:
	var normalized: String = mesh_name.to_lower()
	for hint in hints:
		if normalized.contains(String(hint)):
			return true
	return false


func _create_tinted_material(base_material: Material, tint_color: Color) -> Material:
	if base_material == null:
		var generated_material := StandardMaterial3D.new()
		generated_material.albedo_color = tint_color
		return generated_material
	if base_material is BaseMaterial3D:
		var copied := (base_material as BaseMaterial3D).duplicate(true) as BaseMaterial3D
		copied.albedo_color = tint_color
		return copied
	return base_material


func _apply_mesh_render_preset() -> void:
	if _character_root == null:
		return

	for mesh_instance in _collect_mesh_instances(_character_root):
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _find_first_skeleton(node: Node) -> Skeleton3D:
	if node == null:
		return null
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_first_skeleton(child)
		if found != null:
			return found
	return null


func _find_hand_bone_name(skeleton: Skeleton3D, prefer_left_hand: bool) -> String:
	var hints: Array
	if prefer_left_hand:
		hints = LEFT_HAND_BONE_HINTS
	else:
		hints = RIGHT_HAND_BONE_HINTS
	var all_bones: Array[String] = []
	for bone_index in range(skeleton.get_bone_count()):
		all_bones.append(skeleton.get_bone_name(bone_index))

	for hint in hints:
		var normalized_hint := _normalize_bone_name(hint)
		for bone_name in all_bones:
			if _normalize_bone_name(bone_name).contains(normalized_hint):
				return bone_name

	for bone_name in all_bones:
		var normalized := _normalize_bone_name(bone_name)
		if not normalized.contains("hand"):
			continue
		if prefer_left_hand and normalized.contains("l"):
			return bone_name
		if not prefer_left_hand and normalized.contains("r"):
			return bone_name
	return ""


func _normalize_bone_name(value: String) -> String:
	return value.to_lower().replace("_", "").replace(" ", "").replace(".", "").replace(":", "")
