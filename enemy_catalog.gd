extends RefCounted
class_name EnemyCatalog

const DEFAULT_ENEMY_TABLE_NAME: StringName = &"enemies"
const TYPE_NORMAL: int = 1
const TYPE_ELITE: int = 2
const TYPE_BOSS: int = 3


static func load_all_enemies(table_name: StringName = DEFAULT_ENEMY_TABLE_NAME) -> Array[EnemyData]:
	var data_table: Node = _get_data_table()
	if data_table == null:
		push_warning("DataTable singleton not available.")
		return []

	if not data_table.has_table(table_name):
		push_warning("Enemy table not found in DataTable: %s" % str(table_name))
		return []

	var raw_rows: Array = data_table.call("get_all", table_name)
	var enemies: Array[EnemyData] = []
	for raw_row in raw_rows:
		if not (raw_row is Dictionary):
			continue

		var row: Dictionary = raw_row
		if row.is_empty():
			continue

		var enemy_key: String = str(row.get("id", "")).strip_edges()
		if enemy_key.is_empty() or enemy_key.begins_with("#"):
			continue

		enemies.append(_row_to_enemy_data(row))

	return enemies


static func _get_data_table() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null("DataTable")
	return null


static func _row_to_enemy_data(row: Dictionary) -> EnemyData:
	var enemy: EnemyData = EnemyData.new()

	enemy.enemy_id = StringName(str(row.get("id", "")))
	enemy.enemy_name = str(row.get("name", ""))
	enemy.enemy_type = _parse_enemy_type(row.get("enemy_type", TYPE_NORMAL))

	var model_value = row.get("model_id", row.get("sprite", "1010"))
	enemy.model_id = StringName(str(model_value))
	enemy.behavior_id = StringName(str(row.get("behavior_id", row.get("ai_behavior", row.get("behavior", enemy.behavior_id)))).strip_edges())
	if String(enemy.behavior_id).is_empty():
		enemy.behavior_id = &"melee_chaser"

	enemy.max_health = maxi(1, _to_int(row.get("max_hp", enemy.max_health), enemy.max_health))
	enemy.move_speed = maxf(0.0, _to_float(row.get("move_speed", enemy.move_speed), enemy.move_speed))
	enemy.touch_damage = maxi(0, _to_int(row.get("touch_damage", enemy.touch_damage), enemy.touch_damage))
	enemy.collision_radius = maxf(1.0, _to_float(row.get("collision_radius", enemy.collision_radius), enemy.collision_radius))
	enemy.exp_reward = maxi(0, _to_int(row.get("exp_reward", enemy.exp_reward), enemy.exp_reward))
	enemy.gold_reward = maxi(0, _to_int(row.get("gold_reward", enemy.gold_reward), enemy.gold_reward))

	enemy.armor = _to_float(row.get("armor", enemy.armor), enemy.armor)
	enemy.magic_resist = _to_float(row.get("magic_resist", enemy.magic_resist), enemy.magic_resist)

	var attack_interval_value: float = _to_float(row.get("attack_interval", row.get("attack_speed", enemy.attack_interval)), enemy.attack_interval)
	enemy.attack_interval = maxf(0.05, attack_interval_value)

	if row.has("skill_ids"):
		enemy.skill_ids = _parse_skill_ids(row.get("skill_ids"))
	elif row.has("skill_id"):
		enemy.skill_ids = _parse_skill_ids(row.get("skill_id"))

	enemy.notes = str(row.get("notes", ""))
	return enemy


static func _parse_enemy_type(raw_type) -> int:
	var text: String = str(raw_type).strip_edges().to_lower()
	if text.is_empty():
		return TYPE_NORMAL

	if text.is_valid_int():
		var enum_value: int = int(text)
		if enum_value >= TYPE_NORMAL and enum_value <= TYPE_BOSS:
			return enum_value
		return TYPE_NORMAL

	match text:
		"normal":
			return TYPE_NORMAL
		"elite":
			return TYPE_ELITE
		"boss":
			return TYPE_BOSS
		_:
			return TYPE_NORMAL


static func _parse_skill_ids(raw_value) -> Array[StringName]:
	var result: Array[StringName] = []
	if raw_value == null:
		return result

	if raw_value is Array:
		var raw_array: Array = raw_value
		for item in raw_array:
			_append_skill_id(result, str(item))
		return result

	var text: String = str(raw_value).strip_edges()
	if text.is_empty():
		return result

	var normalized: String = text.replace(";", ",").replace("|", ",")
	var tokens: PackedStringArray = normalized.split(",", false)
	if tokens.is_empty():
		_append_skill_id(result, normalized)
		return result

	for token in tokens:
		_append_skill_id(result, token)
	return result


static func _append_skill_id(target: Array[StringName], raw_text: String) -> void:
	var token: String = raw_text.strip_edges()
	if token.is_empty():
		return
	target.append(StringName(token))


static func _to_int(raw_value, default_value: int = 0) -> int:
	if raw_value == null:
		return default_value
	if raw_value is int:
		return raw_value
	if raw_value is float:
		return int(round(raw_value))

	var text := str(raw_value).strip_edges()
	if text.is_empty():
		return default_value
	if text.is_valid_int():
		return text.to_int()
	if text.is_valid_float():
		return int(round(text.to_float()))
	return default_value


static func _to_float(raw_value, default_value: float = 0.0) -> float:
	if raw_value == null:
		return default_value
	if raw_value is float:
		return raw_value
	if raw_value is int:
		return raw_value * 1.0

	var text := str(raw_value).strip_edges()
	if text.is_empty():
		return default_value
	if text.is_valid_float():
		return text.to_float()
	if text.is_valid_int():
		return text.to_int() * 1.0
	return default_value
