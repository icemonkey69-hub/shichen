extends Control
class_name WaveInfoUi

@onready var title_label: Label = get_node("面板/标题") as Label
@onready var progress_label: Label = get_node("面板/进度") as Label
@onready var timer_label: Label = get_node("面板/计时") as Label


func set_wave_info(title: String, progress: String, timer_text: String) -> void:
	title_label.text = title
	progress_label.text = progress
	timer_label.text = timer_text


func set_panel_visible(visible_state: bool) -> void:
	visible = visible_state
