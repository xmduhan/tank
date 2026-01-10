extends Node2D

func _ready():
    # 加载坦克场景
    var tank_scene = load("res://scenes/tank/tank.tscn")
    # 实例化坦克
    var tank_instance = tank_scene.instantiate()
    # 将坦克添加到当前场景
    add_child(tank_instance)
    # 设置坦克位置为屏幕中心
    tank_instance.position = get_viewport_rect().size / 2
    # tank_instance.position = Vector2(0, 0)
