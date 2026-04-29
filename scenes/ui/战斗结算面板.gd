extends Control
class_name BattleResultUi

signal return_requested

@onready var title_label: Label = get_node("主面板/标题") as Label
@onready var summary_label: Label = get_node("主面板/摘要") as Label
@onready var return_button: Button = get_node("主面板/返回按钮") as Button


func _ready() -> void:
	if not return_button.pressed.is_connected(_on_return_button_pressed):
		return_button.pressed.connect(_on_return_button_pressed)


func show_result(title: String, summary: String) -> void:
	title_label.text = title
	summary_label.text = summary
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	return_button.grab_focus()


func hide_panel() -> void:
	visible = false


func _on_return_button_pressed() -> void:
	return_requested.emit()
