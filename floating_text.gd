extends Node2D

@export var text: String = "0"
@export var text_color := Color(1.0, 0.95, 0.85, 1.0)
@export var shadow_color := Color(0.08, 0.06, 0.03, 0.85)
@export var font_size := 24
@export var lifetime := 0.7
@export var rise_speed := 66.0
@export var drift_speed := 22.0

var elapsed := 0.0
var drift_direction := 0.0


func _ready() -> void:
	drift_direction = randf_range(-1.0, 1.0)
	z_index = 50
	queue_redraw()


func configure(content: String, color: Color, size: int = 24, life: float = 0.7) -> void:
	text = content
	text_color = color
	font_size = size
	lifetime = maxf(life, 0.05)
	if is_inside_tree():
		queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	global_position += Vector2(drift_direction * drift_speed, -rise_speed) * delta
	queue_redraw()

	if elapsed >= lifetime:
		queue_free()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null or text.is_empty():
		return

	var alpha := clampf(1.0 - elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	var color := text_color
	color.a *= alpha
	var outline := shadow_color
	outline.a *= alpha

	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var origin := Vector2(-text_size.x * 0.5, text_size.y * 0.35)
	var outline_offsets := [
		Vector2(-1, 0),
		Vector2(1, 0),
		Vector2(0, -1),
		Vector2(0, 1),
	]
	for offset in outline_offsets:
		draw_string(font, origin + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
