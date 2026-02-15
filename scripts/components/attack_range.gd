extends Area2D
class_name AttackRangeComponent
## 攻击范围组件：检测敌方单位，管理目标列表与瞄准，统一绘制视觉标记。

## 当瞄准目标发生变化时发出（new_target 为 null 表示无目标）。
signal target_changed(new_target: CharacterBody2D)

var _targets: Array[CharacterBody2D] = []
var _current_target: CharacterBody2D = null

## 当前瞄准目标（只读；失效时自动返回 null）。
var current_target: CharacterBody2D:
	get: return _current_target if is_instance_valid(_current_target) else null

## 范围内所有有效目标（只读）。
var targets: Array[CharacterBody2D]:
	get: return _targets

# ─── 生命周期 ─────────────────────────────────────────────

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	_purge_invalid()
	queue_redraw()


func _draw() -> void:
	var aimed := current_target
	for t in _targets:
		var pos := to_local(t.global_position)
		if t == aimed:
			_draw_crosshair(pos)
		else:
			draw_arc(pos, 40, 0, TAU, 64, Color.RED, 2.0)

# ─── 公共接口 ─────────────────────────────────────────────

## 切换到目标列表中的下一个单位（循环）。
## find 未命中返回 -1，(−1+1)%size = 0，自然回退到首个目标。
func cycle_target() -> void:
	if _targets.is_empty():
		return
	var idx := (_targets.find(_current_target) + 1) % _targets.size()
	_set_target(_targets[idx])

# ─── 信号回调 ─────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	var unit := _as_enemy(body)
	if unit == null or unit in _targets:
		return
	_targets.append(unit)
	if current_target == null:
		_set_target(unit)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_remove_target(body as CharacterBody2D)

# ─── 内部逻辑 ─────────────────────────────────────────────

## 校验 body：非自身、是 CharacterBody2D、非友方时返回该单位，否则 null。
func _as_enemy(body: Node2D) -> CharacterBody2D:
	if body == get_parent() or body is not CharacterBody2D:
		return null
	var unit := body as CharacterBody2D
	if get_parent().get_groups().any(func(g): return unit.is_in_group(g)):
		return null
	return unit


func _set_target(target: CharacterBody2D) -> void:
	if _current_target == target:
		return
	_current_target = target
	target_changed.emit(target)


func _remove_target(body: CharacterBody2D) -> void:
	if body not in _targets:
		return
	var was_aimed := body == _current_target
	_targets.erase(body)
	if was_aimed:
		_set_target(_nearest_target())


func _purge_invalid() -> void:
	var had_target := _current_target != null
	_targets.assign(_targets.filter(func(t): return is_instance_valid(t)))
	if had_target and not is_instance_valid(_current_target):
		_current_target = null
		_set_target(_nearest_target())


func _nearest_target() -> CharacterBody2D:
	if _targets.is_empty():
		return null
	var origin := global_position
	return _targets.reduce(func(a, b):
		return a if origin.distance_squared_to(a.global_position) <= origin.distance_squared_to(b.global_position) else b
	)


func _draw_crosshair(pos: Vector2) -> void:
	draw_line(Vector2.ZERO, pos, Color.YELLOW, 2.0)
	var h := 10.0
	draw_line(pos + Vector2(-h, 0), pos + Vector2(h, 0), Color.YELLOW, 2.0)
	draw_line(pos + Vector2(0, -h), pos + Vector2(0, h), Color.YELLOW, 2.0)
	draw_arc(pos, 40, 0, TAU, 64, Color.YELLOW, 3.0)