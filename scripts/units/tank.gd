extends "res://scripts/units/vehicle.gd"

class_name Tank

# 坦克特有属性
var turret_rotation: float = 0.0  # 炮塔旋转角度
var ammo_count: int = 20          # 炮弹数量
var max_ammo: int = 20            # 最大炮弹数量

# 设置炮塔旋转
func set_turret_rotation(rotation_degrees: float) -> void:
	turret_rotation = fmod(rotation_degrees, 360.0)
	print("炮塔旋转角度设置为: ", turret_rotation)

# 开火
func fire() -> bool:
	if is_destroyed:
		print("坦克已被摧毁，无法开火")
		return false
	
	if ammo_count <= 0:
		print("没有炮弹了！")
		return false
	
	ammo_count -= 1
	print("开火！剩余炮弹: ", ammo_count, "/", max_ammo)
	return true

# 重新装填
func reload(amount: int) -> void:
	if is_destroyed:
		print("坦克已被摧毁，无法装填")
		return
	
	ammo_count = min(ammo_count + amount, max_ammo)
	print("装填炮弹: ", amount, "，当前炮弹: ", ammo_count, "/", max_ammo)

# 坦克特有的移动方式
func move(direction: Vector2, delta: float) -> void:
	if is_destroyed:
		print("坦克已被摧毁，无法移动")
		return
	
	# 坦克移动速度较慢
	var tank_speed = move_speed * 0.7
	var velocity = direction.normalized() * tank_speed * delta
	print("坦克移动: ", velocity, " (速度较慢但装甲厚重)")