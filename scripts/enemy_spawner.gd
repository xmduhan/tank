extends Node
class_name EnemySpawner

@export var enemy_scene: PackedScene = preload("res://scenes/units/tank/enemy.tscn")
@export var desired_enemy_count: int = 4

@export_group("Spawn Area")
@export var spawn_rect: Rect2 = Rect2(Vector2(520, 120), Vector2(220, 360))
@export var spawn_margin: float = 24.0
@export var corner_inset: float = 36.0


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
    var missing: int = max(desired_enemy_count - enemies.size(), 0)
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
    enemy.global_position = _corner_spawn_position()

    enemy.tree_exited.connect(_on_enemy_exited)


func _on_enemy_exited() -> void:
    call_deferred("_ensure_enemy_count")


func _corner_spawn_position() -> Vector2:
    var rect := _safe_rect(spawn_rect, spawn_margin)
    var inset := maxf(corner_inset, 0.0)

    var corners := [
        rect.position,
        Vector2(rect.end.x, rect.position.y),
        Vector2(rect.position.x, rect.end.y),
        rect.end,
    ]

    var idx := randi() % 4
    var c: Vector2 = corners[idx]

    var sx := 1.0 if (c.x <= rect.position.x + 0.001) else -1.0
    var sy := 1.0 if (c.y <= rect.position.y + 0.001) else -1.0

    var p := c + Vector2(inset * sx, inset * sy)
    return WorldBounds.clamp_point_to_rect(p, rect)


func _safe_rect(r: Rect2, margin: float) -> Rect2:
    var rect := r
    var m := maxf(margin, 0.0)
    rect.position += Vector2(m, m)
    rect.size -= Vector2(m * 2.0, m * 2.0)

    if rect.size.x <= 1.0 or rect.size.y <= 1.0:
        rect = Rect2(r.position, Vector2(maxf(r.size.x, 2.0), maxf(r.size.y, 2.0)))

    return rect


const WorldBounds := preload("res://scripts/utils/world_bounds.gd")