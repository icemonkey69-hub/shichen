extends RefCounted
class_name AttributeSystem

const ATTRIBUTE_TABLE_NAME: StringName = &"attributes"
const DEFAULT_MOVE_SPEED_CAP := 550.0
const MAX_COOLDOWN_REDUCTION := 0.85
const CombatStatsScript := preload("res://combat_stats.gd")


static func build_hero_stats(hero: HeroData, bonus_values: Dictionary = {}, runtime_progress: Dictionary = {}):
	var stats: Variant = _create_empty_stats()
	stats.hero_id = hero.hero_id
	stats.primary_attr = hero.primary_attr

	stats.set_stat(&"base_str", hero.base_str)
	stats.set_stat(&"base_agi", hero.base_agi)
	stats.set_stat(&"base_int", hero.base_int)
	stats.set_stat(&"base_health", hero.starting_max_health)
	stats.set_stat(&"max_mana", hero.starting_max_mana)
	stats.set_stat(&"base_attack_power", hero.starting_attack_damage)
	stats.set_stat(&"base_attack_interval", hero.starting_attack_interval)
	stats.set_stat(&"move_speed_cap", DEFAULT_MOVE_SPEED_CAP)
	stats.set_stat(&"move_speed", hero.starting_move_speed)
	stats.set_stat(&"attack_range", hero.starting_attack_range)
	stats.set_stat(&"level", 1.0)
	stats.set_stat(&"gold", 0.0)
	stats.set_stat(&"exp", 0.0)
	stats.set_stat(&"kill_count", 0.0)
	stats.set_stat(&"crit_damage", 2.0)

	for key in bonus_values.keys():
		stats.set_stat(StringName(String(key)), float(bonus_values[key]))

	for key in runtime_progress.keys():
		stats.set_stat(StringName(String(key)), float(runtime_progress[key]))

	_recalculate_core_stats(stats, hero)
	return stats


static func calculate_basic_attack_damage(
	stats,
	target_armor: float = 0.0,
	crit_triggered: bool = false
) -> float:
	var effective_armor: float = get_effective_armor(
		target_armor,
		stats.get_stat(&"physical_pen_flat"),
		stats.get_stat(&"physical_pen_percent")
	)
	var damage_taken_ratio: float = get_physical_taken_ratio(effective_armor)
	var crit_multiplier: float = float(stats.get_stat(&"crit_damage", 2.0)) if crit_triggered else 1.0

	var damage: float = float(stats.get_stat(&"attack_power"))
	damage *= 1.0 + stats.get_stat(&"basic_attack_damage_percent")
	damage *= 1.0 + stats.get_stat(&"physical_damage_percent")
	damage *= 1.0 + stats.get_stat(&"final_damage_percent")
	damage *= crit_multiplier
	damage *= damage_taken_ratio
	return maxf(damage, 0.0)


static func calculate_skill_damage(
	stats,
	base_value: float,
	skill_ratio: float,
	damage_type: StringName = &"physical",
	target_armor: float = 0.0,
	target_magic_resist: float = 0.0,
	crit_triggered: bool = false
) -> float:
	var crit_multiplier: float = float(stats.get_stat(&"crit_damage", 2.0)) if crit_triggered else 1.0
	var damage_taken_ratio: float = 1.0
	var damage_bonus: float = 1.0 + float(stats.get_stat(&"final_damage_percent"))

	if damage_type == &"magic":
		var effective_magic_resist: float = get_effective_magic_resist(
			target_magic_resist,
			stats.get_stat(&"magic_pen_flat"),
			stats.get_stat(&"magic_pen_percent")
		)
		damage_bonus *= 1.0 + stats.get_stat(&"magic_damage_percent")
		damage_taken_ratio = get_magic_taken_ratio(effective_magic_resist)
	else:
		var effective_armor: float = get_effective_armor(
			target_armor,
			stats.get_stat(&"physical_pen_flat"),
			stats.get_stat(&"physical_pen_percent")
		)
		damage_bonus *= 1.0 + stats.get_stat(&"physical_damage_percent")
		damage_taken_ratio = get_physical_taken_ratio(effective_armor)

	var damage: float = base_value * skill_ratio
	damage *= 1.0 + stats.get_stat(&"skill_damage_percent")
	damage *= damage_bonus
	damage *= crit_multiplier
	damage *= damage_taken_ratio
	return maxf(damage, 0.0)


