extends RefCounted
class_name RuntimeEnemySnapshot

var alive_enemy_count := 0
var active_boss_nodes: Array[Node2D] = []
var snapshot_frame := -1


func refresh(tree: SceneTree, force: bool = false) -> void:
	if tree == null:
		alive_enemy_count = 0
		active_boss_nodes.clear()
		snapshot_frame = -1
		return

	var current_frame: int = Engine.get_process_frames()
	if not force and snapshot_frame == current_frame:
		return

	snapshot_frame = current_frame
	alive_enemy_count = 0
	active_boss_nodes.clear()

	var enemy_nodes: Array = tree.get_nodes_in_group("enemy")
	alive_enemy_count = enemy_nodes.size()

	var boss_nodes: Array = tree.get_nodes_in_group("boss")
	for boss_node in boss_nodes:
		if boss_node == null or not is_instance_valid(boss_node):
			continue
		if boss_node is Node2D:
			active_boss_nodes.append(boss_node)


func invalidate() -> void:
	snapshot_frame = -1
