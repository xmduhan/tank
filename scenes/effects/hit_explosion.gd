extends Node2D

@onready var _p: GPUParticles2D = $Particles


func _ready() -> void:
    top_level = true
    if _p != null:
        _p.one_shot = true
        _p.emitting = true


func _process(_delta: float) -> void:
    if _p != null and not _p.emitting:
        queue_free()