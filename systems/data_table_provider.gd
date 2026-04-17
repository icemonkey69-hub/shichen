extends RefCounted
class_name DataTableProvider

var data_table_cache: Node


func get_data_table_node(tree: SceneTree) -> Node:
	if data_table_cache != null and is_instance_valid(data_table_cache):
		return data_table_cache
	if tree == null:
		return null
	data_table_cache = tree.root.get_node_or_null("DataTable")
	return data_table_cache


func invalidate() -> void:
	data_table_cache = null


func load_rows(tree: SceneTree, table_name: StringName, sort_key: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var data_table := get_data_table_node(tree)
	if data_table == null or not data_table.has_table(table_name):
		return rows

	var raw_rows: Array = data_table.call("get_all", table_name)
	for raw_row in raw_rows:
		if raw_row is Dictionary:
			rows.append((raw_row as Dictionary).duplicate(true))

	if not sort_key.is_empty():
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get(sort_key, 0)) < float(b.get(sort_key, 0))
		)
	return rows
