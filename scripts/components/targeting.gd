extends Area2D
class_name TargetingComponent
## 攻击范围组件：检测敌方单位，管理目标列表与瞄准，统一绘制视觉标记。

signal target_changed(new_target: CharacterBody2D)

@export_range(10.0, 100.0, 0.5) var marker_radius: float = 41.25
@export_range(1.0, 10.0) var line_width: float = 6.0

@export_group("Aim Line")
@export var min_aim_width: float = 2.0
@export var max_aim_width: float = 200.0
@export var min_line_thickness: float = 1.5
@export var max_line_thickness: float = 7.0

var _targets: Array[CharacterBody2D] = []
var _current: CharacterBody2D = null
var _color: Color

var current_target: CharacterBody2D:
    get: return _current if is_instance_valid(_current) else null


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    z_index = -1
    _setup_color()


func _process(_delta: float) -> void:
    _purge_invalid()
    queue_redraw()


func _draw() -> void:
    var aimed: CharacterBody2D = current_target
    for t in _targets:
        var pos: Vector2 = to_local(t.global_position)
        draw_arc(pos, marker_radius, 0, TAU, 64, _color, line_width)

        if t == aimed:
            _draw_cross(pos)
            _draw_aim_line(pos)


func cycle_target() -> void:
    if _targets.is_empty():
        return
    var idx: int = _targets.find(_current)
    _set_target(_targets[(idx + 1) % _targets.size()])


func _setup_color() -> void:
    var is_enemy: bool = get_parent().is_in_group("enemy")
    _color = Color(0.4, 0.6, 1.0, 0.6) if is_enemy else Color(1.0, 0.4, 0.4, 0.6)


func _on_body_entered(body: Node2D) -> void:
    if _is_valid_unit(body) and body not in _targets:
        _targets.append(body)
        if not current_target:
            _set_target(body as CharacterBody2D)


func _on_body_exited(body: Node2D) -> void:
    if body is CharacterBody2D:
        _release(body as CharacterBody2D)


func _is_valid_unit(body: Node2D) -> bool:
    if body == get_parent() or body is not CharacterBody2D:
        return false
    var parent_groups: Array[StringName] = get_parent().get_groups()
    return not parent_groups.any(func(g: StringName) -> bool: return body.is_in_group(g))


func _set_target(target: CharacterBody2D) -> void:
    if _current == target:
        return
    _current = target
    target_changed.emit(target)


func _release(unit: CharacterBody2D) -> void:
    if unit not in _targets:
        return
    var was_aimed: bool = (unit == _current)
    _targets.erase(unit)
    if was_aimed:
        _set_target(_nearest())


func _purge_invalid() -> void:
    var n: int = _targets.size()
    _targets.assign(_targets.filter(is_instance_valid))
    if _targets.size() < n and not is_instance_valid(_current):
        _current = null
        _set_target(_nearest())


func _nearest() -> CharacterBody2D:
    if _targets.is_empty():
        return null
    var o: Vector2 = global_position
    return _targets.reduce(func(a: CharacterBody2D, b: CharacterBody2D) -> CharacterBody2D:
        return a if o.distance_squared_to(a.global_position) <= o.distance_squared_to(b.global_position) else b
    )


func _draw_cross(pos: Vector2) -> void:
    var h: float = 10.0
    draw_line(pos - Vector2(h, 0), pos + Vector2(h, 0), _color, 2.0)
    draw_line(pos - Vector2(0, h), pos + Vector2(0, h), _color, 2.0)


func _draw_aim_line(target_pos: Vector2) -> void:
    var dist: float = target_pos.length()
    if dist < 10.0:
        return

    var aim_color: Color = Color(_color.r, _color.g, _color.b, _color.a * 0.4)

    var dir: Vector2 = target_pos.normalized()
    var arrow_size: float = 8.0
    var spacing: float = 20.0
    var step: float = arrow_size + spacing
    var num_arrows: int = int(dist / step)

    for i in range(num_arrows):
        var t: float = (i + 1) * step
        if t > dist:
            break

        var progress: float = t / dist
        var spread: float = lerpf(min_aim_width, max_aim_width, progress)
        var half_spread: float = spread * 0.5
        var w: float = lerpf(min_line_thickness, max_line_thickness, progress)

        var tip: Vector2 = dir * t
        var back: Vector2 = tip - dir * arrow_size
        var side: Vector2 = dir.orthogonal() * half_spread

        draw_line(back - side, tip, aim_color, w)
        draw_line(back + side, tip, aim_color, w)