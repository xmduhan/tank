extends Node2D
class_name RedCircleMarker

func _draw():
	draw_arc(Vector2.ZERO, 40, 0, TAU, 64, Color.RED, 2.0)
