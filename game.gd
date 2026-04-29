extends Node2D

const ENEMY_SCENE := preload("res://enemy.tscn")
const PROJECTILE_SCENE := preload("res://projectile.tscn")
const PICKUP_SCENE := preload("res://pickup.tscn")
const FLOATING_TEXT_SCENE := preload("res://floating_text.tscn")
const COIN_BURST_EFFECT_SCENE := preload("res://coin_burst_effect.tscn")
const CardPickupBurstEffectScript := preload("res://card_pickup_burst_effect.gd")
const AttributeSystemScript := preload("res://attribute_system.gd")
const RuntimeEnemySnapshotScript := preload("res://systems/runtime_enemy_snapshot.gd")
const DataTableProviderScript := preload("res://systems/data_table_provider.gd")
const TemplateBloodlineOptionIndexScript := preload("res://systems/template_bloodline_option_index.gd")
const SelectionStateScript := preload("res://systems/selection_state.gd")
const WaveRuntimeScript := preload("res://systems/wave_runtime.gd")
const BattleResultFormatterScript := preload("res://systems/battle_result_formatter.gd")
const WeaponGrowthRuntimeScript := preload("res://systems/weapon_growth_runtime.gd")
const CardCollectionBuilderScript := preload("res://systems/card_collection_builder.gd")
const CardChoiceDropRuntimeScript := preload("res://systems/card_choice_drop_runtime.gd")
const LevelRuntimeScript := preload("res://systems/level_runtime.gd")
const CombatInfoFormatterScript := preload("res://systems/combat_info_formatter.gd")
const KillRewardAmountCalculatorScript := preload("res://systems/kill_reward_amount_calculator.gd")
const RewardPickupSplitterScript := preload("res://systems/reward_pickup_splitter.gd")
const ThresholdRewardPickerScript := preload("res://systems/threshold_reward_picker.gd")
const CardIconResolverScript := preload("res://systems/card_icon_resolver.gd")
const TableValueUtilsScript := preload("res://systems/table_value_utils.gd")
const CardDisplayTextScript := preload("res://systems/card_display_text.gd")
const CardDescriptionTextScript := preload("res://systems/card_description_text.gd")
const RegexCacheScript := preload("res://systems/regex_cache.gd")
const DEFAULT_REWARD_MESSAGE_DURATION := 2.4
const DEFAULT_MESSAGE_GAP_DURATION := 0.12
const DEFAULT_RESPAWN_SECONDS := 5.0
const HIGH_LEVEL_RESPAWN_SECONDS := 10.0
const HIGH_LEVEL_RESPAWN_THRESHOLD := 50
const WAVE_TYPE_NORMAL := 1
const WAVE_TYPE_BOSS := 2
const MD04_TARGET_WAVE_COUNT := 10
const MAIN_MENU_SCENE_PATH := "res://main_menu.tscn"
const RUN_RECORD_SAVE_PATH := "user://run_record.json"
const DEBUG_CHEAT_KILL_RADIUS := 800.0
const PASSIVE_TICK_SECONDS := 0.2
const SELECTION_TOOLTIP_DELAY_SEC := 0.08
const WAVE_INFO_SCENE := preload("res://scenes/ui/波次信息.tscn")
const BOSS_HEALTH_SCENE := preload("res://scenes/ui/Boss血条.tscn")
const WAVE_BANNER_SCENE := preload("res://scenes/ui/波次横幅.tscn")
const DEATH_OVERLAY_SCENE := preload("res://scenes/ui/死亡遮罩.tscn")
const BATTLE_RESULT_SCENE := preload("res://scenes/ui/战斗结算面板.tscn")
const ATTRIBUTES_PANEL_SCENE := preload("res://scenes/ui/属性面板.tscn")
const CARD_COLLECTION_SCENE := preload("res://scenes/ui/神权收藏.tscn")
const CARD_CHOICE_SCENE := preload("res://scenes/ui/神权三选一.tscn")
const CARD_CHOICE_DRAW_COUNT := 3
const CARD_CHOICE_DEFAULT_REFRESH_COUNT := 2
const CARD_CHOICE_PICKUP_REWARD_TYPE: StringName = &"card_choice"
const WEAPON_GROWTH_TABLE_NAME: StringName = &"weapon_growth"
const RUNTIME_CONSTANT_TABLE_NAME: StringName = &"runtime_constants"
const RUNTIME_CONSTANT_CARD_CHOICE_COOLDOWN_ID := "1"
const RUNTIME_CONSTANT_CARD_CHOICE_INITIAL_CHANCE_ID := "2"
const RUNTIME_CONSTANT_CARD_CHOICE_CHANCE_INCREASE_ID := "3"
const CARD_CHOICE_DEMO_ICON_BY_ID := {
	"152": "res://assets/ui/card_choice/icons/sample/titan_heart_icon_v1.png",
}
const CARD_CHOICE_DEMO_ICON_BY_NAME := {
	"泰坦心脏": "res://assets/ui/card_choice/icons/sample/titan_heart_icon_v1.png",
}
const CARD_CHOICE_DEBUG_TITLE := "神权三选一"
const CARD_CHOICE_PICKUP_TITLE := CARD_CHOICE_DEBUG_TITLE
const CARD_COLLECTION_BUTTON_TEXT := "[神权]"
const CARD_COLLECTION_SORT_TIME := "time"
const CARD_COLLECTION_SORT_QUALITY := "quality"

const CARD_STAT_ALIAS_MAP := {
	"attack_damage": {
		"flat_id": &"bonus_attack_power",
		"percent_id": &"attack_power_percent",
	},
	"attack_power": {
		"flat_id": &"bonus_attack_power",
		"percent_id": &"attack_power_percent",
	},
	"move_speed": {
		"flat_id": &"bonus_move_speed_flat",
	},
	"max_health": {
		"flat_id": &"added_health",
		"percent_id": &"health_percent",
	},
	"attack_speed": {
		"percent_id": &"gear_skill_attack_speed_percent",
		"flat_id": &"gear_skill_attack_speed_percent",
		"default_to_percent": true,
	},
	"attack_speed_percent": {
		"percent_id": &"gear_skill_attack_speed_percent",
		"flat_id": &"gear_skill_attack_speed_percent",
		"default_to_percent": true,
	},
	"crit_rate": {
		"percent_id": &"gear_skill_crit_rate",
		"flat_id": &"gear_skill_crit_rate",
		"default_to_percent": true,
	},
	"crit_damage": {
		"percent_id": &"crit_damage_percent",
		"flat_id": &"crit_damage_percent",
		"default_to_percent": true,
	},
	"armor": {
		"flat_id": &"armor_bonus_flat",
		"percent_id": &"armor_percent",
	},
	"magic_resist": {
		"flat_id": &"magic_resist_bonus_flat",
		"percent_id": &"magic_resist_percent",
	},
	"attack_range": {
		"flat_id": &"attack_range",
	},
	"physical_damage": {
		"percent_id": &"physical_damage_percent",
		"flat_id": &"physical_damage_percent",
		"default_to_percent": true,
	},
	"magic_damage": {
		"percent_id": &"magic_damage_percent",
		"flat_id": &"magic_damage_percent",
		"default_to_percent": true,
	},
	"basic_attack_damage": {
		"percent_id": &"basic_attack_damage_percent",
		"flat_id": &"basic_attack_damage_percent",
		"default_to_percent": true,
	},
	"skill_damage": {
		"percent_id": &"skill_damage_percent",
		"flat_id": &"skill_damage_percent",
		"default_to_percent": true,
	},
	"final_damage": {
		"percent_id": &"final_damage_percent",
		"flat_id": &"final_damage_percent",
		"default_to_percent": true,
	},
	"gold_gain": {
		"percent_id": &"gold_gain_percent",
		"flat_id": &"gold_gain_percent",
		"default_to_percent": true,
	},
	"exp_gain": {
		"percent_id": &"exp_gain_percent",
		"flat_id": &"exp_gain_percent",
		"default_to_percent": true,
	},
	"skill_cdr": {
		"cdr_percent": true,
	},
}

const CARD_DESCRIPTION_ALIAS_MAP := {
	"攻击力": {
		"flat_id": &"bonus_attack_power",
		"percent_id": &"attack_power_percent",
	},
	"基础攻击力": {
		"flat_id": &"base_attack_power",
	},
	"每秒攻击力": {
		"flat_id": &"attack_power_per_second",
	},
	"攻击速度": {
		"flat_id": &"gear_skill_attack_speed_percent",
		"percent_id": &"gear_skill_attack_speed_percent",
		"default_to_percent": true,
	},
	"攻速": {
		"flat_id": &"gear_skill_attack_speed_percent",
		"percent_id": &"gear_skill_attack_speed_percent",
		"default_to_percent": true,
	},
	"攻击释放频率": {
		"flat_id": &"gear_skill_attack_speed_percent",
		"percent_id": &"gear_skill_attack_speed_percent",
		"default_to_percent": true,
	},
	"攻击间隔": {
		"flat_id": &"gear_skill_attack_speed_percent",
		"percent_id": &"gear_skill_attack_speed_percent",
		"default_to_percent": true,
		"convert_mode": "attack_interval",
	},
	"生命值": {
		"flat_id": &"added_health",
	},
	"最大生命值": {
		"flat_id": &"added_health",
	},
	"生命增幅": {
		"flat_id": &"health_percent",
		"percent_id": &"health_percent",
		"default_to_percent": true,
	},
	"法力值": {
		"flat_id": &"bonus_max_mana_flat",
		"percent_id": &"max_mana_percent",
		"default_to_percent": true,
	},
	"最大法力值": {
		"flat_id": &"bonus_max_mana_flat",
		"percent_id": &"max_mana_percent",
		"default_to_percent": true,
	},
	"最大法力": {
		"flat_id": &"bonus_max_mana_flat",
		"percent_id": &"max_mana_percent",
		"default_to_percent": true,
	},
	"法力回复": {
		"flat_id": &"mana_regen",
		"percent_id": &"mana_regen_percent",
		"default_to_percent": true,
	},
	"每秒回蓝": {
		"flat_id": &"mana_regen",
		"percent_id": &"mana_regen_percent",
		"default_to_percent": true,
	},
	"技能急速": {
		"flat_id": &"skill_haste",
	},
	"护甲": {
		"flat_id": &"armor_bonus_flat",
		"percent_id": &"armor_percent",
	},
	"基础护甲": {
		"flat_id": &"base_armor",
	},
	"魔抗": {
		"flat_id": &"magic_resist_bonus_flat",
		"percent_id": &"magic_resist_percent",
	},
	"法术伤害": {
		"flat_id": &"magic_damage_percent",
		"percent_id": &"magic_damage_percent",
		"default_to_percent": true,
	},
	"物理伤害": {
		"flat_id": &"physical_damage_percent",
		"percent_id": &"physical_damage_percent",
		"default_to_percent": true,
	},
	"普攻伤害": {
		"flat_id": &"basic_attack_damage_percent",
		"percent_id": &"basic_attack_damage_percent",
		"default_to_percent": true,
	},
	"独立增伤": {
		"flat_id": &"final_damage_percent",
		"percent_id": &"final_damage_percent",
		"default_to_percent": true,
	},
	"暴击率": {
		"flat_id": &"gear_skill_crit_rate",
		"percent_id": &"gear_skill_crit_rate",
		"default_to_percent": true,
	},
	"暴击几率": {
		"flat_id": &"gear_skill_crit_rate",
		"percent_id": &"gear_skill_crit_rate",
		"default_to_percent": true,
	},
	"暴击伤害": {
		"flat_id": &"crit_damage_percent",
		"percent_id": &"crit_damage_percent",
		"default_to_percent": true,
	},
	"闪避能力": {
		"flat_id": &"dodge_power",
		"percent_id": &"dodge_percent_bonus",
	},
	"移动速度": {
		"flat_id": &"bonus_move_speed_flat",
	},
	"射程": {
		"flat_id": &"attack_range",
	},
	"金币": {
		"flat_id": &"gold",
	},
	"钻石": {
		"flat_id": &"crystal",
	},
	"水晶": {
		"flat_id": &"crystal",
	},
	"经验获取": {
		"flat_id": &"exp_gain_percent",
		"percent_id": &"exp_gain_percent",
		"default_to_percent": true,
	},
	"每秒金币": {
		"flat_id": &"gold_per_second",
	},
	"每秒经验": {
		"flat_id": &"exp_per_second",
	},
	"每秒经济": {
		"flat_id": &"gold_per_second",
	},
	"每秒水晶": {
		"flat_id": &"crystal_per_second",
	},
	"杀敌金币": {
		"flat_id": &"bonus_gold_per_kill",
	},
	"每秒杀敌数": {
		"flat_id": &"kill_count_per_second",
	},
	"每秒杀敌": {
		"flat_id": &"kill_count_per_second",
	},
	"物理穿透": {
		"flat_id": &"physical_pen_flat",
		"percent_id": &"physical_pen_percent",
	},
	"法师穿透": {
		"flat_id": &"magic_pen_flat",
		"percent_id": &"magic_pen_percent",
	},
	"法术穿透": {
		"flat_id": &"magic_pen_flat",
		"percent_id": &"magic_pen_percent",
	},
	"分裂": {
		"flat_id": &"split_percent",
		"percent_id": &"split_percent",
		"default_to_percent": true,
	},
	"攻击回复": {
		"flat_id": &"on_hit_heal",
	},
	"吸血": {
		"flat_id": &"life_steal",
		"percent_id": &"life_steal",
		"default_to_percent": true,
	},
	"法术吸血": {
		"flat_id": &"spell_vamp",
		"percent_id": &"spell_vamp",
		"default_to_percent": true,
	},
	"武器释放频率": {
		"flat_id": &"weapon_cast_rate_percent",
		"percent_id": &"weapon_cast_rate_percent",
		"default_to_percent": true,
	},
	"[武器]释放频率": {
		"flat_id": &"weapon_cast_rate_percent",
		"percent_id": &"weapon_cast_rate_percent",
		"default_to_percent": true,
	},
	"武器伤害系数": {
		"flat_id": &"weapon_damage_ratio",
		"percent_id": &"weapon_damage_ratio",
	},
	"[武器]伤害系数": {
		"flat_id": &"weapon_damage_ratio",
		"percent_id": &"weapon_damage_ratio",
	},
	"所有[武器]伤害系数": {
		"flat_id": &"weapon_damage_ratio",
		"percent_id": &"weapon_damage_ratio",
	},
	"[武器]最终伤害": {
		"flat_id": &"weapon_final_damage_percent",
		"percent_id": &"weapon_final_damage_percent",
		"default_to_percent": true,
	},
	"[武器]频率间隔": {
		"flat_id": &"weapon_interval_reduce_percent",
		"percent_id": &"weapon_interval_reduce_percent",
		"default_to_percent": true,
		"convert_mode": "interval_reduce",
	},
	"武器频率间隔": {
		"flat_id": &"weapon_interval_reduce_percent",
		"percent_id": &"weapon_interval_reduce_percent",
		"default_to_percent": true,
		"convert_mode": "interval_reduce",
	},
	"[弹幕]武器伤害系数": {
		"flat_id": &"barrage_weapon_damage_ratio",
		"percent_id": &"barrage_weapon_damage_ratio",
	},
	"[弹幕]武器释放频率": {
		"flat_id": &"barrage_interval_reduce_percent",
		"percent_id": &"barrage_interval_reduce_percent",
		"default_to_percent": true,
	},
	"[弹幕]:释放间隔": {
		"flat_id": &"barrage_interval_reduce_percent",
		"percent_id": &"barrage_interval_reduce_percent",
		"default_to_percent": true,
		"convert_mode": "interval_reduce",
	},
	"[弹幕]释放间隔": {
		"flat_id": &"barrage_interval_reduce_percent",
		"percent_id": &"barrage_interval_reduce_percent",
		"default_to_percent": true,
		"convert_mode": "interval_reduce",
	},
	"[弹幕]武器双重施法": {
		"flat_id": &"barrage_double_cast_rate",
		"percent_id": &"barrage_double_cast_rate",
		"default_to_percent": true,
	},
	"[弹幕]直接释放": {
		"flat_id": &"barrage_instant_cast_rate",
		"percent_id": &"barrage_instant_cast_rate",
		"default_to_percent": true,
	},
	"[飞行物]武器伤害系数": {
		"flat_id": &"projectile_weapon_damage_ratio",
		"percent_id": &"projectile_weapon_damage_ratio",
	},
	"[飞行物]武器频率间隔": {
		"flat_id": &"projectile_interval_reduce_percent",
		"percent_id": &"projectile_interval_reduce_percent",
		"default_to_percent": true,
		"convert_mode": "interval_reduce",
	},
	"[飞行物]三重施法": {
		"flat_id": &"projectile_triple_cast_rate",
		"percent_id": &"projectile_triple_cast_rate",
		"default_to_percent": true,
	},
	"[附魔]武器伤害系数": {
		"flat_id": &"enchant_weapon_damage_ratio",
		"percent_id": &"enchant_weapon_damage_ratio",
	},
	"[附魔]普攻释放": {
		"flat_id": &"enchant_on_attack_rate",
		"percent_id": &"enchant_on_attack_rate",
		"default_to_percent": true,
	},
	"[符文]武器伤害系数": {
		"flat_id": &"rune_weapon_damage_ratio",
		"percent_id": &"rune_weapon_damage_ratio",
	},
	"[符文]武器武器伤害系数": {
		"flat_id": &"rune_weapon_damage_ratio",
		"percent_id": &"rune_weapon_damage_ratio",
	},
	"[符文]武器释放频率": {
		"flat_id": &"rune_interval_reduce_percent",
		"percent_id": &"rune_interval_reduce_percent",
		"default_to_percent": true,
	},
	"[符文]武器释放间隔": {
		"flat_id": &"rune_interval_reduce_percent",
		"percent_id": &"rune_interval_reduce_percent",
		"default_to_percent": true,
		"convert_mode": "interval_reduce",
	},
	"[符文]武器每秒释放": {
		"flat_id": &"rune_auto_cast_rate",
		"percent_id": &"rune_auto_cast_rate",
		"default_to_percent": true,
	},
	"[战宠]独立增伤": {
		"flat_id": &"pet_final_damage_percent",
		"percent_id": &"pet_final_damage_percent",
		"default_to_percent": true,
	},
	"[战宠]持续时间": {
		"flat_id": &"pet_duration_seconds",
	},
	"[战宠]护甲和魔抗": {
		"flat_ids": [&"pet_armor", &"pet_magic_resist"],
	},
	"[战宠]护甲": {
		"flat_id": &"pet_armor",
	},
	"[战宠]魔抗": {
		"flat_id": &"pet_magic_resist",
	},
	"[战宠]武器的战宠攻击速度": {
		"flat_id": &"pet_attack_speed_percent",
		"percent_id": &"pet_attack_speed_percent",
		"default_to_percent": true,
	},
	"所有[战宠]的攻击速度": {
		"flat_id": &"pet_attack_speed_percent",
		"percent_id": &"pet_attack_speed_percent",
		"default_to_percent": true,
	},
	"[战宠]武器的战宠最终伤害": {
		"flat_id": &"pet_final_damage_percent",
		"percent_id": &"pet_final_damage_percent",
		"default_to_percent": true,
	},
}

const HERO_SELECTION_TABLE_NAME: StringName = &"heroes"
const BLOODLINE_TABLE_NAME: StringName = &"bloodlines"
const TEMPLATE_BLOODLINE_OPTION_TABLE_NAME: StringName = &"template_bloodline_options"
const BLOODLINE_ICON_DIR := "res://assets/ui/icons/bloodlines/"
const SELECTION_GRID_COLUMNS := 5
const COMBAT_INFO_REFRESH_INTERVAL := 0.12

@export var play_area := Rect2(-1000.0, -1000.0, 2000.0, 2000.0)
@export var hero_selection_duration := 10.0
@export var wave_duration_seconds := 80.0 # 波次表未填写 duration 时的兜底秒数
@export var wave_prepare_seconds := 2.5
@export var wave_transition_seconds := 2.0
@export var wave_banner_seconds := 1.6
@export var card_choice_pickup_interval_seconds := 5.0
@export var card_choice_pickup_initial_chance_percent := 100.0
@export var card_choice_pickup_chance_increase_percent := 4.0
@export var max_alive_enemies := 50
@export var enemy_overload_defeat_seconds := 10.0
@export var respawn_invulnerability_seconds := 1.5
@export var enemy_pool_enabled := true
@export var enemy_pool_size_per_model := 64
@export var enemy_pool_total_cap := 120
@export var enemy_pool_hidden_position := Vector2(-22000.0, -22000.0)
@export var hero_table_name: StringName = HERO_SELECTION_TABLE_NAME
@export var selected_hero_id: StringName = &""
@export var selected_hero: HeroData

@onready var player = $Player
@onready var enemies = $Enemies
@onready var projectiles = $Projectiles
@onready var battle_terrain: Node = get_node_or_null("测试地形")
@onready var hud: BattleHudUi = $战斗HUD
@onready var selection_overlay: HeroSelectionOverlayUi = $SelectionLayer/SelectionOverlay

var elapsed_time := 0.0
var kill_count := 0
var spawn_cooldown := 0.0
var game_over := false
var wave_rows: Array[Dictionary] = []
var current_wave_index := 0
var current_wave_spawned := 0
var current_wave_spawn_timer := 0.0
var wave_boss_spawned := false
var current_wave_elapsed := 0.0
var current_gold := 0
var current_exp := 0
var current_level := 1
var runtime_bonus_values: Dictionary = {}
var reward_attribute_bonus_values: Dictionary = {}
var passive_accumulated_bonus_values: Dictionary = {}
var passive_conditional_bonus_values: Dictionary = {}
var passive_tick_accumulator := 0.0
var passive_spec_progress: Dictionary = {}
var card_rows: Array[Dictionary] = []
var weapon_rows: Array[Dictionary] = []
var bloodline_rows: Array[Dictionary] = []
var template_bloodline_option_rows: Array[Dictionary] = []
var kill_reward_rows: Array[Dictionary] = []
var next_kill_reward_index := 0
var owned_cards: Array[Dictionary] = []
var owned_card_passives: Array[Dictionary] = []
var owned_card_runtime_specs: Array[Dictionary] = []
var passive_fractional_progress := {
	"gold": 0.0,
	"kill_count": 0.0,
	"health": 0.0,
	"mana": 0.0,
}
var owned_weapons: Array[Dictionary] = []
var transient_message_remaining := 0.0
var transient_message_queue: Array[Dictionary] = []

var available_heroes: Array[HeroData] = []
var hero_button_nodes: Array[Button] = []
var bloodline_button_nodes: Array[Button] = []
var bloodline_rows_by_id: Dictionary = {}
var available_enemies: Array[EnemyData] = []
var normal_enemies: Array[EnemyData] = []
var elite_enemies: Array[EnemyData] = []
var boss_enemies: Array[EnemyData] = []
var enemy_data_by_id: Dictionary = {}
var enemy_pool_nodes: Array[Node2D] = []
var enemy_pool_available_by_model: Dictionary = {}
var selection_active := true
var selection_time_remaining := 0.0
var selection_preview_model_root: Node2D
var selection_preview_hero_model: HeroModel
var selection_skill_buttons: Dictionary = {}
var selection_preview_dragging := false
var selection_preview_signature := ""
var selection_last_skill_signature := ""
var selection_preview_should_replay_intro := true
var combat_info_refresh_accumulator := 0.0
var runtime_enemy_snapshot: RuntimeEnemySnapshot
var data_table_provider: DataTableProvider
var template_bloodline_option_index: TemplateBloodlineOptionIndex
var selection_state: SelectionState
var wave_runtime: WaveRuntime
var weapon_growth_runtime: WeaponGrowthRuntime
var level_runtime: LevelRuntime
var regex_cache: RegexCache

var attributes_panel: AttributesPanelUi
var attributes_value_labels: Dictionary = {}
var attribute_panel_entries: Array[Dictionary] = []
var attributes_panel_visible := false
var card_collection_button: Button
var card_collection_overlay: CardCollectionOverlayUi
var card_collection_sort_mode := CARD_COLLECTION_SORT_QUALITY
var card_collection_selected_stack_key := ""
var card_collection_visible := false
var card_icon_resolver: CardIconResolver
var card_choice_overlay: CardChoiceOverlayUi
var card_choice_overlay_visible := false
var card_choice_rows: Array[Dictionary] = []
var card_choice_selected_index := -1
var card_choice_refresh_remaining := 0
var card_choice_title_text := CARD_CHOICE_DEBUG_TITLE
var queued_card_choice_pickups := 0
var card_choice_overlay_request_pending := false
var card_choice_drop_runtime: CardChoiceDropRuntime
var card_collect_effect_layer: Control
var wave_info_panel: WaveInfoUi
var wave_banner_panel: WaveBannerUi
var wave_banner_remaining := 0.0

enum WaveFlowState {
	PREPARE,
	ACTIVE,
	TRANSITION,
	COMPLETE,
}

var wave_flow_state := WaveFlowState.PREPARE
var wave_state_remaining := 0.0
var current_wave_timed_spawns: Array[Dictionary] = []
var pickups: Node2D
var effects: Node2D
var death_overlay: DeathOverlayUi
var respawn_remaining := 0.0
var player_respawning := false
var player_respawn_anchor := Vector2.ZERO
var boss_health_panel: BossHealthUi
var victory_overlay: BattleResultUi
var battle_finished := false
var enemy_overload_remaining := 0.0
var cleared_wave_count := 0
var battle_result_reason := ""


