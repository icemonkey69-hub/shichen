extends RefCounted
class_name CardDisplayText


static func build_placeholder(card_name: String, max_chars: int = 4) -> String:
	var compact_name := card_name.strip_edges()
	var safe_max_chars := maxi(max_chars, 1)
	if compact_name.length() <= safe_max_chars:
		return compact_name
	return compact_name.substr(0, safe_max_chars)
