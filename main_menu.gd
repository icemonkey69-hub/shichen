extends Control

const GAME_SCENE_PATH := "res://game.tscn"
const CARD_TABLE_NAME: StringName = &"cards"
const CARD_ICON_FALLBACK_DIR := "res://assets/ui/icons/cards"
const CARD_ICON_EXTENSIONS := ["png", "webp", "jpg", "jpeg", "svg"]

@onready var start_button: Button = $CenterPanel/MarginContainer/VBoxContainer/StartButton
@onready var archive_button: Button = $CenterPanel/MarginContainer/VBoxContainer/ArchiveButton
@onready var backpack_overlay: ColorRect = $BackpackOverlay
@onready var card_backpack_panel: Panel = $CardBackpackPanel
@onready var close_backpack_button: Button = $CardBackpackPanel/Header/CloseButton
@onready var filter_all_button: Button = $CardBackpackPanel/Body/LeftPane/FilterBar/FilterAll
@onready var filter_tier_1_button: Button = $CardBackpackPanel/Body/LeftPane/FilterBar/FilterTier1
@onready var filter_tier_2_button: Button = $CardBackpackPanel/Body/LeftPane/FilterBar/FilterTier2
@onready var filter_tier_3_button: Button = $CardBackpackPanel/Body/LeftPane/FilterBar/FilterTier3
@onready var filter_tier_4_button: Button = $CardBackpackPanel/Body/LeftPane/FilterBar/FilterTier4
@onready var filter_tier_5_button: Button = $CardBackpackPanel/Body/LeftPane/FilterBar/FilterTier5
@onready var filter_tier_6_button: Button = $CardBackpackPanel/Body/LeftPane/FilterBar/FilterTier6
@onready var card_grid: GridContainer = $CardBackpackPanel/Body/LeftPane/ScrollContainer/ScrollContent/CardGrid
@onready var empty_label: Label = $CardBackpackPanel/Body/LeftPane/EmptyLabel
@onready var detail_title_label: Label = $CardBackpackPanel/Body/RightPane/DetailHeader/DetailTitle
@onready var detail_tier_label: Label = $CardBackpackPanel/Body/RightPane/DetailHeader/TierBadge
@onready var detail_icon_rect: TextureRect = $CardBackpackPanel/Body/RightPane/IconPanel/Icon
@onready var detail_placeholder_label: Label = $CardBackpackPanel/Body/RightPane/IconPanel/Placeholder
@onready var detail_meta_container: GridContainer = $CardBackpackPanel/Body/RightPane/Meta
@onready var detail_description_label: RichTextLabel = $CardBackpackPanel/Body/RightPane/Description

var card_rows: Array[Dictionary] = []
var active_tier_filter: int = 0
var filter_buttons_by_tier: Dictionary = {}
var selected_card_id := ""
var card_slot_buttons: Array[Button] = []


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	archive_button.pressed.connect(_on_archive_button_pressed)
	archive_button.disabled = false
	archive_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_backpack_button.pressed.connect(_hide_card_backpack)
	backpack_overlay.gui_input.connect(_on_backpack_overlay_gui_input)
	backpack_overlay.visible = false
	backpack_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	card_backpack_panel.visible = false
	card_backpack_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if detail_meta_container != null:
		detail_meta_container.visible = false
	_setup_filter_buttons()
	_load_card_rows()
	_rebuild_card_backpack()


func _on_start_button_pressed() -> void:
	var scene_tree := get_tree()
	if scene_tree == null:
		return

	var error_code: Error = scene_tree.change_scene_to_file(GAME_SCENE_PATH)
	if error_code != OK:
		push_error("无法进入游戏场景：%s（错误码 %d）" % [GAME_SCENE_PATH, int(error_code)])


func _on_archive_button_pressed() -> void:
	if card_backpack_panel.visible:
		_hide_card_backpack()
	else:
		_show_card_backpack()


func _show_card_backpack() -> void:
	_reset_card_filter()
	_rebuild_card_backpack()
	backpack_overlay.visible = true
	card_backpack_panel.visible = true
	card_backpack_panel.modulate = Color(1, 1, 1, 1)
	backpack_overlay.move_to_front()
	card_backpack_panel.move_to_front()


func _hide_card_backpack() -> void:
	_reset_card_filter()
	_rebuild_card_backpack()
	backpack_overlay.visible = false
	card_backpack_panel.visible = false


func _on_backpack_overlay_gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button == null:
		return
	if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
		_hide_card_backpack()


