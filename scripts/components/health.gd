extends Node
class_name HealthComponent
## 血量组件：管理血量，并在宿主头顶显示血条（默认隐藏，血量变化后显示3秒）。

signal health_changed(current: float, max_value: float, delta: float)
signal died()

@export var max_health: float = 100.0:
	set(v):
		max_health = max(v, 1.0)
		_current = clamp(_current, 0.0, max_health)
		_emit_changed(0.0)
		_update_bar()

@export var show_seconds: float = 3.0

# 血条外观参数（可按需在 Inspector 调）
@export var bar_size := Vector2(90, 10)
@export var bar_offset := Vector2(0, -70) # 相对宿主的偏移（头顶）
@export var bg_color := Color(0, 0, 0, 0.55)
@export var fg_color := Color(0.25, 0.95, 0.25, 0.9)
@export var border_color := Color(1, 1, 1, 0.35)
@export var border_width: float = 1.0

var _current: float = 100.0

var current_health: float:
	get: return _current

var ratio: float:
	get: return clamp(_current / max_health, 0.0, 1.0)

var _bar: _HealthBar = null
var _hide_timer: Timer = null


func _ready() -> void:
	_current = clamp(_current, 0.0, max_health)
	_create_bar()
	_create_timer()
	_update_bar()
	_hide_bar_immediate()


# ─── Public API ───────────────────────────────────────────

func set_health(value: float) -> void:
	var new_value := clamp(value, 0.0, max_health)
	var d := new_value - _current
	if is_zero_approx(d):
		return
	_current = new_value
	_emit_changed(d)
	_on_value_changed()
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
	# 这里不直接 queue_free()，由外部决定死亡处理（播放特效/掉落等）
	# 如果希望自动销毁可取消注释：
	# get_parent().queue_free()

func _emit_changed(delta: float) -> void:
	health_changed.emit(_current, max_health, delta)

func _on_value_changed() -> void:
	_show_bar_for_seconds()
	_update_bar()

func _create_bar() -> void:
	var host := get_parent()
	assert(host != null)

	_bar = _HealthBar.new()
	_bar.name = "health_bar"
	_bar.size = bar_size
	_bar.position = bar_offset - bar_size * 0.5
	_bar.z_index = 1000
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.set_colors(bg_color, fg_color, border_color, border_width)
	_bar.set_ratio(ratio)

	# 将 Control 作为 CharacterBody2D 的子节点：会随宿主一起移动/旋转。
	# 如不想随旋转，可把它放到独立 CanvasLayer，这里先保持简单实现。
	host.add_child(_bar)

func _create_timer() -> void:
	_hide_timer = Timer.new()
	_hide_timer.name = "health_bar_hide_timer"
	_hide_timer.one_shot = true
	_hide_timer.wait_time = show_seconds
	_hide_timer.timeout.connect(_on_hide_timeout)
	add_child(_hide_timer)

func _show_bar_for_seconds() -> void:
	if not is_instance_valid(_bar):
		return
	_bar.visible = true
	if is_instance_valid(_hide_timer):
		_hide_timer.start(show_seconds)

func _hide_bar_immediate() -> void:
	if is_instance_valid(_bar):
		_bar.visible = false

func _on_hide_timeout() -> void:
	_hide_bar_immediate()

func _update_bar() -> void:
	if is_instance_valid(_bar):
		_bar.set_ratio(ratio)


# ─── Internal Control for drawing ─────────────────────────
class _HealthBar extends Control:
	var _ratio: float = 1.0
	var _bg: Color
	var _fg: Color
	var _border: Color
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
		var r := Rect2(Vector2.ZERO, size)

		# background
		draw_rect(r, _bg, true)

		# fill
		var fill := Rect2(Vector2.ZERO, Vector2(size.x * _ratio, size.y))
		draw_rect(fill, _fg, true)

		# border
		if _border_w > 0.0:
			draw_rect(r, _border, false, _border_w)