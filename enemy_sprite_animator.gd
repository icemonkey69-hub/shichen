extends "res://unit_sprite_animator.gd"
class_name EnemySpriteAnimator


func _init() -> void:
	model_root_dir = "res://assets/enemies/Models_2d"
	visual_offset = Vector2(0.0, 0.0)
	visual_ground_offset = 10.0
	display_scale = 1.0
