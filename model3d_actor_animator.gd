extends Node2D
class_name Model3DActorAnimator

const PROFILE_INDEX_PATH := "res://assets/heroes/models_3d/index.json"
const ACTIONS_TABLE_PATH := "res://data/tables/actions.json"
const RUNTIME_CONSTANTS_TABLE_PATH := "res://data/tables/runtime_constants.json"
const RUNTIME_WEAPON_SOCKET_TARGET_EXTENT_KEY := "model3d_weapon_socket_target_extent"
const RUNTIME_WEAPON_SOCKET_TARGET_EXTENT_ID := "5"
const VIEWPORT_SIZE := Vector2i(180, 180)
const DEFAULT_SPRITE_SCALE := 1.0
const DEFAULT_CAMERA_YAW := 0.0
const DEFAULT_CAMERA_PITCH := deg_to_rad(8.0)
const DEFAULT_CAMERA_DISTANCE := 4.4
const DEFAULT_CAMERA_FOCUS := Vector3(0.0, 1.0, 0.0)
const MODEL_FACING_YAW_OFFSET := 0.0
const MODEL_FRAME_PADDING := 1.35
const DEFAULT_WEAPON_SOCKET_TARGET_EXTENT := 0.95
const WEAPON_TUNE_UNITS := "godot_units"
const LEGACY_WEAPON_TUNE_POSITION_SCALE := 0.01
const LEGACY_WEAPON_TUNE_POSITION_THRESHOLD := 5.0
const WEAPON_ELONGATED_GRIP_RATIO := 1.6
const USE_SNAPSHOT_TEXTURE_FALLBACK := false
const VIEWPORT_BIND_RETRY_INTERVAL := 0.25
const VIEWPORT_BIND_MAX_ATTEMPTS := 12
const RIGHT_HAND_HINTS := [
	"hand.r",
	"hand_r",
	"r_hand",
	"rhand",
	"righthand",
	"right hand",
	"handslot.r",
	"handslot_r",
	"mixamorig:righthand",
	"bip001rhand",
]
const LEFT_HAND_HINTS := [
	"hand.l",
	"hand_l",
	"l_hand",
	"lhand",
	"lefthand",
	"left hand",
	"handslot.l",
	"handslot_l",
	"mixamorig:lefthand",
	"bip001lhand",
]
const ROOT_MOTION_POSITION_BONE_NAMES := ["hips", "pelvis", "root", "mixamorig:hips"]

@export var visual_offset := Vector2(0, -8)
@export var display_scale := DEFAULT_SPRITE_SCALE
@export var asset_quality := "runtime"

var _model_id: StringName = &""
var _profile: Dictionary = {}
var _viewport: SubViewport
var _sprite: Sprite2D
var _world_root: Node3D
var _model_container: Node3D
var _model_root: Node3D
var _camera: Camera3D
var _animation_player: AnimationPlayer
var _animation_names: PackedStringArray = PackedStringArray()
var _action_row: Dictionary = {}
var _current_clip := ""
var _clip_window_start_seconds := 0.0
var _clip_window_end_seconds := -1.0
var _clip_window_loop := false
var _dead := false
var _attack_locked := false
var _pending_config_model_id: StringName = &""
var _is_building_runtime := false
var _static_ground_anchor := Vector3.ZERO
var _has_static_ground_anchor := false
static var _scene_template_cache: Dictionary = {}
static var _runtime_constant_float_cache: Dictionary = {}
static var _action_row_cache: Dictionary = {}


func set_asset_quality(value: String) -> void:
	asset_quality = value


func configure_model_id(model_id: StringName) -> bool:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	if String(_model_id).strip_edges() == String(model_id).strip_edges() and _model_root != null:
		_dead = false
		_attack_locked = false
		_current_clip = ""
		return true
	_model_id = model_id
	_dead = false
	_attack_locked = false
	_current_clip = ""
	_profile = _load_profile(model_id)
	if _profile.is_empty():
		return false
	_action_row = _load_action_row(model_id)
	var character_path := _profile_character_path()
	if character_path.is_empty():
		return false
	_pending_config_model_id = model_id
	if is_inside_tree():
		call_deferred("_apply_pending_model_config")
	return true


func ensure_model_ready() -> void:
	if _model_root != null:
		return
	if not String(_pending_config_model_id).strip_edges().is_empty():
		_apply_pending_model_config()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	if not String(_pending_config_model_id).strip_edges().is_empty():
		call_deferred("_apply_pending_model_config")


func _apply_pending_model_config() -> void:
	if _is_building_runtime:
		return
	if String(_pending_config_model_id).strip_edges().is_empty():
		return
	_is_building_runtime = true
	var model_id := _pending_config_model_id
	_pending_config_model_id = &""
	_clear_runtime_nodes()
	_model_id = model_id
	_profile = _load_profile(model_id)
	_action_row = _load_action_row(model_id)
	var character_path := _profile_character_path()
	if character_path.is_empty():
		_is_building_runtime = false
		return
	var animation_character_path := _profile_animation_character_path(character_path)
	_setup_viewport()
	_model_root = _instantiate_scene_as_node3d(character_path)
	if _model_root == null:
		_is_building_runtime = false
		return
	_set_process_always_recursive(_model_root)
	_model_container = Node3D.new()
	_model_container.name = "ModelDisplayContainer"
	_model_container.process_mode = Node.PROCESS_MODE_ALWAYS
	_world_root.add_child(_model_container)
	_model_container.add_child(_model_root)
	_apply_profile_scale()
	_attach_profile_weapons()
	_setup_animations(animation_character_path)
	_set_process_always_recursive(_model_root)
	_capture_static_ground_anchor()
	_center_model_on_focus()
	_apply_mesh_render_defaults()
	_frame_model()
	play_idle()
	_prepare_viewport_texture_binding()
	_is_building_runtime = false


func _process(_delta: float) -> void:
	_update_clip_window()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_clear_external_scene_template_cache()


func set_motion_state(direction: Vector2, is_moving: bool) -> void:
	if _dead or _attack_locked:
		return
	_update_facing(direction)
	if is_moving:
		_play_action_state("move", ["run", "walk", "move"], true)
	else:
		play_idle()


func play_idle() -> void:
	_play_action_state("idle", ["idle", "stand"], true)


func play_attack(direction: Vector2, attack_duration: float) -> Dictionary:
	if _dead:
		return {}
	_attack_locked = true
	_update_facing(direction)
	_play_action_state("attack", ["attack", "atk", "slash"], false)
	return _build_attack_timing(attack_duration)


