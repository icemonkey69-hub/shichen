extends Resource
class_name HeroData

# HeroData is the runtime hero object used by gameplay systems.
# Day-to-day editing should happen in `Excel/heroes#英雄.xlsx`,
# then be exported to `data/tables/heroes.json`.
@export var hero_id: StringName = &"crimson_hunter"
@export var hero_name := "Crimson Hunter"
@export_multiline var hero_description := "A balanced starter hero for early survival runs."
@export var model_id: StringName = &"default_player"
@export var preview_model_id: StringName = &""
@export var bloodline_ids: PackedStringArray = PackedStringArray()
@export var model_profile_overrides: Dictionary = {}
@export var preview_model_profile_overrides: Dictionary = {}
@export var model_profile_override_tag := ""
@export var preview_model_profile_override_tag := ""
@export var portrait_icon: Texture2D

@export_group("Core Attributes")
@export var primary_attr: StringName = &"str"
@export var base_str := 10.0
@export var base_agi := 10.0
@export var base_int := 10.0
@export var str_growth := 0.0
@export var agi_growth := 0.0
@export var int_growth := 0.0

@export_group("Starting Stats")
@export var starting_max_health := 100
@export var starting_max_mana := 0
@export var starting_attack_damage := 1
@export var starting_move_speed := 300.0
@export var starting_attack_interval := 0.4
@export var starting_attack_range := 460.0

@export_group("Visuals")
@export var body_color := Color(0.862745, 0.231373, 0.286275, 1)
@export var accent_color := Color(1, 0.905882, 0.756863, 1)

@export_group("Selection Skills")
@export var q_skill_name := ""
@export_multiline var q_skill_description := ""
@export var q_skill_icon: Texture2D
@export var w_skill_name := ""
@export_multiline var w_skill_description := ""
@export var w_skill_icon: Texture2D
@export var r_skill_name := ""
@export_multiline var r_skill_description := ""
@export var r_skill_icon: Texture2D
