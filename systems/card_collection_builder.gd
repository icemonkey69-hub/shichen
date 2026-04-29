extends RefCounted
class_name CardCollectionBuilder

const SORT_TIME := "time"
const SORT_QUALITY := "quality"


static func build_stack_infos(owned_cards: Array[Dictionary], sort_mode: String) -> Array[Dictionary]:
	var stacks_by_key: Dictionary = {}
	var ordered: Array[Dictionary] = []
	var acquired_index := 0

	for card_row in owned_cards:
		var card_name := get_card_stack_key(card_row)
		if not stacks_by_key.has(card_name):
			var info := {
				"stack_key": card_name,
				"row": card_row,
				"count": 1,
				"first_acquired_index": acquired_index,
			}
			stacks_by_key[card_name] = info
			ordered.append(info)
		else:
			var stack_info: Dictionary = stacks_by_key[card_name]
			stack_info["count"] = int(stack_info.get("count", 0)) + 1
			stacks_by_key[card_name] = stack_info
		acquired_index += 1

	for index in ordered.size():
		var key := str(ordered[index].get("stack_key", ""))
		ordered[index] = stacks_by_key.get(key, ordered[index])

	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if sort_mode == SORT_TIME:
			var time_a := int(a.get("first_acquired_index", 0))
			var time_b := int(b.get("first_acquired_index", 0))
			if time_a != time_b:
				return time_a < time_b
		else:
			var tier_a := int((a.get("row", {}) as Dictionary).get("tier", 0))
			var tier_b := int((b.get("row", {}) as Dictionary).get("tier", 0))
			if tier_a != tier_b:
				return tier_a > tier_b
		return str(a.get("stack_key", "")) < str(b.get("stack_key", ""))
	)
	return ordered


static func count_owned_card(owned_cards: Array[Dictionary], card_row: Dictionary) -> int:
	var stack_key := get_card_stack_key(card_row)
	var count := 0
	for owned_row in owned_cards:
		if get_card_stack_key(owned_row) == stack_key:
			count += 1
	return count


static func get_card_stack_key(card_row: Dictionary) -> String:
	var card_name := str(card_row.get("name", card_row.get("id", "神权"))).strip_edges()
	if card_name.is_empty():
		card_name = str(card_row.get("id", "神权"))
	return card_name