static func calculate_incoming_damage(raw_damage: float, damage_type: StringName = &"physical", armor: float = 0.0, magic_resist: float = 0.0) -> float:
	if damage_type == &"magic":
		return maxf(raw_damage * get_magic_taken_ratio(magic_resist), 0.0)
	return maxf(raw_damage * get_physical_taken_ratio(armor), 0.0)


static func get_effective_armor(target_armor: float, flat_pen: float, percent_pen: float) -> float:
	return maxf(0.0, target_armor - flat_pen) * maxf(0.0, 1.0 - percent_pen)


static func get_effective_magic_resist(target_magic_resist: float, flat_pen: float, percent_pen: float) -> float:
	return maxf(0.0, target_magic_resist - flat_pen) * maxf(0.0, 1.0 - percent_pen)


static func get_physical_taken_ratio(armor: float) -> float:
	var reduction := armor / (armor + 100.0)
	return 1.0 - reduction


static func get_magic_taken_ratio(magic_resist: float) -> float:
	var reduction := magic_resist / (magic_resist + 100.0)
	return 1.0 - reduction


static func _create_empty_stats():
	var stats: Variant = CombatStatsScript.new()
	var data_table := _get_data_table()
	if data_table == null:
		return stats

	var raw_rows: Array = data_table.call("get_all", ATTRIBUTE_TABLE_NAME)
	for raw_row in raw_rows:
		if not (raw_row is Dictionary):
			continue
		var row: Dictionary = raw_row
		if not bool(row.get("enabled", true)):
			continue

		var stat_id := String(row.get("id", "")).strip_edges()
		if stat_id.is_empty():
			continue
		stats.set_stat(StringName(stat_id), 0.0)

	return stats


