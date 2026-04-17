extends Node3D

const PACKS: Array[Dictionary] = [
	{
		"id": "skeletons",
		"label": "Skeletons 1.1 FREE",
		"characters_dir": "res://combat_visual_editor/KayKit_Skeletons_1.1_FREE/characters/gltf",
		"weapons_dir": "res://combat_visual_editor/KayKit_Skeletons_1.1_FREE/assets/gltf",
		"animations_dir": "res://combat_visual_editor/KayKit_Skeletons_1.1_FREE/Animations/gltf/Rig_Medium",
	},
	{
		"id": "adventurers",
		"label": "Adventurers 2.0 FREE",
		"characters_dir": "res://combat_visual_editor/KayKit_Adventurers_2.0_FREE/Characters/gltf",
		"weapons_dir": "res://combat_visual_editor/KayKit_Adventurers_2.0_FREE/Assets/gltf",
		"animations_dir": "res://combat_visual_editor/KayKit_Adventurers_2.0_FREE/Animations/gltf/Rig_Medium",
	},
	{
		"id": "newmodel",
		"label": "NewModel (Mixamo Import)",
		"characters_dir": "res://combat_visual_editor/newmodel/characters",
		"weapons_dir": "",
		"animations_dir": "",
	},
]
const SHARED_MEDIUM_ANIMATIONS_DIR := "res://combat_visual_editor/KayKit_Character_Animations_1.1/Animations/gltf/Rig_Medium"
const GENERATED_CONFIG_ROOT := "res://assets/heroes/models_3d"
const ATTACK_SLOT_COUNT := 6
const ATTACK_DEFAULT_FPS := 30.0
const MODEL_FOCUS_POINT := Vector3(0.0, 1.0, 0.0)
const UNIFIED_PACK_ID := "all_in_one"
const UNIFIED_PACK_LABEL := "All Packs (Unified)"
const UI_PANEL_MARGIN := 16.0
const UI_PANEL_GAP := 12.0
const UI_PANEL_MIN_WIDTH := 360.0
const HAT_NODE_HINTS := ["hat", "hood", "cap", "mask", "helm", "helmet"]
const HAIR_NODE_HINTS := ["hair", "beard", "brow", "mustache", "mohawk"]
const SKIN_NODE_HINTS := ["head", "face", "skin", "ear", "nose", "jaw", "skull", "neck", "hand"]
const CLOTH_NODE_HINTS := ["body", "cloak", "cape", "robe", "cloth", "coat", "armor", "torso", "leg", "pants", "skirt", "shoulder", "boot", "shoe"]
const EYE_NODE_HINTS := ["eye", "eyes", "pupil"]
const SKELETON_BONE_NODE_HINTS := ["arm", "leg", "body", "head", "jaw", "skull", "spine", "rib", "pelvis", "hand", "foot"]

const HAT_COLOR_PRESETS: Array[Dictionary] = [
	{"label": "Default", "key": "default", "color": Color(1.0, 1.0, 1.0, 1.0)},
	{"label": "Blue", "key": "blue", "color": Color(0.45, 0.72, 1.18, 1.0)},
	{"label": "Green", "key": "green", "color": Color(0.52, 1.12, 0.62, 1.0)},
	{"label": "Red", "key": "red", "color": Color(1.22, 0.48, 0.48, 1.0)},
	{"label": "Purple", "key": "purple", "color": Color(0.92, 0.62, 1.22, 1.0)},
]
const HAIR_COLOR_PRESETS: Array[Dictionary] = [
	{"label": "Default", "key": "default", "color": Color(1.0, 1.0, 1.0, 1.0)},
	{"label": "Blonde", "key": "blonde", "color": Color(1.20, 1.02, 0.58, 1.0)},
	{"label": "Brown", "key": "brown", "color": Color(0.58, 0.38, 0.24, 1.0)},
	{"label": "White", "key": "white", "color": Color(1.15, 1.15, 1.15, 1.0)},
	{"label": "Blue", "key": "blue", "color": Color(0.52, 0.74, 1.20, 1.0)},
]
const SKIN_COLOR_PRESETS: Array[Dictionary] = [
	{"label": "Default", "key": "default", "color": Color(1.0, 1.0, 1.0, 1.0)},
	{"label": "Light", "key": "light", "color": Color(1.18, 1.03, 0.95, 1.0)},
	{"label": "Warm", "key": "warm", "color": Color(1.12, 0.90, 0.76, 1.0)},
	{"label": "Deep", "key": "deep", "color": Color(0.76, 0.56, 0.44, 1.0)},
	{"label": "Cold", "key": "cold", "color": Color(0.84, 0.86, 0.94, 1.0)},
]
const CLOTH_COLOR_PRESETS: Array[Dictionary] = [
	{"label": "Default", "key": "default", "color": Color(1.0, 1.0, 1.0, 1.0)},
	{"label": "Navy", "key": "navy", "color": Color(0.58, 0.72, 1.20, 1.0)},
	{"label": "Olive", "key": "olive", "color": Color(0.66, 0.90, 0.54, 1.0)},
	{"label": "Wine", "key": "wine", "color": Color(1.08, 0.56, 0.68, 1.0)},
	{"label": "Golden", "key": "golden", "color": Color(1.06, 0.98, 0.66, 1.0)},
]

const WEAPON_TERM_CN := {}
const ANIMATION_TERM_CN := {}

const HAND_BONE_HINTS := [
	"hand.r",
	"hand_r",
	"r_hand",
	"rhand",
	"righthand",
	"right hand",
	"handslot.r",
	"handslot_r",
	"mixamorig:righthand",
	"bip001rhand",
]
const LEFT_HAND_BONE_HINTS := [
	"hand.l",
	"hand_l",
	"l_hand",
	"lhand",
	"lefthand",
	"left hand",
	"handslot.l",
	"handslot_l",
	"mixamorig:lefthand",
	"bip001lhand",
]

@onready var preview_pivot: Node3D = $PreviewPivot
@onready var spawn_root: Node3D = $PreviewPivot/SpawnRoot
@onready var camera_3d: Camera3D = $Camera3D
@onready var ui_panel: PanelContainer = $CanvasLayer/UiPanel

@onready var pack_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/PackRow/PackOption
@onready var character_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/CharacterRow/CharacterOption
@onready var weapon_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/WeaponRow/WeaponOption
@onready var left_weapon_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/LeftWeaponRow/LeftWeaponOption
@onready var animation_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AnimationRow/AnimationOption
@onready var play_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AnimationActionRow/PlayButton
@onready var stop_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AnimationActionRow/StopButton
@onready var loop_toggle: CheckButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AnimationActionRow/LoopToggle
@onready var extra_animation_toggle: CheckButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/ExtraAnimationToggle
@onready var speed_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/SpeedRow/SpeedSlider
@onready var speed_value_label: Label = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/SpeedRow/SpeedValue
@onready var hair_color_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/HairColorRow/HairColorOption
@onready var skin_color_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/SkinColorRow/SkinColorOption
@onready var cloth_color_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/ClothColorRow/ClothColorOption
@onready var hat_color_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/HatColorRow/HatColorOption
@onready var weapon_pos_x_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/WeaponTunePosRow/PosX
@onready var weapon_pos_y_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/WeaponTunePosRow/PosY
@onready var weapon_pos_z_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/WeaponTunePosRow/PosZ
@onready var weapon_rot_x_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/WeaponTuneRotRow/RotX
@onready var weapon_rot_y_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/WeaponTuneRotRow/RotY
@onready var weapon_rot_z_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/WeaponTuneRotRow/RotZ
@onready var weapon_tune_reset_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/WeaponTuneActionRow/WeaponTuneResetButton
@onready var left_weapon_pos_x_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/LeftWeaponTunePosRow/LeftPosX
@onready var left_weapon_pos_y_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/LeftWeaponTunePosRow/LeftPosY
@onready var left_weapon_pos_z_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/LeftWeaponTunePosRow/LeftPosZ
@onready var left_weapon_rot_x_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/LeftWeaponTuneRotRow/LeftRotX
@onready var left_weapon_rot_y_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/LeftWeaponTuneRotRow/LeftRotY
@onready var left_weapon_rot_z_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/LeftWeaponTuneRotRow/LeftRotZ
@onready var left_weapon_tune_reset_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/LeftWeaponTuneActionRow/LeftWeaponTuneResetButton
@onready var scale_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/ScaleRow/ScaleSlider
@onready var generate_id_input: LineEdit = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/GenerateRow/IdInput
@onready var generate_name_input: LineEdit = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/GenerateNameRow/NameInput
@onready var generate_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/GenerateRow/GenerateButton
@onready var saved_profile_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/SavedProfileRow/SavedProfileOption
@onready var load_saved_profile_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/SavedProfileRow/LoadSavedProfileButton
@onready var attack_slot_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackSlotRow/AttackSlotOption
@onready var attack_anim_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackSlotRow/AttackAnimOption
@onready var attack_hit_frames_input: LineEdit = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackFrameRow/HitFramesInput
@onready var attack_fps_input: LineEdit = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackFrameRow/AttackFpsInput
@onready var attack_frame_preview_label: Label = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackMetaRow/AttackFramePreviewLabel
@onready var attack_hit_bone_option: OptionButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackMetaRow/AttackHitBoneOption
@onready var attack_frame_slider: HSlider = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackScrubRow/AttackFrameSlider
@onready var attack_effect_input: LineEdit = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackFxRow/AttackEffectInput
@onready var attack_note_input: LineEdit = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackNoteRow/AttackNoteInput
@onready var save_attack_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackActionRow/SaveAttackButton
@onready var append_current_frame_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackActionRow/AppendCurrentFrameButton
@onready var clear_attack_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AttackActionRow/ClearAttackButton
@onready var pause_preview_toggle: CheckButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/ActionRow/PausePreviewToggle
@onready var auto_rotate_toggle: CheckButton = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/AutoRotateToggle
@onready var info_label: Label = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/InfoLabel
@onready var random_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/ActionRow/RandomButton
@onready var reset_camera_button: Button = $CanvasLayer/UiPanel/MarginContainer/ScrollContainer/VBoxContainer/ActionRow/ResetCameraButton

var _current_pack: Dictionary = {}
var _character_paths: Array[String] = []
var _weapon_paths: Array[String] = []
var _animation_scene_paths: Array[String] = []
var _animation_names: Array[String] = []
var _animation_display_names: Array[String] = []
var _character_instance: Node3D = null
var _preview_animation_player: AnimationPlayer = null
var _current_weapon_instance: Node3D = null
var _current_weapon_path := ""
var _current_left_weapon_instance: Node3D = null
var _current_left_weapon_path := ""
var _weapon_base_position := Vector3.ZERO
var _weapon_base_rotation_degrees := Vector3.ZERO
var _weapon_offset_position := Vector3.ZERO
var _weapon_offset_rotation_degrees := Vector3.ZERO
var _left_weapon_base_position := Vector3.ZERO
var _left_weapon_base_rotation_degrees := Vector3.ZERO
var _left_weapon_offset_position := Vector3.ZERO
var _left_weapon_offset_rotation_degrees := Vector3.ZERO
var _is_syncing_weapon_tune_controls := false
var _attach_note := ""
var _animation_note := ""
var _animation_source_note := ""
var _style_color_note := ""
var _weapon_tune_note := ""
var _pause_note := ""
var _generate_note := ""
var _attack_note := ""
var _is_preview_paused := false
var _generated_profile_cache: Dictionary = {}
var _attack_configs: Array[Dictionary] = []
var _is_syncing_attack_panel := false
var _is_syncing_attack_scrub_slider := false
var _attack_edit_profile_id := ""

var _is_dragging := false
var _yaw := deg_to_rad(30.0)
var _pitch := deg_to_rad(14.0)
var _distance := 5.8


func _ready() -> void:
	randomize()
	_populate_pack_options()
	_populate_hat_color_options()
	_select_first_available_pack()
	_connect_signals()
	_configure_option_button_width_behavior()
	_update_ui_panel_layout()
	_reset_camera()
	generate_id_input.text = _suggest_next_profile_id()
	generate_name_input.text = ""
	_init_attack_config_defaults()
	_populate_attack_slot_options()
	_refresh_attack_animation_options()
	_refresh_attack_hit_bone_options()
	_update_attack_frame_preview_label_clean()
	_populate_saved_profile_options()
	_reset_weapon_tune_controls(true)
	_reset_left_weapon_tune_controls(true)

	if _current_pack.is_empty():
		_set_controls_enabled(false)
		info_label.text = "No valid resource pack found.\nPlease verify res://combat_visual_editor/."
		return

	_refresh_pack_data()
func _process(delta: float) -> void:
	_update_ui_panel_layout()
	if auto_rotate_toggle.button_pressed and not _is_preview_paused:
		preview_pivot.rotate_y(delta * 0.75)
	_update_attack_frame_preview_label_clean()


func _configure_option_button_width_behavior() -> void:
	var options: Array[OptionButton] = [
		pack_option,
		character_option,
		weapon_option,
		left_weapon_option,
		animation_option,
		hair_color_option,
		skin_color_option,
		cloth_color_option,
		hat_color_option,
		saved_profile_option,
		attack_slot_option,
		attack_anim_option,
		attack_hit_bone_option,
	]
	for option in options:
		option.fit_to_longest_item = false


func _update_ui_panel_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	ui_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ui_panel.custom_minimum_size = Vector2.ZERO

	var available_width := maxf(320.0, viewport_size.x - UI_PANEL_MARGIN * 2.0)
	var half_width := available_width * 0.5 - UI_PANEL_GAP * 0.5
	var panel_width := clampf(half_width, UI_PANEL_MIN_WIDTH, available_width)
	var panel_height := maxf(260.0, viewport_size.y - UI_PANEL_MARGIN * 2.0)
	var target_position := Vector2(UI_PANEL_MARGIN, UI_PANEL_MARGIN)
	var target_size := Vector2(panel_width, panel_height)

	var layout_changed := false
	if ui_panel.position.distance_squared_to(target_position) > 0.01:
		ui_panel.position = target_position
		layout_changed = true
	if ui_panel.size.distance_squared_to(target_size) > 0.01:
		ui_panel.size = target_size
		layout_changed = true

	if layout_changed:
		_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			_is_dragging = mouse_button.pressed
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = max(2.5, _distance - 0.4)
			_update_camera()
		elif mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = min(12.0, _distance + 0.4)
			_update_camera()

	if event is InputEventMouseMotion and _is_dragging:
		var mouse_motion := event as InputEventMouseMotion
		_yaw -= mouse_motion.relative.x * 0.01
		_pitch = clamp(_pitch - mouse_motion.relative.y * 0.008, deg_to_rad(-35.0), deg_to_rad(70.0))
		_update_camera()


