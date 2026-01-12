extends Node2D

func _ready():
    spawn_enemy_tank(Vector2(570, 180))
    spawn_player_tank(Vector2(200, 180))

func spawn_enemy_tank(_position: Vector2):
    var tank = load("res://scenes/units/tank/enemy.tscn").instantiate()
    add_child(tank)
    tank.position = _position
    print(tank.rotation_degrees)
    return tank

func spawn_player_tank(_position: Vector2):
    var player = load("res://scenes/units/tank/player.tscn").instantiate()
    add_child(player)
    player.position = _position
    # player.rotation_degrees = 90  # 旋转90度
    return player
