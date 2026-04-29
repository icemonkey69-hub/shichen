extends RefCounted
class_name CardIconResolver

const DEFAULT_FALLBACK_DIR := "res://assets/ui/icons/cards"
const DEFAULT_EXTENSIONS := ["png", "webp", "jpg", "jpeg", "svg"]

var _fallback_by_id: Dictionary = {}
var _fallback_by_name: Dictionary = {}
var _texture_cache: Dictionary = {}
var _fallback_dir := DEFAULT_FALLBACK_DIR
var _extensions := DEFAULT_EXTENSIONS


func _init(
	fallback_by_id: Dictionary = {},
	fallback_by_name: Dictionary = {},
	fallback_dir: String = DEFAULT_FALLBACK_DIR,
	extensions: Array = DEFAULT_EXTENSIONS
) -> void:
	_fallback_by_id = fallback_by_id.duplicate()
	_fallback_by_name = fallback_by_name.duplicate()
	_fallback_dir = fallback_dir
	_extensions = extensions.duplicate()


func resolve(card_row: Dictionary) -> Texture2D:
	var raw_icon_value = card_row.get("icon", "")
	if raw_icon_value == null:
		return null

	var raw_icon := String(raw_icon_value).strip_edges()
	if raw_icon.is_empty():
		raw_icon = _resolve_fallback_icon(card_row)
		if raw_icon.is_empty():
			return null

	if _texture_cache.has(raw_icon):
		return _texture_cache.get(raw_icon, null) as Texture2D

	for candidate in _build_candidates(raw_icon):
		if ResourceLoader.exists(candidate):
			var texture := load(candidate) as Texture2D
			_texture_cache[raw_icon] = texture
			return texture

	_texture_cache[raw_icon] = null
	return null


func clear_cache() -> void:
	_texture_cache.clear()


func _resolve_fallback_icon(card_row: Dictionary) -> String:
	var fallback_id := String(card_row.get("id", "")).strip_edges()
	if _fallback_by_id.has(fallback_id):
		return String(_fallback_by_id.get(fallback_id, "")).strip_edges()

	var fallback_name := String(card_row.get("name", "")).strip_edges()
	if _fallback_by_name.has(fallback_name):
		return String(_fallback_by_name.get(fallback_name, "")).strip_edges()

	return ""


func _build_candidates(icon_ref: String) -> Array[String]:
	var normalized_ref := icon_ref.strip_edges()
	if normalized_ref.is_empty():
		return []
	if normalized_ref.begins_with("res://") or normalized_ref.begins_with("uid://"):
		return [normalized_ref]

	var candidates: Array[String] = []
	candidates.append("%s/%s" % [_fallback_dir, normalized_ref])
	for ext in _extensions:
		candidates.append("%s/%s.%s" % [_fallback_dir, normalized_ref, String(ext)])
	return candidates
