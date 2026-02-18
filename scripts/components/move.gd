extends Node
class_name MoveComponent

@export var speed: float = 200.0

@export_group("Audio")
@export var tracks_loop_sfx: AudioStream = preload("res://assets/audio/sfx/tracks_loop.ogg")
@export var tracks_fade_in: float = 0.06
@export var tracks_fade_out: float = 0.10

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

    _update_tracks_audio()
    body.move_and_slide()


func _update_tracks_audio() -> void:
    if not is_instance_valid(body):
        return

    var moving: bool = direction.length_squared() > 0.001
    if moving:
        AudioManager.play_loop(&"tracks", tracks_loop_sfx, -12.0, tracks_fade_in)
    else:
        AudioManager.stop_loop(&"tracks", tracks_fade_out)