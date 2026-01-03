extends Node2D

@onready var rail_tilemap: TileMapLayer = $RailTileMap

var length: float = 128
var is_horizontal: bool = false
var tile_set_loaded: bool = false

func set_length(new_length: float) -> void:
	length = new_length

func set_horizontal(horizontal: bool) -> void:
	is_horizontal = horizontal

func ensure_tile_set_loaded() -> void:
	if rail_tilemap.tile_set != null:
		tile_set_loaded = true
		update_rail()
	else:
		# 如果tile_set尚未加载，等待一帧再检查
		await get_tree().process_frame
		if rail_tilemap.tile_set != null:
			tile_set_loaded = true
			update_rail()

func _ready() -> void:
	# 确保tile_set加载完成后更新铁轨
	if rail_tilemap.tile_set != null:
		tile_set_loaded = true
		update_rail()
	else:
		# 如果tile_set尚未加载，等待一帧
		await get_tree().process_frame
		if rail_tilemap.tile_set != null:
			tile_set_loaded = true
			update_rail()

func update_rail() -> void:
	if not tile_set_loaded:
		return
	
	# 清除现有的瓦片
	rail_tilemap.clear()
	
	# 获取铁轨瓦片的ID（假设使用第一个瓦片）
	var tile_set = rail_tilemap.tile_set
	var source_id = tile_set.get_source_id(0)
	var atlas_coords = Vector2i(0, 0)
	var alternative_id = 0
	
	# 根据方向放置瓦片
	if is_horizontal:
		# 水平铁轨：从左到右放置
		for i in range(ceil(length)):
			var cell_position = Vector2i(i, 0)
			rail_tilemap.set_cell(cell_position, source_id, atlas_coords, alternative_id)
	else:
		# 垂直铁轨：从上到下放置
		for i in range(ceil(length)):
			var cell_position = Vector2i(0, i)
			rail_tilemap.set_cell(cell_position, source_id, atlas_coords, alternative_id)