func _ready() -> void:
	randomize()
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec", SELECTION_TOOLTIP_DELAY_SEC)
	runtime_enemy_snapshot = RuntimeEnemySnapshotScript.new()
	data_table_provider = DataTableProviderScript.new()
	template_bloodline_option_index = TemplateBloodlineOptionIndexScript.new()
	selection_state = SelectionStateScript.new()
	wave_runtime = WaveRuntimeScript.new()
	weapon_growth_runtime = WeaponGrowthRuntimeScript.new()
	card_choice_drop_runtime = CardChoiceDropRuntimeScript.new()
	level_runtime = LevelRuntimeScript.new()
	card_icon_resolver = CardIconResolverScript.new(CARD_CHOICE_DEMO_ICON_BY_ID, CARD_CHOICE_DEMO_ICON_BY_NAME)
	regex_cache = RegexCacheScript.new()
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemies.process_mode = Node.PROCESS_MODE_PAUSABLE
	projectiles.process_mode = Node.PROCESS_MODE_PAUSABLE
	pickups = Node2D.new()
	pickups.name = "Pickups"
	pickups.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(pickups)
	effects = Node2D.new()
	effects.name = "Effects"
	effects.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(effects)

	_apply_terrain_settings()
	player.configure(play_area)
	player.projectile_requested.connect(_on_player_projectile_requested)
	player.health_changed.connect(_on_player_health_changed)
	player.mana_changed.connect(_on_player_mana_changed)
	player.died.connect(_on_player_died)
	player.set_controls_enabled(false)
	player.visible = false

	if hud == null:
		push_warning("Battle HUD is missing from game.tscn.")
	else:
		hud.set_combat_hud_visible(false)
		hud.set_help_text("Tab: 全属性面板（暂停/继续）  F1: 范围清怪(测试)  F2: 完成当前波次(测试)  F8: 自杀(测试)")
		hud.hide_message()
		hud.set_minimap_visible(false)
		hud.configure_minimap(play_area, player)
		hud.connect_weapon_growth_upgrade(Callable(self, "_on_weapon_growth_upgrade_requested"))
	if selection_overlay == null:
		push_warning("Hero selection overlay is missing from game.tscn.")
	else:
		if not selection_overlay.confirm_requested.is_connected(_confirm_current_hero_selection):
			selection_overlay.confirm_requested.connect(_confirm_current_hero_selection)
		if not selection_overlay.preview_gui_input.is_connected(_on_selection_preview_gui_input):
			selection_overlay.preview_gui_input.connect(_on_selection_preview_gui_input)
		if not selection_overlay.preview_resized.is_connected(_on_selection_preview_size_changed):
			selection_overlay.preview_resized.connect(_on_selection_preview_size_changed)
	selection_skill_buttons = selection_overlay.get_skill_buttons() if selection_overlay != null else {}
	_connect_selection_skill_signals()

	_setup_wave_info_display()
	_setup_boss_health_bar()
	_setup_wave_banner_display()
	_setup_death_overlay()
	_setup_victory_overlay()
	_setup_attributes_panel()
	_setup_card_runtime_ui()
	_load_available_heroes()
	_load_available_enemies()
	_rebuild_enemy_pool()
	_load_wave_rows()
	_load_card_rows()
	_load_weapon_rows()
	_load_weapon_growth_rows()
	_load_bloodline_rows()
	_load_kill_reward_rows()
	_load_levelup_rows()
	_load_runtime_constant_settings()
	_build_hero_selection_buttons()
	_start_hero_selection()


func _apply_terrain_settings() -> void:
	if battle_terrain == null:
		push_warning("Battle terrain is missing from game.tscn; fallback play_area will be used.")
		return
	if not battle_terrain.has_method("get_play_area"):
		push_warning("Battle terrain does not expose get_play_area(); fallback play_area will be used.")
		return
	var terrain_area: Rect2 = battle_terrain.call("get_play_area")
	if terrain_area.size.x <= 0.0 or terrain_area.size.y <= 0.0:
		push_warning("Battle terrain play_area is invalid; fallback play_area will be used.")
		return
	play_area = terrain_area


func _get_player_start_position() -> Vector2:
	if battle_terrain != null and battle_terrain.has_method("get_spawn_position"):
		return battle_terrain.call("get_spawn_position")
	return play_area.position + play_area.size * 0.5


