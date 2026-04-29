extends Control
class_name WeaponGrowthPanelUi

signal upgrade_requested(slot: String)

@onready var gold_label: Label = get_node("面板/内容/金币") as Label
@onready var sword_card: Control = get_node("面板/内容/列表/剑") as Control
@onready var shield_card: Control = get_node("面板/内容/列表/盾") as Control

var slot_controls: Dictionary = {}


func _ready() -> void:
	slot_controls = {
		"sword": _cache_slot_controls(sword_card),
		"shield": _cache_slot_controls(shield_card),
	}
	_connect_slot_button("sword")
	_connect_slot_button("shield")


func configure(slot_infos: Array[Dictionary], current_gold: int) -> void:
	visible = not slot_infos.is_empty()
	if not visible:
		return

	gold_label.text = "金币 %d" % current_gold
	var used_slots := {}
	for info in slot_infos:
		var slot := String(info.get("slot", "")).strip_edges()
		used_slots[slot] = true
		_apply_slot_info(slot, info)

	for slot in slot_controls.keys():
		var controls: Dictionary = slot_controls.get(slot, {})
		var root: Control = controls.get("root", null) as Control
		if root != null:
			root.visible = used_slots.has(slot)


func _cache_slot_controls(root: Control) -> Dictionary:
	if root == null:
		return {}
	return {
		"root": root,
		"name": root.get_node("内容/名称") as Label,
		"level": root.get_node("内容/等级") as Label,
		"current": root.get_node("内容/当前") as Label,
		"next": root.get_node("内容/下级") as Label,
		"button": root.get_node("内容/升级") as Button,
	}


func _connect_slot_button(slot: String) -> void:
	var controls: Dictionary = slot_controls.get(slot, {})
	var button: Button = controls.get("button", null) as Button
	if button == null:
		return
	if not button.pressed.is_connected(_on_upgrade_pressed.bind(slot)):
		button.pressed.connect(_on_upgrade_pressed.bind(slot))


func _apply_slot_info(slot: String, info: Dictionary) -> void:
	var controls: Dictionary = slot_controls.get(slot, {})
	if controls.is_empty():
		return

	var title_label: Label = controls.get("name", null) as Label
	var level_label: Label = controls.get("level", null) as Label
	var current_label: Label = controls.get("current", null) as Label
	var next_label: Label = controls.get("next", null) as Label
	var button: Button = controls.get("button", null) as Button
	var is_max := bool(info.get("is_max", false))

	if title_label != null:
		title_label.text = String(info.get("title", slot))
	if level_label != null:
		level_label.text = String(info.get("level_text", ""))
	if current_label != null:
		current_label.text = String(info.get("current_text", ""))
	if next_label != null:
		next_label.text = String(info.get("next_text", ""))
	if button != null:
		button.disabled = is_max
		button.text = "已满级" if is_max else "升级 %d" % int(info.get("cost_gold", 0))


func _on_upgrade_pressed(slot: String) -> void:
	upgrade_requested.emit(slot)
