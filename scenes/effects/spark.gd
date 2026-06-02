extends Node2D
## 命中特效：一次性粒子播放完自动销毁

@export var auto_free_delay: float = 0.6


func _ready() -> void:
    top_level = true
    global_position = global_position

    var particles: GPUParticles2D = _find_particles(self)
    if particles != null:
        particles.emitting = true

    get_tree().create_timer(auto_free_delay).timeout.connect(queue_free)


func _find_particles(node: Node) -> GPUParticles2D:
    if node is GPUParticles2D:
        return node as GPUParticles2D

    for c in node.get_children():
        var p := _find_particles(c)
        if p != null:
            return p

    return null