func start_attack_preview(direction: Vector2) -> void:
	play_attack(direction, 0.0)


func set_attack_preview_progress(direction: Vector2, _progress: float) -> void:
	if _dead:
		return
	_update_facing(direction)
	_attack_locked = true


func play_attack_hit(direction: Vector2) -> void:
	play_attack(direction, 0.0)


func set_attack_recover_progress(direction: Vector2, _progress: float) -> void:
	if _dead:
		return
	_update_facing(direction)


func stop_attack(direction: Vector2) -> void:
	if _dead:
		return
	_attack_locked = false
	set_motion_state(direction, false)


func cancel_attack() -> void:
	_attack_locked = false
	play_idle()


func play_death() -> void:
	_dead = true
	_attack_locked = false
	_play_action_state("death", ["death", "die"], false)


func play_hit() -> void:
	if _dead:
		return
	_play_action_state("hit", ["hit", "damage"], false)


func play_spawn() -> void:
	if _dead:
		return
	play_idle()


func play_victory() -> void:
	_play_action_state("victory", ["victory", "win", "idle"], true)


func set_stunned(_enabled: bool) -> void:
	pass


func set_runtime_active(enabled: bool) -> void:
	if _viewport != null:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_ONCE


func reset_runtime_state(default_direction: Vector2 = Vector2.DOWN, force_idle: bool = true) -> void:
	_dead = false
	_attack_locked = false
	_update_facing(default_direction)
	if force_idle:
		play_idle()


func set_dissolve_progress(progress: float) -> void:
	modulate.a = 1.0 - clampf(progress, 0.0, 1.0)


func rotate_preview(delta_yaw: float) -> void:
	if _world_root != null:
		_world_root.rotate_y(delta_yaw)


func start_showcase() -> void:
	play_idle()


func stop_showcase() -> void:
	pass


func set_showcase_spin_speed(_speed: float) -> void:
	pass


func apply_selection_preview_preset() -> void:
	pass


func play_selection_preview_intro() -> void:
	play_idle()


func apply_profile_overrides(_overrides: Dictionary) -> void:
	pass


func start_jump(direction: Vector2) -> void:
	_update_facing(direction)
	_play_action_state("jump", ["jump"], false)


func set_jump_direction(direction: Vector2) -> void:
	_update_facing(direction)


func stop_jump(direction: Vector2, is_moving: bool) -> void:
	set_motion_state(direction, is_moving)


func set_jump_phase(_phase_index: int) -> void:
	pass


func get_jump_motion_config() -> Dictionary:
	var fps := _read_action_fps("jump")
	var start_frame := _read_action_frame("jump_start_frame", 0)
	var end_frame := _read_action_frame("jump_end_frame", -1)
	var ignore_frame := _read_action_frame("jump_ignore_collision_frame", -1)
	var land_frame := _read_action_frame("jump_land_frame", -1)
	var start_seconds := _frame_to_seconds(start_frame, fps)
	var end_seconds := _frame_to_seconds(end_frame, fps)
	var duration_seconds := -1.0
	if end_seconds > start_seconds:
		duration_seconds = end_seconds - start_seconds
	var ignore_seconds := -1.0
	if ignore_frame >= 0:
		ignore_seconds = maxf((float(ignore_frame) - float(start_frame)) / fps, 0.0)
	var land_seconds := -1.0
	if land_frame >= 0:
		land_seconds = maxf((float(land_frame) - float(start_frame)) / fps, 0.0)
	return {
		"fps": fps,
		"start_frame": start_frame,
		"end_frame": end_frame,
		"ignore_collision_frame": ignore_frame,
		"land_frame": land_frame,
		"ignore_collision_seconds": ignore_seconds,
		"land_seconds": land_seconds,
		"duration_seconds": duration_seconds,
	}


func set_visual_height(offset_y: float) -> void:
	position.y = offset_y


func _setup_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "ModelViewport"
	_viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	_viewport.size = VIEWPORT_SIZE
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.disable_3d = false
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_world_root = Node3D.new()
	_world_root.name = "WorldRoot"
	_world_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_viewport.add_child(_world_root)

	var light := DirectionalLight3D.new()
	light.name = "KeyLight"
	light.process_mode = Node.PROCESS_MODE_ALWAYS
	light.light_energy = 2.0
	light.rotation_degrees = Vector3(-45, 35, 0)
	_world_root.add_child(light)

	var fill := OmniLight3D.new()
	fill.name = "FillLight"
	fill.process_mode = Node.PROCESS_MODE_ALWAYS
	fill.light_energy = 1.2
	fill.position = Vector3(0, 2.0, 3.0)
	_world_root.add_child(fill)

	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.process_mode = Node.PROCESS_MODE_ALWAYS
	_camera.current = true
	_camera.cull_mask = 0xFFFFF
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.fov = 45.0
	_viewport.add_child(_camera)

	_sprite = Sprite2D.new()
	_sprite.name = "ViewportSprite"
	_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	_sprite.centered = true
	_sprite.position = visual_offset
	_sprite.scale = Vector2.ONE * display_scale
	_sprite.z_index = 100
	_sprite.z_as_relative = true
	add_child(_sprite)


func _prepare_viewport_texture_binding() -> void:
	if _viewport == null or _sprite == null:
		return
	_sprite.texture = _viewport.get_texture()
	_sprite.visible = true
	_bind_viewport_texture_after_timer(1)


func _bind_viewport_texture_after_timer(attempt: int) -> void:
	await get_tree().create_timer(VIEWPORT_BIND_RETRY_INTERVAL, true, false, true).timeout
	_bind_viewport_texture_now(attempt)


func _bind_viewport_texture_now(attempt: int) -> void:
	if _viewport == null or _sprite == null:
		return
	var used_pixels := -1
	var detail_pixels := -1
	var viewport_texture := _viewport.get_texture()
	_sprite.texture = viewport_texture
	var image := viewport_texture.get_image()
	if image != null:
		used_pixels = _count_visible_pixels(image)
		detail_pixels = _count_pixels_different_from_corner(image)
		if USE_SNAPSHOT_TEXTURE_FALLBACK and used_pixels > 0:
			_sprite.texture = ImageTexture.create_from_image(image)
	_sprite.visible = true
	if (used_pixels <= 0 or detail_pixels <= 0) and attempt < VIEWPORT_BIND_MAX_ATTEMPTS:
		_bind_viewport_texture_after_timer(attempt + 1)


