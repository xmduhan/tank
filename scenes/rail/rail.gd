extends Node2D

# 预加载轨道块场景
var rail_block_scene = preload("res://scenes/rail/rail_block.tscn")

# 可访问的高度属性，用于控制轨道在垂直方向的位置
@export var height: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_horizontal_rail_across_screen()

func create_horizontal_rail_across_screen():
	# 获取屏幕尺寸
	var viewport_size = get_viewport_rect().size
	
	var scale_factor = .5
	
	# 轨道块纹理的尺寸（假设为128x128，根据rail_block.tscn中的offset计算）
	var block_size = 128.0 * scale_factor # offset_right - offset_left = 64 - (-64) = 128
	
	# 计算需要多少个轨道块才能横穿屏幕
	var num_blocks = ceil(viewport_size.x / block_size) + 2
	
	# 计算起始位置，使得轨道在屏幕中央垂直位置，并从屏幕左侧开始
	var start_x = -viewport_size.x / 2  # 从屏幕左侧边缘开始
	var center_y = height  # 使用height属性控制垂直位置
	
	# 创建并放置轨道块
	for i in range(num_blocks):
		var rail_block = rail_block_scene.instantiate()
		
		# 设置位置：水平排列，使用height属性控制垂直位置
		rail_block.position = Vector2(start_x + i * block_size, center_y)
		
		# 确保轨道是水平的（rail_block.gd中horizontal默认为true）
		rail_block.horizontal = false
		rail_block.scale_factor = scale_factor
		
		# 添加到场景中
		add_child(rail_block)
