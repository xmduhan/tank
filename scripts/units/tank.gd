extends Vehicle

class_name Tank

# 坦克特有属性
var turret_rotation: float = 0.0  # 炮塔旋转角度

# 设置炮塔旋转
func set_turret_rotation(rotation_degrees: float) -> void:
    turret_rotation = fmod(rotation_degrees, 360.0)
    print("炮塔旋转角度设置为: ", turret_rotation)

# 开火
func fire() -> bool:
    return true
