extends Control
class_name CardChoiceOverlayUi

signal option_selected(index: int)
signal refresh_requested

const CARD_CHOICE_FRAME_DIR := "res://assets/ui/card_choice/frames"
const CARD_CHOICE_SELECTION_SHADER_RESOURCE := preload("res://assets/shaders/card_choice_selected_highlight.gdshader")
const CARD_CHOICE_TEMPLATE_SLOT_COUNT := 9
const CARD_ICON_FALLBACK_DIR := "res://assets/ui/icons/cards"
const CARD_NAME_MAX_FONT_SIZE := 18
const CARD_NAME_MIN_FONT_SIZE := 13
const CARD_DESCRIPTION_MAX_FONT_SIZE := 13
const CARD_DESCRIPTION_MIN_FONT_SIZE := 8
const CARD_NAME_ANCHOR_Y := 0.523
const CARD_NAME_HALF_HEIGHT := 13.0

@onready var main_panel: Panel = get_node("主面板") as Panel
@onready var title_label: Label = get_node("主面板/标题") as Label
@onready var hint_label: Label = get_node("主面板/提示") as Label
@onready var button_row: HFlowContainer = get_node("主面板/卡牌行") as HFlowContainer
@onready var refresh_count_label: Label = get_node_or_null("主面板/详情区/剩余刷新次数") as Label
@onready var refresh_button: BaseButton = get_node_or_null("主面板/详情区/刷新按钮") as BaseButton

var choice_rows: Array[Dictionary] = []
var slot_nodes: Array[Dictionary] = []
var visible_buttons: Array[Button] = []
var slot_template_button: Button
var selected_index := -1
var refresh_remaining := 0
var interaction_locked := false
var open_transition_tween: Tween
var frame_texture_cache: Dictionary = {}
var icon_texture_cache: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	_cache_slot_nodes()
	_apply_slot_runtime_texture_settings()
	if refresh_button != null and not refresh_button.pressed.is_connected(_on_refresh_button_pressed):
		refresh_button.pressed.connect(_on_refresh_button_pressed)
	if not resized.is_connected(_layout_overlay):
		resized.connect(_layout_overlay)
	_layout_overlay()
	clear_choices()


func configure_choices(rows: Array[Dictionary], overlay_title: String, remaining_refresh_count: int) -> void:
	choice_rows.clear()
	for row in rows:
		choice_rows.append(row.duplicate(true))
	refresh_remaining = remaining_refresh_count
	selected_index = -1
	interaction_locked = false
	_set_label_text(title_label, overlay_title)
	_refresh_hint_text()
	_update_refresh_ui()
	_rebuild_choice_slots()
	if choice_rows.is_empty():
		_show_empty_detail()
	else:
		_show_choice_detail(0)
	_layout_overlay()


