extends Control
class_name HeroSelectionOverlayUi

signal confirm_requested
signal preview_gui_input(event: InputEvent)
signal preview_resized

@onready var title_label: Label = get_node("SelectionPanel/Title") as Label
@onready var countdown_label: Label = get_node("SelectionPanel/Countdown") as Label
@onready var template_title_label: Label = get_node("SelectionPanel/MainColumns/LeftColumn/HeroSection/TemplateTitle") as Label
@onready var bloodline_title_label: Label = get_node("SelectionPanel/MainColumns/LeftColumn/BloodlineSection/BloodlineTitle") as Label
@onready var template_frame: Panel = get_node("SelectionPanel/MainColumns/LeftColumn/HeroSection/TemplateFrame") as Panel
@onready var bloodline_frame: Panel = get_node("SelectionPanel/MainColumns/LeftColumn/BloodlineSection/BloodlineFrame") as Panel
@onready var template_scroll: ScrollContainer = get_node("SelectionPanel/MainColumns/LeftColumn/HeroSection/TemplateFrame/TemplateScroll") as ScrollContainer
@onready var bloodline_scroll: ScrollContainer = get_node("SelectionPanel/MainColumns/LeftColumn/BloodlineSection/BloodlineFrame/BloodlineScroll") as ScrollContainer
@onready var template_buttons: GridContainer = get_node("SelectionPanel/MainColumns/LeftColumn/HeroSection/TemplateFrame/TemplateScroll/TemplateButtons") as GridContainer
@onready var bloodline_buttons: GridContainer = get_node("SelectionPanel/MainColumns/LeftColumn/BloodlineSection/BloodlineFrame/BloodlineScroll/BloodlineButtons") as GridContainer
@onready var preview_hint_label: Label = get_node("SelectionPanel/MainColumns/PreviewColumn/Hint") as Label
@onready var preview_frame: Panel = get_node("SelectionPanel/MainColumns/PreviewColumn/PreviewFrame") as Panel
@onready var preview_container: SubViewportContainer = get_node("SelectionPanel/MainColumns/PreviewColumn/PreviewFrame/PreviewModel") as SubViewportContainer
@onready var preview_viewport: SubViewport = get_node("SelectionPanel/MainColumns/PreviewColumn/PreviewFrame/PreviewModel/Viewport") as SubViewport
@onready var preview_root: Node2D = get_node("SelectionPanel/MainColumns/PreviewColumn/PreviewFrame/PreviewModel/Viewport/PreviewRoot") as Node2D
@onready var summary_frame: Panel = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame") as Panel
@onready var name_label: Label = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/Name") as Label
@onready var bloodline_name_label: Label = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/Bloodline") as Label
@onready var primary_attr_label: Label = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/PrimaryAttr") as Label
@onready var stats_label: Label = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/Stats") as Label
@onready var skills_label: Label = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/SkillsTitle/SkillsLabel") as Label
@onready var skill_q_button: Button = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/SkillsTitle/SkillButtons/SkillQ") as Button
@onready var skill_w_button: Button = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/SkillsTitle/SkillButtons/SkillW") as Button
@onready var skill_r_button: Button = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/SkillsTitle/SkillButtons/SkillR") as Button
@onready var skill_tooltip_title_label: Label = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/SkillTooltipTitle") as Label
@onready var skill_tooltip_body_label: Label = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/SkillTooltipBody") as Label
@onready var description_label: Label = get_node("SelectionPanel/MainColumns/SummaryColumn/SummaryFrame/SummaryContent/Description") as Label
@onready var confirm_button: Button = get_node("SelectionPanel/ConfirmButton") as Button

var skill_buttons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	preview_viewport.transparent_bg = true
	skill_buttons = {
		"Q": skill_q_button,
		"W": skill_w_button,
		"R": skill_r_button,
	}
	_apply_default_texts()
	_apply_panel_styles()
	_apply_confirm_button_style()
	if not confirm_button.pressed.is_connected(_on_confirm_button_pressed):
		confirm_button.pressed.connect(_on_confirm_button_pressed)
	if not preview_container.gui_input.is_connected(_on_preview_container_gui_input):
		preview_container.gui_input.connect(_on_preview_container_gui_input)
	if not preview_container.resized.is_connected(_on_preview_container_resized):
		preview_container.resized.connect(_on_preview_container_resized)


func show_overlay() -> void:
	visible = true


func hide_overlay() -> void:
	visible = false


func get_skill_buttons() -> Dictionary:
	return skill_buttons


func clear_template_grid() -> void:
	for child in template_buttons.get_children():
		child.queue_free()


func clear_bloodline_grid() -> void:
	for child in bloodline_buttons.get_children():
		child.queue_free()


func rebuild_template_grid(buttons: Array[Button]) -> void:
	_rebuild_grid(template_buttons, buttons)


func rebuild_bloodline_grid(buttons: Array[Button]) -> void:
	_rebuild_grid(bloodline_buttons, buttons)


