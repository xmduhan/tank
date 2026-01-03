extends Node2D

# 铁路轨道脚本
# 使用TextureRect显示轨道图片

# 可设置的属性
@export var position_offset: Vector2 = Vector2.ZERO
@export var horizontal: bool = false
@export var scale_factor: float = 1

func _ready():
	# 应用位置偏移
	position += position_offset
	
	# 根据方向属性调整轨道显示
	if not horizontal:
		# 垂直轨道
		$RailTexture.rotation_degrees = 90
	else:
		# 水平轨道（默认）
		$RailTexture.rotation_degrees = 0
	
	# 应用缩放比例
	$RailTexture.scale = Vector2(scale_factor, scale_factor)
