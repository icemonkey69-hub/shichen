extends Node2D
class_name HeroModel

# Create one scene per hero model and attach this script to the root node.
# Any child node whose name starts with `Primary_` will receive body_color.
# Any child node whose name starts with `Accent_` will receive accent_color.
# This works with Polygon2D, Sprite2D, AnimatedSprite2D, Line2D, and most CanvasItem nodes.
@export var collision_radius := 34.0
@export var rotate_with_facing := true

const PRIMARY_PREFIX := "Primary_"
const ACCENT_PREFIX := "Accent_"
var _pending_model_id: StringName = &""


func _ready() -> void:
	_apply_pending_model_id_if_needed()


func apply_colors(primary_color: Color, accent_color: Color) -> void:
	_apply_colors_recursive(self, primary_color, accent_color)


func set_motion_state(direction: Vector2, is_moving: bool) -> void:
	_set_motion_state_recursive(self, direction, is_moving)


func play_attack(direction: Vector2, attack_duration: float) -> Dictionary:
	return _play_attack_recursive(self, direction, attack_duration)


func get_socket_global_position(socket_name: String, direction: Vector2 = Vector2.ZERO, state: String = "") -> Vector2:
	var result := _get_socket_global_position_recursive(self, socket_name, direction, state)
	if result != Vector2.INF:
		return result
	push_error("Missing socket '%s' on hero model." % socket_name)
	return global_position


func cancel_attack() -> void:
	_cancel_attack_recursive(self)


func play_death() -> void:
	_play_death_recursive(self)


func play_victory() -> void:
	_play_victory_recursive(self)


func play_hit() -> void:
	_play_hit_recursive(self)


func set_stunned(enabled: bool) -> void:
	_set_stunned_recursive(self, enabled)


func play_spawn() -> void:
	_play_spawn_recursive(self)


func start_showcase() -> void:
	_start_showcase_recursive(self)


func play_selection_preview_intro() -> void:
	_play_selection_preview_intro_recursive(self)


func apply_selection_preview_preset() -> void:
	_apply_selection_preview_preset_recursive(self)


func stop_showcase() -> void:
	_stop_showcase_recursive(self)


func set_showcase_spin_speed(speed: float) -> void:
	_set_showcase_spin_speed_recursive(self, speed)


func rotate_preview(delta_yaw: float) -> void:
	_rotate_preview_recursive(self, delta_yaw)


func apply_profile_overrides(overrides: Dictionary) -> void:
	_apply_profile_overrides_recursive(self, overrides)


func configure_model_id(model_id: StringName) -> bool:
	_pending_model_id = model_id
	return _configure_model_id_recursive(self, model_id)


func set_model_id(model_id: StringName) -> void:
	_pending_model_id = model_id
	_apply_pending_model_id_if_needed()


func _apply_pending_model_id_if_needed() -> void:
	if not is_inside_tree():
		return
	var model_id_text: String = String(_pending_model_id).strip_edges()
	if model_id_text.is_empty():
		return
	configure_model_id(_pending_model_id)
	_pending_model_id = &""


func start_jump(direction: Vector2) -> void:
	_start_jump_recursive(self, direction)


func set_jump_direction(direction: Vector2) -> void:
	_set_jump_direction_recursive(self, direction)


func stop_jump(direction: Vector2, is_moving: bool) -> void:
	_stop_jump_recursive(self, direction, is_moving)


func set_jump_phase(phase_index: int) -> void:
	_set_jump_phase_recursive(self, phase_index)


func get_jump_motion_config() -> Dictionary:
	return _get_jump_motion_config_recursive(self)


func set_visual_height(offset_y: float) -> void:
	_set_visual_height_recursive(self, offset_y)


func _apply_colors_recursive(node: Node, primary_color: Color, accent_color: Color) -> void:
	for child in node.get_children():
		_apply_colors_recursive(child, primary_color, accent_color)

	if node is not CanvasItem:
		return

	var node_name := String(node.name)
	if node_name.begins_with(PRIMARY_PREFIX):
		_apply_color_to_node(node, primary_color)
	elif node_name.begins_with(ACCENT_PREFIX):
		_apply_color_to_node(node, accent_color)


func _set_motion_state_recursive(node: Node, direction: Vector2, is_moving: bool) -> void:
	for child in node.get_children():
		_set_motion_state_recursive(child, direction, is_moving)

	if node.has_method("set_motion_state") and node != self:
		node.call("set_motion_state", direction, is_moving)


func _play_attack_recursive(node: Node, direction: Vector2, attack_duration: float) -> Dictionary:
	var result: Dictionary = {}
	for child in node.get_children():
		var child_result: Dictionary = _play_attack_recursive(child, direction, attack_duration)
		if result.is_empty() and not child_result.is_empty():
			result = child_result

	if node.has_method("play_attack") and node != self:
		var raw_result: Variant = node.call("play_attack", direction, attack_duration)
		if result.is_empty() and raw_result is Dictionary:
			result = (raw_result as Dictionary).duplicate(true)
	return result


func _get_socket_global_position_recursive(node: Node, socket_name: String, direction: Vector2, state: String) -> Vector2:
	for child in node.get_children():
		var child_position := _get_socket_global_position_recursive(child, socket_name, direction, state)
		if child_position != Vector2.INF:
			return child_position

	if node.has_method("get_socket_global_position") and node != self:
		var raw_position: Variant = node.call("get_socket_global_position", socket_name, direction, state)
		if raw_position is Vector2:
			return raw_position as Vector2
	return Vector2.INF


