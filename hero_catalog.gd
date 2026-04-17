extends RefCounted
class_name HeroCatalog

const DEFAULT_HERO_TABLE_NAME: StringName = &"heroes"
const HERO_PORTRAIT_DIR := "res://assets/heroes/portraits/"
const HERO_SKILL_ICON_DIR := "res://assets/ui/icons/skills/"
const TEXTURE_EXTENSIONS := ["png", "webp", "jpg", "jpeg", "svg"]


static func load_hero_by_id(hero_id: StringName, table_name: StringName = DEFAULT_HERO_TABLE_NAME) -> HeroData:
	var heroes: Array[HeroData] = load_all_heroes(table_name)
	for hero in heroes:
		if hero.hero_id == hero_id:
			return hero
	return null


static func load_all_heroes(table_name: StringName = DEFAULT_HERO_TABLE_NAME) -> Array[HeroData]:
	var data_table: Node = _get_data_table()
	if data_table == null:
		push_warning("DataTable singleton not available.")
		return []

	if not data_table.has_table(table_name):
		push_warning("Hero table not found in DataTable: %s" % str(table_name))
		return []

	var raw_rows: Array = data_table.call("get_all", table_name)
	var heroes: Array[HeroData] = []
	for raw_row in raw_rows:
		if not (raw_row is Dictionary):
			continue

		var row: Dictionary = raw_row
		if row.is_empty():
			continue
		if _is_row_banned(row):
			continue

		var hero_key: String = str(row.get("id", "")).strip_edges()
		if hero_key.is_empty() or hero_key.begins_with("#"):
			continue

		heroes.append(_row_to_hero_data(row))

	return heroes


static func _get_data_table() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null("DataTable")
	return null


static func _row_to_hero_data(row: Dictionary) -> HeroData:
	var hero := HeroData.new()

	hero.hero_id = StringName(str(row.get("id", "")))
	hero.hero_name = str(row.get("name", ""))
	hero.hero_description = str(row.get("description", ""))
	var model_text: String = str(row.get("model_id", "")).strip_edges()
	hero.model_id = StringName(model_text)
	var preview_model_text: String = str(row.get("preview_model_id", row.get("selection_model_id", ""))).strip_edges()
	if preview_model_text.is_empty():
		preview_model_text = model_text
	hero.preview_model_id = StringName(preview_model_text)
	hero.bloodline_ids = _parse_bloodline_ids(row.get("bloodline_ids", row.get("bloodline_id_list", "")))
	hero.primary_attr = StringName(str(row.get("primary_attr", hero.primary_attr)))
	hero.base_str = float(row.get("base_str", hero.base_str))
	hero.base_agi = float(row.get("base_agi", hero.base_agi))
	hero.base_int = float(row.get("base_int", hero.base_int))
	hero.str_growth = float(row.get("str_growth", hero.str_growth))
	hero.agi_growth = float(row.get("agi_growth", hero.agi_growth))
	hero.int_growth = float(row.get("int_growth", hero.int_growth))

	var portrait_path: String = str(row.get("portrait_icon", "")).strip_edges()
	if not portrait_path.is_empty():
		hero.portrait_icon = _load_hero_portrait_texture(portrait_path)
	hero.q_skill_name = str(row.get("q_skill_name", row.get("skill_q_name", ""))).strip_edges()
	hero.q_skill_description = str(row.get("q_skill_description", row.get("skill_q_description", ""))).strip_edges()
	hero.w_skill_name = str(row.get("w_skill_name", row.get("skill_w_name", ""))).strip_edges()
	hero.w_skill_description = str(row.get("w_skill_description", row.get("skill_w_description", ""))).strip_edges()
	hero.r_skill_name = str(row.get("r_skill_name", row.get("skill_r_name", ""))).strip_edges()
	hero.r_skill_description = str(row.get("r_skill_description", row.get("skill_r_description", ""))).strip_edges()
	hero.q_skill_icon = load_texture_from_reference(str(row.get("q_skill_icon", row.get("skill_q_icon", ""))).strip_edges(), HERO_SKILL_ICON_DIR)
	hero.w_skill_icon = load_texture_from_reference(str(row.get("w_skill_icon", row.get("skill_w_icon", ""))).strip_edges(), HERO_SKILL_ICON_DIR)
	hero.r_skill_icon = load_texture_from_reference(str(row.get("r_skill_icon", row.get("skill_r_icon", ""))).strip_edges(), HERO_SKILL_ICON_DIR)

	hero.starting_max_health = int(row.get("base_hp", hero.starting_max_health))
	hero.starting_max_mana = int(row.get("base_mana", hero.starting_max_mana))
	hero.starting_attack_damage = int(row.get("attack_damage", hero.starting_attack_damage))
	hero.starting_move_speed = float(row.get("move_speed", hero.starting_move_speed))
	hero.starting_attack_interval = float(row.get("attack_interval", hero.starting_attack_interval))
	hero.starting_attack_range = float(row.get("attack_range", hero.starting_attack_range))

	if row.has("body_color"):
		hero.body_color = Color.from_string(str(row.get("body_color", "")), hero.body_color)
	if row.has("accent_color"):
		hero.accent_color = Color.from_string(str(row.get("accent_color", "")), hero.accent_color)

	return hero


