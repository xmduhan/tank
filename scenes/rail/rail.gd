extends Node2D

@export var length: float = 1.0
@export var is_horizontal: bool = false

@onready var tilemap_layer: TileMapLayer = $RailTileMap

func _ready() -> void:
	print('rail._ready() is call')
	await ensure_tile_set_loaded()
	update_rail()

func ensure_tile_set_loaded() -> void:
	# 等待tile_set加载完成
	while tilemap_layer and not tilemap_layer.tile_set:
		await get_tree().process_frame

func update_rail() -> void:
	if not is_valid():
		print('TileMapLayer not ready')
		return
	
	clear_existing_tiles()
	draw_rail_tiles()
	adjust_position()

func is_valid() -> bool:
	return tilemap_layer != null and tilemap_layer.tile_set != null

func clear_existing_tiles() -> void:
	tilemap_layer.clear()

func draw_rail_tiles() -> void:
	var tile_count = calculate_tile_count()
	
	if is_horizontal:
		draw_horizontal_rail(tile_count)
	else:
		draw_vertical_rail(tile_count)

func calculate_tile_count() -> int:
	var tile_size = tilemap_layer.tile_set.tile_size
	var tile_count = int(ceil(length))
	print("tile_size: ", tile_size, ", tile_count: ", tile_count)
	return tile_count

func draw_horizontal_rail(tile_count: int) -> void:
	for i in range(tile_count):
		var cell_position = Vector2i(i, 0)
		tilemap_layer.set_cell(cell_position, 0, Vector2i(0, 0))

func draw_vertical_rail(tile_count: int) -> void:
	for i in range(tile_count):
		var cell_position = Vector2i(0, i)
		tilemap_layer.set_cell(cell_position, 1, Vector2i(0, 0))

func adjust_position() -> void:
	var tile_size = tilemap_layer.tile_set.tile_size
	var tile_count = calculate_tile_count()
	var total_size = Vector2(tile_size.x * tile_count, tile_size.y)
	
	if is_horizontal:
		tilemap_layer.position = Vector2(-total_size.x / 2, -tile_size.y / 2)
	else:
		tilemap_layer.position = Vector2(-tile_size.x / 2, -total_size.y / 2)

func set_length(new_length: float) -> void:
	if new_length <= 0:
		push_error("Rail length must be greater than 0")
		return
	
	length = new_length
	if is_valid():
		update_rail()

func set_horizontal(is_horiz: bool) -> void:
	is_horizontal = is_horiz
	if is_valid():
		update_rail()