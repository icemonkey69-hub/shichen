extends RefCounted
class_name HeroModelCatalog

const Model3DActorAnimatorScript := preload("res://model3d_actor_animator.gd")


static func instantiate_model(model_id: StringName) -> Node2D:
	var root := HeroModel.new()
	root.name = "HeroModel3D"
	root.rotate_with_facing = false

	var actor: Node = Model3DActorAnimatorScript.new()
	actor.name = "Model3DActor"
	root.add_child(actor)
	if actor.has_method("set_asset_quality"):
		actor.call("set_asset_quality", "preview")
	var configured: bool = bool(actor.configure_model_id(model_id))
	if not configured:
		root.queue_free()
		return null
	return root
