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

var category_option: OptionButton
var model_option: OptionButton
var png_option: OptionButton
var preview: TextureRect
var title_label: Label
var path_label: Label
var frame_label: Label
var status_label: Label
var play_button: Button

var current_texture: Texture2D
var current_atlas := AtlasTexture.new()
var current_regions: Array[Rect2] = []
var current_frame := 0
var frame_elapsed := 0.0
var fps := 8.0
var playing := true
var model_dirs: Array[Dictionary] = []
var png_files: Array[String] = []


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


func _process(delta: float) -> void:
	if not playing or current_regions.size() <= 1:
		return

	frame_elapsed += delta
	var frame_duration := 1.0 / maxf(fps, 1.0)
	while frame_elapsed >= frame_duration:
		frame_elapsed -= frame_duration
		current_frame = (current_frame + 1) % current_regions.size()
		_apply_current_frame()


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

	play_button = Button.new()
	play_button.text = "暂停"
	play_button.pressed.connect(_toggle_playing)
	controls.add_child(play_button)

	var reload_button := Button.new()
	reload_button.text = "刷新"
	reload_button.pressed.connect(_reload_current_category)
	controls.add_child(reload_button)

	path_label = Label.new()
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(path_label)

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

	var model_path := String(model_dirs[index]["path"])
	png_files = _collect_png_files(model_path)
	_refresh_png_option(model_path)


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
	current_regions = _build_regions(texture)
	current_frame = 0
	frame_elapsed = 0.0
	path_label.text = file_path
	_apply_current_frame()
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
	frame_label.text = "帧 %d / %d    PNG %dx%d    单帧 %dx%d    FPS %.0f" % [
		current_frame + 1,
		current_regions.size(),
		int(texture_size.x),
		int(texture_size.y),
		int(frame_size.x),
		int(frame_size.y),
		fps
	]


func _toggle_playing() -> void:
	playing = not playing
	play_button.text = "暂停" if playing else "播放"


func _clear_preview() -> void:
	current_texture = null
	current_regions.clear()
	preview.texture = null
	frame_label.text = ""


func _show_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.42, 0.34, 1.0) if is_error else Color(0.72, 0.92, 0.72, 1.0)
