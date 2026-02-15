extends Node2D
class_name HealthComponent
## 血量组件：管理血量数值，提供伤害/治疗接口与信号，在对象正上方显示血量。

signal health_changed(current: float, max_value: float, delta: float)
signal died()

@export var max_health: float = 100.0:
    set(v):
        max_health = max(v, 1.0)
        _current = clamp(_current, 0.0, max_health)
        _emit_changed(0.0)

@export var show_seconds: float = 10.0
@export var bar_size: Vector2 = Vector2(200, 200)
@export var bar_offset: Vector2 = Vector2(-100, 0)
@export var bg_color: Color = Color(0.4, 0, 0, 0.549)

@export var text_offset: Vector2 = Vector2(0, -50)
@export var font_size: int = 16
@export var font_color: Color = Color.WHITE

var _current: float = 100.0

@onready var _host: Node2D = get_parent() as Node2D


# ─── Computed ─────────────────────────────────────────────

var current_health: float:
    get: return _current

var ratio: float:
    get: return clamp(_current / max_health, 0.0, 1.0)


# ─── Lifecycle ────────────────────────────────────────────

func _ready() -> void:
    assert(_host != null, "HealthComponent requires a host(parent) Node2D.")
    _current = clamp(_current, 0.0, max_health)
    top_level = true
    z_index = 100


func _process(_delta: float) -> void:
    if is_instance_valid(_host):
        global_position = _host.global_position + text_offset
    queue_redraw()


func _draw() -> void:
    var font := ThemeDB.fallback_font
    var text := "%d / %d" % [int(_current), int(max_health)]
    var string_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
    var pos := Vector2(-string_size.x / 2.0, string_size.y / 2.0)
    draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, font_color)


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