extends Node2D
class_name UnitSpriteAnimator

const DEFAULT_FPS := 8.0
const ATTACK_FPS := 12.0
const DEATH_FPS := 8.0
const ANIM_CONFIG_FILE := "anim_config.json"

@export var model_root_dir := "res://assets/enemies/Models_2d"
@export var visual_offset := Vector2.ZERO
@export var visual_ground_offset := 10.0
@export var display_scale := 1.0

var _sprite: Sprite2D
var _model_id: StringName = &""
var _model_dir := ""
var _available_files: Array[String] = []
var _anim_config: Dictionary = {}
var _current_state := "idle"
var _current_files: Array[String] = []
var _current_frame_width := 0.0
var _current_frame_height := 0.0
var _current_file_index := 0
var _current_texture: Texture2D
var _current_regions: Array[Rect2] = []
var _frame_index := 0
var _frame_elapsed := 0.0
var _fps := DEFAULT_FPS
var _loop := true
var _last_direction := Vector2.DOWN
var _attack_locked := false
var _dead := false
var _runtime_active := true
var _dissolve_progress := 0.0
var _defaults_captured := false
var _default_visual_offset := Vector2.ZERO
var _default_visual_ground_offset := 10.0
var _default_display_scale := 1.0


func _ready() -> void:
	_capture_visual_defaults()
	_ensure_sprite()
	set_process(true)


func configure_model_id(model_id: StringName) -> bool:
	var clean_id := String(model_id).strip_edges()
	if clean_id.is_empty():
		return false
	if String(_model_id).strip_edges() == clean_id and not _available_files.is_empty():
		reset_runtime_state(_last_direction, true)
		return true

	var resolved_dir := _resolve_model_dir(clean_id)
	if resolved_dir.is_empty():
		return false

	_model_id = StringName(clean_id)
	_model_dir = resolved_dir
	_available_files = _collect_png_files(_model_dir)
	if _available_files.is_empty():
		return false
	_capture_visual_defaults()
	_reset_visual_defaults()
	_anim_config = _load_anim_config(_model_dir)
	_apply_anim_config_defaults()

	_dead = false
	_attack_locked = false
	_last_direction = Vector2.DOWN
	_play_state("idle", _last_direction, true)
	return true


func ensure_model_ready() -> void:
	_ensure_sprite()


func set_motion_state(direction: Vector2, is_moving: bool) -> void:
	if _dead or _attack_locked:
		return
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_play_state("run" if is_moving else "idle", _last_direction)


func play_attack(direction: Vector2, _attack_duration: float = 0.0) -> Dictionary:
	start_attack_preview(direction)
	return {"hit_ratio": 0.45}


func start_attack_preview(direction: Vector2) -> void:
	if _dead:
		return
	_attack_locked = true
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_play_state("attack", _last_direction, true)


func set_attack_preview_progress(direction: Vector2, _progress: float) -> void:
	start_attack_preview(direction)


func play_attack_hit(direction: Vector2) -> void:
	start_attack_preview(direction)


func set_attack_recover_progress(direction: Vector2, _progress: float) -> void:
	start_attack_preview(direction)


func stop_attack(direction: Vector2) -> void:
	if _dead:
		return
	_attack_locked = false
	if direction != Vector2.ZERO:
		_last_direction = direction.normalized()
	_play_state("idle", _last_direction, true)


func cancel_attack() -> void:
	stop_attack(_last_direction)


func play_death() -> void:
	_dead = true
	_attack_locked = false
	_play_state("death", _last_direction, true)


func play_hit() -> void:
	if _dead:
		return
	var previous_modulate := modulate
	modulate = Color(1.0, 0.72, 0.72, previous_modulate.a)


func set_stunned(_enabled: bool) -> void:
	pass


func play_spawn() -> void:
	if _dead:
		return
	_play_state("idle", _last_direction, true)


func set_runtime_active(enabled: bool) -> void:
	_runtime_active = enabled
	visible = enabled
	set_process(enabled)


func reset_runtime_state(default_direction: Vector2 = Vector2.DOWN, force_idle: bool = true) -> void:
	_dead = false
	_attack_locked = false
	_dissolve_progress = 0.0
	modulate = Color(1, 1, 1, 1)
	_last_direction = default_direction.normalized() if default_direction != Vector2.ZERO else Vector2.DOWN
	if force_idle:
		_play_state("idle", _last_direction, true)


