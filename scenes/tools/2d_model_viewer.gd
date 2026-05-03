extends Control

const GAME_SCENE := "res://game.tscn"
const ANIM_CONFIG_FILE := "anim_config.json"
const CATEGORIES := [
	{
		"label": "敌人",
		"root": "res://assets/enemies/Models_2d",
		"desc": "enemies.model_id"
	},
	{
		"label": "守护者",
		"root": "res://assets/heroes/Models_2d",
		"desc": "bloodlines.model_id"
	},
	{
		"label": "塔",
		"root": "res://assets/heroes/point_2d",
		"desc": "bloodlines.model_id_point"
	}
]
const STATES := [
	{"label": "待机", "state": "idle"},
	{"label": "移动", "state": "run"},
	{"label": "攻击", "state": "attack"},
	{"label": "死亡", "state": "death"},
	{"label": "受击", "state": "hit"},
	{"label": "出生", "state": "spawn"}
]
const DIRECTIONS := [
	{"label": "W 上", "vector": Vector2.UP},
	{"label": "W+D 右上", "vector": Vector2(1, -1)},
	{"label": "D 右", "vector": Vector2.RIGHT},
	{"label": "S+D 右下", "vector": Vector2(1, 1)},
	{"label": "S 下", "vector": Vector2.DOWN},
	{"label": "S+A 左下", "vector": Vector2(-1, 1)},
	{"label": "A 左", "vector": Vector2.LEFT},
	{"label": "W+A 左上", "vector": Vector2(-1, -1)}
]
const SOCKETS := [
	{"key": "projectile_socket", "label": "投射物发射点", "button": "投射物"},
	{"key": "pickup_socket", "label": "拾取吸附点", "button": "拾取"}
]
const SOCKET_PICK_RADIUS := 28.0

var category_option: OptionButton
var model_option: OptionButton
var png_option: OptionButton
var state_option: OptionButton
var direction_option: OptionButton
var active_socket_option: OptionButton
var preview: TextureRect
var marker_overlay: Control
var title_label: Label
var path_label: Label
var frame_label: Label
var status_label: Label
var action_match_label: RichTextLabel
var play_button: Button
var fps_spin: SpinBox
var loop_check: CheckBox
var hit_frame_spin: SpinBox
var skip_frames_edit: LineEdit
var frame_width_spin: SpinBox
var frame_height_spin: SpinBox
var display_scale_spin: SpinBox
var visual_offset_x_spin: SpinBox
var visual_offset_y_spin: SpinBox
var visual_ground_offset_spin: SpinBox
var socket_controls: Dictionary = {}
var socket_button_controls: Dictionary = {}

var current_texture: Texture2D
var current_atlas := AtlasTexture.new()
var current_regions: Array[Rect2] = []
var current_sequence_files: Array[String] = []
var current_file_index := 0
var current_frame := 0
var frame_elapsed := 0.0
var fps := 8.0
var playing := true
var model_dirs: Array[Dictionary] = []
var png_files: Array[String] = []
var current_model_path := ""
var current_anim_config: Dictionary = {}
var applying_config := false
var dragging_socket_key := ""


func _ready() -> void:
	_build_ui()
	_load_categories()
	set_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file(GAME_SCENE)
		elif event.physical_keycode == KEY_F6:
			_reload_current_category()
		elif event.physical_keycode == KEY_W:
			_select_direction(0)
		elif event.physical_keycode == KEY_D:
			_select_direction(2)
		elif event.physical_keycode == KEY_S:
			_select_direction(4)
		elif event.physical_keycode == KEY_A:
			_select_direction(6)


