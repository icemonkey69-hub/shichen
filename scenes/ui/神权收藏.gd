extends Control
class_name CardCollectionOverlayUi

signal close_requested
signal sort_mode_changed(mode: String)
signal stack_selected(stack_key: String)

const CARD_CHOICE_BACKGROUND_PATH := "res://assets/ui/card_choice/backgrounds/god_demon_choice_bg_v1.png"
const CARD_CHOICE_FRAME_DIR := "res://assets/ui/card_choice/frames"

@onready var overlay: CardCollectionOverlayUi = self
@onready var shade: ColorRect = get_node("遮罩") as ColorRect
@onready var main_panel: Panel = get_node("主面板") as Panel
@onready var background_rect: TextureRect = get_node("主面板/背景图") as TextureRect
@onready var title_label: Label = get_node("主面板/标题栏/标题") as Label
@onready var sort_time_button: Button = get_node("主面板/标题栏/排序区/时间") as Button
@onready var sort_quality_button: Button = get_node("主面板/标题栏/排序区/品质") as Button
@onready var close_button: Button = get_node("主面板/标题栏/关闭") as Button
@onready var empty_label: Label = get_node("主面板/内容区/左栏/空状态") as Label
@onready var scroll: ScrollContainer = get_node("主面板/内容区/左栏/滚动区") as ScrollContainer
@onready var grid: GridContainer = get_node("主面板/内容区/左栏/滚动区/滚动内边距/神权网格") as GridContainer
@onready var detail_panel: Panel = get_node("主面板/内容区/详情区") as Panel
@onready var detail_title_label: Label = get_node("主面板/内容区/详情区/详情标题栏/详情标题") as Label
@onready var detail_tier_label: Label = get_node("主面板/内容区/详情区/详情标题栏/品阶") as Label
@onready var detail_icon_panel: Panel = get_node("主面板/内容区/详情区/图标容器") as Panel
@onready var detail_icon_rect: TextureRect = get_node("主面板/内容区/详情区/图标容器/图标") as TextureRect
@onready var detail_placeholder_label: Label = get_node("主面板/内容区/详情区/图标容器/占位") as Label
@onready var detail_description_label: RichTextLabel = get_node("主面板/内容区/详情区/描述") as RichTextLabel

var stack_infos: Array[Dictionary] = []
var slot_buttons: Array[Button] = []
var selected_stack_key := ""
var sort_mode := "quality"
var frame_texture_cache: Dictionary = {}
var hover_glow_shader: Shader


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if ResourceLoader.exists(CARD_CHOICE_BACKGROUND_PATH):
		background_rect.texture = load(CARD_CHOICE_BACKGROUND_PATH) as Texture2D
	_setup_static_style()
	if not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)
	if not sort_time_button.pressed.is_connected(_on_sort_button_pressed.bind("time")):
		sort_time_button.pressed.connect(_on_sort_button_pressed.bind("time"))
	if not sort_quality_button.pressed.is_connected(_on_sort_button_pressed.bind("quality")):
		sort_quality_button.pressed.connect(_on_sort_button_pressed.bind("quality"))
	if not overlay.gui_input.is_connected(_on_overlay_gui_input):
		overlay.gui_input.connect(_on_overlay_gui_input)
	if not resized.is_connected(_layout_overlay):
		resized.connect(_layout_overlay)
	_layout_overlay()
	clear_collection()


func configure_collection(rows: Array[Dictionary], focus_stack_key: String, current_sort_mode: String) -> void:
	stack_infos.clear()
	for row in rows:
		stack_infos.append(row.duplicate(true))
	sort_mode = current_sort_mode
	selected_stack_key = focus_stack_key.strip_edges()
	_set_label_text(title_label, "神权收藏")
	_apply_sort_button_styles()
	_rebuild_grid()
	if stack_infos.is_empty():
		_show_empty_detail()
		return
	if selected_stack_key.is_empty() or _find_stack_info(selected_stack_key).is_empty():
		selected_stack_key = String(stack_infos[0].get("stack_key", "")).strip_edges()
	_show_detail(_find_stack_info(selected_stack_key))
	_layout_overlay()


func clear_collection() -> void:
	stack_infos.clear()
	selected_stack_key = ""
	for child in grid.get_children():
		child.queue_free()
	slot_buttons.clear()
	empty_label.visible = false
	_show_empty_detail()
	_apply_sort_button_styles()


func grab_close_focus() -> void:
	if close_button != null:
		close_button.grab_focus()