func set_dissolve_progress(progress: float) -> void:
	_dissolve_progress = clampf(progress, 0.0, 1.0)
	modulate.a = 1.0 - _dissolve_progress


func set_visual_height(offset_y: float) -> void:
	position = visual_offset + Vector2(0.0, offset_y)


func start_jump(_direction: Vector2) -> void:
	pass


func set_jump_direction(_direction: Vector2) -> void:
	pass


func stop_jump(direction: Vector2, is_moving: bool) -> void:
	set_motion_state(direction, is_moving)


func set_jump_phase(_phase_index: int) -> void:
	pass


func get_jump_motion_config() -> Dictionary:
	return {}


func play_victory() -> void:
	_play_state("idle", _last_direction, true)


func start_showcase() -> void:
	_play_state("idle", _last_direction, true)


func play_selection_preview_intro() -> void:
	_play_state("idle", _last_direction, true)


func apply_selection_preview_preset() -> void:
	_play_state("idle", _last_direction, true)


func stop_showcase() -> void:
	pass


func set_showcase_spin_speed(_speed: float) -> void:
	pass


func rotate_preview(delta_yaw: float) -> void:
	if _sprite != null and absf(delta_yaw) > 0.001:
		_sprite.flip_h = delta_yaw < 0.0


func apply_profile_overrides(_overrides: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	if not _runtime_active or _current_regions.is_empty():
		return
	_frame_elapsed += delta
	var frame_duration := 1.0 / maxf(_fps, 0.01)
	while _frame_elapsed >= frame_duration:
		_frame_elapsed -= frame_duration
		_advance_frame()


func _ensure_sprite() -> void:
	if _sprite != null and is_instance_valid(_sprite):
		return
	_sprite = Sprite2D.new()
	_sprite.name = "FrameSprite"
	_sprite.centered = false
	_sprite.region_enabled = true
	add_child(_sprite)


func _play_state(state: String, direction: Vector2, force_restart := false) -> void:
	_ensure_sprite()
	var next_files := _select_files_for_state(state, direction)
	if next_files.is_empty() and state != "idle":
		next_files = _select_files_for_state("idle", direction)
		state = "idle"
	if next_files.is_empty():
		return

	var should_restart := force_restart or state != _current_state or next_files != _current_files
	_current_state = state
	_current_files = next_files
	var state_config := _get_animation_config(state, direction)
	_current_frame_width = _get_float_from_config(state_config, "frame_width", 0.0)
	_current_frame_height = _get_float_from_config(state_config, "frame_height", 0.0)
	_fps = _get_state_fps(state)
	_loop = _get_bool_from_config(state_config, "loop", state != "death")
	if should_restart:
		_current_file_index = 0
		_frame_index = 0
		_frame_elapsed = 0.0
		_load_current_file()


func _advance_frame() -> void:
	if _current_regions.is_empty():
		return
	_frame_index += 1
	if _frame_index >= _current_regions.size():
		if _current_files.size() > 1 and _current_regions.size() <= 1:
			_current_file_index += 1
			if _current_file_index >= _current_files.size():
				if _loop:
					_current_file_index = 0
				else:
					_current_file_index = _current_files.size() - 1
			_frame_index = 0
			_load_current_file()
			return
		if _loop:
			_frame_index = 0
		else:
			_frame_index = _current_regions.size() - 1
	_apply_frame()


func _load_current_file() -> void:
	if _current_files.is_empty():
		return
	_current_file_index = clampi(_current_file_index, 0, _current_files.size() - 1)
	var texture := load(_current_files[_current_file_index]) as Texture2D
	if texture == null:
		return
	_current_texture = texture
	_current_regions = _build_regions_for_texture(texture)
	_frame_index = clampi(_frame_index, 0, max(_current_regions.size() - 1, 0))
	_apply_frame()


func _apply_frame() -> void:
	if _sprite == null or _current_texture == null or _current_regions.is_empty():
		return
	var region := _current_regions[clampi(_frame_index, 0, _current_regions.size() - 1)]
	_sprite.texture = _current_texture
	_sprite.region_rect = region
	_sprite.scale = Vector2.ONE * display_scale
	_sprite.offset = Vector2(-region.size.x * 0.5, -region.size.y + visual_ground_offset)
	position = visual_offset
	if _last_direction.x < -0.01:
		_sprite.flip_h = true
	elif _last_direction.x > 0.01:
		_sprite.flip_h = false


func _build_regions_for_texture(texture: Texture2D) -> Array[Rect2]:
	var regions: Array[Rect2] = []
	var size := texture.get_size()
	if _current_frame_width > 0.0 and _current_frame_height > 0.0:
		var frame_width := int(_current_frame_width)
		var frame_height := int(_current_frame_height)
		var columns := maxi(int(size.x) / frame_width, 1)
		var rows := maxi(int(size.y) / frame_height, 1)
		for y in rows:
			for x in columns:
				regions.append(Rect2(Vector2(frame_width * x, frame_height * y), Vector2(frame_width, frame_height)))
	elif size.x > size.y and int(size.x) % int(size.y) == 0:
		var frame_size := size.y
		var frame_count := int(size.x / frame_size)
		for i in frame_count:
			regions.append(Rect2(Vector2(frame_size * float(i), 0.0), Vector2(frame_size, frame_size)))
	else:
		regions.append(Rect2(Vector2.ZERO, size))
	return regions


func _resolve_model_dir(model_id: String) -> String:
	var root := model_root_dir.trim_suffix("/")
	var dir := DirAccess.open(root)
	if dir == null:
		return ""
	for child_name in dir.get_directories():
		var id_part := child_name.split("_", false, 1)[0]
		if id_part == model_id:
			return "%s/%s" % [root, child_name]
	return ""


func _collect_png_files(root: String) -> Array[String]:
	var results: Array[String] = []
	_collect_png_files_recursive(root, results)
	results.sort()
	return results


func _collect_png_files_recursive(root: String, results: Array[String]) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	for file_name in dir.get_files():
		if file_name.get_extension().to_lower() == "png":
			results.append("%s/%s" % [root, file_name])
	for child_dir in dir.get_directories():
		_collect_png_files_recursive("%s/%s" % [root, child_dir], results)


func _select_files_for_state(state: String, direction: Vector2) -> Array[String]:
	var configured_files := _select_configured_files_for_state(state, direction)
	if not configured_files.is_empty():
		return configured_files

	var keyword_matches: Array[String] = []
	var keywords := _get_state_keywords(state)
	for file_path in _available_files:
		var file_lower := file_path.get_file().to_lower()
		for keyword in keywords:
			if file_lower.contains(keyword):
				keyword_matches.append(file_path)
				break
	if keyword_matches.is_empty() and state == "idle":
		keyword_matches = _available_files.duplicate()
	if keyword_matches.is_empty():
		return []

	var direction_matches := _filter_direction_files(keyword_matches, direction)
	if not direction_matches.is_empty():
		return direction_matches
	return keyword_matches


func _select_configured_files_for_state(state: String, direction: Vector2) -> Array[String]:
	var state_config := _get_animation_config(state, direction)
	if state_config.is_empty():
		return []

	var raw_files = state_config.get("files", state_config.get("file", []))
	var configured_files: Array[String] = []
	if raw_files is Array:
		for raw_file in raw_files:
			_append_configured_file(configured_files, str(raw_file))
	else:
		_append_configured_file(configured_files, str(raw_files))
	return configured_files


func _append_configured_file(target: Array[String], raw_file: String) -> void:
	var file_name := raw_file.strip_edges()
	if file_name.is_empty():
		return

	var path := file_name
	if not path.begins_with("res://"):
		path = "%s/%s" % [_model_dir, file_name]
	if ResourceLoader.exists(path):
		target.append(path)


func _get_animation_config(state: String, direction: Vector2) -> Dictionary:
	if _anim_config.is_empty():
		return {}

	var result: Dictionary = {}
	var animations = _anim_config.get("animations", {})
	if animations is Dictionary and (animations as Dictionary).has(state):
		var state_value = (animations as Dictionary).get(state)
		if state_value is Dictionary:
			result.merge(state_value as Dictionary, true)

	var direction_configs = _anim_config.get("directions", {})
	if direction_configs is Dictionary:
		var token := _get_direction_token(direction)
		var direction_value = (direction_configs as Dictionary).get(token, {})
		if direction_value is Dictionary and (direction_value as Dictionary).has(state):
			var direction_state_value = (direction_value as Dictionary).get(state)
			if direction_state_value is Dictionary:
				result.merge(direction_state_value as Dictionary, true)
	return result


func _filter_direction_files(files: Array[String], direction: Vector2) -> Array[String]:
	var token := _get_direction_token(direction)
	if token.is_empty():
		return []
	var matches: Array[String] = []
	for file_path in files:
		var lower_name := file_path.get_file().to_lower()
		if lower_name.contains(token):
			matches.append(file_path)
	if matches.is_empty() and token == "left":
		for file_path in files:
			var lower_name := file_path.get_file().to_lower()
			if lower_name.contains("right"):
				matches.append(file_path)
	return matches


func _get_direction_token(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		direction = _last_direction
	if direction == Vector2.ZERO:
		return "down"
	var angle := direction.angle()
	if angle < 0.0:
		angle += TAU
	var sector := int(round(angle / (PI / 4.0))) % 8
	match sector:
		0:
			return "right"
		1:
			return "downright"
		2:
			return "down"
		3:
			return "downright"
		4:
			return "right"
		5:
			return "upright"
		6:
			return "up"
		_:
			return "upright"


func _get_state_keywords(state: String) -> PackedStringArray:
	match state:
		"run":
			return PackedStringArray(["run", "walk", "move"])
		"attack":
			return PackedStringArray(["attack", "shoot", "melee", "cast"])
		"death":
			return PackedStringArray(["death", "die"])
		"hit":
			return PackedStringArray(["hit", "damage"])
		"spawn":
			return PackedStringArray(["spawn"])
		_:
			return PackedStringArray(["idle", "stand", "tower"])


func _get_state_fps(state: String) -> float:
	var state_config := _get_animation_config(state, _last_direction)
	var configured_fps := _get_float_from_config(state_config, "fps", 0.0)
	if configured_fps > 0.0:
		return configured_fps

	match state:
		"attack":
			return ATTACK_FPS
		"death":
			return DEATH_FPS
		_:
			return DEFAULT_FPS


func _load_anim_config(model_dir: String) -> Dictionary:
	var config_path := "%s/%s" % [model_dir, ANIM_CONFIG_FILE]
	if not FileAccess.file_exists(config_path):
		return {}

	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open animation config: %s" % config_path)
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		push_warning("Invalid animation config %s: %s" % [config_path, json.get_error_message()])
		return {}

	var parsed = json.data
	if parsed is Dictionary:
		return parsed as Dictionary
	push_warning("Animation config root must be a Dictionary: %s" % config_path)
	return {}


func _apply_anim_config_defaults() -> void:
	if _anim_config.is_empty():
		return
	display_scale = _get_float_from_config(_anim_config, "display_scale", display_scale)
	visual_ground_offset = _get_float_from_config(_anim_config, "visual_ground_offset", visual_ground_offset)
	var offset_value = _anim_config.get("visual_offset", null)
	if offset_value is Array and (offset_value as Array).size() >= 2:
		visual_offset = Vector2(float((offset_value as Array)[0]), float((offset_value as Array)[1]))


func _capture_visual_defaults() -> void:
	if _defaults_captured:
		return
	_default_visual_offset = visual_offset
	_default_visual_ground_offset = visual_ground_offset
	_default_display_scale = display_scale
	_defaults_captured = true


func _reset_visual_defaults() -> void:
	visual_offset = _default_visual_offset
	visual_ground_offset = _default_visual_ground_offset
	display_scale = _default_display_scale


func _get_float_from_config(config: Dictionary, key: String, default_value: float) -> float:
	if not config.has(key):
		return default_value
	var value = config.get(key)
	if value is float or value is int:
		return float(value)
	var text := str(value).strip_edges()
	if text.is_valid_float():
		return text.to_float()
	return default_value


func _get_bool_from_config(config: Dictionary, key: String, default_value: bool) -> bool:
	if not config.has(key):
		return default_value
	var value = config.get(key)
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	if text in ["1", "true", "yes", "y"]:
		return true
	if text in ["0", "false", "no", "n"]:
		return false
	return default_value