func _process(delta: float) -> void:
	if not playing or current_regions.size() <= 1:
		return

	frame_elapsed += delta
	var frame_duration := 1.0 / maxf(fps, 1.0)
	while frame_elapsed >= frame_duration:
		frame_elapsed -= frame_duration
		_advance_preview_frame()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 20
	root.offset_right = -24
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)

	title_label = Label.new()
	title_label.text = "F6 2D 序列帧配置工具"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 24)
	header.add_child(title_label)

	var save_button := Button.new()
	save_button.text = "保存配置"
	save_button.pressed.connect(_save_current_config)
	header.add_child(save_button)

	var back_button := Button.new()
	back_button.text = "返回战斗"
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(GAME_SCENE))
	header.add_child(back_button)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)

	category_option = OptionButton.new()
	category_option.custom_minimum_size = Vector2(150, 34)
	category_option.item_selected.connect(_on_category_selected)
	controls.add_child(category_option)

	model_option = OptionButton.new()
	model_option.custom_minimum_size = Vector2(260, 34)
	model_option.item_selected.connect(_on_model_selected)
	controls.add_child(model_option)

	png_option = OptionButton.new()
	png_option.custom_minimum_size = Vector2(300, 34)
	png_option.item_selected.connect(_on_png_selected)
	controls.add_child(png_option)

	var action_controls := HBoxContainer.new()
	action_controls.add_theme_constant_override("separation", 8)
	root.add_child(action_controls)

	state_option = OptionButton.new()
	state_option.custom_minimum_size = Vector2(150, 34)
	state_option.item_selected.connect(func(_index: int) -> void: _refresh_action_preview())
	action_controls.add_child(state_option)

	direction_option = OptionButton.new()
	direction_option.custom_minimum_size = Vector2(150, 34)
	direction_option.item_selected.connect(func(_index: int) -> void: _refresh_action_preview())
	action_controls.add_child(direction_option)

	active_socket_option = OptionButton.new()
	active_socket_option.custom_minimum_size = Vector2(180, 34)
	for socket in SOCKETS:
		active_socket_option.add_item("%s" % socket["label"])
	active_socket_option.select(0)
	active_socket_option.visible = false
	action_controls.add_child(active_socket_option)

	var socket_button_row := HBoxContainer.new()
	socket_button_row.add_theme_constant_override("separation", 4)
	action_controls.add_child(socket_button_row)
	_add_socket_buttons(socket_button_row)

	play_button = Button.new()
	play_button.text = "暂停"
	play_button.pressed.connect(_toggle_playing)
	action_controls.add_child(play_button)

	var prev_frame_button := Button.new()
	prev_frame_button.text = "上一帧"
	prev_frame_button.pressed.connect(_step_previous_frame)
	action_controls.add_child(prev_frame_button)

	var next_frame_button := Button.new()
	next_frame_button.text = "下一帧"
	next_frame_button.pressed.connect(_step_next_frame)
	action_controls.add_child(next_frame_button)

	var skip_current_button := Button.new()
	skip_current_button.text = "跳过当前帧"
	skip_current_button.pressed.connect(_add_current_frame_to_skip_list)
	action_controls.add_child(skip_current_button)

	var reload_button := Button.new()
	reload_button.text = "刷新"
	reload_button.pressed.connect(_reload_current_category)
	action_controls.add_child(reload_button)

	path_label = Label.new()
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(path_label)

	action_match_label = RichTextLabel.new()
	action_match_label.custom_minimum_size = Vector2(0, 104)
	action_match_label.fit_content = true
	action_match_label.scroll_active = false
	action_match_label.bbcode_enabled = true
	root.add_child(action_match_label)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(preview_panel)

	var preview_stack := Control.new()
	preview_stack.custom_minimum_size = Vector2(520, 360)
	preview_panel.add_child(preview_stack)

	preview = TextureRect.new()
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(preview)

	marker_overlay = Control.new()
	marker_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	marker_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	marker_overlay.draw.connect(_draw_marker_overlay)
	marker_overlay.gui_input.connect(_on_marker_overlay_input)
	preview_stack.add_child(marker_overlay)

	var editor_panel := PanelContainer.new()
	editor_panel.custom_minimum_size = Vector2(360, 360)
	body.add_child(editor_panel)

	var editor_scroll := ScrollContainer.new()
	editor_panel.add_child(editor_scroll)

	var editor := VBoxContainer.new()
	editor.add_theme_constant_override("separation", 8)
	editor_scroll.add_child(editor)

	_add_editor_title(editor, "序列帧")
	var frame_grid := GridContainer.new()
	frame_grid.columns = 2
	frame_grid.add_theme_constant_override("h_separation", 8)
	frame_grid.add_theme_constant_override("v_separation", 6)
	editor.add_child(frame_grid)

	fps_spin = _add_spin_row(frame_grid, "FPS", 1.0, 60.0, 1.0, 8.0)
	hit_frame_spin = _add_spin_row(frame_grid, "命中帧(1起)", 0.0, 300.0, 1.0, 0.0)
	frame_width_spin = _add_spin_row(frame_grid, "帧宽(0自动)", 0.0, 2048.0, 1.0, 0.0)
	frame_height_spin = _add_spin_row(frame_grid, "帧高(0自动)", 0.0, 2048.0, 1.0, 0.0)
	frame_width_spin.value_changed.connect(func(_value: float) -> void: _on_frame_layout_changed())
	frame_height_spin.value_changed.connect(func(_value: float) -> void: _on_frame_layout_changed())

	loop_check = CheckBox.new()
	loop_check.text = "循环播放"
	loop_check.toggled.connect(func(_pressed: bool) -> void: _on_editor_value_changed())
	editor.add_child(loop_check)

	var skip_label := Label.new()
	skip_label.text = "跳过帧(逗号分隔，1起)"
	editor.add_child(skip_label)
	skip_frames_edit = LineEdit.new()
	skip_frames_edit.placeholder_text = "例如：5, 9"
	skip_frames_edit.text_changed.connect(func(_text: String) -> void: _on_editor_value_changed())
	skip_frames_edit.text_changed.connect(func(_text: String) -> void: _on_frame_layout_changed())
	editor.add_child(skip_frames_edit)

	_add_editor_title(editor, "显示")
	var visual_grid := GridContainer.new()
	visual_grid.columns = 2
	visual_grid.add_theme_constant_override("h_separation", 8)
	visual_grid.add_theme_constant_override("v_separation", 6)
	editor.add_child(visual_grid)

	display_scale_spin = _add_spin_row(visual_grid, "显示缩放", 0.1, 5.0, 0.05, 1.0)
	visual_ground_offset_spin = _add_spin_row(visual_grid, "落地偏移Y", -300.0, 300.0, 1.0, 10.0)
	visual_offset_x_spin = _add_spin_row(visual_grid, "整体偏移X", -500.0, 500.0, 1.0, 0.0)
	visual_offset_y_spin = _add_spin_row(visual_grid, "整体偏移Y", -500.0, 500.0, 1.0, 0.0)

	_add_editor_title(editor, "点位")
	for socket in SOCKETS:
		_add_socket_editor(editor, String(socket["key"]), String(socket["label"]))

	var help := RichTextLabel.new()
	help.fit_content = true
	help.scroll_active = false
	help.bbcode_enabled = true
	help.text = "[color=#b8d7ff]预览区左键点击/拖动：设置当前选中的点位。保存后会写入当前模型目录的 anim_config.json。[/color]"
	editor.add_child(help)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	root.add_child(footer)

	frame_label = Label.new()
	frame_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(frame_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(status_label)


func _add_editor_title(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)


func _add_spin_row(parent: GridContainer, label_text: String, min_value: float, max_value: float, step: float, default_value: float) -> SpinBox:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)

	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value = default_value
	spin.allow_greater = true
	spin.allow_lesser = true
	spin.value_changed.connect(func(_value: float) -> void: _on_editor_value_changed())
	parent.add_child(spin)
	return spin