func _process(delta: float) -> void:
	if selection_active:
		_process_hero_selection(delta)
		return

	if attributes_panel_visible:
		_refresh_attribute_panel_values()
		return

	if card_choice_overlay_visible or card_collection_visible:
		return

	if game_over:
		if Input.is_physical_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	_update_transient_message(delta)
	_update_wave_banner(delta)
	_update_respawn_state(delta)
	if player_respawning:
		_update_hud(player.health, player.max_health, delta)
		return
	elapsed_time += delta
	_request_queued_card_choice_overlay()
	_process_card_runtime_effects(delta)
	_process_wave_spawning(delta)
	_refresh_runtime_enemy_snapshot()
	var alive_enemy_count := _get_runtime_alive_enemy_count()
	_update_enemy_overload_state(delta, alive_enemy_count)
	_check_battle_completion(alive_enemy_count)

	_update_hud(player.health, player.max_health, delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F6:
			_reload_data_tables()
			get_tree().reload_current_scene()
			return

		if not selection_active and event.physical_keycode == KEY_TAB and not game_over:
			_toggle_attributes_panel()
			return

		if not selection_active and event.physical_keycode == KEY_F1 and not game_over:
			_debug_kill_enemies_around_player(DEBUG_CHEAT_KILL_RADIUS)
			return

		if not selection_active and event.physical_keycode == KEY_F2 and not game_over:
			_debug_complete_current_wave()
			return

		if not selection_active and event.physical_keycode == KEY_F8 and not game_over:
			player.receive_damage(player.health)
			return

		if not selection_active and event.physical_keycode == KEY_F3 and not game_over:
			_debug_open_card_choice()
			return

	if not selection_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_W, KEY_UP:
				_step_template_selection(-1)
			KEY_S, KEY_DOWN:
				_step_template_selection(1)
			KEY_A, KEY_LEFT:
				_step_bloodline_selection(-1)
			KEY_D, KEY_RIGHT:
				_step_bloodline_selection(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_confirm_current_hero_selection()


func _on_player_projectile_requested(spawn_position: Vector2, direction: Vector2, damage: int, source_stats) -> void:
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = spawn_position
	projectile.direction = direction
	projectile.damage = damage
	projectile.source_stats = source_stats
	projectile.play_area = play_area
	projectiles.add_child(projectile)


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	_update_hud(current_health, max_health)


func _on_player_mana_changed(current_mana: int, max_mana: int) -> void:
	_update_resource_bars(player.health, player.max_health, current_mana, max_mana)


func _on_player_died() -> void:
	player.set_controls_enabled(false)
	player_respawn_anchor = player.global_position
	_start_player_respawn()


func _start_player_respawn() -> void:
	player_respawning = true
	respawn_remaining = _get_player_respawn_duration()
	_show_death_overlay()
	_update_death_overlay_text()


func _update_respawn_state(delta: float) -> void:
	if not player_respawning:
		return

	respawn_remaining = maxf(respawn_remaining - delta, 0.0)
	_update_death_overlay_text()
	if respawn_remaining == 0.0:
		_finish_player_respawn()


func _finish_player_respawn() -> void:
	player_respawning = false
	_hide_death_overlay()
	player.respawn(player_respawn_anchor, respawn_invulnerability_seconds)
	player_respawn_anchor = player.global_position
	player.set_controls_enabled(true)
	_show_transient_message("已复活", 1.2)
	_update_hud(player.health, player.max_health)


func _get_player_respawn_duration() -> float:
	if current_level > HIGH_LEVEL_RESPAWN_THRESHOLD:
		return HIGH_LEVEL_RESPAWN_SECONDS
	return DEFAULT_RESPAWN_SECONDS


func _show_death_overlay() -> void:
	if death_overlay == null:
		return
	death_overlay.show_overlay("你已阵亡", "%d 秒后复活" % max(ceili(respawn_remaining), 0))


func _hide_death_overlay() -> void:
	if death_overlay == null:
		return
	death_overlay.hide_overlay()


func _update_death_overlay_text() -> void:
	if death_overlay == null:
		return

	var respawn_seconds := ceili(respawn_remaining)
	death_overlay.set_texts("你已阵亡", "%d 秒后复活" % max(respawn_seconds, 0))


func _refresh_runtime_enemy_snapshot(force: bool = false) -> void:
	if runtime_enemy_snapshot == null:
		runtime_enemy_snapshot = RuntimeEnemySnapshotScript.new()
	var tree := get_tree()
	if tree == null:
		return
	runtime_enemy_snapshot.refresh(tree, force)


func _invalidate_runtime_enemy_snapshot() -> void:
	if runtime_enemy_snapshot != null:
		runtime_enemy_snapshot.invalidate()


func _get_runtime_alive_enemy_count(force_refresh: bool = false) -> int:
	_refresh_runtime_enemy_snapshot(force_refresh)
	if runtime_enemy_snapshot == null:
		return 0
	return runtime_enemy_snapshot.alive_enemy_count


func _get_runtime_active_boss_nodes(force_refresh: bool = false) -> Array[Node2D]:
	_refresh_runtime_enemy_snapshot(force_refresh)
	if runtime_enemy_snapshot == null:
		return []
	return runtime_enemy_snapshot.active_boss_nodes


func _check_battle_completion(alive_enemy_count: int = -1) -> void:
	if alive_enemy_count < 0:
		alive_enemy_count = _get_runtime_alive_enemy_count()
	if wave_runtime == null:
		wave_runtime = WaveRuntimeScript.new()
	var should_finish := wave_runtime.should_finish_victory(
		battle_finished,
		not wave_rows.is_empty(),
		wave_flow_state,
		WaveFlowState.COMPLETE,
		alive_enemy_count
	)
	if not should_finish:
		return

	_finish_battle_victory()


func _finish_battle_victory() -> void:
	if battle_finished:
		return

	battle_finished = true
	battle_result_reason = "最终波清场"
	game_over = true
	player_respawning = false
	_hide_death_overlay()
	_hide_attributes_panel()
	if player != null:
		player.set_controls_enabled(false)

	_save_run_record("victory")
	_show_victory_overlay()


func _finish_battle_defeat(reason: String) -> void:
	if battle_finished:
		return

	battle_finished = true
	battle_result_reason = reason.strip_edges()
	game_over = true
	player_respawning = false
	enemy_overload_remaining = 0.0
	_hide_death_overlay()
	_hide_attributes_panel()
	if player != null:
		player.set_controls_enabled(false)

	_save_run_record("defeat")
	_show_defeat_overlay(reason)


func _show_victory_overlay() -> void:
	if victory_overlay == null:
		return

	var final_wave: int = _get_wave_number(wave_rows.size() - 1) if not wave_rows.is_empty() else 0
	var elapsed_seconds: int = int(round(elapsed_time))
	var hero_name := selected_hero.hero_name if selected_hero != null else "未知英雄"
	var summary_text := BattleResultFormatterScript.build_victory_summary(
		hero_name,
		final_wave,
		elapsed_seconds,
		kill_count,
		current_gold,
		current_exp,
		current_level
	)
	victory_overlay.show_result("战斗胜利", summary_text)


func _show_defeat_overlay(reason: String) -> void:
	if victory_overlay == null:
		return

	var reached_wave: int = _get_wave_number(current_wave_index) if not wave_rows.is_empty() else 0
	var elapsed_seconds: int = int(round(elapsed_time))
	var hero_name := selected_hero.hero_name if selected_hero != null else "未知英雄"
	var reason_text := reason.strip_edges()
	if reason_text.is_empty():
		reason_text = "战斗失败"
	var summary_text := BattleResultFormatterScript.build_defeat_summary(
		reason_text,
		hero_name,
		reached_wave,
		elapsed_seconds,
		kill_count,
		current_gold,
		current_exp,
		current_level
	)
	victory_overlay.show_result("战斗失败", summary_text)


func _hide_victory_overlay() -> void:
	if victory_overlay == null:
		return
	victory_overlay.hide_panel()


func _on_victory_return_button_pressed() -> void:
	_return_to_main_menu()


func _return_to_main_menu() -> void:
	get_tree().paused = false
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	var error_code: Error = scene_tree.change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if error_code != OK:
		push_error("无法切换到主界面：%s (错误码 %d)" % [MAIN_MENU_SCENE_PATH, int(error_code)])


func _save_run_record(result: String) -> void:
	var save_data: Dictionary = _load_run_record()
	var run_record: Dictionary = _build_run_record(result)
	save_data["version"] = 1
	save_data["total_runs"] = int(save_data.get("total_runs", 0)) + 1
	save_data["last_run"] = run_record

	var current_kills: int = int(run_record.get("kill_count", 0))
	var best_kills: int = int(save_data.get("best_kill_count", 0))
	save_data["best_kill_count"] = maxi(best_kills, current_kills)

	var current_clear_seconds: float = float(run_record.get("elapsed_seconds", 0.0))
	var best_clear_seconds: float = float(save_data.get("best_clear_seconds", 0.0))
	if result == "victory" and (best_clear_seconds <= 0.0 or current_clear_seconds < best_clear_seconds):
		save_data["best_clear_seconds"] = current_clear_seconds

	var save_file: FileAccess = FileAccess.open(RUN_RECORD_SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_warning("存档写入失败：%s" % RUN_RECORD_SAVE_PATH)
		return
	save_file.store_string(JSON.stringify(save_data, "\t"))


func _load_run_record() -> Dictionary:
	if not FileAccess.file_exists(RUN_RECORD_SAVE_PATH):
		return {}

	var save_file: FileAccess = FileAccess.open(RUN_RECORD_SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return {}

	var content: String = save_file.get_as_text()
	if content.strip_edges().is_empty():
		return {}

	var json := JSON.new()
	var parse_error: Error = json.parse(content)
	if parse_error != OK:
		push_warning("读取存档失败（JSON 解析错误）：%s" % RUN_RECORD_SAVE_PATH)
		return {}

	var data: Variant = json.data
	if data is Dictionary:
		return (data as Dictionary).duplicate(true)
	return {}


func _build_run_record(result: String) -> Dictionary:
	var hero_name := selected_hero.hero_name if selected_hero != null else "未知英雄"
	var current_wave: int = _get_wave_number(current_wave_index) if not wave_rows.is_empty() else 0
	var total_waves := wave_rows.size()
	return {
		"result": result,
		"hero_id": String(selected_hero_id),
		"hero_name": String(hero_name),
		"current_wave": current_wave,
		"cleared_wave_count": cleared_wave_count,
		"total_waves": total_waves,
		"elapsed_seconds": float(elapsed_time),
		"kill_count": kill_count,
		"gold": current_gold,
		"exp": current_exp,
		"level": current_level,
		"reason": battle_result_reason,
		"timestamp_unix": int(Time.get_unix_time_from_system()),
	}


func _on_enemy_died(_world_position: Vector2, reward_info: Dictionary = {}) -> void:
	_invalidate_runtime_enemy_snapshot()
	kill_count += 1
	_apply_card_passives_on_kill()
	_spawn_enemy_death_feedback(_world_position, reward_info)
	_try_spawn_card_choice_pickup_from_enemy_death(_world_position, reward_info)
	_spawn_kill_reward_pickups(_world_position, reward_info)
	_process_kill_reward_thresholds()
	_sync_player_runtime_progress()
	_update_hud(player.health, player.max_health)


func _debug_kill_enemies_around_player(radius: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	var player_position: Vector2 = player.global_position
	var safe_radius: float = maxf(radius, 0.0)
	var radius_squared: float = safe_radius * safe_radius
	var killed_count := 0
	var enemy_nodes = get_tree().get_nodes_in_group("enemy")
	for enemy_node in enemy_nodes:
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if not (enemy_node is Node2D):
			continue

		var enemy_2d: Node2D = enemy_node
		if enemy_2d.global_position.distance_squared_to(player_position) > radius_squared:
			continue
		if enemy_2d.has_method("take_damage"):
			enemy_2d.call("take_damage", 999999999)
			killed_count += 1

	if killed_count > 0:
		_show_transient_message("测试：清除半径 %.0f 范围敌人 x%d" % [safe_radius, killed_count], 1.2)
	else:
		_show_transient_message("测试：半径 %.0f 范围内无敌人" % safe_radius, 0.9)


func _debug_complete_current_wave() -> void:
	if wave_rows.is_empty():
		_show_transient_message("测试：当前无波次表，无法跳波。", 1.2)
		return

	match wave_flow_state:
		WaveFlowState.COMPLETE:
			_show_transient_message("测试：当前已是最终完成状态。", 1.0)
			return
		WaveFlowState.TRANSITION:
			wave_state_remaining = 0.0
			_advance_wave()
			_update_hud(player.health, player.max_health)
			_show_transient_message("测试：已快速推进到下一波。", 1.0)
			return
		WaveFlowState.PREPARE:
			_start_current_wave()
		_:
			pass

	var removed_count: int = _debug_clear_all_enemies_immediately()
	_start_wave_transition(true)
	_update_hud(player.health, player.max_health)
	_show_transient_message(
		"测试：第%s波已完成（清场 x%d）。" % [_get_wave_display_text(), removed_count],
		1.15
	)


func _debug_clear_all_enemies_immediately() -> int:
	var removed_count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemy"):
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if enemy_node is Node2D and enemy_pool_nodes.has(enemy_node as Node2D):
			_release_enemy_to_pool(enemy_node as Node2D)
		else:
			enemy_node.queue_free()
		removed_count += 1
	return removed_count


func _spawn_enemy_ring(count: int) -> void:
	for _i in count:
		_spawn_enemy()


func _spawn_enemy(enemy_data: EnemyData = null, force_boss: bool = false) -> void:
	if enemy_data == null:
		enemy_data = _pick_enemy_for_spawn()

	var enemy: Node2D = _acquire_enemy_instance_for_data(enemy_data)
	if enemy == null:
		return

	if enemy_data != null and enemy.has_method("apply_enemy_data"):
		enemy.call("apply_enemy_data", enemy_data)
		_apply_enemy_boss_override(enemy, force_boss)
	else:
		enemy.max_health = 1 + int(elapsed_time / 20.0)
		enemy.move_speed = 88.0 + min(elapsed_time * 3.0, 70.0)
		enemy.touch_damage = 6 + int(elapsed_time / 30.0)
		enemy.set("health", enemy.max_health)
		_apply_enemy_boss_override(enemy, force_boss)

	if enemy.has_method("ensure_model_ready"):
		enemy.call("ensure_model_ready")

	var spawn_position: Vector2 = _pick_spawn_position(force_boss)
	if enemy.has_method("activate_from_pool"):
		enemy.call("activate_from_pool", player, spawn_position)
	else:
		enemy.set("player", player)
		enemy.global_position = spawn_position
	_invalidate_runtime_enemy_snapshot()


func _apply_enemy_boss_override(enemy, force_boss: bool) -> void:
	if enemy == null or not force_boss:
		return
	if enemy.has_method("set_forced_boss_state"):
		enemy.call("set_forced_boss_state", true)
		return

	enemy.set("enemy_type", EnemyCatalog.TYPE_BOSS)
	enemy.set("is_boss", true)
	if enemy.has_method("_sync_enemy_groups"):
		enemy.call("_sync_enemy_groups")
	else:
		enemy.add_to_group("boss")


func _pick_spawn_position(force_boss: bool = false) -> Vector2:
	if force_boss:
		return _get_boss_spawn_position()

	if player != null and is_instance_valid(player):
		return _pick_spawn_position_outside_player_view()

	var min_corner := play_area.position
	var max_corner := play_area.position + play_area.size
	var spawn_margin := 36.0

	match randi() % 4:
		0:
			return Vector2(randf_range(min_corner.x, max_corner.x), min_corner.y - spawn_margin)
		1:
			return Vector2(max_corner.x + spawn_margin, randf_range(min_corner.y, max_corner.y))
		2:
			return Vector2(randf_range(min_corner.x, max_corner.x), max_corner.y + spawn_margin)
		_:
			return Vector2(min_corner.x - spawn_margin, randf_range(min_corner.y, max_corner.y))


func _get_boss_spawn_position() -> Vector2:
	if battle_terrain != null and battle_terrain.has_method("get_boss_spawn_position"):
		return battle_terrain.call("get_boss_spawn_position")
	return play_area.position + play_area.size * 0.5


func _pick_spawn_position_outside_player_view() -> Vector2:
	if player == null or not is_instance_valid(player):
		return Vector2.ZERO

	var visible_rect: Rect2 = _get_player_visible_world_rect()
	var avoid_rect: Rect2 = visible_rect.grow(36.0)
	var spawn_band := 120.0
	var play_rect: Rect2 = play_area.grow(-6.0)

	for _attempt in range(28):
		var side := randi() % 4
		var candidate := Vector2.ZERO
		match side:
			0:
				candidate = Vector2(randf_range(avoid_rect.position.x, avoid_rect.end.x), avoid_rect.position.y - spawn_band)
			1:
				candidate = Vector2(avoid_rect.end.x + spawn_band, randf_range(avoid_rect.position.y, avoid_rect.end.y))
			2:
				candidate = Vector2(randf_range(avoid_rect.position.x, avoid_rect.end.x), avoid_rect.end.y + spawn_band)
			_:
				candidate = Vector2(avoid_rect.position.x - spawn_band, randf_range(avoid_rect.position.y, avoid_rect.end.y))

		if not play_rect.has_point(candidate):
			continue
		if avoid_rect.has_point(candidate):
			continue
		return candidate

	# 边界情况（例如玩家贴近地图边缘）回退到场地边缘刷怪。
	var min_corner := play_area.position
	var max_corner := play_area.position + play_area.size
	var spawn_margin := 36.0
	match randi() % 4:
		0:
			return Vector2(randf_range(min_corner.x, max_corner.x), min_corner.y - spawn_margin)
		1:
			return Vector2(max_corner.x + spawn_margin, randf_range(min_corner.y, max_corner.y))
		2:
			return Vector2(randf_range(min_corner.x, max_corner.x), max_corner.y + spawn_margin)
		_:
			return Vector2(min_corner.x - spawn_margin, randf_range(min_corner.y, max_corner.y))


func _get_player_visible_world_rect() -> Rect2:
	var player_node: Node2D = player as Node2D
	var center: Vector2 = player_node.global_position if player_node != null else Vector2.ZERO
	if player_node != null and player_node.has_node("Camera2D"):
		var camera: Camera2D = player_node.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			center = camera.get_screen_center_position()

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zoom: Vector2 = Vector2.ONE
	if player_node != null and player_node.has_node("Camera2D"):
		var player_camera: Camera2D = player_node.get_node_or_null("Camera2D") as Camera2D
		if player_camera != null:
			zoom = player_camera.zoom

	var world_size: Vector2 = viewport_size * zoom
	var half_size: Vector2 = world_size * 0.5
	return Rect2(center - half_size, world_size)


func _get_spawn_interval() -> float:
	return max(0.95, 1.45 - elapsed_time * 0.01)


func _get_spawn_burst_count() -> int:
	return 1


func _process_wave_spawning(delta: float) -> void:
	if wave_rows.is_empty():
		# 没有波次配置时回退到旧版无限刷怪逻辑，避免 Demo 空场景。
		if spawn_cooldown <= 0.0:
			spawn_cooldown = _get_spawn_interval()
			_spawn_enemy_ring(_get_spawn_burst_count())
		return

	if current_wave_index >= wave_rows.size():
		current_wave_index = maxi(wave_rows.size() - 1, 0)

	var alive_count: int = _get_runtime_alive_enemy_count(true)
	match wave_flow_state:
		WaveFlowState.PREPARE:
			wave_state_remaining = maxf(wave_state_remaining - delta, 0.0)
			if wave_state_remaining == 0.0:
				_start_current_wave()
			return
		WaveFlowState.TRANSITION:
			wave_state_remaining = maxf(wave_state_remaining - delta, 0.0)
			if wave_state_remaining == 0.0:
				_advance_wave()
			return
		WaveFlowState.COMPLETE:
			return
		_:
			pass

	current_wave_elapsed += delta
	var current_wave_duration: float = _get_current_wave_duration()
	var row: Dictionary = wave_rows[current_wave_index]
	var is_boss_wave := _get_wave_type(row) == WAVE_TYPE_BOSS
	var total: int = int(row.get("total", 0))
	var enemy_id = row.get("enemy_id", "")
	if is_boss_wave:
		enemy_id = _get_wave_boss_id(row, current_wave_index)

	var spawn_interval := _get_wave_spawn_interval(row)
	if spawn_interval > 0.0:
		current_wave_spawn_timer -= delta
		while current_wave_spawn_timer <= 0.0:
			if total > 0 and current_wave_spawned >= total:
				break
			_spawn_enemy(_resolve_enemy_by_id(enemy_id), is_boss_wave)
			if is_boss_wave:
				wave_boss_spawned = true
			current_wave_spawned += 1
			alive_count += 1
			current_wave_spawn_timer += spawn_interval

	alive_count = _process_wave_timed_spawns(alive_count, is_boss_wave)

	# Boss波允许只配置 wave_type=2：若未配置 total/插刷，则默认刷出 1 只 Boss。
	if is_boss_wave and total <= 0 and current_wave_timed_spawns.is_empty() and not wave_boss_spawned:
		_spawn_enemy(_resolve_enemy_by_id(enemy_id), true)
		wave_boss_spawned = true
		alive_count += 1

	var reached_time_limit := current_wave_elapsed >= current_wave_duration
	if reached_time_limit:
		current_wave_elapsed = current_wave_duration

	if is_boss_wave:
		if _is_current_wave_cleared(row, alive_count):
			_start_wave_transition(true)
		elif reached_time_limit:
			_finish_battle_defeat("第%s波 Boss 限时 %.0f 秒未击败" % [_get_wave_display_text(), current_wave_duration])
	else:
		if reached_time_limit:
			_start_wave_transition(false)


func _update_hud(current_health: int, max_health: int, delta: float = 0.0) -> void:
	var should_refresh_combat_info := delta <= 0.0
	if delta > 0.0:
		combat_info_refresh_accumulator += delta
		if combat_info_refresh_accumulator >= COMBAT_INFO_REFRESH_INTERVAL:
			should_refresh_combat_info = true
			combat_info_refresh_accumulator = 0.0
	if should_refresh_combat_info:
		if hud != null:
			hud.set_combat_info_text(_build_combat_info_text())
	_update_resource_bars(current_health, max_health, player.mana, player.max_mana)
	_update_wave_info_hud()
	_update_boss_health_bar()
	_refresh_weapon_growth_panel()

	if not game_over:
		if transient_message_remaining <= 0.0:
			if hud != null:
				hud.hide_message()


func _build_combat_info_text() -> String:
	return CombatInfoFormatterScript.build_text(
		elapsed_time,
		_get_wave_display_text(),
		kill_count,
		current_gold,
		current_exp,
		_get_player_combat_stats()
	)


func _get_player_combat_stats():
	if player == null or not player.has_method("get_combat_stats"):
		return null
	return player.get_combat_stats()


func _update_resource_bars(current_health: int, max_health: int, current_mana: int, max_mana: int) -> void:
	var exp_needed := _get_exp_required_for_level(current_level)
	var exp_progress := _get_current_level_exp_progress()
	if hud != null:
		hud.update_resource_bars(
			current_health,
			max_health,
			current_mana,
			max_mana,
			current_level,
			exp_progress,
			exp_needed,
			current_level >= _get_max_level()
		)


func _apply_hero_header() -> void:
	if selected_hero == null:
		if hud != null:
			hud.clear_hero_header()
		return

	if hud != null:
		hud.set_hero_header(selected_hero.hero_name, current_level, selected_hero.portrait_icon)


func _load_available_heroes() -> void:
	available_heroes = HeroCatalog.load_all_heroes(hero_table_name)
	if available_heroes.is_empty() and hero_table_name != &"heroes":
		available_heroes = HeroCatalog.load_all_heroes(&"heroes")

	if not available_heroes.is_empty():
		var default_index := _find_hero_index(selected_hero_id)
		if default_index == -1:
			selected_hero = available_heroes[0]
			selected_hero_id = selected_hero.hero_id
		else:
			selected_hero = available_heroes[default_index]
	elif selected_hero != null:
		available_heroes.append(selected_hero)
	if selection_state != null:
		selection_state.mark_dirty()


func _load_available_enemies() -> void:
	available_enemies = EnemyCatalog.load_all_enemies()
	normal_enemies.clear()
	elite_enemies.clear()
	boss_enemies.clear()
	enemy_data_by_id.clear()

	for enemy_data in available_enemies:
		var enemy_key := _normalize_optional_id(enemy_data.enemy_id)
		if enemy_key.is_empty():
			enemy_key = String(enemy_data.enemy_id)
		enemy_data_by_id[enemy_key] = enemy_data
		match enemy_data.enemy_type:
			EnemyCatalog.TYPE_BOSS:
				boss_enemies.append(enemy_data)
			EnemyCatalog.TYPE_ELITE:
				elite_enemies.append(enemy_data)
			_:
				normal_enemies.append(enemy_data)


func _rebuild_enemy_pool() -> void:
	_clear_enemy_pool()
	if not enemy_pool_enabled:
		return
	if ENEMY_SCENE == null:
		return
	if available_enemies.is_empty():
		return

	var unique_model_ids: Array[StringName] = []
	for enemy_data in available_enemies:
		if enemy_data == null:
			continue
		var model_key := StringName(String(enemy_data.model_id).strip_edges())
		if String(model_key).is_empty():
			continue
		if not unique_model_ids.has(model_key):
			unique_model_ids.append(model_key)

	if unique_model_ids.is_empty():
		return

	var requested_per_model: int = maxi(enemy_pool_size_per_model, 1)
	var safe_total_cap: int = maxi(enemy_pool_total_cap, unique_model_ids.size())
	var per_model_cap: int = maxi(1, int(floor(float(safe_total_cap) / float(unique_model_ids.size()))))
	var prewarm_count: int = mini(requested_per_model, per_model_cap)
	for model_id in unique_model_ids:
		var seed_data: EnemyData = _find_enemy_seed_data_for_model(model_id)
		var bucket_key: String = _pool_key_for_model(String(model_id))
		if not enemy_pool_available_by_model.has(bucket_key):
			enemy_pool_available_by_model[bucket_key] = []
		for _i in prewarm_count:
			var pooled_enemy: Node2D = _create_enemy_instance(true)
			if pooled_enemy == null:
				continue
			if seed_data != null and pooled_enemy.has_method("apply_enemy_data"):
				pooled_enemy.call("apply_enemy_data", seed_data)
			if pooled_enemy.has_method("ensure_model_ready"):
				pooled_enemy.call("ensure_model_ready")
			if pooled_enemy.has_method("deactivate_to_pool"):
				pooled_enemy.call("deactivate_to_pool", enemy_pool_hidden_position)
			else:
				pooled_enemy.visible = false
				pooled_enemy.global_position = enemy_pool_hidden_position
				pooled_enemy.set_process(false)
				pooled_enemy.set_physics_process(false)
			_add_enemy_to_pool_bucket(bucket_key, pooled_enemy)


func _clear_enemy_pool() -> void:
	for enemy_node in enemy_pool_nodes:
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		enemy_node.queue_free()
	enemy_pool_nodes.clear()
	enemy_pool_available_by_model.clear()


func _pool_key_for_model(model_id_text: String) -> String:
	var key: String = model_id_text.strip_edges()
	if key.is_empty():
		return "__generic__"
	return key


func _add_enemy_to_pool_bucket(bucket_key: String, enemy_node: Node2D) -> void:
	if enemy_node == null:
		return
	if not enemy_pool_available_by_model.has(bucket_key):
		enemy_pool_available_by_model[bucket_key] = []
	var bucket: Array = enemy_pool_available_by_model.get(bucket_key, [])
	if not bucket.has(enemy_node):
		bucket.append(enemy_node)
	enemy_pool_available_by_model[bucket_key] = bucket


func _pop_enemy_from_pool_bucket(bucket_key: String) -> Node2D:
	var bucket: Array = enemy_pool_available_by_model.get(bucket_key, [])
	while not bucket.is_empty():
		var candidate: Variant = bucket.pop_back()
		if candidate is Node2D and is_instance_valid(candidate):
			enemy_pool_available_by_model[bucket_key] = bucket
			return candidate as Node2D
	enemy_pool_available_by_model[bucket_key] = bucket
	return null


func _find_enemy_seed_data_for_model(model_id: StringName) -> EnemyData:
	var target_model_id: String = String(model_id).strip_edges()
	if target_model_id.is_empty():
		return null
	for enemy_data in available_enemies:
		if enemy_data == null:
			continue
		if String(enemy_data.model_id).strip_edges() == target_model_id:
			return enemy_data
	return null


func _create_enemy_instance(use_pool_mode: bool) -> Node2D:
	if ENEMY_SCENE == null:
		return null
	var enemy = ENEMY_SCENE.instantiate()
	if enemy == null:
		return null
	if enemy is not Node2D:
		enemy.queue_free()
		return null

	var enemy_node: Node2D = enemy as Node2D
	enemy_node.set("player", player)
	if enemy_node.has_signal("died"):
		enemy_node.connect("died", Callable(self, "_on_enemy_died"))
	if enemy_node.has_signal("damaged"):
		enemy_node.connect("damaged", Callable(self, "_on_enemy_damaged"))
	if enemy_node.has_method("set_pool_mode"):
		enemy_node.call("set_pool_mode", use_pool_mode)
	if use_pool_mode and enemy_node.has_signal("despawn_requested"):
		enemy_node.connect("despawn_requested", Callable(self, "_on_enemy_despawn_requested"))

	enemies.add_child(enemy_node)
	if use_pool_mode:
		enemy_pool_nodes.append(enemy_node)
	return enemy_node


func _acquire_enemy_instance_for_data(enemy_data: EnemyData) -> Node2D:
	var model_key: String = "__generic__"
	if enemy_data != null:
		model_key = _pool_key_for_model(String(enemy_data.model_id))

	if enemy_pool_enabled:
		var pooled_enemy: Node2D = _pop_enemy_from_pool_bucket(model_key)
		if pooled_enemy != null:
			return pooled_enemy

		var expanded_enemy: Node2D = _create_enemy_instance(true)
		if expanded_enemy != null:
			return expanded_enemy

	return _create_enemy_instance(false)


func _release_enemy_to_pool(enemy_node: Node2D) -> void:
	if enemy_node == null or not is_instance_valid(enemy_node):
		return
	if not enemy_pool_nodes.has(enemy_node):
		enemy_node.queue_free()
		_invalidate_runtime_enemy_snapshot()
		return
	if enemy_node.has_method("deactivate_to_pool"):
		enemy_node.call("deactivate_to_pool", enemy_pool_hidden_position)
	else:
		enemy_node.visible = false
		enemy_node.global_position = enemy_pool_hidden_position
		enemy_node.set_process(false)
		enemy_node.set_physics_process(false)
	var bucket_key: String = _pool_key_for_model(String(enemy_node.get("model_id")))
	_add_enemy_to_pool_bucket(bucket_key, enemy_node)
	_invalidate_runtime_enemy_snapshot()


func _on_enemy_despawn_requested(enemy_node: Node2D) -> void:
	_release_enemy_to_pool(enemy_node)


func _get_data_table_node() -> Node:
	if data_table_provider == null:
		data_table_provider = DataTableProviderScript.new()
	return data_table_provider.get_data_table_node(get_tree())


func _load_wave_rows() -> void:
	wave_rows.clear()

	var data_table := _get_data_table_node()
	if data_table == null or not data_table.has_table(&"waves"):
		return

	var raw_rows: Array = data_table.call("get_all", &"waves")
	for raw_row in raw_rows:
		if not (raw_row is Dictionary):
			continue
		var row: Dictionary = raw_row
		if row.is_empty():
			continue
		if int(row.get("wave", 0)) <= 0:
			continue
		wave_rows.append(row)

	wave_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("wave", 0)) < int(b.get("wave", 0))
	)
	_validate_md04_wave_rows()


func _validate_md04_wave_rows(target_wave_count: int = MD04_TARGET_WAVE_COUNT) -> void:
	if wave_rows.is_empty():
		push_warning("MD-04 波次校验失败：waves 表为空。")
		return

	var safe_target := maxi(target_wave_count, 1)
	var issues: Array[String] = []
	if wave_rows.size() < safe_target:
		issues.append("仅配置了 %d 波，低于目标 %d 波。" % [wave_rows.size(), safe_target])

	var inspect_count := mini(wave_rows.size(), safe_target)
	for index in inspect_count:
		var row: Dictionary = wave_rows[index]
		var wave_number := int(row.get("wave", index + 1))
		var expected_wave_number := index + 1
		if wave_number != expected_wave_number:
			issues.append("第%d行波次编号为 %d，应为 %d（建议前%d波连续编号）。" % [index + 1, wave_number, expected_wave_number, safe_target])

		var wave_label := "第%d波" % wave_number
		var raw_wave_type = row.get("wave_type", null)
		if raw_wave_type == null or str(raw_wave_type).strip_edges().is_empty():
			issues.append("%s 缺少 wave_type。" % wave_label)
		var wave_type := _get_wave_type(row)
		var main_spawn_total := int(row.get("total", 0))
		var main_spawn_interval := _get_wave_spawn_interval(row)

		if wave_type == WAVE_TYPE_BOSS:
			var boss_enemy_id_text := _normalize_optional_id(row.get("enemy_id", ""))
			if not boss_enemy_id_text.is_empty() and not enemy_data_by_id.has(boss_enemy_id_text):
				issues.append("%s enemy_id=%s 在 enemies 表中不存在。" % [wave_label, boss_enemy_id_text])
			if boss_enemy_id_text.is_empty() and available_enemies.is_empty():
				issues.append("%s enemy_id 为空且默认怪物池为空，无法生成 Boss。" % wave_label)
		else:
			var enemy_id_text := _normalize_optional_id(row.get("enemy_id", ""))
			if enemy_id_text.is_empty():
				issues.append("%s 缺少 enemy_id。" % wave_label)
			elif not enemy_data_by_id.has(enemy_id_text):
				issues.append("%s enemy_id=%s 在 enemies 表中不存在。" % [wave_label, enemy_id_text])
		if main_spawn_total > 0 and main_spawn_interval <= 0.0:
			issues.append("%s total=%d 但未配置有效的 spawn_interval/spawn_rate。" % [wave_label, main_spawn_total])

		var special_enemy_id := _normalize_optional_id(row.get("special_enemy_id", ""))
		var has_special_id := not special_enemy_id.is_empty()
		var has_special_time := row.get("special_spawn_time", null) != null
		var has_special_count := row.get("special_spawn_count", null) != null
		if has_special_id or has_special_time or has_special_count:
			if not has_special_id:
				issues.append("%s 插刷配置缺少 special_enemy_id。" % wave_label)
			elif not enemy_data_by_id.has(special_enemy_id):
				issues.append("%s special_enemy_id=%s 在 enemies 表中不存在。" % [wave_label, special_enemy_id])

			if not has_special_time:
				issues.append("%s 插刷配置缺少 special_spawn_time。" % wave_label)
			elif float(row.get("special_spawn_time", 0.0)) < 0.0:
				issues.append("%s special_spawn_time 不能小于 0。" % wave_label)

			if not has_special_count:
				issues.append("%s 插刷配置缺少 special_spawn_count。" % wave_label)
			elif int(row.get("special_spawn_count", 0)) <= 0:
				issues.append("%s special_spawn_count 必须大于 0。" % wave_label)

	if issues.is_empty():
		print("MD-04 前%d波表驱动校验通过：已加载 %d 波。" % [safe_target, wave_rows.size()])
		return

	push_warning(
		"MD-04 前%d波表驱动校验发现 %d 项问题：\n- %s"
		% [safe_target, issues.size(), "\n- ".join(issues)]
	)


func _load_card_rows() -> void:
	card_rows = _load_table_rows(&"cards", "tier")


func _try_spawn_card_choice_pickup_from_enemy_death(world_position: Vector2, reward_info: Dictionary) -> void:
	if _is_card_choice_drop_boss_reward(reward_info):
		return
	if player_respawning or battle_finished:
		return
	if card_rows.is_empty():
		return
	if player == null or not is_instance_valid(player):
		return
	if card_choice_drop_runtime == null:
		card_choice_drop_runtime = CardChoiceDropRuntimeScript.new()
	var roll_count := card_choice_drop_runtime.consume_due_rolls(elapsed_time)
	if roll_count <= 0:
		return
	for _i in range(roll_count):
		_roll_card_choice_pickup_at(world_position)


func _roll_card_choice_pickup_at(world_position: Vector2) -> void:
	if card_choice_drop_runtime == null:
		card_choice_drop_runtime = CardChoiceDropRuntimeScript.new()
	if card_choice_drop_runtime.roll_succeeds(randf() * 100.0):
		_spawn_card_choice_pickup_at(world_position)


func _is_card_choice_drop_boss_reward(reward_info: Dictionary) -> bool:
	if int(reward_info.get("enemy_type", EnemyCatalog.TYPE_NORMAL)) == EnemyCatalog.TYPE_BOSS:
		return true
	return _variant_flag_enabled(reward_info.get("is_boss", false))


func _spawn_card_choice_pickup_at(world_position: Vector2) -> void:
	if pickups == null or PICKUP_SCENE == null:
		_grant_card_choice_opportunity(world_position)
		return
	var spawn_position := world_position + Vector2(0.0, -8.0)
	var impulse := Vector2(randf_range(-18.0, 18.0), randf_range(-34.0, -12.0))
	_spawn_single_pickup(spawn_position, CARD_CHOICE_PICKUP_REWARD_TYPE, 1, impulse)


func _grant_card_choice_opportunity(world_position: Vector2) -> void:
	queued_card_choice_pickups += 1
	_spawn_card_pickup_burst_effect(world_position + Vector2(0, -4), 1.0)
	_request_queued_card_choice_overlay()


func _load_weapon_rows() -> void:
	weapon_rows = _load_table_rows(&"weapons", "quality")


func _load_weapon_growth_rows() -> void:
	if weapon_growth_runtime == null:
		weapon_growth_runtime = WeaponGrowthRuntimeScript.new()
	weapon_growth_runtime.setup_rows(_load_table_rows(WEAPON_GROWTH_TABLE_NAME, "step"))


func _load_bloodline_rows() -> void:
	var raw_rows := _load_table_rows(BLOODLINE_TABLE_NAME, "sort_order")
	bloodline_rows.clear()
	bloodline_rows_by_id.clear()
	for row in raw_rows:
		if _is_table_row_banned(row):
			continue
		bloodline_rows.append(row)
		var bloodline_id := str(row.get("id", "")).strip_edges()
		if bloodline_id.is_empty():
			continue
		bloodline_rows_by_id[bloodline_id] = row


func _load_template_bloodline_option_rows() -> void:
	template_bloodline_option_rows = _load_table_rows(TEMPLATE_BLOODLINE_OPTION_TABLE_NAME, "sort_order")
	_rebuild_template_bloodline_option_index()
	if selection_state != null:
		selection_state.mark_dirty()


func _rebuild_template_bloodline_option_index() -> void:
	if template_bloodline_option_index == null:
		template_bloodline_option_index = TemplateBloodlineOptionIndexScript.new()
	template_bloodline_option_index.rebuild(template_bloodline_option_rows)


func _load_kill_reward_rows() -> void:
	kill_reward_rows = _load_table_rows(&"kill_rewards", "threshold")


func _load_levelup_rows() -> void:
	if level_runtime == null:
		level_runtime = LevelRuntimeScript.new()
	level_runtime.setup_rows(_load_table_rows(&"levelup", "level"))


func _load_runtime_constant_settings() -> void:
	card_choice_pickup_interval_seconds = maxf(
		_load_runtime_constant_float(RUNTIME_CONSTANT_CARD_CHOICE_COOLDOWN_ID, card_choice_pickup_interval_seconds),
		0.0
	)
	card_choice_pickup_initial_chance_percent = clampf(
		_load_runtime_constant_float(RUNTIME_CONSTANT_CARD_CHOICE_INITIAL_CHANCE_ID, card_choice_pickup_initial_chance_percent),
		0.0,
		100.0
	)
	card_choice_pickup_chance_increase_percent = maxf(
		_load_runtime_constant_float(RUNTIME_CONSTANT_CARD_CHOICE_CHANCE_INCREASE_ID, card_choice_pickup_chance_increase_percent),
		0.0
	)
	if card_choice_drop_runtime == null:
		card_choice_drop_runtime = CardChoiceDropRuntimeScript.new()
	card_choice_drop_runtime.configure(
		card_choice_pickup_interval_seconds,
		card_choice_pickup_initial_chance_percent,
		card_choice_pickup_chance_increase_percent
	)


func _load_runtime_constant_float(row_id: String, fallback_value: float) -> float:
	var row: Dictionary = _load_table_row(RUNTIME_CONSTANT_TABLE_NAME, row_id)
	if row.is_empty():
		return fallback_value
	return TableValueUtilsScript.float_or(row.get("value", fallback_value), fallback_value)


func _reset_card_choice_pickup_runtime_state() -> void:
	if card_choice_drop_runtime == null:
		card_choice_drop_runtime = CardChoiceDropRuntimeScript.new()
	card_choice_drop_runtime.reset_runtime()
	queued_card_choice_pickups = 0
	card_choice_overlay_request_pending = false


func _reset_wave_runtime_state() -> void:
	current_wave_index = 0
	current_wave_spawned = 0
	current_wave_spawn_timer = 0.0
	wave_boss_spawned = false
	current_wave_elapsed = 0.0
	wave_state_remaining = 0.0
	current_wave_timed_spawns.clear()
	if wave_rows.is_empty():
		wave_flow_state = WaveFlowState.ACTIVE
		return
	_enter_wave_prepare(true)


func _advance_wave() -> void:
	if wave_rows.is_empty():
		return
	if current_wave_index < wave_rows.size() - 1:
		current_wave_index += 1
		_enter_wave_prepare(false)
		return

	wave_flow_state = WaveFlowState.COMPLETE
	wave_state_remaining = 0.0
	current_wave_elapsed = _get_current_wave_duration()
	_show_wave_banner("全部波次已完成", "继续清理残余敌人", wave_banner_seconds + 0.4)


func _resolve_enemy_by_id(enemy_id) -> EnemyData:
	var key: String = _normalize_optional_id(enemy_id)
	if key.is_empty():
		return _pick_enemy_for_spawn()

	var mapped: EnemyData = enemy_data_by_id.get(key)
	if mapped != null:
		return mapped

	# 兼容旧波次表里的历史ID，避免你没改表时直接刷不出来。
	var legacy_map := {
		"slime_small": "1",
		"bat_swarm": "2",
		"armored_brute": "3",
		"slime_king": "4",
	}
	if legacy_map.has(key):
		var legacy_key: String = legacy_map[key]
		var legacy_enemy: EnemyData = enemy_data_by_id.get(legacy_key)
		if legacy_enemy != null:
			return legacy_enemy

	return _pick_enemy_for_spawn()


func _pick_enemy_for_spawn() -> EnemyData:
	if available_enemies.is_empty():
		return null

	var can_spawn_elite: bool = elapsed_time >= 25.0
	var has_alive_boss: bool = not _get_runtime_active_boss_nodes().is_empty()
	var can_spawn_boss: bool = elapsed_time >= 90.0 and not has_alive_boss
	var spawn_roll: float = randf()

	if can_spawn_boss and not boss_enemies.is_empty() and spawn_roll <= 0.06:
		return _pick_random_enemy_from_pool(boss_enemies)
	if can_spawn_elite and not elite_enemies.is_empty() and spawn_roll <= 0.28:
		return _pick_random_enemy_from_pool(elite_enemies)
	if not normal_enemies.is_empty():
		return _pick_random_enemy_from_pool(normal_enemies)
	if can_spawn_elite and not elite_enemies.is_empty():
		return _pick_random_enemy_from_pool(elite_enemies)
	if can_spawn_boss and not boss_enemies.is_empty():
		return _pick_random_enemy_from_pool(boss_enemies)

	return _pick_random_enemy_from_pool(available_enemies)


func _pick_random_enemy_from_pool(pool: Array[EnemyData]) -> EnemyData:
	if pool.is_empty():
		return null
	var index: int = randi() % pool.size()
	return pool[index]


func _ensure_selection_state() -> void:
	if selection_state == null:
		selection_state = SelectionStateScript.new()


func _resolve_selection_preview_model_id(hero: HeroData) -> StringName:
	if hero == null:
		return &""
	var preview_text: String = str(hero.preview_model_id).strip_edges()
	if not preview_text.is_empty():
		return hero.preview_model_id
	return hero.model_id


func _build_selection_preview_signature(hero: HeroData) -> String:
	if hero == null:
		return ""
	var preview_model_id := _resolve_selection_preview_model_id(hero)
	var body_color := hero.body_color.to_html(true)
	var accent_color := hero.accent_color.to_html(true)
	return "%s|%s|%s" % [String(preview_model_id), body_color, accent_color]


func _build_selection_skill_signature(hero: HeroData) -> String:
	if hero == null:
		return "__empty__"
	var icon_q := str(hero.q_skill_icon.get_rid()) if hero.q_skill_icon != null else ""
	var icon_w := str(hero.w_skill_icon.get_rid()) if hero.w_skill_icon != null else ""
	var icon_r := str(hero.r_skill_icon.get_rid()) if hero.r_skill_icon != null else ""
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		hero.q_skill_name,
		hero.q_skill_description,
		icon_q,
		hero.w_skill_name,
		hero.w_skill_description,
		icon_w,
		hero.r_skill_name,
		hero.r_skill_description,
		icon_r,
	]


func _build_hero_selection_buttons() -> void:
	_ensure_selection_state()
	if selection_overlay == null:
		return

	selection_overlay.clear_template_grid()
	selection_overlay.clear_bloodline_grid()

	hero_button_nodes.clear()
	bloodline_button_nodes.clear()
	var hero_card_width := selection_overlay.get_template_card_width(SELECTION_GRID_COLUMNS, 80.0, 100.0)

	for i in available_heroes.size():
		var hero := available_heroes[i]
		var button := _create_selection_card_button(
			hero.hero_name,
			hero.portrait_icon,
			"%s\n%s" % [hero.hero_name, str(hero.hero_description).strip_edges()],
			Vector2(hero_card_width, hero_card_width),
			hero_card_width * 0.94,
			false
		)
		button.pressed.connect(_on_template_button_pressed.bind(i))
		hero_button_nodes.append(button)
	selection_overlay.rebuild_template_grid(hero_button_nodes)
	if selection_state != null:
		selection_state.mark_dirty()


func _start_hero_selection() -> void:
	_ensure_selection_state()
	selection_active = true
	selection_time_remaining = 0.0
	_hide_card_choice_overlay(false)
	_hide_card_collection(false)
	if card_collection_button != null:
		card_collection_button.visible = false
	if hud != null:
		hud.show_selection_mode()
	if selection_overlay != null:
		selection_overlay.show_overlay()
	if wave_info_panel != null:
		wave_info_panel.visible = false
	if boss_health_panel != null:
		boss_health_panel.visible = false
	_hide_wave_banner()
	_hide_death_overlay()
	_hide_victory_overlay()
	_hide_attributes_panel()

	var default_index := _find_hero_index(selected_hero_id)
	selection_state.reset(default_index if default_index != -1 else 0)
	selection_preview_signature = ""
	selection_last_skill_signature = ""
	_refresh_hero_selection_ui()
	call_deferred("_refresh_hero_selection_ui")


func _process_hero_selection(_delta: float) -> void:
	if available_heroes.is_empty():
		selection_active = false
		selected_hero = selected_hero if selected_hero != null else HeroData.new()
		_begin_battle_with_hero(selected_hero, {})
		return


func _step_template_selection(direction: int) -> void:
	_ensure_selection_state()
	if available_heroes.is_empty():
		return

	selection_state.index = posmod(selection_state.index + direction, available_heroes.size())
	selection_state.bloodline_index = 0
	selection_state.ui_dirty = true
	selection_preview_should_replay_intro = true
	_refresh_hero_selection_ui()


func _step_bloodline_selection(direction: int) -> void:
	_ensure_selection_state()
	var option_rows := _get_current_template_bloodline_options()
	if option_rows.is_empty():
		return

	selection_state.bloodline_index = posmod(selection_state.bloodline_index + direction, option_rows.size())
	selection_preview_should_replay_intro = true
	_refresh_hero_selection_ui()


func _confirm_current_hero_selection() -> void:
	_ensure_selection_state()
	if available_heroes.is_empty():
		return

	_ensure_valid_bloodline_selection()
	var template_hero := available_heroes[selection_state.index]
	var bloodline_option := _get_current_bloodline_option()
	var bloodline_row := _get_bloodline_row_for_option(bloodline_option)
	var runtime_hero := _build_runtime_selected_hero(template_hero, bloodline_option, bloodline_row)
	_begin_battle_with_hero(runtime_hero, bloodline_option)


func _on_template_button_pressed(hero_index: int) -> void:
	_ensure_selection_state()
	selection_state.set_template(hero_index)
	selection_preview_should_replay_intro = true
	_refresh_hero_selection_ui()


func _on_bloodline_button_pressed(option_index: int) -> void:
	_ensure_selection_state()
	selection_state.set_bloodline(option_index)
	selection_preview_should_replay_intro = true
	_refresh_hero_selection_ui()


func _refresh_hero_selection_ui() -> void:
	_ensure_selection_state()
	if available_heroes.is_empty():
		if selection_overlay != null:
			selection_overlay.set_summary_texts("暂无模板数据", "请先配置 heroes#英雄.xlsx。", "", "")
			selection_overlay.set_description_visible(false)
			selection_overlay.set_skill_tooltip("血脉效果", "Q / W / R 展示字段会从血脉表读取。")
			selection_overlay.set_confirm_disabled(true)
		_clear_selection_preview_model()
		if selection_overlay != null:
			selection_overlay.clear_bloodline_grid()
		bloodline_button_nodes.clear()
		if selection_state != null:
			selection_state.mark_dirty()
		selection_preview_signature = ""
		selection_last_skill_signature = ""
		_update_selection_skill_buttons(null)
		return

	selection_state.index = clampi(selection_state.index, 0, available_heroes.size() - 1)
	_ensure_valid_bloodline_selection()
	var hero := available_heroes[selection_state.index]
	var option_rows := _get_current_template_bloodline_options()
	var template_id := str(hero.hero_id).strip_edges()
	var should_rebuild_bloodline_buttons := selection_state.should_rebuild_bloodline_buttons(template_id, option_rows.size())
	var current_option := _get_current_bloodline_option()
	var current_bloodline := _get_bloodline_row_for_option(current_option)
	var preview_hero := _build_runtime_selected_hero(hero, current_option, current_bloodline)
	var preview_stats = AttributeSystemScript.build_hero_stats(preview_hero)
	if selection_overlay != null:
		selection_overlay.set_confirm_disabled(current_option.is_empty())
	var bloodline_name := _get_bloodline_option_display_name(current_option, current_bloodline)
	var stats_text := "生命 %d\n法力 %d\n攻击 %d\n移速 %.0f\n攻速 %.2fs\n射程 %.0f\n力量 %.0f  敏捷 %.0f  智力 %.0f" % [
		preview_stats.get_stat_int(&"max_health", preview_hero.starting_max_health),
		preview_stats.get_stat_int(&"max_mana", preview_hero.starting_max_mana),
		preview_stats.get_stat_int(&"attack_power", preview_hero.starting_attack_damage),
		preview_stats.get_stat(&"move_speed", preview_hero.starting_move_speed),
		preview_stats.get_stat(&"final_attack_interval", preview_hero.starting_attack_interval),
		preview_stats.get_stat(&"attack_range", preview_hero.starting_attack_range),
		preview_hero.base_str,
		preview_hero.base_agi,
		preview_hero.base_int,
	]

	if selection_overlay != null:
		selection_overlay.set_summary_texts(
			hero.hero_name,
			"血脉：%s" % (bloodline_name if not bloodline_name.is_empty() else "未配置"),
			"主属性：%s" % _get_primary_attr_display_name(hero.primary_attr),
			stats_text
		)
		selection_overlay.set_description_visible(false)
	_update_selection_preview_model(preview_hero, selection_preview_should_replay_intro)
	selection_preview_should_replay_intro = false
	if should_rebuild_bloodline_buttons:
		_rebuild_bloodline_selection_buttons(option_rows)
		selection_state.mark_bloodline_buttons_rebuilt(template_id, option_rows.size())
	_refresh_bloodline_button_styles(option_rows)
	_update_selection_skill_buttons(preview_hero)
	_reset_selection_skill_hover_text(preview_hero, current_option, current_bloodline)

	for i in hero_button_nodes.size():
		var button := hero_button_nodes[i]
		var is_selected := i == selection_state.index
		var border_color := Color(1.0, 0.86, 0.32, 1.0) if is_selected else Color(0.42, 0.48, 0.44, 1.0)
		var background_color := Color(0.2, 0.19, 0.14, 0.98) if is_selected else Color(0.1, 0.12, 0.11, 0.92)
		_apply_selection_card_button_style(button, border_color, background_color, 4 if is_selected else 2)


func _rebuild_bloodline_selection_buttons(option_rows: Array[Dictionary]) -> void:
	if selection_overlay == null:
		return

	selection_overlay.clear_bloodline_grid()
	bloodline_button_nodes.clear()
	var bloodline_card_width := selection_overlay.get_bloodline_card_width(SELECTION_GRID_COLUMNS, 90.0, 110.0)
	var bloodline_card_height := bloodline_card_width + 16.0

	for i in option_rows.size():
		var option_row := option_rows[i]
		var bloodline_row := _get_bloodline_row_for_option(option_row)
		var icon_texture := _resolve_bloodline_icon_texture(option_row, bloodline_row)
		var button := _create_selection_card_button(
			_get_bloodline_option_display_name(option_row, bloodline_row),
			icon_texture,
			_build_bloodline_option_tooltip(option_row, bloodline_row),
			Vector2(bloodline_card_width, bloodline_card_height),
			bloodline_card_width * 0.60,
			true
		)
		button.pressed.connect(_on_bloodline_button_pressed.bind(i))
		bloodline_button_nodes.append(button)
	selection_overlay.rebuild_bloodline_grid(bloodline_button_nodes)


func _refresh_bloodline_button_styles(option_rows: Array[Dictionary]) -> void:
	if bloodline_button_nodes.is_empty():
		return
	for i in bloodline_button_nodes.size():
		if i >= option_rows.size():
			continue
		var button := bloodline_button_nodes[i]
		var is_selected := i == selection_state.bloodline_index
		var option_row := option_rows[i]
		var bloodline_row := _get_bloodline_row_for_option(option_row)
		var accent_color := _get_bloodline_option_color(option_row, bloodline_row)
		var selected_border := Color(0.96, 0.80, 0.36, 0.88)
		var border_color := selected_border if is_selected else accent_color.darkened(0.18)
		var background_color := Color(0.18, 0.15, 0.11, 0.96) if is_selected else Color(0.1, 0.11, 0.09, 0.94)
		_apply_selection_card_button_style(button, border_color, background_color, 3 if is_selected else 2)


func _ensure_valid_bloodline_selection() -> void:
	_ensure_selection_state()
	var option_rows := _get_current_template_bloodline_options()
	if option_rows.is_empty():
		selection_state.bloodline_index = 0
		selection_state.selected_template_bloodline_option = {}
		return

	selection_state.bloodline_index = clampi(selection_state.bloodline_index, 0, option_rows.size() - 1)
	selection_state.selected_template_bloodline_option = option_rows[selection_state.bloodline_index]


func _get_current_template_bloodline_options() -> Array[Dictionary]:
	_ensure_selection_state()
	if available_heroes.is_empty():
		return []

	var hero: HeroData = available_heroes[selection_state.index]
	var template_id: String = str(hero.hero_id).strip_edges()
	if template_id.is_empty() and hero != null:
		template_id = str(hero.hero_name).strip_edges()
	if template_id.is_empty():
		return []

	var options_from_template: Array[Dictionary] = _build_template_bloodline_options_from_hero(hero)
	if not options_from_template.is_empty():
		return options_from_template

	return _build_default_bloodline_options()


func _build_template_bloodline_options_from_hero(hero: HeroData) -> Array[Dictionary]:
	var option_rows: Array[Dictionary] = []
	if hero == null:
		return option_rows
	if hero.bloodline_ids.is_empty():
		return option_rows

	var template_id: String = str(hero.hero_id).strip_edges()
	if template_id.is_empty():
		template_id = str(hero.hero_name).strip_edges()
	var dedupe: Dictionary = {}
	var option_order: int = 0
	for raw_id in hero.bloodline_ids:
		var bloodline_id: String = _normalize_bloodline_id_token(raw_id)
		if bloodline_id.is_empty() or dedupe.has(bloodline_id):
			continue
		dedupe[bloodline_id] = true
		var bloodline_row: Dictionary = bloodline_rows_by_id.get(bloodline_id, {})
		if bloodline_row.is_empty():
			continue
		option_order += 1
		option_rows.append(_build_bloodline_option_row(template_id, bloodline_row, option_order * 10))
	return option_rows


func _build_default_bloodline_options() -> Array[Dictionary]:
	var option_rows: Array[Dictionary] = []
	var template_id: String = "default"
	if not available_heroes.is_empty():
		var hero: HeroData = available_heroes[selection_state.index]
		template_id = str(hero.hero_id).strip_edges()
		if template_id.is_empty():
			template_id = str(hero.hero_name).strip_edges()

	var option_order: int = 0
	for bloodline_row in bloodline_rows:
		var bloodline_id: String = _normalize_bloodline_id_token(bloodline_row.get("id", ""))
		if bloodline_id.is_empty():
			continue
		option_order += 1
		option_rows.append(_build_bloodline_option_row(template_id, bloodline_row, option_order * 10))
	return option_rows


func _build_bloodline_option_row(template_id: String, bloodline_row: Dictionary, fallback_sort_order: int) -> Dictionary:
	var bloodline_id: String = _normalize_bloodline_id_token(bloodline_row.get("id", ""))
	var sort_order_value: int = int(bloodline_row.get("sort_order", fallback_sort_order))
	return {
		"id": "%s_%s" % [template_id, bloodline_id],
		"template_id": template_id,
		"bloodline_id": bloodline_id,
		"sort_order": sort_order_value,
		"selection_name": _get_optional_text(bloodline_row.get("name", "")),
		"selection_description": _get_optional_text(bloodline_row.get("description", "")),
		"skill_group_id": _get_optional_text(bloodline_row.get("skill_group_id", "")),
		"skill_group_name": _get_optional_text(bloodline_row.get("skill_group_name", "")),
		"model_id_override": _get_optional_text(bloodline_row.get("model_id", "")),
		"visual_label": _get_optional_text(bloodline_row.get("visual_label", "")),
		"ui_color": _get_optional_text(bloodline_row.get("ui_color", "")),
		"icon": _get_optional_text(bloodline_row.get("icon", "")),
		"enabled": true,
		"source": "heroes.bloodline_ids",
	}


func _normalize_bloodline_id_token(raw_value: Variant) -> String:
	var token: String = str(raw_value).strip_edges()
	if token == "<null>":
		return ""
	return token


func _get_current_bloodline_option() -> Dictionary:
	var option_rows := _get_current_template_bloodline_options()
	if option_rows.is_empty():
		return {}
	var clamped_index := clampi(selection_state.bloodline_index, 0, option_rows.size() - 1)
	return option_rows[clamped_index]


func _get_bloodline_row_for_option(option_row: Dictionary) -> Dictionary:
	if option_row.is_empty():
		return {}
	var bloodline_id: String = _normalize_bloodline_id_token(option_row.get("bloodline_id", ""))
	if bloodline_id.is_empty():
		bloodline_id = _normalize_bloodline_id_token(option_row.get("id", ""))
	if bloodline_id.is_empty():
		return {}
	return bloodline_rows_by_id.get(bloodline_id, {})


func _get_bloodline_option_display_name(option_row: Dictionary, bloodline_row: Dictionary) -> String:
	var option_name := str(option_row.get("selection_name", "")).strip_edges()
	if not option_name.is_empty():
		return option_name
	return str(bloodline_row.get("name", bloodline_row.get("id", "未命名血脉"))).strip_edges()


func _get_bloodline_option_skill_group_name(option_row: Dictionary, bloodline_row: Dictionary = {}) -> String:
	var display_name := str(option_row.get("skill_group_name", "")).strip_edges()
	if not display_name.is_empty():
		return display_name
	var bloodline_display_name: String = str(bloodline_row.get("skill_group_name", "")).strip_edges()
	if not bloodline_display_name.is_empty():
		return bloodline_display_name
	var option_group_id: String = str(option_row.get("skill_group_id", "")).strip_edges()
	if not option_group_id.is_empty():
		return option_group_id
	var bloodline_group_id: String = str(bloodline_row.get("skill_group_id", "")).strip_edges()
	if not bloodline_group_id.is_empty():
		return bloodline_group_id
	return str(bloodline_row.get("r_skill_name", "")).strip_edges()


func _build_bloodline_option_tooltip(option_row: Dictionary, bloodline_row: Dictionary) -> String:
	var lines: Array[String] = []
	var description := str(option_row.get("selection_description", bloodline_row.get("description", ""))).strip_edges()
	if not description.is_empty():
		lines.append(description)
	return "\n".join(lines)


func _build_runtime_selected_hero(template_hero: HeroData, option_row: Dictionary, bloodline_row: Dictionary) -> HeroData:
	if template_hero == null:
		return null

	var runtime_hero := template_hero.duplicate(true) as HeroData
	if runtime_hero == null:
		return template_hero

	var model_text: String = _get_optional_text(option_row.get("base_model_id_override", runtime_hero.model_id))
	if model_text.is_empty():
		model_text = _get_optional_text(runtime_hero.model_id)
	var bloodline_model_text: String = _get_optional_text(option_row.get("model_id_override", bloodline_row.get("model_id", "")))
	var bloodline_model_valid := not bloodline_model_text.is_empty() and _has_visual_model_profile(bloodline_model_text)
	if bloodline_model_valid:
		# 统一规则：血脉模型优先，确保与 F6 生成配置一致。
		if model_text.is_empty():
			model_text = bloodline_model_text
	if not model_text.is_empty() and not _has_visual_model_profile(model_text):
		if bloodline_model_valid:
			model_text = bloodline_model_text
	if not model_text.is_empty():
		runtime_hero.model_id = StringName(model_text)

	var preview_text: String = _get_optional_text(option_row.get("base_preview_model_id_override", runtime_hero.preview_model_id))
	if preview_text.is_empty():
		preview_text = _get_optional_text(runtime_hero.preview_model_id)
	if preview_text.is_empty():
		preview_text = _get_optional_text(option_row.get("preview_model_id_override", bloodline_row.get("model_id", "")))
	if bloodline_model_valid:
		preview_text = bloodline_model_text
	if preview_text.is_empty():
		preview_text = _get_optional_text(runtime_hero.model_id)
	if not preview_text.is_empty():
		runtime_hero.preview_model_id = StringName(preview_text)

	var normalized_primary_attr: StringName = _resolve_bloodline_primary_attr_id(option_row, bloodline_row, runtime_hero)
	if String(normalized_primary_attr).strip_edges().is_empty():
		normalized_primary_attr = _normalize_primary_attr_id(runtime_hero.primary_attr)
	if not String(normalized_primary_attr).strip_edges().is_empty():
		runtime_hero.primary_attr = normalized_primary_attr

	_apply_bloodline_attribute_overrides(runtime_hero, option_row, bloodline_row)
	return runtime_hero


func _normalize_primary_attr_id(attr_id: StringName) -> StringName:
	match str(attr_id).strip_edges().to_lower():
		"str":
			return &"str"
		"agi":
			return &"agi"
		"int":
			return &"int"
	return &""


func _resolve_bloodline_primary_attr_id(option_row: Dictionary, bloodline_row: Dictionary, runtime_hero: HeroData) -> StringName:
	var direct_attr_text: String = _get_optional_text(
		option_row.get("primary_attr_override", bloodline_row.get("primary_attr", runtime_hero.primary_attr))
	).to_lower()
	var direct_attr_id: StringName = _normalize_primary_attr_id(StringName(direct_attr_text))
	if not String(direct_attr_id).strip_edges().is_empty():
		return direct_attr_id

	# 兼容删掉 primary_attr 字段后的新表：根据三维基础属性自动推导主属性。
	var base_str_value: float = _resolve_bloodline_float_value(option_row, "base_str_override", bloodline_row, "base_str", runtime_hero.base_str)
	var base_agi_value: float = _resolve_bloodline_float_value(option_row, "base_agi_override", bloodline_row, "base_agi", runtime_hero.base_agi)
	var base_int_value: float = _resolve_bloodline_float_value(option_row, "base_int_override", bloodline_row, "base_int", runtime_hero.base_int)
	if base_str_value >= base_agi_value and base_str_value >= base_int_value:
		return &"str"
	if base_agi_value >= base_int_value:
		return &"agi"
	return &"int"


func _apply_bloodline_attribute_overrides(runtime_hero: HeroData, option_row: Dictionary, bloodline_row: Dictionary) -> void:
	runtime_hero.base_str = _resolve_bloodline_float_value(option_row, "base_str_override", bloodline_row, "base_str", runtime_hero.base_str)
	runtime_hero.base_agi = _resolve_bloodline_float_value(option_row, "base_agi_override", bloodline_row, "base_agi", runtime_hero.base_agi)
	runtime_hero.base_int = _resolve_bloodline_float_value(option_row, "base_int_override", bloodline_row, "base_int", runtime_hero.base_int)
	runtime_hero.starting_max_health = int(round(_resolve_bloodline_float_value(option_row, "base_hp_override", bloodline_row, "base_hp", float(runtime_hero.starting_max_health))))
	runtime_hero.starting_max_mana = int(round(_resolve_bloodline_float_value(option_row, "base_mana_override", bloodline_row, "base_mana", float(runtime_hero.starting_max_mana))))
	runtime_hero.starting_move_speed = _resolve_bloodline_float_value(option_row, "move_speed_override", bloodline_row, "move_speed", runtime_hero.starting_move_speed)
	runtime_hero.starting_attack_damage = int(round(_resolve_bloodline_float_value(option_row, "attack_damage_override", bloodline_row, "attack_damage", float(runtime_hero.starting_attack_damage))))
	runtime_hero.starting_attack_interval = _resolve_bloodline_float_value(option_row, "attack_interval_override", bloodline_row, "attack_interval", runtime_hero.starting_attack_interval)
	runtime_hero.starting_attack_range = _resolve_bloodline_float_value(option_row, "attack_range_override", bloodline_row, "attack_range", runtime_hero.starting_attack_range)
	runtime_hero.accent_color = _resolve_bloodline_color_value(option_row, "accent_color_override", bloodline_row, "accent_color", _get_bloodline_option_color(option_row, bloodline_row), runtime_hero.accent_color)

	runtime_hero.q_skill_name = _resolve_bloodline_text_value(option_row, "q_skill_name_override", bloodline_row, "q_skill_name", runtime_hero.q_skill_name)
	runtime_hero.q_skill_description = _resolve_bloodline_text_value(option_row, "q_skill_description_override", bloodline_row, "q_skill_description", runtime_hero.q_skill_description)
	runtime_hero.q_skill_icon = _resolve_bloodline_skill_icon(option_row, "q_skill_icon_override", bloodline_row, "q_skill_icon", runtime_hero.q_skill_icon)

	runtime_hero.w_skill_name = _resolve_bloodline_text_value(option_row, "w_skill_name_override", bloodline_row, "w_skill_name", runtime_hero.w_skill_name)
	runtime_hero.w_skill_description = _resolve_bloodline_text_value(option_row, "w_skill_description_override", bloodline_row, "w_skill_description", runtime_hero.w_skill_description)
	runtime_hero.w_skill_icon = _resolve_bloodline_skill_icon(option_row, "w_skill_icon_override", bloodline_row, "w_skill_icon", runtime_hero.w_skill_icon)

	runtime_hero.r_skill_name = _resolve_bloodline_text_value(option_row, "r_skill_name_override", bloodline_row, "r_skill_name", runtime_hero.r_skill_name)
	runtime_hero.r_skill_description = _resolve_bloodline_text_value(option_row, "r_skill_description_override", bloodline_row, "r_skill_description", runtime_hero.r_skill_description)
	runtime_hero.r_skill_icon = _resolve_bloodline_skill_icon(option_row, "r_skill_icon_override", bloodline_row, "r_skill_icon", runtime_hero.r_skill_icon)


func _resolve_bloodline_float_value(option_row: Dictionary, option_key: String, bloodline_row: Dictionary, bloodline_key: String, fallback_value: float) -> float:
	var option_value: Variant = option_row.get(option_key, null)
	var option_text := _get_optional_text(option_value)
	if not option_text.is_empty():
		return float(option_value)

	var bloodline_value: Variant = bloodline_row.get(bloodline_key, null)
	var bloodline_text := _get_optional_text(bloodline_value)
	if not bloodline_text.is_empty():
		return float(bloodline_value)

	return fallback_value


func _resolve_bloodline_text_value(option_row: Dictionary, option_key: String, bloodline_row: Dictionary, bloodline_key: String, fallback_value: String) -> String:
	var option_text := _get_optional_text(option_row.get(option_key, null))
	if not option_text.is_empty():
		return option_text
	var bloodline_text := _get_optional_text(bloodline_row.get(bloodline_key, null))
	if not bloodline_text.is_empty():
		return bloodline_text                        
	return fallback_value


func _resolve_bloodline_skill_icon(option_row: Dictionary, option_key: String, bloodline_row: Dictionary, bloodline_key: String, fallback_texture: Texture2D) -> Texture2D:
	var option_icon := _get_optional_text(option_row.get(option_key, null))
	if not option_icon.is_empty():
		var option_texture := HeroCatalog.load_texture_from_reference(option_icon, "res://assets/ui/icons/skills/")
		if option_texture != null:
			return option_texture
	var bloodline_icon := _get_optional_text(bloodline_row.get(bloodline_key, null))
	if not bloodline_icon.is_empty():
		var bloodline_texture := HeroCatalog.load_texture_from_reference(bloodline_icon, "res://assets/ui/icons/skills/")
		if bloodline_texture != null:
			return bloodline_texture
	return fallback_texture


func _resolve_bloodline_color_value(option_row: Dictionary, option_key: String, bloodline_row: Dictionary, bloodline_key: String, fallback_color: Color, fallback_value: Color) -> Color:
	var option_color_text := _get_optional_text(option_row.get(option_key, null))
	if not option_color_text.is_empty():
		return Color.from_string(option_color_text, fallback_color)
	var bloodline_color_text := _get_optional_text(bloodline_row.get(bloodline_key, null))
	if not bloodline_color_text.is_empty():
		return Color.from_string(bloodline_color_text, fallback_color)
	return fallback_value


func _get_primary_attr_display_name(attr_id: StringName) -> String:
	match str(attr_id).strip_edges().to_lower():
		"str":
			return "力量"
		"agi":
			return "敏捷"
		"int":
			return "智力"
	return str(attr_id).strip_edges()


func _resolve_bloodline_icon_texture(option_row: Dictionary, bloodline_row: Dictionary) -> Texture2D:
	var option_icon := _get_optional_text(option_row.get("icon", ""))
	if not option_icon.is_empty():
		var option_texture := HeroCatalog.load_texture_from_reference(option_icon, BLOODLINE_ICON_DIR)
		if option_texture != null:
			return option_texture
	var bloodline_icon := _get_optional_text(bloodline_row.get("icon", ""))
	if not bloodline_icon.is_empty():
		var bloodline_texture := HeroCatalog.load_texture_from_reference(bloodline_icon, BLOODLINE_ICON_DIR)
		if bloodline_texture != null:
			return bloodline_texture
	var bloodline_id := _get_optional_text(bloodline_row.get("id", ""))
	if not bloodline_id.is_empty():
		var id_texture := HeroCatalog.load_texture_from_reference(bloodline_id, BLOODLINE_ICON_DIR)
		if id_texture != null:
			return id_texture
	var model_id := _get_optional_text(bloodline_row.get("model_id", ""))
	if not model_id.is_empty():
		return HeroCatalog.load_texture_from_reference(model_id, BLOODLINE_ICON_DIR)
	return null


func _get_optional_text(value: Variant) -> String:
	if value == null:
		return ""
	var text := str(value).strip_edges()
	return "" if text == "<null>" else text


func _has_visual_model_profile(model_id_text: String) -> bool:
	var clean_model_id := model_id_text.strip_edges()
	if clean_model_id.is_empty():
		return false
	var index_path := "res://assets/heroes/models_3d/index.json"
	if not FileAccess.file_exists(index_path):
		return false
	var file := FileAccess.open(index_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed is Dictionary and (parsed as Dictionary).has(clean_model_id)


func _connect_selection_skill_signals() -> void:
	for skill_key in selection_skill_buttons.keys():
		var button := selection_skill_buttons[skill_key] as Button
		if button == null:
			continue
		_ensure_skill_button_card(button, String(skill_key))
		button.mouse_entered.connect(_on_selection_skill_mouse_entered.bind(String(skill_key)))
		button.mouse_exited.connect(_on_selection_skill_mouse_exited)
		button.focus_mode = Control.FOCUS_NONE


func _update_selection_skill_buttons(hero: HeroData) -> void:
	var signature := _build_selection_skill_signature(hero)
	if signature == selection_last_skill_signature:
		return
	selection_last_skill_signature = signature

	for skill_key in selection_skill_buttons.keys():
		var button := selection_skill_buttons[skill_key] as Button
		if button == null:
			continue
		_ensure_skill_button_card(button, String(skill_key))
		var skill_entry := _get_selection_skill_entry(hero, String(skill_key))
		var skill_name := str(skill_entry.get("name", "")).strip_edges()
		var skill_description := str(skill_entry.get("description", "")).strip_edges()
		var skill_icon := skill_entry.get("icon", null) as Texture2D
		button.text = ""
		button.tooltip_text = "%s\n%s" % [
			skill_name if not skill_name.is_empty() else "%s 技能待填写" % String(skill_key),
			skill_description if not skill_description.is_empty() else "这个技能描述还没有写入 bloodlines 表。",
		]
		button.icon = null
		var icon_rect := button.get_node_or_null("Card/Icon") as TextureRect
		if icon_rect != null:
			icon_rect.texture = skill_icon
		var active_color := Color(0.88, 0.71, 0.28, 1.0) if not skill_name.is_empty() else Color(0.42, 0.45, 0.44, 1.0)
		var bg_color := Color(0.16, 0.12, 0.08, 0.98) if not skill_name.is_empty() else Color(0.1, 0.12, 0.11, 0.94)
		_apply_selection_card_button_style(button, active_color, bg_color, 2)


func _get_selection_skill_entry(hero: HeroData, skill_key: String) -> Dictionary:
	if hero == null:
		return {
			"name": "",
			"description": "",
			"icon": null,
		}

	match skill_key:
		"Q":
			return {
				"name": hero.q_skill_name,
				"description": hero.q_skill_description,
				"icon": hero.q_skill_icon,
			}
		"W":
			return {
				"name": hero.w_skill_name,
				"description": hero.w_skill_description,
				"icon": hero.w_skill_icon,
			}
		"R":
			return {
				"name": hero.r_skill_name,
				"description": hero.r_skill_description,
				"icon": hero.r_skill_icon,
			}
	return {
		"name": "",
		"description": "",
		"icon": null,
	}


func _reset_selection_skill_hover_text(hero: HeroData, option_row: Dictionary, bloodline_row: Dictionary) -> void:
	if selection_overlay == null:
		return
	var title_text := "血脉效果"
	var lines: Array[String] = []
	var description := str(option_row.get("selection_description", bloodline_row.get("description", ""))).strip_edges()
	if description.is_empty() and hero != null:
		description = str(hero.hero_description).strip_edges()
	if not description.is_empty():
		lines.append(description)
	selection_overlay.set_skill_tooltip(title_text, "\n".join(lines))


func _on_selection_skill_mouse_entered(skill_key: String) -> void:
	if selection_overlay == null:
		return
	var preview_hero: HeroData = selected_hero
	if selection_active and not available_heroes.is_empty():
		var option_row := _get_current_bloodline_option()
		var bloodline_row := _get_bloodline_row_for_option(option_row)
		preview_hero = _build_runtime_selected_hero(available_heroes[selection_state.index], option_row, bloodline_row)
	var skill_entry := _get_selection_skill_entry(preview_hero, skill_key)
	var skill_name := str(skill_entry.get("name", "")).strip_edges()
	var skill_description := str(skill_entry.get("description", "")).strip_edges()
	selection_overlay.set_skill_tooltip(
		"%s 技能" % skill_key,
		"%s\n%s" % [
			skill_name if not skill_name.is_empty() else "%s 技能待填写" % skill_key,
			skill_description if not skill_description.is_empty() else "请在 bloodlines#血脉.xlsx 中填写该技能名称与文本。",
		]
	)


func _on_selection_skill_mouse_exited() -> void:
	if selection_overlay == null:
		return
	if available_heroes.is_empty():
		return
	var option_row := _get_current_bloodline_option()
	var bloodline_row := _get_bloodline_row_for_option(option_row)
	var hero := available_heroes[selection_state.index]
	_reset_selection_skill_hover_text(hero, option_row, bloodline_row)


func _get_bloodline_option_color(option_row: Dictionary, bloodline_row: Dictionary) -> Color:
	var color_text := str(option_row.get("ui_color", bloodline_row.get("ui_color", ""))).strip_edges()
	if color_text.is_empty():
		return Color(0.88, 0.71, 0.28, 1.0)
	return Color.from_string(color_text, Color(0.88, 0.71, 0.28, 1.0))


func _begin_battle_with_hero(hero: HeroData, bloodline_option: Dictionary = {}) -> void:
	_ensure_selection_state()
	if hero == null:
		return

	_clear_active_enemies()
	selection_active = false
	_hide_attributes_panel()
	selected_hero = hero
	selected_hero_id = hero.hero_id
	selection_state.selected_template_bloodline_option = bloodline_option.duplicate(true)
	if hud != null:
		hud.show_battle_mode()
	if selection_overlay != null:
		selection_overlay.hide_overlay()
	_clear_selection_preview_model()
	if wave_info_panel != null:
		wave_info_panel.visible = true
	elapsed_time = 0.0
	kill_count = 0
	current_gold = 0
	current_exp = 0
	current_level = 1
	runtime_bonus_values.clear()
	reward_attribute_bonus_values.clear()
	passive_accumulated_bonus_values.clear()
	passive_conditional_bonus_values.clear()
	passive_tick_accumulator = 0.0
	passive_spec_progress.clear()
	passive_fractional_progress["gold"] = 0.0
	passive_fractional_progress["kill_count"] = 0.0
	passive_fractional_progress["health"] = 0.0
	passive_fractional_progress["mana"] = 0.0
	owned_cards.clear()
	owned_card_passives.clear()
	owned_card_runtime_specs.clear()
	owned_weapons.clear()
	_reset_weapon_growth_runtime_state(hero, bloodline_option)
	next_kill_reward_index = 0
	transient_message_remaining = 0.0
	transient_message_queue.clear()
	game_over = false
	battle_finished = false
	battle_result_reason = ""
	cleared_wave_count = 0
	enemy_overload_remaining = 0.0
	player_respawning = false
	respawn_remaining = 0.0
	_hide_death_overlay()
	_hide_victory_overlay()
	_hide_card_choice_overlay(false)
	_hide_card_collection(false)
	_reset_card_choice_pickup_runtime_state()
	spawn_cooldown = 1.2
	_reset_wave_runtime_state()
	_refresh_level_state(false)
	player.global_position = _get_player_start_position()
	player_respawn_anchor = player.global_position
	player.visible = true
	player.apply_hero_data(hero)
	if weapon_growth_runtime != null and weapon_growth_runtime.is_available():
		_push_runtime_bonus_values_to_player(false)
	else:
		_sync_player_runtime_progress()
	player.set_controls_enabled(true)
	if card_collection_button != null:
		card_collection_button.visible = true
	_refresh_card_collection_button_state()
	_rebuild_card_collection_ui()
	_apply_hero_header()
	_build_attribute_panel_entries()
	if hud != null:
		hud.hide_message()
	_update_hud(player.health, player.max_health)
	if wave_rows.is_empty():
		_spawn_enemy_ring(2)


func _clear_active_enemies() -> void:
	for enemy_node in get_tree().get_nodes_in_group("enemy"):
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if enemy_node is Node2D and enemy_pool_nodes.has(enemy_node as Node2D):
			_release_enemy_to_pool(enemy_node as Node2D)
		else:
			enemy_node.queue_free()


func get_runtime_bonus_values() -> Dictionary:
	return runtime_bonus_values.duplicate(true)


func get_owned_card_passives() -> Array[Dictionary]:
	return owned_card_passives.duplicate(true)


func set_runtime_bonus_values(values: Dictionary, preserve_resources: bool = true) -> void:
	runtime_bonus_values.clear()
	for raw_key in values.keys():
		_set_runtime_bonus_value_internal(StringName(String(raw_key)), float(values[raw_key]))
	_push_runtime_bonus_values_to_player(preserve_resources)


func merge_runtime_bonus_values(values: Dictionary, preserve_resources: bool = true) -> void:
	for raw_key in values.keys():
		_set_runtime_bonus_value_internal(StringName(String(raw_key)), float(values[raw_key]))
	_push_runtime_bonus_values_to_player(preserve_resources)


func set_runtime_bonus_value(stat_id: StringName, value: float, preserve_resources: bool = true) -> void:
	_set_runtime_bonus_value_internal(stat_id, value)
	_push_runtime_bonus_values_to_player(preserve_resources)


func add_runtime_bonus_value(stat_id: StringName, delta: float, preserve_resources: bool = true) -> void:
	var stat_key := StringName(String(stat_id))
	var next_value := float(runtime_bonus_values.get(stat_key, 0.0)) + delta
	_set_runtime_bonus_value_internal(stat_key, next_value)
	_push_runtime_bonus_values_to_player(preserve_resources)


func clear_runtime_bonus_values(preserve_resources: bool = true) -> void:
	runtime_bonus_values.clear()
	_push_runtime_bonus_values_to_player(preserve_resources)


func _reset_weapon_growth_runtime_state(hero: HeroData, bloodline_option: Dictionary) -> void:
	if weapon_growth_runtime == null:
		weapon_growth_runtime = WeaponGrowthRuntimeScript.new()
	weapon_growth_runtime.reset(hero, bloodline_option)
	_refresh_weapon_growth_panel()


func _on_weapon_growth_upgrade_requested(slot: String) -> void:
	if selection_active or game_over or weapon_growth_runtime == null or not weapon_growth_runtime.is_available():
		return
	var result: Dictionary = weapon_growth_runtime.try_upgrade(slot, current_gold, selected_hero)
	if not bool(result.get("success", false)):
		var fail_message := String(result.get("message", "")).strip_edges()
		if not fail_message.is_empty():
			_show_transient_message(fail_message, 1.8)
		_refresh_weapon_growth_panel()
		return

	current_gold -= maxi(int(result.get("spent_gold", 0)), 0)
	_push_runtime_bonus_values_to_player(true)
	_show_transient_message(String(result.get("message", "")), 1.8)
	_refresh_weapon_growth_panel()
	_update_hud(player.health, player.max_health)


func _refresh_weapon_growth_panel() -> void:
	if hud == null:
		return
	if selection_active or game_over or weapon_growth_runtime == null or not weapon_growth_runtime.is_available():
		hud.hide_weapon_growth_panel()
		return
	hud.configure_weapon_growth(weapon_growth_runtime.build_slot_infos(), current_gold)


func _find_hero_index(hero_id: StringName) -> int:
	for i in available_heroes.size():
		if available_heroes[i].hero_id == hero_id:
			return i

	return -1


func _clear_selection_preview_model() -> void:
	var preview_root := selection_overlay.preview_root if selection_overlay != null else null
	if preview_root == null:
		selection_preview_model_root = null
		selection_preview_hero_model = null
		selection_preview_dragging = false
		selection_preview_signature = ""
		selection_preview_should_replay_intro = true
		return

	for child in preview_root.get_children():
		child.queue_free()

	selection_preview_model_root = null
	selection_preview_hero_model = null
	selection_preview_dragging = false
	selection_preview_signature = ""
	selection_preview_should_replay_intro = true


func _update_selection_preview_model(hero: HeroData, force_replay_intro: bool = false) -> void:
	var preview_root := selection_overlay.preview_root if selection_overlay != null else null
	if hero == null or preview_root == null:
		_clear_selection_preview_model()
		return

	var preview_signature := _build_selection_preview_signature(hero)
	var preview_model_id := _resolve_selection_preview_model_id(hero)
	if String(preview_model_id).strip_edges().is_empty():
		_clear_selection_preview_model()
		return

	var can_reuse := selection_preview_signature == preview_signature \
		and selection_preview_model_root != null \
		and is_instance_valid(selection_preview_model_root) \
		and selection_preview_model_root.get_parent() == preview_root
	if can_reuse:
		if force_replay_intro and selection_preview_hero_model != null:
			selection_preview_hero_model.play_selection_preview_intro()
		call_deferred("_layout_selection_preview_model")
		return

	_clear_selection_preview_model()

	var instance := HeroModelCatalog.instantiate_model(preview_model_id)
	if instance == null:
		return

	selection_preview_model_root = instance
	preview_root.add_child(selection_preview_model_root)
	selection_preview_model_root.scale = Vector2(0.65, 0.65)
	selection_preview_hero_model = selection_preview_model_root as HeroModel
	selection_preview_signature = preview_signature
	call_deferred("_layout_selection_preview_model")

	if selection_preview_hero_model != null:
		selection_preview_hero_model.apply_selection_preview_preset()
		selection_preview_hero_model.play_selection_preview_intro()
		selection_preview_hero_model.set_showcase_spin_speed(0.0)


func _layout_selection_preview_model() -> void:
	if selection_preview_model_root == null or not is_instance_valid(selection_preview_model_root):
		return
	var preview_viewport := selection_overlay.preview_viewport if selection_overlay != null else null
	if preview_viewport == null:
		return

	var preview_size := Vector2(preview_viewport.get_visible_rect().size)
	if preview_size == Vector2.ZERO:
		preview_size = Vector2(preview_viewport.size)

	selection_preview_model_root.position = Vector2(preview_size.x * 0.5, preview_size.y * 0.66)


func _on_selection_preview_size_changed() -> void:
	call_deferred("_layout_selection_preview_model")


func _make_portrait_button_style(border_color: Color, background_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style


func _create_selection_card_button(display_name: String, icon_texture: Texture2D, tooltip_text: String, button_size: Vector2, icon_size: float, show_name: bool = true) -> Button:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = tooltip_text
	button.custom_minimum_size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var card := VBoxContainer.new()
	card.name = "Card"
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 4.0
	card.offset_top = 4.0
	card.offset_right = -4.0
	card.offset_bottom = -4.0
	card.alignment = BoxContainer.ALIGNMENT_BEGIN if not show_name else BoxContainer.ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_constant_override("separation", 2 if show_name else 0)
	button.add_child(card)

	var icon_holder: Control
	if show_name:
		icon_holder = CenterContainer.new()
	else:
		icon_holder = MarginContainer.new()
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not show_name:
		icon_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(icon_holder)

	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	if show_name:
		icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_rect.offset_left = 0.0
		icon_rect.offset_top = 0.0
		icon_rect.offset_right = 0.0
		icon_rect.offset_bottom = 0.0
		icon_rect.custom_minimum_size = Vector2.ZERO
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon_rect.texture = icon_texture
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(icon_rect)

	if show_name:
		var name_label := Label.new()
		name_label.name = "NameLabel"
		name_label.text = display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.custom_minimum_size = Vector2(0, 22)
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_label)

	return button


func _apply_selection_card_button_style(button: Button, border_color: Color, background_color: Color, border_width: int) -> void:
	if button == null:
		return
	var normal_style := _make_portrait_button_style(border_color, background_color, border_width)
	var hover_style := _make_portrait_button_style(border_color.lightened(0.08), background_color.lightened(0.04), border_width)
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", normal_style)

	var name_label := button.get_node_or_null("Card/NameLabel") as Label
	if name_label != null:
		name_label.modulate = Color(0.97, 0.97, 0.95, 1.0)


func _ensure_skill_button_card(button: Button, shortcut_key: String) -> void:
	if button == null:
		return
	if button.get_node_or_null("Card") != null:
		return

	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var card := VBoxContainer.new()
	card.name = "Card"
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 5.0
	card.offset_top = 5.0
	card.offset_right = -5.0
	card.offset_bottom = -5.0
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_constant_override("separation", 3)
	button.add_child(card)

	var icon_holder := CenterContainer.new()
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_holder)

	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.custom_minimum_size = Vector2(22, 22)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(icon_rect)

	var shortcut_label := Label.new()
	shortcut_label.name = "Shortcut"
	shortcut_label.text = shortcut_key
	shortcut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shortcut_label.add_theme_font_size_override("font_size", 11)
	shortcut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(shortcut_label)


func _on_selection_preview_gui_input(event: InputEvent) -> void:
	if selection_overlay == null:
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button != null and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		selection_preview_dragging = mouse_button.pressed
		return

	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion == null or not selection_preview_dragging:
		return
	if selection_preview_hero_model != null:
		selection_preview_hero_model.rotate_preview(mouse_motion.relative.x * 0.01)


func _setup_wave_info_display() -> void:
	wave_info_panel = WAVE_INFO_SCENE.instantiate() as WaveInfoUi
	wave_info_panel.name = "WaveInfoPanel"
	wave_info_panel.visible = false
	_set_process_mode_recursive(wave_info_panel, Node.PROCESS_MODE_ALWAYS)
	if hud != null:
		hud.add_runtime_ui(wave_info_panel)


func _setup_boss_health_bar() -> void:
	boss_health_panel = BOSS_HEALTH_SCENE.instantiate() as BossHealthUi
	boss_health_panel.name = "BossHealthPanel"
	boss_health_panel.visible = false
	_set_process_mode_recursive(boss_health_panel, Node.PROCESS_MODE_ALWAYS)
	if hud != null:
		hud.add_runtime_ui(boss_health_panel)


func _setup_wave_banner_display() -> void:
	wave_banner_panel = WAVE_BANNER_SCENE.instantiate() as WaveBannerUi
	wave_banner_panel.name = "WaveBannerPanel"
	wave_banner_panel.visible = false
	_set_process_mode_recursive(wave_banner_panel, Node.PROCESS_MODE_ALWAYS)
	if hud != null:
		hud.add_runtime_ui(wave_banner_panel)


func _setup_death_overlay() -> void:
	death_overlay = DEATH_OVERLAY_SCENE.instantiate() as DeathOverlayUi
	death_overlay.name = "DeathOverlay"
	death_overlay.visible = false
	_set_process_mode_recursive(death_overlay, Node.PROCESS_MODE_ALWAYS)
	if hud != null:
		hud.add_runtime_ui(death_overlay)


func _setup_victory_overlay() -> void:
	victory_overlay = BATTLE_RESULT_SCENE.instantiate() as BattleResultUi
	victory_overlay.name = "VictoryOverlay"
	victory_overlay.visible = false
	_set_process_mode_recursive(victory_overlay, Node.PROCESS_MODE_ALWAYS)
	if not victory_overlay.return_requested.is_connected(_on_victory_return_button_pressed):
		victory_overlay.return_requested.connect(_on_victory_return_button_pressed)
	if hud != null:
		hud.add_runtime_ui(victory_overlay)


func _setup_attributes_panel() -> void:
	attributes_panel = ATTRIBUTES_PANEL_SCENE.instantiate() as AttributesPanelUi
	attributes_panel.name = "AttributesPanel"
	attributes_panel.hide_panel()
	_set_process_mode_recursive(attributes_panel, Node.PROCESS_MODE_ALWAYS)
	if hud != null:
		hud.add_runtime_ui(attributes_panel)


func _toggle_attributes_panel() -> void:
	if attributes_panel_visible:
		_hide_attributes_panel()
	else:
		_show_attributes_panel()


func _show_attributes_panel() -> void:
	if selection_active or game_over or card_choice_overlay_visible or card_collection_visible:
		return

	_build_attribute_panel_entries()
	_refresh_attribute_panel_values()
	if attributes_panel != null:
		attributes_panel.show_panel()
	attributes_panel_visible = true
	_update_runtime_pause_state()


func _hide_attributes_panel() -> void:
	if attributes_panel == null:
		return

	attributes_panel.hide_panel()
	attributes_panel_visible = false
	_update_runtime_pause_state()


func _build_attribute_panel_entries() -> void:
	if attributes_panel == null:
		return

	attributes_value_labels.clear()
	attribute_panel_entries.clear()

	var data_table := _get_data_table_node()
	if data_table == null:
		return

	var raw_rows: Array = data_table.call("get_all", &"attributes")
	var order_index := 0
	for raw_row in raw_rows:
		if not (raw_row is Dictionary):
			order_index += 1
			continue

		var row: Dictionary = raw_row
		if not bool(row.get("enabled", true)):
			order_index += 1
			continue

		var entry := {
			"id": StringName(String(row.get("id", ""))),
			"name": String(row.get("name", "")),
			"value_type": String(row.get("value_type", "值")),
			"sort_weight": int(row.get("sort_weight", order_index)),
			"order_index": order_index,
		}
		if String(entry["id"]).is_empty():
			order_index += 1
			continue
		if entry["id"] == &"level":
			order_index += 1
			continue

		attribute_panel_entries.append(entry)
		order_index += 1

	attribute_panel_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var weight_a: int = int(a.get("sort_weight", 0))
		var weight_b: int = int(b.get("sort_weight", 0))
		if weight_a == weight_b:
			return int(a.get("order_index", 0)) < int(b.get("order_index", 0))
		return weight_a < weight_b
	)

	for entry in attribute_panel_entries:
		attributes_value_labels[entry["id"]] = "%s: -" % String(entry.get("name", ""))
	attributes_panel.rebuild_entries(attribute_panel_entries)


func _refresh_attribute_panel_values() -> void:
	if attributes_panel == null or attribute_panel_entries.is_empty():
		return

	var stats = _get_player_combat_stats()
	if stats == null and selected_hero != null:
		stats = AttributeSystemScript.build_hero_stats(selected_hero)
	if stats == null:
		return

	var display_values: Dictionary = {}
	for entry in attribute_panel_entries:
		var stat_id: StringName = entry.get("id", &"")
		var stat_name := String(entry.get("name", stat_id))
		var value_type := String(entry.get("value_type", "值"))
		var value: float = float(stats.get_stat(stat_id))
		display_values[stat_id] = "%s: %s" % [stat_name, _format_attribute_value(value, value_type)]
	attributes_panel.update_value_texts(display_values)


func _format_attribute_value(value: float, value_type: String) -> String:
	match value_type:
		"百分比":
			var percent_value := value * 100.0 if absf(value) <= 2.0 else value
			return "%.1f%%" % [percent_value]
		"值/秒":
			return "%.1f/秒" % [value]
		"秒":
			return "%.2fs" % [value]
		_:
			if absf(value - round(value)) < 0.001:
				return str(int(round(value)))
			return "%.2f" % [value]


func _update_wave_info_hud() -> void:
	if wave_info_panel == null:
		return
	if selection_active:
		wave_info_panel.set_panel_visible(false)
		return

	wave_info_panel.set_panel_visible(true)
	var alive_count: int = _get_runtime_alive_enemy_count()
	var cap: int = maxi(max_alive_enemies, 1)
	var progress_text := _build_wave_hud_progress_text(alive_count, cap)
	if wave_rows.is_empty():
		var survival_texts := _apply_enemy_overload_warning_to_wave_texts(progress_text, "持续战斗", alive_count, cap)
		wave_info_panel.set_wave_info("生存模式", String(survival_texts.get("progress", progress_text)), String(survival_texts.get("timer", "持续战斗")))
		return

	var wave_text := _get_wave_display_text()
	var info_state := wave_runtime.build_wave_info_state(
		wave_flow_state,
		WaveFlowState.PREPARE,
		WaveFlowState.TRANSITION,
		WaveFlowState.COMPLETE,
		wave_text,
		wave_state_remaining,
		_get_wave_remaining_time()
	)
	var title_text := String(info_state.get("title", ""))
	var timer_text := String(info_state.get("timer", ""))
	var texts := _apply_enemy_overload_warning_to_wave_texts(progress_text, timer_text, alive_count, cap)
	wave_info_panel.set_wave_info(title_text, String(texts.get("progress", progress_text)), String(texts.get("timer", timer_text)))


func _build_wave_hud_progress_text(alive_count: int, cap: int) -> String:
	return "场上怪物 %d/%d" % [alive_count, cap]


func _apply_enemy_overload_warning_to_wave_texts(progress_text: String, timer_text: String, alive_count: int, threshold: int) -> Dictionary:
	if alive_count <= threshold:
		return {"progress": progress_text, "timer": timer_text}
	var remain_seconds := enemy_overload_remaining
	if remain_seconds <= 0.0:
		remain_seconds = maxf(enemy_overload_defeat_seconds, 0.1)
	return {
		"progress": "场上怪物 %d/%d  (超载)" % [alive_count, threshold],
		"timer": "%s  |  超载倒计时 %.1fs" % [timer_text, remain_seconds],
	}


func _update_boss_health_bar() -> void:
	if boss_health_panel == null:
		return
	if selection_active:
		boss_health_panel.hide_bar()
		return

	var active_bosses: Array[Node2D] = _get_runtime_active_boss_nodes()
	if active_bosses.is_empty():
		boss_health_panel.hide_bar()
		return

	var total_max_hp := 0.0
	var total_hp := 0.0
	for boss_node in active_bosses:
		var max_hp := maxf(float(boss_node.get("max_health")), 1.0)
		var hp := clampf(float(boss_node.get("health")), 0.0, max_hp)
		total_max_hp += max_hp
		total_hp += hp

	total_max_hp = maxf(total_max_hp, 1.0)
	total_hp = clampf(total_hp, 0.0, total_max_hp)
	var title_text := ""
	if active_bosses.size() == 1:
		var single_boss: Node2D = active_bosses[0]
		title_text = "%s  HP %d / %d" % [str(single_boss.get("enemy_name")), int(round(total_hp)), int(round(total_max_hp))]
	else:
		title_text = "Boss敌群 x%d  总HP %d / %d" % [active_bosses.size(), int(round(total_hp)), int(round(total_max_hp))]
	boss_health_panel.show_boss_health(title_text, total_hp, total_max_hp)


func _get_wave_display_text() -> String:
	if wave_rows.is_empty():
		return "1"

	return str(_get_wave_number(current_wave_index))


func _get_current_wave_duration() -> float:
	if wave_rows.is_empty():
		return maxf(wave_duration_seconds, 1.0)

	var clamped_index: int = clampi(current_wave_index, 0, wave_rows.size() - 1)
	var row: Dictionary = wave_rows[clamped_index]
	var duration_from_table: float = float(row.get("duration", wave_duration_seconds))
	return maxf(duration_from_table, 1.0)


func _get_wave_spawn_interval(row: Dictionary) -> float:
	var explicit_interval := float(row.get("spawn_interval", 0.0))
	if explicit_interval > 0.0:
		return explicit_interval

	var spawn_rate: float = maxf(float(row.get("spawn_rate", 0.0)), 0.0)
	if spawn_rate <= 0.0:
		return 0.0
	return 1.0 / spawn_rate


func _get_wave_type(row: Dictionary) -> int:
	var raw_type = row.get("wave_type", WAVE_TYPE_NORMAL)
	if raw_type == null:
		return WAVE_TYPE_NORMAL
	if raw_type is int:
		return WAVE_TYPE_BOSS if int(raw_type) == WAVE_TYPE_BOSS else WAVE_TYPE_NORMAL
	if raw_type is float:
		var numeric_type := int(round(float(raw_type)))
		return WAVE_TYPE_BOSS if numeric_type == WAVE_TYPE_BOSS else WAVE_TYPE_NORMAL

	var type_text := str(raw_type).strip_edges().to_lower()
	if type_text.is_empty():
		return WAVE_TYPE_NORMAL
	if type_text.is_valid_int():
		var enum_value := int(type_text)
		if enum_value == WAVE_TYPE_BOSS:
			return WAVE_TYPE_BOSS
		return WAVE_TYPE_NORMAL
	if type_text.is_valid_float():
		var float_enum_value := int(round(float(type_text)))
		if float_enum_value == WAVE_TYPE_BOSS:
			return WAVE_TYPE_BOSS
		return WAVE_TYPE_NORMAL

	match type_text:
		"boss", "boss_wave":
			return WAVE_TYPE_BOSS
		_:
			return WAVE_TYPE_NORMAL


func _build_wave_timed_spawns(row: Dictionary) -> Array[Dictionary]:
	var timed_spawns: Array[Dictionary] = []

	var raw_events = row.get("timed_spawns", null)
	if raw_events is Array:
		for raw_event in raw_events:
			if raw_event is Dictionary:
				var event_row: Dictionary = raw_event
				_append_wave_timed_spawn(
					timed_spawns,
					event_row.get("enemy_id", ""),
					float(event_row.get("spawn_time", 0.0)),
					int(event_row.get("count", 1))
				)

	_append_wave_timed_spawn(
		timed_spawns,
		row.get("special_enemy_id", ""),
		float(0.0 if row.get("special_spawn_time", null) == null else row.get("special_spawn_time", 0.0)),
		int(0 if row.get("special_spawn_count", null) == null else row.get("special_spawn_count", 1))
	)
	return timed_spawns


func _append_wave_timed_spawn(target: Array[Dictionary], enemy_id, spawn_time: float, count: int) -> void:
	var enemy_id_text := _normalize_optional_id(enemy_id)
	if enemy_id_text.is_empty():
		return
	if spawn_time < 0.0:
		return
	if count <= 0:
		return

	target.append({
		"enemy_id": enemy_id_text,
		"spawn_time": spawn_time,
		"count": count,
		"spawned_count": 0,
	})


func _process_wave_timed_spawns(alive_count: int, force_boss: bool = false) -> int:
	if current_wave_timed_spawns.is_empty():
		return alive_count

	var updated_alive_count := alive_count
	for event_index in current_wave_timed_spawns.size():
		var event: Dictionary = current_wave_timed_spawns[event_index]
		var spawn_time := float(event.get("spawn_time", 0.0))
		if current_wave_elapsed < spawn_time:
			continue

		var count := int(event.get("count", 0))
		var spawned_count := int(event.get("spawned_count", 0))
		while spawned_count < count:
			_spawn_enemy(_resolve_enemy_by_id(event.get("enemy_id", "")), force_boss)
			if force_boss:
				wave_boss_spawned = true
			spawned_count += 1
			updated_alive_count += 1

		event["spawned_count"] = spawned_count
		current_wave_timed_spawns[event_index] = event
	return updated_alive_count


func _get_wave_boss_id(row: Dictionary, wave_index: int = -1) -> String:
	if _get_wave_type(row) != WAVE_TYPE_BOSS:
		return ""

	var boss_enemy_id := _normalize_optional_id(row.get("enemy_id", ""))
	if not boss_enemy_id.is_empty():
		return boss_enemy_id

	return _get_default_boss_enemy_id_for_wave(wave_index)


func _get_default_boss_enemy_id_for_wave(wave_index: int = -1) -> String:
	if wave_index < 0:
		wave_index = current_wave_index

	if not boss_enemies.is_empty():
		var boss_cycle_index := maxi(wave_index, 0) % boss_enemies.size()
		return str(boss_enemies[boss_cycle_index].enemy_id)

	if not available_enemies.is_empty():
		var fallback_cycle_index := maxi(wave_index, 0) % available_enemies.size()
		return str(available_enemies[fallback_cycle_index].enemy_id)
	return ""


func _get_wave_remaining_time() -> float:
	if wave_flow_state == WaveFlowState.ACTIVE:
		return maxf(_get_current_wave_duration() - current_wave_elapsed, 0.0)
	if wave_flow_state == WaveFlowState.PREPARE or wave_flow_state == WaveFlowState.TRANSITION:
		return maxf(wave_state_remaining, 0.0)
	return 0.0


func _update_wave_banner(delta: float) -> void:
	if wave_banner_panel == null or not wave_banner_panel.visible:
		return

	wave_banner_remaining = maxf(wave_banner_remaining - delta, 0.0)
	var alpha_scale := 1.0
	if wave_banner_remaining < 0.25:
		alpha_scale = wave_banner_remaining / 0.25
	wave_banner_panel.set_alpha_scale(alpha_scale)

	if wave_banner_remaining == 0.0:
		_hide_wave_banner()


func _show_wave_banner(title: String, subtitle: String, duration: float) -> void:
	if wave_banner_panel == null:
		return

	wave_banner_panel.show_banner(title, subtitle)
	wave_banner_remaining = maxf(duration, 0.01)


func _hide_wave_banner() -> void:
	if wave_banner_panel == null:
		return

	wave_banner_panel.hide_banner()
	wave_banner_remaining = 0.0


func _enter_wave_prepare(_is_initial_wave: bool) -> void:
	wave_flow_state = WaveFlowState.PREPARE
	wave_state_remaining = maxf(wave_prepare_seconds, 0.0)
	current_wave_spawned = 0
	current_wave_spawn_timer = 0.0
	wave_boss_spawned = false
	current_wave_elapsed = 0.0
	current_wave_timed_spawns = _build_wave_timed_spawns(wave_rows[clampi(current_wave_index, 0, wave_rows.size() - 1)])

	if wave_state_remaining == 0.0:
		_start_current_wave()


func _start_current_wave() -> void:
	wave_flow_state = WaveFlowState.ACTIVE
	wave_state_remaining = 0.0
	current_wave_elapsed = 0.0
	current_wave_spawn_timer = 0.0
	var row: Dictionary = wave_rows[clampi(current_wave_index, 0, wave_rows.size() - 1)] if not wave_rows.is_empty() else {}
	if _get_wave_type(row) == WAVE_TYPE_BOSS:
		var boss_id_text := _get_wave_boss_id(row, current_wave_index)
		var boss_data: EnemyData = enemy_data_by_id.get(boss_id_text)
		var boss_name := boss_data.enemy_name if boss_data != null else "Boss"
		var subtitle := wave_runtime.build_wave_banner_subtitle(
			int(row.get("total", 0)),
			_get_wave_spawn_interval(row),
			boss_name if not boss_id_text.is_empty() else ""
		)
		_show_wave_banner("第%s波 开始" % _get_wave_display_text(), subtitle, wave_banner_seconds)


func _start_wave_transition(cleared_by_cleanup: bool) -> void:
	if wave_flow_state != WaveFlowState.ACTIVE:
		return

	cleared_wave_count = maxi(cleared_wave_count, _get_wave_number(current_wave_index))
	_apply_card_passives_on_wave_cleared()
	wave_flow_state = WaveFlowState.TRANSITION
	wave_state_remaining = maxf(wave_transition_seconds, 0.0)

	var has_next_wave := current_wave_index < wave_rows.size() - 1
	var next_is_boss_wave := false
	var next_wave_number := _get_wave_number(current_wave_index)
	if has_next_wave:
		var next_row: Dictionary = wave_rows[current_wave_index + 1]
		next_is_boss_wave = _get_wave_type(next_row) == WAVE_TYPE_BOSS
		next_wave_number = _get_wave_number(current_wave_index + 1)
	var subtitle := wave_runtime.build_wave_transition_subtitle(
		cleared_by_cleanup,
		has_next_wave,
		next_is_boss_wave,
		wave_state_remaining,
		next_wave_number
	)

	_show_wave_banner("第%s波 完成" % _get_wave_display_text(), subtitle, maxf(wave_state_remaining, wave_banner_seconds))

	if wave_state_remaining == 0.0:
		_advance_wave()


func _is_current_wave_cleared(row: Dictionary, alive_count: int) -> bool:
	if alive_count > 0:
		return false

	var total: int = int(row.get("total", 0))
	var boss_id_text := _get_wave_boss_id(row, current_wave_index)
	var has_boss := not boss_id_text.is_empty()
	var has_limited_spawn := total > 0
	var has_timed_spawn := not current_wave_timed_spawns.is_empty()

	if has_boss and not wave_boss_spawned:
		return false
	if has_limited_spawn and current_wave_spawned < total:
		return false
	if has_timed_spawn:
		for event in current_wave_timed_spawns:
			if int(event.get("spawned_count", 0)) < int(event.get("count", 0)):
				return false
	if not has_boss and not has_limited_spawn and not has_timed_spawn:
		return false
	return true


func _update_enemy_overload_state(delta: float, alive_enemy_count: int = -1) -> void:
	var threshold := maxi(max_alive_enemies, 1)
	if alive_enemy_count < 0:
		alive_enemy_count = _get_runtime_alive_enemy_count()
	if wave_runtime == null:
		wave_runtime = WaveRuntimeScript.new()
	var result: Dictionary = wave_runtime.update_enemy_overload(
		game_over,
		selection_active,
		threshold,
		alive_enemy_count,
		enemy_overload_remaining,
		enemy_overload_defeat_seconds,
		delta
	)
	enemy_overload_remaining = float(result.get("remaining", enemy_overload_remaining))
	if bool(result.get("defeated", false)):
		_finish_battle_defeat("场上怪物数持续超过 %d 达到 %.0f 秒" % [threshold, enemy_overload_defeat_seconds])


func _get_wave_number(index: int) -> int:
	if wave_rows.is_empty():
		return 1

	var clamped_index: int = clampi(index, 0, wave_rows.size() - 1)
	return int(wave_rows[clamped_index].get("wave", clamped_index + 1))


func _normalize_optional_id(raw_value) -> String:
	return TableValueUtilsScript.normalize_optional_id(raw_value)


func _grant_kill_rewards(reward_info: Dictionary) -> void:
	var reward_amounts := KillRewardAmountCalculatorScript.calculate(reward_info, _get_player_combat_stats())

	current_gold += int(reward_amounts.get("gold", 0))
	current_exp += int(reward_amounts.get("exp", 0))
	_refresh_level_state(true)


func _sync_player_runtime_progress() -> void:
	if player == null or not player.has_method("sync_runtime_progress"):
		return
	player.sync_runtime_progress(current_gold, current_exp, kill_count, current_level)


func _push_runtime_bonus_values_to_player(preserve_resources: bool) -> void:
	if player == null or not player.has_method("set_bonus_values"):
		return

	player.set_bonus_values(_compose_all_bonus_values(), preserve_resources)
	_sync_player_runtime_progress()
	if not selection_active and not game_over:
		_update_hud(player.health, player.max_health)


func _set_runtime_bonus_value_internal(stat_id: StringName, value: float) -> void:
	var key_text := String(stat_id).strip_edges()
	if key_text.is_empty():
		return

	var key := StringName(key_text)
	if absf(value) < 0.0001:
		runtime_bonus_values.erase(key)
	else:
		runtime_bonus_values[key] = value


func _load_table_rows(table_name: StringName, sort_key: String) -> Array[Dictionary]:
	if data_table_provider == null:
		data_table_provider = DataTableProviderScript.new()
	return data_table_provider.load_rows(get_tree(), table_name, sort_key)


func _load_table_row(table_name: StringName, row_id: Variant) -> Dictionary:
	if data_table_provider == null:
		data_table_provider = DataTableProviderScript.new()
	return data_table_provider.load_row(get_tree(), table_name, row_id)


func _is_table_row_banned(row: Dictionary) -> bool:
	if row.is_empty():
		return false
	return row.has("ban") and TableValueUtilsScript.flag_enabled(row.get("ban"))


func _variant_flag_enabled(raw_value: Variant) -> bool:
	return TableValueUtilsScript.flag_enabled(raw_value)


func _refresh_level_state(show_feedback: bool = true) -> void:
	var previous_level := current_level
	current_level = level_runtime.calculate_level(current_exp) if level_runtime != null else 1
	if current_level != previous_level:
		if show_feedback and current_level > previous_level:
			for reached_level in range(previous_level + 1, current_level + 1):
				_show_transient_message("升级！\n达到 Lv.%d" % reached_level, 2.2)
		_push_runtime_bonus_values_to_player(true)
		_apply_hero_header()
	else:
		_sync_player_runtime_progress()


func _get_max_level() -> int:
	return level_runtime.get_max_level() if level_runtime != null else 100


func _get_exp_required_for_level(level: int) -> int:
	return level_runtime.get_exp_required_for_level(level) if level_runtime != null else 0


func _get_current_level_exp_progress() -> int:
	if level_runtime == null:
		return 0
	return level_runtime.get_current_level_exp_progress(current_exp, current_level)


func _update_transient_message(delta: float) -> void:
	if game_over:
		return

	if transient_message_remaining > 0.0:
		transient_message_remaining = maxf(transient_message_remaining - delta, 0.0)
		if transient_message_remaining == 0.0:
			if hud != null:
				hud.hide_message()

	if transient_message_remaining == 0.0 and not transient_message_queue.is_empty():
		var next_message: Dictionary = transient_message_queue.pop_front()
		_display_transient_message(
			String(next_message.get("text", "")),
			float(next_message.get("duration", DEFAULT_REWARD_MESSAGE_DURATION))
		)


func _show_transient_message(text: String, duration: float = DEFAULT_REWARD_MESSAGE_DURATION) -> void:
	if hud == null:
		return

	if transient_message_remaining > 0.0:
		transient_message_queue.append({
			"text": text,
			"duration": duration + DEFAULT_MESSAGE_GAP_DURATION,
		})
		return

	_display_transient_message(text, duration)


func _display_transient_message(text: String, duration: float) -> void:
	if hud != null:
		hud.show_message_text(text)
	transient_message_remaining = maxf(duration, 0.01)


func _on_enemy_damaged(world_position: Vector2, amount: int) -> void:
	if amount <= 0:
		return

	_spawn_world_floating_text(
		world_position + Vector2(randf_range(-12.0, 12.0), randf_range(-20.0, -8.0)),
		str(amount),
		Color(0.96, 0.22, 0.22, 1.0),
		24,
		0.58
	)
	if player != null and player.has_method("heal"):
		var stats = _get_player_combat_stats()
		if stats != null:
			var on_hit_heal := maxi(int(round(float(stats.get_stat(&"on_hit_heal")))), 0)
			if on_hit_heal > 0:
				player.heal(on_hit_heal)


func _spawn_enemy_death_feedback(world_position: Vector2, reward_info: Dictionary) -> void:
	var gold_amount := int(reward_info.get("gold", 0))
	if gold_amount > 0:
		_spawn_coin_burst_effect(world_position + Vector2(0, -8), clampf(0.9 + gold_amount / 18.0, 0.9, 2.0))


func _spawn_kill_reward_pickups(world_position: Vector2, reward_info: Dictionary) -> void:
	if PICKUP_SCENE == null or pickups == null:
		_grant_kill_rewards(reward_info)
		return

	var reward_amounts := KillRewardAmountCalculatorScript.calculate(reward_info, _get_player_combat_stats())
	var gold_amount := int(reward_amounts.get("gold", 0))
	var exp_amount := int(reward_amounts.get("exp", 0))
	if gold_amount <= 0 and exp_amount <= 0:
		return

	if gold_amount > 0:
		_spawn_pickup_burst(world_position, &"gold", gold_amount, 10)
	if exp_amount > 0:
		_spawn_pickup_burst(world_position, &"exp", exp_amount, 14)


func _spawn_pickup_burst(world_position: Vector2, reward_type: StringName, total_amount: int, ideal_chunk: int) -> void:
	var chunks := RewardPickupSplitterScript.split_amount(total_amount, ideal_chunk)
	var chunk_count := chunks.size()
	if chunk_count == 0:
		return

	for i in chunk_count:
		var angle := randf_range(-0.95, 0.95) + (TAU / maxf(float(chunk_count), 1.0)) * float(i) * 0.12
		var impulse_strength := randf_range(42.0, 86.0) + chunk_count * 4.0
		var impulse := Vector2.RIGHT.rotated(angle - PI * 0.5) * impulse_strength
		var spawn_offset := impulse.normalized() * randf_range(2.0, 10.0) if impulse.length_squared() > 0.0 else Vector2.ZERO
		_spawn_single_pickup(world_position + spawn_offset, reward_type, chunks[i], impulse)


func _spawn_single_pickup(world_position: Vector2, reward_type: StringName, amount: int, impulse: Vector2) -> void:
	var pickup = PICKUP_SCENE.instantiate()
	pickup.global_position = world_position
	pickup.collected.connect(_on_pickup_collected)
	pickups.add_child(pickup)
	if pickup.has_method("configure_pickup"):
		pickup.configure_pickup(reward_type, amount, player, impulse)


func _on_pickup_collected(reward_type: StringName, amount: int, world_position: Vector2) -> void:
	match reward_type:
		&"gold":
			current_gold += maxi(amount, 0)
			_spawn_pickup_gain_text(player.global_position + Vector2(randf_range(-14.0, 14.0), -36.0), amount, reward_type)
		&"exp":
			current_exp += maxi(amount, 0)
			_refresh_level_state(true)
			_spawn_pickup_gain_text(player.global_position + Vector2(randf_range(-10.0, 10.0), -28.0), amount, reward_type)
		CARD_CHOICE_PICKUP_REWARD_TYPE:
			for _i in range(maxi(amount, 1)):
				_grant_card_choice_opportunity(world_position)
		_:
			return

	_sync_player_runtime_progress()
	_update_hud(player.health, player.max_health)


func _spawn_pickup_gain_text(world_position: Vector2, amount: int, reward_type: StringName) -> void:
	if amount <= 0:
		return

	var color := Color(0.98, 0.82, 0.24, 1.0)
	var font_size := 24
	var text := "+%d" % amount
	if reward_type == &"exp":
		color = Color(0.42, 0.94, 0.72, 1.0)
		font_size = 20
		text = "+%d EXP" % amount

	_spawn_world_floating_text(world_position, text, color, font_size, 0.64)


func _spawn_world_floating_text(world_position: Vector2, text: String, color: Color, font_size: int = 24, lifetime: float = 0.7) -> void:
	if FLOATING_TEXT_SCENE == null or effects == null:
		return

	var instance = FLOATING_TEXT_SCENE.instantiate()
	instance.global_position = world_position
	effects.add_child(instance)
	if instance.has_method("configure"):
		instance.configure(text, color, font_size, lifetime)


func _spawn_coin_burst_effect(world_position: Vector2, burst_scale: float = 1.0) -> void:
	if COIN_BURST_EFFECT_SCENE == null or effects == null:
		return

	var effect = COIN_BURST_EFFECT_SCENE.instantiate()
	effect.global_position = world_position
	effects.add_child(effect)
	if effect.has_method("configure_burst"):
		var particle_count := int(clampf(6.0 + burst_scale * 2.5, 6.0, 14.0))
		effect.configure_burst(particle_count, burst_scale)


func _spawn_card_pickup_burst_effect(world_position: Vector2, burst_scale: float = 1.0) -> void:
	if CardPickupBurstEffectScript == null or effects == null:
		return
	var effect := CardPickupBurstEffectScript.new()
	effect.global_position = world_position
	effects.add_child(effect)
	if effect.has_method("configure_burst"):
		effect.configure_burst(burst_scale)


func _play_card_choice_focus_effect() -> void:
	if card_collect_effect_layer == null:
		return
	var flash := ColorRect.new()
	flash.name = "CardChoiceFocusFlash"
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(0.98, 0.84, 0.34, 0.0)
	card_collect_effect_layer.add_child(flash)
	flash.move_to_front()

	var tween := card_collect_effect_layer.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(flash, "color", Color(0.98, 0.84, 0.34, 0.12), 0.05)
	tween.tween_property(flash, "color", Color(0.98, 0.84, 0.34, 0.0), 0.14)
	tween.tween_callback(Callable(flash, "queue_free"))


func _process_kill_reward_thresholds() -> void:
	while next_kill_reward_index < kill_reward_rows.size():
		var row: Dictionary = kill_reward_rows[next_kill_reward_index]
		var threshold: int = int(row.get("threshold", 0))
		if kill_count < threshold:
			break

		_grant_threshold_reward(row)
		next_kill_reward_index += 1


func _grant_threshold_reward(row: Dictionary) -> void:
	var reward_type := String(row.get("reward_type", "")).strip_edges().to_lower()
	var reward_value := String(row.get("reward_value", "")).strip_edges()
	match reward_type:
		"gold":
			var bonus_gold := maxi(int(reward_value), 0)
			current_gold += bonus_gold
			_sync_player_runtime_progress()
			_show_transient_message("击杀奖励达成\n获得金币 %d" % bonus_gold)
		"card":
			var card_row := ThresholdRewardPickerScript.pick_card(reward_value, card_rows, owned_cards)
			if card_row.is_empty():
				_show_transient_message("击杀奖励达成\n未找到可用卡牌奖励")
				return
			owned_cards.append(card_row)
			_rebuild_owned_card_passives()
			_push_runtime_bonus_values_to_player(true)
			_show_transient_message("击杀奖励达成\n获得卡牌：%s\n%s" % [
				String(card_row.get("name", card_row.get("id", "卡牌"))),
				String(card_row.get("description", "")),
			], 2.8)
		"attribute":
			var applied_text := _apply_attribute_reward(reward_value)
			_push_runtime_bonus_values_to_player(true)
			_show_transient_message("击杀奖励达成\n属性奖励生效\n%s" % applied_text, 2.8)
		"weapon":
			var weapon_row := ThresholdRewardPickerScript.pick_weapon(reward_value, weapon_rows)
			if weapon_row.is_empty():
				_show_transient_message("击杀奖励达成\n未找到可用武器奖励")
				return
			owned_weapons.append(weapon_row)
			_push_runtime_bonus_values_to_player(true)
			_show_transient_message("击杀奖励达成\n获得武器：%s\n%s" % [
				String(weapon_row.get("name", weapon_row.get("id", "武器"))),
				String(weapon_row.get("description", "")),
			], 2.9)
		_:
			_show_transient_message("击杀奖励达成\n未识别奖励：%s" % reward_type)


func _apply_attribute_reward(reward_value: String) -> String:
	var parts := reward_value.split(":", false, 1)
	if parts.size() != 2:
		return reward_value

	var stat_key := parts[0].strip_edges()
	var value_text := parts[1].strip_edges()
	var parsed := _parse_bonus_value_expression(stat_key, value_text)
	if parsed.is_empty():
		return reward_value

	var bonus_id: StringName = parsed.get("bonus_id", &"")
	var bonus_value: float = float(parsed.get("bonus_value", 0.0))
	_add_dict_bonus_value(reward_attribute_bonus_values, bonus_id, bonus_value)
	return "%s %s" % [stat_key, value_text]


func _parse_bonus_value_expression(stat_key: String, value_text: String) -> Dictionary:
	var cleaned_value := value_text.replace(" ", "")
	var is_percent := cleaned_value.ends_with("%")
	var numeric_text := cleaned_value.trim_suffix("%")
	var parsed_value := float(numeric_text)
	if is_percent:
		parsed_value *= 0.01

	var alias_key := stat_key.strip_edges().to_lower()
	if CARD_STAT_ALIAS_MAP.has(alias_key):
		var mapping: Dictionary = CARD_STAT_ALIAS_MAP[alias_key]
		if bool(mapping.get("default_to_percent", false)) and not is_percent and absf(parsed_value) > 1.0:
			parsed_value *= 0.01
		if bool(mapping.get("cdr_percent", false)):
			var haste_bonus := _convert_cdr_percent_to_haste(parsed_value)
			return {"bonus_id": &"skill_haste", "bonus_value": haste_bonus}
		if is_percent and mapping.has("percent_id"):
			return {"bonus_id": mapping["percent_id"], "bonus_value": parsed_value}
		if mapping.has("flat_id"):
			return {"bonus_id": mapping["flat_id"], "bonus_value": parsed_value}
		return {}

	return {
		"bonus_id": StringName(stat_key),
		"bonus_value": parsed_value,
	}


func _compose_all_bonus_values() -> Dictionary:
	var combined: Dictionary = runtime_bonus_values.duplicate(true)
	_merge_bonus_dictionary(combined, reward_attribute_bonus_values)
	_merge_bonus_dictionary(combined, passive_accumulated_bonus_values)
	_merge_bonus_dictionary(combined, passive_conditional_bonus_values)
	if weapon_growth_runtime != null:
		_merge_bonus_dictionary(combined, weapon_growth_runtime.get_bonus_values())

	for card_row in owned_cards:
		_merge_bonus_dictionary(combined, _build_card_bonus_values(card_row))
	for weapon_row in owned_weapons:
		_merge_bonus_dictionary(combined, _build_weapon_bonus_values(weapon_row))

	return combined


func _build_card_bonus_values(card_row: Dictionary) -> Dictionary:
	var parsed_effects := _extract_card_effects(card_row)
	var parsed_bonuses: Dictionary = parsed_effects.get("bonuses", {})
	if not parsed_bonuses.is_empty():
		return parsed_bonuses

	var stat_key := String(card_row.get("stat", "")).strip_edges()
	if stat_key.is_empty():
		return {}

	var value := float(card_row.get("value", 0.0))
	var parsed := _parse_bonus_value_expression(stat_key, str(value))
	if parsed.is_empty():
		return {}

	return {
		parsed.get("bonus_id", &""): parsed.get("bonus_value", 0.0),
	}


func _rebuild_owned_card_passives() -> void:
	owned_card_passives.clear()
	owned_card_runtime_specs.clear()
	for card_row in owned_cards:
		var parsed_effects := _extract_card_effects(card_row)
		var passive_lines: Array = parsed_effects.get("passives", [])
		for passive_entry in passive_lines:
			var passive_text := str(passive_entry).strip_edges()
			if passive_text.is_empty():
				continue
			owned_card_passives.append({
				"card_id": str(card_row.get("id", "")),
				"card_name": str(card_row.get("name", card_row.get("id", "卡牌"))),
				"description": passive_text,
			})
		for runtime_spec in _build_card_runtime_specs(card_row):
			owned_card_runtime_specs.append(runtime_spec)


func _process_card_runtime_effects(delta: float) -> void:
	if selection_active or battle_finished or player == null:
		return

	passive_tick_accumulator += delta
	if passive_tick_accumulator < PASSIVE_TICK_SECONDS:
		return

	var tick_delta := passive_tick_accumulator
	passive_tick_accumulator = 0.0
	_update_conditional_card_passives()

	var stats = _get_player_combat_stats()
	if stats == null:
		return

	var bonuses_changed := _apply_builtin_runtime_bonus_rates(stats, tick_delta)
	bonuses_changed = _apply_card_runtime_specs_for_second(stats, tick_delta) or bonuses_changed
	if bonuses_changed:
		_push_runtime_bonus_values_to_player(true)
		var refreshed_stats = _get_player_combat_stats()
		if refreshed_stats != null:
			stats = refreshed_stats

	var progress_changed := _apply_builtin_runtime_progress_rates(stats, tick_delta)
	if progress_changed:
		_sync_player_runtime_progress()
		if not game_over:
			_update_hud(player.health, player.max_health)


func _apply_card_passives_on_kill() -> void:
	var stats = _get_player_combat_stats()
	if stats == null:
		return

	var bonuses_changed := false
	var primary_attr_gain := float(stats.get_stat(&"primary_attr_per_kill"))
	if absf(primary_attr_gain) >= 0.0001:
		_add_passive_bonus_entries_from_text("主属性", primary_attr_gain, false)
		bonuses_changed = true

	bonuses_changed = _apply_card_runtime_specs_for_trigger("kill", stats, 1.0) or bonuses_changed
	if bonuses_changed:
		_push_runtime_bonus_values_to_player(true)


func _apply_card_passives_on_wave_cleared() -> void:
	var stats = _get_player_combat_stats()
	if stats == null:
		return

	var bonuses_changed := false
	var primary_attr_gain := float(stats.get_stat(&"primary_attr_per_wave"))
	if absf(primary_attr_gain) >= 0.0001:
		_add_passive_bonus_entries_from_text("主属性", primary_attr_gain, false)
		bonuses_changed = true

	bonuses_changed = _apply_card_runtime_specs_for_trigger("wave", stats, 1.0) or bonuses_changed
	if bonuses_changed:
		_push_runtime_bonus_values_to_player(true)


func _update_conditional_card_passives() -> void:
	var has_condition_spec := false
	for spec in owned_card_runtime_specs:
		if String(spec.get("kind", "")) == "condition_ratio":
			has_condition_spec = true
			break
	if not has_condition_spec and passive_conditional_bonus_values.is_empty():
		return
	var stats = _get_player_combat_stats()
	if stats == null:
		return

	var computed: Dictionary = {}
	for spec in owned_card_runtime_specs:
		if String(spec.get("kind", "")) != "condition_ratio":
			continue
		var source_value := _get_runtime_passive_source_value(String(spec.get("source", "")), stats)
		var source_step := maxf(float(spec.get("source_step", 0.0)), 0.0001)
		if source_value <= 0.0:
			continue

		var step_count: float = floor(source_value / source_step)
		if step_count <= 0.0:
			continue

		var total_value: float = step_count * float(spec.get("value_per_step", 0.0))
		var max_value := float(spec.get("max_value", -1.0))
		if max_value >= 0.0:
			total_value = minf(total_value, max_value)
		_append_bonus_entries_from_text(
			computed,
			String(spec.get("target_key", "")),
			total_value,
			bool(spec.get("target_is_percent", false))
		)

	passive_conditional_bonus_values = computed
	_push_runtime_bonus_values_to_player(true)


func _apply_builtin_runtime_bonus_rates(stats, delta: float) -> bool:
	var changed := false

	var primary_attr_gain := float(stats.get_stat(&"primary_attr_per_second")) * delta
	if absf(primary_attr_gain) >= 0.0001:
		_add_passive_bonus_entries_from_text("主属性", primary_attr_gain, false)
		changed = true

	var attack_power_gain := float(stats.get_stat(&"attack_power_per_second")) * delta
	if absf(attack_power_gain) >= 0.0001:
		_add_dict_bonus_value(passive_accumulated_bonus_values, &"added_attack_power", attack_power_gain)
		changed = true

	var health_gain := float(stats.get_stat(&"health_per_second")) * delta
	if absf(health_gain) >= 0.0001:
		_add_dict_bonus_value(passive_accumulated_bonus_values, &"added_health", health_gain)
		changed = true

	return changed


func _apply_builtin_runtime_progress_rates(stats, delta: float) -> bool:
	var changed := false

	var gold_rate := maxf(float(stats.get_stat(&"gold_per_second")), 0.0)
	if gold_rate > 0.0:
		var scaled_gold_rate := gold_rate * maxf(1.0 + float(stats.get_stat(&"gold_gain_percent")), 0.0)
		var gold_gain := _consume_fractional_progress("gold", scaled_gold_rate * delta)
		if gold_gain > 0:
			current_gold += gold_gain
			changed = true

	var exp_rate := maxf(float(stats.get_stat(&"exp_per_second")), 0.0)
	if exp_rate > 0.0:
		var scaled_exp_rate := exp_rate * maxf(1.0 + float(stats.get_stat(&"exp_gain_percent")), 0.0)
		var exp_gain := _consume_fractional_progress("exp", scaled_exp_rate * delta)
		if exp_gain > 0:
			current_exp += exp_gain
			changed = true

	var kill_rate := maxf(float(stats.get_stat(&"kill_count_per_second")), 0.0)
	if kill_rate > 0.0:
		var extra_kills := _consume_fractional_progress("kill_count", kill_rate * delta)
		if extra_kills > 0:
			kill_count += extra_kills
			_process_kill_reward_thresholds()
			changed = true

	if player != null and not player.is_dead:
		var health_gain := _consume_fractional_progress("health", maxf(float(stats.get_stat(&"health_regen")), 0.0) * delta)
		if health_gain > 0 and player.has_method("heal"):
			player.heal(health_gain)
			changed = true

		var mana_gain := _consume_fractional_progress("mana", maxf(float(stats.get_stat(&"mana_regen")), 0.0) * delta)
		if mana_gain > 0 and player.has_method("restore_mana"):
			player.restore_mana(mana_gain)
			changed = true

	return changed


func _apply_card_runtime_specs_for_second(_stats, delta: float) -> bool:
	var changed := false
	for spec in owned_card_runtime_specs:
		match String(spec.get("kind", "")):
			"periodic_bonus":
				if String(spec.get("trigger", "")) != "second":
					continue
				var applied_value := _consume_spec_amount(spec, float(spec.get("value", 0.0)) * delta)
				if absf(applied_value) < 0.0001:
					continue
				_add_passive_bonus_entries_from_text(
					String(spec.get("target_key", "")),
					applied_value,
					bool(spec.get("target_is_percent", false))
				)
				changed = true
			"periodic_progress":
				if String(spec.get("trigger", "")) != "second":
					continue
				var progress_value := float(spec.get("value", 0.0)) * delta
				var progress_stat := String(spec.get("progress_stat", ""))
				if progress_stat == "kill_count":
					var added_kills := _consume_fractional_progress("kill_count", progress_value)
					if added_kills > 0:
						kill_count += added_kills
						_process_kill_reward_thresholds()
						changed = true
				elif progress_stat == "gold":
					var added_gold := _consume_fractional_progress("gold", progress_value)
					if added_gold > 0:
						current_gold += added_gold
						changed = true
			"heal_percent":
				if String(spec.get("trigger", "")) != "second":
					continue
				if player == null or player.is_dead or not player.has_method("heal"):
					continue
				var regen_value: float = float(player.max_health) * float(spec.get("value", 0.0)) * delta
				var heal_amount := _consume_fractional_progress("health", regen_value)
				if heal_amount > 0:
					player.heal(heal_amount)
					changed = true
	return changed


func _apply_card_runtime_specs_for_trigger(trigger: String, stats, delta: float) -> bool:
	var changed := false
	for spec in owned_card_runtime_specs:
		var kind := String(spec.get("kind", ""))
		if String(spec.get("trigger", "")) != trigger:
			if not (kind == "condition_kill_progress" and trigger == "kill"):
				continue

		match kind:
			"periodic_bonus":
				var applied_value := _consume_spec_amount(spec, float(spec.get("value", 0.0)) * delta)
				if absf(applied_value) < 0.0001:
					continue
				_add_passive_bonus_entries_from_text(
					String(spec.get("target_key", "")),
					applied_value,
					bool(spec.get("target_is_percent", false))
				)
				changed = true
			"periodic_progress":
				var rounded_value := int(round(float(spec.get("value", 0.0)) * delta))
				var progress_stat := String(spec.get("progress_stat", ""))
				if rounded_value <= 0:
					continue
				if progress_stat == "kill_count":
					kill_count += rounded_value
					_process_kill_reward_thresholds()
					changed = true
				elif progress_stat == "gold":
					current_gold += rounded_value
					changed = true
			"condition_kill_progress":
				var threshold := float(spec.get("threshold", 0.0))
				var source_value := _get_runtime_passive_source_value(String(spec.get("source", "")), stats)
				var extra_value := int(round(float(spec.get("value", 0.0))))
				if source_value >= threshold and extra_value > 0:
					kill_count += extra_value
					_process_kill_reward_thresholds()
					changed = true
	return changed


func _build_card_runtime_specs(card_row: Dictionary) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	var description_lines := CardDescriptionTextScript.get_lines(card_row)
	for line in description_lines:
		var should_try_runtime := CardDescriptionTextScript.is_passive_line(line) or _parse_card_description_bonus_entries(line).is_empty()
		if not should_try_runtime:
			continue
		var spec := _build_card_runtime_spec_from_line(card_row, CardDescriptionTextScript.strip_passive_prefix(line), description_lines)
		if not spec.is_empty():
			specs.append(spec)
	return specs


func _build_card_runtime_spec_from_line(card_row: Dictionary, line: String, description_lines: Array[String]) -> Dictionary:
	var compact_line := line.replace(" ", "")
	if compact_line.is_empty():
		return {}

	var wave_match := _match_card_runtime_pattern("^每波收益:(主属性|力量|敏捷|智力|杀敌数)\\+(\\d+(?:\\.\\d+)?)$", compact_line)
	if wave_match != null:
		var wave_target := wave_match.get_string(1)
		var wave_value := float(wave_match.get_string(2))
		if wave_target == "杀敌数":
			return _make_card_runtime_spec(card_row, "periodic_progress", "wave", {"progress_stat": "kill_count", "value": wave_value})
		var wave_limit := _find_card_limit_value(description_lines, ["最多增加:", "最多累计:", "上限:"])
		return _make_card_runtime_spec(card_row, "periodic_bonus", "wave", {
			"target_key": wave_target,
			"value": wave_value,
			"target_is_percent": false,
			"progress_key": "%s:wave:%s" % [str(card_row.get("id", "")), wave_target],
			"max_value": float(wave_limit.get("value", -1.0)),
		})

	var second_match := _match_card_runtime_pattern("^每秒(基础)?(主属性|力量|敏捷|智力|攻击力)\\+(\\d+(?:\\.\\d+)?)$", compact_line)
	if second_match != null:
		var target_key := "%s%s" % [second_match.get_string(1), second_match.get_string(2)]
		return _make_card_runtime_spec(card_row, "periodic_bonus", "second", {
			"target_key": target_key,
			"value": float(second_match.get_string(3)),
			"target_is_percent": false,
			"progress_key": "%s:second:%s" % [str(card_row.get("id", "")), target_key],
			"max_value": -1.0,
		})

	var kill_match := _match_card_runtime_pattern("^杀敌(基础)?(主属性|力量|敏捷|智力|攻击力|杀敌数)\\+(\\d+(?:\\.\\d+)?)$", compact_line)
	if kill_match != null:
		var kill_target := "%s%s" % [kill_match.get_string(1), kill_match.get_string(2)]
		var kill_value := float(kill_match.get_string(3))
		if kill_target == "杀敌数":
			return _make_card_runtime_spec(card_row, "periodic_progress", "kill", {"progress_stat": "kill_count", "value": kill_value})
		return _make_card_runtime_spec(card_row, "periodic_bonus", "kill", {
			"target_key": kill_target,
			"value": kill_value,
			"target_is_percent": false,
			"progress_key": "%s:kill:%s" % [str(card_row.get("id", "")), kill_target],
			"max_value": -1.0,
		})

	var heal_match := _match_card_runtime_pattern("^每秒(?:回复)?最大生命(?:值)?(?:回复)?\\+(\\d+(?:\\.\\d+)?)%$", compact_line)
	if heal_match == null:
		heal_match = _match_card_runtime_pattern("^每秒生命回复\\+(\\d+(?:\\.\\d+)?)%$", compact_line)
	if heal_match != null:
		return _make_card_runtime_spec(card_row, "heal_percent", "second", {
			"value": float(heal_match.get_string(1)) * 0.01,
		})

	var primary_attack_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点主属性额外增加(\\d+(?:\\.\\d+)?)的攻击力$", compact_line)
	if primary_attack_match != null:
		return _make_condition_ratio_spec(card_row, "primary_attr", float(primary_attack_match.get_string(1)), "攻击力", float(primary_attack_match.get_string(2)), false, description_lines, [])

	var health_attack_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点最大生命值提供(\\d+(?:\\.\\d+)?)%点?攻击力$", compact_line)
	if health_attack_match != null:
		return _make_condition_ratio_spec(card_row, "max_health", float(health_attack_match.get_string(1)), "攻击力", float(health_attack_match.get_string(2)) * 0.01, true, description_lines, ["最大攻击力:", "最大值:", "上限:"])

	var health_primary_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点最大生命值提供(\\d+(?:\\.\\d+)?)%主属性增幅$", compact_line)
	if health_primary_match != null:
		return _make_condition_ratio_spec(card_row, "max_health", float(health_primary_match.get_string(1)), "主属性", float(health_primary_match.get_string(2)) * 0.01, true, description_lines, ["最大主属性增幅:", "最大属性值:", "上限:"])

	var on_hit_attack_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点攻击回复增加(\\d+(?:\\.\\d+)?)%攻击力$", compact_line)
	if on_hit_attack_match != null:
		return _make_condition_ratio_spec(card_row, "on_hit_heal", float(on_hit_attack_match.get_string(1)), "攻击力", float(on_hit_attack_match.get_string(2)) * 0.01, true, description_lines, ["最大上限:", "最大攻击力:", "上限:"])

	var mana_attack_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点最大法力值额外增加(\\d+(?:\\.\\d+)?)%普攻伤害$", compact_line)
	if mana_attack_match != null:
		return _make_condition_ratio_spec(card_row, "max_mana", float(mana_attack_match.get_string(1)), "普攻伤害", float(mana_attack_match.get_string(2)) * 0.01, true, description_lines, ["最大上限:", "最大值:", "上限:"])

	var mana_primary_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点最大法力值额外增加(\\d+(?:\\.\\d+)?)%主属性$", compact_line)
	if mana_primary_match != null:
		return _make_condition_ratio_spec(card_row, "max_mana", float(mana_primary_match.get_string(1)), "主属性", float(mana_primary_match.get_string(2)) * 0.01, true, description_lines, ["最大属性值:", "最大值:", "上限:"])

	var armor_primary_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点护甲提供(\\d+(?:\\.\\d+)?)%的?主属性$", compact_line)
	if armor_primary_match != null:
		return _make_condition_ratio_spec(card_row, "armor", float(armor_primary_match.get_string(1)), "主属性", float(armor_primary_match.get_string(2)) * 0.01, true, description_lines, ["最大主属性增幅:", "最大值:", "上限:"])

	var move_primary_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点额外移动速度主属性\\+(\\d+(?:\\.\\d+)?)%$", compact_line)
	if move_primary_match != null:
		return _make_condition_ratio_spec(card_row, "bonus_move_speed_flat", float(move_primary_match.get_string(1)), "主属性", float(move_primary_match.get_string(2)) * 0.01, true, description_lines, ["当前:", "上限:"])

	var armor_base_primary_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点护甲,?基础主属性\\+(\\d+(?:\\.\\d+)?)$", compact_line)
	if armor_base_primary_match != null:
		return _make_condition_ratio_spec(card_row, "armor", float(armor_base_primary_match.get_string(1)), "基础主属性", float(armor_base_primary_match.get_string(2)), false, description_lines, ["最多获取:", "最大值:", "上限:"])

	var armor_pen_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点护甲,?物理穿透\\+(\\d+(?:\\.\\d+)?)$", compact_line)
	if armor_pen_match != null:
		return _make_condition_ratio_spec(card_row, "armor", float(armor_pen_match.get_string(1)), "物理穿透", float(armor_pen_match.get_string(2)), false, description_lines, ["最多:", "上限:", "最大值:"])

	var armor_damage_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点护甲,?独立增伤\\+(\\d+(?:\\.\\d+)?)%$", compact_line)
	if armor_damage_match != null:
		return _make_condition_ratio_spec(card_row, "armor", float(armor_damage_match.get_string(1)), "独立增伤", float(armor_damage_match.get_string(2)) * 0.01, true, description_lines, ["独立增伤上限:", "最大值:", "上限:"])

	var base_str_damage_match := _match_card_runtime_pattern("^每有(\\d+(?:\\.\\d+)?)点基础力量,独立增伤\\+(\\d+(?:\\.\\d+)?)%$", compact_line)
	if base_str_damage_match != null:
		return _make_condition_ratio_spec(card_row, "base_str", float(base_str_damage_match.get_string(1)), "独立增伤", float(base_str_damage_match.get_string(2)) * 0.01, true, description_lines, ["最多增加独立增伤:", "最大值:", "上限:"])

	var base_agi_pen_match := _match_card_runtime_pattern("^每有(\\d+(?:\\.\\d+)?)点基础敏捷,物理穿透\\+(\\d+(?:\\.\\d+)?)%$", compact_line)
	if base_agi_pen_match != null:
		return _make_condition_ratio_spec(card_row, "base_agi", float(base_agi_pen_match.get_string(1)), "物理穿透", float(base_agi_pen_match.get_string(2)) * 0.01, true, description_lines, ["最大值:", "上限:"])

	var weapon_rate_match := _match_card_runtime_pattern("^每(\\d+(?:\\.\\d+)?)点主属性增加(\\d+(?:\\.\\d+)?)%武器释放频率$", compact_line)
	if weapon_rate_match != null:
		return _make_condition_ratio_spec(card_row, "primary_attr", float(weapon_rate_match.get_string(1)), "武器释放频率", float(weapon_rate_match.get_string(2)) * 0.01, true, description_lines, ["最大值:", "上限:"])

	var crit_overflow_match := _match_card_runtime_pattern("^溢出的每(\\d+(?:\\.\\d+)?)%暴击率转换为(\\d+(?:\\.\\d+)?)%的?暴击伤害$", compact_line)
	if crit_overflow_match != null:
		return _make_condition_ratio_spec(card_row, "crit_rate_overflow", float(crit_overflow_match.get_string(1)) * 0.01, "暴击伤害", float(crit_overflow_match.get_string(2)) * 0.01, true, description_lines, ["最大值:", "上限:"])

	var threshold_kill_match := _match_card_runtime_pattern("^如果你至少拥有(\\d+(?:\\.\\d+)?)(基础力量|基础敏捷|基础智力),则杀敌时额外\\+(\\d+(?:\\.\\d+)?)杀敌数$", compact_line)
	if threshold_kill_match != null:
		var source_key := "base_str"
		match threshold_kill_match.get_string(2):
			"基础敏捷":
				source_key = "base_agi"
			"基础智力":
				source_key = "base_int"
		return _make_card_runtime_spec(card_row, "condition_kill_progress", "kill", {
			"source": source_key,
			"threshold": float(threshold_kill_match.get_string(1)),
			"value": float(threshold_kill_match.get_string(3)),
		})

	return {}


func _make_card_runtime_spec(card_row: Dictionary, kind: String, trigger: String, payload: Dictionary) -> Dictionary:
	var spec := {
		"card_id": str(card_row.get("id", "")),
		"card_name": str(card_row.get("name", card_row.get("id", "卡牌"))),
		"kind": kind,
		"trigger": trigger,
	}
	for key in payload.keys():
		spec[key] = payload[key]
	return spec


func _make_condition_ratio_spec(card_row: Dictionary, source: String, source_step: float, target_key: String, value_per_step: float, target_is_percent: bool, description_lines: Array[String], limit_prefixes: Array[String]) -> Dictionary:
	var limit := _find_card_limit_value(description_lines, limit_prefixes)
	return _make_card_runtime_spec(card_row, "condition_ratio", "always", {
		"source": source,
		"source_step": source_step,
		"target_key": target_key,
		"value_per_step": value_per_step,
		"target_is_percent": target_is_percent,
		"max_value": float(limit.get("value", -1.0)),
	})


func _match_card_runtime_pattern(pattern: String, line: String) -> RegExMatch:
	return _search_cached_regex(pattern, line)


func _search_cached_regex(pattern: String, text: String) -> RegExMatch:
	if regex_cache == null:
		regex_cache = RegexCacheScript.new()
	return regex_cache.search(pattern, text)


func _find_card_limit_value(description_lines: Array[String], prefixes: Array[String]) -> Dictionary:
	for raw_line in description_lines:
		var compact_line := CardDescriptionTextScript.strip_passive_prefix(raw_line).replace(" ", "")
		for prefix in prefixes:
			if compact_line.begins_with(prefix):
				return _parse_numeric_value_token(compact_line.substr(prefix.length()))
	return {}


func _parse_numeric_value_token(text: String) -> Dictionary:
	var match := _search_cached_regex("(-?\\d+(?:\\.\\d+)?)(%)?", text)
	if match == null:
		return {}
	var value := float(match.get_string(1))
	if match.get_string(2) == "%":
		value *= 0.01
	return {"value": value}


func _get_runtime_passive_source_value(source: String, stats) -> float:
	match source:
		"primary_attr":
			return stats.get_primary_attr_value() if stats != null and stats.has_method("get_primary_attr_value") else 0.0
		"base_primary_attr":
			var primary_attr_name := _get_active_primary_attr_name()
			return stats.get_stat(StringName("base_%s" % String(primary_attr_name)))
		"crit_rate_overflow":
			return maxf(float(stats.get_stat(&"crit_rate")) - 1.0, 0.0)
		_:
			return float(stats.get_stat(StringName(source)))


func _append_bonus_entries_from_text(target: Dictionary, target_key: String, value: float, is_percent: bool) -> void:
	var entries := _resolve_card_description_bonus_entries(target_key, value, is_percent)
	for entry in entries:
		var bonus_id: StringName = entry.get("bonus_id", &"")
		var bonus_value := float(entry.get("bonus_value", 0.0))
		if bonus_id == &"" or absf(bonus_value) < 0.0001:
			continue
		_add_dict_bonus_value(target, bonus_id, bonus_value)


func _add_passive_bonus_entries_from_text(target_key: String, value: float, is_percent: bool) -> void:
	_append_bonus_entries_from_text(passive_accumulated_bonus_values, target_key, value, is_percent)


func _consume_spec_amount(spec: Dictionary, raw_amount: float) -> float:
	var amount := raw_amount
	var max_value := float(spec.get("max_value", -1.0))
	if max_value < 0.0:
		return amount

	var progress_key := String(spec.get("progress_key", ""))
	if progress_key.is_empty():
		return minf(amount, max_value)

	var accumulated := float(passive_spec_progress.get(progress_key, 0.0))
	var remaining := maxf(max_value - accumulated, 0.0)
	amount = minf(amount, remaining)
	if amount <= 0.0:
		return 0.0
	passive_spec_progress[progress_key] = accumulated + amount
	return amount


func _consume_fractional_progress(key: String, delta_value: float) -> int:
	if absf(delta_value) < 0.0001:
		return 0
	var stored := float(passive_fractional_progress.get(key, 0.0)) + delta_value
	var whole_value := int(floor(stored))
	passive_fractional_progress[key] = stored - whole_value
	return whole_value


func _extract_card_effects(card_row: Dictionary) -> Dictionary:
	var bonuses: Dictionary = {}
	var passives: Array[String] = []
	var description := str(card_row.get("description", ""))
	var lines := description.split("\n", false)
	var append_to_last_passive := false

	for raw_line in lines:
		var line := CardDescriptionTextScript.normalize_line(str(raw_line))
		if line.is_empty():
			continue
		if CardDescriptionTextScript.is_passive_line(line):
			passives.append(line)
			append_to_last_passive = true
			continue
		if append_to_last_passive:
			passives[passives.size() - 1] = "%s\n%s" % [passives[passives.size() - 1], line]
			continue

		var parsed_entries := _parse_card_description_bonus_entries(line)
		if not parsed_entries.is_empty():
			for entry in parsed_entries:
				var bonus_id: StringName = entry.get("bonus_id", &"")
				var bonus_value := float(entry.get("bonus_value", 0.0))
				if bonus_id == &"" or absf(bonus_value) < 0.0001:
					continue
				_add_dict_bonus_value(bonuses, bonus_id, bonus_value)
			continue

		if not CardDescriptionTextScript.should_ignore_line(line):
			passives.append(line)
			append_to_last_passive = true

	return {
		"bonuses": bonuses,
		"passives": passives,
	}


func _parse_card_description_bonus_entries(line: String) -> Array:
	var match := _search_cached_regex("^(.*?)([+-])\\s*(\\d+(?:\\.\\d+)?)\\s*(%)?\\s*(秒)?$", line)
	if match == null:
		return []

	var raw_key := match.get_string(1).strip_edges()
	if raw_key.is_empty():
		return []

	var numeric_sign := -1.0 if match.get_string(2) == "-" else 1.0
	var parsed_value := numeric_sign * float(match.get_string(3))
	var is_percent := match.get_string(4) == "%"
	if is_percent:
		parsed_value *= 0.01

	return _resolve_card_description_bonus_entries(raw_key, parsed_value, is_percent)


func _resolve_card_description_bonus_entries(raw_key: String, parsed_value: float, is_percent: bool) -> Array:
	var normalized_key := raw_key.replace(" ", "")

	match normalized_key:
		"主属性":
			return _build_primary_attribute_bonus_entries(_get_primary_attr_names(), parsed_value, is_percent, false)
		"基础主属性":
			return _build_primary_attribute_bonus_entries(_get_primary_attr_names(), parsed_value, is_percent, true)
		"副属性":
			return _build_primary_attribute_bonus_entries(_get_secondary_attr_names(), parsed_value, is_percent, false)
		"基础副属性":
			return _build_primary_attribute_bonus_entries(_get_secondary_attr_names(), parsed_value, is_percent, true)
		"力量":
			return _build_primary_attribute_bonus_entries([&"str"], parsed_value, is_percent, false)
		"基础力量":
			return _build_primary_attribute_bonus_entries([&"str"], parsed_value, is_percent, true)
		"敏捷":
			return _build_primary_attribute_bonus_entries([&"agi"], parsed_value, is_percent, false)
		"基础敏捷":
			return _build_primary_attribute_bonus_entries([&"agi"], parsed_value, is_percent, true)
		"智力":
			return _build_primary_attribute_bonus_entries([&"int"], parsed_value, is_percent, false)
		"基础智力":
			return _build_primary_attribute_bonus_entries([&"int"], parsed_value, is_percent, true)
		"每秒主属性":
			return [{"bonus_id": &"primary_attr_per_second", "bonus_value": parsed_value}]
		"每波收益:主属性":
			return [{"bonus_id": &"primary_attr_per_wave", "bonus_value": parsed_value}]
		"杀敌主属性":
			return [{"bonus_id": &"primary_attr_per_kill", "bonus_value": parsed_value}]
		_:
			if not CARD_DESCRIPTION_ALIAS_MAP.has(normalized_key):
				return []
			return _build_bonus_entries_from_mapping(CARD_DESCRIPTION_ALIAS_MAP[normalized_key], parsed_value, is_percent)


func _build_primary_attribute_bonus_entries(attr_names: Array, parsed_value: float, is_percent: bool, use_base_stat: bool) -> Array:
	var entries: Array = []
	for attr_name in attr_names:
		var name_key := StringName(str(attr_name))
		if name_key == &"":
			continue
		var bonus_id := &""
		if use_base_stat:
			bonus_id = StringName("base_%s" % str(name_key))
		elif is_percent:
			bonus_id = StringName("%s_percent" % str(name_key))
		else:
			bonus_id = StringName("added_%s" % str(name_key))
		entries.append({
			"bonus_id": bonus_id,
			"bonus_value": parsed_value,
		})
	return entries


func _get_primary_attr_names() -> Array:
	return [_get_active_primary_attr_name()]


func _get_secondary_attr_names() -> Array:
	var primary_attr := _get_active_primary_attr_name()
	var secondary_attrs: Array = []
	for attr_name in [&"str", &"agi", &"int"]:
		if attr_name != primary_attr:
			secondary_attrs.append(attr_name)
	return secondary_attrs


func _get_active_primary_attr_name() -> StringName:
	if selected_hero != null:
		return selected_hero.primary_attr
	if player != null and player.hero_data != null:
		return player.hero_data.primary_attr
	return &"str"


func _build_bonus_entries_from_mapping(mapping: Dictionary, parsed_value: float, is_percent: bool) -> Array:
	var adjusted_value := parsed_value
	if bool(mapping.get("default_to_percent", false)) and not is_percent and absf(adjusted_value) > 1.0:
		adjusted_value *= 0.01

	match str(mapping.get("convert_mode", "")):
		"attack_interval":
			adjusted_value = _convert_interval_change_to_attack_speed_bonus(adjusted_value)
		"interval_reduce":
			adjusted_value = -adjusted_value

	var target_ids = null
	if is_percent and mapping.has("percent_ids"):
		target_ids = mapping.get("percent_ids", [])
	elif is_percent and mapping.has("percent_id"):
		target_ids = mapping.get("percent_id", &"")
	elif mapping.has("flat_ids"):
		target_ids = mapping.get("flat_ids", [])
	else:
		target_ids = mapping.get("flat_id", &"")

	var entries: Array = []
	if target_ids is Array:
		for target_id in target_ids:
			var key := StringName(str(target_id))
			if key == &"":
				continue
			entries.append({
				"bonus_id": key,
				"bonus_value": adjusted_value,
			})
	else:
		var single_key := StringName(str(target_ids))
		if single_key != &"":
			entries.append({
				"bonus_id": single_key,
				"bonus_value": adjusted_value,
			})
	return entries


func _convert_interval_change_to_attack_speed_bonus(interval_delta: float) -> float:
	if absf(interval_delta) < 0.0001:
		return 0.0
	return (1.0 / maxf(1.0 + interval_delta, 0.05)) - 1.0


func _build_weapon_bonus_values(weapon_row: Dictionary) -> Dictionary:
	var weapon_id := String(weapon_row.get("id", "")).strip_edges()
	var quality := maxf(float(weapon_row.get("quality", 1)), 1.0)
	var weapon_type := String(weapon_row.get("type", "")).strip_edges().to_lower()
	var param1 := float(weapon_row.get("param1", 0.0))
	var param2 := float(weapon_row.get("param2", 0.0))
	var cooldown := maxf(float(weapon_row.get("cooldown", 0.0)), 0.0)
	var trigger_type := String(weapon_row.get("trigger_type", "")).strip_edges().to_lower()
	var cast_rate_bonus := 0.0
	if cooldown > 0.0:
		cast_rate_bonus = minf(0.08 + 1.2 / (cooldown + 1.6), 0.34)

	var bonuses: Dictionary = {}
	_add_dict_bonus_value(bonuses, &"weapon_cast_rate_percent", cast_rate_bonus)

	match trigger_type:
		"projectile":
			_add_dict_bonus_value(bonuses, &"projectile_weapon_damage_ratio", maxf(param1, 1.0) * (0.14 + quality * 0.03))
			_add_dict_bonus_value(bonuses, &"weapon_damage_ratio", 0.04 * quality)
		"aoe":
			_add_dict_bonus_value(bonuses, &"weapon_final_damage_percent", 0.04 + quality * 0.02)
			_add_dict_bonus_value(bonuses, &"weapon_damage_ratio", maxf(param2, 1.0) * 0.008)
		"summon":
			_add_dict_bonus_value(bonuses, &"pet_final_damage_percent", 0.06 + quality * 0.025)
			_add_dict_bonus_value(bonuses, &"weapon_damage_ratio", maxf(param1, 1.0) * 0.05)
		"passive":
			_add_dict_bonus_value(bonuses, &"final_damage_percent", maxf(param1, 0.04))
			_add_dict_bonus_value(bonuses, &"gear_skill_attack_speed_percent", maxf(param1 * 0.5, 0.04))
		_:
			_add_dict_bonus_value(bonuses, &"weapon_damage_ratio", 0.05 * quality)

	match weapon_type:
		"blade":
			_add_dict_bonus_value(bonuses, &"bonus_attack_power", 2.0 + quality * 2.0)
			_add_dict_bonus_value(bonuses, &"basic_attack_damage_percent", 0.03 * quality)
		"magic":
			_add_dict_bonus_value(bonuses, &"magic_damage_percent", 0.04 * quality)
		"summon":
			_add_dict_bonus_value(bonuses, &"pet_final_damage_percent", 0.03 * quality)
		"aura":
			_add_dict_bonus_value(bonuses, &"gear_skill_attack_speed_percent", maxf(param1 * 0.65, 0.05))
			_add_dict_bonus_value(bonuses, &"gold_gain_percent", 0.02 * quality)

	match weapon_id:
		"war_banner":
			_add_dict_bonus_value(bonuses, &"gear_skill_attack_speed_percent", maxf(param1 * 0.45, 0.04))
			_add_dict_bonus_value(bonuses, &"final_damage_percent", maxf(param1 * 0.5, 0.05))
		"blood_blade":
			_add_dict_bonus_value(bonuses, &"bonus_attack_power", maxf(param1, 1.0) * 2.0)
			_add_dict_bonus_value(bonuses, &"projectile_weapon_damage_ratio", 0.1)
		"frost_ring":
			_add_dict_bonus_value(bonuses, &"magic_damage_percent", 0.03)
			_add_dict_bonus_value(bonuses, &"weapon_final_damage_percent", 0.02)
		"wolf_totem":
			_add_dict_bonus_value(bonuses, &"pet_final_damage_percent", 0.05)

	return bonuses


func _merge_bonus_dictionary(target: Dictionary, source: Dictionary) -> void:
	for raw_key in source.keys():
		var key := StringName(String(raw_key))
		_add_dict_bonus_value(target, key, float(source[raw_key]))


func _add_dict_bonus_value(target: Dictionary, stat_id: StringName, value: float) -> void:
	var key_text := String(stat_id).strip_edges()
	if key_text.is_empty():
		return

	var key := StringName(key_text)
	target[key] = float(target.get(key, 0.0)) + value
	if absf(float(target[key])) < 0.0001:
		target.erase(key)


func _convert_cdr_percent_to_haste(cdr_value: float) -> float:
	var clamped_cdr := clampf(cdr_value, -0.95, 0.84)
	if clamped_cdr <= 0.0:
		return clamped_cdr * 100.0
	return 100.0 * clamped_cdr / maxf(1.0 - clamped_cdr, 0.01)


func _reload_data_tables() -> void:
	var data_table := _get_data_table_node()
	if data_table != null:
		data_table.call("reload_all")
	if data_table_provider != null:
		data_table_provider.invalidate()
	if runtime_enemy_snapshot != null:
		runtime_enemy_snapshot.invalidate()
	if template_bloodline_option_index != null:
		template_bloodline_option_index.clear()
	if selection_state != null:
		selection_state.mark_dirty()


func _setup_card_runtime_ui() -> void:
	_setup_card_collection_button()
	_setup_card_collection_overlay()
	_setup_card_choice_overlay()
	_setup_card_collect_effect_layer()
	_refresh_card_collection_button_state()


func _setup_card_collection_button() -> void:
	card_collection_button = Button.new()
	card_collection_button.name = "CardCollectionButton"
	card_collection_button.anchor_left = 0.0
	card_collection_button.anchor_top = 0.0
	card_collection_button.anchor_right = 0.0
	card_collection_button.anchor_bottom = 0.0
	card_collection_button.offset_left = 314.0
	card_collection_button.offset_top = 14.0
	card_collection_button.offset_right = 446.0
	card_collection_button.offset_bottom = 54.0
	card_collection_button.focus_mode = Control.FOCUS_NONE
	card_collection_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card_collection_button.text = CARD_COLLECTION_BUTTON_TEXT
	card_collection_button.visible = false
	card_collection_button.process_mode = Node.PROCESS_MODE_ALWAYS
	card_collection_button.pressed.connect(_on_card_collection_button_pressed)
	_apply_card_collection_button_style()
	if hud != null:
		hud.add_runtime_ui(card_collection_button)


func _setup_card_collection_overlay() -> void:
	card_collection_overlay = CARD_COLLECTION_SCENE.instantiate() as CardCollectionOverlayUi
	card_collection_overlay.name = "CardCollectionOverlay"
	card_collection_overlay.visible = false
	card_collection_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_process_mode_recursive(card_collection_overlay, Node.PROCESS_MODE_ALWAYS)
	if hud != null:
		hud.add_runtime_ui(card_collection_overlay)
	if not card_collection_overlay.close_requested.is_connected(_hide_card_collection.bind(true)):
		card_collection_overlay.close_requested.connect(_hide_card_collection.bind(true))
	if not card_collection_overlay.sort_mode_changed.is_connected(_on_card_collection_sort_button_pressed):
		card_collection_overlay.sort_mode_changed.connect(_on_card_collection_sort_button_pressed)
	if not card_collection_overlay.stack_selected.is_connected(_on_card_collection_stack_selected):
		card_collection_overlay.stack_selected.connect(_on_card_collection_stack_selected)
	card_collection_overlay.clear_collection()


func _setup_card_choice_overlay() -> void:
	card_choice_overlay = CARD_CHOICE_SCENE.instantiate() as CardChoiceOverlayUi
	card_choice_overlay.name = "CardChoiceOverlay"
	card_choice_overlay.visible = false
	card_choice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_process_mode_recursive(card_choice_overlay, Node.PROCESS_MODE_ALWAYS)
	if hud != null:
		hud.add_runtime_ui(card_choice_overlay)
	if not card_choice_overlay.option_selected.is_connected(_on_card_choice_selected):
		card_choice_overlay.option_selected.connect(_on_card_choice_selected)
	if not card_choice_overlay.refresh_requested.is_connected(_on_card_choice_refresh_pressed):
		card_choice_overlay.refresh_requested.connect(_on_card_choice_refresh_pressed)
	card_choice_overlay.clear_choices()


func _set_process_mode_recursive(node: Node, mode: Node.ProcessMode) -> void:
	if node == null:
		return
	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)


