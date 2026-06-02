extends Node
class_name RadarAudioController
## 雷达循环音效仲裁器（P2 解耦）：
## - 监听所有 TargetingComponent.target_changed 以获知“是否存在锁定目标”
## - 外部通过 set_aiming(true/false) 告知“正在答题/瞄准”以切换变速
## - ALWAYS：在 SceneTree.paused 时仍可更新 loop（是否播放由 AudioManager 自身决定）

@export_group("Audio")
@export var radar_sfx: AudioStream = preload("res://assets/audio/sfx/radar.wav")
@export var loop_key: StringName = &"radar"
@export var volume_db: float = -18.0
@export var fade_in: float = 0.08
@export var fade_out: float = 0.10
@export var pitch_normal: float = 1.0
@export var pitch_aiming: float = 2.0

var _has_target: bool = false
var _is_aiming: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    if radar_sfx == null:
        push_error("RadarAudioController: radar_sfx is null.")

    _wire_targeting_tree(get_tree().current_scene if get_tree() != null else null)

    var cs: Node = get_tree().current_scene if get_tree() != null else null
    if cs != null:
        cs.child_entered_tree.connect(_on_any_node_entered_tree)


func set_aiming(active: bool) -> void:
    if _is_aiming == active:
        return
    _is_aiming = active
    _update_loop()


func _on_any_node_entered_tree(node: Node) -> void:
    _wire_targeting_tree(node)


func _wire_targeting_tree(root: Node) -> void:
    if root == null:
        return

    for n: Node in _walk(root):
        var t: TargetingComponent = n as TargetingComponent
        if t == null:
            continue

        if not t.target_changed.is_connected(_on_target_changed):
            t.target_changed.connect(_on_target_changed)


func _walk(root: Node) -> Array[Node]:
    var out: Array[Node] = []
    var stack: Array[Node] = [root]

    while not stack.is_empty():
        var n: Node = stack.pop_back()
        out.append(n)
        for c: Node in n.get_children():
            stack.append(c)

    return out


func _on_target_changed(new_target: CharacterBody2D) -> void:
    _has_target = is_instance_valid(new_target)
    _update_loop()


func _update_loop() -> void:
    if _has_target:
        var pitch: float = pitch_aiming if _is_aiming else pitch_normal
        AudioManager.play_loop(loop_key, radar_sfx, volume_db, fade_in, pitch)
    else:
        AudioManager.stop_loop(loop_key, fade_out)