func _add_socket_buttons(parent: BoxContainer) -> void:
	for socket in SOCKETS:
		var key := String(socket["key"])
		var button := Button.new()
		button.text = String(socket["button"])
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(70, 34)
		button.pressed.connect(func() -> void: _select_socket_option_by_key(key))
		parent.add_child(button)
		socket_button_controls[key] = button
	_update_socket_button_states()


func _add_socket_editor(parent: VBoxContainer, key: String, label_text: String) -> void:
	var title_bar := HBoxContainer.new()
	parent.add_child(title_bar)

	var title := Label.new()
	title.text = label_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(title)

	var select_button := Button.new()
	select_button.text = "选中"
	select_button.pressed.connect(func() -> void: _select_socket_option_by_key(key))
	title_bar.add_child(select_button)

	var row := GridContainer.new()
	row.columns = 4
	row.add_theme_constant_override("h_separation", 8)
	parent.add_child(row)

	var x_label := Label.new()
	x_label.text = "X"
	row.add_child(x_label)

	var x_spin := SpinBox.new()
	x_spin.min_value = -1000.0
	x_spin.max_value = 1000.0
	x_spin.step = 1.0
	x_spin.allow_greater = true
	x_spin.allow_lesser = true
	x_spin.value_changed.connect(func(_value: float) -> void: _on_editor_value_changed())
	row.add_child(x_spin)

	var y_label := Label.new()
	y_label.text = "Y"
	row.add_child(y_label)

	var y_spin := SpinBox.new()
	y_spin.min_value = -1000.0
	y_spin.max_value = 1000.0
	y_spin.step = 1.0
	y_spin.allow_greater = true
	y_spin.allow_lesser = true
	y_spin.value_changed.connect(func(_value: float) -> void: _on_editor_value_changed())
	row.add_child(y_spin)

	socket_controls[key] = {"x": x_spin, "y": y_spin}


func _load_categories() -> void:
	state_option.clear()
	for state in STATES:
		state_option.add_item("%s: %s" % [state["label"], state["state"]])
	state_option.select(0)

	direction_option.clear()
	for direction in DIRECTIONS:
		direction_option.add_item(String(direction["label"]))
	direction_option.select(4)

	category_option.clear()
	for category in CATEGORIES:
		category_option.add_item("%s: %s" % [category["label"], category["desc"]])
	category_option.select(0)
	_on_category_selected(0)


func _on_category_selected(index: int) -> void:
	index = clampi(index, 0, CATEGORIES.size() - 1)
	_reload_model_dirs(String(CATEGORIES[index]["root"]))
	_refresh_model_option()


func _reload_current_category() -> void:
	_on_category_selected(category_option.selected)


func _reload_model_dirs(root_path: String) -> void:
	model_dirs.clear()
	var dir := DirAccess.open(root_path)
	if dir == null:
		_show_status("目录不存在：%s" % root_path, true)
		return

	for child_name in dir.get_directories():
		var child_path := "%s/%s" % [root_path, child_name]
		model_dirs.append({
			"name": child_name,
			"path": child_path,
			"id": child_name.split("_", false, 1)[0]
		})

	model_dirs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["name"]).naturalnocasecmp_to(String(b["name"])) < 0
	)


func _refresh_model_option() -> void:
	model_option.clear()
	png_option.clear()
	if model_dirs.is_empty():
		_clear_preview()
		_show_status("当前分类没有 ID_备注 文件夹", true)
		return

	for item in model_dirs:
		model_option.add_item("%s  [%s]" % [item["name"], item["id"]])
	model_option.select(0)
	_on_model_selected(0)


func _on_model_selected(index: int) -> void:
	if index < 0 or index >= model_dirs.size():
		return

	current_model_path = String(model_dirs[index]["path"])
	current_anim_config = _load_anim_config(current_model_path)
	png_files = _collect_png_files(current_model_path)
	_refresh_png_option(current_model_path)
	_apply_config_to_editor()


