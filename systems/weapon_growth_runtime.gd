extends RefCounted
class_name WeaponGrowthRuntime

const SUPPORTED_BLOODLINE_ID := "2001"
const SLOT_ORDER := ["sword", "shield"]

var rows_by_slot: Dictionary = {}
var levels := {
	"sword": 0,
	"shield": 0,
}
var bonus_values: Dictionary = {}
var available := false


func setup_rows(rows: Array[Dictionary]) -> void:
	rows_by_slot.clear()
	for row in rows:
		if str(row.get("bloodline_id", "")).strip_edges() != SUPPORTED_BLOODLINE_ID:
			continue
		var slot := str(row.get("slot", "")).strip_edges().to_lower()
		if slot.is_empty():
			continue
		var slot_rows: Array = rows_by_slot.get(slot, [])
		slot_rows.append(row)
		rows_by_slot[slot] = slot_rows

	for slot in rows_by_slot.keys():
		var slot_rows: Array = rows_by_slot[slot]
		slot_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("step", 0)) < int(b.get("step", 0))
		)


func reset(hero: HeroData, bloodline_option: Dictionary) -> void:
	for slot in SLOT_ORDER:
		levels[slot] = 0
	bonus_values.clear()
	available = _is_supported(hero, bloodline_option)
	if available:
		_refresh_bonus_values(_get_primary_attr_text(hero))


func is_available() -> bool:
	return available


func get_bonus_values() -> Dictionary:
	return bonus_values.duplicate(true)


func try_upgrade(slot: String, current_gold: int, hero: HeroData) -> Dictionary:
	if not available:
		return {"success": false, "message": ""}

	var normalized_slot := slot.strip_edges().to_lower()
	var current_step := int(levels.get(normalized_slot, 0))
	var next_row := _get_row(normalized_slot, current_step + 1)
	if next_row.is_empty():
		return {
			"success": false,
			"message": "%s已满级" % get_slot_title(normalized_slot),
		}

	var cost := maxi(int(next_row.get("cost_gold", 0)), 0)
	if current_gold < cost:
		return {
			"success": false,
			"message": "金币不足\n%s升级需要 %d 金币\n当前金币 %d" % [
				get_slot_title(normalized_slot),
				cost,
				current_gold,
			],
		}

	levels[normalized_slot] = current_step + 1
	_refresh_bonus_values(_get_primary_attr_text(hero))
	return {
		"success": true,
		"spent_gold": cost,
		"message": "%s升级：%s\n%s" % [
			get_slot_title(normalized_slot),
			str(next_row.get("name", "")),
			build_delta_text(next_row, false),
		],
	}


func build_slot_infos() -> Array[Dictionary]:
	var infos: Array[Dictionary] = []
	for slot in SLOT_ORDER:
		var rows: Array = rows_by_slot.get(slot, [])
		if rows.is_empty():
			continue
		var current_step := clampi(int(levels.get(slot, 0)), 0, rows.size() - 1)
		var current_row: Dictionary = rows[current_step]
		var next_row := _get_row(slot, current_step + 1)
		var is_max := next_row.is_empty()
		infos.append({
			"slot": slot,
			"title": get_slot_title(slot),
			"level_text": "阶%d Lv.%d  %d/%d" % [
				int(current_row.get("tier", 0)),
				int(current_row.get("level", current_step)),
				current_step,
				rows.size() - 1,
			],
			"current_text": build_total_text(slot, current_step),
			"next_text": "下级：已满级" if is_max else build_delta_text(next_row, true),
			"cost_gold": 0 if is_max else int(next_row.get("cost_gold", 0)),
			"is_max": is_max,
		})
	return infos


func get_slot_title(slot: String) -> String:
	match slot:
		"sword":
			return "剑"
		"shield":
			return "盾"
		_:
			return slot