func _setup_filter_buttons() -> void:
	filter_buttons_by_tier = {
		0: filter_all_button,
		1: filter_tier_1_button,
		2: filter_tier_2_button,
		3: filter_tier_3_button,
		4: filter_tier_4_button,
		5: filter_tier_5_button,
		6: filter_tier_6_button,
	}
	for tier in filter_buttons_by_tier.keys():
		var filter_button := filter_buttons_by_tier[tier] as Button
		if filter_button == null:
			continue
		filter_button.focus_mode = Control.FOCUS_NONE
		filter_button.mouse_filter = Control.MOUSE_FILTER_STOP
		filter_button.pressed.connect(_on_filter_button_pressed.bind(int(tier)))
	_update_filter_button_styles()


func _on_filter_button_pressed(tier: int) -> void:
	if tier <= 0:
		active_tier_filter = 0
	elif active_tier_filter == tier:
		active_tier_filter = 0
	else:
		active_tier_filter = tier
	_update_filter_button_styles()
	_rebuild_card_backpack()


func _reset_card_filter() -> void:
	active_tier_filter = 0
	_update_filter_button_styles()


func _update_filter_button_styles() -> void:
	for tier in filter_buttons_by_tier.keys():
		var filter_button := filter_buttons_by_tier[tier] as Button
		if filter_button == null:
			continue
		var is_active := int(tier) == active_tier_filter
		var palette := _get_filter_button_colors(int(tier), is_active)
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = palette.get("bg", Color(0.14, 0.16, 0.18, 0.94))
		normal_style.border_color = palette.get("border", Color(0.52, 0.54, 0.58, 1.0))
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(9)
		var hover_style := normal_style.duplicate()
		hover_style.bg_color = (palette.get("hover_bg", normal_style.bg_color) as Color)
		hover_style.border_color = (palette.get("hover_border", normal_style.border_color) as Color)
		filter_button.add_theme_stylebox_override("normal", normal_style)
		filter_button.add_theme_stylebox_override("hover", hover_style)
		filter_button.add_theme_stylebox_override("pressed", hover_style)
		filter_button.add_theme_stylebox_override("focus", hover_style)
		filter_button.add_theme_color_override("font_color", palette.get("font", Color(0.94, 0.94, 0.94, 1.0)))
		filter_button.add_theme_color_override("font_hover_color", palette.get("font", Color(0.94, 0.94, 0.94, 1.0)))
		filter_button.add_theme_color_override("font_pressed_color", palette.get("font", Color(0.94, 0.94, 0.94, 1.0)))


func _get_filter_button_colors(tier: int, is_active: bool) -> Dictionary:
	if tier <= 0:
		if is_active:
			return {
				"bg": Color(0.27, 0.30, 0.24, 0.98),
				"border": Color(0.89, 0.82, 0.54, 1.0),
				"hover_bg": Color(0.31, 0.34, 0.28, 1.0),
				"hover_border": Color(0.96, 0.88, 0.60, 1.0),
				"font": Color(0.98, 0.96, 0.88, 1.0),
			}
		return {
			"bg": Color(0.10, 0.12, 0.11, 0.96),
			"border": Color(0.38, 0.42, 0.36, 1.0),
			"hover_bg": Color(0.14, 0.16, 0.15, 1.0),
			"hover_border": Color(0.55, 0.59, 0.49, 1.0),
			"font": Color(0.86, 0.87, 0.84, 1.0),
		}

	var tier_colors := _get_tier_colors(tier)
	var border_color := tier_colors.get("border", Color(0.82, 0.82, 0.82, 1.0)) as Color
	var bg_color := tier_colors.get("bg", Color(0.16, 0.16, 0.16, 0.96)) as Color
	if is_active:
		return {
			"bg": bg_color.lightened(0.10),
			"border": border_color,
			"hover_bg": bg_color.lightened(0.16),
			"hover_border": border_color.lightened(0.08),
			"font": border_color.lightened(0.12),
		}
	return {
		"bg": bg_color.darkened(0.28),
		"border": border_color.darkened(0.10),
		"hover_bg": bg_color.darkened(0.14),
		"hover_border": border_color,
		"font": border_color.lightened(0.04),
	}


func _load_card_rows() -> void:
	card_rows.clear()
	var data_table := get_node_or_null("/root/DataTable")
	if data_table == null or not data_table.has_table(CARD_TABLE_NAME):
		return

	var raw_rows: Array = data_table.call("get_all", CARD_TABLE_NAME)
	for raw_row in raw_rows:
		if raw_row is Dictionary:
			card_rows.append((raw_row as Dictionary).duplicate(true))

	card_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var tier_a := int(a.get("tier", 0))
		var tier_b := int(b.get("tier", 0))
		if tier_a != tier_b:
			return tier_a < tier_b
		return str(a.get("id", "")) < str(b.get("id", ""))
	)


