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

	var remaining := current_remaining
	if remaining <= 0.0:
		remaining = maxf(defeat_seconds, 0.1)

	remaining = maxf(remaining - delta, 0.0)
	var defeated := remaining == 0.0
	return {
		"active": true,
		"remaining": remaining,
		"defeated": defeated,
	}
