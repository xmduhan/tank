extends "res://scripts/units/unit.gd"

class_name Vehicle

# 车辆特有属性
var body_rotation: float = 0.0  # 车身旋转角度
var armor: float = 50.0         # 装甲值
var capacity: int = 5           # 容量（乘客/货物数量）
var current_passengers: int = 0 # 当前乘客数量

# 重写受伤方法，考虑装甲值
func take_damage(amount: float) -> void:
	if is_destroyed:
		return
	
	# 装甲减少伤害
	var actual_damage = max(amount - armor * 0.1, amount * 0.5)
	health -= actual_damage
	print("车辆受到伤害: ", amount, "，装甲减免后: ", actual_damage, "，剩余血量: ", health)
	
	if health <= 0:
		destroy()

# 设置车身旋转
func set_body_rotation(rotation_degrees: float) -> void:
	body_rotation = fmod(rotation_degrees, 360.0)
	print("车身旋转角度设置为: ", body_rotation)

# 载入乘客/货物
func load_passenger() -> bool:
	if current_passengers >= capacity:
		print("车辆已满，无法载入更多乘客")
		return false
	
	current_passengers += 1
	print("乘客已载入，当前乘客数: ", current_passengers, "/", capacity)
	return true

# 卸载乘客/货物
func unload_passenger() -> bool:
	if current_passengers <= 0:
		print("没有乘客可卸载")
		return false
	
	current_passengers -= 1
	print("乘客已卸载，当前乘客数: ", current_passengers, "/", capacity)
	return true