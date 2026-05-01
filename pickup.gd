extends Node2D

signal collected(reward_type: StringName, amount: int, world_position: Vector2)

const CARD_CHOICE_REWARD_TYPE: StringName = &"card_choice"
const CARD_PICKUP_FRAME_TEXTURE: Texture2D = preload("res://assets/ui/card_choice/frames/tier_1_white.png")
const CARD_PICKUP_ICON_TEXTURE: Texture2D = preload("res://assets/ui/card_choice/icons/sample/titan_heart_icon_v1.png")
const GOLD_PICKUP_TEXTURE: Texture2D = preload("res://assets/pickups/gold/Gold_Resource_Highlight.png")
const EXP_PICKUP_TEXTURE: Texture2D = preload("res://assets/pickups/exp/Meat_Resource.png")

@export var reward_type: StringName = &"gold"
@export var amount := 1
@export var float_duration := 0.22
@export var idle_delay := 0.12
@export var close_magnet_delay := 0.04
@export var magnet_range := 150.0
@export var card_choice_magnet_range := 150.0
@export var card_choice_idle_delay := 0.05
@export var collect_range := 28.0
@export var base_speed := 145.0
@export var magnet_speed := 420.0
@export var max_magnet_speed := 1280.0

@onready var shadow: Polygon2D = $Shadow
@onready var ground_glow: Polygon2D = $GroundGlow
@onready var card_aura: Polygon2D = $CardAura
@onready var orb: Polygon2D = $Orb
@onready var resource_sprite: Sprite2D = $ResourceSprite
@onready var card_frame: Sprite2D = $CardFrame
@onready var card_icon: Sprite2D = $CardIcon

var player: Node2D
var launch_velocity := Vector2.ZERO
var elapsed := 0.0
var collecting := false
var bob_seed := 0.0
var resource_regions: Array[Rect2] = []
var resource_frame_index := 0
var resource_frame_elapsed := 0.0
var resource_fps := 8.0
var resource_base_y := -8.0


func _ready() -> void:
	bob_seed = randf() * TAU
	_update_visual()


func _process(delta: float) -> void:
	elapsed += delta
	_update_resource_animation(delta)

	if not is_instance_valid(player):
		global_position += launch_velocity * delta
		launch_velocity = launch_velocity.move_toward(Vector2.ZERO, delta * 180.0)
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	var effective_idle_delay := close_magnet_delay if distance <= 180.0 else idle_delay
	var attract_active := elapsed >= effective_idle_delay and (magnet_range <= 0.0 or distance <= magnet_range)
	if attract_active:
		collecting = true
		var direction := to_player / maxf(distance, 0.001)
		var speed := magnet_speed + maxf(amount * 1.4, 0.0) + minf(distance * 1.55, 760.0)
		speed = clampf(speed, base_speed, max_magnet_speed)
		global_position += direction * speed * delta
	else:
		if elapsed <= float_duration:
			global_position += launch_velocity * delta
			launch_velocity = launch_velocity.move_toward(Vector2.ZERO, delta * 200.0)
		else:
			global_position.y += sin(elapsed * 3.6 + bob_seed) * 9.0 * delta

	if card_frame != null and card_frame.visible:
		var card_rotation: float = sin(elapsed * 1.9 + bob_seed) * 0.09
		var card_hover_offset: float = sin(elapsed * 2.4 + bob_seed) * 2.4
		card_frame.rotation = card_rotation
		card_frame.position.y = -3.0 + card_hover_offset
		if card_icon != null and card_icon.visible:
			card_icon.rotation = card_rotation
			card_icon.position.y = card_frame.position.y - 1.0
		if ground_glow != null and ground_glow.visible:
			var glow_scale: float = 1.0 + sin(elapsed * 2.1 + bob_seed) * 0.08
			ground_glow.scale = Vector2(glow_scale, glow_scale * 0.92)
			ground_glow.color.a = 0.16 + sin(elapsed * 2.6 + bob_seed) * 0.04
		if card_aura != null and card_aura.visible:
			card_aura.rotation = -card_rotation * 0.65
			card_aura.scale = Vector2.ONE * (1.0 + sin(elapsed * 2.9 + bob_seed) * 0.06)
			card_aura.color.a = 0.12 + sin(elapsed * 3.2 + bob_seed) * 0.05
	elif resource_sprite != null and resource_sprite.visible:
		resource_sprite.position.y = resource_base_y + sin(elapsed * 3.2 + bob_seed) * 2.0

	if distance <= collect_range:
		collected.emit(reward_type, amount, global_position)
		queue_free()


