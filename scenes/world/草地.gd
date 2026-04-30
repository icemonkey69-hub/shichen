extends Node2D
class_name GrassTerrain

@export var play_area := Rect2(-1024.0, -1024.0, 2048.0, 2048.0)
@export var boss_spawn_offset := Vector2(760.0, -680.0)
@export var show_bounds := false
@export var decorations_enabled := true

const TREE_1 := preload("res://Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree1.png")
const TREE_2 := preload("res://Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree2.png")
const TREE_3 := preload("res://Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree3.png")
const TREE_4 := preload("res://Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree4.png")
const BUSH_1 := preload("res://Tiny Swords (Free Pack)/Terrain/Decorations/Bushes/Bushe1.png")
const BUSH_2 := preload("res://Tiny Swords (Free Pack)/Terrain/Decorations/Bushes/Bushe2.png")
const BUSH_3 := preload("res://Tiny Swords (Free Pack)/Terrain/Decorations/Bushes/Bushe3.png")
const BUSH_4 := preload("res://Tiny Swords (Free Pack)/Terrain/Decorations/Bushes/Bushe4.png")
const ROCK_1 := preload("res://Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/Rock1.png")
const ROCK_2 := preload("res://Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/Rock2.png")
const ROCK_3 := preload("res://Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/Rock3.png")
const ROCK_4 := preload("res://Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/Rock4.png")
const STUMP_1 := preload("res://Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Stump 1.png")
const STUMP_2 := preload("res://Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Stump 2.png")
const STUMP_3 := preload("res://Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Stump 3.png")
const STUMP_4 := preload("res://Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Stump 4.png")

const TREE_REGION := Vector2(192.0, 256.0)
const BUSH_REGION := Vector2(128.0, 128.0)
const EMPTY_REGION := Vector2.ZERO
const DECORATION_ROOT_NAME := "GeneratedDecorations"


func _ready() -> void:
	_disable_tilemap_collision()
	if decorations_enabled:
		_rebuild_decorations()
	queue_redraw()


func get_play_area() -> Rect2:
	return play_area


func get_spawn_position() -> Vector2:
	return play_area.position + play_area.size * 0.5


func get_boss_spawn_position() -> Vector2:
	return get_spawn_position() + boss_spawn_offset


func _draw() -> void:
	if not show_bounds:
		return
	draw_rect(play_area, Color(0.7, 1.0, 0.55, 0.65), false, 3.0)


func _disable_tilemap_collision() -> void:
	for child in get_children():
		if child is TileMapLayer:
			child.set("collision_enabled", false)


