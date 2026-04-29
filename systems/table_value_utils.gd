extends RefCounted
class_name TableValueUtils


static func normalize_optional_id(raw_value) -> String:
	if raw_value == null:
		return ""

	var text: String = str(raw_value).strip_edges()
	if text.begins_with("&\"") and text.ends_with("\"") and text.length() > 3:
		text = text.substr(2, text.length() - 3)
	if text.is_empty():
		return ""

	var lowered := text.to_lower()
	if lowered == "null" or lowered == "<null>" or lowered == "nil":
		return ""
	if text.contains(".") and text.is_valid_float():
		var numeric_value := float(text)
		var rounded_value: float = round(numeric_value)
		if is_equal_approx(numeric_value, rounded_value):
			return str(int(rounded_value))
	return text


static func flag_enabled(raw_value: Variant) -> bool:
	if raw_value == null:
		return false
	if raw_value is bool:
		return raw_value
	if raw_value is int:
		return int(raw_value) != 0
	if raw_value is float:
		return absf(float(raw_value)) >= 0.0001
	var text := str(raw_value).strip_edges().to_lower()
	if text.is_empty():
		return false
	if text in ["0", "false", "no", "n", "off", "null", "<null>"]:
		return false
	return true


static func float_or(raw_value: Variant, fallback_value: float) -> float:
	if raw_value is int or raw_value is float:
		return float(raw_value)
	var text: String = String(raw_value).strip_edges()
	if text.is_empty():
		return fallback_value
	if text.is_valid_float():
		return float(text)
	if text.is_valid_int():
		return float(int(text))
	return fallback_value
