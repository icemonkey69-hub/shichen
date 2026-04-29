extends RefCounted
class_name CardChoiceDropRuntime

var interval_seconds := 5.0
var initial_chance_percent := 100.0
var chance_increase_percent := 4.0

var next_pickup_time := 0.0
var available_rolls := 1
var current_chance_percent := 100.0


func configure(interval: float, initial_chance: float, chance_increase: float) -> void:
	interval_seconds = maxf(interval, 0.0)
	initial_chance_percent = clampf(initial_chance, 0.0, 100.0)
	chance_increase_percent = maxf(chance_increase, 0.0)
	reset_roll_state()


func reset_runtime() -> void:
	available_rolls = 1
	next_pickup_time = interval_seconds if interval_seconds > 0.0 else 0.0
	reset_roll_state()


func consume_due_rolls(elapsed_time: float) -> int:
	if interval_seconds <= 0.0:
		available_rolls = maxi(available_rolls, 1)
	else:
		if next_pickup_time <= 0.0:
			next_pickup_time = interval_seconds
		while elapsed_time >= next_pickup_time:
			available_rolls += 1
			next_pickup_time += interval_seconds

	var roll_count := available_rolls
	available_rolls = 0
	return roll_count


func roll_succeeds(roll_percent: float) -> bool:
	var threshold := clampf(current_chance_percent, 0.0, 100.0)
	var success := threshold >= 100.0 or roll_percent <= threshold
	if success:
		reset_roll_state()
	else:
		current_chance_percent = clampf(current_chance_percent + chance_increase_percent, 0.0, 100.0)
	return success


func reset_roll_state() -> void:
	current_chance_percent = clampf(initial_chance_percent, 0.0, 100.0)
