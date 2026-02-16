extends Node2D

signal arrived

@export var width: float = 12.375
@export var color: Color = Color(1.0, 0.15, 0.08, 1.0)

## 到达后淡出时间（更短 = 反馈更快）
@export var fade_time: float = 0.04

## 最短飞行时间：防止距离很近时"看不到"，但仍然非常快
@export var min_flight_time: float = 0.02

## 到达判定阈值：更早触发 arrived，让打击更"爽快"
@export_range(0.0, 1.0, 0.01) var arrive_threshold: float = 0.92

@export_group("Feel")
## 尾迹长度占总距离的比例（越大 = 弹道越长）
@export_range(0.01, 1.0, 0.01) var trail_length_ratio: float = 0.19
## 尾迹的最小长度（像素），防止距离很近时完全看不见
@export var min_trail_length: float = 50.0
## 速度倍率
@export var speed_multiplier: float = 4.0

@export_group("Shape")
## 水滴形线段数量（越多越平滑）
@export var segments: int = 16

var _start: Vector2
var _end: Vector2
var _speed: float = 900.0
var _t: float = 0.0
var _fading: bool = false
var _flight_time: float = 0.0
var _elapsed: float = 0.0
var _arrived_emitted: bool = false

@onready var _line: Line2D = $Line


func setup(start_pos: Vector2, end_pos: Vector2, speed: float = 900.0) -> void:
    _start = start_pos
    _end = end_pos
    _speed = max(speed * speed_multiplier, 1.0)

    top_level = true
    global_position = Vector2.ZERO

    _elapsed = 0.0
    _t = 0.0
    _fading = false
    _arrived_emitted = false

    var dist: float = _start.distance_to(_end)
    _flight_time = max(dist / _speed, min_flight_time)

    _apply_style()
    _update_line(_start)


func _ready() -> void:
    if _start == Vector2.ZERO and _end == Vector2.ZERO:
        _start = global_position
        _end = global_position
    _apply_style()


func _process(delta: float) -> void:
    if _line == null:
        return

    if _fading:
        var c: Color = _line.default_color
        c.a = max(c.a - delta / max(fade_time, 0.001), 0.0)
        _line.default_color = c
        if c.a <= 0.01:
            queue_free()
        return

    var dist: float = _start.distance_to(_end)
    if dist <= 0.001:
        _emit_arrived_if_needed()
        _begin_fade()
        return

    _elapsed += delta
    _t = clampf(_elapsed / max(_flight_time, 0.001), 0.0, 1.0)

    var head: Vector2 = _start.lerp(_end, _t)
    _update_line(head)

    if (not _arrived_emitted) and _t >= arrive_threshold:
        _emit_arrived_if_needed()

    if is_equal_approx(_t, 1.0):
        _begin_fade()


func _apply_style() -> void:
    _line.width = width
    if color.a <= 0.0 and color.r <= 0.0 and color.g <= 0.0 and color.b <= 0.0:
        color = Color(1.0, 0.98, 0.85, 1.0)
    _line.default_color = color


## 用多段线点构建尾迹，配合 width_curve 实现水滴形状
func _update_line(head: Vector2) -> void:
    var full_dist: float = _start.distance_to(_end)
    var tail_len: float = max(full_dist * trail_length_ratio, min_trail_length)

    var dir: Vector2 = head - _start
    var head_dist: float = dir.length()
    if head_dist <= 0.001:
        _line.clear_points()
        _line.add_point(_start)
        _line.add_point(_start)
        return

    var tail_start_dist: float = max(head_dist - tail_len, 0.0)
    var direction: Vector2 = dir.normalized()
    var tail: Vector2 = _start + direction * tail_start_dist

    _line.clear_points()

    # 使用多个线段点，让 width_curve 的水滴轮廓平滑渲染
    var seg: int = max(segments, 2)
    for i in range(seg + 1):
        var tt: float = float(i) / float(seg)
        var point: Vector2 = tail.lerp(head, tt)
        _line.add_point(point)


func _emit_arrived_if_needed() -> void:
    if _arrived_emitted:
        return
    _arrived_emitted = true
    arrived.emit()


func _begin_fade() -> void:
    _fading = true