func _rebuild_decorations() -> void:
	var old_root := get_node_or_null(DECORATION_ROOT_NAME)
	if old_root != null:
		old_root.free()

	var root := Node2D.new()
	root.name = DECORATION_ROOT_NAME
	add_child(root)

	_add_forest_cluster(root, Vector2(-920.0, -870.0), [TREE_1, TREE_2, TREE_3], [0, 2, 4, 6], 0.76)
	_add_forest_cluster(root, Vector2(650.0, -860.0), [TREE_1, TREE_2, TREE_4], [1, 3, 5, 7], 0.8)
	_add_forest_cluster(root, Vector2(-860.0, 720.0), [TREE_1, TREE_3, TREE_4], [0, 3, 6], 0.82)
	_add_forest_cluster(root, Vector2(880.0, 610.0), [TREE_1, TREE_2, TREE_3], [1, 4, 7], 0.78)

	_add_tree(root, TREE_1, Vector2(-720.0, -820.0), 5, 0.74)
	_add_tree(root, TREE_3, Vector2(-540.0, -780.0), 1, 0.68)
	_add_tree(root, TREE_2, Vector2(880.0, -420.0), 2, 0.72)
	_add_tree(root, TREE_4, Vector2(940.0, 140.0), 6, 0.72)
	_add_tree(root, TREE_1, Vector2(-940.0, 170.0), 0, 0.7)
	_add_tree(root, TREE_3, Vector2(-620.0, 930.0), 3, 0.66)
	_add_tree(root, TREE_2, Vector2(350.0, 910.0), 4, 0.68)

	_add_bush(root, BUSH_1, Vector2(-820.0, -500.0), 1, 0.78)
	_add_bush(root, BUSH_2, Vector2(-350.0, -720.0), 4, 0.72)
	_add_bush(root, BUSH_3, Vector2(410.0, -690.0), 2, 0.74)
	_add_bush(root, BUSH_4, Vector2(760.0, -230.0), 6, 0.7)
	_add_bush(root, BUSH_1, Vector2(-780.0, 360.0), 7, 0.74)
	_add_bush(root, BUSH_2, Vector2(-270.0, 820.0), 0, 0.72)
	_add_bush(root, BUSH_3, Vector2(560.0, 520.0), 5, 0.76)
	_add_bush(root, BUSH_4, Vector2(870.0, 760.0), 3, 0.68)

	_add_sprite(root, ROCK_1, Vector2(-530.0, -360.0), EMPTY_REGION, 0, 0.82, "Rock")
	_add_sprite(root, ROCK_2, Vector2(210.0, -540.0), EMPTY_REGION, 0, 0.86, "Rock")
	_add_sprite(root, ROCK_3, Vector2(630.0, -150.0), EMPTY_REGION, 0, 0.78, "Rock")
	_add_sprite(root, ROCK_4, Vector2(-760.0, 80.0), EMPTY_REGION, 0, 0.8, "Rock")
	_add_sprite(root, ROCK_1, Vector2(-120.0, 610.0), EMPTY_REGION, 0, 0.86, "Rock")
	_add_sprite(root, ROCK_2, Vector2(330.0, 690.0), EMPTY_REGION, 0, 0.74, "Rock")

	_add_sprite(root, STUMP_1, Vector2(-190.0, -760.0), EMPTY_REGION, 0, 0.52, "Stump")
	_add_sprite(root, STUMP_2, Vector2(170.0, -770.0), EMPTY_REGION, 0, 0.52, "Stump")
	_add_sprite(root, STUMP_3, Vector2(-560.0, 560.0), EMPTY_REGION, 0, 0.5, "Stump")
	_add_sprite(root, STUMP_4, Vector2(640.0, 250.0), EMPTY_REGION, 0, 0.5, "Stump")


func _add_forest_cluster(root: Node2D, origin: Vector2, textures: Array, frames: Array, base_scale: float) -> void:
	var offsets := [
		Vector2(-130.0, -30.0),
		Vector2(-45.0, -85.0),
		Vector2(55.0, -55.0),
		Vector2(145.0, -10.0),
		Vector2(-95.0, 90.0),
		Vector2(10.0, 55.0),
		Vector2(120.0, 90.0),
	]
	for index in offsets.size():
		var texture: Texture2D = textures[index % textures.size()]
		var frame: int = frames[index % frames.size()]
		var scale := base_scale + float(index % 3) * 0.035
		_add_tree(root, texture, origin + offsets[index], frame, scale)


func _add_tree(root: Node2D, texture: Texture2D, position: Vector2, frame: int, scale: float) -> void:
	_add_sprite(root, texture, position, TREE_REGION, frame, scale, "Tree")


func _add_bush(root: Node2D, texture: Texture2D, position: Vector2, frame: int, scale: float) -> void:
	_add_sprite(root, texture, position, BUSH_REGION, frame, scale, "Bush")


func _add_sprite(root: Node2D, texture: Texture2D, position: Vector2, region_size: Vector2, frame: int, scale_amount: float, prefix: String) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "%s_%d" % [prefix, root.get_child_count()]
	sprite.texture = texture
	sprite.position = position
	sprite.scale = Vector2.ONE * scale_amount
	sprite.centered = true
	sprite.z_as_relative = false
	sprite.z_index = clampi(roundi(position.y), -4096, 4096)

	if region_size != EMPTY_REGION:
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2(region_size.x * float(frame), 0.0), region_size)
		sprite.offset = Vector2(0.0, -region_size.y * 0.5)
	else:
		sprite.offset = Vector2(0.0, -float(texture.get_height()) * 0.5)

	root.add_child(sprite)