func play_open_transition() -> void:
	if open_transition_tween != null:
		open_transition_tween.kill()
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	if main_panel != null:
		main_panel.scale = Vector2(0.96, 0.96)
	open_transition_tween = create_tween()
	open_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	open_transition_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)
	if main_panel != null:
		open_transition_tween.parallel().tween_property(main_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func clear_choices() -> void:
	choice_rows.clear()
	visible_buttons.clear()
	selected_index = -1
	refresh_remaining = 0
	interaction_locked = false
	if open_transition_tween != null:
		open_transition_tween.kill()
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if main_panel != null:
		main_panel.scale = Vector2.ONE
	for slot in slot_nodes:
		var button := slot.get("button") as Button
		if button == null:
			continue
		button.visible = false
		button.disabled = true
		_set_button_selection_effect(button, 1, false)
	_show_empty_detail()
	_refresh_hint_text()
	_update_refresh_ui()


func set_interaction_locked(locked: bool) -> void:
	interaction_locked = locked
	for button in visible_buttons:
		if button == null:
			continue
		button.disabled = locked
	_update_refresh_ui()


func get_option_global_center(index: int) -> Vector2:
	if index < 0 or index >= slot_nodes.size():
		return Vector2.ZERO
	var button := slot_nodes[index].get("button") as Button
	if button == null:
		return Vector2.ZERO
	var rect := button.get_global_rect()
	return rect.position + rect.size * 0.5


func _cache_slot_nodes() -> void:
	if not slot_nodes.is_empty():
		return
	if button_row == null:
		return
	var buttons: Array[Button] = []
	for child in button_row.get_children():
		var button: Button = child as Button
		if button == null:
			continue
		buttons.append(button)
	if buttons.is_empty():
		return
	if slot_template_button == null:
		slot_template_button = buttons[0]
	while buttons.size() < CARD_CHOICE_TEMPLATE_SLOT_COUNT:
		var duplicated: Node = slot_template_button.duplicate()
		var duplicated_button: Button = duplicated as Button
		if duplicated_button == null:
			break
		duplicated_button.name = "卡牌%d" % (buttons.size() + 1)
		duplicated_button.visible = false
		button_row.add_child(duplicated_button)
		buttons.append(duplicated_button)
	slot_nodes.clear()
	for button in buttons:
		_register_slot_button(button)


func _register_slot_button(button: Button) -> void:
	var root := button.get_node_or_null("根") as Control
	if root == null:
		return
	_clear_runtime_selection_effect(button)
	var slot_index := slot_nodes.size()
	var selection_highlight := _build_selection_highlight()
	root.add_child(selection_highlight)
	button.set_meta("selection_highlight", selection_highlight)
	button.mouse_entered.connect(_on_option_hovered.bind(button, slot_index))
	button.mouse_exited.connect(_on_option_unhovered.bind(button))
	button.pressed.connect(_on_option_pressed.bind(slot_index))
	var name_label := root.get_node("名字") as Label
	var description_label := root.get_node_or_null("描述") as Label
	name_label.z_index = 10
	if description_label != null:
		description_label.z_index = 10
	slot_nodes.append(
		{
			"button": button,
			"root": root,
			"frame": root.get_node("卡框") as TextureRect,
			"name_label": name_label,
			"icon_rect": root.get_node("图标容器/图标") as TextureRect,
			"placeholder": root.get_node("图标容器/占位") as Label,
			"description_label": description_label,
		}
	)


func _ensure_slot_count(required_count: int) -> void:
	var target_count: int = maxi(required_count, 0)
	if slot_template_button == null:
		return
	while slot_nodes.size() < target_count:
		var duplicated: Node = slot_template_button.duplicate()
		var button: Button = duplicated as Button
		if button == null:
			return
		button.name = "卡牌%d" % (slot_nodes.size() + 1)
		button.visible = false
		button_row.add_child(button)
		_register_slot_button(button)


func _apply_slot_runtime_texture_settings() -> void:
	for slot in slot_nodes:
		var frame_rect: TextureRect = slot.get("frame") as TextureRect
		if frame_rect != null:
			frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
		var icon_rect: TextureRect = slot.get("icon_rect") as TextureRect
		if icon_rect != null:
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _layout_overlay() -> void:
	if main_panel != null:
		main_panel.pivot_offset = main_panel.size * 0.5


func _refresh_hint_text() -> void:
	var choice_count := maxi(choice_rows.size(), 1)
	_set_label_text(hint_label, "从 %d 张神权中选择 1 张，点击卡牌立即生效" % choice_count)


func _update_refresh_ui() -> void:
	_set_label_text(refresh_count_label, "剩余刷新 %d 次" % maxi(refresh_remaining, 0))
	if refresh_button != null:
		refresh_button.disabled = interaction_locked or refresh_remaining <= 0
		refresh_button.modulate = Color.WHITE


func _rebuild_choice_slots() -> void:
	visible_buttons.clear()
	_ensure_slot_count(choice_rows.size())
	for slot_index in slot_nodes.size():
		var slot: Dictionary = slot_nodes[slot_index]
		var button := slot.get("button") as Button
		if button == null:
			continue
		if slot_index < choice_rows.size():
			_populate_slot(slot, choice_rows[slot_index], slot_index)
			button.visible = true
			button.disabled = interaction_locked
			visible_buttons.append(button)
		else:
			button.visible = false
			button.disabled = true
	_layout_overlay()


func _populate_slot(slot: Dictionary, row: Dictionary, index: int) -> void:
	var button := slot.get("button") as Button
	if button == null:
		return
	var tier := int(row.get("tier", 0))
	_apply_button_style(button, tier, index == selected_index)

	var frame_rect := slot.get("frame") as TextureRect
	if frame_rect != null:
		frame_rect.texture = _load_frame_texture(tier)
		_sync_selection_highlight_to_frame(button, frame_rect, tier)

	var name_label := slot.get("name_label") as Label
	var card_name := String(row.get("name", row.get("id", "神权"))).strip_edges()
	if name_label != null:
		_apply_name_label_rect_for_tier(name_label, tier)
		var name_color: Color = Color(0.98, 0.96, 0.92, 1.0)
		var name_outline_color: Color = Color(0.10, 0.08, 0.05, 0.88)
		name_label.add_theme_color_override("font_color", name_color)
		name_label.add_theme_color_override("font_outline_color", name_outline_color)
		name_label.add_theme_constant_override("outline_size", 2)
		_fit_label_font_to_rect(name_label, card_name, CARD_NAME_MAX_FONT_SIZE, CARD_NAME_MIN_FONT_SIZE, false)

	var description_label := slot.get("description_label") as Label
	if description_label != null:
		var description_color: Color = Color(0.97, 0.95, 0.90, 0.98)
		var description_outline_color: Color = Color(0.10, 0.08, 0.05, 0.76)
		description_label.add_theme_color_override("font_color", description_color)
		description_label.add_theme_color_override("font_outline_color", description_outline_color)
		description_label.add_theme_constant_override("outline_size", 1)
		_fit_label_font_to_rect(description_label, String(row.get("description", "暂无描述")).strip_edges(), CARD_DESCRIPTION_MAX_FONT_SIZE, CARD_DESCRIPTION_MIN_FONT_SIZE, true)

	var icon_rect := slot.get("icon_rect") as TextureRect
	var placeholder := slot.get("placeholder") as Label
	var icon_texture := _get_icon_texture(row)
	if icon_rect != null:
		icon_rect.texture = icon_texture
		icon_rect.visible = icon_texture != null
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if placeholder != null:
		placeholder.text = _build_placeholder_text(card_name)
		placeholder.visible = icon_texture == null

	_refresh_selection_highlight()


func _show_choice_detail(index: int) -> void:
	if index < 0 or index >= choice_rows.size():
		return
	var reset_selection_effect := selected_index != index
	selected_index = index
	_refresh_selection_highlight(reset_selection_effect)


func _show_empty_detail() -> void:
	selected_index = -1
	_refresh_selection_highlight()


func _refresh_selection_highlight(reset_selected_effect: bool = false) -> void:
	for button_index in visible_buttons.size():
		var button := visible_buttons[button_index]
		if button == null or button_index >= choice_rows.size():
			continue
		var tier: int = int(choice_rows[button_index].get("tier", 0))
		var is_selected: bool = button_index == selected_index
		_apply_button_style(button, tier, is_selected)
		_set_button_selection_effect(button, tier, is_selected, reset_selected_effect and is_selected)


func _on_option_hovered(_button: Button, index: int) -> void:
	_show_choice_detail(index)


func _on_option_unhovered(_button: Button) -> void:
	pass


func _on_option_pressed(index: int) -> void:
	if interaction_locked:
		return
	if index < 0 or index >= choice_rows.size() or index >= visible_buttons.size():
		return
	interaction_locked = true
	for button in visible_buttons:
		if button != null:
			button.disabled = true
	_update_refresh_ui()
	_show_choice_detail(index)
	var tier := int(choice_rows[index].get("tier", 0))
	_play_selection_confirm_burst(visible_buttons[index], tier)
	var confirm_tween := create_tween()
	confirm_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	confirm_tween.tween_interval(0.16)
	confirm_tween.tween_callback(func() -> void: option_selected.emit(index))


func _on_refresh_button_pressed() -> void:
	if interaction_locked or refresh_remaining <= 0:
		return
	refresh_requested.emit()


func _apply_button_style(button: Button, tier: int, _is_selected: bool) -> void:
	var colors := _get_tier_colors(tier)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	normal_style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	normal_style.set_border_width_all(0)
	normal_style.set_corner_radius_all(18)
	normal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.10)
	normal_style.shadow_size = 2
	normal_style.shadow_offset = Vector2(0.0, 4.0)
	var hover_style := normal_style.duplicate()
	var bg_color := colors.get("bg", Color(0.14, 0.16, 0.13, 0.96)) as Color
	hover_style.bg_color = Color(bg_color.r, bg_color.g, bg_color.b, 0.02)
	hover_style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)


