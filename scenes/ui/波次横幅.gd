extends Control
class_name WaveBannerUi

@onready var title_label: Label = get_node("标题") as Label
@onready var subtitle_label: Label = get_node("副标题") as Label


func show_banner(title: String, subtitle: String) -> void:
	title_label.text = title
	subtitle_label.text = subtitle
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func set_alpha_scale(alpha_scale: float) -> void:
	modulate = Color(1.0, 1.0, 1.0, clampf(alpha_scale, 0.0, 1.0))


func hide_banner() -> void:
	visible = false
	modulate = Color(1.0, 1.0, 1.0, 1.0)
