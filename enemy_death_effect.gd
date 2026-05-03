extends Node2D
class_name EnemyDeathEffect

const ENEMY_MODEL_ROOT := "res://assets/enemies/Models_2d"
const DEFAULT_DEATH_MODEL_ID := "0"
const ANIM_CONFIG_FILE := "anim_config.json"
const DEFAULT_FPS := 8.0
const HOLD_AND_FADE_SECONDS := 1.0
const DEATH_KEYWORDS := ["dead", "death", "die"]

var _sprite: Sprite2D
var _model_dir := ""
var _anim_config: Dictionary = {}
var _files: Array[String] = []
var _current_file_index := 0
var _current_texture: Texture2D
var _regions: Array[Rect2] = []
var _frame_index := 0
var _frame_elapsed := 0.0
var _fps := DEFAULT_FPS
var _direction := Vector2.DOWN
var _frame_width := 0.0
var _frame_height := 0.0
var _display_scale := 1.0
var _visual_offset := Vector2.ZERO
var _visual_ground_offset := 10.0
var _holding_last_frame := false
var _hold_elapsed := 0.0


func setup(model_id: StringName, world_position: Vector2, direction: Vector2) -> bool:
	global_position = world_position
	_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.DOWN
	modulate = Color(1, 1, 1, 1)
	_holding_last_frame = false
	_hold_elapsed = 0.0
	_frame_elapsed = 0.0
	_frame_index = 0
	_current_file_index = 0

	var clean_model_id := String(model_id).strip_edges()
	_model_dir = _resolve_model_dir(clean_model_id)
	_files = _select_death_files(_model_dir, _direction)
	if _files.is_empty():
		_model_dir = _resolve_model_dir(DEFAULT_DEATH_MODEL_ID)
		_files = _select_death_files(_model_dir, _direction)
	if _files.is_empty():
		return false

	_anim_config = _load_anim_config(_model_dir)
	_apply_anim_config()
	_ensure_sprite()
	_load_current_file()
	_update_draw_order()
	set_process(true)
	return true


func _process(delta: float) -> void:
	if _holding_last_frame:
		_hold_elapsed += delta
		var fade_t := clampf(_hold_elapsed / HOLD_AND_FADE_SECONDS, 0.0, 1.0)
		modulate.a = 1.0 - fade_t
		if fade_t >= 1.0:
			queue_free()
		return

	if _regions.is_empty():
		return

	_frame_elapsed += delta
	var frame_duration := 1.0 / maxf(_fps, 0.01)
	while _frame_elapsed >= frame_duration:
		_frame_elapsed -= frame_duration
		_advance_frame()
		if _holding_last_frame:
			return


func _ensure_sprite() -> void:
	if _sprite != null and is_instance_valid(_sprite):
		return
	_sprite = Sprite2D.new()
	_sprite.name = "DeathSprite"
	_sprite.centered = false
	_sprite.region_enabled = true
	add_child(_sprite)


func _load_current_file() -> void:
	if _files.is_empty():
		return
	_current_file_index = clampi(_current_file_index, 0, _files.size() - 1)
	var texture := load(_files[_current_file_index]) as Texture2D
	if texture == null:
		return
	_current_texture = texture
	_regions = _build_regions(texture)
	_frame_index = 0
	_apply_frame()


func _advance_frame() -> void:
	_frame_index += 1
	if _frame_index < _regions.size():
		_apply_frame()
		return

	if _current_file_index < _files.size() - 1:
		_current_file_index += 1
		_load_current_file()
		return

	_frame_index = maxi(_regions.size() - 1, 0)
	_apply_frame()
	_holding_last_frame = true
	_hold_elapsed = 0.0


func _apply_frame() -> void:
	if _sprite == null or _current_texture == null or _regions.is_empty():
		return
	var region := _regions[clampi(_frame_index, 0, _regions.size() - 1)]
	_sprite.texture = _current_texture
	_sprite.region_rect = region
	_sprite.scale = Vector2.ONE * _display_scale
	_sprite.offset = Vector2(-region.size.x * 0.5, -region.size.y + _visual_ground_offset)
	_sprite.position = _visual_offset
	if _direction.x < -0.01:
		_sprite.flip_h = true
	elif _direction.x > 0.01:
		_sprite.flip_h = false


func _build_regions(texture: Texture2D) -> Array[Rect2]:
	var regions: Array[Rect2] = []
	var size := texture.get_size()
	if _frame_width > 0.0 and _frame_height > 0.0:
		regions = _build_grid_regions(size, int(_frame_width), int(_frame_height))
	elif int(size.x) * 2 == int(size.y) * 5:
		regions = _build_grid_regions(size, int(size.x / 5.0), int(size.y / 2.0))
	elif size.x > size.y and int(size.x) % int(size.y) == 0:
		var frame_size := int(size.y)
		var frame_count := int(size.x / size.y)
		for index in frame_count:
			regions.append(Rect2(Vector2(frame_size * index, 0), Vector2(frame_size, frame_size)))
	else:
		regions.append(Rect2(Vector2.ZERO, size))
	return _apply_skip_frames(regions)