func _setup_static_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.05, 0.04, 0.96)
	panel_style.border_color = Color(0.96, 0.79, 0.42, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(22)
	main_panel.add_theme_stylebox_override("panel", panel_style)

	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(0.11, 0.08, 0.07, 0.92)
	detail_style.border_color = Color(0.44, 0.30, 0.18, 0.95)
	detail_style.set_border_width_all(1)
	detail_style.set_corner_radius_all(14)
	detail_panel.add_theme_stylebox_override("panel", detail_style)

	detail_description_label.bbcode_enabled = false
	detail_description_label.scroll_active = true
	detail_description_label.fit_content = false
	detail_description_label.add_theme_font_size_override("normal_font_size", 17)

	empty_label.add_theme_font_size_override("font_size", 16)
	empty_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 0.86))
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.58, 1.0))
	detail_title_label.add_theme_font_size_override("font_size", 22)
	detail_title_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.92, 1.0))
	detail_tier_label.add_theme_font_size_override("font_size", 15)
	detail_placeholder_label.add_theme_font_size_override("font_size", 36)
	detail_placeholder_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.90, 0.9))

	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.22, 0.13, 0.08, 0.94)
	close_style.border_color = Color(0.96, 0.79, 0.42, 1.0)
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(10)
	var close_hover_style := close_style.duplicate()
	close_hover_style.bg_color = Color(0.30, 0.17, 0.08, 0.98)
	close_hover_style.border_color = Color(1.0, 0.88, 0.56, 1.0)
	close_button.add_theme_stylebox_override("normal", close_style)
	close_button.add_theme_stylebox_override("hover", close_hover_style)
	close_button.add_theme_stylebox_override("pressed", close_hover_style)
	close_button.add_theme_stylebox_override("focus", close_hover_style)
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.add_theme_color_override("font_color", Color(1.0, 0.96, 0.92, 1.0))

	_apply_detail_icon_panel_style(0)


func _layout_overlay() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var panel_width: float = clampf(viewport_size.x * 0.84, 860.0, maxf(viewport_size.x - 24.0, 860.0))
	var panel_height: float = clampf(viewport_size.y * 0.82, 520.0, maxf(viewport_size.y - 24.0, 520.0))
	main_panel.offset_left = -panel_width * 0.5
	main_panel.offset_top = -panel_height * 0.5
	main_panel.offset_right = panel_width * 0.5
	main_panel.offset_bottom = panel_height * 0.5

	_refresh_grid_layout(panel_width)


func _rebuild_grid() -> void:
	for child in grid.get_children():
		child.queue_free()
	slot_buttons.clear()
	if stack_infos.is_empty():
		empty_label.visible = true
		return
	empty_label.visible = false
	for stack_info in stack_infos:
		var button := _build_slot_button(stack_info)
		slot_buttons.append(button)
		grid.add_child(button)
	_refresh_grid_layout(main_panel.size.x)


func _refresh_grid_layout(panel_width: float) -> void:
	var available_width: float = maxf(scroll.size.x - 16.0, panel_width * 0.48)
	var spacing := 10
	var target_slot_width := 92.0
	var columns := clampi(int(floor((available_width + float(spacing)) / (target_slot_width + float(spacing)))), 5, 7)
	var exact_slot_width := floorf((available_width - float((columns - 1) * spacing)) / float(columns))
	exact_slot_width = clampf(exact_slot_width, 86.0, 104.0)
	var slot_height := clampf(exact_slot_width * 1.34, 118.0, 140.0)
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", spacing)
	grid.add_theme_constant_override("v_separation", 10)
	for button in slot_buttons:
		if button == null or not is_instance_valid(button):
			continue
		button.custom_minimum_size = Vector2(exact_slot_width, slot_height)