func configure_pickup(p_type: StringName, p_amount: int, p_player: Node2D, impulse: Vector2 = Vector2.ZERO) -> void:
	reward_type = p_type
	amount = maxi(p_amount, 0)
	player = p_player
	launch_velocity = impulse
	if reward_type == CARD_CHOICE_REWARD_TYPE:
		magnet_range = card_choice_magnet_range
		idle_delay = card_choice_idle_delay
	if is_inside_tree():
		_update_visual()


func _update_visual() -> void:
	var main_color := Color(0.95, 0.81, 0.22, 1.0)
	var shadow_color := Color(0.35, 0.24, 0.08, 0.5)
	var use_card_visual := reward_type == CARD_CHOICE_REWARD_TYPE
	var resource_texture: Texture2D = null
	var resource_scale := Vector2.ONE
	if reward_type == &"exp":
		main_color = Color(0.35, 0.88, 0.68, 1.0)
		shadow_color = Color(0.08, 0.28, 0.2, 0.5)
		resource_texture = EXP_PICKUP_TEXTURE
		resource_scale = Vector2(0.5, 0.5)
	elif reward_type == &"gold":
		resource_texture = GOLD_PICKUP_TEXTURE
		resource_scale = Vector2(0.32, 0.32)
	elif use_card_visual:
		main_color = Color(0.96, 0.84, 0.42, 0.32)
		shadow_color = Color(0.18, 0.12, 0.05, 0.44)

	orb.color = main_color
	shadow.color = shadow_color
	orb.visible = not use_card_visual and resource_texture == null
	if resource_texture != null:
		_configure_resource_sprite(resource_texture, resource_scale)
	else:
		resource_sprite.visible = false
		resource_regions.clear()
	if ground_glow != null:
		ground_glow.visible = use_card_visual
		ground_glow.scale = Vector2.ONE
		ground_glow.color = Color(0.97, 0.83, 0.35, 0.16)
	if card_aura != null:
		card_aura.visible = use_card_visual
		card_aura.rotation = 0.0
		card_aura.scale = Vector2.ONE
		card_aura.color = Color(1.0, 0.95, 0.74, 0.14)
	if card_frame != null:
		card_frame.visible = use_card_visual
		card_frame.position = Vector2.ZERO
		card_frame.rotation = 0.0
		card_frame.texture = CARD_PICKUP_FRAME_TEXTURE
		card_frame.modulate = Color(1.0, 0.96, 0.9, 1.0)
	if card_icon != null:
		card_icon.visible = use_card_visual
		card_icon.position = Vector2(0, -1)
		card_icon.rotation = 0.0
		card_icon.texture = CARD_PICKUP_ICON_TEXTURE
		card_icon.modulate = Color(1.0, 1.0, 1.0, 0.96)

	var size_scale: float = clampf(0.9 + log(float(maxi(amount, 1)) + 1.0) * 0.16, 0.9, 1.5)
	if use_card_visual:
		size_scale = clampf(size_scale * 0.92, 0.92, 1.18)
	scale = Vector2.ONE * size_scale


func _configure_resource_sprite(texture: Texture2D, sprite_scale: Vector2) -> void:
	resource_sprite.visible = true
	resource_sprite.texture = texture
	resource_sprite.centered = true
	resource_sprite.position = Vector2(0, resource_base_y)
	resource_sprite.rotation = 0.0
	resource_sprite.scale = sprite_scale
	resource_sprite.modulate = Color.WHITE
	resource_regions = _build_texture_regions(texture)
	resource_frame_index = 0
	resource_frame_elapsed = 0.0
	resource_sprite.region_enabled = not resource_regions.is_empty()
	_apply_resource_frame()


func _build_texture_regions(texture: Texture2D) -> Array[Rect2]:
	var regions: Array[Rect2] = []
	var width := texture.get_width()
	var height := texture.get_height()
	if height > 0 and width > height and width % height == 0:
		var frame_count := int(float(width) / float(height))
		for i in frame_count:
			regions.append(Rect2(i * height, 0, height, height))
	else:
		regions.append(Rect2(0, 0, width, height))
	return regions


func _update_resource_animation(delta: float) -> void:
	if resource_regions.size() <= 1 or resource_sprite == null or not resource_sprite.visible:
		return

	resource_frame_elapsed += delta
	var frame_duration := 1.0 / maxf(resource_fps, 1.0)
	while resource_frame_elapsed >= frame_duration:
		resource_frame_elapsed -= frame_duration
		resource_frame_index = (resource_frame_index + 1) % resource_regions.size()
		_apply_resource_frame()


func _apply_resource_frame() -> void:
	if resource_regions.is_empty() or resource_sprite == null:
		return

	resource_sprite.region_rect = resource_regions[resource_frame_index]
