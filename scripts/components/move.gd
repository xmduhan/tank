extends Node
class_name MoveComponent

@export var speed := 200.0
@export var separation_force := 40.0   # ✅ 新增：分离力度

var body: CharacterBody2D
var direction := Vector2.ZERO
const BIAS := Vector2(.2, .2)

func _ready():
    body = get_parent() as CharacterBody2D
    assert(body)

    # 自动连接同级 Input / AI 组件
    for child in body.get_children():
        if child.has_signal("move_input"):
            child.connect("move_input", _on_move_input)


func _on_move_input(dir: Vector2):
    direction = dir


func _physics_process(delta):
    # 1️⃣ 正常移动
    body.velocity = direction * speed - BIAS
    body.move_and_slide()