func _clear_runtime_selection_effect(button: Button) -> void:
	if button == null:
		return
	if button.has_meta("selection_effect_tween"):
		var tween_meta: Variant = button.get_meta("selection_effect_tween")
		if tween_meta is Tween:
			(tween_meta as Tween).kill()
	if button.has_meta("selection_card_tween"):
		var card_tween_meta: Variant = button.get_meta("selection_card_tween")
		if card_tween_meta is Tween:
			(card_tween_meta as Tween).kill()
	if button.has_meta("selection_flash_tween"):
		var flash_tween_meta: Variant = button.get_meta("selection_flash_tween")
		if flash_tween_meta is Tween:
			(flash_tween_meta as Tween).kill()
	if button.has_meta("selection_sweep_tween"):
		var sweep_tween_meta: Variant = button.get_meta("selection_sweep_tween")
		if sweep_tween_meta is Tween:
			(sweep_tween_meta as Tween).kill()
	button.remove_meta("selection_highlight")
	button.remove_meta("selection_effect_tween")
	button.remove_meta("selection_card_tween")
	button.remove_meta("selection_flash_tween")
	button.remove_meta("selection_sweep_tween")
	var root := button.get_node_or_null("根") as Control
	if root == null:
		return
	for child in root.get_children():
		if child.name == "__runtime_selection_highlight":
			child.queue_free()