func _setup_card_collect_effect_layer() -> void:
	card_collect_effect_layer = Control.new()
	card_collect_effect_layer.name = "CardCollectEffectLayer"
	card_collect_effect_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_collect_effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_collect_effect_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	if hud != null:
		hud.add_runtime_ui(card_collect_effect_layer)


func _update_runtime_pause_state() -> void:
	var should_pause := attributes_panel_visible or card_choice_overlay_visible or card_collection_visible
	get_tree().paused = should_pause


func _on_card_collection_button_pressed() -> void:
	if card_collection_visible:
		_hide_card_collection(true)
	else:
		_show_card_collection()


func _show_card_collection() -> void:
	if selection_active or game_over or card_choice_overlay_visible:
		return
	_rebuild_card_collection_ui()
	card_collection_visible = true
	if card_collection_overlay != null:
		card_collection_overlay.visible = true
		card_collection_overlay.move_to_front()
		card_collection_overlay.grab_close_focus()
	if card_collect_effect_layer != null:
		card_collect_effect_layer.move_to_front()
	_update_runtime_pause_state()


func _hide_card_collection(restore_pause_state: bool = true) -> void:
	card_collection_visible = false
	card_collection_selected_stack_key = ""
	if card_collection_overlay != null:
		card_collection_overlay.clear_collection()
		card_collection_overlay.visible = false
	if restore_pause_state:
		_update_runtime_pause_state()