static func _parse_bloodline_ids(raw_value: Variant) -> PackedStringArray:
	var parsed_ids: PackedStringArray = PackedStringArray()
	var dedupe: Dictionary = {}
	if raw_value is Array:
		for entry in raw_value:
			_append_bloodline_id(parsed_ids, dedupe, entry)
		return parsed_ids

	var source_text: String = str(raw_value).strip_edges()
	if source_text.is_empty():
		return parsed_ids
	var normalized: String = source_text
	var separators: Array[String] = [",", "，", ";", "；", "|", "/", "\n", "\r", "\t", " "]
	for separator in separators:
		normalized = normalized.replace(separator, ",")
	for token in normalized.split(",", false):
		_append_bloodline_id(parsed_ids, dedupe, token)
	return parsed_ids


static func _append_bloodline_id(target: PackedStringArray, dedupe: Dictionary, raw_value: Variant) -> void:
	var token: String = str(raw_value).strip_edges()
	if token.is_empty():
		return
	if dedupe.has(token):
		return
	dedupe[token] = true
	target.append(token)


static func _is_row_banned(row: Dictionary) -> bool:
	if row.is_empty():
		return false
	return row.has("ban") and _variant_flag_enabled(row.get("ban"))


static func _variant_flag_enabled(raw_value: Variant) -> bool:
	if raw_value == null:
		return false
	if raw_value is bool:
		return raw_value
	if raw_value is int:
		return int(raw_value) != 0
	if raw_value is float:
		return absf(float(raw_value)) >= 0.0001
	var text := str(raw_value).strip_edges().to_lower()
	if text.is_empty():
		return false
	if text in ["0", "false", "no", "n", "off", "null", "<null>"]:
		return false
	return true


static func _load_hero_portrait_texture(portrait_ref: String) -> Texture2D:
	return load_texture_from_reference(portrait_ref, HERO_PORTRAIT_DIR)


static func _build_hero_portrait_candidates(portrait_ref: String) -> Array[String]:
	return _build_texture_candidates(portrait_ref, HERO_PORTRAIT_DIR)


static func load_texture_from_reference(texture_ref: String, base_dir: String = "") -> Texture2D:
	for candidate_path in _build_texture_candidates(texture_ref, base_dir):
		if not ResourceLoader.exists(candidate_path):
			continue
		var texture := load(candidate_path) as Texture2D
		if texture != null:
			return texture
	return null


static func _build_texture_candidates(texture_ref: String, base_dir: String = "") -> Array[String]:
	var normalized_ref := texture_ref.strip_edges()
	if normalized_ref.is_empty():
		return []
	if normalized_ref.begins_with("res://") or normalized_ref.begins_with("uid://"):
		return [normalized_ref]

	var normalized_base_dir := base_dir.strip_edges()
	if not normalized_base_dir.is_empty() and normalized_base_dir.ends_with("/"):
		normalized_base_dir = normalized_base_dir.trim_suffix("/")

	var candidates: Array[String] = []
	if normalized_base_dir.is_empty():
		candidates.append(normalized_ref)
		for ext in TEXTURE_EXTENSIONS:
			candidates.append("%s.%s" % [normalized_ref, ext])
		return candidates

	candidates.append("%s/%s" % [normalized_base_dir, normalized_ref])
	for ext in TEXTURE_EXTENSIONS:
		candidates.append("%s/%s.%s" % [normalized_base_dir, normalized_ref, ext])
	return candidates
