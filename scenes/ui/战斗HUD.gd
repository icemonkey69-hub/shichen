extends CanvasLayer
class_name BattleHudUi

@onready var minimap: Minimap = $小地图 as Minimap
@onready var portrait_panel: Control = $头像面板 as Control
@onready var portrait_rect: TextureRect = $头像面板/头像 as TextureRect
@onready var portrait_name_label: Label = $头像面板/英雄名 as Label
@onready var hp_bar: ProgressBar = $头像面板/生命条 as ProgressBar
@onready var hp_label: Label = $头像面板/生命条/生命文本 as Label
@onready var mana_bar: ProgressBar = $头像面板/法力条 as ProgressBar
@onready var mana_label: Label = $头像面板/法力条/法力文本 as Label
@onready var exp_bar: ProgressBar = $头像面板/经验条 as ProgressBar
@onready var exp_label: Label = $头像面板/经验条/经验文本 as Label
@onready var combat_panel: Control = $战斗信息面板 as Control
@onready var hero_name_label: Label = $战斗信息面板/英雄名 as Label
@onready var stats_label: Label = $战斗信息面板/战斗信息 as Label
@onready var help_label: Label = $战斗信息面板/帮助 as Label
@onready var message_label: Label = $中央提示 as Label
@onready var weapon_growth_panel: Control = $武器成长面板 as Control


func _ready() -> void:
	if portrait_panel != null:
		portrait_panel.clip_contents = true
	if portrait_rect != null:
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func add_runtime_ui(node: Node) -> void:
	if node != null:
		add_child(node)


func connect_weapon_growth_upgrade(callable: Callable) -> void:
	if weapon_growth_panel == null or not weapon_growth_panel.has_signal("upgrade_requested"):
		return
	if not weapon_growth_panel.is_connected("upgrade_requested", callable):
		weapon_growth_panel.connect("upgrade_requested", callable)


func configure_weapon_growth(slot_infos: Array[Dictionary], current_gold: int) -> void:
	if weapon_growth_panel == null:
		return
	weapon_growth_panel.call("configure", slot_infos, current_gold)


func hide_weapon_growth_panel() -> void:
	if weapon_growth_panel != null:
		weapon_growth_panel.visible = false


func configure_minimap(play_rect: Rect2, player_node: Node2D) -> void:
	if minimap == null:
		return
	minimap.play_area = play_rect
	minimap.player = player_node


func set_help_text(text: String) -> void:
	if help_label != null and help_label.text != text:
		help_label.text = text


func set_combat_hud_visible(visible_state: bool) -> void:
	if combat_panel != null:
		combat_panel.visible = visible_state
	if portrait_panel != null:
		portrait_panel.visible = visible_state


func set_minimap_visible(visible_state: bool) -> void:
	if minimap != null:
		minimap.visible = visible_state


func show_selection_mode() -> void:
	set_combat_hud_visible(false)
	hide_weapon_growth_panel()
	hide_message()
	set_minimap_visible(false)


func show_battle_mode() -> void:
	set_combat_hud_visible(true)
	show_message()
	set_minimap_visible(true)


func set_combat_info_text(text: String) -> void:
	if stats_label != null and stats_label.text != text:
		stats_label.text = text


func update_resource_bars(
	current_health: int,
	max_health: int,
	current_mana: int,
	max_mana: int,
	current_level: int,
	exp_progress: int,
	exp_needed: int,
	is_max_level: bool
) -> void:
	if hp_bar != null:
		hp_bar.max_value = maxf(float(max_health), 1.0)
		hp_bar.value = clampf(float(current_health), 0.0, hp_bar.max_value)
	if hp_label != null:
		hp_label.text = "HP %d / %d" % [current_health, max_health]

	var safe_max_mana: int = maxi(max_mana, 0)
	if mana_bar != null:
		mana_bar.max_value = maxf(float(maxi(safe_max_mana, 1)), 1.0)
		mana_bar.value = clampf(float(current_mana), 0.0, mana_bar.max_value)
		mana_bar.visible = true
	if mana_label != null:
		mana_label.text = "MP %d / %d" % [current_mana, max_mana]

	if exp_bar != null:
		if is_max_level:
			exp_bar.max_value = 1.0
			exp_bar.value = 1.0
		else:
			exp_bar.max_value = maxf(float(maxi(exp_needed, 1)), 1.0)
			exp_bar.value = clampf(float(exp_progress), 0.0, exp_bar.max_value)
		exp_bar.visible = true
	if exp_label != null:
		if is_max_level:
			exp_label.text = "EXP MAX"
		else:
			exp_label.text = "EXP %d / %d" % [exp_progress, exp_needed]

	if portrait_name_label != null and hero_name_label != null and hero_name_label.text.strip_edges().length() > 0:
		portrait_name_label.text = "%s  Lv.%d" % [hero_name_label.text, current_level]


func clear_hero_header() -> void:
	if hero_name_label != null:
		hero_name_label.text = "未知英雄"
	if portrait_name_label != null:
		portrait_name_label.text = "未知英雄"
	if portrait_rect != null:
		portrait_rect.texture = null


func set_hero_header(hero_name: String, current_level: int, portrait: Texture2D) -> void:
	if hero_name_label != null:
		hero_name_label.text = hero_name
	if portrait_name_label != null:
		portrait_name_label.text = "%s  Lv.%d" % [hero_name, current_level]
	if portrait_rect != null:
		portrait_rect.texture = portrait


func set_message_visible(visible_state: bool) -> void:
	if message_label != null:
		message_label.visible = visible_state


func set_message_text(text: String) -> void:
	if message_label != null and message_label.text != text:
		message_label.text = text


func show_message() -> void:
	set_message_visible(true)


func hide_message() -> void:
	set_message_visible(false)


func show_message_text(text: String) -> void:
	set_message_text(text)
	show_message()
