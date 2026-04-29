extends RefCounted
class_name TemplateBloodlineOptionIndex

var rows_by_template: Dictionary = {}


func rebuild(rows: Array[Dictionary]) -> void:
	rows_by_template.clear()
	for row in rows:
		if not bool(row.get("enabled", true)):
			continue
		var template_id: String = str(row.get("template_id", "")).strip_edges()
		if template_id.is_empty():
			continue
		if not rows_by_template.has(template_id):
			rows_by_template[template_id] = []
		var template_rows: Array = rows_by_template[template_id]
		template_rows.append(row)
		rows_by_template[template_id] = template_rows


func get_rows(template_id: String) -> Array[Dictionary]:
	var normalized_template_id: String = template_id.strip_edges()
	if normalized_template_id.is_empty():
		return []
	var raw_rows: Array = rows_by_template.get(normalized_template_id, []) as Array
	var typed_rows: Array[Dictionary] = []
	for row in raw_rows:
		if row is Dictionary:
			typed_rows.append(row)
	return typed_rows


func clear() -> void:
	rows_by_template.clear()