func _rebuild_card_backpack() -> void:
	for child in card_grid.get_children():
		child.queue_free()
	card_slot_buttons.clear()

	var visible_rows := _get_visible_card_rows()
	if visible_rows.is_empty():
		selected_card_id = ""
		empty_label.visible = true
		_show_card_detail_v2({})
		return

	empty_label.visible = false
	for row in visible_rows:
		var slot_button := _build_card_slot_v2(row)
		card_slot_buttons.append(slot_button)
		card_grid.add_child(slot_button)

	_show_card_detail_v2(visible_rows[0])


func _get_visible_card_rows() -> Array[Dictionary]:
	if active_tier_filter <= 0:
		return card_rows

	var filtered_rows: Array[Dictionary] = []
	for row in card_rows:
		if int(row.get("tier", 0)) == active_tier_filter:
			filtered_rows.append(row)
	return filtered_rows


func _build_card_slot_v2(card_row: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(92, 122)
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.text = ""

	var card_name := str(card_row.get("name", card_row.get("id", "Unnamed Card")))
	var card_id := str(card_row.get("id", "")).strip_edges()
	var card_tier := int(card_row.get("tier", 0))
	var icon_texture := _resolve_card_icon(card_row)
	if icon_texture != null:
		button.icon = icon_texture
	else:
		button.text = _build_card_placeholder_text(card_name)

	button.tooltip_text = ""
	button.set_meta("card_id", card_id)
	button.set_meta("card_tier", card_tier)
	_apply_card_slot_button_style_v2(button, card_tier, false)
	button.add_theme_font_size_override("font_size", 15)
	button.mouse_entered.connect(_show_card_detail_v2.bind(card_row))
	button.pressed.connect(_show_card_detail_v2.bind(card_row))
	return button


func _show_card_detail_v2(card_row: Dictionary) -> void:
	if card_row.is_empty():
		detail_title_label.text = "未选择卡牌"
		detail_tier_label.text = "等待选择"
		detail_description_label.text = "将鼠标移动到左侧卡牌，这里会显示详细信息。"
		detail_icon_rect.texture = null
		detail_icon_rect.visible = false
		detail_placeholder_label.visible = true
		detail_placeholder_label.text = "神权"
		selected_card_id = ""
		_refresh_card_slot_highlight_v2()
		return

	var card_name := str(card_row.get("name", card_row.get("id", "Unnamed Card")))
	var card_id := str(card_row.get("id", "")).strip_edges()
	var card_tier := int(card_row.get("tier", 0))
	var description := str(card_row.get("description", "暂无描述")).strip_edges()
	var icon_texture := _resolve_card_icon(card_row)
	var colors := _get_tier_colors(card_tier)

	detail_title_label.text = card_name
	detail_tier_label.text = "阶级 %d" % card_tier
	detail_tier_label.modulate = colors.get("border", Color(0.87, 0.78, 0.51, 1.0))
	detail_description_label.text = description

	if icon_texture != null:
		detail_icon_rect.texture = icon_texture
		detail_icon_rect.visible = true
		detail_placeholder_label.visible = false
	else:
		detail_icon_rect.texture = null
		detail_icon_rect.visible = false
		detail_placeholder_label.visible = true
		detail_placeholder_label.text = _build_card_placeholder_text(card_name)

	selected_card_id = card_id
	_refresh_card_slot_highlight_v2()


func _refresh_card_slot_highlight_v2() -> void:
	for button in card_slot_buttons:
		if button == null or not is_instance_valid(button):
			continue
		var card_id := str(button.get_meta("card_id", "")).strip_edges()
		var card_tier := int(button.get_meta("card_tier", 0))
		var is_selected := not selected_card_id.is_empty() and card_id == selected_card_id
		_apply_card_slot_button_style_v2(button, card_tier, is_selected)


func _apply_card_slot_button_style_v2(button: Button, card_tier: int, is_selected: bool) -> void:
	var colors := _get_tier_colors(card_tier)
	var bg_color := colors.get("bg", Color(0.12, 0.14, 0.16, 0.96)) as Color
	var tier_border := colors.get("border", Color(0.55, 0.55, 0.55, 1.0)) as Color
	var selected_border := Color(0.96, 0.80, 0.36, 1.0)
	var border_color := selected_border if is_selected else tier_border
	var border_width := 3 if is_selected else 2

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = bg_color
	normal_style.border_color = border_color
	normal_style.set_border_width_all(border_width)
	normal_style.set_corner_radius_all(10)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.08)
	hover_style.border_color = selected_border.lightened(0.08) if is_selected else tier_border.lightened(0.12)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)


