extends Node2D
class_name OneShotFx
## OneShotFx：一次性特效通用基类（极致 DRY）
## - 自动 top_level，保持世界坐标不随父节点变换
## - 自动查找并触发第一个 GPUParticles2D emitting
## - auto_free_delay 秒后 queue_free
##
## 用法：
## 1) 特效脚本 extends OneShotFx
## 2) 可覆盖：
##    - _on_before_play(): 播放前钩子（例如播放音效）
##    - _on_after_play(): 播放后钩子

@export var auto_free_delay: float = 0.6

var _timer_started: bool = false


func _ready() -> void:
    top_level = true
    global_position = global_position

    _on_before_play()

    var particles: GPUParticles2D = _find_first_particles(self)
    if particles != null:
        particles.emitting = true

    _on_after_play()

    _start_auto_free_timer()


func _on_before_play() -> void:
    pass


func _on_after_play() -> void:
    pass


func _start_auto_free_timer() -> void:
    if _timer_started:
        return
    _timer_started = true

    var delay: float = maxf(auto_free_delay, 0.0)
    if delay <= 0.0:
        queue_free()
        return

    var tree: SceneTree = get_tree()
    assert(tree != null, "OneShotFx must be inside SceneTree.")

    tree.create_timer(delay).timeout.connect(queue_free)


static func _find_first_particles(node: Node) -> GPUParticles2D:
    if node is GPUParticles2D:
        return node as GPUParticles2D

    for c: Node in node.get_children():
        var p: GPUParticles2D = _find_first_particles(c)
        if p != null:
            return p

    return null
