extends Resource
class_name EnemyData

@export var enemy_id: StringName = &"1"
@export var enemy_name: String = "Enemy"
# 1=normal, 2=elite, 3=boss
@export var enemy_type: int = 1
@export var model_id: StringName = &"1010"
@export var behavior_id: StringName = &"melee_chaser"

@export_group("Combat")
@export var max_health: int = 20
@export var move_speed: float = 100.0
@export var touch_damage: int = 6
@export var attack_range: float = 88.0
@export var attack_interval: float = 0.7
@export var armor: float = 0.0
@export var magic_resist: float = 0.0

@export_group("Collision")
@export var collision_radius: float = 16.0

@export_group("Reward")
@export var exp_reward: int = 0
@export var gold_reward: int = 0

@export_group("Skill")
@export var skill_ids: Array[StringName] = []
@export var notes: String = ""