func _debug_open_card_choice() -> void:
	_try_open_card_choice_overlay(CARD_CHOICE_DEBUG_TITLE)


func _try_open_card_choice_overlay(title: String) -> bool:
	if selection_active or game_over or player_respawning or battle_finished:
		return false
	if card_choice_overlay_request_pending:
		return false
	if card_choice_overlay_visible or card_collection_visible:
		return false
	if card_rows.is_empty():
		_show_transient_message("当前卡池为空，无法打开神权三选一。")
		return false
	if attributes_panel_visible:
		_hide_attributes_panel()
	var choice_rows := _draw_random_card_choices(CARD_CHOICE_DRAW_COUNT)
	choice_rows = _ensure_demo_card_choice_visible(choice_rows)
	if choice_rows.is_empty():
		_show_transient_message("当前没有可用于抽取的神权。")
		return false
	_show_card_choice_overlay(choice_rows, title)
	return true


func _request_queued_card_choice_overlay() -> void:
	if queued_card_choice_pickups <= 0:
		return
	if card_choice_overlay_request_pending:
		return
	if selection_active or game_over or player_respawning or battle_finished:
		return
	if card_choice_overlay_visible or card_collection_visible:
		return
	card_choice_overlay_request_pending = true
	_play_card_choice_focus_effect()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.12)
	tween.tween_callback(Callable(self, "_open_queued_card_choice_overlay"))


