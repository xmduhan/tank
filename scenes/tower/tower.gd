extends Node2D

var move_speed = 200  # 移动速度，单位：像素/秒

func _process(delta):
	# 检测键盘输入并移动炮塔
	if Input.is_action_pressed("tower_left"):  # 默认h键映射到ui_left
		position.x -= move_speed * delta
	if Input.is_action_pressed("tower_right"):  # 默认l键映射到ui_right
		position.x += move_speed * delta
