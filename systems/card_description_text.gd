extends RefCounted
class_name CardDescriptionText

const PASSIVE_PREFIXES := [
	"唯一被动[",
	"唯一被动:",
	"唯一被动",
	"被动[",
	"被动:",
]

const IGNORED_PREFIXES := [
	"累计",
	"当前",
	"最多",
	"上限",
	"最大",
	"武器名称:",
	"卡牌上限:",
]


static func get_lines(card_row: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for raw_line in str(card_row.get("description", "")).split("\n", false):
		var line := normalize_line(str(raw_line))
		if not line.is_empty():
			lines.append(line)
	return lines


static func normalize_line(raw_line: String) -> String:
	return raw_line.strip_edges().replace("：", ":").replace("％", "%").replace("，", ",")


static func is_passive_line(line: String) -> bool:
	for prefix in PASSIVE_PREFIXES:
		if line.begins_with(prefix):
			return true
	return false


static func should_ignore_line(line: String) -> bool:
	for prefix in IGNORED_PREFIXES:
		if line.begins_with(prefix):
			return true
	return false


static func strip_passive_prefix(line: String) -> String:
	var text := line.strip_edges()
	for prefix in PASSIVE_PREFIXES:
		if not text.begins_with(prefix):
			continue
		var colon_index := text.find(":")
		if colon_index != -1:
			return text.substr(colon_index + 1).strip_edges()
		var closing_bracket := text.find("]")
		if closing_bracket != -1:
			return text.substr(closing_bracket + 1).trim_prefix(":").strip_edges()
		return text.trim_prefix(prefix).trim_prefix(":").strip_edges()
	return text