func _open_queued_card_choice_overlay() -> void:
	card_choice_overlay_request_pending = false
	if queued_card_choice_pickups <= 0:
		return
	if _try_open_card_choice_overlay(CARD_CHOICE_PICKUP_TITLE):
		queued_card_choice_pickups = maxi(queued_card_choice_pickups - 1, 0)


func _show_card_choice_overlay(choice_rows: Array[Dictionary], title: String) -> void:
	card_choice_rows = choice_rows.duplicate(true)
	card_choice_selected_index = -1
	card_choice_refresh_remaining = CARD_CHOICE_DEFAULT_REFRESH_COUNT
	card_choice_title_text = title
	card_choice_overlay_visible = true
	if card_choice_overlay != null:
		card_choice_overlay.visible = true
		card_choice_overlay.move_to_front()
		card_choice_overlay.configure_choices(_build_card_choice_ui_rows(card_choice_rows), card_choice_title_text, card_choice_refresh_remaining)
		card_choice_overlay.play_open_transition()
	if card_collect_effect_layer != null:
		card_collect_effect_layer.move_to_front()
	_update_runtime_pause_state()


func _hide_card_choice_overlay(restore_pause_state: bool = true) -> void:
	card_choice_overlay_visible = false
	card_choice_rows.clear()
	card_choice_selected_index = -1
	card_choice_refresh_remaining = 0
	card_choice_title_text = CARD_CHOICE_DEBUG_TITLE
	if card_choice_overlay != null:
		card_choice_overlay.clear_choices()
		card_choice_overlay.visible = false
	if restore_pause_state:
		_update_runtime_pause_state()
	_request_queued_card_choice_overlay()


