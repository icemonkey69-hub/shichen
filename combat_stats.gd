extends RefCounted
class_name CombatStats

# 战斗属性快照。
# 这一层不直接关心 UI、动画或场景节点，只负责保存“当前这一刻的最终属性值”。

var hero_id: StringName = &""
var primary_attr: StringName = &"str"
var values: Dictionary = {}


func set_stat(stat_id: StringName, value: float) -> void:
	values[stat_id] = value


func add_stat(stat_id: StringName, value: float) -> void:
	set_stat(stat_id, get_stat(stat_id) + value)


func get_stat(stat_id: StringName, default_value: float = 0.0) -> float:
	var raw_value = values.get(stat_id, default_value)
	if raw_value is int or raw_value is float:
		return float(raw_value)
	return default_value


func get_stat_int(stat_id: StringName, default_value: int = 0) -> int:
	return int(round(get_stat(stat_id, float(default_value))))


func get_primary_attr_value() -> float:
	match String(primary_attr):
		"agi":
			return get_stat(&"final_agi")
		"int":
			return get_stat(&"final_int")
		_:
			return get_stat(&"final_str")


func duplicate_stats():
	var copied = get_script().new()
	copied.hero_id = hero_id
	copied.primary_attr = primary_attr
	copied.values = values.duplicate(true)
	return copied
