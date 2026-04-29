extends RefCounted
class_name RewardPickupSplitter

const DEFAULT_MAX_CHUNKS := 6


static func split_amount(total_amount: int, ideal_chunk: int, max_chunks: int = DEFAULT_MAX_CHUNKS) -> Array[int]:
	var result: Array[int] = []
	var remaining := maxi(total_amount, 0)
	if remaining <= 0:
		return result

	var safe_chunk := maxi(ideal_chunk, 1)
	var safe_max_chunks := maxi(max_chunks, 1)
	var chunk_count := mini(safe_max_chunks, maxi(int(ceil(float(remaining) / float(safe_chunk))), 1))
	for index in chunk_count:
		var left_slots := chunk_count - index
		var average := int(round(float(remaining) / float(left_slots)))
		var jitter := int(floor(randf_range(-safe_chunk * 0.2, safe_chunk * 0.2)))
		var chunk := clampi(average + jitter, 1, remaining - (left_slots - 1))
		result.append(chunk)
		remaining -= chunk

	if remaining > 0:
		result[result.size() - 1] += remaining

	return result