func _draw_random_card_choices(draw_count: int) -> Array[Dictionary]:
	var picked: Array[Dictionary] = []
	var used_ids: Dictionary = {}
	var safe_draw_count := clampi(draw_count, 1, maxi(card_rows.size(), 1))
	var guard := 0
	while picked.size() < safe_draw_count and guard < card_rows.size() * 12:
		guard += 1
		var candidate: Dictionary = card_rows[randi() % card_rows.size()]
		var card_id := String(candidate.get("id", "")).strip_edges()
		if card_id.is_empty() or used_ids.has(card_id):
			continue
		used_ids[card_id] = true
		picked.append(candidate.duplicate(true))
	return picked


func _ensure_demo_card_choice_visible(choice_rows: Array[Dictionary]) -> Array[Dictionary]:
	if choice_rows.is_empty():
		return choice_rows
	var demo_names := CARD_CHOICE_DEMO_ICON_BY_NAME.keys()
	if demo_names.is_empty():
		return choice_rows
	for row in choice_rows:
		if CARD_CHOICE_DEMO_ICON_BY_NAME.has(String(row.get("name", "")).strip_edges()):
			return choice_rows
	var demo_row := _find_card_row_by_name(String(demo_names[0]))
	if demo_row.is_empty():
		return choice_rows
	var output := choice_rows.duplicate(true)
	output[0] = demo_row.duplicate(true)
	return output


