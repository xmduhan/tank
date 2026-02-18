extends Node
class_name KeyEcho

## KeyEcho：键盘输入回响组件
## - echo_key_event(): 将 InputEventKey 映射为“数字/退格/提交/取消/其它”并播放音效
## - 默认使用 assets/audio/sfx/keypress.wav
## - 支持节流：避免按住键时音效过密
## - PROCESS_MODE_ALWAYS：暂停时也能回响（依赖 AudioManager 本身 ALWAYS）

enum EchoKind {
    DIGIT,
    BACKSPACE,
    SUBMIT,
    CANCEL,
    OTHER
}

@export_group("Audio Streams")
@export var keypress_sfx: AudioStream = preload("res://assets/audio/sfx/keypress.wav")
@export var backspace_sfx: AudioStream = null
@export var submit_sfx: AudioStream = null
@export var cancel_sfx: AudioStream = null

@export_group("Mix")
@export var volume_db: float = -10.0
@export var digit_pitch: float = 1.00
@export var backspace_pitch: float = 0.92
@export var submit_pitch: float = 1.06
@export var cancel_pitch: float = 0.96

@export_group("Throttle")
@export var min_interval_seconds: float = 0.030

var _last_play_ms: int = -1


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func echo_key_event(event: InputEventKey, host: Node) -> void:
    if event == null or not event.pressed:
        return

    if event.echo:
        return

    if not _allow_play_now():
        return

    var kind: int = _classify(event)
    var stream: AudioStream = _stream_for_kind(kind)
    if stream == null:
        return

    AudioManager.play_sfx_2d(host, stream, volume_db, _pitch_for_kind(kind))


func _allow_play_now() -> bool:
    var interval: float = maxf(min_interval_seconds, 0.0)
    if interval <= 0.0:
        return true

    var now_ms: int = Time.get_ticks_msec()
    if _last_play_ms < 0:
        _last_play_ms = now_ms
        return true

    var dt_ms: int = now_ms - _last_play_ms
    if float(dt_ms) >= interval * 1000.0:
        _last_play_ms = now_ms
        return true

    return false


func _classify(event: InputEventKey) -> int:
    var kc: int = int(event.keycode)

    if _is_digit_keycode(kc):
        return EchoKind.DIGIT

    if kc == KEY_BACKSPACE:
        return EchoKind.BACKSPACE

    if kc == KEY_ESCAPE:
        return EchoKind.CANCEL

    if kc == KEY_ENTER or kc == KEY_KP_ENTER:
        return EchoKind.SUBMIT

    return EchoKind.OTHER


func _is_digit_keycode(kc: int) -> bool:
    return (kc >= KEY_0 and kc <= KEY_9) or (kc >= KEY_KP_0 and kc <= KEY_KP_9)


func _stream_for_kind(kind: int) -> AudioStream:
    match kind:
        EchoKind.DIGIT:
            return keypress_sfx
        EchoKind.BACKSPACE:
            return backspace_sfx if backspace_sfx != null else keypress_sfx
        EchoKind.SUBMIT:
            return submit_sfx if submit_sfx != null else keypress_sfx
        EchoKind.CANCEL:
            return cancel_sfx if cancel_sfx != null else keypress_sfx
        EchoKind.OTHER:
            return keypress_sfx
        _:
            return keypress_sfx


func _pitch_for_kind(kind: int) -> float:
    match kind:
        EchoKind.DIGIT:
            return digit_pitch
        EchoKind.BACKSPACE:
            return backspace_pitch
        EchoKind.SUBMIT:
            return submit_pitch
        EchoKind.CANCEL:
            return cancel_pitch
        EchoKind.OTHER:
            return digit_pitch
        _:
            return 1.0