func _set_process_always_recursive(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_set_process_always_recursive(child)


func _count_visible_pixels(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.01:
				count += 1
	return count


func _count_pixels_different_from_corner(image: Image) -> int:
	var count := 0
	var reference := image.get_pixel(0, 0)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if absf(color.r - reference.r) > 0.02 or absf(color.g - reference.g) > 0.02 or absf(color.b - reference.b) > 0.02 or absf(color.a - reference.a) > 0.02:
				count += 1
	return count


func _clear_runtime_nodes() -> void:
	modulate = Color.WHITE
	for child in get_children():
		child.queue_free()
	_viewport = null
	_sprite = null
	_world_root = null
	_model_container = null
	_model_root = null
	_camera = null
	_animation_player = null
	_animation_names = PackedStringArray()
	_static_ground_anchor = Vector3.ZERO
	_has_static_ground_anchor = false


static func _load_profile(model_id: StringName) -> Dictionary:
	var key := String(model_id).strip_edges()
	if key.is_empty() or not FileAccess.file_exists(PROFILE_INDEX_PATH):
		return {}
	var file := FileAccess.open(PROFILE_INDEX_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		return {}
	var profile_variant: Variant = (parsed as Dictionary).get(key, {})
	if profile_variant is Dictionary:
		return (profile_variant as Dictionary).duplicate(true)
	return {}


static func _load_action_row(model_id: StringName) -> Dictionary:
	var key := String(model_id).strip_edges()
	if key.is_empty():
		return {}
	_ensure_action_row_cache()
	var row_variant: Variant = _action_row_cache.get(key, {})
	if row_variant is Dictionary:
		return (row_variant as Dictionary).duplicate(true)
	return {}


static func _ensure_action_row_cache() -> void:
	if bool(_action_row_cache.get("__loaded", false)):
		return
	_action_row_cache.clear()
	_action_row_cache["__loaded"] = true
	if not FileAccess.file_exists(ACTIONS_TABLE_PATH):
		return
	var file := FileAccess.open(ACTIONS_TABLE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Array:
		return
	for row_variant in parsed as Array:
		if row_variant is not Dictionary:
			continue
		var row := row_variant as Dictionary
		var model_id_text := str(row.get("model_id", "")).strip_edges()
		if model_id_text.is_empty():
			continue
		_action_row_cache[model_id_text] = row.duplicate(true)


func _profile_character_path() -> String:
	var preview_path := str(_profile.get("character_path", "")).strip_edges()
	if _uses_preview_assets():
		return preview_path
	var runtime_path := str(_profile.get("runtime_character_path", _profile.get("low_character_path", ""))).strip_edges()
	if not runtime_path.is_empty() and _scene_path_exists(runtime_path):
		return runtime_path
	var derived_path := _derive_low_character_path(preview_path)
	if not derived_path.is_empty() and _scene_path_exists(derived_path):
		return derived_path
	return preview_path


func _profile_animation_character_path(fallback_path: String) -> String:
	var preview_path := str(_profile.get("character_path", "")).strip_edges()
	if not preview_path.is_empty() and _scene_path_exists(preview_path):
		return preview_path
	return fallback_path


func _profile_right_weapon_path() -> String:
	var preview_path := str(_profile.get("right_weapon_path", _profile.get("weapon_path", ""))).strip_edges()
	if _uses_preview_assets():
		return preview_path
	var runtime_path := str(_profile.get("runtime_right_weapon_path", _profile.get("low_right_weapon_path", ""))).strip_edges()
	if not runtime_path.is_empty() and _scene_path_exists(runtime_path):
		return runtime_path
	var derived_path := _derive_low_weapon_path(preview_path)
	if not derived_path.is_empty() and _scene_path_exists(derived_path):
		return derived_path
	return preview_path


func _profile_left_weapon_path() -> String:
	var preview_path := str(_profile.get("left_weapon_path", "")).strip_edges()
	if _uses_preview_assets():
		return preview_path
	var runtime_path := str(_profile.get("runtime_left_weapon_path", _profile.get("low_left_weapon_path", ""))).strip_edges()
	if not runtime_path.is_empty() and _scene_path_exists(runtime_path):
		return runtime_path
	var derived_path := _derive_low_weapon_path(preview_path)
	if not derived_path.is_empty() and _scene_path_exists(derived_path):
		return derived_path
	return preview_path


func _uses_preview_assets() -> bool:
	return asset_quality.strip_edges().to_lower() == "preview"


static func _scene_path_exists(path: String) -> bool:
	var clean_path := path.strip_edges()
	if clean_path.is_empty():
		return false
	if _is_project_resource_path(clean_path):
		return ResourceLoader.exists(clean_path, "PackedScene") or FileAccess.file_exists(clean_path)
	return FileAccess.file_exists(clean_path)


static func _derive_low_character_path(path: String) -> String:
	var clean_path := path.strip_edges()
	if clean_path.is_empty():
		return ""
	var extension := clean_path.get_extension()
	if extension.is_empty():
		return ""
	var base_name := clean_path.get_file().get_basename()
	var lower_base := base_name.to_lower()
	if lower_base.ends_with("_low_benti"):
		return clean_path
	if not lower_base.ends_with("_benti"):
		return ""
	var name_without_benti := base_name.substr(0, base_name.length() - 6)
	return "%s/%s_low_benti.%s" % [clean_path.get_base_dir(), name_without_benti, extension]


static func _derive_low_weapon_path(path: String) -> String:
	var clean_path := path.strip_edges()
	if clean_path.is_empty():
		return ""
	var extension := clean_path.get_extension()
	if extension.is_empty():
		return ""
	var base_name := clean_path.get_file().get_basename()
	if base_name.to_lower().ends_with("_low"):
		return clean_path
	return "%s/%s_low.%s" % [clean_path.get_base_dir(), base_name, extension]


static func _clear_external_scene_template_cache() -> void:
	for key in _scene_template_cache.keys():
		var value: Variant = _scene_template_cache.get(key)
		if value is Node3D:
			var node := value as Node3D
			if is_instance_valid(node):
				node.free()
			_scene_template_cache.erase(key)


func _instantiate_scene_as_node3d(scene_path: String) -> Node3D:
	var resolved_path := scene_path.strip_edges()
	if resolved_path.is_empty():
		return null
	if _is_project_resource_path(resolved_path):
		var cached: Variant = _scene_template_cache.get(resolved_path, null)
		if cached is PackedScene:
			return _coerce_to_node3d((cached as PackedScene).instantiate())
		var packed_scene := load(resolved_path) as PackedScene
		if packed_scene != null:
			_scene_template_cache[resolved_path] = packed_scene
			return _coerce_to_node3d(packed_scene.instantiate())
	var external_cached: Variant = _scene_template_cache.get(resolved_path, null)
	if external_cached is Node3D:
		return _coerce_to_node3d((external_cached as Node3D).duplicate())
	if not FileAccess.file_exists(resolved_path):
		return null
	var extension := resolved_path.get_extension().to_lower()
	if extension != "glb" and extension != "gltf":
		push_warning("Runtime 3D actor only loads GLB/GLTF directly: %s" % resolved_path)
		return null
	var gltf_document := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	var error := gltf_document.append_from_file(resolved_path, gltf_state)
	if error != OK:
		push_warning("Runtime GLB load failed: %s (%s)" % [resolved_path, error])
		return null
	var generated_node := _coerce_to_node3d(gltf_document.generate_scene(gltf_state))
	if generated_node != null:
		_scene_template_cache[resolved_path] = generated_node.duplicate()
	return generated_node


func _coerce_to_node3d(node: Node) -> Node3D:
	if node == null:
		return null
	if node is Node3D:
		return node as Node3D
	for child in node.get_children():
		if child is Node3D:
			node.remove_child(child)
			node.queue_free()
			return child as Node3D
	node.queue_free()
	return null


func _setup_animations(character_path: String) -> void:
	if _model_root == null:
		return
	_animation_player = AnimationPlayer.new()
	_animation_player.name = "RuntimeAnimationPlayer"
	_animation_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_model_root.add_child(_animation_player)
	var library := AnimationLibrary.new()
	for animation_path in _collect_animation_scene_paths_for_character(character_path):
		_merge_animations_from_scene(animation_path, library)
	if library.get_animation_list().is_empty():
		_merge_animations_from_scene(character_path, library)
	_animation_player.add_animation_library("", library)
	_animation_names = _animation_player.get_animation_list()


func _collect_animation_scene_paths_for_character(character_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	var folder := character_path.get_base_dir()
	if folder.is_empty():
		return result
	var dir := DirAccess.open(folder)
	if dir == null:
		return result
	var selected := character_path.replace("\\", "/").to_lower()
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir():
			var extension := file_name.get_extension().to_lower()
			if extension == "glb" or extension == "gltf":
				var path := "%s/%s" % [folder, file_name]
				var normalized := path.replace("\\", "/").to_lower()
				if normalized != selected and not _is_benti_model_file(folder, path):
					result.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


func _is_benti_model_file(folder: String, path: String) -> bool:
	var folder_name := folder.get_file().to_lower()
	var base_name := path.get_file().get_basename().to_lower()
	return base_name == "%s_benti" % folder_name or base_name.ends_with("_benti")


func _merge_animations_from_scene(scene_path: String, target_library: AnimationLibrary) -> void:
	var instance := _instantiate_scene_as_node3d(scene_path)
	if instance == null:
		return
	var candidates: Array[Dictionary] = []
	for player in _find_animation_players(instance):
		var source_player := player as AnimationPlayer
		for animation_name in source_player.get_animation_list():
			var animation := source_player.get_animation(animation_name)
			if animation != null:
				candidates.append({"name": animation_name, "animation": animation})
	var chosen := _choose_animation_from_file_candidates(scene_path.get_file().get_basename(), candidates)
	if chosen != null:
		var target_name := _dedupe_animation_name(scene_path.get_file().get_basename(), target_library)
		target_library.add_animation(target_name, _strip_root_motion_tracks(chosen))
	instance.queue_free()


func _find_animation_players(root: Node) -> Array:
	var result: Array = []
	if root is AnimationPlayer:
		result.append(root)
	for child in root.get_children():
		result.append_array(_find_animation_players(child))
	return result


func _choose_animation_from_file_candidates(file_animation_name: String, candidates: Array[Dictionary]) -> Animation:
	if candidates.is_empty():
		return null
	var best_score := -999999.0
	var best_animation: Animation = null
	var file_tokens := _split_identifier_tokens(file_animation_name)
	for candidate in candidates:
		var candidate_name := str(candidate.get("name", ""))
		var animation := candidate.get("animation", null) as Animation
		if animation == null:
			continue
		var score := animation.length
		var normalized_name := candidate_name.to_lower()
		if normalized_name.contains("clip0"):
			score -= 100.0
		else:
			score += 10.0
		for token in file_tokens:
			if token.length() > 1 and normalized_name.contains(token.to_lower()):
				score += 50.0
		if score > best_score:
			best_score = score
			best_animation = animation
	return best_animation


func _dedupe_animation_name(base_name: String, target_library: AnimationLibrary) -> String:
	if not target_library.has_animation(base_name):
		return base_name
	var index := 2
	while target_library.has_animation("%s_%d" % [base_name, index]):
		index += 1
	return "%s_%d" % [base_name, index]


func _strip_root_motion_tracks(animation: Animation) -> Animation:
	var sanitized := animation.duplicate(true) as Animation
	if sanitized == null:
		return animation
	for track_index in range(sanitized.get_track_count() - 1, -1, -1):
		if _is_root_motion_track(sanitized, track_index):
			sanitized.remove_track(track_index)
	return sanitized


func _is_root_motion_track(animation: Animation, track_index: int) -> bool:
	var track_type := animation.track_get_type(track_index)
	if track_type != Animation.TYPE_POSITION_3D and track_type != Animation.TYPE_ROTATION_3D:
		return false
	var path_text := String(animation.track_get_path(track_index)).to_lower()
	if not path_text.contains(":"):
		return true
	if track_type != Animation.TYPE_POSITION_3D:
		return false
	var bone_name := path_text.get_slice(":", 1).strip_edges().replace("_", "").replace(" ", "")
	for root_name in ROOT_MOTION_POSITION_BONE_NAMES:
		var normalized_root: String = root_name.replace("_", "").replace(" ", "")
		if bone_name == normalized_root or bone_name.ends_with(normalized_root):
			return true
	return false


func _split_identifier_tokens(text: String) -> PackedStringArray:
	var normalized := text.replace("-", "_").replace(" ", "_")
	var parts := normalized.split("_", false)
	var result := PackedStringArray()
	for part in parts:
		var token := part.strip_edges()
		if not token.is_empty():
			result.append(token)
	return result


func _play_best_clip(hints: Array[String], loop: bool) -> void:
	if _animation_player == null or _animation_names.is_empty():
		return
	var clip := _find_clip_by_hints(hints)
	if clip.is_empty():
		clip = _animation_names[0]
	_play_clip_window(clip, loop, 0.0, -1.0)


func _play_action_state(state_name: String, hints: Array[String], default_loop: bool) -> void:
	if _animation_player == null or _animation_names.is_empty():
		return
	var expression := str(_action_row.get(state_name, "")).strip_edges()
	var loop := _read_action_loop(state_name, default_loop)
	if not expression.is_empty():
		var action_clip := _resolve_action_clip(expression)
		if not action_clip.is_empty():
			var fps := _read_action_fps(state_name)
			var start_seconds := _frame_to_seconds(_read_action_frame("%s_start_frame" % state_name, -1), fps)
			var end_seconds := _frame_to_seconds(_read_action_frame("%s_end_frame" % state_name, -1), fps)
			_play_clip_window(action_clip, loop, start_seconds, end_seconds)
			return
	_play_best_clip(hints, default_loop)


func _play_clip_window(clip: String, loop: bool, start_seconds: float = 0.0, end_seconds: float = -1.0) -> void:
	if clip.is_empty() or _animation_player == null:
		return
	var animation := _animation_player.get_animation(clip)
	if animation == null:
		return
	var safe_start := clampf(start_seconds, 0.0, maxf(animation.length, 0.0))
	var safe_end := end_seconds
	if safe_end > 0.0:
		safe_end = clampf(safe_end, safe_start + 0.001, maxf(animation.length, safe_start + 0.001))
	animation.loop_mode = Animation.LOOP_NONE if safe_end > 0.0 else (Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE)
	if clip == _current_clip and _animation_player.is_playing() and is_equal_approx(_clip_window_start_seconds, safe_start) and is_equal_approx(_clip_window_end_seconds, safe_end):
		return
	_animation_player.speed_scale = 1.0
	_clip_window_start_seconds = safe_start
	_clip_window_end_seconds = safe_end
	_clip_window_loop = loop
	_animation_player.play(clip)
	if safe_start > 0.0:
		_animation_player.seek(safe_start, true)
	_current_clip = clip


func _update_clip_window() -> void:
	if _animation_player == null or _current_clip.is_empty():
		return
	if _clip_window_end_seconds <= 0.0:
		return
	if _animation_player.current_animation != _current_clip:
		return
	if _animation_player.current_animation_position < _clip_window_end_seconds:
		return
	if _clip_window_loop:
		_animation_player.seek(_clip_window_start_seconds, true)
		if not _animation_player.is_playing():
			_animation_player.play(_current_clip)
	else:
		_animation_player.seek(_clip_window_end_seconds, true)
		_animation_player.speed_scale = 0.0


func _resolve_action_clip(expression: String) -> String:
	var alternatives: Array[String] = []
	var normalized_expression := expression.replace("，", "|").replace(",", "|")
	for part in normalized_expression.split("|", false):
		var token := str(part).strip_edges()
		if token.is_empty():
			continue
		if token.contains(">"):
			token = str(token.split(">", false)[0]).strip_edges()
		if not token.is_empty():
			alternatives.append(token)
	if alternatives.is_empty():
		return ""
	var start_index := randi() % alternatives.size()
	for offset in range(alternatives.size()):
		var action_name := alternatives[(start_index + offset) % alternatives.size()]
		var clip := _find_clip_by_action_name(action_name)
		if not clip.is_empty():
			return clip
	return ""


func _find_clip_by_action_name(action_name: String) -> String:
	var normalized_action := action_name.strip_edges().to_lower()
	if normalized_action.is_empty():
		return ""
	for animation_name in _animation_names:
		if String(animation_name).to_lower() == normalized_action:
			return String(animation_name)
	for animation_name in _animation_names:
		if String(animation_name).to_lower().contains(normalized_action):
			return String(animation_name)
	var tokens := _split_identifier_tokens(action_name)
	var hints: Array[String] = []
	for token in tokens:
		hints.append(str(token))
	return _find_clip_by_hints(hints)


func _read_action_loop(state_name: String, fallback: bool) -> bool:
	var key := "%s_loop" % state_name
	if not _action_row.has(key):
		return fallback
	return bool(_action_row.get(key, fallback))


func _read_action_fps(state_name: String) -> float:
	var state_key := "%s_fps" % state_name
	var raw_value: Variant = _action_row.get(state_key, _action_row.get("default_fps", 30.0))
	if raw_value == null:
		raw_value = _action_row.get("default_fps", 30.0)
	if raw_value == null:
		raw_value = 30.0
	return maxf(float(raw_value), 1.0)


func _read_action_frame(key: String, fallback: int) -> int:
	var raw_value: Variant = _action_row.get(key, fallback)
	if raw_value == null:
		return fallback
	var text := str(raw_value).strip_edges()
	if text.is_empty() or text == "<null>":
		return fallback
	return int(float(text))


func _frame_to_seconds(frame: int, fps: float) -> float:
	if frame < 0:
		return -1.0
	return float(frame) / maxf(fps, 1.0)


func _find_clip_by_hints(hints: Array[String]) -> String:
	for hint in hints:
		var normalized_hint := hint.to_lower()
		for animation_name in _animation_names:
			if String(animation_name).to_lower().contains(normalized_hint):
				return String(animation_name)
	return ""


func _build_attack_timing(attack_duration: float) -> Dictionary:
	var fallback_ratio := 8.0 / 18.0
	var attack_plan: Array = _profile.get("attack_plan", [])
	if attack_plan.is_empty():
		return {"hit_ratio": fallback_ratio}
	var first_plan: Dictionary = attack_plan[0] if attack_plan[0] is Dictionary else {}
	var hit_seconds: Array = first_plan.get("hit_seconds", [])
	if not hit_seconds.is_empty() and attack_duration > 0.0:
		return {"hit_ratio": clampf(float(hit_seconds[0]) / attack_duration, 0.0, 1.0)}
	var hit_frames: Array = first_plan.get("hit_frames", [])
	var fps := maxf(float(first_plan.get("fps", 30.0)), 1.0)
	if not hit_frames.is_empty() and attack_duration > 0.0:
		return {"hit_ratio": clampf((float(hit_frames[0]) / fps) / attack_duration, 0.0, 1.0)}
	return {"hit_ratio": fallback_ratio}


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO or _model_container == null:
		return
	var safe_direction := direction.normalized()
	var yaw := atan2(safe_direction.x, safe_direction.y) + MODEL_FACING_YAW_OFFSET
	_model_container.rotation.y = yaw


func _apply_profile_scale() -> void:
	if _model_container == null:
		return
	var scale_value := maxf(float(_profile.get("scale", 1.0)), 0.01)
	_model_container.scale = Vector3.ONE * scale_value


static func _load_runtime_weapon_socket_target_extent() -> float:
	return _load_runtime_constant_float(
		RUNTIME_WEAPON_SOCKET_TARGET_EXTENT_ID,
		RUNTIME_WEAPON_SOCKET_TARGET_EXTENT_KEY,
		DEFAULT_WEAPON_SOCKET_TARGET_EXTENT
	)


static func _load_runtime_constant_float(row_id: String, row_key: String, fallback_value: float) -> float:
	var cache_key := "%s|%s" % [row_id, row_key]
	if _runtime_constant_float_cache.has(cache_key):
		return float(_runtime_constant_float_cache.get(cache_key, fallback_value))
	if not FileAccess.file_exists(RUNTIME_CONSTANTS_TABLE_PATH):
		var missing_file_value := maxf(fallback_value, 0.0001)
		_runtime_constant_float_cache[cache_key] = missing_file_value
		return missing_file_value
	var file := FileAccess.open(RUNTIME_CONSTANTS_TABLE_PATH, FileAccess.READ)
	if file == null:
		var missing_open_value := maxf(fallback_value, 0.0001)
		_runtime_constant_float_cache[cache_key] = missing_open_value
		return missing_open_value
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Array:
		var invalid_table_value := maxf(fallback_value, 0.0001)
		_runtime_constant_float_cache[cache_key] = invalid_table_value
		return invalid_table_value
	for row_variant in parsed as Array:
		if row_variant is not Dictionary:
			continue
		var row := row_variant as Dictionary
		var current_id := String(row.get("id", "")).strip_edges()
		var current_key := String(row.get("key", "")).strip_edges()
		if current_id != row_id and current_key != row_key:
			continue
		var raw_value: Variant = row.get("value", fallback_value)
		var parsed_value := _parse_runtime_float(raw_value, fallback_value)
		var final_value := maxf(parsed_value, 0.0001)
		_runtime_constant_float_cache[cache_key] = final_value
		return final_value
	var fallback := maxf(fallback_value, 0.0001)
	_runtime_constant_float_cache[cache_key] = fallback
	return fallback


static func _parse_runtime_float(raw_value: Variant, fallback_value: float) -> float:
	if raw_value is int or raw_value is float:
		return float(raw_value)
	var text := String(raw_value).strip_edges()
	if text.is_empty():
		return fallback_value
	if text.is_valid_float():
		return float(text)
	if text.is_valid_int():
		return float(int(text))
	return fallback_value


func _center_model_on_focus() -> void:
	_lock_model_ground_anchor()


func _capture_static_ground_anchor() -> void:
	if _model_root == null:
		_has_static_ground_anchor = false
		return
	var bounds := _measure_model_frame_bounds()
	if bounds.size == Vector3.ZERO:
		_has_static_ground_anchor = false
		return
	_static_ground_anchor = Vector3(
		bounds.position.x + bounds.size.x * 0.5,
		bounds.position.y,
		bounds.position.z + bounds.size.z * 0.5
	)
	_has_static_ground_anchor = true


func _lock_model_ground_anchor() -> void:
	if _model_root == null or _model_container == null:
		return
	if not _has_static_ground_anchor:
		_capture_static_ground_anchor()
	if not _has_static_ground_anchor:
		return
	var container_scale := _model_container.scale
	_model_container.position = Vector3(
		DEFAULT_CAMERA_FOCUS.x - _static_ground_anchor.x * container_scale.x,
		-_static_ground_anchor.y * container_scale.y,
		DEFAULT_CAMERA_FOCUS.z - _static_ground_anchor.z * container_scale.z
	)

func _apply_mesh_render_defaults() -> void:
	if _model_root == null:
		return
	for mesh_instance in _collect_mesh_instances(_model_root):
		mesh_instance.visible = true
		mesh_instance.layers = 1
		mesh_instance.visibility_range_begin = 0.0
		mesh_instance.visibility_range_end = 0.0
		mesh_instance.visibility_range_begin_margin = 0.0
		mesh_instance.visibility_range_end_margin = 0.0
		mesh_instance.extra_cull_margin = 100.0
		mesh_instance.ignore_occlusion_culling = true
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _frame_model() -> void:
	if _model_root == null or _model_container == null or _camera == null:
		return
	var bounds := _measure_model_visual_bounds()
	var focus := _model_container.position + (bounds.position + bounds.size * 0.5) * _model_container.scale
	if bounds.size == Vector3.ZERO:
		focus = DEFAULT_CAMERA_FOCUS
	var scaled_size := Vector3(
		absf(bounds.size.x * _model_container.scale.x),
		absf(bounds.size.y * _model_container.scale.y),
		absf(bounds.size.z * _model_container.scale.z)
	)
	var frame_size := maxf(scaled_size.y, maxf(scaled_size.x, scaled_size.z)) * MODEL_FRAME_PADDING
	_camera.size = maxf(frame_size, 1.2)
	var distance := DEFAULT_CAMERA_DISTANCE
	var horizontal_distance := distance * cos(DEFAULT_CAMERA_PITCH)
	var camera_offset := Vector3(
		horizontal_distance * sin(DEFAULT_CAMERA_YAW),
		distance * sin(DEFAULT_CAMERA_PITCH),
		horizontal_distance * cos(DEFAULT_CAMERA_YAW)
	)
	_camera.near = 0.02
	_camera.far = maxf(distance * 8.0, 32.0)
	_camera.position = focus + camera_offset
	_camera.look_at_from_position(focus + camera_offset, focus, Vector3.UP)


func _attach_profile_weapons() -> void:
	var skeleton := _find_skeleton(_model_root)
	if skeleton == null:
		return
	_attach_weapon(_profile_right_weapon_path(), skeleton, false)
	_attach_weapon(_profile_left_weapon_path(), skeleton, true)


func _attach_weapon(weapon_path: String, skeleton: Skeleton3D, prefer_left_hand: bool) -> void:
	weapon_path = weapon_path.strip_edges()
	if weapon_path.is_empty():
		return
	var weapon := _instantiate_scene_as_node3d(weapon_path)
	if weapon == null:
		return
	var hand_bone_name := _find_hand_bone(skeleton, prefer_left_hand)
	if hand_bone_name.is_empty():
		hand_bone_name = _find_hand_bone(skeleton, not prefer_left_hand)
	if hand_bone_name.is_empty():
		_model_root.add_child(weapon)
		return
	var socket := BoneAttachment3D.new()
	socket.name = "LeftWeaponSocket" if prefer_left_hand else "RightWeaponSocket"
	socket.bone_name = hand_bone_name
	skeleton.add_child(socket)
	var tune_root := Node3D.new()
	tune_root.name = "LeftWeaponTuneRoot" if prefer_left_hand else "RightWeaponTuneRoot"
	socket.add_child(tune_root)
	tune_root.add_child(weapon)
	_apply_weapon_base_transform(weapon, weapon_path, hand_bone_name)
	_apply_weapon_profile_tune(tune_root, prefer_left_hand)
	_apply_weapon_render_defaults(weapon)


func _apply_weapon_base_transform(weapon: Node3D, weapon_path: String, hand_bone_name: String) -> void:
	_normalize_weapon_origin_for_socket(weapon)
	weapon.scale = Vector3.ONE * _compute_weapon_socket_scale(weapon, _load_runtime_weapon_socket_target_extent())
	if hand_bone_name.to_lower().contains("handslot"):
		weapon.position = Vector3.ZERO
		weapon.rotation_degrees = Vector3.ZERO
	else:
		weapon.position = Vector3.ZERO
		weapon.rotation_degrees = Vector3(-90.0, 0.0, 90.0)
	var lower_path := weapon_path.to_lower()
	if lower_path.contains("shield"):
		weapon.position += Vector3(0.01, 0.0, -0.02)
	elif lower_path.contains("staff") or lower_path.contains("bow") or lower_path.contains("crossbow"):
		weapon.position += Vector3(0.0, -0.01, 0.02)
	elif lower_path.contains("sword") or lower_path.contains("dagger") or lower_path.contains("axe"):
		weapon.position += Vector3(0.0, 0.0, 0.01)


func _apply_weapon_render_defaults(weapon: Node3D) -> void:
	for mesh_instance in _collect_mesh_instances(weapon):
		mesh_instance.visible = true
		mesh_instance.layers = 1
		mesh_instance.visibility_range_begin = 0.0
		mesh_instance.visibility_range_end = 0.0
		mesh_instance.visibility_range_begin_margin = 0.0
		mesh_instance.visibility_range_end_margin = 0.0
		mesh_instance.extra_cull_margin = 100.0
		mesh_instance.ignore_occlusion_culling = true
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _apply_weapon_profile_tune(tune_root: Node3D, prefer_left_hand: bool) -> void:
	var prefix := "left_weapon" if prefer_left_hand else "weapon"
	if prefer_left_hand:
		prefix = "left_weapon"
	tune_root.position = _read_weapon_tune_position(prefix)
	tune_root.rotation_degrees = Vector3(
		float(_profile.get("%s_tune_rot_x" % prefix, 0.0)),
		float(_profile.get("%s_tune_rot_y" % prefix, 0.0)),
		float(_profile.get("%s_tune_rot_z" % prefix, 0.0))
	)
	tune_root.scale = Vector3(
		maxf(float(_profile.get("%s_tune_scale_x" % prefix, 1.0)), 0.01),
		maxf(float(_profile.get("%s_tune_scale_y" % prefix, 1.0)), 0.01),
		maxf(float(_profile.get("%s_tune_scale_z" % prefix, 1.0)), 0.01)
	)


func _read_weapon_tune_position(prefix: String) -> Vector3:
	var tune_position := Vector3(
		float(_profile.get("%s_tune_pos_x" % prefix, 0.0)),
		float(_profile.get("%s_tune_pos_y" % prefix, 0.0)),
		float(_profile.get("%s_tune_pos_z" % prefix, 0.0))
	)
	if str(_profile.get("weapon_tune_units", "")).strip_edges() == WEAPON_TUNE_UNITS:
		return tune_position
	if tune_position.length() > LEGACY_WEAPON_TUNE_POSITION_THRESHOLD:
		return tune_position * LEGACY_WEAPON_TUNE_POSITION_SCALE
	return tune_position


func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _find_hand_bone(skeleton: Skeleton3D, prefer_left_hand: bool) -> String:
	var hints := LEFT_HAND_HINTS if prefer_left_hand else RIGHT_HAND_HINTS
	var fallback_side_token := "l" if prefer_left_hand else "r"
	var fallback_word := "left" if prefer_left_hand else "right"
	for hint in hints:
		for bone_index in skeleton.get_bone_count():
			var bone_name := skeleton.get_bone_name(bone_index)
			if _normalize_bone_name(bone_name) == _normalize_bone_name(hint):
				return bone_name
	for bone_index in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(bone_index)
		var normalized := _normalize_bone_name(bone_name)
		if normalized.contains("hand") and (normalized.contains(fallback_word) or normalized.contains("hand%s" % fallback_side_token) or normalized.contains("%shand" % fallback_side_token)):
			return bone_name
	return ""


func _normalize_bone_name(raw_name: String) -> String:
	var text := raw_name.strip_edges().to_lower()
	for token in [" ", "_", ".", "-", ":"]:
		text = text.replace(token, "")
	return text


func _normalize_weapon_origin_for_socket(weapon: Node3D) -> void:
	var meshes := _collect_mesh_instances(weapon)
	if meshes.is_empty():
		return
	var bounds := _measure_node3d_local_bounds(weapon)
	if bounds.size == Vector3.ZERO:
		return
	var grip_point := _pick_weapon_grip_point(bounds)
	for child in weapon.get_children():
		if child is Node3D:
			(child as Node3D).position -= grip_point


func _pick_weapon_grip_point(bounds: AABB) -> Vector3:
	var min_bounds := bounds.position
	var max_bounds := bounds.position + bounds.size
	var center := bounds.position + bounds.size * 0.5
	var extents := [
		{"axis": 0, "size": bounds.size.x},
		{"axis": 1, "size": bounds.size.y},
		{"axis": 2, "size": bounds.size.z},
	]
	extents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("size", 0.0)) > float(b.get("size", 0.0))
	)
	var longest := float(extents[0].get("size", 0.0))
	var second := maxf(float(extents[1].get("size", 0.0)), 0.0001)
	var grip := center
	if longest / second >= WEAPON_ELONGATED_GRIP_RATIO:
		match int(extents[0].get("axis", 0)):
			0:
				grip.x = max_bounds.x
			1:
				grip.y = max_bounds.y
			2:
				grip.z = max_bounds.z
		return grip
	grip.z = min_bounds.z
	return grip


func _compute_weapon_socket_scale(weapon: Node3D, target_global_extent: float) -> float:
	var bounds := _measure_node3d_local_bounds(weapon)
	if bounds.size == Vector3.ZERO:
		return 1.0
	var max_extent := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if max_extent <= 0.0001:
		return 1.0
	var parent_scale := 1.0
	var parent_node := weapon.get_parent()
	if parent_node is Node3D and (parent_node as Node3D).is_inside_tree():
		parent_scale = _average_basis_scale((parent_node as Node3D).global_transform.basis)
	if parent_scale <= 0.0001:
		parent_scale = 1.0
	return clampf(target_global_extent / (max_extent * parent_scale), 0.01, 500.0)


func _average_basis_scale(basis: Basis) -> float:
	return (basis.x.length() + basis.y.length() + basis.z.length()) / 3.0


func _measure_model_frame_bounds() -> AABB:
	if _model_root == null:
		return AABB()
	var transformed_bounds := _measure_node3d_bounds(_model_root, false)
	var raw_bounds := _measure_node3d_raw_mesh_bounds(_model_root, false)
	if raw_bounds.size != Vector3.ZERO and (transformed_bounds.size == Vector3.ZERO or raw_bounds.size.y > transformed_bounds.size.y * 5.0):
		return raw_bounds
	return transformed_bounds


func _measure_model_visual_bounds() -> AABB:
	if _model_root == null:
		return AABB()
	var transformed_bounds := _measure_node3d_bounds(_model_root, true)
	var raw_bounds := _measure_node3d_raw_mesh_bounds(_model_root, true)
	if raw_bounds.size != Vector3.ZERO and (transformed_bounds.size == Vector3.ZERO or raw_bounds.size.y > transformed_bounds.size.y * 5.0):
		return raw_bounds
	return transformed_bounds


func _measure_runtime_anchor_bounds() -> AABB:
	if _model_root == null:
		return AABB()
	var bounds := _measure_node3d_bounds(_model_root, false)
	if bounds.size != Vector3.ZERO:
		return bounds
	return _measure_model_frame_bounds()


func _measure_node3d_raw_mesh_bounds(root_node: Node3D, include_weapon_meshes: bool = true) -> AABB:
	var meshes := _collect_mesh_instances(root_node, include_weapon_meshes)
	var has_bounds := false
	var min_bounds := Vector3(INF, INF, INF)
	var max_bounds := Vector3(-INF, -INF, -INF)
	for mesh_instance in meshes:
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		for corner in _aabb_corners(mesh.get_aabb()):
			min_bounds = min_bounds.min(corner)
			max_bounds = max_bounds.max(corner)
			has_bounds = true
	if not has_bounds:
		return AABB()
	return AABB(min_bounds, max_bounds - min_bounds)


func _measure_node3d_bounds(root_node: Node3D, include_weapon_meshes: bool = true) -> AABB:
	var meshes := _collect_mesh_instances(root_node, include_weapon_meshes)
	var has_bounds := false
	var min_bounds := Vector3(INF, INF, INF)
	var max_bounds := Vector3(-INF, -INF, -INF)
	for mesh_instance in meshes:
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		var aabb := mesh.get_aabb()
		var mesh_transform := _get_node3d_transform_relative(mesh_instance, root_node)
		for corner in _aabb_corners(aabb):
			var point: Vector3 = mesh_transform * corner
			min_bounds = min_bounds.min(point)
			max_bounds = max_bounds.max(point)
			has_bounds = true
	if not has_bounds:
		return AABB()
	return AABB(min_bounds, max_bounds - min_bounds)


func _measure_node3d_local_bounds(root_node: Node3D, include_weapon_meshes: bool = true) -> AABB:
	var meshes := _collect_mesh_instances(root_node, include_weapon_meshes)
	var has_bounds := false
	var min_bounds := Vector3(INF, INF, INF)
	var max_bounds := Vector3(-INF, -INF, -INF)
	for mesh_instance in meshes:
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		var aabb := mesh.get_aabb()
		var mesh_transform := _get_node3d_transform_relative(mesh_instance, root_node)
		for corner in _aabb_corners(aabb):
			var point: Vector3 = mesh_transform * corner
			min_bounds = min_bounds.min(point)
			max_bounds = max_bounds.max(point)
			has_bounds = true
	if not has_bounds:
		return AABB()
	return AABB(min_bounds, max_bounds - min_bounds)


func _get_node3d_transform_relative(node: Node3D, ancestor: Node3D) -> Transform3D:
	var chain: Array[Node3D] = []
	var current: Node = node
	while current != null and current is Node3D:
		chain.append(current as Node3D)
		if current == ancestor:
			break
		current = current.get_parent()
	var result := Transform3D.IDENTITY
	for index in range(chain.size() - 1, -1, -1):
		result = result * chain[index].transform
	return result


func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	return [
		Vector3(aabb.position.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.position.y, aabb.position.z + aabb.size.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb.position.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z + aabb.size.z),
		Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb.size.z),
		aabb.position + aabb.size,
	]


func _collect_mesh_instances(root: Node, include_weapon_meshes: bool = true) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances_recursive(root, include_weapon_meshes, false, meshes)
	return meshes


func _collect_mesh_instances_recursive(node: Node, include_weapon_meshes: bool, weapon_branch: bool, output: Array[MeshInstance3D]) -> void:
	var in_weapon_branch := weapon_branch or _is_weapon_attachment_node(node)
	if node is MeshInstance3D and (include_weapon_meshes or not in_weapon_branch):
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_mesh_instances_recursive(child, include_weapon_meshes, in_weapon_branch, output)


func _is_weapon_attachment_node(node: Node) -> bool:
	var node_name := String(node.name).to_lower()
	return node_name.contains("weaponsocket") or node_name.contains("weapontuneroot")


static func _is_project_resource_path(path: String) -> bool:
	return path.begins_with("res://") or path.begins_with("user://")
