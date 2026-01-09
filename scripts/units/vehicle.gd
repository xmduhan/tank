extends Unit

class_name Vehicle

# 车辆特有属性
var body_rotation: float = 0.0  # 车身旋转角度
var armor: float = 50.0         # 装甲值
var capacity: int = 5           # 容量（单位数量）
var current_units: int = 0      # 当前单位数量（乘客/物资）

# 重写受伤方法，考虑装甲值
func take_damage(amount: float) -> void:
    var actual_damage = max(amount - armor * 0.1, amount * 0.5)
    health -= actual_damage
    print("车辆受到伤害: ", amount, "，装甲减免后: ", actual_damage, "，剩余血量: ", health)

# 设置车身旋转
func set_body_rotation(rotation_degrees: float) -> void:
    body_rotation = fmod(rotation_degrees, 360.0)
    print("车身旋转角度设置为: ", body_rotation)

