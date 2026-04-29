extends RefCounted
class_name ThresholdRewardPicker


static func pick_card(reward_value: String, card_rows: Array[Dictionary], owned_cards: Array[Dictionary]) -> Dictionary:
	if reward_value.begins_with("random_tier_"):
		var tier_text := reward_value.trim_prefix("random_tier_")
		var target_tier := int(tier_text)
		var candidates: Array[Dictionary] = []
		for row in card_rows:
			if int(row.get("tier", 0)) != target_tier:
				continue
			if bool(row.get("is_unique", false)) and has_owned_with_id(owned_cards, String(row.get("id", ""))):
				continue
			candidates.append(row)
		if candidates.is_empty():
			return {}
		return candidates[randi() % candidates.size()]

	for row in card_rows:
		if String(row.get("id", "")) == reward_value:
			return row
	return {}


static func pick_weapon(reward_value: String, weapon_rows: Array[Dictionary]) -> Dictionary:
	if reward_value.begins_with("random_quality_"):
		var quality_text := reward_value.trim_prefix("random_quality_")
		var target_quality := int(quality_text)
		var candidates: Array[Dictionary] = []
		for row in weapon_rows:
			if int(row.get("quality", 0)) == target_quality:
				candidates.append(row)
		if candidates.is_empty():
			return {}
		return pick_weighted_row(candidates, "drop_weight")

	for row in weapon_rows:
		if String(row.get("id", "")) == reward_value:
			return row
	return {}


static func has_owned_with_id(rows: Array[Dictionary], reward_id: String) -> bool:
	for row in rows:
		if String(row.get("id", "")) == reward_id:
			return true
	return false


static func pick_weighted_row(rows: Array[Dictionary], weight_key: String) -> Dictionary:
	if rows.is_empty():
		return {}

	var total_weight := 0.0
	for row in rows:
		total_weight += maxf(float(row.get(weight_key, 1.0)), 0.0)

	if total_weight <= 0.0:
		return rows[randi() % rows.size()]

	var roll := randf() * total_weight
	var cursor := 0.0
	for row in rows:
		cursor += maxf(float(row.get(weight_key, 1.0)), 0.0)
		if roll <= cursor:
			return row

	return rows[rows.size() - 1]