func _refresh_png_option(model_path: String) -> void:
	png_option.clear()
	if png_files.is_empty():
		_clear_preview()
		path_label.text = model_path
		_show_status("该 ID 文件夹内没有 PNG", true)
		return

	for file_path in png_files:
		png_option.add_item(file_path.get_file())
	png_option.select(0)
	_on_png_selected(0)
	_refresh_action_preview()


func _on_png_selected(index: int) -> void:
	if index < 0 or index >= png_files.size():
		return

	var file_path := png_files[index]
	var texture := load(file_path) as Texture2D
	if texture == null:
		_clear_preview()
		_show_status("PNG 未导入或无法加载：%s" % file_path, true)
		return

	current_texture = texture
	current_sequence_files = [file_path]
	current_file_index = 0
	current_regions = _build_regions(texture)
	current_frame = 0
	frame_elapsed = 0.0
	path_label.text = file_path
	_apply_current_frame()
	_update_action_match_label(_select_files_for_state(_get_selected_state(), _get_selected_direction()))
	_show_status("已加载", false)


func _collect_png_files(root_path: String) -> Array[String]:
	var results: Array[String] = []
	_collect_png_files_recursive(root_path, results)
	results.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	return results


func _collect_png_files_recursive(root_path: String, results: Array[String]) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		return

	for file_name in dir.get_files():
		if file_name.get_extension().to_lower() == "png":
			results.append("%s/%s" % [root_path, file_name])

	for child_name in dir.get_directories():
		_collect_png_files_recursive("%s/%s" % [root_path, child_name], results)


func _build_regions(texture: Texture2D) -> Array[Rect2]:
	var regions: Array[Rect2] = []
	var size := texture.get_size()
	var configured_width := int(frame_width_spin.value) if frame_width_spin != null else 0
	var configured_height := int(frame_height_spin.value) if frame_height_spin != null else 0
	if configured_width > 0 and configured_height > 0:
		var columns := maxi(int(floor(size.x / float(configured_width))), 1)
		var rows := maxi(int(floor(size.y / float(configured_height))), 1)
		for y in rows:
			for x in columns:
				regions.append(Rect2(Vector2(configured_width * x, configured_height * y), Vector2(configured_width, configured_height)))
	elif size.y > 0.0 and size.x > size.y and int(size.x) % int(size.y) == 0:
		var frame_size := size.y
		var frame_count := int(size.x / frame_size)
		for i in frame_count:
			regions.append(Rect2(Vector2(frame_size * float(i), 0.0), Vector2(frame_size, frame_size)))
	else:
		regions.append(Rect2(Vector2.ZERO, size))
	return _apply_skip_frames_to_regions(regions)


func _apply_skip_frames_to_regions(regions: Array[Rect2]) -> Array[Rect2]:
	var skip_frames := _parse_int_list(skip_frames_edit.text if skip_frames_edit != null else "")
	if skip_frames.is_empty():
		return regions

	var filtered: Array[Rect2] = []
	for index in regions.size():
		if not skip_frames.has(index + 1):
			filtered.append(regions[index])
	return filtered if not filtered.is_empty() else regions


func _apply_current_frame() -> void:
	if current_texture == null or current_regions.is_empty():
		return

	current_frame = clampi(current_frame, 0, current_regions.size() - 1)
	current_atlas.atlas = current_texture
	current_atlas.region = current_regions[current_frame]
	preview.texture = current_atlas
	var texture_size := current_texture.get_size()
	var frame_size := current_regions[current_frame].size
	frame_label.text = "文件 %d / %d    帧 %d / %d    PNG %dx%d    单帧 %dx%d    FPS %.0f" % [
		current_file_index + 1,
		maxi(current_sequence_files.size(), 1),
		current_frame + 1,
		current_regions.size(),
		int(texture_size.x),
		int(texture_size.y),
		int(frame_size.x),
		int(frame_size.y),
		fps
	]
	marker_overlay.queue_redraw()


func _advance_preview_frame() -> void:
	if current_regions.is_empty():
		return

	current_frame += 1
	if current_frame < current_regions.size():
		_apply_current_frame()
		return

	if current_sequence_files.size() > 1:
		current_file_index = (current_file_index + 1) % current_sequence_files.size()
		_load_sequence_file(current_file_index)
		return

	current_frame = 0
	_apply_current_frame()


func _step_previous_frame() -> void:
	playing = false
	play_button.text = "播放"
	if current_regions.is_empty():
		return
	current_frame = wrapi(current_frame - 1, 0, current_regions.size())
	_apply_current_frame()


func _step_next_frame() -> void:
	playing = false
	play_button.text = "播放"
	if current_regions.is_empty():
		return
	current_frame = wrapi(current_frame + 1, 0, current_regions.size())
	_apply_current_frame()


func _add_current_frame_to_skip_list() -> void:
	var skip_frames := _parse_int_list(skip_frames_edit.text)
	var frame_number := current_frame + 1
	if not skip_frames.has(frame_number):
		skip_frames.append(frame_number)
		skip_frames.sort()
	skip_frames_edit.text = _format_int_list(skip_frames)
	_reload_current_sequence_file()
	_show_status("已加入跳过帧，保存后生效到运行时", false)


