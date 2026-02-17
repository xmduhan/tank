extends Node
class_name MoveComponent

@export var speed: float = 200.0

var body: CharacterBody2D
var direction: Vector2 = Vector2.ZERO

const BIAS: Vector2 = Vector2(0.1, 0.1)


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    body = get_parent() as CharacterBody2D
    assert(body)


@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
    body.velocity = direction * speed - BIAS

    if direction.length() > 0.0:
        body.rotation = direction.angle()

    body.move_and_slide()