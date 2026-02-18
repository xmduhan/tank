extends Node
class_name AudioManager

## 轻量全局音频管理（无 Autoload 依赖）：
## - 通过静态方法访问：AudioManager.play_sfx_2d / play_loop / stop_loop
## - 通过 ensure(root) 确保场景中存在且仅存在一个实例
## - 支持循环音效按 key 复用，并提供淡入淡出
##
## 新增：
## - set_paused(paused): 暂停时将 loop player stream_paused=true（避免暂停界面仍在循环播放）

static var _instance: AudioManager = null

@export var bus_sfx: StringName = &"Master"
@export var bus_music: StringName = &"Master"

@export var default_sfx_volume_db: float = -6.0
@export var loop_volume_db: float = -12.0

var _loops: Dictionary = {} # StringName -> AudioStreamPlayer
var _tweens: Dictionary = {} # StringName -> Tween
var _paused: bool = false


func _enter_tree() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if _instance == null:
        _instance = self


func _exit_tree() -> void:
    if _instance == self:
        _instance = null


static func is_ready() -> bool:
    return is_instance_valid(_instance)


static func ensure(root: Node) -> AudioManager:
    if is_instance_valid(_instance):
        return _instance

    if root == null:
        return null

    var existing: AudioManager = _find_existing_under(root)
    if is_instance_valid(existing):
        _instance = existing
        return existing

    var mgr: AudioManager = AudioManager.new()
    mgr.name = "AudioManager"
    root.add_child(mgr)
    _instance = mgr
    return mgr


static func _find_existing_under(root: Node) -> AudioManager:
    if root is AudioManager:
        return root as AudioManager

    for c: Node in root.get_children():
        var mgr: AudioManager = c as AudioManager
        if mgr != null:
            return mgr
    return null


static func set_paused(paused: bool) -> void:
    var mgr: AudioManager = ensure(_safe_current_scene())
    if mgr == null:
        return
    mgr._set_paused_impl(paused)


static func play_sfx_2d(host: Node, stream: AudioStream, volume_db: float = NAN, pitch_scale: float = 1.0) -> void:
    if stream == null:
        return

    var root: Node = host.get_tree().current_scene if host != null and host.get_tree() != null else null
    var mgr: AudioManager = ensure(root)
    if mgr == null:
        return

    mgr._play_sfx_2d_impl(host, stream, volume_db, pitch_scale)


static func play_loop(key: StringName, stream: AudioStream, volume_db: float = NAN, fade_in: float = 0.08) -> void:
    if stream == null:
        return

    var mgr: AudioManager = ensure(_safe_current_scene())
    if mgr == null:
        return

    mgr._play_loop_impl(key, stream, volume_db, fade_in)


static func stop_loop(key: StringName, fade_out: float = 0.10) -> void:
    var mgr: AudioManager = ensure(_safe_current_scene())
    if mgr == null:
        return

    mgr._stop_loop_impl(key, fade_out)


static func _safe_current_scene() -> Node:
    var tree: SceneTree = Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.current_scene


func _set_paused_impl(paused: bool) -> void:
    _paused = paused
    for key: Variant in _loops.keys():
        var k: StringName = key as StringName
        var p: AudioStreamPlayer = _loops.get(k, null) as AudioStreamPlayer
        if is_instance_valid(p):
            p.stream_paused = _paused


func _play_sfx_2d_impl(host: Node, stream: AudioStream, volume_db: float, pitch_scale: float) -> void:
    var p: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
    p.stream = stream
    p.bus = bus_sfx
    p.volume_db = default_sfx_volume_db if is_nan(volume_db) else volume_db
    p.pitch_scale = maxf(pitch_scale, 0.01)

    var world: Node = SceneTreeUtils.safe_world(host) if host != null else get_tree().current_scene
    if world == null:
        return

    world.add_child(p)

    if host is Node2D:
        p.global_position = (host as Node2D).global_position
    else:
        p.global_position = Vector2.ZERO

    p.finished.connect(p.queue_free)
    p.play()


func _play_loop_impl(key: StringName, stream: AudioStream, volume_db: float, fade_in: float) -> void:
    var player: AudioStreamPlayer = _loops.get(key, null) as AudioStreamPlayer
    if not is_instance_valid(player):
        player = AudioStreamPlayer.new()
        player.bus = bus_sfx
        add_child(player)
        _loops[key] = player

    _ensure_stream_looping(stream)

    var target_db: float = loop_volume_db if is_nan(volume_db) else volume_db
    var should_restart: bool = (player.stream != stream)

    player.stream = stream
    player.pitch_scale = 1.0
    player.stream_paused = _paused
    player.volume_db = target_db if fade_in <= 0.0 else -80.0

    if not player.playing or should_restart:
        player.play()

    _kill_tween(key)
    if fade_in > 0.0:
        var tw: Tween = create_tween()
        _tweens[key] = tw
        tw.tween_property(player, "volume_db", target_db, fade_in).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _stop_loop_impl(key: StringName, fade_out: float) -> void:
    var player: AudioStreamPlayer = _loops.get(key, null) as AudioStreamPlayer
    if not is_instance_valid(player):
        _loops.erase(key)
        _kill_tween(key)
        return

    _kill_tween(key)

    if fade_out <= 0.0:
        player.stop()
        return

    var tw: Tween = create_tween()
    _tweens[key] = tw
    tw.tween_property(player, "volume_db", -80.0, fade_out).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    tw.tween_callback(Callable(player, "stop"))


func _kill_tween(key: StringName) -> void:
    var tw: Tween = _tweens.get(key, null) as Tween
    if is_instance_valid(tw):
        tw.kill()
    _tweens.erase(key)


func _ensure_stream_looping(stream: AudioStream) -> void:
    if stream == null:
        return

    var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
    if ogg != null:
        ogg.loop = true
        return