extends Node
class_name MoveComponent

@export var speed := 200.0

var body: CharacterBody2D
var direction := Vector2.ZERO


func _ready():
    body = get_parent() as CharacterBody2D  
    assert(body)

    # 自动连接同级 Input 组件
    for child in body.get_children():
        if child.has_signal("move_input"):
            child.connect("move_input", _on_move_input)

func _on_move_input(dir: Vector2):
    direction = dir

func _physics_process(delta):
    body.velocity = direction * speed * delta * 60
    body.move_and_slide()
