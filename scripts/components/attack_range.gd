extends Area2D
class_name AttackRangeComponent
## 攻击范围组件：检测进入范围的敌方单位，维护目标列表，管理当前瞄准目标及视觉标记。

## 当瞄准目标发生变化时发出（new_target 为 null 表示无目标）。
signal target_changed(new_target: CharacterBody2D)

## 范围内所有有效目标的有序列表。
var targets: Array[CharacterBody2D] = []
## 当前瞄准的目标，可为 null。
var current_target: CharacterBody2D = null

var _markers: Dictionary = {}          # { CharacterBody2D : RedCircleMarker }
var _current_index: int = -1

# ─── 生命周期 ─────────────────────────────────────────────

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	_purge_invalid_targets()
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
	if targets.is_empty():
		return
	_current_index = (_current_index + 1) % targets.size()
	_select_target(targets[_current_index])

# ─── 信号回调 ─────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if body == get_parent() or body is not CharacterBody2D:
		return
	var unit := body as CharacterBody2D
	if unit in targets:
		return
	targets.append(unit)
	_attach_marker(unit)
	# 自动选中第一个进入范围的目标
	if current_target == null:
		_current_index = 0
		_select_target(unit)


func _on_body_exited(body: Node2D) -> void:
	if body is not CharacterBody2D:
		return
	_unregister(body as CharacterBody2D)

# ─── 目标管理（私有） ────────────────────────────────────

## 选中指定目标并更新高亮。
func _select_target(target: CharacterBody2D) -> void:
	if current_target == target:
		return
	_set_marker_highlight(current_target, false)
	current_target = target
	_set_marker_highlight(current_target, true)
	target_changed.emit(current_target)


## 清除当前目标。
func _clear_target() -> void:
	_set_marker_highlight(current_target, false)
	current_target = null
	_current_index = -1
	target_changed.emit(null)


## 将指定单位从目标列表中完全移除，并自动切换瞄准。
func _unregister(body: CharacterBody2D) -> void:
	_detach_marker(body)
	var idx := targets.find(body)
	if idx == -1:
		return
	var was_current := (body == current_target)
	targets.remove_at(idx)
	if was_current:
		_auto_select_nearest(idx)
	elif _current_index > idx:
		_current_index -= 1


## 反向遍历清理已被销毁的目标引用（防御性维护）。
func _purge_invalid_targets() -> void:
	var lost_current := false
	for i in range(targets.size() - 1, -1, -1):
		if not is_instance_valid(targets[i]):
			_markers.erase(targets[i])
			if targets[i] == current_target:
				lost_current = true
			targets.remove_at(i)
	if lost_current:
		_auto_select_nearest(_current_index)


## 目标被移除后，根据 hint_idx 自动选中最近位置的目标，或清空瞄准。
func _auto_select_nearest(hint_idx: int) -> void:
	if targets.is_empty():
		_clear_target()
	else:
		_current_index = clampi(hint_idx, 0, targets.size() - 1)
		current_target = null          # 避免 _select_target 因相同引用而短路
		_select_target(targets[_current_index])

# ─── 标记管理（私有） ────────────────────────────────────

## 为指定单位添加红圈标记。
func _attach_marker(body: CharacterBody2D) -> void:
	if _markers.has(body):
		return
	var marker := RedCircleMarker.new()
	body.add_child(marker)
	_markers[body] = marker


## 移除指定单位的红圈标记。
func _detach_marker(body: CharacterBody2D) -> void:
	if not _markers.has(body):
		return
	var marker: Node2D = _markers[body]
	if is_instance_valid(marker):
		marker.queue_free()
	_markers.erase(body)


## 设置指定单位标记的高亮状态。
func _set_marker_highlight(body: CharacterBody2D, value: bool) -> void:
	if body == null or not _markers.has(body):
		return
	var marker: RedCircleMarker = _markers[body]
	if not is_instance_valid(marker):
		return
	marker.highlighted = value
	marker.queue_redraw()