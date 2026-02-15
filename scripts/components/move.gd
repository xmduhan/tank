extends Node
class_name MoveComponent

@export var speed := 200.0

var body: CharacterBody2D
var direction := Vector2.ZERO

const BIAS := Vector2(.1, .1)

func _ready():
    body = get_parent() as CharacterBody2D
    assert(body)

@warning_ignore("unused_parameter")
func _physics_process(delta):
    # 1️⃣ 正常移动
    body.velocity = direction * speed - BIAS
    
    # 2️⃣ 根据方向旋转坦克（瞬间转向）
    if direction.length() > 0:
        # 直接设置旋转角度，实现瞬间转向
        body.rotation = direction.angle()
    
    body.move_and_slide()
