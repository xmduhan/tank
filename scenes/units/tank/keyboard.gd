extends Node

@onready var move: MoveComponent = get_parent().get_node_or_null("movable") as MoveComponent

func _ready() -> void:
	assert(move != null)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_H):
		direction.x -= 1
	if Input.is_key_pressed(KEY_L):
		direction.x += 1
	if Input.is_key_pressed(KEY_K):
		direction.y -= 1
	if Input.is_key_pressed(KEY_J):
		direction.y += 1

	# 防止斜向移动更快
	move.direction = direction.normalized()