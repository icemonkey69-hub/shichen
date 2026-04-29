extends Control
class_name BossHealthUi

@onready var title_label: Label = get_node("面板/标题") as Label
@onready var health_bar: ProgressBar = get_node("面板/血条") as ProgressBar


func show_boss_health(title: String, current_hp: float, max_hp: float) -> void:
	visible = true
	title_label.text = title
	health_bar.max_value = max(max_hp, 1.0)
	health_bar.value = clampf(current_hp, 0.0, health_bar.max_value)


func hide_bar() -> void:
	visible = false
