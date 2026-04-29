extends RefCounted
class_name LevelRuntime

var rows: Array[Dictionary] = []
var rows_by_level: Dictionary = {}


func setup_rows(source_rows: Array[Dictionary]) -> void:
	rows.clear()
	rows_by_level.clear()
	for row in source_rows:
		var row_copy := row.duplicate(true)
		rows.append(row_copy)
		rows_by_level[int(row_copy.get("level", 0))] = row_copy
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("level", 0)) < int(b.get("level", 0))
	)


func calculate_level(total_exp: int) -> int:
	if rows.is_empty():
		return 1

	var resolved_level := 1
	for row in rows:
		var row_level := int(row.get("level", resolved_level))
		var total_required := int(row.get("total_exp", 0))
		if total_exp < total_required:
			break
		resolved_level = row_level

	return clampi(resolved_level, 1, get_max_level())


func get_max_level() -> int:
	if rows.is_empty():
		return 100
	return int(rows[rows.size() - 1].get("level", 100))


func get_total_exp_for_level(level: int) -> int:
	var row := get_level_row(level)
	if row.is_empty():
		return 0
	return int(row.get("total_exp", 0))


func get_exp_required_for_level(level: int) -> int:
	var row := get_level_row(level)
	if row.is_empty():
		return 0
	return int(row.get("exp_to_next", 0))


func get_current_level_exp_progress(current_exp: int, current_level: int) -> int:
	if current_level >= get_max_level():
		return get_exp_required_for_level(current_level)
	return maxi(current_exp - get_total_exp_for_level(current_level), 0)


func get_level_row(level: int) -> Dictionary:
	if rows.is_empty():
		return {}
	if rows_by_level.has(level):
		return (rows_by_level[level] as Dictionary).duplicate(true)
	return rows[rows.size() - 1].duplicate(true)
