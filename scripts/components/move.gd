extends Node
class_name MoveComponent

@export var speed: float = 200.0

@export_group("Audio")
@export var enable_tracks_sfx: bool = true
@export var tracks_loop_sfx: AudioStream = preload("res://assets/audio/sfx/tracks_loop.ogg")
@export var tracks_fade_in: float = 0.06
@export var tracks_fade_out: float = 0.10
@export var tracks_volume_db: float = -12.0

var body: CharacterBody2D
var direction: Vector2 = Vector2.ZERO

const BIAS: Vector2 = Vector2(0.1, 0.1)

var _tracks_key: StringName = &""
var _tracks_playing: bool = false
var _tracks_allowed: bool = true


func _ready() -> void:
    # 必须随游戏暂停：答题弹窗出现时 SceneTree.paused=true，
    # MoveComponent 不应继续驱动移动/音效。
    process_mode = Node.PROCESS_MODE_PAUSABLE

    body = get_parent() as CharacterBody2D
    assert(body != null)

    _tracks_key = StringName("tracks_%s" % str(body.get_instance_id()))
    _tracks_allowed = _compute_tracks_allowed()

    set_physics_process(true)
    set_process(true)


func _physics_process(_delta: float) -> void:
    if not is_instance_valid(body):
        return

    body.velocity = direction * speed - BIAS

    if direction.length_squared() > 0.001:
        body.rotation = direction.angle()

    body.move_and_slide()


func _process(_delta: float) -> void:
    _update_tracks_audio()


func _exit_tree() -> void:
    _stop_tracks_immediately()


func _is_moving() -> bool:
    return direction.length_squared() > 0.001


func _compute_tracks_allowed() -> bool:
    if not enable_tracks_sfx:
        return false

    if not is_instance_valid(body):
        return false

    if body.is_in_group(&"enemy") and (not GameBalance.ENEMY_TRACKS_SFX_ENABLED):
        return false

    return tracks_loop_sfx != null


func _update_tracks_audio() -> void:
    if not is_instance_valid(body):
        return

    if not _tracks_allowed:
        if _tracks_playing:
            _stop_tracks_immediately()
        return

    var moving: bool = _is_moving()
    if moving and not _tracks_playing:
        _tracks_playing = true
        AudioManager.play_loop(_tracks_key, tracks_loop_sfx, tracks_volume_db, tracks_fade_in)
        return

    if (not moving) and _tracks_playing:
        _tracks_playing = false
        AudioManager.stop_loop(_tracks_key, tracks_fade_out)


func _stop_tracks_immediately() -> void:
    if _tracks_key == &"":
        return
    _tracks_playing = false
    AudioManager.stop_loop(_tracks_key, 0.0)