func _build_slot_button(stack_info: Dictionary) -> Button:
	var card_row: Dictionary = stack_info.get("row", {})
	var stack_key: String = String(stack_info.get("stack_key", "")).strip_edges()
	var count: int = int(stack_info.get("count", 0))
	var card_name: String = String(card_row.get("name", card_row.get("id", "神权")))
	var tier: int = int(card_row.get("tier", 0))

	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(94.0, 126.0)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = ""
	button.tooltip_text = ""
	button.set_meta("stack_key", stack_key)
	button.set_meta("card_tier", tier)
	_apply_slot_style(button, tier, stack_key == selected_stack_key)

	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(root)

	var frame_texture := _load_frame_texture(tier)
	if frame_texture != null:
		var frame_rect := TextureRect.new()
		frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
		frame_rect.texture = frame_texture
		frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(frame_rect)

	var icon_panel := Panel.new()
	icon_panel.anchor_right = 1.0
	icon_panel.anchor_bottom = 1.0
	icon_panel.offset_left = 10.0
	icon_panel.offset_top = 10.0
	icon_panel.offset_right = -10.0
	icon_panel.offset_bottom = -36.0
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon_panel)

	var icon_panel_style := StyleBoxFlat.new()
	icon_panel_style.bg_color = Color(0.10, 0.11, 0.10, 0.42)
	icon_panel_style.border_color = (_get_tier_colors(tier).get("border", Color(0.88, 0.82, 0.62, 1.0)) as Color).darkened(0.18)
	icon_panel_style.set_border_width_all(1)
	icon_panel_style.set_corner_radius_all(12)
	icon_panel.add_theme_stylebox_override("panel", icon_panel_style)

	var icon_texture := stack_info.get("icon_texture", null) as Texture2D
	if icon_texture != null:
		var icon_rect := TextureRect.new()
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_rect.offset_left = 10.0
		icon_rect.offset_top = 10.0
		icon_rect.offset_right = -10.0
		icon_rect.offset_bottom = -10.0
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = icon_texture
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_panel.add_child(icon_rect)
	else:
		var placeholder := Label.new()
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		placeholder.text = _build_placeholder_text(card_name)
		placeholder.add_theme_font_size_override("font_size", 28)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_panel.add_child(placeholder)

	var name_back := ColorRect.new()
	name_back.anchor_top = 1.0
	name_back.anchor_right = 1.0
	name_back.anchor_bottom = 1.0
	name_back.offset_left = 12.0
	name_back.offset_top = -26.0
	name_back.offset_right = -12.0
	name_back.offset_bottom = -8.0
	name_back.color = Color(0.07, 0.06, 0.05, 0.72)
	name_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name_back)

	var name_label := Label.new()
	name_label.anchor_top = 1.0
	name_label.anchor_right = 1.0
	name_label.anchor_bottom = 1.0
	name_label.offset_left = 14.0
	name_label.offset_top = -27.0
	name_label.offset_right = -14.0
	name_label.offset_bottom = -7.0
	name_label.text = card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.92, 0.98))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(name_label)

	var badge := Label.new()
	badge.text = "x%d" % max(count, 1)
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -38.0
	badge.offset_top = 8.0
	badge.offset_right = -8.0
	badge.offset_bottom = 28.0
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color(0.98, 0.94, 0.84, 1.0))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(badge)

	var hover_glow := _build_hover_glow(tier)
	root.add_child(hover_glow)
	button.set_meta("hover_glow", hover_glow)

	button.mouse_entered.connect(_on_slot_hovered.bind(stack_key))
	button.mouse_entered.connect(_set_button_hover_glow.bind(button, true))
	button.mouse_exited.connect(_set_button_hover_glow.bind(button, false))
	button.pressed.connect(_on_slot_hovered.bind(stack_key))
	return button


func _show_detail(stack_info: Dictionary) -> void:
	if stack_info.is_empty():
		_show_empty_detail()
		return
	var card_row: Dictionary = stack_info.get("row", {})
	var stack_key := String(stack_info.get("stack_key", "")).strip_edges()
	var card_name := String(card_row.get("name", card_row.get("id", "神权")))
	var tier := int(card_row.get("tier", 0))
	var description := String(card_row.get("description", "暂无描述")).strip_edges()
	selected_stack_key = stack_key
	_set_label_text(detail_title_label, card_name)
	_set_label_text(detail_tier_label, "阶级 %d" % tier)
	detail_tier_label.modulate = _get_tier_colors(tier).get("border", Color(0.87, 0.78, 0.51, 1.0)) as Color
	detail_description_label.text = description
	_apply_detail_icon_panel_style(tier)

	var icon_texture := stack_info.get("icon_texture", null) as Texture2D
	detail_icon_rect.texture = icon_texture
	detail_icon_rect.visible = icon_texture != null
	detail_placeholder_label.visible = icon_texture == null
	if icon_texture == null:
		detail_placeholder_label.text = _build_placeholder_text(card_name)
	_refresh_slot_highlight()


func _show_empty_detail() -> void:
	_set_label_text(detail_title_label, "神权收藏")
	_set_label_text(detail_tier_label, "等待选择")
	detail_tier_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	detail_description_label.text = "当前还没有神权，完成选择后会在这里显示实时说明。"
	detail_icon_rect.texture = null
	detail_icon_rect.visible = false
	detail_placeholder_label.visible = true
	detail_placeholder_label.text = "神权"
	_apply_detail_icon_panel_style(0)
	selected_stack_key = ""
	_refresh_slot_highlight()


