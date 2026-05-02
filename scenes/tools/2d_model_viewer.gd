extends Control

const GAME_SCENE := "res://game.tscn"
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

var category_option: OptionButton
var model_option: OptionButton
var png_option: OptionButton
var state_option: OptionButton
var direction_option: OptionButton
var preview: TextureRect
var title_label: Label
var path_label: Label
var frame_label: Label
var status_label: Label
var action_match_label: RichTextLabel
var play_button: Button

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
	title_label.text = "F6 2D 序列帧查看器"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 24)
	header.add_child(title_label)

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

	play_button = Button.new()
	play_button.text = "暂停"
	play_button.pressed.connect(_toggle_playing)
	action_controls.add_child(play_button)

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

	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(preview_panel)

	preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(preview)

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


func _load_categories() -> void:
	state_option.clear()
	for state in STATES:
		state_option.add_item("%s：%s" % [state["label"], state["state"]])
	state_option.select(0)

	direction_option.clear()
	for direction in DIRECTIONS:
		direction_option.add_item(String(direction["label"]))
	direction_option.select(4)

	category_option.clear()
	for category in CATEGORIES:
		category_option.add_item("%s：%s" % [category["label"], category["desc"]])
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
	png_files = _collect_png_files(current_model_path)
	_refresh_png_option(current_model_path)


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
	if size.y > 0.0 and size.x > size.y and int(size.x) % int(size.y) == 0:
		var frame_size := size.y
		var frame_count := int(size.x / frame_size)
		for i in frame_count:
			regions.append(Rect2(Vector2(frame_size * float(i), 0.0), Vector2(frame_size, frame_size)))
	else:
		regions.append(Rect2(Vector2.ZERO, size))
	return regions


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


func _refresh_action_preview() -> void:
	if current_model_path.is_empty() or png_files.is_empty():
		return

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
	_load_sequence_file(0)
	_select_png_option_for_path(matched_files[0])
	_show_status("按动作匹配预览", false)


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


func _show_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.42, 0.34, 1.0) if is_error else Color(0.72, 0.92, 0.72, 1.0)
