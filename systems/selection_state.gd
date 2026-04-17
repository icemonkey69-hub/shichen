extends RefCounted
class_name SelectionState

var index := 0
var bloodline_index := 0
var selected_template_bloodline_option: Dictionary = {}
var ui_dirty := true
var last_template_id := ""
var last_bloodline_option_count := -1


func reset(default_index: int) -> void:
	index = maxi(default_index, 0)
	bloodline_index = 0
	selected_template_bloodline_option = {}
	mark_dirty()


func mark_dirty() -> void:
	ui_dirty = true
	last_template_id = ""
	last_bloodline_option_count = -1


func set_template(new_index: int) -> void:
	index = maxi(new_index, 0)
	bloodline_index = 0
	ui_dirty = true


func set_bloodline(new_index: int) -> void:
	bloodline_index = maxi(new_index, 0)


func should_rebuild_bloodline_buttons(template_id: String, option_count: int) -> bool:
	return ui_dirty \
		or template_id != last_template_id \
		or option_count != last_bloodline_option_count


func mark_bloodline_buttons_rebuilt(template_id: String, option_count: int) -> void:
	last_template_id = template_id
	last_bloodline_option_count = option_count
	ui_dirty = false
