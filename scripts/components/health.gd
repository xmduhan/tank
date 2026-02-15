extends Node
class_name HealthComponent
## 血量组件：管理血量数值，提供伤害/治疗接口与信号。

signal health_changed(current: float, max_value: float, delta: float)
signal died()

@export var max_health: float = 100.0:
    set(v):
        max_health = max(v, 1.0)
        _current = clamp(_current, 0.0, max_health)
        _emit_changed(0.0)

var _current: float = 100.0

@onready var _host: Node = get_parent()


# ─── Computed ─────────────────────────────────────────────

var current_health: float:
    get: return _current

var ratio: float:
    get: return clamp(_current / max_health, 0.0, 1.0)


# ─── Lifecycle ────────────────────────────────────────────

func _ready() -> void:
    assert(_host != null, "HealthComponent requires a host(parent) node.")
    _current = clamp(_current, 0.0, max_health)


# ─── Public API ───────────────────────────────────────────

func set_health(value: float) -> void:
    var new_value: float = clamp(value, 0.0, max_health)
    var delta: float = new_value - _current
    if is_zero_approx(delta):
        return

    _current = new_value
    _emit_changed(delta)

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