extends Node2D
## 坦克殉爆特效：一次性粒子播放完自动销毁
## 新增：播放爆炸音效（命中爆炸/死亡殉爆共用该特效）

@export var auto_free_delay: float = 1.2

@export_group("Audio")
@export var explosion_sfx: AudioStream = preload("res://assets/audio/sfx/explosion.ogg")

func _ready() -> void:
    top_level = true
    global_position = global_position

    AudioManager.play_sfx_2d(self, explosion_sfx)

    var particles: GPUParticles2D = _find_particles(self)
    if particles != null:
        particles.emitting = true

    get_tree().create_timer(auto_free_delay).timeout.connect(queue_free)


func _find_particles(node: Node) -> GPUParticles2D:
    if node is GPUParticles2D:
        return node as GPUParticles2D

    for c in node.get_children():
        var p: GPUParticles2D = _find_particles(c)
        if p != null:
            return p

    return null