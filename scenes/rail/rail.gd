extends Node2D

@export var length: float = 1.0
@export var is_horizontal: bool = false

@onready var tilemap: TileMap = $RailTileMap

func _ready() -> void:
	update_rail()

func update_rail() -> void:
	if not tilemap:
		return
	
	# 检查tile_set是否已加载
	if not tilemap.tile_set:
		# 若未加载，延迟到下一帧再尝试更新
		await get_tree().process_frame
		# 再次检查，确保tile_set存在
		if not tilemap.tile_set:
			push_error("RailTileMap's tile_set is still null after waiting.")
			return
	
	# 清除所有现有的图块
	tilemap.clear()
	
	# 计算需要绘制的图块数量
	var tile_size = tilemap.tile_set.tile_size
	var tile_count = int(ceil(length))
	
	if is_horizontal:
		# 水平铁轨
		for i in range(tile_count):
			var cell_position = Vector2i(i, 0)
			tilemap.set_cell(0, cell_position, 0, Vector2i(0, 0))
	else:
		# 垂直铁轨
		for i in range(tile_count):
			var cell_position = Vector2i(0, i)
			tilemap.set_cell(0, cell_position, 1, Vector2i(0, 0))
	
	# 调整TileMap的位置使其居中
	var total_size = Vector2(tile_size.x * tile_count, tile_size.y)
	if is_horizontal:
		tilemap.position = Vector2(-total_size.x / 2, -tile_size.y / 2)
	else:
		tilemap.position = Vector2(-tile_size.x / 2, -total_size.y / 2)

func set_length(new_length: float) -> void:
	length = new_length
	update_rail()

func set_horizontal(is_horiz: bool) -> void:
	is_horizontal = is_horiz
	update_rail()