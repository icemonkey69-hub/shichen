extends RefCounted
class_name CombatInfoFormatter


static func build_text(
	elapsed_time: float,
	wave_text: String,
	kill_count: int,
	current_gold: int,
	current_exp: int,
	stats
) -> String:
	var base_text := "时间 %.1fs  波次 %s  击杀 %d  金币 %d  总经验 %d" % [
		elapsed_time,
		wave_text,
		kill_count,
		current_gold,
		current_exp,
	]
	if stats == null:
		return base_text

	var atk := int(round(float(stats.get_stat(&"attack_power"))))
	var armor := float(stats.get_stat(&"armor"))
	var mr := float(stats.get_stat(&"magic_resist"))
	var atk_spd_pct := float(stats.get_stat(&"attack_speed_percent")) * 100.0
	var atk_interval := float(stats.get_stat(&"final_attack_interval"))
	var move_spd := float(stats.get_stat(&"move_speed"))
	var cdr := float(stats.get_stat(&"cooldown_reduction")) * 100.0
	var str_v := int(round(float(stats.get_stat(&"final_str"))))
	var agi_v := int(round(float(stats.get_stat(&"final_agi"))))
	var int_v := int(round(float(stats.get_stat(&"final_int"))))

	return "%s\n攻击 %d  护甲 %.1f  魔抗 %.1f  攻速 %.1f%%(间隔%.2fs)  移速 %.0f  冷却缩减 %.1f%%  力量 %d  敏捷 %d  智力 %d" % [
		base_text,
		atk,
		armor,
		mr,
		atk_spd_pct,
		atk_interval,
		move_spd,
		cdr,
		str_v,
		agi_v,
		int_v,
	]
