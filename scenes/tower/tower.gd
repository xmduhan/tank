# res://scripts/Artillery.gd
extends Node2D

# 炮台脚本，负责发射炮弹。
# 挂在 actors/Artillery.tscn 的根节点 Node2D 上。

@onready var shoot_position = $ShootPosition
var projectile_scene = preload("res://scenes/bullet/bullet.tscn")
