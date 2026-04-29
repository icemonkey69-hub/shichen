extends RefCounted
class_name WaveRuntime

func should_finish_victory(battle_finished: bool, has_waves: bool, wave_flow_state: int, complete_state: int, alive_enemy_count: int) -> bool:
	if battle_finished:
		return false
	if not has_waves:
		return false
	if wave_flow_state != complete_state:
		return false
	return alive_enemy_count <= 0


func update_enemy_overload(
	game_over: bool,
	selection_active: bool,
	threshold: int,
	alive_enemy_count: int,
	current_remaining: float,
	defeat_seconds: float,
	delta: float
) -> Dictionary:
	if game_over or selection_active:
		return {
			"active": false,
			"remaining": current_remaining,
			"defeated": false,
		}

	if alive_enemy_count <= threshold:
		return {
			"active": false,
			"remaining": 0.0,
			"defeated": false,
		}

	var remaining: float = current_remaining
	if remaining <= 0.0:
		remaining = maxf(defeat_seconds, 0.1)

	remaining = maxf(remaining - delta, 0.0)
	var defeated: bool = remaining == 0.0
	return {
		"active": true,
		"remaining": remaining,
		"defeated": defeated,
	}


func build_wave_info_state(
	wave_flow_state: int,
	prepare_state: int,
	transition_state: int,
	complete_state: int,
	wave_text: String,
	wave_state_remaining: float,
	wave_remaining_time: float
) -> Dictionary:
	match wave_flow_state:
		prepare_state:
			return {
				"title": "第%s波  准备期" % wave_text,
				"timer": "准备 %.1fs" % wave_state_remaining,
			}
		transition_state:
			return {
				"title": "第%s波  结算过渡" % wave_text,
				"timer": "过渡 %.1fs" % wave_state_remaining,
			}
		complete_state:
			return {
				"title": "全部波次完成",
				"timer": "清理残敌",
			}
		_:
			return {
				"title": "第%s波  战斗中" % wave_text,
				"timer": "剩余 %.1fs" % wave_remaining_time,
			}


func build_wave_banner_subtitle(total: int, spawn_interval: float, boss_name: String) -> String:
	if not boss_name.is_empty():
		return "%s 来袭" % boss_name
	if total > 0:
		if spawn_interval > 0.0:
			return "目标 %d 只  每 %.2f 秒 1 只" % [total, spawn_interval]
		return "目标 %d 只" % total
	if spawn_interval > 0.0:
		return "敌潮来袭  每 %.2f 秒 1 只" % spawn_interval
	return "保持阵型"


func build_wave_transition_subtitle(
	cleared_by_cleanup: bool,
	has_next_wave: bool,
	next_is_boss_wave: bool,
	wave_state_remaining: float,
	next_wave_number: int
) -> String:
	if not has_next_wave:
		return "最终波结算中"
	if next_is_boss_wave:
		return "%s\n%.1fs 后进入 Boss波次" % [
			"已清场，Boss 气息正在逼近" if cleared_by_cleanup else "时间到，Boss 正在逼近",
			wave_state_remaining,
		]
	return "%s\n%.1fs 后进入第%d波" % [
		"已清场，敌潮短暂退却" if cleared_by_cleanup else "时间到，敌潮正在重组",
		wave_state_remaining,
		next_wave_number,
	]
