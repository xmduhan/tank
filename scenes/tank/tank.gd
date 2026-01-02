extends Area2D

# 车身旋转角度（弧度）
var body_rotation: float = 1.6
# 炮塔旋转角度（弧度）
var turret_rotation: float = 0

func _ready():
	$body.frame = 0
	$turret.frame = 0
	
	# 应用初始旋转角度
	$body.rotation = body_rotation
	$turret.rotation = turret_rotation
