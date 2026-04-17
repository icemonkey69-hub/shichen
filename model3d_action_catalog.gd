extends RefCounted
class_name Model3DActionCatalog

const ACTION_TABLE_PATH := "res://data/tables/actions.json"
const STATE_KEYS: PackedStringArray = [
	"idle",
	"move",
	"hit",
	"stun",
	"death",
	"jump",
	"spawn",
	"victory",
]

static var _cache_loaded: bool = false
static var _action_cache: Dictionary = {}


static func reload() -> void:
	_cache_loaded = false
	_action_cache.clear()
	_ensure_cache_loaded()


static func has_profile_actions(model_id: StringName) -> bool:
	_ensure_cache_loaded()
	var key: String = _normalize_model_id(model_id)
	return not key.is_empty() and _action_cache.has(key)


static func get_profile_actions(model_id: StringName) -> Dictionary:
	_ensure_cache_loaded()
	var key: String = _normalize_model_id(model_id)
	if key.is_empty():
		return {}
	var raw_entry: Variant = _action_cache.get(key, {})
	if raw_entry is Dictionary:
		return (raw_entry as Dictionary).duplicate(true)
	return {}


static func _ensure_cache_loaded() -> void:
	if _cache_loaded:
		return
	_cache_loaded = true
	_action_cache.clear()

	if not ResourceLoader.exists(ACTION_TABLE_PATH):
		push_warning("Model3D actions table missing: %s" % ACTION_TABLE_PATH)
		return
	_load_from_path(ACTION_TABLE_PATH)


static func _load_from_path(table_path: String) -> bool:
	var file: FileAccess = FileAccess.open(table_path, FileAccess.READ)
	if file == null:
		push_warning("Model3D actions open failed: %s" % table_path)
		return false

	var content: String = file.get_as_text()
	if content.strip_edges().is_empty():
		return false

	var parsed: Variant = JSON.parse_string(content)
	if parsed is Dictionary:
		var entries: Dictionary = parsed as Dictionary
		for raw_key in entries.keys():
			var normalized_id: String = _normalize_model_id(raw_key)
			if normalized_id.is_empty():
				continue
			var raw_value: Variant = entries[raw_key]
			if raw_value is not Dictionary:
				continue
			_action_cache[normalized_id] = _sanitize_action_row(raw_value as Dictionary)
		return not _action_cache.is_empty()

	if parsed is Array:
		var rows: Array = parsed as Array
		for raw_row in rows:
			if raw_row is not Dictionary:
				continue
			var row: Dictionary = raw_row as Dictionary
			var normalized_id: String = _normalize_model_id(row.get("model_id", row.get("id", "")))
			if normalized_id.is_empty():
				continue
			_action_cache[normalized_id] = _sanitize_action_row(row)
		return not _action_cache.is_empty()

	push_warning("Model3D actions root must be Dictionary/Array: %s" % table_path)
	return false


static func _sanitize_action_row(row: Dictionary) -> Dictionary:
	var sanitized: Dictionary = {}
	for state_key in STATE_KEYS:
		var direct_text: String = _coerce_action_name(row.get(state_key, ""))
		if not direct_text.is_empty():
			var direct_spec: Dictionary = _build_spec_from_text(direct_text)
			if not direct_spec.is_empty():
				sanitized[state_key] = direct_spec
				continue

		var grouped_sequences: Array[PackedStringArray] = _collect_grouped_state_sequences(row, state_key)
		if grouped_sequences.size() > 1:
			sanitized[state_key] = {
				"mode": "random_sequence",
				"sequences": grouped_sequences,
			}
			continue
		if grouped_sequences.size() == 1:
			var only_sequence: PackedStringArray = grouped_sequences[0]
			if only_sequence.size() <= 1:
				sanitized[state_key] = {
					"mode": "single",
					"clips": only_sequence,
				}
			else:
				sanitized[state_key] = {
					"mode": "sequence",
					"clips": only_sequence,
				}
			continue

		var numbered_values: PackedStringArray = _collect_numbered_state_values(row, state_key)
		if numbered_values.is_empty():
			continue
		if numbered_values.size() <= 1:
			sanitized[state_key] = {
				"mode": "single",
				"clips": numbered_values,
			}
		else:
			var default_mode: String = "random"
			if state_key == "jump":
				default_mode = "sequence"
			sanitized[state_key] = {
				"mode": default_mode,
				"clips": numbered_values,
			}
	return sanitized


static func _build_spec_from_text(text: String) -> Dictionary:
	var normalized: String = text.replace("->", ">").replace("=>", ">")
	if normalized.contains("|"):
		var random_groups: Array[String] = _split_tokens(normalized, "|")
		var sequences: Array[PackedStringArray] = []
		for group_text in random_groups:
			var group_sequence: PackedStringArray = _extract_sequence_tokens(group_text)
			if not group_sequence.is_empty():
				sequences.append(group_sequence)
		if sequences.size() > 1:
			return {
				"mode": "random_sequence",
				"sequences": sequences,
			}
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
		return {}

	if normalized.contains(">"):
		var chained_tokens: PackedStringArray = _extract_sequence_tokens(normalized)
		if chained_tokens.size() <= 1:
			return {
				"mode": "single",
				"clips": chained_tokens,
			}
		return {
			"mode": "sequence",
			"clips": chained_tokens,
		}

	var random_tokens: PackedStringArray = _extract_random_tokens(normalized)
	if random_tokens.size() <= 1:
		return {
			"mode": "single",
			"clips": random_tokens,
		}
	return {
		"mode": "random",
		"clips": random_tokens,
	}


