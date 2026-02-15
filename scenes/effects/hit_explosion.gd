extends Node2D

@export var ring_radius_start: float = 6.0
@export var ring_radius_end: float = 42.0
@export var ring_points: int = 32
@export var ring_time: float = 0.12

@onready var _p: GPUParticles2D = $Particles
@onready var _ring: Line2D = $Ring

var _t: float = 0.0


func _ready() -> void:
    top_level = true

    if _p != null:
        _p.one_shot = true
        _p.emitting = true

    if _ring != null:
        _ring.visible = true
        _ring.z_index = 10
        _rebuild_ring(ring_radius_start)
        var c := _ring.default_color
        c.a = 1.0
        _ring.default_color = c


func _process(delta: float) -> void:
    _t += delta

    if _ring != null:
        var p := clampf(_t / max(ring_time, 0.001), 0.0, 1.0)
        var eased := 1.0 - pow(1.0 - p, 3.0)
        var r := lerpf(ring_radius_start, ring_radius_end, eased)
        _rebuild_ring(r)

        var c := _ring.default_color
        c.a = lerpf(1.0, 0.0, p)
        _ring.default_color = c

        if p >= 1.0:
            _ring.visible = false

    if _p != null and not _p.emitting and (_ring == null or not _ring.visible):
        queue_free()


func _rebuild_ring(radius: float) -> void:
    if _ring == null:
        return

    var pts: int = max(ring_points, 12)
    _ring.clear_points()

    for i in range(pts):
        var a := TAU * float(i) / float(pts)
        _ring.add_point(Vector2(cos(a), sin(a)) * radius)