func get_template_card_width(columns: int, min_width: float, max_width: float) -> float:
	return _get_grid_item_width(template_scroll, columns, min_width, max_width)


func get_bloodline_card_width(columns: int, min_width: float, max_width: float) -> float:
	return _get_grid_item_width(bloodline_scroll, columns, min_width, max_width)


func set_confirm_disabled(disabled: bool) -> void:
	confirm_button.disabled = disabled


func set_summary_texts(hero_name: String, bloodline_name: String, primary_attr: String, stats_text: String) -> void:
	_set_label_text(name_label, hero_name)
	_set_label_text(bloodline_name_label, bloodline_name)
	_set_label_text(primary_attr_label, primary_attr)
	_set_label_text(stats_label, stats_text)


func set_skill_tooltip(title_text: String, body_text: String) -> void:
	_set_label_text(skill_tooltip_title_label, title_text)
	_set_label_text(skill_tooltip_body_label, body_text)


func set_skill_tooltip_visible(visible_state: bool) -> void:
	skill_tooltip_title_label.visible = visible_state
	skill_tooltip_body_label.visible = visible_state


func set_description_visible(visible_state: bool) -> void:
	description_label.visible = visible_state


func _apply_default_texts() -> void:
	_set_label_text(title_label, "选择模板与血脉")
	_set_label_text(template_title_label, "人物")
	_set_label_text(bloodline_title_label, "血脉")
	_set_label_text(skills_label, "血脉效果")
	_set_label_text(countdown_label, "左侧挑选模板与血脉，中间预览模型，右侧查看出战汇总。")
	_set_label_text(preview_hint_label, "按住左键左右拖动，可旋转模型。")
	_set_label_text(skill_tooltip_title_label, "血脉效果")
	_set_label_text(skill_tooltip_body_label, "Q / W / R 展示字段会从血脉表读取。")
	skill_tooltip_title_label.visible = false
	skill_tooltip_body_label.visible = false
	description_label.visible = false


func _apply_panel_styles() -> void:
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.09, 0.11, 0.09, 0.96)
	frame_style.border_color = Color(0.29, 0.35, 0.32, 1.0)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(14)
	frame_style.content_margin_left = 14
	frame_style.content_margin_top = 14
	frame_style.content_margin_right = 14
	frame_style.content_margin_bottom = 14
	template_frame.add_theme_stylebox_override("panel", frame_style)
	bloodline_frame.add_theme_stylebox_override("panel", frame_style)
	preview_frame.add_theme_stylebox_override("panel", frame_style)
	summary_frame.add_theme_stylebox_override("panel", frame_style)


func _apply_confirm_button_style() -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.12, 0.11, 0.98)
	normal_style.border_color = Color(0.95, 0.80, 0.28, 1.0)
	normal_style.set_border_width_all(3)
	normal_style.set_corner_radius_all(10)
	normal_style.content_margin_left = 12
	normal_style.content_margin_top = 6
	normal_style.content_margin_right = 12
	normal_style.content_margin_bottom = 6

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.20, 0.17, 0.10, 1.0)
	hover_style.border_color = Color(1.0, 0.90, 0.38, 1.0)

	var pressed_style := hover_style.duplicate()
	pressed_style.bg_color = Color(0.18, 0.15, 0.09, 1.0)

	confirm_button.add_theme_stylebox_override("normal", normal_style)
	confirm_button.add_theme_stylebox_override("hover", hover_style)
	confirm_button.add_theme_stylebox_override("pressed", pressed_style)
	confirm_button.add_theme_stylebox_override("focus", hover_style)
	confirm_button.add_theme_stylebox_override("disabled", normal_style)
	confirm_button.add_theme_color_override("font_color", Color(0.98, 0.97, 0.92, 1.0))
	confirm_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.96, 1.0))
	confirm_button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 0.96, 1.0))


func _get_grid_item_width(host: Control, columns: int, min_width: float, max_width: float) -> float:
	var safe_columns: int = maxi(columns, 1)
	var available_width: float = 0.0
	if host != null:
		available_width = host.size.x
		if available_width <= 1.0 and host.get_parent() is Control:
			available_width = (host.get_parent() as Control).size.x
	if available_width <= 1.0:
		available_width = 520.0
	var total_spacing: float = 8.0 * float(maxi(safe_columns - 1, 0))
	var computed_width: float = floor((available_width - total_spacing) / float(safe_columns))
	return clampf(computed_width, min_width, max_width)


func _rebuild_grid(container: GridContainer, buttons: Array[Button]) -> void:
	for child in container.get_children():
		child.queue_free()
	for button in buttons:
		container.add_child(button)


func _on_confirm_button_pressed() -> void:
	confirm_requested.emit()


func _on_preview_container_gui_input(event: InputEvent) -> void:
	preview_gui_input.emit(event)


func _on_preview_container_resized() -> void:
	preview_resized.emit()


func _set_label_text(label: Label, value: String) -> void:
	if label != null and label.text != value:
		label.text = value