func _build_card_slot(card_row: Dictionary) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(92, 122)
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.text = ""

	var card_name := str(card_row.get("name", card_row.get("id", "未命名卡牌")))
	var card_tier := int(card_row.get("tier", 0))
	var icon_texture := _resolve_card_icon(card_row)
	if icon_texture != null:
		button.icon = icon_texture
	else:
		button.text = _build_card_placeholder_text(card_name)

	button.tooltip_text = "%s\n阶级 %d\n%s" % [
		card_name,
		card_tier,
		str(card_row.get("description", "暂无描述")).strip_edges(),
	]
	var colors := _get_tier_colors(card_tier)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = colors.get("bg", Color(0.12, 0.14, 0.16, 0.96))
	normal_style.border_color = colors.get("border", Color(0.55, 0.55, 0.55, 1.0))
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(10)
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = (colors.get("bg", Color(0.12, 0.14, 0.16, 0.96)) as Color).lightened(0.08)
	hover_style.border_color = (colors.get("border", Color(0.55, 0.55, 0.55, 1.0)) as Color).lightened(0.12)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_font_size_override("font_size", 15)

	button.mouse_entered.connect(_show_card_detail.bind(card_row))
	button.pressed.connect(_show_card_detail.bind(card_row))
	return button


func _show_card_detail(card_row: Dictionary) -> void:
	if card_row.is_empty():
		detail_title_label.text = "卡牌背包"
		detail_tier_label.text = "等待选择"
		detail_description_label.text = "把鼠标放到左侧卡牌上，这里会显示名称、阶级和描述。"
		detail_icon_rect.texture = null
		detail_icon_rect.visible = false
		detail_placeholder_label.visible = true
		detail_placeholder_label.text = "神权"
		return

	var card_name := str(card_row.get("name", card_row.get("id", "未命名卡牌")))
	var card_tier := int(card_row.get("tier", 0))
	var description := str(card_row.get("description", "暂无描述")).strip_edges()
	var icon_texture := _resolve_card_icon(card_row)
	var colors := _get_tier_colors(card_tier)

	detail_title_label.text = "神权背包"
	detail_tier_label.text = "阶级 %d" % card_tier
	detail_tier_label.modulate = colors.get("border", Color(0.87, 0.78, 0.51, 1.0))
	detail_description_label.text = description

	if icon_texture != null:
		detail_icon_rect.texture = icon_texture
		detail_icon_rect.visible = true
		detail_placeholder_label.visible = false
	else:
		detail_icon_rect.texture = null
		detail_icon_rect.visible = false
		detail_placeholder_label.visible = true
		detail_placeholder_label.text = _build_card_placeholder_text(card_name)


func _resolve_card_icon(card_row: Dictionary) -> Texture2D:
	var raw_icon_value = card_row.get("icon", "")
	if raw_icon_value == null:
		return null
	var raw_icon := str(raw_icon_value).strip_edges()
	if raw_icon.is_empty():
		return null

	var candidates := _build_card_icon_candidates(raw_icon)
	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			return load(candidate) as Texture2D
	return null


func _build_card_icon_candidates(icon_ref: String) -> Array[String]:
	var normalized_ref := icon_ref.strip_edges()
	if normalized_ref.is_empty():
		return []
	if normalized_ref.begins_with("res://") or normalized_ref.begins_with("uid://"):
		return [normalized_ref]

	var candidates: Array[String] = []
	candidates.append("%s/%s" % [CARD_ICON_FALLBACK_DIR, normalized_ref])
	for ext in CARD_ICON_EXTENSIONS:
		candidates.append("%s/%s.%s" % [CARD_ICON_FALLBACK_DIR, normalized_ref, ext])
	return candidates


func _build_card_placeholder_text(card_name: String) -> String:
	var compact_name := card_name.strip_edges()
	if compact_name.length() <= 4:
		return compact_name
	return compact_name.substr(0, 4)


func _get_tier_colors(tier: int) -> Dictionary:
	match tier:
		6:
			return {
				"bg": Color(0.28, 0.08, 0.09, 0.96),
				"border": Color(0.93, 0.24, 0.24, 1.0),
			}
		5:
			return {
				"bg": Color(0.28, 0.15, 0.05, 0.96),
				"border": Color(0.96, 0.60, 0.18, 1.0),
			}
		4:
			return {
				"bg": Color(0.19, 0.11, 0.25, 0.96),
				"border": Color(0.70, 0.45, 0.95, 1.0),
			}
		3:
			return {
				"bg": Color(0.07, 0.15, 0.24, 0.96),
				"border": Color(0.29, 0.63, 0.96, 1.0),
			}
		2:
			return {
				"bg": Color(0.09, 0.18, 0.11, 0.96),
				"border": Color(0.36, 0.81, 0.40, 1.0),
			}
		1:
			return {
				"bg": Color(0.18, 0.18, 0.18, 0.96),
				"border": Color(0.92, 0.92, 0.92, 1.0),
			}
		_:
			return {
				"bg": Color(0.14, 0.16, 0.13, 0.96),
				"border": Color(0.82, 0.77, 0.59, 1.0),
			}