static func _extract_sequence_tokens(text: String) -> PackedStringArray:
	var parts: Array[String] = _split_tokens(text, ">")
	var result: PackedStringArray = PackedStringArray()
	for part in parts:
		var token: String = _coerce_action_name(part)
		if token.is_empty():
			continue
		result.append(token)
	return result


static func _extract_random_tokens(text: String) -> PackedStringArray:
	var normalized: String = text
	normalized = normalized.replace(";", ",")
	normalized = normalized.replace("|", ",")
	normalized = normalized.replace("/", ",")
	normalized = normalized.replace("\\", ",")
	normalized = normalized.replace("+", ",")
	normalized = normalized.replace("&", ",")

	var parts: Array[String] = _split_tokens(normalized, ",")
	var result: PackedStringArray = PackedStringArray()
	for part in parts:
		var token: String = _coerce_action_name(part)
		if token.is_empty():
			continue
		result.append(token)
	return result


static func _collect_numbered_state_values(row: Dictionary, state_key: String) -> PackedStringArray:
	var entries: Array[Dictionary] = []
	var prefix: String = "%s_" % state_key.to_lower()

	for raw_key in row.keys():
		var key_text: String = String(raw_key).strip_edges().to_lower()
		if not key_text.begins_with(prefix):
			continue
		var suffix: String = key_text.substr(prefix.length())
		if not suffix.is_valid_int():
			continue
		var value: String = _coerce_action_name(row.get(raw_key, ""))
		if value.is_empty():
			continue
		entries.append({
			"order": int(suffix),
			"value": value,
		})

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)

	var values: PackedStringArray = PackedStringArray()
	for entry in entries:
		values.append(String(entry.get("value", "")))
	return values


static func _collect_grouped_state_sequences(row: Dictionary, state_key: String) -> Array[PackedStringArray]:
	var groups: Dictionary = {}
	var prefix: String = "%s_" % state_key.to_lower()

	for raw_key in row.keys():
		var key_text: String = String(raw_key).strip_edges().to_lower()
		if not key_text.begins_with(prefix):
			continue

		var suffix: String = key_text.substr(prefix.length())
		var parts: PackedStringArray = suffix.split("_", false)
		if parts.size() < 2:
			continue
		if not String(parts[0]).is_valid_int() or not String(parts[1]).is_valid_int():
			continue

		var group_index: int = int(parts[0])
		var order_index: int = int(parts[1])
		var value: String = _coerce_action_name(row.get(raw_key, ""))
		if value.is_empty():
			continue

		if not groups.has(group_index):
			groups[group_index] = []
		var group_entries_variant: Variant = groups.get(group_index, [])
		var group_entries: Array = group_entries_variant as Array
		group_entries.append({
			"order": order_index,
			"value": value,
		})
		groups[group_index] = group_entries

	if groups.is_empty():
		return []

	var sorted_group_ids: Array[int] = []
	for raw_group_id in groups.keys():
		sorted_group_ids.append(int(raw_group_id))
	sorted_group_ids.sort()

	var sequences: Array[PackedStringArray] = []
	for group_id in sorted_group_ids:
		var group_entries_variant: Variant = groups.get(group_id, [])
		var group_entries: Array = group_entries_variant as Array
		group_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("order", 0)) < int(b.get("order", 0))
		)

		var sequence: PackedStringArray = PackedStringArray()
		for entry in group_entries:
			var clip_name: String = _coerce_action_name(entry.get("value", ""))
			if not clip_name.is_empty():
				sequence.append(clip_name)
		if not sequence.is_empty():
			sequences.append(sequence)

	return sequences


static func _split_tokens(text: String, delimiter: String) -> Array[String]:
	var raw_parts: PackedStringArray = text.split(delimiter, false)
	var result: Array[String] = []
	for raw_part in raw_parts:
		var token: String = String(raw_part).strip_edges()
		if token.is_empty():
			continue
		result.append(token)
	return result


static func _coerce_action_name(raw_value: Variant) -> String:
	if raw_value == null:
		return ""
	var text: String = String(raw_value).strip_edges()
	var lowered: String = text.to_lower()
	if lowered == "null" or lowered == "<null>" or lowered == "nil":
		return ""
	return text


static func _normalize_model_id(raw_value: Variant) -> String:
	if raw_value == null:
		return ""
	var text: String = String(raw_value).strip_edges()
	if text.begins_with("&\"") and text.ends_with("\"") and text.length() > 3:
		text = text.substr(2, text.length() - 3)
	var lowered: String = text.to_lower()
	if lowered == "null" or lowered == "<null>" or lowered == "nil":
		return ""
	if text.contains(".") and text.is_valid_float():
		var float_value: float = float(text)
		var rounded_value: float = float(round(float_value))
		if is_equal_approx(float_value, rounded_value):
			return str(int(rounded_value))
	return text
