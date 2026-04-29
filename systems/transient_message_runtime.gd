extends RefCounted
class_name TransientMessageRuntime

var _remaining := 0.0
var _queue: Array[Dictionary] = []


func reset() -> void:
	_remaining = 0.0
	_queue.clear()


func is_active() -> bool:
	return _remaining > 0.0


func update(delta: float, default_duration: float) -> Dictionary:
	var expired := false
	if _remaining > 0.0:
		_remaining = maxf(_remaining - delta, 0.0)
		expired = _remaining == 0.0

	if _remaining == 0.0 and not _queue.is_empty():
		var next_message: Dictionary = _queue.pop_front()
		return _start(
			String(next_message.get("text", "")),
			float(next_message.get("duration", default_duration))
		)

	if expired:
		return {"hide": true}
	return {}


func show(text: String, duration: float, gap_duration: float) -> Dictionary:
	if _remaining > 0.0:
		_queue.append({
			"text": text,
			"duration": duration + gap_duration,
		})
		return {}

	return _start(text, duration)


func _start(text: String, duration: float) -> Dictionary:
	_remaining = maxf(duration, 0.01)
	return {
		"display": true,
		"text": text,
	}
