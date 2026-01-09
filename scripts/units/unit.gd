extends Node

class_name Unit

# 基础属性
var health: float = 100.0
var max_health: float = 100.0
var move_speed: float = 100.0
var is_destroyed: bool = false

# 移动功能
func move(direction: Vector2, delta: float) -> void:
	if is_destroyed:
		print("单位已被摧毁，无法移动")
		return
	
	var velocity = direction.normalized() * move_speed * delta
	# 在实际游戏中，这里会更新位置
	print("单位移动: ", velocity)

# 受到伤害
func take_damage(amount: float) -> void:
	if is_destroyed:
		return
	
	health -= amount
	print("单位受到伤害: ", amount, "，剩余血量: ", health)
	
	if health <= 0:
		destroy()

# 摧毁单位
func destroy() -> void:
	is_destroyed = true
	print("单位已被摧毁")

# 治疗单位
func heal(amount: float) -> void:
	if is_destroyed:
		print("单位已被摧毁，无法治疗")
		return
	
	health = min(health + amount, max_health)
	print("单位治疗: ", amount, "，当前血量: ", health)