extends Node
class_name EnemySpawner

const WorldBounds := preload("res://scripts/utils/world_bounds.gd")

@export var enemy_scene: PackedScene = preload("res://scenes/units/tank/enemy.tscn")
@export var desired_enemy_count: int = 4

@export_group("Respawn")
@export var respawn_delay_seconds: float = 15.0

@export_group("Spawn Area (legacy)")
@export var spawn_rect: Rect2 = Rect2(Vector2(520, 120), Vector2(220, 360))
@export var spawn_margin: float = 24.0
@export var corner_inset: float = 36.0

var _pending_respawns: int = 0
var _respawn_timer: SceneTreeTimer = null


func _ready() -> void:
    assert(enemy_scene != null, "EnemySpawner: enemy_scene is null.")
    call_deferred("_bootstrap")


func _bootstrap() -> void:
    if not is_inside_tree():
        return

    var world := _world()
    if world == null:
        return

    for e in _get_enemies(world):
        _wire_enemy(e)

    _ensure_enemy_count()


func _world() -> Node:
    var world: Node = get_tree().current_scene
    return world if world != null else get_parent()


func _get_enemies(root: Node) -> Array[Node2D]:
    var out: Array[Node2D] = []
    for n in root.get_children():
        var e := n as Node2D
        if e != null and e.is_in_group("enemy"):
            out.append(e)
    return out


func _ensure_enemy_count() -> void:
    var world := _world()
    if world == null:
        return

    var alive := _get_enemies(world).size()
    var missing:int = max(desired_enemy_count - alive - _pending_respawns, 0)
    if missing <= 0:
        return

    _pending_respawns += missing
    _schedule_next_respawn_if_needed()


func _schedule_next_respawn_if_needed() -> void:
    if _pending_respawns <= 0:
        return
    if _respawn_timer != null:
        return

    var delay := maxf(respawn_delay_seconds, 0.0)
    _respawn_timer = get_tree().create_timer(delay)
    _respawn_timer.timeout.connect(_on_respawn_timeout)


func _on_respawn_timeout() -> void:
    _respawn_timer = null

    var world := _world()
    if world == null:
        return

    var alive := _get_enemies(world).size()
    if alive >= desired_enemy_count:
        _pending_respawns = 0
        return

    if _pending_respawns <= 0:
        _ensure_enemy_count()
        return

    _spawn_one(world)
    _pending_respawns = max(_pending_respawns - 1, 0)
    _schedule_next_respawn_if_needed()


func _spawn_one(world: Node) -> void:
    var enemy := enemy_scene.instantiate() as Node2D
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
    _ensure_enemy_count()


func _screen_corner_spawn_position(enemy: Node2D) -> Vector2:
    var vp := get_viewport()
    if vp == null:
        return Vector2.ZERO

    var visible := WorldBounds.get_visible_world_rect(vp)
    if visible.size.length() <= 1.0:
        return Vector2.ZERO

    var r := _estimate_radius(enemy)
    var inset := maxf(corner_inset, 0.0) + maxf(spawn_margin, 0.0) + r
    var rect := WorldBounds.inset_rect(visible, Vector2(inset, inset))

    var corners := [
        rect.position,
        Vector2(rect.end.x, rect.position.y),
        Vector2(rect.position.x, rect.end.y),
        rect.end,
    ]

    return corners[randi() % corners.size()]


func _estimate_radius(body: Node2D) -> float:
    if body == null:
        return 34.0

    var shape_node := body.get_node_or_null("shape") as CollisionShape2D
    if shape_node == null or shape_node.shape == null:
        return 34.0

    var s := shape_node.shape
    if s is CircleShape2D:
        return (s as CircleShape2D).radius
    if s is RectangleShape2D:
        var ext := (s as RectangleShape2D).size * 0.5
        return maxf(ext.x, ext.y)

    return 34.0
