extends Area2D

# 车身旋转角度（弧度）- 初始指向东方(0弧度)
var body_rotation: float = 0
# 炮塔旋转角度（弧度）- 初始与车身方向一致
var turret_rotation: float = 0
# 移动速度（像素/秒）
var move_speed: float = 60.0

func _ready():
	$body.frame = 0
	$turret.frame = 0
	
	# 应用初始旋转角度
	$body.rotation = body_rotation
	$turret.rotation = turret_rotation

func _process(delta):
	# 根据车身方向计算移动向量，并乘以delta时间确保帧率无关的平滑移动
	var move_vector = Vector2(cos(body_rotation), sin(body_rotation)) * move_speed * delta
	# 更新位置
	position += move_vector