func _refresh_slot_highlight() -> void:
	for button in slot_buttons:
		if button == null or not is_instance_valid(button):
			continue
		var stack_key := String(button.get_meta("stack_key", "")).strip_edges()
		var tier := int(button.get_meta("card_tier", 0))
		_apply_slot_style(button, tier, stack_key == selected_stack_key)


func _find_stack_info(stack_key: String) -> Dictionary:
	for stack_info in stack_infos:
		if String(stack_info.get("stack_key", "")).strip_edges() == stack_key:
			return stack_info
	return {}


func _apply_sort_button_styles() -> void:
	var normal_bg := Color(0.16, 0.11, 0.08, 0.94)
	var active_bg := Color(0.31, 0.18, 0.08, 0.98)
	var normal_border := Color(0.54, 0.40, 0.24, 0.95)
	var active_border := Color(0.96, 0.82, 0.45, 1.0)
	for entry in [
		{"button": sort_time_button, "mode": "time"},
		{"button": sort_quality_button, "mode": "quality"},
	]:
		var btn := entry.get("button", null) as Button
		if btn == null:
			continue
		var is_active := sort_mode == String(entry.get("mode", ""))
		var style := StyleBoxFlat.new()
		style.bg_color = active_bg if is_active else normal_bg
		style.border_color = active_border if is_active else normal_border
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0.0, 3.0)
		var hover_style := style.duplicate()
		hover_style.bg_color = style.bg_color.lightened(0.10)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)
		btn.add_theme_stylebox_override("focus", hover_style)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color(0.98, 0.96, 0.92, 1.0))


func _apply_detail_icon_panel_style(tier: int) -> void:
	var border_color := Color(0.46, 0.44, 0.33, 1.0)
	if tier > 0:
		border_color = (_get_tier_colors(tier).get("border", border_color) as Color).lightened(0.06)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.13, 1.0)
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = border_color.darkened(0.7)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 4.0)
	detail_icon_panel.add_theme_stylebox_override("panel", style)


func _apply_slot_style(button: Button, tier: int, is_selected: bool) -> void:
	var colors := _get_tier_colors(tier)
	var tier_border := colors.get("border", Color(0.55, 0.55, 0.55, 1.0)) as Color
	var selected_border := Color(0.96, 0.80, 0.36, 1.0)
	var border_color := selected_border if is_selected else tier_border
	var border_width := 3 if is_selected else 2
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	normal_style.border_color = border_color
	normal_style.set_border_width_all(border_width)
	normal_style.set_corner_radius_all(16)
	normal_style.shadow_color = border_color.darkened(0.6) if is_selected else Color(0.0, 0.0, 0.0, 0.26)
	normal_style.shadow_size = 10 if is_selected else 5
	normal_style.shadow_offset = Vector2(0.0, 5.0)
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.0, 0.0, 0.0, 0.10)
	hover_style.border_color = selected_border.lightened(0.08) if is_selected else tier_border.lightened(0.18)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_font_size_override("font_size", 15)


func _build_hover_glow(tier: int) -> ColorRect:
	var overlay_rect := ColorRect.new()
	overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_rect.color = Color.WHITE
	overlay_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if hover_glow_shader == null:
		hover_glow_shader = Shader.new()
		hover_glow_shader.code = """
shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(1.0, 0.86, 0.45, 1.0);
uniform float start_time = 0.0;

void fragment() {
	vec2 uv = UV;
	float local_time = max(TIME - start_time, 0.0);
	float sweep = fract(local_time * 0.75);
	float diag = uv.x * 0.96 + uv.y * 0.84;
	float beam = smoothstep(0.26, 0.02, abs(diag - (sweep * 2.10 - 0.36)));
	float beam_tail = smoothstep(0.45, 0.08, abs(diag - (sweep * 2.10 - 0.42))) * 0.40;
	float center = smoothstep(0.72, 0.08, distance(uv, vec2(0.5, 0.5))) * 0.10;
	float edge = (1.0 - smoothstep(0.0, 0.08, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)))) * 0.34;
	float shimmer = pow(max(sin((uv.x * 12.0 - uv.y * 9.0) + local_time * 5.5), 0.0), 5.0) * 0.10;
	float alpha = clamp(beam * 1.05 + beam_tail + edge + center + shimmer, 0.0, 1.0);
	COLOR = vec4(glow_color.rgb * alpha, alpha);
}
"""
	var glow_material: ShaderMaterial = ShaderMaterial.new()
	glow_material.shader = hover_glow_shader
	glow_material.set_shader_parameter("glow_color", (_get_tier_colors(tier).get("border", Color(0.98, 0.87, 0.46, 1.0)) as Color).lightened(0.18))
	glow_material.set_shader_parameter("start_time", 0.0)
	overlay_rect.material = glow_material
	return overlay_rect


