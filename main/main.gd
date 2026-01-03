# res://scripts/Main.gd
extends Node2D

# 主游戏脚本，负责游戏流程控制。
# 挂在 main/Main.tscn 的根节点 Node2D 上。

@onready var artillery = $Artillery
@onready var tank_spawn_timer = $TankSpawnTimer
@onready var tanks_root = $TanksRoot # 所有坦克的父节点，便于管理

var active_tanks = {}  # 字典：answer -> tank instance

func _ready():
	# 创建炮塔
	# create_tower()
	
	# 创建东西向铁轨，贯穿整个屏幕
	await create_horizontal_rail()

func create_tower():
	# 加载炮塔到屏幕中间位置
	var tower_scene = preload("res://scenes/tower/tower.tscn")
	var tower_instance = tower_scene.instantiate()
	
	# 获取屏幕中心位置
	var screen_center = get_viewport_rect().size / 2
	tower_instance.position = screen_center
	print("炮塔位置：", screen_center)
	
	# 添加到场景中
	add_child(tower_instance)

func create_horizontal_rail():
	# 加载铁轨场景
	var rail_scene = preload("res://scenes/rail/rail.tscn")
	var rail_instance = rail_scene.instantiate()
	
	# 获取屏幕尺寸
	var screen_size = get_viewport_rect().size
	
	# 计算需要的铁轨长度（屏幕宽度除以铁轨纹理宽度128）
	var rail_texture_width = 128.0
	var required_length = screen_size.x / rail_texture_width
	
	# 设置铁轨属性
	rail_instance.set_length(required_length)
	rail_instance.set_horizontal(false)
	
	# 将铁轨放置在屏幕中间高度位置
	rail_instance.position = Vector2(screen_size.x / 2, screen_size.y / 2)
	
	# 添加到场景中
	add_child(rail_instance)
	
	print("创建东西向铁轨，长度：", required_length, "，位置：", rail_instance.position)
	
	# 等待铁轨的tile_set加载完成
	await rail_instance.ensure_tile_set_loaded()
