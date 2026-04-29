extends RefCounted
class_name BattleResultFormatter


static func build_victory_summary(
	hero_name: String,
	final_wave: int,
	elapsed_seconds: int,
	kill_count: int,
	current_gold: int,
	current_exp: int,
	current_level: int
) -> String:
	return "英雄：%s\n最终波次：第%d波（全清）\n战斗时长：%d 秒\n击杀：%d\n金币：%d\n总经验：%d\n等级：Lv.%d\n本局结果已写入存档记录" % [
		hero_name,
		final_wave,
		elapsed_seconds,
		kill_count,
		current_gold,
		current_exp,
		current_level,
	]


static func build_defeat_summary(
	reason_text: String,
	hero_name: String,
	reached_wave: int,
	elapsed_seconds: int,
	kill_count: int,
	current_gold: int,
	current_exp: int,
	current_level: int
) -> String:
	return "原因：%s\n英雄：%s\n停留波次：第%d波\n战斗时长：%d 秒\n击杀：%d\n金币：%d\n总经验：%d\n等级：Lv.%d\n本局结果已写入存档记录" % [
		reason_text,
		hero_name,
		reached_wave,
		elapsed_seconds,
		kill_count,
		current_gold,
		current_exp,
		current_level,
	]
