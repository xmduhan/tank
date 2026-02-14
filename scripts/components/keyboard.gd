extends Node
class_name Keyboard

signal move_input(direction: Vector2)

func _physics_process(delta):
	var dir := Vector2.ZERO

	if Input.is_key_pressed(KEY_H):
		dir.x -= 1
	if Input.is_key_pressed(KEY_L):
		dir.x += 1
	if Input.is_key_pressed(KEY_K):
		dir.y -= 1
	if Input.is_key_pressed(KEY_J):
		dir.y += 1

	emit_signal("move_input", dir)
