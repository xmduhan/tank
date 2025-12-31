# res://scripts/Tank.gd
extends Area2D

# 坦克脚本，负责显示算式、移动和被击中。
# 挂在 actors/Tank.tscn 的根节点 Area2D 上。

@onready var label = $Label

var correct_answer: int

func _ready():
	# 将坦克添加到“tank”组，便于炮弹识别
	add_to_group("tank")
	# 连接碰撞信号（虽然主要靠炮弹检测，但保留以备扩展）
	body_entered.connect(_on_body_entered)

# 初始化坦克：设置算式和答案
func setup(num1: int, num2: int, answer: int):
	correct_answer = answer
	label.text = str(num1) + " + " + str(num2) + " = ?"

# 被击中时调用，销毁坦克
func destroy():
	queue_free()

# 碰撞处理（备用逻辑）
func _on_body_entered(body):
	if body.is_in_group("projectile"):
		destroy()