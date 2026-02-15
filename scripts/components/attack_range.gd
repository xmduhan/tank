extends Area2D

var markers := {}
var targets: Array[CharacterBody2D] = []
var current_target_index := -1
var current_target: CharacterBody2D = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	# 持续重绘瞄准线（因为目标在移动）
	queue_redraw()

func _draw():
	if current_target and is_instance_valid(current_target):
		var target_local_pos = to_local(current_target.global_position)
		# 画瞄准线：黄色，从自身原点（即父坦克位置）到目标
		draw_line(Vector2.ZERO, target_local_pos, Color.YELLOW, 2.0)
		# 在瞄准线终点画一个小十字准星
		var cross_size := 10.0
		draw_line(target_local_pos + Vector2(-cross_size, 0), target_local_pos + Vector2(cross_size, 0), Color.YELLOW, 2.0)
		draw_line(target_local_pos + Vector2(0, -cross_size), target_local_pos + Vector2(0, cross_size), Color.YELLOW, 2.0)

func _on_body_entered(body: Node2D):
	if body == get_parent():
		return
	if body is CharacterBody2D and not markers.has(body):
		var marker := RedCircleMarker.new()
		body.add_child(marker)
		markers[body] = marker
		targets.append(body)
		# 自动选中第一个进入范围的目标
		if current_target == null:
			_set_current_target(0)

func _on_body_exited(body: Node2D):
	if markers.has(body):
		var marker = markers[body]
		if is_instance_valid(marker):
			marker.queue_free()
		markers.erase(body)
		var idx = targets.find(body)
		if idx != -1:
			targets.remove_at(idx)
			if body == current_target:
				# 当前目标离开，自动切换
				if targets.size() > 0:
					_set_current_target(0)
				else:
					current_target_index = -1
					current_target = null
			elif current_target_index > idx:
				current_target_index -= 1

func cycle_target():
	if targets.size() == 0:
		return
	var next_index = (current_target_index + 1) % targets.size()
	_set_current_target(next_index)

func _set_current_target(index: int):
	# 取消旧目标高亮
	if current_target and markers.has(current_target):
		var old_marker = markers[current_target]
		if is_instance_valid(old_marker):
			old_marker.highlighted = false
			old_marker.queue_redraw()
	# 设置新目标
	current_target_index = index
	current_target = targets[index]
	# 新目标高亮
	if markers.has(current_target):
		var new_marker = markers[current_target]
		if is_instance_valid(new_marker):
			new_marker.highlighted = true
			new_marker.queue_redraw()