func _refresh_action_preview() -> void:
	if current_model_path.is_empty() or png_files.is_empty():
		return

	_apply_config_to_editor()
	var state := _get_selected_state()
	var direction := _get_selected_direction()
	var matched_files := _select_files_for_state(state, direction)
	_update_action_match_label(matched_files)
	if matched_files.is_empty():
		_show_status("该方向/动作没有匹配 PNG", true)
		return

	current_sequence_files = matched_files
	current_file_index = 0
	current_frame = 0
	frame_elapsed = 0.0
	fps = float(fps_spin.value)
	_load_sequence_file(0)
	_select_png_option_for_path(matched_files[0])
	_show_status("按动作匹配预览", false)


func _reload_current_sequence_file() -> void:
	if current_sequence_files.is_empty():
		return
	_load_sequence_file(current_file_index)


func _load_sequence_file(index: int) -> void:
	if index < 0 or index >= current_sequence_files.size():
		return

	var file_path := current_sequence_files[index]
	var texture := load(file_path) as Texture2D
	if texture == null:
		_show_status("PNG 未导入或无法加载：%s" % file_path, true)
		return

	current_file_index = index
	current_texture = texture
	current_regions = _build_regions(texture)
	current_frame = 0
	path_label.text = file_path
	_apply_current_frame()


func _select_png_option_for_path(file_path: String) -> void:
	for i in png_files.size():
		if png_files[i] == file_path:
			png_option.select(i)
			return


func _select_direction(index: int) -> void:
	index = clampi(index, 0, DIRECTIONS.size() - 1)
	direction_option.select(index)
	_refresh_action_preview()


func _select_files_for_state(state: String, direction: Vector2) -> Array[String]:
	var configured_files := _select_configured_files_for_state(state, direction)
	if not configured_files.is_empty():
		return configured_files

	var keyword_matches: Array[String] = []
	var keywords := _get_state_keywords(state)
	for file_path in png_files:
		var file_lower := file_path.get_file().to_lower()
		for keyword in keywords:
			if file_lower.contains(keyword):
				keyword_matches.append(file_path)
				break

	if keyword_matches.is_empty() and state == "idle":
		keyword_matches = png_files.duplicate()
	if keyword_matches.is_empty():
		return []

	var direction_matches := _filter_direction_files(keyword_matches, direction)
	if not direction_matches.is_empty():
		return direction_matches
	return keyword_matches


func _select_configured_files_for_state(state: String, direction: Vector2) -> Array[String]:
	var state_config := _get_animation_config(state, direction)
	if state_config.is_empty():
		return []

	var raw_files = state_config.get("files", state_config.get("file", []))
	var configured_files: Array[String] = []
	if raw_files is Array:
		for raw_file in raw_files:
			_append_configured_file(configured_files, str(raw_file))
	else:
		_append_configured_file(configured_files, str(raw_files))
	return configured_files


func _append_configured_file(target: Array[String], raw_file: String) -> void:
	var file_name := raw_file.strip_edges()
	if file_name.is_empty():
		return

	var path := file_name
	if not path.begins_with("res://"):
		path = "%s/%s" % [current_model_path, file_name]
	if ResourceLoader.exists(path):
		target.append(path)


func _filter_direction_files(files: Array[String], direction: Vector2) -> Array[String]:
	var token := _get_direction_token(direction)
	var matches: Array[String] = []
	for file_path in files:
		var lower_name := file_path.get_file().to_lower()
		if lower_name.contains(token):
			matches.append(file_path)

	return matches


func _get_direction_token(direction: Vector2) -> String:
	var angle := direction.angle()
	if angle < 0.0:
		angle += TAU
	var sector := int(round(angle / (PI / 4.0))) % 8
	match sector:
		0:
			return "right"
		1:
			return "downright"
		2:
			return "down"
		3:
			return "downright"
		4:
			return "right"
		5:
			return "upright"
		6:
			return "up"
		_:
			return "upright"


func _get_state_keywords(state: String) -> PackedStringArray:
	match state:
		"run":
			return PackedStringArray(["run", "walk", "move"])
		"attack":
			return PackedStringArray(["attack", "shoot", "melee", "cast"])
		"death":
			return PackedStringArray(["death", "die"])
		"hit":
			return PackedStringArray(["hit", "damage"])
		"spawn":
			return PackedStringArray(["spawn"])
		_:
			return PackedStringArray(["idle", "stand", "tower"])