func _populate_pack_options() -> void:
	pack_option.clear()
	pack_option.add_item(_clean_ui_text(UNIFIED_PACK_LABEL, "All Resources (Cross-Pack)"))


func _select_first_available_pack() -> void:
	var has_any_pack := false
	for pack in PACKS:
		if _is_valid_pack(pack):
			has_any_pack = true
			break
	if has_any_pack:
		_current_pack = {
			"id": UNIFIED_PACK_ID,
			"label": UNIFIED_PACK_LABEL,
		}
	else:
		_current_pack = {}
	pack_option.select(0)


func _is_valid_pack(pack: Dictionary) -> bool:
	# Character directory is mandatory. Weapon directory can be empty in partial resource bundles.
	return _dir_exists(pack.get("characters_dir", ""))


func _dir_exists(path: String) -> bool:
	if path.is_empty():
		return false
	return DirAccess.open(path) != null


func _refresh_pack_data() -> void:
	_character_paths.clear()
	_weapon_paths.clear()
	for pack in PACKS:
		if not _is_valid_pack(pack):
			continue
		_append_unique_paths(_character_paths, _collect_scene_files(pack.get("characters_dir", "")))
		_append_unique_paths(_weapon_paths, _collect_scene_files(pack.get("weapons_dir", "")))
	_character_paths.sort()
	_weapon_paths.sort()
	_rebuild_animation_scene_paths()

	_weapon_paths.insert(0, "")
	_populate_model_options()
	_populate_animation_options([])
	_refresh_attack_animation_options()

	var has_character := not _character_paths.is_empty()
	_set_controls_enabled(has_character)
	if not has_character:
		info_label.text = "No character model found in resource packs."
		return

	_apply_selection()
func _append_unique_paths(target: Array[String], incoming: Array[String]) -> void:
	for path in incoming:
		if not target.has(path):
			target.append(path)


