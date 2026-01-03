# res://scripts/Main.gd
extends Node2D

# 主游戏脚本，负责游戏流程控制。
# 挂在 main/Main.tscn 的根节点 Node2D 上。

@onready var artillery = $Artillery
@onready var tank_spawn_timer = $TankSpawnTimer
@onready var tanks_root = $TanksRoot # 所有坦克的父节点，便于管理

var active_tanks = {}  # 字典：answer -> tank instance

func _ready():
	# create_tower()
	await create_rail()

func create_tower():
	var tower_scene = preload("res://scenes/tower/tower.tscn")
	var tower_instance = tower_scene.instantiate()
	var screen_center = get_viewport_rect().size / 2
	tower_instance.position = screen_center
	add_child(tower_instance)

func create_rail():
	var rail_scene = preload("res://scenes/rail/rail.tscn")
	var rail_instance = rail_scene.instantiate()
	
	var screen_center = get_viewport_rect().size / 2
	rail_instance.position = screen_center 
	
	add_child(rail_instance)
	