func _update_action_match_label(matched_files: Array[String]) -> void:
	if action_match_label == null:
		return

	if current_model_path.is_empty():
		action_match_label.text = ""
		return

	var state := _get_selected_state()
	var direction := _get_selected_direction()
	var direction_label := String(DIRECTIONS[clampi(direction_option.selected, 0, DIRECTIONS.size() - 1)]["label"])
	var direction_token := _get_direction_token(direction)
	var lines: Array[String] = []
	lines.append("[b]WSAD 动作匹配[/b]  方向：%s  token：%s  状态：%s" % [direction_label, direction_token, state])
	if matched_files.is_empty():
		lines.append("[color=#ff7566]当前状态/方向没有匹配 PNG；运行时会按状态回退，仍为空则不播放。[/color]")
	else:
		for file_path in matched_files:
			lines.append("- %s" % file_path.get_file())
		if direction.x < -0.01:
			lines.append("[color=#b8d7ff]说明：左侧方向运行时复用对应右侧方向文件，并由 Sprite2D 水平翻转。[/color]")
	lines.append("")
	lines.append("[b]该方向全部状态概览[/b]")
	for state_row in STATES:
		var overview_state := String(state_row["state"])
		var overview_files := _select_files_for_state(overview_state, direction)
		var names: Array[String] = []
		for file_path in overview_files:
			names.append(file_path.get_file())
		var label := String(state_row["label"])
		var prefix := "=> " if overview_state == state else "   "
		lines.append("%s%s/%s：%s" % [prefix, label, overview_state, "、".join(names) if not names.is_empty() else "无匹配"])
	action_match_label.text = "\n".join(lines)


func _load_anim_config(model_path: String) -> Dictionary:
	var config_path := "%s/%s" % [model_path, ANIM_CONFIG_FILE]
	if not FileAccess.file_exists(config_path):
		return {}

	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		_show_status("无法读取配置：%s" % config_path, true)
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		_show_status("配置 JSON 格式错误：%s" % json.get_error_message(), true)
		return {}

	if json.data is Dictionary:
		return json.data as Dictionary
	_show_status("配置根节点必须是 Dictionary：%s" % config_path, true)
	return {}


func _apply_config_to_editor() -> void:
	if fps_spin == null:
		return

	applying_config = true
	var state := _get_selected_state()
	var direction := _get_selected_direction()
	var state_config := _get_animation_config(state, direction)
	fps_spin.value = _get_float_from_config(state_config, "fps", _get_default_fps(state))
	loop_check.button_pressed = _get_bool_from_config(state_config, "loop", state != "attack" and state != "death")
	hit_frame_spin.value = _get_int_from_config(state_config, "hit_frame", 0)
	frame_width_spin.value = _get_int_from_config(state_config, "frame_width", 0)
	frame_height_spin.value = _get_int_from_config(state_config, "frame_height", 0)
	skip_frames_edit.text = _format_int_list(_get_int_array_from_config(state_config, "skip_frames"))

	display_scale_spin.value = _get_float_from_config(current_anim_config, "display_scale", 1.0)
	visual_ground_offset_spin.value = _get_float_from_config(current_anim_config, "visual_ground_offset", 10.0)
	var visual_offset := _get_vector2_array(current_anim_config.get("visual_offset", [0, 0]), Vector2.ZERO)
	visual_offset_x_spin.value = visual_offset.x
	visual_offset_y_spin.value = visual_offset.y

	for socket in SOCKETS:
		var key := String(socket["key"])
		var value := _get_socket_value(key, state_config)
		_set_socket_control_value(key, value)

	fps = float(fps_spin.value)
	applying_config = false
	if marker_overlay != null:
		marker_overlay.queue_redraw()


func _get_animation_config(state: String, direction: Vector2) -> Dictionary:
	if current_anim_config.is_empty():
		return {}

	var result: Dictionary = {}
	var animations = current_anim_config.get("animations", {})
	if animations is Dictionary and (animations as Dictionary).has(state):
		var state_value = (animations as Dictionary).get(state)
		if state_value is Dictionary:
			result.merge(state_value as Dictionary, true)

	var direction_configs = current_anim_config.get("directions", {})
	if direction_configs is Dictionary:
		var token := _get_direction_token(direction)
		var direction_value = (direction_configs as Dictionary).get(token, {})
		if direction_value is Dictionary and (direction_value as Dictionary).has(state):
			var direction_state_value = (direction_value as Dictionary).get(state)
			if direction_state_value is Dictionary:
				result.merge(direction_state_value as Dictionary, true)
	return result


func _save_current_config() -> void:
	if current_model_path.is_empty():
		_show_status("没有可保存的模型目录", true)
		return

	var state := _get_selected_state()
	var direction_token := _get_direction_token(_get_selected_direction())
	current_anim_config["display_scale"] = snappedf(float(display_scale_spin.value), 0.001)
	current_anim_config["visual_offset"] = [snappedf(float(visual_offset_x_spin.value), 0.001), snappedf(float(visual_offset_y_spin.value), 0.001)]
	current_anim_config["visual_ground_offset"] = snappedf(float(visual_ground_offset_spin.value), 0.001)

	var sockets := _get_or_make_dictionary(current_anim_config, "sockets")
	for socket in SOCKETS:
		var key := String(socket["key"])
		sockets[key] = _get_socket_array(key)

	var directions := _get_or_make_dictionary(current_anim_config, "directions")
	var direction_config := _get_or_make_dictionary(directions, direction_token)
	var state_config := _get_or_make_dictionary(direction_config, state)

	var files: Array[String] = []
	for file_path in current_sequence_files:
		files.append(_make_model_relative_path(file_path))
	state_config["files"] = files
	state_config["fps"] = snappedf(float(fps_spin.value), 0.001)
	state_config["loop"] = loop_check.button_pressed
	state_config["frame_width"] = int(frame_width_spin.value)
	state_config["frame_height"] = int(frame_height_spin.value)
	state_config["hit_frame"] = int(hit_frame_spin.value)
	state_config["skip_frames"] = _parse_int_list(skip_frames_edit.text)
	state_config["projectile_socket"] = _get_socket_array("projectile_socket")

	var config_path := "%s/%s" % [current_model_path, ANIM_CONFIG_FILE]
	var file := FileAccess.open(config_path, FileAccess.WRITE)
	if file == null:
		_show_status("无法写入配置：%s" % config_path, true)
		return

	file.store_string(JSON.stringify(current_anim_config, "\t"))
	file.close()
	current_anim_config = _load_anim_config(current_model_path)
	_apply_config_to_editor()
	_refresh_action_preview()
	_show_status("已保存：%s" % config_path, false)


