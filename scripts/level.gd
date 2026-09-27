class_name Level
extends TileMapLayer
## Builds the level from an ASCII map (see res://levels/level_01.gd).
##
## Tile art comes from res://assets/tiles/tileset.png when it exists
## (a 64x64 stone tile), otherwise a procedural placeholder is generated.

const TILE := 64
const TILESET_PATH := "res://assets/tiles/tileset.png"
const LEVEL_SCRIPT := preload("res://levels/level_01.gd")

const ATLAS_STONE := Vector2i(0, 0)
const STONE_COLOR := Color(0.32, 0.33, 0.38)

var player_spawn := Vector2.ZERO

var _size := Vector2i.ZERO


func _ready() -> void:
	tile_set = _build_tileset()
	_parse_map(LEVEL_SCRIPT.MAP)


## Level area in pixels, starting at the top-left tile.
func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(_size * TILE))


func _parse_map(rows: Array[String]) -> void:
	_size = Vector2i(0, rows.size())
	for y in rows.size():
		var row := rows[y]
		_size.x = maxi(_size.x, row.length())
		for x in row.length():
			var cell := Vector2i(x, y)
			match row[x]:
				"#":
					set_cell(cell, 0, ATLAS_STONE)
				"P":
					# Characters stand on the bottom edge of their tile.
					player_spawn = map_to_local(cell) + Vector2(0.0, TILE * 0.5)


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = _load_tile_texture()
	source.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(source, 0)

	var half := TILE * 0.5
	source.create_tile(ATLAS_STONE)
	var data := source.get_tile_data(ATLAS_STONE, 0)
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]))
	return ts


func _load_tile_texture() -> Texture2D:
	if ResourceLoader.exists(TILESET_PATH):
		return load(TILESET_PATH)
	return ImageTexture.create_from_image(_make_placeholder_tile())


## Noisy stone slab with a dark rim.
func _make_placeholder_tile() -> Image:
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in TILE:
		for x in TILE:
			var c := STONE_COLOR.darkened(rng.randf() * 0.15)
			if x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1:
				c = STONE_COLOR.darkened(0.45)
			img.set_pixel(x, y, c)
	return img
