# res://scripts/Main.gd
extends Node2D

# 主游戏脚本，负责游戏流程控制。
# 挂在 main/Main.tscn 的根节点 Node2D 上。

@onready var artillery = $Artillery
@onready var tank_spawn_timer = $TankSpawnTimer
@onready var tanks_root = $TanksRoot # 所有坦克的父节点，便于管理

var active_tanks = {}  # 字典：answer -> tank instance

func _ready():
	
	# 在屏幕中间位置创建一辆坦克
	var tank_scene = preload("res://scenes/tank/tank.tscn")
	var tank_instance = tank_scene.instantiate()
	
	# 获取屏幕中心位置
	var screen_center = get_viewport_rect().size / 2
	tank_instance.position = screen_center
	print(screen_center)
	
	# 添加到场景中
	# add_child(tank_instance)