func _get_or_make_dictionary(parent: Dictionary, key: String) -> Dictionary:
	if not parent.has(key) or not (parent[key] is Dictionary):
		parent[key] = {}
	return parent[key] as Dictionary


func _make_model_relative_path(file_path: String) -> String:
	var prefix := "%s/" % current_model_path
	if file_path.begins_with(prefix):
		return file_path.substr(prefix.length())
	return file_path


func _get_socket_value(key: String, state_config: Dictionary) -> Vector2:
	if state_config.has(key):
		return _get_vector2_array(state_config.get(key), Vector2.ZERO)
	var sockets = current_anim_config.get("sockets", {})
	if sockets is Dictionary and (sockets as Dictionary).has(key):
		return _get_vector2_array((sockets as Dictionary).get(key), Vector2.ZERO)
	return Vector2.ZERO


func _set_socket_control_value(key: String, value: Vector2) -> void:
	if not socket_controls.has(key):
		return
	var controls := socket_controls[key] as Dictionary
	(controls["x"] as SpinBox).value = value.x
	(controls["y"] as SpinBox).value = value.y


func _get_socket_array(key: String) -> Array:
	if not socket_controls.has(key):
		return [0, 0]
	var controls := socket_controls[key] as Dictionary
	return [int((controls["x"] as SpinBox).value), int((controls["y"] as SpinBox).value)]


func _get_socket_vector(key: String) -> Vector2:
	if not socket_controls.has(key):
		return Vector2.ZERO
	var controls := socket_controls[key] as Dictionary
	return Vector2(float((controls["x"] as SpinBox).value), float((controls["y"] as SpinBox).value))


