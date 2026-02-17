extends Node2D

@export var desired_enemy_count: int = 4
@export var total_enemy_count: int = 20


func _ready() -> void:
    randomize()

    var spawner := _setup_enemy_spawner()
    _spawn_player_tank(Vector2(200, 180))
    _wire_victory_and_defeat(spawner)


func _setup_enemy_spawner() -> EnemySpawner:
    var spawner := EnemySpawner.new()
    add_child(spawner)

    spawner.desired_enemy_count = desired_enemy_count
    spawner.total_enemies_to_spawn = total_enemy_count
    return spawner


func _spawn_player_tank(pos: Vector2) -> CharacterBody2D:
    var player := load("res://scenes/units/tank/player.tscn").instantiate() as CharacterBody2D
    add_child(player)
    player.position = pos
    return player


func _wire_victory_and_defeat(spawner: EnemySpawner) -> void:
    if is_instance_valid(spawner) and spawner.has_signal("victory"):
        spawner.victory.connect(_on_victory)

    var player := _find_player()
    if not is_instance_valid(player):
        return

    var health := player.get_node_or_null("health") as HealthComponent
    if health != null:
        health.died.connect(_on_defeat)


func _find_player() -> CharacterBody2D:
    var players := get_tree().get_nodes_in_group("player")
    for n in players:
        var p := n as CharacterBody2D
        if is_instance_valid(p):
            return p
    return null


func _end_game(message: String) -> void:
    get_tree().paused = true
    get_window().title = message


func _on_victory() -> void:
    _end_game("Victory: all enemies destroyed")


func _on_defeat() -> void:
    _end_game("Defeat: player destroyed")
