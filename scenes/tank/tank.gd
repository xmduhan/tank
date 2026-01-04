extends Area2D

# 车身旋转角度（度）- 初始指向东方(0度)
var body_rotation: float = 90
# 炮塔旋转角度（度）- 初始与车身方向一致
var turret_rotation: float = 45
# 移动速度（像素/秒）
var move_speed: float = 20.0

func _ready():
	$body.frame = 0
	$turret.frame = 0
	
	# 应用初始旋转角度（将角度转换为弧度）
	$body.rotation = deg_to_rad(body_rotation)
	$turret.rotation = deg_to_rad(turret_rotation)

func _process(delta):
	# 将角度转换为弧度后计算移动向量
	var body_rotation_rad = deg_to_rad(body_rotation)
	var move_vector = Vector2(cos(body_rotation_rad), sin(body_rotation_rad)) * move_speed * delta
	# 更新位置
	position += move_vector