static func _recalculate_core_stats(stats, hero: HeroData) -> void:
	var level: float = maxf(float(stats.get_stat(&"level", 1.0)), 1.0)

	var final_str: float = _calculate_final_primary_value(stats, &"str", hero, level)
	var final_agi: float = _calculate_final_primary_value(stats, &"agi", hero, level)
	var final_int: float = _calculate_final_primary_value(stats, &"int", hero, level)
	stats.set_stat(&"final_str", final_str)
	stats.set_stat(&"final_agi", final_agi)
	stats.set_stat(&"final_int", final_int)

	var primary_attr_value: float = float(stats.get_primary_attr_value())
	var base_attack_power: float = float(hero.starting_attack_damage) + primary_attr_value
	stats.set_stat(&"base_attack_power", base_attack_power)

	var attack_power: float = base_attack_power + float(stats.get_stat(&"bonus_attack_power"))
	attack_power *= 1.0 + stats.get_stat(&"attack_power_percent")
	attack_power += stats.get_stat(&"kill_base_attack_power")
	attack_power += stats.get_stat(&"kill_bonus_attack_power")
	attack_power += stats.get_stat(&"added_attack_power")
	stats.set_stat(&"attack_power", attack_power)

	var attack_speed_percent: float = float(stats.get_stat(&"base_attack_speed_percent"))
	attack_speed_percent += stats.get_stat(&"growth_attack_speed_percent")
	attack_speed_percent += stats.get_stat(&"gear_skill_attack_speed_percent")
	stats.set_stat(&"attack_speed_percent", attack_speed_percent)

	var base_attack_interval := maxf(float(hero.starting_attack_interval), 0.01)
	stats.set_stat(&"base_attack_interval", base_attack_interval)
	stats.set_stat(
		&"final_attack_interval",
		base_attack_interval / maxf(1.0 + attack_speed_percent, 0.05)
	)

	var crit_rate: float = float(stats.get_stat(&"base_crit_rate")) + float(stats.get_stat(&"gear_skill_crit_rate"))
	stats.set_stat(&"crit_rate", crit_rate)
	stats.set_stat(
		&"crit_damage",
		2.0 * (1.0 + stats.get_stat(&"crit_damage_percent")) + stats.get_stat(&"crit_overflow_bonus")
	)

	var max_health: float = float(hero.starting_max_health)
	max_health *= 1.0 + stats.get_stat(&"health_percent")
	max_health *= 1.0 + stats.get_stat(&"extra_health_percent")
	max_health *= 1.0 + stats.get_stat(&"final_health_percent")
	max_health += stats.get_stat(&"added_health")
	stats.set_stat(&"base_health", hero.starting_max_health)
	stats.set_stat(&"max_health", max_health)

	var armor: float = float(stats.get_stat(&"base_armor")) + float(stats.get_stat(&"armor_growth")) * level + float(stats.get_stat(&"armor_bonus_flat"))
	armor *= 1.0 + stats.get_stat(&"armor_percent")
	armor += stats.get_stat(&"added_armor")
	stats.set_stat(&"armor", armor)

	var magic_resist: float = float(stats.get_stat(&"base_magic_resist")) + float(stats.get_stat(&"magic_resist_growth")) * level + float(stats.get_stat(&"magic_resist_bonus_flat"))
	magic_resist *= 1.0 + stats.get_stat(&"magic_resist_percent")
	magic_resist += stats.get_stat(&"added_magic_resist")
	stats.set_stat(&"magic_resist", magic_resist)

	var skill_haste: float = float(stats.get_stat(&"skill_haste"))
	stats.set_stat(&"cooldown_reduction", minf(skill_haste / (skill_haste + 100.0), MAX_COOLDOWN_REDUCTION))

	var move_speed_cap: float = maxf(float(stats.get_stat(&"move_speed_cap", DEFAULT_MOVE_SPEED_CAP)), 1.0)
	var move_speed: float = float(hero.starting_move_speed) + float(stats.get_stat(&"bonus_move_speed_flat"))
	stats.set_stat(&"move_speed", minf(move_speed, move_speed_cap))

	var max_mana: float = float(hero.starting_max_mana)
	max_mana *= 1.0 + stats.get_stat(&"max_mana_percent")
	max_mana += stats.get_stat(&"bonus_max_mana_flat")
	stats.set_stat(&"max_mana", max_mana)


static func _calculate_final_primary_value(stats, attr_name: StringName, hero: HeroData, level: float) -> float:
	var base_stat_id := StringName("base_%s" % String(attr_name))
	var kill_stat_id := StringName("kill_%s" % String(attr_name))
	var added_stat_id := StringName("added_%s" % String(attr_name))
	var percent_stat_id := StringName("%s_percent" % String(attr_name))
	var extra_percent_stat_id := StringName("%s_extra_percent" % String(attr_name))

	var hero_base := _get_hero_primary_base_value(hero, attr_name)
	var hero_growth := _get_hero_primary_growth_value(hero, attr_name)
	var current_base := float(stats.get_stat(base_stat_id))
	var base_bonus := current_base - hero_base
	var scaled_base := hero_base + base_bonus + hero_growth * maxf(level - 1.0, 0.0)
	stats.set_stat(base_stat_id, scaled_base)

	var value: float = scaled_base + float(stats.get_stat(kill_stat_id))
	value *= 1.0 + stats.get_stat(percent_stat_id) + stats.get_stat(extra_percent_stat_id)
	value += stats.get_stat(added_stat_id)
	return value


static func _get_hero_primary_base_value(hero: HeroData, attr_name: StringName) -> float:
	match attr_name:
		&"agi":
			return hero.base_agi
		&"int":
			return hero.base_int
		_:
			return hero.base_str


static func _get_hero_primary_growth_value(hero: HeroData, attr_name: StringName) -> float:
	match attr_name:
		&"agi":
			return hero.agi_growth
		&"int":
			return hero.int_growth
		_:
			return hero.str_growth


static func _get_data_table() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null("DataTable")
	return null
