extends Node2D

# 铁路轨道脚本
# 使用TextureRect显示轨道图片

func _ready():
	# 确保轨道正确显示
	print("Rail scene loaded")
	print("TextureRect size: ", $RailTexture.size)
	print("TextureRect position: ", $RailTexture.position)
	print("TextureRect texture: ", $RailTexture.texture)
	
	# 如果图片加载失败，显示警告
	if $RailTexture.texture == null:
		print("WARNING: Rail texture failed to load!")
		# 尝试重新加载图片
		var texture = load("res://scenes/rail/images/rail.png")
		if texture:
			$RailTexture.texture = texture
			print("Texture reloaded successfully")
		else:
			print("ERROR: Cannot load rail.png from path")