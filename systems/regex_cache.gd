extends RefCounted
class_name RegexCache

var _compiled_patterns: Dictionary = {}
var _invalid_patterns: Dictionary = {}


func search(pattern: String, text: String) -> RegExMatch:
	var regex := _get_regex(pattern)
	if regex == null:
		return null
	return regex.search(text)


func clear() -> void:
	_compiled_patterns.clear()
	_invalid_patterns.clear()


func _get_regex(pattern: String) -> RegEx:
	if _compiled_patterns.has(pattern):
		return _compiled_patterns[pattern] as RegEx
	if _invalid_patterns.has(pattern):
		return null

	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		_invalid_patterns[pattern] = true
		return null

	_compiled_patterns[pattern] = regex
	return regex
