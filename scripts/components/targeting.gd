extends Area2D
class_name TargetingComponent
## 攻击范围组件：检测敌方单位，管理目标列表与瞄准，使用“帧绘制节点”绘制视觉标记。

signal target_changed(new_target: CharacterBody2D)

@export_range(10.0, 100.0, 0.5) var marker_radius := 41.25
@export_range(1.0, 10.0) var line_width := 6.0

var _targets: Array[CharacterBody2D] = []
var _current: CharacterBody2D = null
var _color: Color = Color.WHITE

var _drawer: _TargetingDrawer = null

var current_target: CharacterBody2D:
    get:
        return _current if is_instance_valid(_current) else null


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    z_index = -1
    _setup_color()
    _ensure_drawer()


func _process(_delta: float) -> void:
    _purge_invalid()
    _ensure_drawer()
    if is_instance_valid(_drawer):
        _drawer.queue_redraw()


# ─── 公共接口 ──────────────────────────────────────────────

func cycle_target() -> void:
    if _targets.is_empty():
        return

    var idx := _targets.find(_current)
    _set_target(_targets[(idx + 1) % _targets.size()])


func get_current_target() -> CharacterBody2D:
    return current_target


# ─── 内部逻辑 ─────────────────────────────────────────────

func _ensure_drawer() -> void:
    if is_instance_valid(_drawer):
        return

    _drawer = _TargetingDrawer.new()
    _drawer.name = "targeting_drawer"
    _drawer.z_index = z_index
    _drawer.component = self
    add_child(_drawer)


func _setup_color() -> void:
    var is_enemy := get_parent().is_in_group("enemy")
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

    # 检查是否属于同一阵营（任意分组重叠即视为友军）
    var parent_groups := get_parent().get_groups()
    return not parent_groups.any(func(g): return body.is_in_group(g))


func _set_target(target: CharacterBody2D) -> void:
    if _current == target:
        return
    _current = target
    target_changed.emit(target)


func _release(unit: CharacterBody2D) -> void:
    if unit not in _targets:
        return
    var was_aimed := (unit == _current)
    _targets.erase(unit)
    if was_aimed:
        _set_target(_nearest())


func _purge_invalid() -> void:
    var n := _targets.size()
    _targets.assign(_targets.filter(is_instance_valid))

    if _targets.size() < n and not is_instance_valid(_current):
        _current = null
        _set_target(_nearest())


func _nearest() -> CharacterBody2D:
    if _targets.is_empty():
        return null

    var o := global_position
    return _targets.reduce(func(a: CharacterBody2D, b: CharacterBody2D) -> CharacterBody2D:
        return a if o.distance_squared_to(a.global_position) <= o.distance_squared_to(b.global_position) else b
    )


# ─── 绘制节点(帧绘制) ─────────────────────────────────────

class _TargetingDrawer extends Node2D:
    var component: TargetingComponent = null

    func _draw() -> void:
        if component == null:
            return

        var aimed := component.current_target
        var color := component._color
        var radius := component.marker_radius
        var width := component.line_width

        for t in component._targets:
            if not is_instance_valid(t):
                continue

            var pos := to_local(t.global_position)
            draw_arc(pos, radius, 0.0, TAU, 64, color, width)

            if t == aimed:
                _draw_cross(pos, color)
                _draw_aim_line(pos, color)

    func _draw_cross(pos: Vector2, color: Color) -> void:
        var h := 10.0
        draw_line(pos - Vector2(h, 0.0), pos + Vector2(h, 0.0), color, 2.0)
        draw_line(pos - Vector2(0.0, h), pos + Vector2(0.0, h), color, 2.0)

    func _draw_aim_line(target_pos: Vector2, color: Color) -> void:
        var dist := target_pos.length()
        if dist < 10.0:
            return

        var dir := target_pos.normalized()
        var arrow_size := 8.0
        var spacing := 6.0
        var step := arrow_size + spacing
        var num_arrows := int(dist / step)

        for i in range(num_arrows):
            var t := (i + 1) * step
            if t > dist:
                break

            var tip := dir * t
            var back := tip - dir * arrow_size
            var side := dir.orthogonal() * (arrow_size * 0.5)

            draw_line(back - side, tip, color, 4.0)
            draw_line(back + side, tip, color, 4.0)