func _find_card_row_by_name(target_name: String) -> Dictionary:
	var normalized_target := target_name.strip_edges()
	if normalized_target.is_empty():
		return {}
	for row in card_rows:
		if String(row.get("name", "")).strip_edges() == normalized_target:
			return row
	return {}


func _build_card_choice_ui_rows(source_rows: Array[Dictionary]) -> Array[Dictionary]:
	var ui_rows: Array[Dictionary] = []
	for row in source_rows:
		var ui_row := row.duplicate(true)
		ui_row["owned_count"] = CardCollectionBuilderScript.count_owned_card(owned_cards, row)
		ui_row["icon_texture"] = _resolve_card_icon(row)
		ui_rows.append(ui_row)
	return ui_rows


func _build_card_collection_ui_stack_infos() -> Array[Dictionary]:
	var ui_stack_infos: Array[Dictionary] = []
	for stack_info in CardCollectionBuilderScript.build_stack_infos(owned_cards, card_collection_sort_mode):
		var ui_stack_info := stack_info.duplicate(true)
		var card_row: Dictionary = ui_stack_info.get("row", {})
		ui_stack_info["icon_texture"] = _resolve_card_icon(card_row)
		ui_stack_infos.append(ui_stack_info)
	return ui_stack_infos


func _on_card_choice_refresh_pressed() -> void:
	if not card_choice_overlay_visible:
		return
	if card_choice_refresh_remaining <= 0:
		return
	card_choice_refresh_remaining -= 1
	var draw_count := maxi(card_choice_rows.size(), CARD_CHOICE_DRAW_COUNT)
	card_choice_rows = _ensure_demo_card_choice_visible(_draw_random_card_choices(draw_count))
	card_choice_selected_index = -1
	if card_choice_overlay != null:
		card_choice_overlay.configure_choices(_build_card_choice_ui_rows(card_choice_rows), card_choice_title_text, card_choice_refresh_remaining)


func _on_card_choice_selected(index: int) -> void:
	if index < 0 or index >= card_choice_rows.size():
		return
	if card_choice_selected_index == -2:
		return
	card_choice_selected_index = -2
	if card_choice_overlay != null:
		card_choice_overlay.set_interaction_locked(true)
	var chosen_row := card_choice_rows[index].duplicate(true)
	var source_center := card_choice_overlay.get_option_global_center(index) if card_choice_overlay != null else Vector2.ZERO
	_add_owned_card(chosen_row)
	_play_card_collect_animation(chosen_row, source_center)


func _add_owned_card(card_row: Dictionary) -> void:
	owned_cards.append(card_row.duplicate(true))
	_rebuild_owned_card_passives()
	_push_runtime_bonus_values_to_player(true)
	_refresh_card_collection_button_state()
	if card_collection_visible:
		_rebuild_card_collection_ui()


func _play_card_collect_animation(card_row: Dictionary, source_center: Vector2) -> void:
	if card_collect_effect_layer == null or card_collection_button == null:
		_hide_card_choice_overlay(true)
		return
	var effect_card := _build_card_collect_effect(card_row)
	card_collect_effect_layer.add_child(effect_card)
	effect_card.global_position = source_center - effect_card.size * 0.5
	var target_center := _get_control_global_center(card_collection_button)
	var target_position := target_center - effect_card.size * 0.5
	var tween := card_collect_effect_layer.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(effect_card, "global_position", target_position, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(effect_card, "scale", Vector2(0.42, 0.42), 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(effect_card, "modulate", Color(1.0, 1.0, 1.0, 0.35), 0.42)
	tween.tween_callback(Callable(effect_card, "queue_free"))
	tween.tween_callback(Callable(self, "_pulse_card_collection_button"))
	tween.tween_callback(Callable(self, "_hide_card_choice_overlay").bind(true))


func _build_card_collect_effect(card_row: Dictionary) -> Control:
	var tier := int(card_row.get("tier", 0))
	var colors := _get_card_tier_colors(tier)
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(58.0, 58.0)
	panel.size = Vector2(58.0, 58.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var style := StyleBoxFlat.new()
	style.bg_color = colors.get("bg", Color(0.14, 0.16, 0.13, 0.96))
	style.border_color = colors.get("border", Color(0.82, 0.77, 0.59, 1.0))
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var icon_texture := _resolve_card_icon(card_row)
	if icon_texture != null:
		var icon_rect := TextureRect.new()
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_rect.offset_left = 8.0
		icon_rect.offset_top = 8.0
		icon_rect.offset_right = -8.0
		icon_rect.offset_bottom = -8.0
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = icon_texture
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon_rect)
	else:
		var label := Label.new()
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.text = CardDisplayTextScript.build_placeholder(String(card_row.get("name", card_row.get("id", "神权"))))
		label.add_theme_font_size_override("font_size", 22)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
	return panel


func _pulse_card_collection_button() -> void:
	if card_collection_button == null:
		return
	card_collection_button.scale = Vector2.ONE
	var tween := card_collection_button.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(card_collection_button, "scale", Vector2(1.06, 1.06), 0.12)
	tween.tween_property(card_collection_button, "scale", Vector2.ONE, 0.14)


func _refresh_card_collection_button_state() -> void:
	if card_collection_button == null:
		return
	card_collection_button.text = "%s x%d" % [CARD_COLLECTION_BUTTON_TEXT, owned_cards.size()]


func _rebuild_card_collection_ui() -> void:
	if card_collection_overlay == null:
		return
	var stack_infos := _build_card_collection_ui_stack_infos()
	if card_collection_selected_stack_key.is_empty() and not stack_infos.is_empty():
		card_collection_selected_stack_key = String(stack_infos[0].get("stack_key", "")).strip_edges()
	card_collection_overlay.configure_collection(stack_infos, card_collection_selected_stack_key, card_collection_sort_mode)


func _on_card_collection_sort_button_pressed(mode: String) -> void:
	if mode != CARD_COLLECTION_SORT_TIME and mode != CARD_COLLECTION_SORT_QUALITY:
		return
	if card_collection_sort_mode == mode:
		return
	card_collection_sort_mode = mode
	if card_collection_visible:
		_rebuild_card_collection_ui()


func _on_card_collection_stack_selected(stack_key: String) -> void:
	card_collection_selected_stack_key = stack_key.strip_edges()


func _apply_card_collection_button_style() -> void:
	if card_collection_button == null:
		return
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.18, 0.12, 0.07, 0.94)
	normal_style.border_color = Color(0.96, 0.79, 0.42, 1.0)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(12)
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.26, 0.16, 0.08, 0.98)
	hover_style.border_color = Color(1.0, 0.92, 0.62, 1.0)
	card_collection_button.add_theme_stylebox_override("normal", normal_style)
	card_collection_button.add_theme_stylebox_override("hover", hover_style)
	card_collection_button.add_theme_stylebox_override("pressed", hover_style)
	card_collection_button.add_theme_stylebox_override("focus", hover_style)
	card_collection_button.add_theme_font_size_override("font_size", 18)
	card_collection_button.add_theme_color_override("font_color", Color(0.98, 0.97, 0.92, 1.0))


func _get_card_tier_colors(tier: int) -> Dictionary:
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


func _resolve_card_icon(card_row: Dictionary) -> Texture2D:
	if card_icon_resolver == null:
		return null
	return card_icon_resolver.resolve(card_row)


func _get_control_global_center(control: Control) -> Vector2:
	if control == null:
		return Vector2.ZERO
	var rect := control.get_global_rect()
	return rect.position + rect.size * 0.5
