# res://scripts/Main.gd
extends Node2D

# 主游戏脚本，负责游戏流程控制。
# 挂在 main/Main.tscn 的根节点 Node2D 上。

@onready var artillery = $Artillery
@onready var game_ui = $GameUI
@onready var tank_spawn_timer = $TankSpawnTimer
@onready var tanks_root = $TanksRoot # 所有坦克的父节点，便于管理

var tank_scene = preload("res://actors/Tank.tscn")
var active_tanks = {}  # 字典：answer -> tank instance

func _ready():
	# 连接UI和定时器信号
	game_ui.answer_submitted.connect(_on_answer_submitted)
	tank_spawn_timer.timeout.connect(_spawn_tank)

# 生成一辆新的坦克
func _spawn_tank():
	var tank = tank_scene.instantiate()
	tanks_root.add_child(tank) # 添加到专门的父节点下
	
	# 生成加法算式 (0-20)
	var num1 = randi() % 21
	var num2 = randi() % 21
	var answer = num1 + num2
	
	# 设置坦克的算式和答案，并放置在屏幕顶部随机位置
	var random_x = randf_range(100, 1100)  # 屏幕宽度约1200，留出边界
	tank.global_position = Vector2(random_x, -50)  # 从屏幕顶部上方开始
	
	# 设置坦克的旋转，使其朝下（默认坦克图片朝右，旋转90度使其朝下）
	tank.rotation_degrees = 90
	
	tank.setup(num1, num2, answer)
	
	# 保存到活跃坦克字典
	active_tanks[answer] = tank
	
	# 创建移动动画：从上向下移动
	var tween = create_tween()
	var move_distance = 800  # 从y=-50移动到y=750（屏幕底部下方）
	var move_duration = move_distance / 60.0 # 假设速度为60像素/秒
	tween.tween_property(tank, "position:y", 750, move_duration)
	tween.tween_callback(_on_tank_escape.bind(tank, answer))

# 当玩家提交答案时调用
func _on_answer_submitted(answer: int):
	if active_tanks.has(answer):
		var target_tank = active_tanks[answer]
		# 命令炮台向该坦克开火
		artillery.shoot_at(target_tank.global_position)
		# 加分
		game_ui.update_score(10)
		# 从字典中移除，防止重复击中
		active_tanks.erase(answer)
		
	else:
		# 答案错误，暂时不做处理（可扩展为扣分或提示）
		print("答案错误或坦克不存在。")

# 当坦克移动到屏幕外时调用
func _on_tank_escape(tank, answer):
	# 安全地移除坦克实例和字典记录
	if tank and is_instance_valid(tank):
		tank.queue_free()
	if active_tanks.has(answer):
		active_tanks.erase(answer)
		# 可选：坦克逃脱，扣分
		# game_ui.update_score(-5)