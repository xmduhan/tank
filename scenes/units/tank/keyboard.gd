extends Node

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass

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
