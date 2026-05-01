extends RefCounted
class_name HeroModelCatalog

const UnitSpriteAnimatorScript := preload("res://unit_sprite_animator.gd")
const GUARDIAN_MODEL_ROOT := "res://assets/heroes/Models_2d"
const TOWER_MODEL_ROOT := "res://assets/heroes/point_2d"


static func instantiate_model(model_id: StringName, model_root_dir := TOWER_MODEL_ROOT) -> Node2D:
	var root := HeroModel.new()
	root.name = "HeroModel2D"
	root.rotate_with_facing = false

	var actor: Node = UnitSpriteAnimatorScript.new()
	actor.name = "UnitSpriteAnimator"
	actor.set("model_root_dir", model_root_dir)
	actor.set("visual_offset", Vector2.ZERO)
	actor.set("visual_ground_offset", 10.0)
	root.add_child(actor)

	var configured: bool = bool(actor.call("configure_model_id", model_id))
	if not configured:
		root.queue_free()
		return null
	return root
