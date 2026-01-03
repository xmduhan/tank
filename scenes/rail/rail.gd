extends Node2D

@export var length: float = 1.0
@export var is_horizontal: bool = false

@onready var tilemap_layer: TileMapLayer = $RailTileMap

var _tile_set_loaded: bool = false

func _ready() -> void:
	print('rail._ready() is call')
	# 等待tile_set加载完成
	await ensure_tile_set_loaded()
	update_rail()

func ensure_tile_set_loaded() -> void:
	# 如果tile_set已经存在，直接返回
	if tilemap_layer and tilemap_layer.tile_set:
		_tile_set_loaded = true
		return
	
	# 否则等待tile_set加载
	while tilemap_layer and not tilemap_layer.tile_set:
		await get_tree().process_frame
	
	_tile_set_loaded = true

func update_rail() -> void:
	print('update_rail():1')
	if not tilemap_layer or not _tile_set_loaded:
		print('TileMapLayer not ready')
		return
	
	print('update_rail():2')
	
	# 清除所有现有的图块
	tilemap_layer.clear()
	
	# 计算需要绘制的图块数量
	var tile_size = tilemap_layer.tile_set.tile_size
	var tile_count = int(ceil(length))
	
	# 打印调试信息
	print("tile_size: ", tile_size, ", tile_count: ", tile_count)
	
	if is_horizontal:
		# 水平铁轨
		for i in range(tile_count):
			var cell_position = Vector2i(i, 0)
			tilemap_layer.set_cell(cell_position, 0, Vector2i(0, 0))
	else:
		# 垂直铁轨
		for i in range(tile_count):
			var cell_position = Vector2i(0, i)
			tilemap_layer.set_cell(cell_position, 1, Vector2i(0, 0))
	
	# 调整TileMapLayer的位置使其居中
	var total_size = Vector2(tile_size.x * tile_count, tile_size.y)
	if is_horizontal:
		tilemap_layer.position = Vector2(-total_size.x / 2, -tile_size.y / 2)
	else:
		tilemap_layer.position = Vector2(-tile_size.x / 2, -total_size.y / 2)

func set_length(new_length: float) -> void:
	length = new_length
	if _tile_set_loaded:
		update_rail()

func set_horizontal(is_horiz: bool) -> void:
	is_horizontal = is_horiz
	if _tile_set_loaded:
		update_rail()
