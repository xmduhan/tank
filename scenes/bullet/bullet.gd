# res://scripts/Projectile.gd
extends Area2D

# 炮弹脚本，负责飞向目标并检测碰撞。
# 挂在 projectiles/Projectile.tscn 的根节点 Area2D 上。

var speed = 600.0
var target_position: Vector2
var direction: Vector2

func _ready():
	# 连接区域进入信号，用于检测与坦克的碰撞
	body_entered.connect(_on_body_entered)

# 设置目标位置并计算方向
func set_target(pos: Vector2):
	target_position = pos
	direction = (target_position - global_position).normalized()
	# 让炮弹朝向目标
	look_at(target_position)

func _physics_process(delta):
	# 每帧向目标方向移动
	position += direction * speed * delta
	
	# 检查是否到达目标位置附近或飞出屏幕
	if global_position.distance_to(target_position) < 10:
		queue_free()
	# 简单的屏幕边界检查（假设屏幕大小约1200x800）
	if position.x < -100 or position.x > 1300 or position.y < -100 or position.y > 900:
		queue_free()

# 当与其他物理体（如坦克）碰撞时调用
func _on_body_entered(body):
	# 检查碰撞对象是否是坦克
	if body.is_in_group("tank"):
		body.destroy() # 调用坦克的销毁方法
		queue_free() # 销毁炮弹自身