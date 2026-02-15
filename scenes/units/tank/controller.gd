extends Node

@onready var move: MoveComponent = get_parent().get_node_or_null("movable") as MoveComponent
@onready var attack_range = get_parent().get_node_or_null("attack_range")

func _ready() -> void:
	assert(move != null)

func _unhandled_input(event: InputEvent) -> void:
	# Tab 键切换瞄准目标
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if attack_range and attack_range.has_method("cycle_target"):
			attack_range.cycle_target()

func _physics_process(_delta: float) -> void:
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
