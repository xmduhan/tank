extends Node2D

const ENEMY_SPAWNER_SCENE := preload("res://scripts/enemy_spawner.gd")

@export var enemy_spawn_rect: Rect2 = Rect2(Vector2(520, 120), Vector2(240, 380))
@export var desired_enemy_count: int = 4


func _ready() -> void:
    randomize()

    _setup_enemy_spawner()
    _spawn_player_tank(Vector2(200, 180))


func _setup_enemy_spawner() -> void:
    var spawner := EnemySpawner.new()
    add_child(spawner)

    spawner.desired_enemy_count = desired_enemy_count
    spawner.spawn_rect = enemy_spawn_rect


func _spawn_player_tank(pos: Vector2) -> Node2D:
    var player := load("res://scenes/units/tank/player.tscn").instantiate() as Node2D
    add_child(player)
    player.position = pos
    return player
