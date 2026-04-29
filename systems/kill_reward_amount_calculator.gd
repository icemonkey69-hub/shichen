extends RefCounted
class_name KillRewardAmountCalculator


static func calculate(reward_info: Dictionary, stats) -> Dictionary:
	var base_gold := maxi(int(reward_info.get("gold", 0)), 0)
	var base_exp := maxi(int(reward_info.get("exp", 0)), 0)
	var final_gold := base_gold
	var final_exp := base_exp

	if stats != null:
		final_gold = maxi(int(round(float(base_gold) * (1.0 + maxf(stats.get_stat(&"gold_gain_percent"), -1.0)))), 0)
		final_gold += maxi(int(round(stats.get_stat(&"bonus_gold_per_kill"))), 0)
		final_exp = maxi(int(round(float(base_exp) * (1.0 + maxf(stats.get_stat(&"exp_gain_percent"), -1.0)))), 0)
		final_exp += maxi(int(round(stats.get_stat(&"bonus_exp_per_kill"))), 0)

	return {
		"gold": final_gold,
		"exp": final_exp,
	}
