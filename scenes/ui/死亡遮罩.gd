extends Control
class_name DeathOverlayUi

@onready var title_label: Label = get_node("标题") as Label
@onready var subtitle_label: Label = get_node("副标题") as Label


func show_overlay(title: String, subtitle: String) -> void:
	title_label.text = title
	subtitle_label.text = subtitle
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func set_texts(title: String, subtitle: String) -> void:
	title_label.text = title
	subtitle_label.text = subtitle


func hide_overlay() -> void:
	visible = false