func _build_selection_highlight() -> TextureRect:
	var overlay := TextureRect.new()
	overlay.name = "__runtime_selection_highlight"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.z_index = 20
	overlay.modulate = Color.WHITE
	overlay.visible = false
	if CARD_CHOICE_SELECTION_SHADER_RESOURCE != null:
		var selection_material := ShaderMaterial.new()
		selection_material.shader = CARD_CHOICE_SELECTION_SHADER_RESOURCE
		selection_material.set_shader_parameter("strength", 0.0)
		selection_material.set_shader_parameter("flash_strength", 0.0)
		selection_material.set_shader_parameter("sweep_progress", 0.0)
		overlay.material = selection_material
	return overlay


func _sync_selection_highlight_to_frame(button: Button, frame_rect: TextureRect, tier: int) -> void:
	if button == null or frame_rect == null or not button.has_meta("selection_highlight"):
		return
	var highlight_meta: Variant = button.get_meta("selection_highlight")
	if not (highlight_meta is TextureRect):
		return
	var highlight_rect := highlight_meta as TextureRect
	highlight_rect.texture = frame_rect.texture
	highlight_rect.anchor_left = frame_rect.anchor_left
	highlight_rect.anchor_top = frame_rect.anchor_top
	highlight_rect.anchor_right = frame_rect.anchor_right
	highlight_rect.anchor_bottom = frame_rect.anchor_bottom
	highlight_rect.offset_left = frame_rect.offset_left
	highlight_rect.offset_top = frame_rect.offset_top
	highlight_rect.offset_right = frame_rect.offset_right
	highlight_rect.offset_bottom = frame_rect.offset_bottom
	highlight_rect.pivot_offset = frame_rect.size * 0.5
	highlight_rect.expand_mode = frame_rect.expand_mode
	highlight_rect.stretch_mode = frame_rect.stretch_mode
	highlight_rect.z_index = frame_rect.z_index + 1
	var colors := _get_tier_colors(tier)
	var border_color := colors.get("border", Color(0.82, 0.77, 0.59, 1.0)) as Color
	var selection_material := highlight_rect.material as ShaderMaterial
	if selection_material != null:
		selection_material.set_shader_parameter("glow_color", border_color.lightened(0.42))


