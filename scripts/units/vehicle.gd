extends "res://scripts/units/unit.gd"

class_name Vehicle

# 车辆特有属性
var body_rotation: float = 0.0  # 车身旋转角度
var armor: float = 50.0         # 装甲值
var capacity: int = 5           # 容量（单位数量）
var current_units: int = 0      # 当前单位数量（乘客/物资）

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

# 载入单位（乘客/物资）
func load_units(count: int = 1) -> bool:
    if current_units + count > capacity:
        print("车辆容量不足，无法载入", count, "个单位")
        print("当前: ", current_units, "/", capacity, "，尝试载入后: ", current_units + count, "/", capacity)
        return false
    
    current_units += count
    print(count, "个单位已载入，当前单位数: ", current_units, "/", capacity)
    return true

# 卸载单位（乘客/物资）
func unload_units(count: int = 1) -> bool:
    if current_units - count < 0:
        print("没有足够的单位可卸载")
        print("当前: ", current_units, "/", capacity, "，尝试卸载后: ", current_units - count, "/", capacity)
        return false
    
    current_units -= count
    print(count, "个单位已卸载，当前单位数: ", current_units, "/", capacity)
    return true

# 获取容量状态
func get_capacity_status() -> String:
    return "容量状态: " + str(current_units) + "/" + str(capacity) + " 单位"