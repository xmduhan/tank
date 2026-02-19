extends Node
class_name EnemySpawner

signal victory

@export var enemy_scene: PackedScene = preload("res://scenes/units/tank/enemy.tscn")

@export_group("Counts")
@export var desired_enemy_count: int = 64
@export var total_enemies_to_spawn: int = 9999

@export_group("Respawn")
@export var respawn_delay_seconds: float = 1.0

@export_group("Spawn Area (legacy)")
@export var spawn_rect: Rect2 = Rect2(Vector2(520, 120), Vector2(220, 360))
@export var spawn_margin: float = 24.0
@export var corner_inset: float = 36.0

var _remaining_to_spawn: int = 0
var _respawn_timer: SceneTreeTimer = null
var _bootstrapped: bool = false


func _ready() -> void:
    assert(enemy_scene != null, "EnemySpawner: enemy_scene is null.")
    call_deferred("_bootstrap")


func apply_counts_runtime(desired: int, total: int) -> void:
    desired_enemy_count = clampi(int(desired), 0, 1024)
    total_enemies_to_spawn = maxi(int(total), 0)

    if not _bootstrapped:
        return

    _reconcile_remaining_to_spawn()
    _ensure_enemy_count()


func _bootstrap() -> void:
    if not is_inside_tree():
        return

    _bootstrapped = true
    _remaining_to_spawn = max(total_enemies_to_spawn, 0)

    var world: Node = _world()
    if world == null:
        return

    for e: Node2D in _get_enemies(world):
        _wire_enemy(e)

    _ensure_enemy_count()


func _reconcile_remaining_to_spawn() -> void:
    var already_spawned: int = _compute_spawned_so_far()
    _remaining_to_spawn = max(total_enemies_to_spawn - already_spawned, 0)


func _compute_spawned_so_far() -> int:
    var alive: int = _alive_enemies()
    var spawned_so_far: int = total_enemies_to_spawn - _remaining_to_spawn
    spawned_so_far = maxi(spawned_so_far, alive)
    spawned_so_far = maxi(spawned_so_far, 0)
    return spawned_so_far


func _world() -> Node:
    if not is_inside_tree():
        return null

    var tree: SceneTree = get_tree()
    if tree == null:
        return null

    var world: Node = tree.current_scene
    return world if world != null else get_parent()


func _get_enemies(root: Node) -> Array[Node2D]:
    var out: Array[Node2D] = []
    for n: Node in root.get_children():
        var e: Node2D = n as Node2D
        if e != null and e.is_in_group(&"enemy"):
            out.append(e)
    return out


func _alive_enemies() -> int:
    var world: Node = _world()
    return 0 if world == null else _get_enemies(world).size()


func _ensure_enemy_count() -> void:
    if _check_victory_if_done():
        return

    var alive: int = _alive_enemies()
    var desired: int = clampi(desired_enemy_count, 0, 1024)
    var missing_on_field: int = max(desired - alive, 0)
    var to_spawn_now: int = min(missing_on_field, _remaining_to_spawn)

    if to_spawn_now <= 0:
        return

    for _i: int in range(to_spawn_now):
        _remaining_to_spawn -= 1
        _schedule_next_respawn()

    _check_victory_if_done()


func _schedule_next_respawn() -> void:
    if _respawn_timer != null:
        return

    var delay: float = maxf(respawn_delay_seconds, 0.0)
    _respawn_timer = get_tree().create_timer(delay)
    _respawn_timer.timeout.connect(_on_respawn_timeout)


func _on_respawn_timeout() -> void:
    _respawn_timer = null

    if _check_victory_if_done():
        return

    var world: Node = _world()
    if world == null:
        return

    if _alive_enemies() >= desired_enemy_count:
        return

    _spawn_one(world)

    if _remaining_to_spawn > 0 and _alive_enemies() < desired_enemy_count:
        _schedule_next_respawn()


func _spawn_one(world: Node) -> void:
    var enemy: Node2D = enemy_scene.instantiate() as Node2D
    if enemy == null:
        return

    world.add_child(enemy)
    enemy.global_position = _screen_corner_spawn_position(enemy)
    _wire_enemy(enemy)


func _wire_enemy(enemy: Node2D) -> void:
    if enemy == null:
        return
    if not enemy.tree_exited.is_connected(_on_enemy_exited):
        enemy.tree_exited.connect(_on_enemy_exited)


func _on_enemy_exited() -> void:
    if not is_inside_tree():
        return
    _ensure_enemy_count()


func _check_victory_if_done() -> bool:
    if _remaining_to_spawn > 0:
        return false

    if _alive_enemies() > 0:
        return false

    victory.emit()
    return true


func _screen_corner_spawn_position(enemy: Node2D) -> Vector2:
    var vp: Viewport = get_viewport()
    if vp == null:
        return Vector2.ZERO

    var visible: Rect2 = WorldBounds.get_visible_world_rect(vp)
    if visible.size.length() <= 1.0:
        return Vector2.ZERO

    var r: float = _estimate_radius(enemy)
    var inset: float = maxf(corner_inset, 0.0) + maxf(spawn_margin, 0.0) + r
    var rect: Rect2 = WorldBounds.inset_rect(visible, Vector2(inset, inset))

    var corners: Array[Vector2] = [
        rect.position,
        Vector2(rect.end.x, rect.position.y),
        Vector2(rect.position.x, rect.end.y),
        rect.end,
    ]

    return corners[randi() % corners.size()]


func _estimate_radius(body: Node2D) -> float:
    if body == null:
        return 34.0

    var shape_node: CollisionShape2D = body.get_node_or_null("shape") as CollisionShape2D
    if shape_node == null or shape_node.shape == null:
        return 34.0

    var s: Shape2D = shape_node.shape
    if s is CircleShape2D:
        return (s as CircleShape2D).radius
    if s is RectangleShape2D:
        var ext: Vector2 = (s as RectangleShape2D).size * 0.5
        return maxf(ext.x, ext.y)

    return 34.0