func _set_button_hover_glow(button: Button, is_hovered: bool) -> void:
	if button == null or not button.has_meta("hover_glow"):
		return
	var hover_glow: Variant = button.get_meta("hover_glow")
	if not (hover_glow is ColorRect):
		return
	var glow_rect := hover_glow as ColorRect
	if is_hovered and glow_rect.material is ShaderMaterial:
		var glow_material := glow_rect.material as ShaderMaterial
		glow_material.set_shader_parameter("start_time", float(Time.get_ticks_msec()) / 1000.0)
	var target_alpha := 0.92 if is_hovered else 0.0
	var tween: Tween = null
	if button.has_meta("hover_glow_tween"):
		var tween_meta: Variant = button.get_meta("hover_glow_tween")
		if tween_meta is Tween:
			tween = tween_meta as Tween
	if tween != null:
		tween.kill()
	tween = create_tween()
	tween.tween_property(glow_rect, "modulate:a", target_alpha, 0.18 if is_hovered else 0.14)
	button.set_meta("hover_glow_tween", tween)


func _get_tier_colors(tier: int) -> Dictionary:
	match tier:
		6:
			return {"bg": Color(0.28, 0.08, 0.09, 0.96), "border": Color(0.93, 0.24, 0.24, 1.0)}
		5:
			return {"bg": Color(0.28, 0.15, 0.05, 0.96), "border": Color(0.96, 0.60, 0.18, 1.0)}
		4:
			return {"bg": Color(0.19, 0.11, 0.25, 0.96), "border": Color(0.70, 0.45, 0.95, 1.0)}
		3:
			return {"bg": Color(0.07, 0.15, 0.24, 0.96), "border": Color(0.29, 0.63, 0.96, 1.0)}
		2:
			return {"bg": Color(0.09, 0.18, 0.11, 0.96), "border": Color(0.36, 0.81, 0.40, 1.0)}
		1:
			return {"bg": Color(0.18, 0.18, 0.18, 0.96), "border": Color(0.92, 0.92, 0.92, 1.0)}
		_:
			return {"bg": Color(0.14, 0.16, 0.13, 0.96), "border": Color(0.82, 0.77, 0.59, 1.0)}


func _load_frame_texture(tier: int) -> Texture2D:
	var path := "%s/tier_%d_%s.png" % [CARD_CHOICE_FRAME_DIR, tier, _tier_asset_suffix(tier)]
	if frame_texture_cache.has(path):
		return frame_texture_cache.get(path, null) as Texture2D
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	frame_texture_cache[path] = texture
	return texture


func _tier_asset_suffix(tier: int) -> String:
	match tier:
		1:
			return "white"
		2:
			return "green"
		3:
			return "blue"
		4:
			return "purple"
		5:
			return "orange"
		6:
			return "red"
		_:
			return "white"


func _build_placeholder_text(card_name: String) -> String:
	var compact_name := card_name.strip_edges()
	if compact_name.length() <= 4:
		return compact_name
	return compact_name.substr(0, 4)


func _on_close_button_pressed() -> void:
	close_requested.emit()


func _on_sort_button_pressed(mode: String) -> void:
	if mode != "time" and mode != "quality":
		return
	if sort_mode == mode:
		return
	sort_mode = mode
	_apply_sort_button_styles()
	sort_mode_changed.emit(mode)


func _on_slot_hovered(stack_key: String) -> void:
	var stack_info := _find_stack_info(stack_key)
	if stack_info.is_empty():
		return
	_show_detail(stack_info)
	stack_selected.emit(stack_key)


func _on_overlay_gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button == null:
		return
	if mouse_button.button_index != MOUSE_BUTTON_LEFT or not mouse_button.pressed:
		return
	if main_panel.get_global_rect().has_point(mouse_button.global_position):
		return
	close_requested.emit()


func _set_label_text(label: Label, value: String) -> void:
	if label != null and label.text != value:
		label.text = value
