extends Area2D
class_name AttackRangeComponent
## 攻击范围组件：检测进入范围的敌方单位，维护目标列表，管理当前瞄准目标及视觉标记。

## 当瞄准目标发生变化时发出（new_target 为 null 表示无目标）。
signal target_changed(new_target: CharacterBody2D)

## 单一数据源：目标单位 → 红圈标记。
var _entries: Dictionary = {}          # { CharacterBody2D : RedCircleMarker }
## 当前瞄准的目标，可为 null。
var current_target: CharacterBody2D = null
var _current_index: int = -1

## 范围内所有有效目标的有序列表（只读，由 _entries 派生）。
var targets: Array:
	get: return _entries.keys()

# ─── 生命周期 ─────────────────────────────────────────────

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	_purge_invalid()
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(current_target):
		return
	var pos := to_local(current_target.global_position)
	# 瞄准线
	draw_line(Vector2.ZERO, pos, Color.YELLOW, 2.0)
	# 十字准星
	var half := 10.0
	draw_line(pos + Vector2(-half, 0), pos + Vector2(half, 0), Color.YELLOW, 2.0)
	draw_line(pos + Vector2(0, -half), pos + Vector2(0, half), Color.YELLOW, 2.0)

# ─── 公共接口 ─────────────────────────────────────────────

## 切换到目标列表中的下一个单位（循环）。
func cycle_target() -> void:
	var keys := _entries.keys()
	if keys.is_empty():
		return
	_current_index = (_current_index + 1) % keys.size()
	_select_target(keys[_current_index])

# ─── 信号回调 ─────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if body == get_parent() or body is not CharacterBody2D:
		return
	var unit := body as CharacterBody2D
	# 同阵营单位不作为目标
	if _is_same_team(unit):
		return
	if _entries.has(unit):
		return
	# 一次性完成注册：创建标记 + 记录到字典
	var marker := RedCircleMarker.new()
	unit.add_child(marker)
	_entries[unit] = marker
	# 自动选中第一个进入范围的目标
	if current_target == null:
		_current_index = 0
		_select_target(unit)


func _on_body_exited(body: Node2D) -> void:
	if body is not CharacterBody2D:
		return
	_unregister(body as CharacterBody2D)

# ─── 阵营判断（私有） ────────────────────────────────────

## 判断目标是否与自身属于同一阵营（共享任意用户分组即视为同队）。
func _is_same_team(body: CharacterBody2D) -> bool:
	var owner_node := get_parent()
	for group in owner_node.get_groups():
		if body.is_in_group(group):
			return true
	return false

# ─── 目标管理（私有） ────────────────────────────────────

## 选中指定目标并更新高亮。
func _select_target(target: CharacterBody2D) -> void:
	if current_target == target:
		return
	_set_highlight(current_target, false)
	current_target = target
	_set_highlight(current_target, true)
	target_changed.emit(current_target)


## 清除当前目标。
func _clear_target() -> void:
	_set_highlight(current_target, false)
	current_target = null
	_current_index = -1
	target_changed.emit(null)


## 将指定单位从字典中完全移除（含标记清理），并自动切换瞄准。
func _unregister(body: CharacterBody2D) -> void:
	if not _entries.has(body):
		return
	var keys := _entries.keys()
	var idx := keys.find(body)
	var was_current := (body == current_target)
	# 移除标记 + 字典条目（单点操作）
	var marker: Node2D = _entries[body]
	if is_instance_valid(marker):
		marker.queue_free()
	_entries.erase(body)
	# 修正选中状态
	if was_current:
		_auto_select_nearest(idx)
	elif _current_index > idx:
		_current_index -= 1


## 反向遍历清理已被销毁的目标引用（防御性维护）。
func _purge_invalid() -> void:
	var lost_current := false
	for body in _entries.keys():          # keys() 快照，遍历期间可安全 erase
		if not is_instance_valid(body):
			_entries.erase(body)
			if body == current_target:
				lost_current = true
	if lost_current:
		_auto_select_nearest(_current_index)
	elif current_target != null:
		# 条目可能因清除前序元素而偏移，重新校准索引
		_current_index = _entries.keys().find(current_target)


## 目标被移除后，根据 hint_idx 自动选中最近位置的目标，或清空瞄准。
func _auto_select_nearest(hint_idx: int) -> void:
	var keys := _entries.keys()
	if keys.is_empty():
		_clear_target()
	else:
		_current_index = clampi(hint_idx, 0, keys.size() - 1)
		current_target = null          # 避免 _select_target 因相同引用而短路
		_select_target(keys[_current_index])

# ─── 标记高亮（私有） ────────────────────────────────────

## 设置指定单位标记的高亮状态。
func _set_highlight(body: CharacterBody2D, value: bool) -> void:
	if body == null or not _entries.has(body):
		return
	var marker: RedCircleMarker = _entries[body]
	if not is_instance_valid(marker):
		return
	marker.highlighted = value
	marker.queue_redraw()