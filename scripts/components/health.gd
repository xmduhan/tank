extends Node2D
class_name HealthComponent
## 血量组件：管理血量数值，提供伤害/治疗接口与信号，显示血条与损耗动画。

signal health_changed(current: float, max_value: float, delta: float)
signal died()

@export var max_health: float = 100.0:
    set(v):
        max_health = max(v, 1.0)
        _current = clamp(_current, 0.0, max_health)
        _emit_changed(0.0)

@export var show_seconds: float = 10.0

@export_group("Bar")
@export var bar_size: Vector2 = Vector2(80, 6)
@export var bar_offset: Vector2 = Vector2(-40, 10)
@export var bar_position_offset: Vector2 = Vector2(0, -60)
@export var bg_color: Color = Color(0.4, 0, 0, 0.549)
@export var bar_color: Color = Color(0.2, 0.8, 0.2, 0.8)
@export var damage_color: Color = Color(0.9, 0.6, 0.1, 0.8)
@export var damage_lerp_speed: float = 2.0

var _current: float = 100.0
var _display_health: float = 100.0

@onready var _host: Node2D = get_parent() as Node2D


# ─── Computed ─────────────────────────────────────────────

var current_health: float:
    get: return _current

var ratio: float:
    get: return clampf(_current / max_health, 0.0, 1.0)


# ─── Lifecycle ────────────────────────────────────────────

func _ready() -> void:
    assert(_host != null, "HealthComponent requires a host(parent) Node2D.")
    _current = clamp(_current, 0.0, max_health)
    _display_health = _current
    top_level = true
    z_index = 100


func _process(delta: float) -> void:
    if is_instance_valid(_host):
        global_position = _host.global_position + bar_position_offset

    # 平滑动画：损耗缓慢下降，治疗立即跟上
    if _display_health > _current:
        _display_health = lerpf(_display_health, _current, delta * damage_lerp_speed)
        if absf(_display_health - _current) < 0.1:
            _display_health = _current
    else:
        _display_health = _current

    queue_redraw()


func _draw() -> void:
    _draw_bar()


# ─── Bar Drawing ──────────────────────────────────────────

## 根据当前血量比例动态计算血条颜色：满血绿色 → 半血黄色 → 空血红色
func _get_health_color() -> Color:
    var color_green := Color(0.2, 0.8, 0.2, 0.8)
    var color_yellow := Color(0.9, 0.8, 0.2, 0.8)
    var color_red := Color(0.9, 0.1, 0.1, 0.8)

    var r := ratio
    if r > 0.5:
        # 满血→半血：绿色渐变到黄色
        var t := (r - 0.5) / 0.5
        return color_yellow.lerp(color_green, t)
    else:
        # 半血→空血：黄色渐变到红色
        var t := r / 0.5
        return color_red.lerp(color_yellow, t)


func _draw_bar() -> void:
    # 1) 背景 — 空血底色
    draw_rect(Rect2(bar_offset, bar_size), bg_color)

    # 2) 损耗进度 — 橙黄色，从旧血量缓慢缩减到新血量
    var display_ratio: float = clampf(_display_health / max_health, 0.0, 1.0)
    var damage_width: float = bar_size.x * display_ratio
    if damage_width > 0.5:
        draw_rect(Rect2(bar_offset, Vector2(damage_width, bar_size.y)), damage_color)

    # 3) 当前血量 — 颜色随血量动态变化
    var health_width: float = bar_size.x * ratio
    var current_color: Color = _get_health_color()
    if health_width > 0.5:
        draw_rect(Rect2(bar_offset, Vector2(health_width, bar_size.y)), current_color)

    # 4) 边框
    draw_rect(Rect2(bar_offset, bar_size), Color(0, 0, 0, 0.6), false, 1.0)


# ─── Public API ───────────────────────────────────────────

func set_health(value: float) -> void:
    var new_value: float = clamp(value, 0.0, max_health)
    var delta_val: float = new_value - _current
    if is_zero_approx(delta_val):
        return

    _current = new_value
    _emit_changed(delta_val)

    if is_zero_approx(_current):
        _handle_death()


func damage(amount: float) -> void:
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


func _emit_changed(delta: float) -> void:
    health_changed.emit(_current, max_health, delta)