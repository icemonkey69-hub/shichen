extends Node
class_name EnemyBehavior

var enemy: CharacterBody2D


func setup(owner_enemy: CharacterBody2D) -> void:
	enemy = owner_enemy
	reset_state()


func reset_state() -> void:
	pass


func physics_process(_delta: float) -> void:
	pass


func on_deactivated() -> void:
	pass
