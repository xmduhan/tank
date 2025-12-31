# res://scripts/Artillery.gd
extends Node2D

# 炮台脚本，负责发射炮弹。
# 挂在 actors/Artillery.tscn 的根节点 Node2D 上。

@onready var shoot_position = $ShootPosition
var projectile_scene = preload("res://projectiles/Projectile.tscn")

# 向目标位置发射炮弹
func shoot_at(target_position: Vector2):
	var projectile = projectile_scene.instantiate()
	# 添加到主场景，确保炮弹在正确的层级
	get_parent().add_child(projectile)
	projectile.global_position = shoot_position.global_position
	projectile.set_target(target_position)