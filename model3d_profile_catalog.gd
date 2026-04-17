extends RefCounted
class_name Model3DProfileCatalog

const PROFILE_INDEX_PATH := "res://assets/heroes/models_3d/index.json"

static var _cache_loaded := false
static var _profile_cache: Dictionary = {}


static func reload() -> void:
	_cache_loaded = false
	_profile_cache.clear()
	_ensure_cache_loaded()


static func has_profile(model_id: StringName) -> bool:
	_ensure_cache_loaded()
	var key := _normalize_model_id(model_id)
	return not key.is_empty() and _profile_cache.has(key)


static func get_profile(model_id: StringName) -> Dictionary:
	_ensure_cache_loaded()
	var key := _normalize_model_id(model_id)
	if key.is_empty():
		return {}
	var raw_profile: Variant = _profile_cache.get(key, {})
	if raw_profile is Dictionary:
		return (raw_profile as Dictionary).duplicate(true)
	return {}


static func list_profile_ids() -> PackedStringArray:
	_ensure_cache_loaded()
	var ids: PackedStringArray = []
	for raw_key in _profile_cache.keys():
		ids.append(String(raw_key))
	ids.sort()
	return ids


static func get_attack_plan(model_id: StringName) -> Array[Dictionary]:
	var profile := get_profile(model_id)
	var raw_plan: Variant = profile.get("attack_plan", [])
	if raw_plan is not Array:
		return []

	var plan: Array[Dictionary] = []
	for raw_entry in raw_plan:
		if raw_entry is Dictionary:
			plan.append((raw_entry as Dictionary).duplicate(true))
	return plan


static func _ensure_cache_loaded() -> void:
	if _cache_loaded:
		return
	_cache_loaded = true
	_profile_cache.clear()

	if not ResourceLoader.exists(PROFILE_INDEX_PATH):
		return

	var file := FileAccess.open(PROFILE_INDEX_PATH, FileAccess.READ)
	if file == null:
		push_warning("Model3D profile index open failed: %s" % PROFILE_INDEX_PATH)
		return

	var content := file.get_as_text()
	if content.strip_edges().is_empty():
		return

	var parsed: Variant = JSON.parse_string(content)
	if parsed is not Dictionary:
		push_warning("Model3D profile index root must be Dictionary: %s" % PROFILE_INDEX_PATH)
		return

	var profile_map := parsed as Dictionary
	for raw_key in profile_map.keys():
		var key := _normalize_model_id(raw_key)
		if key.is_empty():
			continue
		var raw_value: Variant = profile_map[raw_key]
		if raw_value is Dictionary:
			_profile_cache[key] = (raw_value as Dictionary).duplicate(true)


static func _normalize_model_id(raw_value) -> String:
	if raw_value == null:
		return ""
	var text := String(raw_value).strip_edges()
	if text.begins_with("&\"") and text.ends_with("\"") and text.length() > 3:
		text = text.substr(2, text.length() - 3)
	var lowered := text.to_lower()
	if lowered == "null" or lowered == "<null>" or lowered == "nil":
		return ""
	if text.contains(".") and text.is_valid_float():
		var float_value: float = float(text)
		var rounded_value: float = float(round(float_value))
		if is_equal_approx(float_value, rounded_value):
			return str(int(rounded_value))
	return text