func _build_grid_regions(texture_size: Vector2, frame_width: int, frame_height: int) -> Array[Rect2]:
	var regions: Array[Rect2] = []
	var columns := maxi(int(floor(texture_size.x / float(frame_width))), 1)
	var rows := maxi(int(floor(texture_size.y / float(frame_height))), 1)
	for y in rows:
		for x in columns:
			regions.append(Rect2(Vector2(frame_width * x, frame_height * y), Vector2(frame_width, frame_height)))
	return regions


func _apply_skip_frames(regions: Array[Rect2]) -> Array[Rect2]:
	var state_config := _get_animation_config("death", _direction)
	var skip_frames := _get_int_array_from_config(state_config, "skip_frames")
	if skip_frames.is_empty():
		return regions

	var filtered: Array[Rect2] = []
	for index in regions.size():
		if not skip_frames.has(index + 1):
			filtered.append(regions[index])
	return filtered if not filtered.is_empty() else regions


func _select_death_files(model_dir: String, direction: Vector2) -> Array[String]:
	if model_dir.is_empty():
		return []

	var configured_files := _select_configured_death_files(model_dir, direction)
	if not configured_files.is_empty():
		return configured_files

	var all_files := _collect_png_files(model_dir)
	var matches: Array[String] = []
	for file_path in all_files:
		var lower_name := file_path.get_file().to_lower()
		for keyword in DEATH_KEYWORDS:
			if lower_name.contains(keyword):
				matches.append(file_path)
				break
	if matches.is_empty():
		return []

	var direction_matches := _filter_direction_files(matches, direction)
	if not direction_matches.is_empty():
		return direction_matches
	return matches


func _select_configured_death_files(model_dir: String, direction: Vector2) -> Array[String]:
	_anim_config = _load_anim_config(model_dir)
	var state_config := _get_animation_config("death", direction)
	var raw_files = state_config.get("files", state_config.get("file", []))
	var result: Array[String] = []
	if raw_files is Array:
		for raw_file in raw_files:
			_append_configured_file(result, model_dir, str(raw_file))
	else:
		_append_configured_file(result, model_dir, str(raw_files))
	return result


func _append_configured_file(target: Array[String], model_dir: String, raw_file: String) -> void:
	var file_name := raw_file.strip_edges()
	if file_name.is_empty():
		return
	var path := file_name
	if not path.begins_with("res://"):
		path = "%s/%s" % [model_dir, file_name]
	if ResourceLoader.exists(path):
		target.append(path)


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


func _filter_direction_files(files: Array[String], direction: Vector2) -> Array[String]:
	var token := _get_direction_token(direction)
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


func _resolve_model_dir(model_id: String) -> String:
	if model_id.is_empty():
		return ""
	var dir := DirAccess.open(ENEMY_MODEL_ROOT)
	if dir == null:
		return ""
	for child_name in dir.get_directories():
		var id_part := child_name.split("_", false, 1)[0]
		if id_part == model_id:
			return "%s/%s" % [ENEMY_MODEL_ROOT, child_name]
	return ""


func _load_anim_config(model_dir: String) -> Dictionary:
	var config_path := "%s/%s" % [model_dir, ANIM_CONFIG_FILE]
	if not FileAccess.file_exists(config_path):
		return {}

	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		return {}

	return json.data as Dictionary if json.data is Dictionary else {}


func _apply_anim_config() -> void:
	var state_config := _get_animation_config("death", _direction)
	_display_scale = _get_float_from_config(_anim_config, "display_scale", 1.0)
	_visual_ground_offset = _get_float_from_config(_anim_config, "visual_ground_offset", 10.0)
	_visual_offset = _get_vector2_array(_anim_config.get("visual_offset", [0, 0]), Vector2.ZERO)
	_frame_width = _get_float_from_config(state_config, "frame_width", 0.0)
	_frame_height = _get_float_from_config(state_config, "frame_height", 0.0)
	_fps = _get_float_from_config(state_config, "fps", DEFAULT_FPS)


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


func _get_direction_token(direction: Vector2) -> String:
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


func _get_int_array_from_config(config: Dictionary, key: String) -> Array[int]:
	if not config.has(key):
		return []
	var value = config.get(key)
	var result: Array[int] = []
	if value is Array:
		for item in value:
			if item is int or item is float:
				var numeric_value := int(item)
				if numeric_value > 0 and not result.has(numeric_value):
					result.append(numeric_value)
			elif str(item).strip_edges().is_valid_int():
				var text_value := str(item).strip_edges().to_int()
				if text_value > 0 and not result.has(text_value):
					result.append(text_value)
	elif value is String:
		for part in String(value).split(",", false):
			var clean := part.strip_edges()
			if clean.is_valid_int():
				var parsed := clean.to_int()
				if parsed > 0 and not result.has(parsed):
					result.append(parsed)
	result.sort()
	return result


func _get_vector2_array(value, default_value: Vector2) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float((value as Array)[0]), float((value as Array)[1]))
	return default_value


func _update_draw_order() -> void:
	z_as_relative = false
	z_index = clampi(2000 + int(round(global_position.y)), 1, 4095)