func _collect_scene_files(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	if dir_path.is_empty():
		return paths

	if not _dir_exists(dir_path):
		return paths

	var file_names := DirAccess.get_files_at(dir_path)
	file_names.sort()

	for file_name in file_names:
		var lower_name := file_name.to_lower()
		if lower_name.ends_with(".glb") or lower_name.ends_with(".gltf"):
			var full_path := "%s/%s" % [dir_path, file_name]
			if not ResourceLoader.exists(full_path, "PackedScene"):
				continue
			paths.append(full_path)

	return paths


func _populate_model_options() -> void:
	character_option.clear()
	for path in _character_paths:
		character_option.add_item(_display_character_name_from_path(path))

	weapon_option.clear()
	weapon_option.add_item("None")
	for i in range(1, _weapon_paths.size()):
		weapon_option.add_item(_display_weapon_name_from_path(_weapon_paths[i]))
	left_weapon_option.clear()
	left_weapon_option.add_item("None")
	for i in range(1, _weapon_paths.size()):
		left_weapon_option.add_item(_display_weapon_name_from_path(_weapon_paths[i]))

	if not _character_paths.is_empty():
		character_option.select(0)
	weapon_option.select(0)
	left_weapon_option.select(0)
func _populate_hat_color_options() -> void:
	_populate_preset_option(hair_color_option, HAIR_COLOR_PRESETS)
	_populate_preset_option(skin_color_option, SKIN_COLOR_PRESETS)
	_populate_preset_option(cloth_color_option, CLOTH_COLOR_PRESETS)
	_populate_preset_option(hat_color_option, HAT_COLOR_PRESETS)


func _populate_preset_option(option: OptionButton, presets: Array[Dictionary]) -> void:
	option.clear()
	for preset in presets:
		var fallback_label := str(preset.get("key", "default"))
		option.add_item(_clean_ui_text(str(preset.get("label", "")), fallback_label))
	option.select(0)
func _populate_animation_options(animation_names: Array[String]) -> void:
	_animation_names = animation_names.duplicate()
	_animation_display_names.clear()
	animation_option.clear()

	if _animation_names.is_empty():
		animation_option.add_item("No animation available")
		animation_option.disabled = true
		play_button.disabled = true
		stop_button.disabled = true
		return

	animation_option.disabled = false
	play_button.disabled = false
	stop_button.disabled = false
	for anim_name in _animation_names:
		var display_name := _build_animation_display_name(anim_name)
		_animation_display_names.append(display_name)
		animation_option.add_item(display_name)

	var idle_index := _animation_names.find("Idle_A")
	if idle_index >= 0:
		animation_option.select(idle_index)
	else:
		animation_option.select(0)
	_refresh_attack_animation_options()
func _connect_signals() -> void:
	pack_option.item_selected.connect(_on_pack_selected)
	character_option.item_selected.connect(_on_character_selected)
	weapon_option.item_selected.connect(_on_weapon_selected)
	left_weapon_option.item_selected.connect(_on_left_weapon_selected)
	animation_option.item_selected.connect(_on_animation_selected)
	play_button.pressed.connect(_on_play_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	loop_toggle.toggled.connect(_on_loop_toggled)
	extra_animation_toggle.toggled.connect(_on_extra_animation_toggled)
	speed_slider.value_changed.connect(_on_speed_changed)
	hair_color_option.item_selected.connect(_on_style_color_changed)
	skin_color_option.item_selected.connect(_on_style_color_changed)
	cloth_color_option.item_selected.connect(_on_style_color_changed)
	hat_color_option.item_selected.connect(_on_hat_color_selected)
	weapon_pos_x_slider.value_changed.connect(_on_weapon_tune_slider_changed)
	weapon_pos_y_slider.value_changed.connect(_on_weapon_tune_slider_changed)
	weapon_pos_z_slider.value_changed.connect(_on_weapon_tune_slider_changed)
	weapon_rot_x_slider.value_changed.connect(_on_weapon_tune_slider_changed)
	weapon_rot_y_slider.value_changed.connect(_on_weapon_tune_slider_changed)
	weapon_rot_z_slider.value_changed.connect(_on_weapon_tune_slider_changed)
	weapon_tune_reset_button.pressed.connect(_on_weapon_tune_reset_pressed)
	left_weapon_pos_x_slider.value_changed.connect(_on_left_weapon_tune_slider_changed)
	left_weapon_pos_y_slider.value_changed.connect(_on_left_weapon_tune_slider_changed)
	left_weapon_pos_z_slider.value_changed.connect(_on_left_weapon_tune_slider_changed)
	left_weapon_rot_x_slider.value_changed.connect(_on_left_weapon_tune_slider_changed)
	left_weapon_rot_y_slider.value_changed.connect(_on_left_weapon_tune_slider_changed)
	left_weapon_rot_z_slider.value_changed.connect(_on_left_weapon_tune_slider_changed)
	left_weapon_tune_reset_button.pressed.connect(_on_left_weapon_tune_reset_pressed)
	scale_slider.value_changed.connect(_on_scale_changed)
	generate_button.pressed.connect(_on_generate_profile_pressed)
	generate_id_input.text_changed.connect(_on_generate_id_text_changed)
	saved_profile_option.item_selected.connect(_on_saved_profile_selected)
	load_saved_profile_button.pressed.connect(_on_load_saved_profile_pressed)
	attack_slot_option.item_selected.connect(_on_attack_slot_selected)
	attack_anim_option.item_selected.connect(_on_attack_animation_selected)
	attack_frame_slider.value_changed.connect(_on_attack_frame_slider_changed)
	attack_frame_slider.drag_started.connect(_on_attack_frame_slider_drag_started)
	save_attack_button.pressed.connect(_on_save_attack_slot_pressed)
	append_current_frame_button.pressed.connect(_on_append_current_frame_pressed)
	clear_attack_button.pressed.connect(_on_clear_attack_slot_pressed)
	random_button.pressed.connect(_on_random_pressed)
	reset_camera_button.pressed.connect(_on_reset_camera_pressed)
	pause_preview_toggle.toggled.connect(_on_pause_preview_toggled)


func _set_controls_enabled(enabled: bool) -> void:
	pack_option.disabled = true
	character_option.disabled = not enabled
	weapon_option.disabled = not enabled
	left_weapon_option.disabled = not enabled
	animation_option.disabled = not enabled
	play_button.disabled = not enabled
	stop_button.disabled = not enabled
	loop_toggle.disabled = not enabled
	extra_animation_toggle.disabled = not enabled
	speed_slider.editable = enabled
	hair_color_option.disabled = not enabled
	skin_color_option.disabled = not enabled
	cloth_color_option.disabled = not enabled
	hat_color_option.disabled = not enabled
	_set_weapon_tune_enabled(enabled and _current_weapon_instance != null, enabled and _current_left_weapon_instance != null)
	scale_slider.editable = enabled
	generate_id_input.editable = enabled
	generate_name_input.editable = enabled
	generate_button.disabled = not enabled
	saved_profile_option.disabled = not enabled or saved_profile_option.item_count <= 1
	load_saved_profile_button.disabled = not enabled or saved_profile_option.item_count <= 1
	attack_slot_option.disabled = not enabled
	attack_anim_option.disabled = not enabled or attack_anim_option.item_count <= 1
	attack_frame_slider.editable = enabled and attack_frame_slider.max_value > 0.0
	attack_hit_frames_input.editable = enabled
	attack_fps_input.editable = enabled
	attack_hit_bone_option.disabled = not enabled or attack_hit_bone_option.item_count <= 1
	attack_effect_input.editable = enabled
	attack_note_input.editable = enabled
	save_attack_button.disabled = not enabled
	append_current_frame_button.disabled = not enabled
	clear_attack_button.disabled = not enabled
	random_button.disabled = not enabled
	reset_camera_button.disabled = not enabled
	pause_preview_toggle.disabled = not enabled
	auto_rotate_toggle.disabled = not enabled
	if not enabled:
		_is_preview_paused = false
		pause_preview_toggle.button_pressed = false
		_pause_note = ""


func _on_pack_selected(index: int) -> void:
	if index != 0:
		return
	_refresh_pack_data()


func _on_character_selected(_index: int) -> void:
	_apply_selection()


func _on_weapon_selected(_index: int) -> void:
	_apply_selection()


func _on_left_weapon_selected(_index: int) -> void:
	_apply_selection()


func _on_animation_selected(_index: int) -> void:
	_play_selected_animation()


func _on_play_pressed() -> void:
	_play_selected_animation()


func _on_stop_pressed() -> void:
	if _preview_animation_player != null:
		_preview_animation_player.stop()
		_animation_note = "Animation stopped."
		_animation_note = "锟斤拷锟斤拷锟斤拷停止"
		_animation_note = "Animation stopped."
		_update_attack_frame_preview_label_clean()
		_update_info()


func _on_loop_toggled(_pressed: bool) -> void:
	_update_selected_animation_loop_mode()
	_play_selected_animation()


func _on_extra_animation_toggled(_pressed: bool) -> void:
	_rebuild_animation_scene_paths()
	_setup_preview_animations()
	_update_info()


func _on_speed_changed(value: float) -> void:
	speed_value_label.text = "%.2fx" % value
	if _preview_animation_player != null:
		if _is_preview_paused:
			_preview_animation_player.speed_scale = 0.0
		else:
			_preview_animation_player.speed_scale = value
	_update_info()


func _on_pause_preview_toggled(pressed: bool) -> void:
	_is_preview_paused = pressed
	_apply_preview_pause_state()
	_update_info()


func _on_style_color_changed(_index: int) -> void:
	_apply_style_colors()
	_update_info()


func _on_hat_color_selected(_index: int) -> void:
	_apply_style_colors()
	_update_info()


func _on_weapon_tune_slider_changed(_value: float) -> void:
	if _is_syncing_weapon_tune_controls:
		return
	_weapon_offset_position = Vector3(
		weapon_pos_x_slider.value,
		weapon_pos_y_slider.value,
		weapon_pos_z_slider.value
	)
	_weapon_offset_rotation_degrees = Vector3(
		weapon_rot_x_slider.value,
		weapon_rot_y_slider.value,
		weapon_rot_z_slider.value
	)
	_apply_weapon_tune_to_current_weapon()
	_update_info()


func _on_left_weapon_tune_slider_changed(_value: float) -> void:
	if _is_syncing_weapon_tune_controls:
		return
	_left_weapon_offset_position = Vector3(
		left_weapon_pos_x_slider.value,
		left_weapon_pos_y_slider.value,
		left_weapon_pos_z_slider.value
	)
	_left_weapon_offset_rotation_degrees = Vector3(
		left_weapon_rot_x_slider.value,
		left_weapon_rot_y_slider.value,
		left_weapon_rot_z_slider.value
	)
	_apply_left_weapon_tune_to_current_weapon()
	_update_info()


func _on_weapon_tune_reset_pressed() -> void:
	_reset_weapon_tune_controls(false)
	_apply_weapon_tune_to_current_weapon()
	_update_info()


func _on_left_weapon_tune_reset_pressed() -> void:
	_reset_left_weapon_tune_controls(false)
	_apply_left_weapon_tune_to_current_weapon()
	_update_info()


func _on_scale_changed(_value: float) -> void:
	if _character_instance == null:
		return
	_character_instance.scale = Vector3.ONE * scale_slider.value
	_update_info()


func _on_generate_profile_pressed() -> void:
	var parsed := _parse_profile_id_and_name(generate_id_input.text, generate_name_input.text)
	var profile_id := str(parsed.get("id", "")).strip_edges()
	var profile_name := _sanitize_profile_name(str(parsed.get("name", "")))
	if profile_id.is_empty():
		_generate_note = "Save failed: enter a numeric profile ID, e.g. 1001."
		_update_info()
		return
	if not _is_all_digits(profile_id):
		_generate_note = "Save failed: profile ID must be digits only."
		_update_info()
		return
	if _character_paths.is_empty():
		_generate_note = "Save failed: no selectable character in current pack."
		_update_info()
		return

	var saved_path := _save_current_profile(profile_id, profile_name)
	if saved_path.is_empty():
		_generate_note = "Save failed: could not write profile files."
		_update_info()
		return

	_attack_edit_profile_id = profile_id
	_generate_note = "Saved profile %s to %s." % [_compose_profile_display_name(profile_id, profile_name), saved_path]
	generate_id_input.text = _suggest_next_profile_id(profile_id)
	generate_name_input.text = ""
	_populate_saved_profile_options()
	_update_info()
func _on_generate_id_text_changed(new_text: String) -> void:
	var parsed := _parse_profile_id_and_name(new_text, generate_name_input.text)
	var profile_id := str(parsed.get("id", "")).strip_edges()
	if profile_id.is_empty():
		return
	if profile_id == _attack_edit_profile_id:
		return
	_attack_edit_profile_id = profile_id
	if _attack_configs.is_empty():
		return
	_init_attack_config_defaults()
	_refresh_attack_slot_labels_clean()
	_sync_attack_panel_from_slot(0)
	_attack_note = "Switched attack edit target to profile ID %s. Slots were reset." % profile_id
	_update_info()
func _on_saved_profile_selected(index: int) -> void:
	if index <= 0 or index >= saved_profile_option.item_count:
		return
	var profile_id := str(saved_profile_option.get_item_metadata(index))
	if profile_id.is_empty():
		return
	generate_id_input.text = _display_profile_id_text(profile_id)
	var payload_variant: Variant = _generated_profile_cache.get(profile_id, {})
	if payload_variant is Dictionary:
		var raw_name := str((payload_variant as Dictionary).get("profile_name", ""))
		generate_name_input.text = _sanitize_profile_name(raw_name)


func _on_load_saved_profile_pressed() -> void:
	var index := saved_profile_option.selected
	if index <= 0:
		_generate_note = "Select one generated profile first."
		_update_info()
		return
	if index >= saved_profile_option.item_count:
		return
	var profile_id := str(saved_profile_option.get_item_metadata(index))
	if profile_id.is_empty():
		return
	_load_profile_by_id(profile_id)
func _init_attack_config_defaults() -> void:
	_attack_configs.clear()
	for _i in range(ATTACK_SLOT_COUNT):
		_attack_configs.append({})


func _populate_attack_slot_options() -> void:
	attack_slot_option.clear()
	for i in range(ATTACK_SLOT_COUNT):
		attack_slot_option.add_item("Slot %d (empty)" % (i + 1))
	attack_slot_option.select(0)
	if attack_anim_option.item_count == 0:
		attack_anim_option.add_item("Not Set")
		attack_anim_option.set_item_metadata(0, "")
	if attack_hit_bone_option.item_count == 0:
		attack_hit_bone_option.add_item("Auto Hand Bone")
		attack_hit_bone_option.set_item_metadata(0, "")
	_refresh_attack_slot_labels_clean()
	_sync_attack_panel_from_slot(0)


func _refresh_attack_animation_options() -> void:
	var selected_slot := clampi(attack_slot_option.selected, 0, ATTACK_SLOT_COUNT - 1)
	var selected_animation_name := ""
	if selected_slot >= 0 and selected_slot < _attack_configs.size():
		var selected_cfg_variant: Variant = _attack_configs[selected_slot]
		if selected_cfg_variant is Dictionary:
			selected_animation_name = str((selected_cfg_variant as Dictionary).get("animation_name", ""))

	attack_anim_option.clear()
	attack_anim_option.add_item("Not Set")
	attack_anim_option.set_item_metadata(0, "")
	for i in range(_animation_names.size()):
		var display_name := _animation_names[i]
		if i < _animation_display_names.size():
			display_name = _animation_display_names[i]
		attack_anim_option.add_item(display_name)
		attack_anim_option.set_item_metadata(i + 1, _animation_names[i])
	attack_anim_option.disabled = _animation_names.is_empty()
	var previous_sync := _is_syncing_attack_panel
	_is_syncing_attack_panel = true
	_select_attack_animation_option_by_name(selected_animation_name)
	_is_syncing_attack_panel = previous_sync


func _on_attack_slot_selected(index: int) -> void:
	_sync_attack_panel_from_slot(index)


func _on_attack_animation_selected(index: int) -> void:
	if _is_syncing_attack_panel:
		return
	if index <= 0 or index >= attack_anim_option.item_count:
		_update_attack_frame_preview_label_clean()
		return
	var animation_name := str(attack_anim_option.get_item_metadata(index))
	if animation_name.is_empty():
		_update_attack_frame_preview_label_clean()
		return
	var main_index := _animation_names.find(animation_name)
	if main_index < 0:
		return
	animation_option.select(main_index)
	_play_selected_animation()
	_update_attack_frame_preview_label_clean()


func _on_attack_frame_slider_drag_started() -> void:
	if _is_preview_paused:
		return
	_is_preview_paused = true
	pause_preview_toggle.set_pressed_no_signal(true)
	_apply_preview_pause_state()


func _on_attack_frame_slider_changed(value: float) -> void:
	if _is_syncing_attack_scrub_slider:
		return
	_seek_attack_frame(int(round(value)), true)


func _on_save_attack_slot_pressed() -> void:
	var slot_index := clampi(attack_slot_option.selected, 0, ATTACK_SLOT_COUNT - 1)
	var config := _collect_attack_config_from_panel(slot_index)
	_attack_configs[slot_index] = config
	_refresh_attack_slot_labels_clean()
	_sync_attack_panel_from_slot(slot_index)
	var animation_name := str(config.get("animation_name", ""))
	var saved_frames := _extract_frame_array(config.get("hit_frames", []))
	var frame_count := saved_frames.size()
	var frame_text := _frames_to_text(saved_frames)
	if animation_name.is_empty():
		_attack_note = "锟斤拷锟斤拷锟斤拷%d锟窖憋拷锟芥（未锟斤拷锟矫讹拷锟斤拷锟斤拷" % (slot_index + 1)
	elif frame_count <= 0:
		_attack_note = "锟斤拷锟斤拷锟斤拷%d锟窖憋拷锟芥（锟斤拷锟斤拷锟斤拷锟斤拷锟矫ｏ拷锟斤拷锟斤拷帧为锟秸ｏ拷" % (slot_index + 1)
	else:
		_attack_note = "锟斤拷锟斤拷锟斤拷%d锟窖憋拷锟芥（锟斤拷锟斤拷帧锟斤拷%s锟斤拷" % [
			slot_index + 1,
			frame_text,
		]
	var persist_suffix := _persist_current_profile_after_attack_edit()
	if not persist_suffix.is_empty():
		_attack_note += persist_suffix
	_update_info()


func _on_clear_attack_slot_pressed() -> void:
	var slot_index := clampi(attack_slot_option.selected, 0, ATTACK_SLOT_COUNT - 1)
	_attack_configs[slot_index] = {}
	_refresh_attack_slot_labels_clean()
	_sync_attack_panel_from_slot(slot_index)
	_attack_note = "Cleared attack slot %d." % (slot_index + 1)
	var persist_suffix := _persist_current_profile_after_attack_edit()
	if not persist_suffix.is_empty():
		_attack_note += persist_suffix
	_update_info()


func _persist_current_profile_after_attack_edit() -> String:
	var parsed := _parse_profile_id_and_name(generate_id_input.text, generate_name_input.text)
	var profile_id := str(parsed.get("id", "")).strip_edges()
	if profile_id.is_empty():
		return "锟斤拷未写锟斤拷锟斤拷锟矫ｏ拷锟斤拷锟斤拷锟斤拷写锟斤拷锟斤拷ID锟斤拷"
	if not _is_all_digits(profile_id):
		return "锟斤拷未写锟斤拷锟斤拷锟矫ｏ拷ID锟斤拷为锟斤拷锟街ｏ拷"
	if _attack_edit_profile_id != profile_id:
		if _attack_edit_profile_id.is_empty():
			return "锟斤拷未写锟斤拷锟斤拷锟矫ｏ拷锟斤拷锟斤拷锟叫伙拷锟斤拷目锟斤拷ID锟斤拷锟劫编辑锟斤拷"
		return "锟斤拷未写锟斤拷锟斤拷锟矫ｏ拷锟斤拷前锟捷革拷锟斤拷锟斤拷ID %s锟斤拷" % _attack_edit_profile_id

	var profile_name := _sanitize_profile_name(str(parsed.get("name", "")))
	if profile_name.is_empty():
		var cached_variant: Variant = _generated_profile_cache.get(profile_id, {})
		if cached_variant is Dictionary:
			profile_name = _sanitize_profile_name(str((cached_variant as Dictionary).get("profile_name", "")))

	var saved_path := _save_current_profile(profile_id, profile_name)
	if saved_path.is_empty():
		return "锟斤拷写锟斤拷锟斤拷锟斤拷失锟杰ｏ拷"

	generate_id_input.text = profile_id
	generate_name_input.text = profile_name
	_populate_saved_profile_options(profile_id)
	return "锟斤拷锟斤拷写锟斤拷%s锟斤拷" % _compose_profile_display_name(profile_id, profile_name)


func _on_append_current_frame_pressed() -> void:
	var current_frame := _current_attack_frame_index()
	if current_frame < 0:
		_attack_note = "锟斤拷锟饺诧拷锟脚讹拷锟斤拷锟斤拷锟斤拷追锟接碉拷前帧"
		_update_info()
		return
	var frames := _parse_hit_frames_text(attack_hit_frames_input.text)
	if not frames.has(current_frame):
		frames.append(current_frame)
		frames.sort()
	attack_hit_frames_input.text = _frames_to_text(frames)
	_attack_note = "锟斤拷追锟接碉拷前帧锟斤拷%d" % current_frame
	_update_info()


func _sync_attack_panel_from_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= ATTACK_SLOT_COUNT:
		return
	_is_syncing_attack_panel = true
	var config: Dictionary = {}
	if slot_index < _attack_configs.size():
		var variant_cfg: Variant = _attack_configs[slot_index]
		if variant_cfg is Dictionary:
			config = variant_cfg as Dictionary

	var animation_name := _extract_release_animation_name(config)
	var hit_frames := _extract_frame_array(config.get("hit_frames", []))
	var fps := float(config.get("fps", ATTACK_DEFAULT_FPS))
	var hit_bone := str(config.get("hit_bone", ""))

	_select_attack_animation_option_by_name(animation_name)
	attack_hit_frames_input.text = _frames_to_text(hit_frames)
	attack_fps_input.text = _float_to_text(fps, 2)
	_select_attack_hit_bone_option_by_name(hit_bone)
	attack_effect_input.text = str(config.get("effect_id", ""))
	attack_note_input.text = str(config.get("note", ""))
	_is_syncing_attack_panel = false
	_update_attack_frame_preview_label_clean()


func _collect_attack_config_from_panel(slot_index: int) -> Dictionary:
	var existing_config: Dictionary = {}
	if slot_index >= 0 and slot_index < _attack_configs.size():
		var existing_variant: Variant = _attack_configs[slot_index]
		if existing_variant is Dictionary:
			existing_config = (existing_variant as Dictionary).duplicate(true)
	var animation_name := ""
	if attack_anim_option.selected >= 0 and attack_anim_option.selected < attack_anim_option.item_count:
		animation_name = str(attack_anim_option.get_item_metadata(attack_anim_option.selected))
	var hit_frames := _parse_hit_frames_text(attack_hit_frames_input.text)
	var fps := _safe_parse_float(attack_fps_input.text, ATTACK_DEFAULT_FPS)
	var hit_bone := ""
	if attack_hit_bone_option.selected > 0 and attack_hit_bone_option.selected < attack_hit_bone_option.item_count:
		hit_bone = str(attack_hit_bone_option.get_item_metadata(attack_hit_bone_option.selected))
	existing_config["slot"] = slot_index + 1
	existing_config["animation_name"] = animation_name
	existing_config["release_animation_name"] = animation_name
	existing_config["hit_frames"] = hit_frames
	existing_config["fps"] = maxf(1.0, fps)
	existing_config["hit_bone"] = hit_bone
	existing_config["effect_id"] = attack_effect_input.text.strip_edges()
	existing_config["note"] = attack_note_input.text.strip_edges()
	return existing_config


func _refresh_attack_slot_labels() -> void:
	_refresh_attack_slot_labels_clean()
func _select_attack_animation_option_by_name(animation_name: String) -> void:
	for i in range(attack_anim_option.item_count):
		if str(attack_anim_option.get_item_metadata(i)) == animation_name:
			attack_anim_option.select(i)
			return
	attack_anim_option.select(0)


func _refresh_attack_hit_bone_options(select_bone: String = "") -> void:
	attack_hit_bone_option.clear()
	attack_hit_bone_option.add_item("Auto Hand Bone")
	attack_hit_bone_option.set_item_metadata(0, "")
	var skeleton := _find_first_skeleton(_character_instance)
	if skeleton != null:
		for i in range(skeleton.get_bone_count()):
			var bone_name := skeleton.get_bone_name(i)
			attack_hit_bone_option.add_item(bone_name)
			attack_hit_bone_option.set_item_metadata(attack_hit_bone_option.item_count - 1, bone_name)
	attack_hit_bone_option.disabled = attack_hit_bone_option.item_count <= 1
	_select_attack_hit_bone_option_by_name(select_bone)


func _select_attack_hit_bone_option_by_name(bone_name: String) -> void:
	if attack_hit_bone_option.item_count == 0:
		return
	var target := bone_name.strip_edges()
	if target.is_empty():
		attack_hit_bone_option.select(0)
		return
	for i in range(1, attack_hit_bone_option.item_count):
		if str(attack_hit_bone_option.get_item_metadata(i)) == target:
			attack_hit_bone_option.select(i)
			return
	attack_hit_bone_option.select(0)


func _current_attack_animation_name() -> String:
	if attack_anim_option.selected >= 0 and attack_anim_option.selected < attack_anim_option.item_count:
		return str(attack_anim_option.get_item_metadata(attack_anim_option.selected))
	return ""


func _current_attack_fps() -> float:
	return maxf(1.0, _safe_parse_float(attack_fps_input.text, ATTACK_DEFAULT_FPS))


func _attack_animation_length_seconds(animation_name: String) -> float:
	if _preview_animation_player == null:
		return 0.0
	if animation_name.is_empty():
		return 0.0
	var animation := _preview_animation_player.get_animation(animation_name)
	if animation == null:
		return 0.0
	return animation.length


func _current_attack_max_frame() -> int:
	var animation_name := _current_attack_animation_name()
	if animation_name.is_empty():
		return 0
	var fps := _current_attack_fps()
	var length_seconds := _attack_animation_length_seconds(animation_name)
	if length_seconds <= 0.0:
		return 0
	return maxi(0, int(ceil(length_seconds * fps)))


func _current_attack_frame_index() -> int:
	if _preview_animation_player == null:
		return -1
	var attack_animation := _current_attack_animation_name()
	if attack_animation.is_empty():
		return -1
	if not _preview_animation_player.is_playing():
		return -1
	if _preview_animation_player.current_animation != attack_animation:
		return -1
	var fps := _current_attack_fps()
	var seconds := _preview_animation_player.current_animation_position
	return int(floor(seconds * fps))


func _seek_attack_frame(frame_index: int, force_pause: bool) -> void:
	if _preview_animation_player == null:
		return
	var attack_animation := _current_attack_animation_name()
	if attack_animation.is_empty():
		return
	var animation := _preview_animation_player.get_animation(attack_animation)
	if animation == null:
		return
	if _preview_animation_player.current_animation != attack_animation:
		var main_index := _animation_names.find(attack_animation)
		if main_index >= 0:
			animation_option.select(main_index)
			_play_selected_animation()
	if force_pause and not _is_preview_paused:
		_is_preview_paused = true
		pause_preview_toggle.set_pressed_no_signal(true)
		_apply_preview_pause_state()
	var fps := _current_attack_fps()
	var max_frame := _current_attack_max_frame()
	var clamped_frame := clampi(frame_index, 0, max_frame)
	var target_seconds := 0.0
	if fps > 0.0:
		target_seconds = float(clamped_frame) / fps
	var max_seconds := maxf(0.0, animation.length - 0.0001)
	target_seconds = clampf(target_seconds, 0.0, max_seconds)
	_preview_animation_player.seek(target_seconds, true)
	_update_attack_frame_preview_label_clean()
	_attack_note = "锟窖讹拷位锟斤拷帧锟斤拷%d" % clamped_frame
	_update_info()


func _update_attack_frame_preview_label() -> void:
	_update_attack_frame_preview_label_clean()
func _refresh_attack_slot_labels_clean() -> void:
	var selected_slot := clampi(attack_slot_option.selected, 0, ATTACK_SLOT_COUNT - 1)
	for i in range(ATTACK_SLOT_COUNT):
		var label := "\u69fd\u4f4d%d\uff08\u672a\u914d\u7f6e\uff09" % (i + 1)
		if i < _attack_configs.size():
			var cfg_variant: Variant = _attack_configs[i]
			if cfg_variant is Dictionary:
				var cfg := cfg_variant as Dictionary
				var animation_name := _extract_release_animation_name(cfg)
				if not animation_name.is_empty():
					var frames := _extract_frame_array(cfg.get("hit_frames", []))
					frames.sort()
					var frame_count := frames.size()
					if frame_count <= 0:
						label = "\u69fd\u4f4d%d\uff08\u5df2\u9009\u52a8\u4f5c\uff0c\u672a\u586b\u547d\u4e2d\u5e27\uff09" % (i + 1)
					elif frame_count == 1:
						label = "\u69fd\u4f4d%d\uff08\u547d\u4e2d\u5e27 %d\uff09" % [(i + 1), frames[0]]
					elif frame_count <= 3:
						label = "\u69fd\u4f4d%d\uff08\u547d\u4e2d\u5e27 %s\uff09" % [(i + 1), _frames_to_text(frames)]
					else:
						label = "\u69fd\u4f4d%d\uff08%d \u4e2a\u547d\u4e2d\u5e27\uff09" % [(i + 1), frame_count]
		attack_slot_option.set_item_text(i, label)
	if selected_slot >= 0 and selected_slot < attack_slot_option.item_count:
		attack_slot_option.select(selected_slot)


func _update_attack_frame_preview_label_clean() -> void:
	var current_frame := _current_attack_frame_index()
	var max_frame := _current_attack_max_frame()
	_is_syncing_attack_scrub_slider = true
	attack_frame_slider.min_value = 0.0
	attack_frame_slider.max_value = float(max_frame)
	attack_frame_slider.step = 1.0
	attack_frame_slider.editable = max_frame > 0
	if current_frame >= 0:
		attack_frame_slider.value = float(clampi(current_frame, 0, max_frame))
	elif max_frame <= 0:
		attack_frame_slider.value = 0.0
	_is_syncing_attack_scrub_slider = false

	if current_frame < 0:
		attack_frame_preview_label.text = "\u5f53\u524d\u5e27\uff1a- / %d" % max_frame
		return
	var seconds := 0.0
	if _preview_animation_player != null:
		seconds = _preview_animation_player.current_animation_position
	attack_frame_preview_label.text = "\u5f53\u524d\u5e27\uff1a%d / %d (%.2fs)" % [current_frame, max_frame, seconds]


func _animation_display_name_by_name(animation_name: String) -> String:
	var index := _animation_names.find(animation_name)
	if index >= 0 and index < _animation_display_names.size():
		return _animation_display_names[index]
	if index >= 0:
		return _animation_names[index]
	return animation_name


func _parse_hit_frames_text(text: String) -> Array[int]:
	var normalized := text
	normalized = normalized.replace("锟斤拷", ",")
	normalized = normalized.replace("锟斤拷", ",")
	normalized = normalized.replace(";", ",")
	normalized = normalized.replace("锟斤拷", ",")
	normalized = normalized.replace("|", ",")
	normalized = normalized.replace("\n", ",")
	normalized = normalized.replace("\t", ",")
	normalized = normalized.replace(" ", "")
	var tokens := normalized.split(",", false)
	var frames: Array[int] = []
	for token in tokens:
		var t := token.strip_edges()
		if not _is_all_digits(t):
			continue
		var frame := int(t)
		if frame < 0:
			continue
		if not frames.has(frame):
			frames.append(frame)
	return frames


func _frames_to_text(frames: Array[int]) -> String:
	if frames.is_empty():
		return ""
	var parts: Array[String] = []
	for frame in frames:
		parts.append(str(frame))
	return ",".join(parts)


func _safe_parse_float(text: String, fallback: float) -> float:
	var value := text.strip_edges()
	if value.is_empty():
		return fallback
	if not value.is_valid_float():
		return fallback
	return value.to_float()


func _float_to_text(value: float, decimals: int) -> String:
	var format := "%%.%df" % decimals
	var text := format % value
	text = text.trim_suffix("0")
	text = text.trim_suffix(".")
	if text.is_empty():
		return "0"
	return text


func _extract_frame_array(raw_value: Variant) -> Array[int]:
	var frames: Array[int] = []
	if raw_value is Array:
		for item in raw_value:
			var frame := int(item)
			if frame < 0:
				continue
			if not frames.has(frame):
				frames.append(frame)
	elif raw_value is PackedInt32Array:
		var packed := raw_value as PackedInt32Array
		for frame in packed:
			if frame < 0:
				continue
			if not frames.has(frame):
				frames.append(frame)
	return frames


func _extract_release_animation_name(config: Dictionary) -> String:
	var release_name := str(config.get("release_animation_name", "")).strip_edges()
	if not release_name.is_empty():
		return release_name
	return str(config.get("animation_name", "")).strip_edges()


func _build_attack_plan_payload() -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	for i in range(ATTACK_SLOT_COUNT):
		if i >= _attack_configs.size():
			continue
		var cfg_variant: Variant = _attack_configs[i]
		if cfg_variant is not Dictionary:
			continue
		var cfg := cfg_variant as Dictionary
		var release_animation_name := _extract_release_animation_name(cfg)
		if release_animation_name.is_empty():
			continue
		var windup_animation_name := str(cfg.get("windup_animation_name", "")).strip_edges()
		var recover_animation_name := str(cfg.get("recover_animation_name", "")).strip_edges()
		var frames := _extract_frame_array(cfg.get("hit_frames", []))
		var fps := maxf(1.0, float(cfg.get("fps", ATTACK_DEFAULT_FPS)))
		var hit_seconds: Array[float] = []
		for frame in frames:
			hit_seconds.append(float(frame) / fps)
		var entry: Dictionary = {
			"slot": i + 1,
			"animation_name": release_animation_name,
			"release_animation_name": release_animation_name,
			"animation_label": _animation_display_name_by_name(release_animation_name),
			"fps": fps,
			"hit_frames": frames,
			"hit_seconds": hit_seconds,
			"hit_bone": str(cfg.get("hit_bone", "")),
			"effect_id": str(cfg.get("effect_id", "")),
			"note": str(cfg.get("note", "")),
		}
		if not windup_animation_name.is_empty():
			entry["windup_animation_name"] = windup_animation_name
		if not recover_animation_name.is_empty():
			entry["recover_animation_name"] = recover_animation_name
		plan.append(entry)
	return plan


func _count_attack_slots_in_use() -> int:
	var count := 0
	for i in range(ATTACK_SLOT_COUNT):
		if i >= _attack_configs.size():
			continue
		var cfg_variant: Variant = _attack_configs[i]
		if cfg_variant is not Dictionary:
			continue
		var animation_name := _extract_release_animation_name(cfg_variant as Dictionary)
		if not animation_name.is_empty():
			count += 1
	return count


func _load_attack_plan_from_payload(payload: Dictionary) -> void:
	_init_attack_config_defaults()
	var plan_variant: Variant = payload.get("attack_plan", [])
	if plan_variant is not Array:
		_refresh_attack_slot_labels_clean()
		_sync_attack_panel_from_slot(clampi(attack_slot_option.selected, 0, ATTACK_SLOT_COUNT - 1))
		_attack_note = ""
		return

	for entry_variant in plan_variant:
		if entry_variant is not Dictionary:
			continue
		var entry := entry_variant as Dictionary
		var slot_index := int(entry.get("slot", 0)) - 1
		if slot_index < 0 or slot_index >= ATTACK_SLOT_COUNT:
			continue
		var release_animation_name := str(entry.get("release_animation_name", entry.get("animation_name", ""))).strip_edges()
		_attack_configs[slot_index] = {
			"slot": slot_index + 1,
			"animation_name": release_animation_name,
			"release_animation_name": release_animation_name,
			"windup_animation_name": str(entry.get("windup_animation_name", "")).strip_edges(),
			"recover_animation_name": str(entry.get("recover_animation_name", "")).strip_edges(),
			"hit_frames": _extract_frame_array(entry.get("hit_frames", [])),
			"fps": maxf(1.0, float(entry.get("fps", ATTACK_DEFAULT_FPS))),
			"hit_bone": str(entry.get("hit_bone", "")),
			"effect_id": str(entry.get("effect_id", "")),
			"note": str(entry.get("note", "")),
		}

	_refresh_attack_slot_labels_clean()
	_sync_attack_panel_from_slot(clampi(attack_slot_option.selected, 0, ATTACK_SLOT_COUNT - 1))
	var used_slots := _count_attack_slots_in_use()
	_attack_note = "锟斤拷锟斤拷锟斤拷锟脚ｏ拷锟斤拷锟斤拷锟斤拷 %d/%d 锟斤拷锟斤拷位" % [used_slots, ATTACK_SLOT_COUNT]


func _on_random_pressed() -> void:
	if _character_paths.is_empty():
		return

	character_option.select(randi() % _character_paths.size())
	weapon_option.select(randi() % _weapon_paths.size())
	left_weapon_option.select(randi() % _weapon_paths.size())
	hair_color_option.select(randi() % HAIR_COLOR_PRESETS.size())
	skin_color_option.select(randi() % SKIN_COLOR_PRESETS.size())
	cloth_color_option.select(randi() % CLOTH_COLOR_PRESETS.size())
	hat_color_option.select(randi() % HAT_COLOR_PRESETS.size())
	scale_slider.value = snapped(randf_range(0.85, 1.25), 0.05)
	_apply_selection()


func _on_reset_camera_pressed() -> void:
	_reset_camera()


func _reset_camera() -> void:
	_yaw = deg_to_rad(30.0)
	_pitch = deg_to_rad(14.0)
	_distance = 5.8
	_update_camera()


func _update_camera() -> void:
	var focus := MODEL_FOCUS_POINT
	var horizontal_distance := _distance * cos(_pitch)
	var camera_offset := Vector3(
		horizontal_distance * sin(_yaw),
		_distance * sin(_pitch),
		horizontal_distance * cos(_yaw)
	)
	var camera_pos := focus + camera_offset
	camera_3d.global_position = camera_pos

	var viewport_size := get_viewport().get_visible_rect().size
	var ui_ratio := 0.0
	if viewport_size.x > 1.0:
		ui_ratio = clampf(ui_panel.size.x / viewport_size.x, 0.0, 0.85)

	var look_target := focus
	if ui_ratio > 0.01:
		var forward_to_model := (focus - camera_pos).normalized()
		var right := forward_to_model.cross(Vector3.UP).normalized()
		if right.length_squared() < 0.0001:
			right = Vector3.RIGHT
		var aspect := viewport_size.x / maxf(1.0, viewport_size.y)
		var vertical_fov := deg_to_rad(camera_3d.fov)
		var horizontal_fov := 2.0 * atan(tan(vertical_fov * 0.5) * aspect)
		var target_ndc_x := ui_ratio
		var horizontal_angle := atan(target_ndc_x * tan(horizontal_fov * 0.5))
		var distance_to_focus := (focus - camera_pos).length()
		var lateral_offset := tan(horizontal_angle) * distance_to_focus
		look_target = focus - right * lateral_offset

	camera_3d.look_at(look_target, Vector3.UP)


func _set_weapon_tune_enabled(right_enabled: bool, left_enabled: bool) -> void:
	weapon_pos_x_slider.editable = right_enabled
	weapon_pos_y_slider.editable = right_enabled
	weapon_pos_z_slider.editable = right_enabled
	weapon_rot_x_slider.editable = right_enabled
	weapon_rot_y_slider.editable = right_enabled
	weapon_rot_z_slider.editable = right_enabled
	weapon_tune_reset_button.disabled = not right_enabled
	left_weapon_pos_x_slider.editable = left_enabled
	left_weapon_pos_y_slider.editable = left_enabled
	left_weapon_pos_z_slider.editable = left_enabled
	left_weapon_rot_x_slider.editable = left_enabled
	left_weapon_rot_y_slider.editable = left_enabled
	left_weapon_rot_z_slider.editable = left_enabled
	left_weapon_tune_reset_button.disabled = not left_enabled


func _reset_weapon_tune_controls(update_note: bool) -> void:
	_is_syncing_weapon_tune_controls = true
	weapon_pos_x_slider.value = 0.0
	weapon_pos_y_slider.value = 0.0
	weapon_pos_z_slider.value = 0.0
	weapon_rot_x_slider.value = 0.0
	weapon_rot_y_slider.value = 0.0
	weapon_rot_z_slider.value = 0.0
	_is_syncing_weapon_tune_controls = false
	_weapon_offset_position = Vector3.ZERO
	_weapon_offset_rotation_degrees = Vector3.ZERO
	_refresh_weapon_tune_note()
	if update_note:
		return


func _reset_left_weapon_tune_controls(update_note: bool) -> void:
	_is_syncing_weapon_tune_controls = true
	left_weapon_pos_x_slider.value = 0.0
	left_weapon_pos_y_slider.value = 0.0
	left_weapon_pos_z_slider.value = 0.0
	left_weapon_rot_x_slider.value = 0.0
	left_weapon_rot_y_slider.value = 0.0
	left_weapon_rot_z_slider.value = 0.0
	_is_syncing_weapon_tune_controls = false
	_left_weapon_offset_position = Vector3.ZERO
	_left_weapon_offset_rotation_degrees = Vector3.ZERO
	_refresh_weapon_tune_note()
	if update_note:
		return


func _capture_weapon_base_transform() -> void:
	if _current_weapon_instance == null:
		_weapon_base_position = Vector3.ZERO
		_weapon_base_rotation_degrees = Vector3.ZERO
		return
	_weapon_base_position = _current_weapon_instance.position
	_weapon_base_rotation_degrees = _current_weapon_instance.rotation_degrees


func _capture_left_weapon_base_transform() -> void:
	if _current_left_weapon_instance == null:
		_left_weapon_base_position = Vector3.ZERO
		_left_weapon_base_rotation_degrees = Vector3.ZERO
		return
	_left_weapon_base_position = _current_left_weapon_instance.position
	_left_weapon_base_rotation_degrees = _current_left_weapon_instance.rotation_degrees


func _apply_weapon_tune_to_current_weapon() -> void:
	if _current_weapon_instance == null:
		_refresh_weapon_tune_note()
		return
	_current_weapon_instance.position = _weapon_base_position + _weapon_offset_position
	_current_weapon_instance.rotation_degrees = _weapon_base_rotation_degrees + _weapon_offset_rotation_degrees
	_refresh_weapon_tune_note()


func _apply_left_weapon_tune_to_current_weapon() -> void:
	if _current_left_weapon_instance == null:
		_refresh_weapon_tune_note()
		return
	_current_left_weapon_instance.position = _left_weapon_base_position + _left_weapon_offset_position
	_current_left_weapon_instance.rotation_degrees = _left_weapon_base_rotation_degrees + _left_weapon_offset_rotation_degrees
	_refresh_weapon_tune_note()


func _refresh_weapon_tune_note() -> void:
	_weapon_tune_note = "锟斤拷锟斤拷微锟斤拷锟斤拷锟斤拷锟斤拷位锟斤拷(%.3f, %.3f, %.3f) 锟斤拷转(%.1f, %.1f, %.1f)锟斤拷锟斤拷锟斤拷位锟斤拷(%.3f, %.3f, %.3f) 锟斤拷转(%.1f, %.1f, %.1f)" % [
		_weapon_offset_position.x,
		_weapon_offset_position.y,
		_weapon_offset_position.z,
		_weapon_offset_rotation_degrees.x,
		_weapon_offset_rotation_degrees.y,
		_weapon_offset_rotation_degrees.z,
		_left_weapon_offset_position.x,
		_left_weapon_offset_position.y,
		_left_weapon_offset_position.z,
		_left_weapon_offset_rotation_degrees.x,
		_left_weapon_offset_rotation_degrees.y,
		_left_weapon_offset_rotation_degrees.z,
	]


func _apply_selection() -> void:
	_attach_note = ""
	_animation_note = ""
	_animation_source_note = ""
	_style_color_note = ""
	_weapon_tune_note = ""
	_generate_note = ""
	preview_pivot.rotation = Vector3.ZERO
	_clear_preview()

	var selected_character := character_option.selected
	if selected_character < 0 or selected_character >= _character_paths.size():
		_refresh_attack_hit_bone_options()
		_update_attack_frame_preview_label_clean()
		info_label.text = "No character selected."
		return

	var character_scene := load(_character_paths[selected_character]) as PackedScene
	if character_scene == null:
		info_label.text = "锟斤拷色锟斤拷锟斤拷锟斤拷锟斤拷失锟杰★拷"
		return

	var character_node := character_scene.instantiate()
	if character_node is not Node3D:
		info_label.text = "锟斤拷色锟斤拷锟节点不锟斤拷 Node3D锟斤拷"
		return

	_character_instance = character_node as Node3D
	spawn_root.add_child(_character_instance)
	_character_instance.scale = Vector3.ONE * scale_slider.value

	_apply_weapon_if_selected()
	_apply_style_colors()
	_setup_preview_animations()
	_refresh_attack_hit_bone_options()
	_update_attack_frame_preview_label_clean()
	_update_info()


func _clear_preview() -> void:
	_preview_animation_player = null
	_current_weapon_instance = null
	_current_weapon_path = ""
	_current_left_weapon_instance = null
	_current_left_weapon_path = ""
	_character_instance = null
	for child in spawn_root.get_children():
		spawn_root.remove_child(child)
		child.queue_free()
	_update_attack_frame_preview_label_clean()


func _apply_weapon_if_selected() -> void:
	if _character_instance == null:
		_current_weapon_instance = null
		_current_left_weapon_instance = null
		_set_weapon_tune_enabled(false, false)
		return

	var right_weapon_path := _selected_weapon_path(weapon_option)
	var left_weapon_path := _selected_weapon_path(left_weapon_option)
	if right_weapon_path != _current_weapon_path:
		_reset_weapon_tune_controls(true)
	if left_weapon_path != _current_left_weapon_path:
		_reset_left_weapon_tune_controls(true)
	var skeleton := _find_first_skeleton(_character_instance)
	_current_weapon_path = right_weapon_path
	_current_left_weapon_path = left_weapon_path

	var right_result := _attach_weapon_to_character(right_weapon_path, skeleton, false)
	var left_result := _attach_weapon_to_character(left_weapon_path, skeleton, true)
	var right_instance_variant: Variant = right_result.get("instance", null)
	var left_instance_variant: Variant = left_result.get("instance", null)
	_current_weapon_instance = right_instance_variant as Node3D
	_current_left_weapon_instance = left_instance_variant as Node3D

	_set_weapon_tune_enabled(_current_weapon_instance != null, _current_left_weapon_instance != null)
	if _current_weapon_instance != null:
		_capture_weapon_base_transform()
		_apply_weapon_tune_to_current_weapon()
	if _current_left_weapon_instance != null:
		_capture_left_weapon_base_transform()
		_apply_left_weapon_tune_to_current_weapon()

	var right_note := str(right_result.get("note", ""))
	var left_note := str(left_result.get("note", ""))
	if right_note.is_empty():
		right_note = "锟斤拷锟街ｏ拷锟斤拷"
	if left_note.is_empty():
		left_note = "锟斤拷锟街ｏ拷锟斤拷"
	_attach_note = "%s锟斤拷%s" % [right_note, left_note]


func _selected_weapon_path(option: OptionButton) -> String:
	if option.selected <= 0:
		return ""
	if option.selected >= _weapon_paths.size():
		return ""
	return _weapon_paths[option.selected]


func _attach_weapon_to_character(weapon_path: String, skeleton: Skeleton3D, prefer_left_hand: bool) -> Dictionary:
	var empty_result := {"instance": null, "note": ""}
	var preferred_side_label := "左手" if prefer_left_hand else "右手"
	if weapon_path.is_empty():
		return empty_result

	var weapon_scene := load(weapon_path) as PackedScene
	if weapon_scene == null:
		return {"instance": null, "note": "%s武器资源加载失败" % preferred_side_label}

	var weapon_node := weapon_scene.instantiate()
	if weapon_node is not Node3D:
		return {"instance": null, "note": "%s武器实例节点不是 Node3D" % preferred_side_label}
	var weapon := weapon_node as Node3D

	if skeleton == null:
		_character_instance.add_child(weapon)
		weapon.position = Vector3(0.35, 1.1, 0.0)
		weapon.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		return {"instance": weapon, "note": "%s武器已挂到角色节点（未检测到骨骼）" % preferred_side_label}

	var primary_bone := _find_left_hand_bone(skeleton) if prefer_left_hand else _find_right_hand_bone(skeleton)
	var fallback_bone := _find_right_hand_bone(skeleton) if prefer_left_hand else _find_left_hand_bone(skeleton)
	var hand_bone_name := primary_bone
	var used_fallback := false
	if hand_bone_name.is_empty() and not fallback_bone.is_empty():
		hand_bone_name = fallback_bone
		used_fallback = true

	if hand_bone_name.is_empty():
		_character_instance.add_child(weapon)
		weapon.position = Vector3(0.35, 1.1, 0.0)
		weapon.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		return {"instance": weapon, "note": "%s武器已挂到角色节点（未检测到手部骨骼）" % preferred_side_label}

	var socket := BoneAttachment3D.new()
	socket.name = "WeaponSocket_L" if prefer_left_hand else "WeaponSocket_R"
	socket.bone_name = hand_bone_name
	skeleton.add_child(socket)
	socket.add_child(weapon)
	_apply_weapon_socket_transform(weapon, weapon_path, hand_bone_name)

	var actual_side_label := _hand_side_label_from_bone(hand_bone_name)
	var fallback_note := ""
	if used_fallback:
		fallback_note = "（未找到%s，已回退到%s）" % [preferred_side_label, actual_side_label]
	return {
		"instance": weapon,
		"note": "%s绑定骨骼：%s%s" % [preferred_side_label, hand_bone_name, fallback_note],
	}


func _hand_side_label_from_bone(hand_bone_name: String) -> String:
	var normalized := _normalize_bone_name(hand_bone_name)
	if normalized.contains("left") or normalized.contains("handl") or normalized.contains("handslotl") or normalized.contains("lhand"):
		return "左手"
	if normalized.contains("right") or normalized.contains("handr") or normalized.contains("handslotr") or normalized.contains("rhand"):
		return "右手"
	return "未知手"


func _apply_weapon_socket_transform(weapon: Node3D, weapon_path: String, hand_bone_name: String) -> void:
	var lower_path := weapon_path.to_lower()
	var handslot_mode := hand_bone_name.to_lower().contains("handslot")

	weapon.scale = Vector3.ONE
	if handslot_mode:
		# For KayKit hand slots, identity transform is usually the intended orientation.
		weapon.position = Vector3.ZERO
		weapon.rotation_degrees = Vector3.ZERO
	else:
		weapon.position = Vector3(0.02, 0.02, 0.0)
		weapon.rotation_degrees = Vector3(-90.0, 0.0, 90.0)

	# Small per-category tweaks to reduce obvious clipping/inside-body issues.
	if lower_path.contains("shield"):
		weapon.position += Vector3(0.01, 0.0, -0.02)
	elif lower_path.contains("staff") or lower_path.contains("bow") or lower_path.contains("crossbow"):
		weapon.position += Vector3(0.0, -0.01, 0.02)
	elif lower_path.contains("sword") or lower_path.contains("dagger") or lower_path.contains("axe"):
		weapon.position += Vector3(0.0, 0.0, 0.01)


func _setup_preview_animations() -> void:
	if _character_instance == null:
		_populate_animation_options([])
		_animation_note = "没锟叫斤拷色实锟斤拷锟斤拷锟睫凤拷锟斤拷锟脚讹拷锟斤拷"
		_animation_source_note = ""
		return

	_preview_animation_player = AnimationPlayer.new()
	_preview_animation_player.name = "PreviewAnimationPlayer"
	_preview_animation_player.speed_scale = speed_slider.value
	_character_instance.add_child(_preview_animation_player)

	var animation_library := AnimationLibrary.new()
	var loaded_names: Array[String] = []
	var local_animation_count := 0
	var selected_character_path := _selected_character_path()
	var selected_pack := _find_pack_by_resource_path(selected_character_path)
	var selected_pack_id := str(selected_pack.get("id", ""))
	var is_newmodel_character := selected_pack_id == "newmodel"

	# Prefer character-embedded animations first. If names overlap,
	# external Rig_Medium library entries are skipped, keeping custom
	# model-specific retargeted clips.
	for local_player_node in _find_animation_players(_character_instance):
		var local_player := local_player_node as AnimationPlayer
		for animation_name in local_player.get_animation_list():
			if animation_library.has_animation(animation_name):
				continue
			var source_animation := local_player.get_animation(animation_name)
			if source_animation == null:
				continue
			var copied := source_animation.duplicate(true) as Animation
			animation_library.add_animation(animation_name, copied)
			loaded_names.append(animation_name)
			local_animation_count += 1

	if not is_newmodel_character:
		for scene_path in _animation_scene_paths:
			var names := _merge_animations_from_scene(scene_path, animation_library)
			for merged_anim_name in names:
				if not loaded_names.has(merged_anim_name):
					loaded_names.append(merged_anim_name)

	if loaded_names.is_empty():
		_animation_note = "锟斤拷前锟斤拷色模锟酵诧拷锟斤拷锟斤拷锟斤拷锟斤拷锟斤拷未锟揭碉拷锟缴合诧拷锟侥讹拷锟斤拷锟斤拷"
		_animation_source_note = ""
		_populate_animation_options([])
		return

	loaded_names.sort()
	_preview_animation_player.add_animation_library("", animation_library)
	_populate_animation_options(loaded_names)
	_update_selected_animation_loop_mode()
	_play_selected_animation()

	var source_label := "锟斤拷锟斤拷锟斤拷源锟斤拷全锟斤拷锟斤拷源锟斤拷"
	if is_newmodel_character:
		source_label = "Custom model local animations only"
	elif extra_animation_toggle.button_pressed and _dir_exists(SHARED_MEDIUM_ANIMATIONS_DIR):
		source_label = "锟斤拷锟斤拷锟斤拷源锟斤拷全锟斤拷锟斤拷源锟斤拷 + Character_Animations_1.1"
	if local_animation_count > 0:
		source_label = "角色内置动作优先 + %s" % source_label
	_animation_source_note = "%s锟斤拷锟斤拷 %d 锟斤拷锟斤拷 (内置 %d)" % [source_label, loaded_names.size(), local_animation_count]


func _merge_animations_from_scene(scene_path: String, target_library: AnimationLibrary) -> Array[String]:
	var added: Array[String] = []
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return added

	var instance := scene.instantiate()
	if instance == null:
		return added

	var players := _find_animation_players(instance)
	for player in players:
		var source_player := player as AnimationPlayer
		for animation_name in source_player.get_animation_list():
			if target_library.has_animation(animation_name):
				continue

			var source_animation := source_player.get_animation(animation_name)
			if source_animation == null:
				continue

			var copied := source_animation.duplicate(true) as Animation
			target_library.add_animation(animation_name, copied)
			added.append(animation_name)

	instance.queue_free()
	return added


func _find_animation_players(root: Node) -> Array:
	var players: Array = []
	if root is AnimationPlayer:
		players.append(root)

	for child in root.get_children():
		players.append_array(_find_animation_players(child))

	return players


func _rebuild_animation_scene_paths() -> void:
	_animation_scene_paths.clear()
	for pack in PACKS:
		if not _is_valid_pack(pack):
			continue
		_append_unique_paths(_animation_scene_paths, _collect_scene_files(pack.get("animations_dir", "")))
	_animation_scene_paths.sort()
	if extra_animation_toggle.button_pressed and _dir_exists(SHARED_MEDIUM_ANIMATIONS_DIR):
		var shared_paths := _collect_scene_files(SHARED_MEDIUM_ANIMATIONS_DIR)
		for path in shared_paths:
			if not _animation_scene_paths.has(path):
				_animation_scene_paths.append(path)


func _build_animation_display_name(raw_name: String) -> String:
	var english_label := raw_name.replace("_", " ").replace("-", " ").strip_edges()
	if english_label.is_empty():
		english_label = raw_name
	var translated := _clean_ui_text(_translate_animation_name(raw_name), "")
	if translated.is_empty():
		return english_label
	if translated.to_lower() == english_label.to_lower():
		return english_label
	return "%s | %s" % [translated, english_label]
func _translate_animation_name(raw_name: String) -> String:
	var tokens := _split_identifier_tokens(raw_name)
	if tokens.is_empty():
		return raw_name
	var zh_parts: Array[String] = []
	var token_map := _animation_token_map()
	for token in tokens:
		var normalized := token.to_lower()
		if normalized.is_empty():
			continue
		zh_parts.append(str(token_map.get(normalized, token)))
	return " ".join(zh_parts).strip_edges()
func _apply_style_colors() -> void:
	if _character_instance == null:
		return

	var hair_preset := _get_selected_preset(hair_color_option, HAIR_COLOR_PRESETS)
	var skin_preset := _get_selected_preset(skin_color_option, SKIN_COLOR_PRESETS)
	var cloth_preset := _get_selected_preset(cloth_color_option, CLOTH_COLOR_PRESETS)
	var hat_preset := _get_selected_preset(hat_color_option, HAT_COLOR_PRESETS)

	var hair_key := str(hair_preset.get("key", "default"))
	var skin_key := str(skin_preset.get("key", "default"))
	var cloth_key := str(cloth_preset.get("key", "default"))
	var hat_key := str(hat_preset.get("key", "default"))

	var hair_color := _preset_color(hair_preset)
	var skin_color := _preset_color(skin_preset)
	var cloth_color := _preset_color(cloth_preset)
	var hat_color := _preset_color(hat_preset)
	var character_path_lower := _selected_character_path().to_lower()
	var is_skeleton_character := character_path_lower.contains("kaykit_skeletons") or character_path_lower.contains("skeleton_")

	var recolored_surface_count := 0
	for mesh_instance in _collect_mesh_instances(_character_instance):
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue

		var mesh_name := String(mesh_instance.name)
		var tint_color := Color(1.0, 1.0, 1.0, 1.0)
		var use_tint := false

		if _is_eye_mesh_name(mesh_name):
			use_tint = false
		elif is_skeleton_character and _is_skeleton_bone_mesh_name(mesh_name) and skin_key != "default":
			tint_color = skin_color
			use_tint = true
		elif _is_hat_mesh_name(mesh_name) and hat_key != "default":
			tint_color = hat_color
			use_tint = true
		elif _is_hair_mesh_name(mesh_name) and hair_key != "default":
			tint_color = hair_color
			use_tint = true
		elif _is_skin_mesh_name(mesh_name) and skin_key != "default":
			tint_color = skin_color
			use_tint = true
		elif _is_cloth_mesh_name(mesh_name) and cloth_key != "default":
			# For skeleton characters, bone meshes should follow skin tint instead of cloth tint.
			if not (is_skeleton_character and _is_skeleton_bone_mesh_name(mesh_name)):
				tint_color = cloth_color
				use_tint = true

		for i in range(mesh.get_surface_count()):
			if not use_tint:
				mesh_instance.set_surface_override_material(i, null)
				continue

			var base_material := mesh.surface_get_material(i)
			if base_material == null:
				base_material = mesh_instance.get_active_material(i)
			var tinted_material := _create_tinted_material(base_material, tint_color)
			mesh_instance.set_surface_override_material(i, tinted_material)
			recolored_surface_count += 1

	var skeleton_rule_note := ""
	if is_skeleton_character:
		skeleton_rule_note = "锟斤拷锟斤拷锟矫癸拷锟斤拷锟斤拷锟斤拷皮锟斤拷色"
	_style_color_note = "锟斤拷郏锟酵凤拷锟絒%s] 皮锟斤拷[%s] 锟铰凤拷[%s] 帽锟斤拷[%s]锟斤拷锟窖革拷锟斤拷 %d 锟斤拷锟斤拷%s锟斤拷" % [
		str(hair_preset.get("label", "原始锟斤拷锟斤拷")),
		str(skin_preset.get("label", "原始锟斤拷锟斤拷")),
		str(cloth_preset.get("label", "原始锟斤拷锟斤拷")),
		str(hat_preset.get("label", "原始锟斤拷锟斤拷")),
		recolored_surface_count,
		skeleton_rule_note,
	]


func _selected_character_path() -> String:
	if character_option.selected >= 0 and character_option.selected < _character_paths.size():
		return _character_paths[character_option.selected]
	return ""


func _get_selected_preset(option: OptionButton, presets: Array[Dictionary]) -> Dictionary:
	if presets.is_empty():
		return {}
	var index := clampi(option.selected, 0, presets.size() - 1)
	return presets[index]


func _preset_color(preset: Dictionary) -> Color:
	var color := Color(1.0, 1.0, 1.0, 1.0)
	var value: Variant = preset.get("color", color)
	if value is Color:
		color = value
	return color


func _collect_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		result.append(root as MeshInstance3D)

	for child in root.get_children():
		result.append_array(_collect_mesh_instances(child))

	return result


func _is_hat_mesh_name(mesh_name: String) -> bool:
	return _mesh_name_contains_hints(mesh_name, HAT_NODE_HINTS)


func _is_hair_mesh_name(mesh_name: String) -> bool:
	return _mesh_name_contains_hints(mesh_name, HAIR_NODE_HINTS)


func _is_skin_mesh_name(mesh_name: String) -> bool:
	return _mesh_name_contains_hints(mesh_name, SKIN_NODE_HINTS)


func _is_cloth_mesh_name(mesh_name: String) -> bool:
	return _mesh_name_contains_hints(mesh_name, CLOTH_NODE_HINTS)


func _is_eye_mesh_name(mesh_name: String) -> bool:
	return _mesh_name_contains_hints(mesh_name, EYE_NODE_HINTS)


func _is_skeleton_bone_mesh_name(mesh_name: String) -> bool:
	return _mesh_name_contains_hints(mesh_name, SKELETON_BONE_NODE_HINTS)


func _mesh_name_contains_hints(mesh_name: String, hints: Array) -> bool:
	var normalized := mesh_name.to_lower()
	for hint in hints:
		if normalized.contains(str(hint)):
			return true
	return false


func _create_tinted_material(base_material: Material, tint_color: Color) -> Material:
	if base_material == null:
		var material := StandardMaterial3D.new()
		material.albedo_color = tint_color
		return material

	if base_material is BaseMaterial3D:
		var copied := (base_material as BaseMaterial3D).duplicate(true) as BaseMaterial3D
		copied.albedo_color = tint_color
		return copied

	return base_material


func _save_current_profile(profile_id: String, profile_name: String) -> String:
	var root_abs := ProjectSettings.globalize_path(GENERATED_CONFIG_ROOT)
	var profile_abs := "%s/%s" % [root_abs, profile_id]

	var mkdir_error := DirAccess.make_dir_recursive_absolute(profile_abs)
	if mkdir_error != OK:
		push_warning("Create directory failed: %s" % profile_abs)
		return ""

	var profile_data := _build_profile_data(profile_id, profile_name)
	var json_path_abs := "%s/monster_profile.json" % profile_abs
	var json_path_res := "%s/%s/monster_profile.json" % [GENERATED_CONFIG_ROOT, profile_id]
	if not _write_json_file(json_path_abs, profile_data):
		return ""

	_update_profile_index(profile_id, profile_data)
	return json_path_res


func _build_profile_data(profile_id: String, profile_name: String) -> Dictionary:
	var character_path := ""
	if character_option.selected >= 0 and character_option.selected < _character_paths.size():
		character_path = _character_paths[character_option.selected]

	var right_weapon_path := ""
	if weapon_option.selected > 0 and weapon_option.selected < _weapon_paths.size():
		right_weapon_path = _weapon_paths[weapon_option.selected]
	var left_weapon_path := ""
	if left_weapon_option.selected > 0 and left_weapon_option.selected < _weapon_paths.size():
		left_weapon_path = _weapon_paths[left_weapon_option.selected]

	var animation_name := ""
	var animation_label := ""
	if animation_option.selected >= 0 and animation_option.selected < _animation_names.size():
		animation_name = _animation_names[animation_option.selected]
	if animation_option.selected >= 0 and animation_option.selected < _animation_display_names.size():
		animation_label = _animation_display_names[animation_option.selected]

	var hat_preset: Dictionary = HAT_COLOR_PRESETS[clampi(hat_color_option.selected, 0, HAT_COLOR_PRESETS.size() - 1)]
	var hair_preset: Dictionary = HAIR_COLOR_PRESETS[clampi(hair_color_option.selected, 0, HAIR_COLOR_PRESETS.size() - 1)]
	var skin_preset: Dictionary = SKIN_COLOR_PRESETS[clampi(skin_color_option.selected, 0, SKIN_COLOR_PRESETS.size() - 1)]
	var cloth_preset: Dictionary = CLOTH_COLOR_PRESETS[clampi(cloth_color_option.selected, 0, CLOTH_COLOR_PRESETS.size() - 1)]
	var hat_color := Color(1.0, 1.0, 1.0, 1.0)
	var hair_color := Color(1.0, 1.0, 1.0, 1.0)
	var skin_color := Color(1.0, 1.0, 1.0, 1.0)
	var cloth_color := Color(1.0, 1.0, 1.0, 1.0)
	var color_variant: Variant = hat_preset.get("color", hat_color)
	if color_variant is Color:
		hat_color = color_variant
	color_variant = hair_preset.get("color", hair_color)
	if color_variant is Color:
		hair_color = color_variant
	color_variant = skin_preset.get("color", skin_color)
	if color_variant is Color:
		skin_color = color_variant
	color_variant = cloth_preset.get("color", cloth_color)
	if color_variant is Color:
		cloth_color = color_variant

	var source_pack := _find_pack_by_resource_path(character_path)
	var data := {
		"profile_id": profile_id,
		"profile_name": profile_name,
		"profile_display_name": _compose_profile_display_name(profile_id, profile_name),
		"pack_id": str(source_pack.get("id", UNIFIED_PACK_ID)),
		"pack_label": str(source_pack.get("label", UNIFIED_PACK_LABEL)),
		"character_path": character_path,
		"character_name": _display_character_name_from_path(character_path) if not character_path.is_empty() else "",
		"weapon_path": right_weapon_path,
		"weapon_name": _display_weapon_name_from_path(right_weapon_path) if not right_weapon_path.is_empty() else "",
		"right_weapon_path": right_weapon_path,
		"right_weapon_name": _display_weapon_name_from_path(right_weapon_path) if not right_weapon_path.is_empty() else "",
		"left_weapon_path": left_weapon_path,
		"left_weapon_name": _display_weapon_name_from_path(left_weapon_path) if not left_weapon_path.is_empty() else "",
		"animation_name": animation_name,
		"animation_label": animation_label,
		"use_extra_animation_pack": extra_animation_toggle.button_pressed,
		"loop": loop_toggle.button_pressed,
		"speed": speed_slider.value,
		"scale": scale_slider.value,
		"weapon_tune_pos_x": _weapon_offset_position.x,
		"weapon_tune_pos_y": _weapon_offset_position.y,
		"weapon_tune_pos_z": _weapon_offset_position.z,
		"weapon_tune_rot_x": _weapon_offset_rotation_degrees.x,
		"weapon_tune_rot_y": _weapon_offset_rotation_degrees.y,
		"weapon_tune_rot_z": _weapon_offset_rotation_degrees.z,
		"left_weapon_tune_pos_x": _left_weapon_offset_position.x,
		"left_weapon_tune_pos_y": _left_weapon_offset_position.y,
		"left_weapon_tune_pos_z": _left_weapon_offset_position.z,
		"left_weapon_tune_rot_x": _left_weapon_offset_rotation_degrees.x,
		"left_weapon_tune_rot_y": _left_weapon_offset_rotation_degrees.y,
		"left_weapon_tune_rot_z": _left_weapon_offset_rotation_degrees.z,
		"attack_plan": _build_attack_plan_payload(),
		"hair_preset_key": str(hair_preset.get("key", "default")),
		"hair_preset_label": str(hair_preset.get("label", "原始锟斤拷锟斤拷")),
		"hair_tint_html": hair_color.to_html(true),
		"skin_preset_key": str(skin_preset.get("key", "default")),
		"skin_preset_label": str(skin_preset.get("label", "原始锟斤拷锟斤拷")),
		"skin_tint_html": skin_color.to_html(true),
		"cloth_preset_key": str(cloth_preset.get("key", "default")),
		"cloth_preset_label": str(cloth_preset.get("label", "原始锟斤拷锟斤拷")),
		"cloth_tint_html": cloth_color.to_html(true),
		"hat_preset_key": str(hat_preset.get("key", "default")),
		"hat_preset_label": str(hat_preset.get("label", "原始锟斤拷锟斤拷")),
		"hat_tint_html": hat_color.to_html(true),
		"generated_at_local": Time.get_datetime_string_from_system(),
	}
	return data


func _write_json_file(abs_path: String, payload: Dictionary) -> bool:
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		push_warning("Open file failed: %s" % abs_path)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true


func _update_profile_index(profile_id: String, payload: Dictionary) -> void:
	var root_abs := ProjectSettings.globalize_path(GENERATED_CONFIG_ROOT)
	var index_abs := "%s/index.json" % root_abs

	var index_data: Dictionary = {}
	if FileAccess.file_exists(index_abs):
		var read_file := FileAccess.open(index_abs, FileAccess.READ)
		if read_file != null:
			var parsed: Variant = JSON.parse_string(read_file.get_as_text())
			if parsed is Dictionary:
				index_data = parsed

	index_data[profile_id] = payload

	var write_file := FileAccess.open(index_abs, FileAccess.WRITE)
	if write_file == null:
		return
	write_file.store_string(JSON.stringify(index_data, "\t"))


func _parse_profile_id_and_name(raw_id_input: String, raw_name_input: String) -> Dictionary:
	var profile_id := raw_id_input.strip_edges()
	var profile_name := raw_name_input.strip_edges()
	if not profile_name.is_empty():
		return {"id": profile_id, "name": profile_name}
	var split_result := _split_profile_id_name_with_fallback_separators(profile_id)
	if not split_result.is_empty():
		return split_result
	var ascii_split := _split_profile_id_name_ascii(profile_id)
	if not ascii_split.is_empty():
		return ascii_split
	# Keep legacy separators fallback below for backward compatibility.

	for separator in ["-", "锟斤拷", "锟斤拷", "_"]:
		var sep_index := profile_id.find(separator)
		if sep_index <= 0:
			continue
		var left := profile_id.substr(0, sep_index).strip_edges()
		var right := profile_id.substr(sep_index + separator.length()).strip_edges()
		if _is_all_digits(left) and not right.is_empty():
			return {"id": left, "name": right}

	return {"id": profile_id, "name": profile_name}


func _split_profile_id_name_with_fallback_separators(profile_id: String) -> Dictionary:
	for separator in ["-", "_", "锟斤拷", "锟斤拷", ":", "锟斤拷"]:
		var sep_index := profile_id.find(separator)
		if sep_index <= 0:
			continue
		var left := profile_id.substr(0, sep_index).strip_edges()
		var right := profile_id.substr(sep_index + separator.length()).strip_edges()
		if _is_all_digits(left) and not right.is_empty():
			return {"id": left, "name": right}
	return {}


func _split_profile_id_name_ascii(profile_id: String) -> Dictionary:
	for separator in ["-", "_", ":", "|", "/"]:
		var sep_index := profile_id.find(separator)
		if sep_index <= 0:
			continue
		var left := profile_id.substr(0, sep_index).strip_edges()
		var right := profile_id.substr(sep_index + separator.length()).strip_edges()
		if _is_all_digits(left) and not right.is_empty():
			return {"id": left, "name": right}
	return {}


func _sanitize_profile_name(raw_name: String) -> String:
	var normalized := raw_name.replace("\n", " ").replace("\r", " ").strip_edges()
	return _clean_ui_text(normalized, "")
func _compose_profile_display_name(profile_id: String, profile_name: String) -> String:
	var id_text := _display_profile_id_text(profile_id)
	if id_text.is_empty():
		id_text = "unknown"
	var clean_name := _sanitize_profile_name(profile_name)
	if clean_name.is_empty() or not _is_safe_profile_display_name(clean_name):
		return id_text
	return "%s-%s" % [id_text, clean_name]


func _is_safe_profile_display_name(text: String) -> bool:
	var has_visible_ascii := false
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code >= 48 and code <= 57:
			has_visible_ascii = true
			continue
		if code >= 65 and code <= 90:
			has_visible_ascii = true
			continue
		if code >= 97 and code <= 122:
			has_visible_ascii = true
			continue
		if code == 32 or code == 95 or code == 45 or code == 47:
			continue
		return false
	return has_visible_ascii


func _display_profile_id_text(raw_id: String) -> String:
	var trimmed := raw_id.strip_edges()
	if trimmed.is_empty():
		return ""
	var ascii_only := _clean_ui_text(trimmed, "")
	if _is_all_digits(ascii_only):
		return ascii_only
	if _is_all_digits(trimmed):
		return trimmed
	var leading_digits := ""
	for i in range(trimmed.length()):
		var code := trimmed.unicode_at(i)
		if code >= 48 and code <= 57:
			leading_digits += trimmed.substr(i, 1)
			continue
		if not leading_digits.is_empty():
			break
	if not leading_digits.is_empty():
		return leading_digits
	return ascii_only
func _populate_saved_profile_options(select_profile_id: String = "") -> void:
	_generated_profile_cache.clear()
	saved_profile_option.clear()
	saved_profile_option.add_item("Select generated profile...")
	saved_profile_option.set_item_metadata(0, "")
	saved_profile_option.select(0)

	var root_abs := ProjectSettings.globalize_path(GENERATED_CONFIG_ROOT)
	var index_abs := "%s/index.json" % root_abs
	if not FileAccess.file_exists(index_abs):
		saved_profile_option.disabled = true
		load_saved_profile_button.disabled = true
		return

	var read_file := FileAccess.open(index_abs, FileAccess.READ)
	if read_file == null:
		saved_profile_option.disabled = true
		load_saved_profile_button.disabled = true
		return

	var parsed: Variant = JSON.parse_string(read_file.get_as_text())
	if parsed is not Dictionary:
		saved_profile_option.disabled = true
		load_saved_profile_button.disabled = true
		return

	var index_data := parsed as Dictionary
	var profile_ids: Array[String] = []
	for key in index_data.keys():
		profile_ids.append(str(key))
	profile_ids.sort_custom(func(a: String, b: String) -> bool:
		var a_digits := _is_all_digits(a)
		var b_digits := _is_all_digits(b)
		if a_digits and b_digits:
			return int(a) < int(b)
		if a_digits:
			return true
		if b_digits:
			return false
		return a.to_lower() < b.to_lower()
	)

	for profile_id in profile_ids:
		var payload: Dictionary = {}
		var payload_variant: Variant = index_data.get(profile_id, {})
		if payload_variant is Dictionary:
			payload = payload_variant as Dictionary
		var display_name := _display_profile_id_text(profile_id)
		if display_name.is_empty():
			display_name = "profile"
		saved_profile_option.add_item(display_name)
		var item_index := saved_profile_option.item_count - 1
		saved_profile_option.set_item_metadata(item_index, profile_id)
		_generated_profile_cache[profile_id] = payload

	var select_index := 0
	var normalized_target := select_profile_id.strip_edges()
	if not normalized_target.is_empty():
		for i in range(1, saved_profile_option.item_count):
			if str(saved_profile_option.get_item_metadata(i)) == normalized_target:
				select_index = i
				break
	saved_profile_option.select(select_index)
	if select_index > 0:
		_on_saved_profile_selected(select_index)

	var has_profiles := saved_profile_option.item_count > 1
	saved_profile_option.disabled = not has_profiles
	load_saved_profile_button.disabled = not has_profiles
func _select_saved_profile_option_by_id(profile_id: String) -> void:
	for i in range(1, saved_profile_option.item_count):
		if str(saved_profile_option.get_item_metadata(i)) == profile_id:
			saved_profile_option.select(i)
			_on_saved_profile_selected(i)
			return


func _find_pack_index_by_id(pack_id: String) -> int:
	if pack_id == UNIFIED_PACK_ID:
		return 0
	for i in range(PACKS.size()):
		if str(PACKS[i].get("id", "")) == pack_id:
			return i
	return -1


func _find_preset_index_by_key(presets: Array[Dictionary], key: String) -> int:
	for i in range(presets.size()):
		if str(presets[i].get("key", "")) == key:
			return i
	return 0


func _find_character_index_by_name(character_name: String) -> int:
	var target := character_name.strip_edges().to_lower()
	if target.is_empty():
		return -1
	for i in range(_character_paths.size()):
		var display_name := _display_character_name_from_path(_character_paths[i]).to_lower()
		if display_name == target:
			return i
		var base_name := _character_paths[i].get_file().get_basename().replace("Skeleton_", "").replace("_", " ").to_lower()
		if base_name == target:
			return i
	return -1


func _load_weapon_tune_from_payload(payload: Dictionary) -> void:
	var pos_x := float(payload.get("weapon_tune_pos_x", 0.0))
	var pos_y := float(payload.get("weapon_tune_pos_y", 0.0))
	var pos_z := float(payload.get("weapon_tune_pos_z", 0.0))
	var rot_x := float(payload.get("weapon_tune_rot_x", 0.0))
	var rot_y := float(payload.get("weapon_tune_rot_y", 0.0))
	var rot_z := float(payload.get("weapon_tune_rot_z", 0.0))
	var left_pos_x := float(payload.get("left_weapon_tune_pos_x", 0.0))
	var left_pos_y := float(payload.get("left_weapon_tune_pos_y", 0.0))
	var left_pos_z := float(payload.get("left_weapon_tune_pos_z", 0.0))
	var left_rot_x := float(payload.get("left_weapon_tune_rot_x", 0.0))
	var left_rot_y := float(payload.get("left_weapon_tune_rot_y", 0.0))
	var left_rot_z := float(payload.get("left_weapon_tune_rot_z", 0.0))

	_is_syncing_weapon_tune_controls = true
	weapon_pos_x_slider.value = pos_x
	weapon_pos_y_slider.value = pos_y
	weapon_pos_z_slider.value = pos_z
	weapon_rot_x_slider.value = rot_x
	weapon_rot_y_slider.value = rot_y
	weapon_rot_z_slider.value = rot_z
	left_weapon_pos_x_slider.value = left_pos_x
	left_weapon_pos_y_slider.value = left_pos_y
	left_weapon_pos_z_slider.value = left_pos_z
	left_weapon_rot_x_slider.value = left_rot_x
	left_weapon_rot_y_slider.value = left_rot_y
	left_weapon_rot_z_slider.value = left_rot_z
	_is_syncing_weapon_tune_controls = false

	_weapon_offset_position = Vector3(pos_x, pos_y, pos_z)
	_weapon_offset_rotation_degrees = Vector3(rot_x, rot_y, rot_z)
	_left_weapon_offset_position = Vector3(left_pos_x, left_pos_y, left_pos_z)
	_left_weapon_offset_rotation_degrees = Vector3(left_rot_x, left_rot_y, left_rot_z)
	_apply_weapon_tune_to_current_weapon()
	_apply_left_weapon_tune_to_current_weapon()


func _load_profile_by_id(profile_id: String) -> void:
	var payload_variant: Variant = _generated_profile_cache.get(profile_id, {})
	if payload_variant is not Dictionary:
		_generate_note = "锟斤拷锟斤拷失锟杰ｏ拷未锟揭碉拷锟斤拷锟斤拷 %s" % profile_id
		_update_info()
		return
	var payload := payload_variant as Dictionary

	generate_id_input.text = _display_profile_id_text(profile_id)
	generate_name_input.text = _sanitize_profile_name(str(payload.get("profile_name", "")))

	pack_option.select(0)
	_on_pack_selected(0)

	extra_animation_toggle.set_pressed_no_signal(bool(payload.get("use_extra_animation_pack", extra_animation_toggle.button_pressed)))
	loop_toggle.set_pressed_no_signal(bool(payload.get("loop", loop_toggle.button_pressed)))
	speed_slider.set_value_no_signal(float(payload.get("speed", speed_slider.value)))
	speed_value_label.text = "%.2fx" % speed_slider.value
	scale_slider.set_value_no_signal(float(payload.get("scale", scale_slider.value)))

	var character_path := str(payload.get("character_path", ""))
	var character_index := _character_paths.find(character_path)
	if character_index < 0:
		character_index = _find_character_index_by_name(str(payload.get("character_name", "")))
	if character_index >= 0:
		character_option.select(character_index)

	var right_weapon_path := str(payload.get("right_weapon_path", payload.get("weapon_path", "")))
	var right_weapon_index := _weapon_paths.find(right_weapon_path)
	if right_weapon_index < 0:
		right_weapon_index = 0
	weapon_option.select(right_weapon_index)

	var left_weapon_path := str(payload.get("left_weapon_path", ""))
	var left_weapon_index := _weapon_paths.find(left_weapon_path)
	if left_weapon_index < 0:
		left_weapon_index = 0
	left_weapon_option.select(left_weapon_index)

	hair_color_option.select(_find_preset_index_by_key(HAIR_COLOR_PRESETS, str(payload.get("hair_preset_key", "default"))))
	skin_color_option.select(_find_preset_index_by_key(SKIN_COLOR_PRESETS, str(payload.get("skin_preset_key", "default"))))
	cloth_color_option.select(_find_preset_index_by_key(CLOTH_COLOR_PRESETS, str(payload.get("cloth_preset_key", "default"))))
	hat_color_option.select(_find_preset_index_by_key(HAT_COLOR_PRESETS, str(payload.get("hat_preset_key", "default"))))

	_apply_selection()

	var animation_name := str(payload.get("animation_name", ""))
	var animation_index := _animation_names.find(animation_name)
	if animation_index >= 0:
		animation_option.select(animation_index)
	_play_selected_animation()

	_load_weapon_tune_from_payload(payload)
	_load_attack_plan_from_payload(payload)
	_attack_edit_profile_id = profile_id
	_select_saved_profile_option_by_id(profile_id)
	_generate_note = "Loaded profile %s." % _compose_profile_display_name(profile_id, str(payload.get("profile_name", "")))
	_update_info()


func _is_all_digits(text: String) -> bool:
	if text.is_empty():
		return false
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code < 48 or code > 57:
			return false
	return true


func _suggest_next_profile_id(last_generated: String = "") -> String:
	if _is_all_digits(last_generated):
		return str(int(last_generated) + 1)

	var start_id := 1001
	var root_abs := ProjectSettings.globalize_path(GENERATED_CONFIG_ROOT)
	var root_dir := DirAccess.open(root_abs)
	if root_dir == null:
		return str(start_id)

	var directories := DirAccess.get_directories_at(GENERATED_CONFIG_ROOT)
	var max_id := start_id - 1
	for dir_name in directories:
		if not _is_all_digits(dir_name):
			continue
		max_id = maxi(max_id, int(dir_name))

	return str(maxi(start_id, max_id + 1))


func _play_selected_animation() -> void:
	if _preview_animation_player == null:
		_animation_note = "锟斤拷前锟斤拷色没锟叫讹拷锟斤拷锟斤拷锟斤拷锟斤拷"
		_update_info()
		return
	if _animation_names.is_empty():
		_animation_note = "锟斤拷前没锟叫可诧拷锟脚讹拷锟斤拷"
		_update_info()
		return
	if animation_option.selected < 0 or animation_option.selected >= _animation_names.size():
		return

	var animation_name := _animation_names[animation_option.selected]
	var animation_display_name := animation_name
	if animation_option.selected < _animation_display_names.size():
		animation_display_name = _animation_display_names[animation_option.selected]
	var concise_display_name := animation_display_name
	var divider := concise_display_name.find(" | ")
	if divider >= 0:
		concise_display_name = concise_display_name.substr(0, divider)
	_update_selected_animation_loop_mode()
	_preview_animation_player.play(animation_name)
	_apply_preview_pause_state()
	_animation_note = "锟斤拷前锟斤拷锟斤拷锟斤拷%s" % concise_display_name
	_update_attack_frame_preview_label_clean()
	_update_info()


func _apply_preview_pause_state() -> void:
	if _preview_animation_player != null:
		_preview_animation_player.speed_scale = 0.0 if _is_preview_paused else speed_slider.value
	_pause_note = "预锟斤拷锟斤拷锟斤拷停锟斤拷锟皆讹拷锟斤拷转 + 锟斤拷锟斤拷锟斤拷" if _is_preview_paused else ""


func _update_selected_animation_loop_mode() -> void:
	if _preview_animation_player == null:
		return
	if animation_option.selected < 0 or animation_option.selected >= _animation_names.size():
		return

	var animation_name := _animation_names[animation_option.selected]
	var animation := _preview_animation_player.get_animation(animation_name)
	if animation == null:
		return

	animation.loop_mode = Animation.LOOP_LINEAR if loop_toggle.button_pressed else Animation.LOOP_NONE


func _find_first_skeleton(root: Node) -> Skeleton3D:
	if root == null:
		return null
	if root is Skeleton3D:
		return root as Skeleton3D

	for child in root.get_children():
		var found := _find_first_skeleton(child)
		if found != null:
			return found

	return null


func _find_bone_by_hints(all_bones: Array[String], hints: Array) -> String:
	for hint in hints:
		var normalized_hint := _normalize_bone_name(str(hint))
		if normalized_hint.is_empty():
			continue
		for bone_name in all_bones:
			if _normalize_bone_name(bone_name) == normalized_hint:
				return bone_name

	for hint in hints:
		var normalized_hint := _normalize_bone_name(str(hint))
		if normalized_hint.is_empty():
			continue
		for bone_name in all_bones:
			if _normalize_bone_name(bone_name).contains(normalized_hint):
				return bone_name
	return ""


func _find_right_hand_bone(skeleton: Skeleton3D) -> String:
	var all_bones: Array[String] = []
	for i in range(skeleton.get_bone_count()):
		all_bones.append(skeleton.get_bone_name(i))

	var by_hint := _find_bone_by_hints(all_bones, HAND_BONE_HINTS)
	if not by_hint.is_empty():
		return by_hint

	for bone_name in all_bones:
		var normalized := _normalize_bone_name(bone_name)
		if normalized.contains("hand") and normalized.contains("r"):
			return bone_name

	return ""


func _find_left_hand_bone(skeleton: Skeleton3D) -> String:
	var all_bones: Array[String] = []
	for i in range(skeleton.get_bone_count()):
		all_bones.append(skeleton.get_bone_name(i))

	var by_hint := _find_bone_by_hints(all_bones, LEFT_HAND_BONE_HINTS)
	if not by_hint.is_empty():
		return by_hint

	for bone_name in all_bones:
		var normalized := _normalize_bone_name(bone_name)
		if normalized.contains("hand") and normalized.contains("l"):
			return bone_name

	return ""


func _normalize_bone_name(value: String) -> String:
	return value.to_lower().replace("_", "").replace(" ", "").replace(".", "").replace(":", "")


func _display_character_name_from_path(path: String) -> String:
	var base_name := path.get_file().get_basename()
	base_name = base_name.replace("Skeleton_", "")
	var short_name := base_name.replace("_", " ")
	var source_pack_label := _short_pack_label_by_resource_path(path)
	if source_pack_label.is_empty():
		return _clean_ui_text(short_name, short_name)
	return _clean_ui_text("%s / %s" % [source_pack_label, short_name], short_name)
func _display_weapon_name_from_path(path: String) -> String:
	var base_name := path.get_file().get_basename()
	base_name = base_name.replace("Skeleton_", "")
	var english_label := base_name.replace("_", " ").to_lower()
	var translated := _clean_ui_text(_translate_weapon_name(english_label), "")
	var localized_label := english_label
	if not translated.is_empty() and translated.to_lower() != english_label.to_lower():
		localized_label = "%s | %s" % [translated, english_label]
	var source_pack_label := _short_pack_label_by_resource_path(path)
	var prefix := ""
	if not source_pack_label.is_empty():
		prefix = "%s / " % source_pack_label
	return _clean_ui_text("%s%s" % [prefix, localized_label], english_label)
func _find_pack_by_resource_path(path: String) -> Dictionary:
	var lower_path := path.to_lower()
	for pack in PACKS:
		var chars_dir := str(pack.get("characters_dir", "")).to_lower()
		var weapons_dir := str(pack.get("weapons_dir", "")).to_lower()
		var anims_dir := str(pack.get("animations_dir", "")).to_lower()
		if (not chars_dir.is_empty() and lower_path.begins_with(chars_dir)) \
			or (not weapons_dir.is_empty() and lower_path.begins_with(weapons_dir)) \
			or (not anims_dir.is_empty() and lower_path.begins_with(anims_dir)):
			return pack
	return {}


func _short_pack_label_by_resource_path(path: String) -> String:
	var pack := _find_pack_by_resource_path(path)
	var pack_id := str(pack.get("id", ""))
	if pack_id == "skeletons":
		return "Skeletons(骷髅)"
	if pack_id == "adventurers":
		return "Adventurers(冒险者)"
	if pack_id == "newmodel":
		return "NewModel(自定义)"
	return ""
func _update_info() -> void:
	var status_lines: Array[String] = []
	if not _attach_note.is_empty():
		status_lines.append(_clean_ui_text(_attach_note, ""))
	if not _animation_source_note.is_empty():
		status_lines.append(_clean_ui_text(_animation_source_note, ""))
	if not _animation_note.is_empty():
		status_lines.append(_clean_ui_text(_animation_note, ""))
	if not _pause_note.is_empty():
		status_lines.append(_clean_ui_text(_pause_note, ""))
	if not _style_color_note.is_empty():
		status_lines.append(_clean_ui_text(_style_color_note, ""))
	if not _weapon_tune_note.is_empty():
		status_lines.append(_clean_ui_text(_weapon_tune_note, ""))
	if not _attack_note.is_empty():
		status_lines.append(_clean_ui_text(_attack_note, ""))
	if not _generate_note.is_empty():
		status_lines.append(_clean_ui_text(_generate_note, ""))
	status_lines = status_lines.filter(func(line: String) -> bool:
		return not line.strip_edges().is_empty()
	)
	if status_lines.is_empty():
		status_lines.append("Ready. Select character, weapon and animation.")

	info_label.text = "\n".join(status_lines)


func _split_identifier_tokens(raw_text: String) -> Array[String]:
	var merged := raw_text.replace("-", " ").replace("_", " ").strip_edges()
	if merged.is_empty():
		return []
	var spaced := ""
	for i in range(merged.length()):
		var code := merged.unicode_at(i)
		var prev_code := merged.unicode_at(i - 1) if i > 0 else -1
		var next_code := merged.unicode_at(i + 1) if i + 1 < merged.length() else -1
		var is_upper := code >= 65 and code <= 90
		var prev_is_lower := prev_code >= 97 and prev_code <= 122
		var prev_is_digit := prev_code >= 48 and prev_code <= 57
		var next_is_lower := next_code >= 97 and next_code <= 122
		if i > 0 and ((is_upper and (prev_is_lower or prev_is_digit)) or (is_upper and next_is_lower and prev_code >= 65 and prev_code <= 90)):
			spaced += " "
		spaced += merged.substr(i, 1)
	var tokens: Array[String] = []
	for token in spaced.split(" ", false):
		var clean_token := token.strip_edges()
		if not clean_token.is_empty():
			tokens.append(clean_token)
	return tokens


func _weapon_phrase_map() -> Dictionary:
	return {
		"shield badge": "盾牌徽记",
		"shield badge color": "盾牌徽记-涂装",
		"shield round": "圆盾",
		"shield round barbarian": "蛮族圆盾",
		"shield round color": "圆盾-涂装",
		"shield spikes": "尖刺盾",
		"shield spikes color": "尖刺盾-涂装",
		"shield square": "方盾",
		"shield square color": "方盾-涂装",
		"spellbook open": "法术书-展开",
		"spellbook closed": "法术书-合上",
		"sword 1handed": "单手剑",
		"sword 2handed": "双手剑",
		"sword 2handed color": "双手剑-涂装",
		"axe 1handed": "单手斧",
		"axe 2handed": "双手斧",
		"crossbow 1handed": "单手弩",
		"crossbow 2handed": "双手弩",
		"bow withstring": "上弦弓",
		"arrow broken half": "断箭-半截",
		"arrow broken": "断箭",
		"arrow half": "半截箭",
		"shield large a": "大盾 A",
		"shield large b": "大盾 B",
		"shield small a": "小盾 A",
		"shield small b": "小盾 B",
	}


func _weapon_token_map() -> Dictionary:
	return {
		"arrow": "箭",
		"axe": "斧",
		"blade": "刀刃",
		"crossbow": "弩",
		"quiver": "箭袋",
		"shield": "盾",
		"large": "大",
		"small": "小",
		"staff": "法杖",
		"sword": "剑",
		"dagger": "匕首",
		"wand": "魔杖",
		"bow": "弓",
		"withstring": "上弦",
		"square": "方",
		"round": "圆",
		"spikes": "尖刺",
		"badge": "徽记",
		"barbarian": "蛮族",
		"color": "涂装",
		"smokebomb": "烟雾弹",
		"spellbook": "法术书",
		"closed": "合上",
		"open": "展开",
		"1handed": "单手",
		"2handed": "双手",
		"bundle": "捆",
		"mug": "杯",
		"empty": "空",
		"full": "满",
		"broken": "断",
		"half": "半",
	}


func _translate_weapon_name(raw_name: String) -> String:
	var normalized := raw_name.to_lower().strip_edges()
	if normalized.is_empty():
		return ""
	var phrase_map := _weapon_phrase_map()
	if phrase_map.has(normalized):
		return str(phrase_map[normalized])
	var tokens := _split_identifier_tokens(normalized)
	if tokens.is_empty():
		return normalized
	var token_map := _weapon_token_map()
	var zh_parts: Array[String] = []
	for token in tokens:
		var key := token.to_lower()
		zh_parts.append(str(token_map.get(key, token)))
	return " ".join(zh_parts).strip_edges()


func _animation_token_map() -> Dictionary:
	return {
		"idle": "待机",
		"death": "死亡",
		"pose": "姿态",
		"hit": "受击",
		"interact": "交互",
		"pickup": "拾取",
		"spawn": "生成",
		"throw": "投掷",
		"use": "使用",
		"item": "道具",
		"jump": "跳跃",
		"full": "完整",
		"long": "长",
		"short": "短",
		"land": "落地",
		"start": "开始",
		"running": "跑动",
		"walking": "行走",
		"melee": "近战",
		"ranged": "远程",
		"attack": "攻击",
		"chop": "劈砍",
		"slice": "斩击",
		"diagonal": "斜向",
		"horizontal": "横向",
		"stab": "突刺",
		"spin": "旋转",
		"spinning": "旋转中",
		"block": "格挡",
		"blocking": "格挡中",
		"unarmed": "空手",
		"punch": "拳击",
		"kick": "踢击",
		"aiming": "瞄准",
		"reload": "装填",
		"shoot": "射击",
		"shooting": "射击中",
		"bow": "弓",
		"draw": "拉弓",
		"release": "释放",
		"magic": "魔法",
		"raise": "举起",
		"spellcasting": "施法",
		"summon": "召唤",
		"crawling": "爬行",
		"crouching": "下蹲",
		"dodge": "闪避",
		"backward": "后退",
		"backwards": "后退",
		"forward": "前进",
		"left": "左",
		"right": "右",
		"holdingbow": "持弓",
		"holdingrifle": "持枪",
		"strafe": "侧移",
		"sneaking": "潜行",
		"cheering": "庆祝",
		"chopping": "劈砍中",
		"dig": "挖掘",
		"digging": "挖掘中",
		"fishing": "钓鱼",
		"bite": "咬击",
		"cast": "施放",
		"catch": "接住",
		"tools": "工具",
		"general": "通用",
		"simulation": "模拟",
		"special": "特殊",
		"combat": "战斗",
		"advanced": "进阶",
		"medium": "中型",
		"skeletons": "骷髅",
		"awaken": "苏醒",
		"inactive": "静止",
		"standing": "站立",
		"floor": "地面",
		"resurrect": "复活",
		"taunt": "挑衅",
		"larger": "大型",
		"1h": "单手",
		"2h": "双手",
		"1handed": "单手",
		"2handed": "双手",
		"a": "A",
		"b": "B",
		"c": "C",
		"l": "L",
		"r": "R",
	}


func _looks_like_mojibake(text: String) -> bool:
	var suspicious_fragments := ["锟斤拷", "�", "閿", "闂", "濂", "鈥", "鈻"]
	for fragment in suspicious_fragments:
		if text.find(fragment) >= 0:
			return true
	return false


func _clean_ui_text(text: String, fallback: String = "") -> String:
	var normalized := text.replace("\n", " ").replace("\r", " ").strip_edges()
	if normalized.is_empty():
		return fallback
	if _looks_like_mojibake(normalized):
		return fallback

	var builder := ""
	for i in range(normalized.length()):
		var code := normalized.unicode_at(i)
		if code == 65533 or code == 65279:
			continue
		if code < 32:
			continue
		builder += normalized.substr(i, 1)
	var cleaned := builder.strip_edges()
	if cleaned.is_empty():
		return fallback
	return cleaned

