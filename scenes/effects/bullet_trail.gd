extends Node2D

signal arrived

@export var width: float = 4.0
@export var color: Color = Color(1.0, 0.9, 0.5, 0.9)
@export var fade_time: float = 0.08

var _start: Vector2
var _end: Vector2
var _speed: float = 900.0
var _t: float = 0.0
var _fading: bool = false

@onready var _line: Line2D = $Line


func setup(start_pos: Vector2, end_pos: Vector2, speed: float = 900.0) -> void:
    _start = start_pos
    _end = end_pos
    _speed = max(speed, 1.0)

    top_level = true
    global_position = Vector2.ZERO

    _apply_style()
    _update_line(_start)


func _ready() -> void:
    if _start == Vector2.ZERO and _end == Vector2.ZERO:
        _start = global_position
        _end = global_position
    _apply_style()


func _process(delta: float) -> void:
    if _fading:
        var c := _line.default_color
        c.a = max(c.a - delta / max(fade_time, 0.001), 0.0)
        _line.default_color = c
        if c.a <= 0.01:
            queue_free()
        return

    var dist := _start.distance_to(_end)
    if dist <= 0.001:
        _arrive()
        return

    _t += (_speed * delta) / dist
    if _t >= 1.0:
        _t = 1.0

    var head := _start.lerp(_end, _t)
    _update_line(head)

    if is_equal_approx(_t, 1.0):
        _arrive()


func _apply_style() -> void:
    if _line == null:
        return
    _line.width = width
    _line.default_color = color


func _update_line(head: Vector2) -> void:
    if _line == null:
        return
    _line.clear_points()
    _line.add_point(_start)
    _line.add_point(head)


func _arrive() -> void:
    arrived.emit()
    _fading = true