func _draw_marker_overlay() -> void:
	if current_regions.is_empty() or marker_overlay == null:
		return

	var rect := _get_preview_draw_rect()
	if rect.size == Vector2.ZERO:
		return

	var frame_size := current_regions[current_frame].size
	var origin_pixel := Vector2(frame_size.x * 0.5, frame_size.y)
	var colors := {
		"projectile_socket": Color(1.0, 0.35, 0.22),
		"pickup_socket": Color(0.3, 1.0, 0.45)
	}
	for socket in SOCKETS:
		var key := String(socket["key"])
		var socket_offset := _get_socket_vector(key)
		var pixel := origin_pixel + socket_offset
		var position := rect.position + Vector2(pixel.x / frame_size.x * rect.size.x, pixel.y / frame_size.y * rect.size.y)
		var color := colors.get(key, Color.WHITE) as Color
		var selected := key == _get_selected_socket_key()
		var marker_radius := 7.0 if selected else 5.0
		var line_length := 14.0 if selected else 10.0
		var line_width := 3.0 if selected else 2.0
		marker_overlay.draw_circle(position, marker_radius, color)
		marker_overlay.draw_line(position + Vector2(-line_length, 0), position + Vector2(line_length, 0), color, line_width)
		marker_overlay.draw_line(position + Vector2(0, -line_length), position + Vector2(0, line_length), color, line_width)
		marker_overlay.draw_string(ThemeDB.fallback_font, position + Vector2(8, -8), String(socket["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, color)


func _on_marker_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_socket_key = _pick_socket_key_at_position(event.position)
			if dragging_socket_key.is_empty():
				dragging_socket_key = _get_selected_socket_key()
			_select_socket_option_by_key(dragging_socket_key)
			_set_socket_from_preview(dragging_socket_key, event.position)
		else:
			dragging_socket_key = ""
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var socket_key := dragging_socket_key if not dragging_socket_key.is_empty() else _get_selected_socket_key()
		_set_socket_from_preview(socket_key, event.position)


func _set_socket_from_preview(socket_key: String, local_position: Vector2) -> void:
	if socket_key.is_empty():
		return
	if current_regions.is_empty():
		return
	var rect := _get_preview_draw_rect()
	if rect.size == Vector2.ZERO or not rect.has_point(local_position):
		return

	var frame_size := current_regions[current_frame].size
	var normalized := (local_position - rect.position) / rect.size
	var pixel := Vector2(normalized.x * frame_size.x, normalized.y * frame_size.y)
	var socket := pixel - Vector2(frame_size.x * 0.5, frame_size.y)
	_set_socket_control_value(socket_key, Vector2(roundf(socket.x), roundf(socket.y)))
	marker_overlay.queue_redraw()


func _pick_socket_key_at_position(local_position: Vector2) -> String:
	if current_regions.is_empty():
		return ""
	var nearest_key := ""
	var nearest_distance := SOCKET_PICK_RADIUS
	for socket in SOCKETS:
		var key := String(socket["key"])
		var marker_position := _get_socket_marker_position(key)
		if marker_position == Vector2.INF:
			continue
		var distance := local_position.distance_to(marker_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_key = key
	return nearest_key


func _get_socket_marker_position(key: String) -> Vector2:
	var rect := _get_preview_draw_rect()
	if rect.size == Vector2.ZERO or current_regions.is_empty():
		return Vector2.INF
	var frame_size := current_regions[current_frame].size
	var origin_pixel := Vector2(frame_size.x * 0.5, frame_size.y)
	var socket_offset := _get_socket_vector(key)
	var pixel := origin_pixel + socket_offset
	return rect.position + Vector2(pixel.x / frame_size.x * rect.size.x, pixel.y / frame_size.y * rect.size.y)


func _get_selected_socket_key() -> String:
	return String(SOCKETS[clampi(active_socket_option.selected, 0, SOCKETS.size() - 1)]["key"])


func _select_socket_option_by_key(socket_key: String) -> void:
	for index in SOCKETS.size():
		if String(SOCKETS[index]["key"]) == socket_key:
			active_socket_option.select(index)
			_update_socket_button_states()
			if marker_overlay != null:
				marker_overlay.queue_redraw()
			return


func _update_socket_button_states() -> void:
	var selected_key := _get_selected_socket_key()
	for socket in SOCKETS:
		var key := String(socket["key"])
		if not socket_button_controls.has(key):
			continue
		var button := socket_button_controls[key] as Button
		button.button_pressed = key == selected_key


func _get_preview_draw_rect() -> Rect2:
	if marker_overlay == null or current_regions.is_empty():
		return Rect2()
	var frame_size := current_regions[current_frame].size
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		return Rect2()
	var available := marker_overlay.size
	var scale := minf(available.x / frame_size.x, available.y / frame_size.y)
	var draw_size := frame_size * scale
	return Rect2((available - draw_size) * 0.5, draw_size)


func _on_editor_value_changed() -> void:
	if applying_config:
		return
	fps = float(fps_spin.value) if fps_spin != null else fps
	if marker_overlay != null:
		marker_overlay.queue_redraw()


func _on_frame_layout_changed() -> void:
	if applying_config:
		return
	_reload_current_sequence_file()


func _get_selected_state() -> String:
	return String(STATES[clampi(state_option.selected, 0, STATES.size() - 1)]["state"])


func _get_selected_direction() -> Vector2:
	return DIRECTIONS[clampi(direction_option.selected, 0, DIRECTIONS.size() - 1)]["vector"] as Vector2


func _toggle_playing() -> void:
	playing = not playing
	play_button.text = "暂停" if playing else "播放"


func _clear_preview() -> void:
	current_texture = null
	current_regions.clear()
	current_sequence_files.clear()
	current_file_index = 0
	preview.texture = null
	frame_label.text = ""
	if action_match_label != null:
		action_match_label.text = ""
	if marker_overlay != null:
		marker_overlay.queue_redraw()


func _show_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.42, 0.34, 1.0) if is_error else Color(0.72, 0.92, 0.72, 1.0)


func _get_default_fps(state: String) -> float:
	match state:
		"attack":
			return 12.0
		"death":
			return 8.0
		_:
			return 8.0


func _get_float_from_config(config: Dictionary, key: String, default_value: float) -> float:
	if not config.has(key):
		return default_value
	var value = config.get(key)
	if value is float or value is int:
		return float(value)
	var text := str(value).strip_edges()
	if text.is_valid_float():
		return text.to_float()
	return default_value


func _get_int_from_config(config: Dictionary, key: String, default_value: int) -> int:
	if not config.has(key):
		return default_value
	var value = config.get(key)
	if value is int:
		return value
	if value is float:
		return int(value)
	var text := str(value).strip_edges()
	if text.is_valid_int():
		return text.to_int()
	return default_value


func _get_bool_from_config(config: Dictionary, key: String, default_value: bool) -> bool:
	if not config.has(key):
		return default_value
	var value = config.get(key)
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	if text in ["1", "true", "yes", "y"]:
		return true
	if text in ["0", "false", "no", "n"]:
		return false
	return default_value


func _get_int_array_from_config(config: Dictionary, key: String) -> Array[int]:
	if not config.has(key):
		return []
	var value = config.get(key)
	var result: Array[int] = []
	if value is Array:
		for item in value:
			if item is int or item is float:
				result.append(int(item))
			elif str(item).strip_edges().is_valid_int():
				result.append(str(item).strip_edges().to_int())
	elif value is String:
		result = _parse_int_list(value)
	return result


func _parse_int_list(text: String) -> Array[int]:
	var result: Array[int] = []
	for part in text.split(",", false):
		var clean := part.strip_edges()
		if clean.is_valid_int():
			var value := clean.to_int()
			if value > 0 and not result.has(value):
				result.append(value)
	result.sort()
	return result


func _format_int_list(values: Array[int]) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)


func _get_vector2_array(value, default_value: Vector2) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float((value as Array)[0]), float((value as Array)[1]))
	return default_value
