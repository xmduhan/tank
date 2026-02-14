extends Node

@onready var move: MoveComponent = get_parent().get_node_or_null("movable") as MoveComponent

func _ready() -> void:
	assert(move != null)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S):
		direction.y += 1

	# 防止斜向移动更快
	move.direction = direction.normalized()