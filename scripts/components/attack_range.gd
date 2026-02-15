extends Area2D
class_name AttackRangeComponent
## 攻击范围组件：检测敌方单位，管理目标列表与瞄准，统一绘制视觉标记。

## 当瞄准目标发生变化时发出（new_target 为 null 表示无目标）。
signal target_changed(new_target: CharacterBody2D)

var _targets: Array[CharacterBody2D] = []
var current_target: CharacterBody2D = null
var _current_index: int = -1

## 范围内所有有效目标的有序列表（只读）。
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
	for t in _targets:
		if not is_instance_valid(t):
			continue
		var pos := to_local(t.global_position)
		if t == current_target:
			# 瞄准线
			draw_line(Vector2.ZERO, pos, Color.YELLOW, 2.0)
			# 十字准星
			var half := 10.0
			draw_line(pos + Vector2(-half, 0), pos + Vector2(half, 0), Color.YELLOW, 2.0)
			draw_line(pos + Vector2(0, -half), pos + Vector2(0, half), Color.YELLOW, 2.0)
			# 当前目标：黄色粗圈
			draw_arc(pos, 40, 0, TAU, 64, Color.YELLOW, 3.0)
		else:
			# 范围内非瞄准目标：红色圈
			draw_arc(pos, 40, 0, TAU, 64, Color.RED, 2.0)

# ─── 公共接口 ─────────────────────────────────────────────

## 切换到目标列表中的下一个单位（循环）。
func cycle_target() -> void:
	if _targets.is_empty():
		return
	_current_index = (_current_index + 1) % _targets.size()
	_select_target(_targets[_current_index])

# ─── 信号回调 ─────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if body == get_parent() or body is not CharacterBody2D:
		return
	var unit := body as CharacterBody2D
	if _is_same_team(unit):
		return
	if unit in _targets:
		return
	_targets.append(unit)
	# 自动选中第一个进入范围的目标
	if current_target == null:
		_current_index = 0
		_select_target(unit)


func _on_body_exited(body: Node2D) -> void:
	if body is not CharacterBody2D:
		return
	_unregister(body as CharacterBody2D)

# ─── 阵营判断（私有） ────────────────────────────────────

func _is_same_team(body: CharacterBody2D) -> bool:
	var owner_node := get_parent()
	for group in owner_node.get_groups():
		if body.is_in_group(group):
			return true
	return false

# ─── 目标管理（私有） ────────────────────────────────────

func _select_target(target: CharacterBody2D) -> void:
	if current_target == target:
		return
	current_target = target
	target_changed.emit(current_target)


func _clear_target() -> void:
	current_target = null
	_current_index = -1
	target_changed.emit(null)


func _unregister(body: CharacterBody2D) -> void:
	var idx := _targets.find(body)
	if idx == -1:
		return
	var was_current := (body == current_target)
	_targets.remove_at(idx)
	if was_current:
		_auto_select_nearest(idx)
	elif _current_index > idx:
		_current_index -= 1


func _purge_invalid() -> void:
	var lost_current := false
	for i in range(_targets.size() - 1, -1, -1):
		if not is_instance_valid(_targets[i]):
			if _targets[i] == current_target:
				lost_current = true
			_targets.remove_at(i)
	if lost_current:
		_auto_select_nearest(_current_index)
	elif current_target != null:
		_current_index = _targets.find(current_target)


func _auto_select_nearest(hint_idx: int) -> void:
	if _targets.is_empty():
		_clear_target()
	else:
		_current_index = clampi(hint_idx, 0, _targets.size() - 1)
		current_target = null
		_select_target(_targets[_current_index])