func _cancel_attack_recursive(node: Node) -> void:
	for child in node.get_children():
		_cancel_attack_recursive(child)

	if node.has_method("cancel_attack") and node != self:
		node.call("cancel_attack")


func _play_death_recursive(node: Node) -> void:
	for child in node.get_children():
		_play_death_recursive(child)

	if node.has_method("play_death") and node != self:
		node.call("play_death")


func _play_victory_recursive(node: Node) -> void:
	for child in node.get_children():
		_play_victory_recursive(child)

	if node.has_method("play_victory") and node != self:
		node.call("play_victory")


func _play_hit_recursive(node: Node) -> void:
	for child in node.get_children():
		_play_hit_recursive(child)

	if node.has_method("play_hit") and node != self:
		node.call("play_hit")


func _set_stunned_recursive(node: Node, enabled: bool) -> void:
	for child in node.get_children():
		_set_stunned_recursive(child, enabled)

	if node.has_method("set_stunned") and node != self:
		node.call("set_stunned", enabled)


func _play_spawn_recursive(node: Node) -> void:
	for child in node.get_children():
		_play_spawn_recursive(child)

	if node.has_method("play_spawn") and node != self:
		node.call("play_spawn")


func _start_showcase_recursive(node: Node) -> void:
	for child in node.get_children():
		_start_showcase_recursive(child)

	if node.has_method("start_showcase") and node != self:
		node.call("start_showcase")


func _play_selection_preview_intro_recursive(node: Node) -> void:
	for child in node.get_children():
		_play_selection_preview_intro_recursive(child)

	if node.has_method("play_selection_preview_intro") and node != self:
		node.call("play_selection_preview_intro")


func _apply_selection_preview_preset_recursive(node: Node) -> void:
	for child in node.get_children():
		_apply_selection_preview_preset_recursive(child)

	if node.has_method("apply_selection_preview_preset") and node != self:
		node.call("apply_selection_preview_preset")


func _stop_showcase_recursive(node: Node) -> void:
	for child in node.get_children():
		_stop_showcase_recursive(child)

	if node.has_method("stop_showcase") and node != self:
		node.call("stop_showcase")


func _set_showcase_spin_speed_recursive(node: Node, speed: float) -> void:
	for child in node.get_children():
		_set_showcase_spin_speed_recursive(child, speed)

	if node.has_method("set_showcase_spin_speed") and node != self:
		node.call("set_showcase_spin_speed", speed)


func _rotate_preview_recursive(node: Node, delta_yaw: float) -> void:
	for child in node.get_children():
		_rotate_preview_recursive(child, delta_yaw)

	if node.has_method("rotate_preview") and node != self:
		node.call("rotate_preview", delta_yaw)


func _configure_model_id_recursive(node: Node, model_id: StringName) -> bool:
	var applied := false
	for child in node.get_children():
		if _configure_model_id_recursive(child, model_id):
			applied = true

	if node.has_method("configure_model_id") and node != self:
		applied = bool(node.call("configure_model_id", model_id)) or applied
	return applied


func _apply_profile_overrides_recursive(node: Node, overrides: Dictionary) -> void:
	for child in node.get_children():
		_apply_profile_overrides_recursive(child, overrides)

	if node.has_method("apply_profile_overrides") and node != self:
		node.call("apply_profile_overrides", overrides)


func _start_jump_recursive(node: Node, direction: Vector2) -> void:
	for child in node.get_children():
		_start_jump_recursive(child, direction)

	if node.has_method("start_jump") and node != self:
		node.call("start_jump", direction)


func _set_jump_direction_recursive(node: Node, direction: Vector2) -> void:
	for child in node.get_children():
		_set_jump_direction_recursive(child, direction)

	if node.has_method("set_jump_direction") and node != self:
		node.call("set_jump_direction", direction)


func _stop_jump_recursive(node: Node, direction: Vector2, is_moving: bool) -> void:
	for child in node.get_children():
		_stop_jump_recursive(child, direction, is_moving)

	if node.has_method("stop_jump") and node != self:
		node.call("stop_jump", direction, is_moving)


func _set_jump_phase_recursive(node: Node, phase_index: int) -> void:
	for child in node.get_children():
		_set_jump_phase_recursive(child, phase_index)

	if node.has_method("set_jump_phase") and node != self:
		node.call("set_jump_phase", phase_index)


func _get_jump_motion_config_recursive(node: Node) -> Dictionary:
	for child in node.get_children():
		var child_config := _get_jump_motion_config_recursive(child)
		if not child_config.is_empty():
			return child_config
	if node.has_method("get_jump_motion_config") and node != self:
		var value: Variant = node.call("get_jump_motion_config")
		if value is Dictionary:
			return value as Dictionary
	return {}


func _set_visual_height_recursive(node: Node, offset_y: float) -> void:
	for child in node.get_children():
		_set_visual_height_recursive(child, offset_y)

	if node.has_method("set_visual_height") and node != self:
		node.call("set_visual_height", offset_y)


func _apply_color_to_node(node: CanvasItem, color: Color) -> void:
	if node is Polygon2D:
		node.color = color
	elif node is Line2D:
		node.default_color = color
	else:
		node.modulate = color