func _set_button_selection_effect(button: Button, _tier: int, is_selected: bool, reset_sweep: bool = false) -> void:
	if button == null or not button.has_meta("selection_highlight"):
		return
	var highlight_meta: Variant = button.get_meta("selection_highlight")
	if not (highlight_meta is TextureRect):
		return
	var highlight_rect := highlight_meta as TextureRect
	var selection_material := highlight_rect.material as ShaderMaterial
	var effect_tween: Tween = null
	if button.has_meta("selection_effect_tween"):
		var tween_meta: Variant = button.get_meta("selection_effect_tween")
		if tween_meta is Tween:
			effect_tween = tween_meta as Tween
	if effect_tween != null:
		effect_tween.kill()

	var root := button.get_node_or_null("根") as Control
	if root != null:
		root.pivot_offset = root.size * 0.5
	var card_tween: Tween = null
	if button.has_meta("selection_card_tween"):
		var card_tween_meta: Variant = button.get_meta("selection_card_tween")
		if card_tween_meta is Tween:
			card_tween = card_tween_meta as Tween
	if card_tween != null:
		card_tween.kill()
	card_tween = create_tween()
	card_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	effect_tween = create_tween()
	effect_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if is_selected:
		button.z_index = 5
		highlight_rect.visible = true
		if selection_material != null:
			effect_tween.tween_property(selection_material, "shader_parameter/strength", 1.38, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_start_selection_sweep(button, selection_material, reset_sweep)
		if root != null:
			card_tween.tween_property(root, "position:y", -8.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			card_tween.parallel().tween_property(root, "scale", Vector2(1.035, 1.035), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		button.z_index = 0
		_stop_selection_sweep(button, selection_material)
		if selection_material != null:
			effect_tween.tween_property(selection_material, "shader_parameter/strength", 0.0, 0.14)
		effect_tween.tween_callback(func() -> void: highlight_rect.visible = false)
		if root != null:
			card_tween.tween_property(root, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			card_tween.parallel().tween_property(root, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.set_meta("selection_effect_tween", effect_tween)
	button.set_meta("selection_card_tween", card_tween)


func _start_selection_sweep(button: Button, selection_material: ShaderMaterial, reset_sweep: bool) -> void:
	if button == null or selection_material == null:
		return
	if button.has_meta("selection_sweep_tween"):
		var existing_tween_meta: Variant = button.get_meta("selection_sweep_tween")
		if existing_tween_meta is Tween and (existing_tween_meta as Tween).is_running() and not reset_sweep:
			return
		if existing_tween_meta is Tween:
			(existing_tween_meta as Tween).kill()
	if reset_sweep:
		selection_material.set_shader_parameter("sweep_progress", 0.0)
	var sweep_tween := create_tween()
	sweep_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	sweep_tween.set_loops()
	sweep_tween.tween_property(selection_material, "shader_parameter/sweep_progress", 1.0, 1.15).from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sweep_tween.tween_interval(0.22)
	button.set_meta("selection_sweep_tween", sweep_tween)


func _stop_selection_sweep(button: Button, selection_material: ShaderMaterial) -> void:
	if button == null:
		return
	if button.has_meta("selection_sweep_tween"):
		var sweep_tween_meta: Variant = button.get_meta("selection_sweep_tween")
		if sweep_tween_meta is Tween:
			(sweep_tween_meta as Tween).kill()
		button.remove_meta("selection_sweep_tween")
	if selection_material != null:
		selection_material.set_shader_parameter("sweep_progress", 0.0)


func _play_selection_confirm_burst(button: Button, _tier: int) -> void:
	if button == null or not button.has_meta("selection_highlight"):
		return
	var highlight_meta: Variant = button.get_meta("selection_highlight")
	if not (highlight_meta is TextureRect):
		return
	var highlight_rect := highlight_meta as TextureRect
	var selection_material := highlight_rect.material as ShaderMaterial
	if selection_material == null:
		return
	highlight_rect.visible = true
	selection_material.set_shader_parameter("strength", 1.65)
	selection_material.set_shader_parameter("flash_strength", 2.6)
	var flash_tween: Tween = null
	if button.has_meta("selection_flash_tween"):
		var tween_meta: Variant = button.get_meta("selection_flash_tween")
		if tween_meta is Tween:
			flash_tween = tween_meta as Tween
	if flash_tween != null:
		flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_tween.tween_property(selection_material, "shader_parameter/flash_strength", 0.0, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var root := button.get_node_or_null("根") as Control
	if root != null:
		flash_tween.parallel().tween_property(root, "scale", Vector2(1.06, 1.06), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flash_tween.tween_property(root, "scale", Vector2(1.035, 1.035), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.set_meta("selection_flash_tween", flash_tween)


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


func _get_icon_texture(row: Dictionary) -> Texture2D:
	var direct_icon: Texture2D = row.get("icon_texture", null) as Texture2D
	if direct_icon != null:
		return direct_icon
	var raw_direct_icon: Variant = row.get("icon_texture", null)
	if raw_direct_icon is Texture2D:
		return raw_direct_icon as Texture2D
	var icon_ref := String(row.get("icon", "")).strip_edges()
	if icon_ref.is_empty():
		return null
	if icon_texture_cache.has(icon_ref):
		return icon_texture_cache.get(icon_ref, null) as Texture2D
	var texture: Texture2D = null
	if ResourceLoader.exists(icon_ref):
		texture = load(icon_ref) as Texture2D
		icon_texture_cache[icon_ref] = texture
		return texture
	var fallback_path := "%s/%s.png" % [CARD_ICON_FALLBACK_DIR, icon_ref]
	if ResourceLoader.exists(fallback_path):
		texture = load(fallback_path) as Texture2D
	icon_texture_cache[icon_ref] = texture
	return texture


func _build_placeholder_text(card_name: String) -> String:
	var compact_name := card_name.strip_edges()
	if compact_name.length() <= 4:
		return compact_name
	return compact_name.substr(0, 4)


func _set_label_text(label: Label, value: String) -> void:
	if label != null and label.text != value:
		label.text = value


func _apply_name_label_rect_for_tier(label: Label, tier: int) -> void:
	var y_offset := 0.0
	if tier == 4:
		y_offset = -4.0
	label.anchor_top = CARD_NAME_ANCHOR_Y
	label.anchor_bottom = CARD_NAME_ANCHOR_Y
	label.offset_top = -CARD_NAME_HALF_HEIGHT + y_offset
	label.offset_bottom = CARD_NAME_HALF_HEIGHT + y_offset


func _fit_label_font_to_rect(label: Label, value: String, max_font_size: int, min_font_size: int, multiline: bool) -> void:
	if label == null:
		return
	label.text = value
	label.clip_text = true
	var available_size := label.size
	if available_size.x <= 1.0:
		available_size.x = maxf(label.offset_right - label.offset_left, 1.0)
	if available_size.y <= 1.0:
		available_size.y = maxf(label.offset_bottom - label.offset_top, 1.0)
	var font := label.get_theme_font("font")
	if font == null:
		label.add_theme_font_size_override("font_size", max_font_size)
		return
	for font_size in range(max_font_size, min_font_size - 1, -1):
		var measured_size := _measure_label_text(label, font, value, font_size, available_size.x, multiline)
		if measured_size.x <= available_size.x + 1.0 and measured_size.y <= available_size.y + 1.0:
			label.add_theme_font_size_override("font_size", font_size)
			return
	label.add_theme_font_size_override("font_size", min_font_size)


func _measure_label_text(label: Label, font: Font, value: String, font_size: int, available_width: float, multiline: bool) -> Vector2:
	if multiline:
		return font.get_multiline_string_size(value, label.horizontal_alignment, available_width, font_size)
	return font.get_string_size(value, label.horizontal_alignment, -1.0, font_size)
