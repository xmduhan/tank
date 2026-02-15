extends Node
class_name HealthComponent
## 血量组件：管理血量，并在宿主头顶显示血条（持续显示）。

signal health_changed(current: float, max_value: float, delta: float)
signal died()

@export var max_health: float = 100.0:
    set(v):
        max_health = max(v, 1.0)
        _current = clamp(_current, 0.0, max_health)
        _emit_changed(0.0)
        _sync_ui()

@export var show_seconds: float = 3.0 # 保留字段以兼容 Inspector，但不再用于自动隐藏

# 血条外观参数（可按需在 Inspector 调）
@export var bar_size := Vector2(90, 10)
@export var bar_offset := Vector2(0, -70) # 相对宿主的偏移（头顶）
@export var bg_color := Color(0, 0, 0, 0.55)
@export var fg_color := Color(0.25, 0.95, 0.25, 0.9)
@export var border_color := Color(1, 1, 1, 0.35)
@export var border_width: float = 1.0

var _current: float = 100.0

@onready var _host: Node = get_parent()
var _bar: _HealthBar
var _hide_timer: Timer


# ─── Computed ─────────────────────────────────────────────

var current_health: float:
    get: return _current

var ratio: float:
    get: return clamp(_current / max_health, 0.0, 1.0)


# ─── Lifecycle ────────────────────────────────────────────

func _ready() -> void:
    assert(_host != null, "HealthComponent requires a host(parent) node.")
    _current = clamp(_current, 0.0, max_health)

    _ensure_ui()
    _sync_ui()
    # 持续显示：进入场景就显示血条
    _set_bar_visible(true)


func _exit_tree() -> void:
    # bar 是挂在宿主上的，组件移除时做一次清理，避免编辑器/运行时热重载残留。
    if is_instance_valid(_bar):
        _bar.queue_free()


# ─── Public API ───────────────────────────────────────────

func set_health(value: float) -> void:
    var new_value: float = clamp(value, 0.0, max_health)
    var delta: float = new_value - _current
    if is_zero_approx(delta):
        return

    _current = new_value
    _emit_changed(delta)

    _on_value_changed()

    if is_zero_approx(_current):
        _handle_death()


func damage(amount: float) -> void:
    print(amount, _current)
    if amount <= 0.0:
        return
    set_health(_current - amount)


func heal(amount: float) -> void:
    if amount <= 0.0:
        return
    set_health(_current + amount)


# ─── Internals ────────────────────────────────────────────

func _handle_death() -> void:
    died.emit()
    # 不在此处 queue_free()：让外部决定死亡表现/销毁时机。


func _emit_changed(delta: float) -> void:
    health_changed.emit(_current, max_health, delta)


func _on_value_changed() -> void:
    _ensure_ui()
    _sync_ui()
    # 持续显示：不再闪烁/隐藏，也不再启动计时器
    _set_bar_visible(true)


func _ensure_ui() -> void:
    if not is_instance_valid(_bar):
        _create_bar()
    # Timer 仍创建以兼容旧结构/热重载，但持续显示模式下不会再启动它
    if not is_instance_valid(_hide_timer):
        _create_timer()


func _sync_ui() -> void:
    if is_instance_valid(_bar):
        _bar.set_ratio(ratio)


func _set_bar_visible(visible: bool) -> void:
    if is_instance_valid(_bar):
        _bar.visible = visible


func _create_bar() -> void:
    _bar = _HealthBar.new()
    _bar.name = "health_bar"
    _bar.size = bar_size
    _bar.position = bar_offset - bar_size * 0.5
    _bar.z_index = 1000
    _bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _bar.set_colors(bg_color, fg_color, border_color, border_width)
    _bar.set_ratio(ratio)

    # Control 挂在宿主下：随宿主移动/旋转（需求更复杂可改 CanvasLayer）。
    _host.add_child(_bar)


func _create_timer() -> void:
    _hide_timer = Timer.new()
    _hide_timer.name = "health_bar_hide_timer"
    _hide_timer.one_shot = true
    _hide_timer.wait_time = show_seconds
    _hide_timer.timeout.connect(func(): _set_bar_visible(false))
    add_child(_hide_timer)


# ─── Internal Control for drawing ─────────────────────────
class _HealthBar extends Control:
    var _ratio: float = 1.0
    var _bg: Color = Color(0, 0, 0, 0.55)
    var _fg: Color = Color(0.25, 0.95, 0.25, 0.9)
    var _border: Color = Color(1, 1, 1, 0.35)
    var _border_w: float = 1.0

    func set_ratio(v: float) -> void:
        _ratio = clamp(v, 0.0, 1.0)
        queue_redraw()

    func set_colors(bg: Color, fg: Color, border: Color, border_w: float) -> void:
        _bg = bg
        _fg = fg
        _border = border
        _border_w = max(border_w, 0.0)
        queue_redraw()

    func _draw() -> void:
        var rect := Rect2(Vector2.ZERO, size)

        # background
        draw_rect(rect, _bg, true)

        # fill
        var fill := Rect2(Vector2.ZERO, Vector2(size.x * _ratio, size.y))
        draw_rect(fill, _fg, true)

        # border
        if _border_w > 0.0:
            draw_rect(rect, _border, false, _border_w)