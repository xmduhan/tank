extends Node2D

func _ready():
    # 在屏幕中心生成一个敌人坦克
    # spawn_enemy_tank()
    
    # 示例：在指定位置 (100, 200) 生成另一个敌人坦克
    spawn_enemy_tank(Vector2(570, 180))
    
    # 在屏幕中心生成玩家坦克
    spawn_player_tank()

# 生成敌人坦克的函数
func spawn_enemy_tank(position: Vector2 = Vector2.ZERO):
    # 加载坦克场景
    var tank_scene = load("res://scenes/units/tank/enemy.tscn")
    # 实例化坦克
    var tank_instance = tank_scene.instantiate()
    # 将坦克添加到当前场景
    add_child(tank_instance)
    
    # 如果未指定位置，则设置为屏幕中心
    if position == Vector2.ZERO:
        position = get_viewport_rect().size / 2
    
    # 设置坦克位置
    tank_instance.position = position
    
    # 设置坦克旋转90度（如果需要）
    # tank_instance.rotation_degrees = 90
    
    # 打印坦克旋转角度（调试用）
    print(tank_instance.rotation_degrees)
    
    # 返回生成的坦克实例，以便进一步操作
    return tank_instance

# 生成玩家坦克的函数
func spawn_player_tank(position: Vector2 = Vector2.ZERO):
    # 加载玩家坦克场景
    var player_scene = load("res://scenes/units/tank/player.tscn")
    # 实例化玩家坦克
    var player_instance = player_scene.instantiate()
    # 将玩家坦克添加到当前场景
    add_child(player_instance)
    
    # 如果未指定位置，则设置为屏幕中心
    if position == Vector2.ZERO:
        position = get_viewport_rect().size / 2
    
    # 设置玩家坦克位置
    player_instance.position = position
    
    # 返回生成的玩家坦克实例，以便进一步操作
    return player_instance
