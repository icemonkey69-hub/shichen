extends Control
class_name AttributesPanelUi

@onready var title_label: Label = get_node("主面板/标题") as Label
@onready var hint_label: Label = get_node("主面板/提示") as Label
@onready var value_grid: GridContainer = get_node("主面板/滚动区/属性列表") as GridContainer

var value_labels: Dictionary = {}


func set_title_text(title: String, hint: String) -> void:
	title_label.text = title
	hint_label.text = hint


func rebuild_entries(entries: Array[Dictionary]) -> void:
	for child in value_grid.get_children():
		child.queue_free()
	value_labels.clear()
	for entry in entries:
		var stat_id: StringName = entry.get("id", &"") as StringName
		var stat_name: String = String(entry.get("name", ""))
		var value_label: Label = Label.new()
		value_label.custom_minimum_size = Vector2(270, 26)
		value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		value_label.clip_text = true
		value_label.text = "%s: -" % stat_name
		value_grid.add_child(value_label)
		value_labels[stat_id] = value_label


func update_value_texts(values_by_id: Dictionary) -> void:
	for stat_id in value_labels.keys():
		var label: Label = value_labels.get(stat_id, null) as Label
		if label == null:
			continue
		var next_text: String = String(values_by_id.get(stat_id, label.text))
		if label.text != next_text:
			label.text = next_text


func has_entries() -> bool:
	return not value_labels.is_empty()


func show_panel() -> void:
	visible = true


func hide_panel() -> void:
	visible = false
