extends Node
class_name EnemySpawner

@export var enemy_scene: PackedScene = preload("res://scenes/units/tank/enemy.tscn")
@export var desired_enemy_count: int = 4

@export_group("Spawn Area")
@export var spawn_rect: Rect2 = Rect2(Vector2(520, 120), Vector2(220, 360))
@export var spawn_margin: float = 24.0


func _ready() -> void:
    assert(enemy_scene != null, "EnemySpawner: enemy_scene is null.")
    call_deferred("_ensure_enemy_count")


func _ensure_enemy_count() -> void:
    if not is_inside_tree():
        return

    var world: Node = get_tree().current_scene
    if world == null:
        world = get_parent()
    if world == null:
        return

    var enemies := _get_enemies(world)
    var missing:int = max(desired_enemy_count - enemies.size(), 0)
    for _i in range(missing):
        _spawn_one(world)


func _get_enemies(root: Node) -> Array[Node2D]:
    var out: Array[Node2D] = []
    for n in root.get_children():
        if n is Node2D and (n as Node2D).is_in_group("enemy"):
            out.append(n as Node2D)
    return out


func _spawn_one(world: Node) -> void:
    if enemy_scene == null:
        return

    var enemy := enemy_scene.instantiate() as Node2D
    if enemy == null:
        return

    world.add_child(enemy)
    enemy.global_position = _random_spawn_position()

    enemy.tree_exited.connect(_on_enemy_exited)


func _on_enemy_exited() -> void:
    call_deferred("_ensure_enemy_count")


func _random_spawn_position() -> Vector2:
    var rect := spawn_rect

    var m := maxf(spawn_margin, 0.0)
    rect.position += Vector2(m, m)
    rect.size -= Vector2(m * 2.0, m * 2.0)

    if rect.size.x <= 1.0 or rect.size.y <= 1.0:
        rect = Rect2(spawn_rect.position, Vector2(maxf(spawn_rect.size.x, 2.0), maxf(spawn_rect.size.y, 2.0)))

    var x := randf_range(rect.position.x, rect.position.x + rect.size.x)
    var y := randf_range(rect.position.y, rect.position.y + rect.size.y)
    return Vector2(x, y)
