extends RefCounted
class_name HeroModelCatalog

const Model3DProfileCatalogScript := preload("res://model3d_profile_catalog.gd")
const HeroModelScript := preload("res://hero_model.gd")
const Model3DActorAnimatorScript := preload("res://model3d_actor_animator.gd")


static func instantiate_model(model_id: StringName) -> Node2D:
	var normalized_model_id := StringName(String(model_id).strip_edges())
	var model3d_instance := _instantiate_model3d_hero_model(normalized_model_id)
	if model3d_instance != null:
		return model3d_instance

	push_warning("Hero 3D profile missing or invalid for model_id=%s." % String(normalized_model_id))
	return null


static func _instantiate_model3d_hero_model(model_id: StringName) -> Node2D:
	if not Model3DProfileCatalogScript.has_profile(model_id):
		return null

	var hero_model := HeroModelScript.new() as HeroModel
	if hero_model == null:
		return null

	hero_model.name = "Model3DHeroModel"
	hero_model.rotate_with_facing = false
	var animator_node := Model3DActorAnimatorScript.new()
	if animator_node == null:
		hero_model.queue_free()
		return null
	animator_node.name = "Animator"
	hero_model.add_child(animator_node)

	if hero_model.has_method("set_model_id"):
		hero_model.call("set_model_id", model_id)
		return hero_model
	if hero_model.has_method("configure_model_id"):
		var applied: bool = bool(hero_model.call("configure_model_id", model_id))
		if applied:
			return hero_model

	hero_model.queue_free()
	return null
