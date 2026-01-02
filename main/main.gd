# res://scripts/Main.gd
extends Node2D

# 主游戏脚本，负责游戏流程控制。
# 挂在 main/Main.tscn 的根节点 Node2D 上。

@onready var artillery = $Artillery
@onready var tank_spawn_timer = $TankSpawnTimer
@onready var tanks_root = $TanksRoot # 所有坦克的父节点，便于管理

var active_tanks = {}  # 字典：answer -> tank instance

func _ready():
	# 连接UI和定时器信号
	print('------ _ready() is called ---------')



func _draw() -> void:
	print('------------- _draw() is called -------------')
