extends Node2D
class_name RedCircleMarker

var highlighted := false

func _draw():
	if highlighted:
		# 当前瞄准目标：黄色粗圈
		draw_arc(Vector2.ZERO, 40, 0, TAU, 64, Color.YELLOW, 3.0)
	else:
		# 范围内非瞄准目标：红色圈
		draw_arc(Vector2.ZERO, 40, 0, TAU, 64, Color.RED, 2.0)