func build_total_text(slot: String, current_step: int) -> String:
	var rows: Array = rows_by_slot.get(slot, [])
	if rows.is_empty():
		return "当前：无"

	var capped_step := clampi(current_step, 0, rows.size() - 1)
	var totals: Dictionary = {}
	var labels: Dictionary = {}
	for index in range(capped_step + 1):
		var row: Dictionary = rows[index]
		for stat_index in range(1, 4):
			var stat_id := str(row.get("stat_%d_id" % stat_index, "")).strip_edges()
			if stat_id.is_empty():
				continue
			var label := str(row.get("stat_%d_label" % stat_index, stat_id)).strip_edges()
			totals[stat_id] = float(totals.get(stat_id, 0.0)) + float(row.get("stat_%d_value" % stat_index, 0.0))
			labels[stat_id] = label

	var parts := ["当前：%s" % str(rows[capped_step].get("name", ""))]
	for key in totals.keys():
		var value := float(totals[key])
		if absf(value) < 0.0001:
			continue
		parts.append("%s +%s" % [str(labels.get(key, key)), format_value(key, value)])
	return "\n".join(parts)


func build_delta_text(row: Dictionary, include_name: bool) -> String:
	var parts: Array[String] = []
	if include_name:
		parts.append("下级：%s" % str(row.get("name", "")))
	for stat_index in range(1, 4):
		var stat_id := str(row.get("stat_%d_id" % stat_index, "")).strip_edges()
		if stat_id.is_empty():
			continue
		var value := float(row.get("stat_%d_value" % stat_index, 0.0))
		if absf(value) < 0.0001:
			continue
		var label := str(row.get("stat_%d_label" % stat_index, stat_id)).strip_edges()
		parts.append("%s +%s" % [label, format_value(stat_id, value)])
	var special := str(row.get("special_effect", "")).strip_edges()
	if not special.is_empty():
		parts.append(special)
	return "\n".join(parts)


func format_value(stat_id_text: String, value: float) -> String:
	if stat_id_text.ends_with("_percent"):
		return "%.0f%%" % (value * 100.0)
	if absf(value - roundf(value)) < 0.001:
		return "%d" % int(roundf(value))
	return "%.2f" % value


func _refresh_bonus_values(primary_attr: String) -> void:
	bonus_values.clear()
	if not available:
		return

	for slot in SLOT_ORDER:
		var rows: Array = rows_by_slot.get(slot, [])
		if rows.is_empty():
			continue
		var current_step := clampi(int(levels.get(slot, 0)), 0, rows.size() - 1)
		levels[slot] = current_step
		for index in range(current_step + 1):
			_merge_row_bonus(rows[index], primary_attr)


func _merge_row_bonus(row: Dictionary, primary_attr: String) -> void:
	for slot_index in range(1, 4):
		var stat_id_text := str(row.get("stat_%d_id" % slot_index, "")).strip_edges()
		if stat_id_text.is_empty():
			continue
		var stat_id := _resolve_stat_id(stat_id_text, primary_attr)
		if stat_id == &"":
			continue
		var value := float(row.get("stat_%d_value" % slot_index, 0.0))
		_add_bonus_value(stat_id, value)


func _resolve_stat_id(stat_id_text: String, primary_attr: String) -> StringName:
	if stat_id_text != "primary_attr":
		return StringName(stat_id_text)

	match primary_attr:
		"agi":
			return &"added_agi"
		"int":
			return &"added_int"
		_:
			return &"added_str"


func _add_bonus_value(stat_id: StringName, value: float) -> void:
	var key_text := str(stat_id).strip_edges()
	if key_text.is_empty():
		return

	var key := StringName(key_text)
	bonus_values[key] = float(bonus_values.get(key, 0.0)) + value
	if absf(float(bonus_values[key])) < 0.0001:
		bonus_values.erase(key)


func _get_row(slot: String, step: int) -> Dictionary:
	var rows: Array = rows_by_slot.get(slot, [])
	if step < 0 or step >= rows.size():
		return {}
	return rows[step]


func _is_supported(hero: HeroData, bloodline_option: Dictionary) -> bool:
	if rows_by_slot.is_empty():
		return false
	var bloodline_id := _normalize_id_token(bloodline_option.get("bloodline_id", ""))
	if bloodline_id.is_empty():
		bloodline_id = _normalize_id_token(bloodline_option.get("id", ""))
	if bloodline_id == SUPPORTED_BLOODLINE_ID:
		return true
	if hero != null and str(hero.model_id) == SUPPORTED_BLOODLINE_ID:
		return true
	return false


func _get_primary_attr_text(hero: HeroData) -> String:
	if hero == null:
		return "str"
	return str(hero.primary_attr)


func _normalize_id_token(raw_value: Variant) -> String:
	var token := str(raw_value).strip_edges()
	if token == "<null>":
		return ""
	return token
