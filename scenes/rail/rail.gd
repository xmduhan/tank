extends Node2D

@export var length: float = 1.0
@export var is_horizontal: bool = false

@onready var texture_rect: TextureRect = $TextureRect

func _ready() -> void:
	update_rail()

func update_rail() -> void:
	if not texture_rect:
		return
	
	# 设置铁轨方向
	if is_horizontal:
		texture_rect.rotation_degrees = 90
	else:
		texture_rect.rotation_degrees = 0
	
	# 设置铁轨长度
	var texture_size = texture_rect.texture.get_size()
	var scale_factor = length
	if is_horizontal:
		texture_rect.scale = Vector2(scale_factor, 1)
	else:
		texture_rect.scale = Vector2(1, scale_factor)
	
	# 调整TextureRect的大小以匹配缩放后的纹理
	var scaled_size = texture_size * texture_rect.scale
	texture_rect.custom_minimum_size = scaled_size
	texture_rect.size = scaled_size

func set_length(new_length: float) -> void:
	length = new_length
	update_rail()

func set_horizontal(is_horiz: bool) -> void:
	is_horizontal = is_horiz
	update_rail()