extends Node

const TABLE_DIR := "res://data/tables"
const DEFAULT_ID_KEYS := [&"id", &"type", &"wave", &"name"]

var _tables: Dictionary = {}


func _ready() -> void:
	reload_all()


func reload_all() -> void:
	_tables.clear()

	var dir := DirAccess.open(TABLE_DIR)
	if dir == null:
		push_warning("DataTable directory not found: %s" % TABLE_DIR)
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if file_name.get_extension().to_lower() != "json":
			continue

		var table_name := StringName(file_name.get_basename())
		var json_path := "%s/%s" % [TABLE_DIR, file_name]
		_tables[table_name] = _load_json_table(json_path)
	dir.list_dir_end()


func get_all(table_name: StringName) -> Array[Dictionary]:
	var rows = _tables.get(table_name, [])
	var result: Array[Dictionary] = []
	for row in rows:
		if row is Dictionary:
			result.append((row as Dictionary).duplicate(true))
	return result


func get_row(table_name: StringName, row_id) -> Dictionary:
	var wanted := String(row_id)
	for row in get_all(table_name):
		for key in DEFAULT_ID_KEYS:
			if row.has(key) and String(row[key]) == wanted:
				return row
	return {}


func has_table(table_name: StringName) -> bool:
	return _tables.has(table_name)


func _load_json_table(json_path: String) -> Array:
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_warning("DataTable JSON not found: %s" % json_path)
		return []

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		return parsed

	push_warning("DataTable JSON root is not Array: %s" % json_path)
	return []
