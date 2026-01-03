extends Node2D

@export var length: float = 1.0
@export var is_horizontal: bool = false

@onready var tilemap_layer: TileMapLayer = $RailTileMap

func _ready() -> void:
	print('rail._ready() is call')
	update_rail()

func update_rail() -> void:
	print('update_rail():1')
	if not tilemap_layer:
		return
	print('update_rail():2')
	# 检查tile_set是否已加载
	if not tilemap_layer.tile_set:
		# 若未加载，延迟到下一帧再尝试更新
		await get_tree().process_frame
		# 再次检查，确保tile_set存在
		if not tilemap_layer.tile_set:
			print('update_rail():3')
			# push_error("RailTileMapLayer's tile_set is still null after waiting.")
			return
	print('update_rail():4')
	
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
	update_rail()

func set_horizontal(is_horiz: bool) -> void:
	is_horizontal = is_horiz
	update_rail()
