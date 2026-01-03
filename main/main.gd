# res://scripts/Main.gd
extends Node2D

func _ready():
	await create_rail()

func create_rail():
	var rail_scene = preload("res://scenes/rail/rail.tscn")
	var rail_instance = rail_scene.instantiate()
	
	var screen_center = get_viewport_rect().size / 2
	rail_instance.position = screen_center 
	
	# 设置height属性为正值，使轨道向下移动到接近屏幕底端的位置
	# 这里设置为屏幕高度的1/4位置（从底部算起）
	rail_instance.height = get_viewport_rect().size.y / 2 - 10
	
	add_child(rail_instance)
