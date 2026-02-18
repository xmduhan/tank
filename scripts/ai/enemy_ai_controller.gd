extends Node
class_name EnemyAIController
## 敌人 AI（角落出生 + 无目标随机游走）：
## - 允许任意方向移动（支持斜走）
## - 目标进入射程后：持续瞄准 aim_time 秒才允许发射
## - 仅当“射程内存在锁定目标(targeting.current_target)”时才追击/开火
## - 无锁定目标时：随机游走（任意方向，周期性换向/可停顿）
## - 屏幕边界软回正，避免出屏


@export_group("Targeting")
@export var player_group: StringName = &"player"
@export var retarget_interval: float = 0.35

@export_group("Movement")
@export var stop_distance: float = 220.0
@export var jitter_strength: float = 0.18
@export var jitter_interval: float = 0.9

@export_group("Wander")
@export var wander_change_interval: float = 1.2
@export var wander_idle_chance: float = 0.08

@export_group("Combat")
@export var fire_cooldown: float = 3.0
@export var aim_time: float = 3.0

@export_group("Screen Bounds")
@export var screen_margin: float = 18.0
@export var bounds_steer_strength: float = 1.35
@export var bounds_soft_zone: float = 90.0

@onready var _host: CharacterBody2D = get_parent() as CharacterBody2D
@onready var _move: MoveComponent = _host.get_node_or_null("movable") as MoveComponent
@onready var _targeting: Area2D = _host.get_node_or_null("targeting") as Area2D
@onready var _shoot: ShootComponent = _host.get_node_or_null("shoot") as ShootComponent

var _chase_target: CharacterBody2D = null
var _retarget_t: float = 0.0
var _fire_t: float = 0.0

var _jitter_t: float = 0.0
var _jitter: Vector2 = Vector2.ZERO

var _bounds: Rect2 = Rect2()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _aim_target: CharacterBody2D = null
var _aim_elapsed: float = 0.0

var _wander_t: float = 0.0
var _wander_dir: Vector2 = Vector2.ZERO


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE

    assert(_host != null)
    assert(_move != null, "EnemyAIController: missing sibling 'movable'(MoveComponent).")
    assert(_shoot != null, "EnemyAIController: missing sibling 'shoot'(ShootComponent).")
    assert(_targeting != null, "EnemyAIController: missing sibling 'targeting'(TargetingComponent).")

    _move.speed = 50.0
    _rng.randomize()
    _pick_new_wander_dir()


func _physics_process(delta: float) -> void:
    _tick(delta)
    _update_jitter_if_needed()
    _update_world_bounds()

    var target_in_range: CharacterBody2D = _get_target_in_range()
    var has_target_in_range: bool = is_instance_valid(target_in_range)

    if has_target_in_range:
        _update_chase_target_if_needed()
    else:
        _chase_target = null
        _update_wander_if_needed()

    var move_dir: Vector2 = _compute_desired_move_direction(has_target_in_range)
    _move.direction = _bounded_direction(move_dir)

    _update_aim_and_fire(delta, target_in_range)


func _tick(delta: float) -> void:
    _retarget_t -= delta
    _fire_t -= delta
    _jitter_t -= delta
    _wander_t -= delta


func _update_jitter_if_needed() -> void:
    if _jitter_t > 0.0:
        return
    _jitter_t = maxf(jitter_interval, 0.01)
    _jitter = _random_unit() * jitter_strength


func _update_wander_if_needed() -> void:
    if _wander_t > 0.0 and _wander_dir != Vector2.ZERO:
        return
    _wander_t = maxf(wander_change_interval, 0.1)
    _pick_new_wander_dir()


func _pick_new_wander_dir() -> void:
    if _rng.randf() < clampf(wander_idle_chance, 0.0, 1.0):
        _wander_dir = Vector2.ZERO
        return

    _wander_dir = _random_unit()


func _update_chase_target_if_needed() -> void:
    if _retarget_t > 0.0:
        return
    _retarget_t = maxf(retarget_interval, 0.05)
    _chase_target = _find_nearest_player()


func _update_world_bounds() -> void:
    var vp: Viewport = get_viewport()
    if vp == null:
        return

    var visible: Rect2 = WorldBounds.get_visible_world_rect(vp)
    if visible.size.length() <= 1.0:
        return

    var inset: Vector2 = _compute_inset_margin()
    _bounds = WorldBounds.inset_rect(visible, inset)


func _compute_inset_margin() -> Vector2:
    var host_radius: float = _estimate_host_radius()
    var m: float = maxf(screen_margin, 0.0) + host_radius
    return Vector2(m, m)


func _estimate_host_radius() -> float:
    var shape_node: CollisionShape2D = _host.get_node_or_null("shape") as CollisionShape2D
    if shape_node == null or shape_node.shape == null:
        return 34.0

    var s: Shape2D = shape_node.shape
    if s is CircleShape2D:
        return (s as CircleShape2D).radius
    if s is RectangleShape2D:
        var ext: Vector2 = (s as RectangleShape2D).size * 0.5
        return maxf(ext.x, ext.y)

    return 34.0


func _compute_desired_move_direction(has_target_in_range: bool) -> Vector2:
    if not has_target_in_range:
        return _wander_dir

    if is_instance_valid(_chase_target):
        var to_target: Vector2 = _chase_target.global_position - _host.global_position
        if to_target.length() <= stop_distance:
            return Vector2.ZERO
        return (to_target.normalized() + _jitter).normalized()

    return Vector2.ZERO


func _update_aim_and_fire(delta: float, target_in_range: CharacterBody2D) -> void:
    if not is_instance_valid(target_in_range):
        _reset_aim()
        return

    if target_in_range != _aim_target:
        _aim_target = target_in_range
        _aim_elapsed = 0.0

    _aim_elapsed += delta

    if _fire_t > 0.0:
        return

    if _aim_elapsed < maxf(aim_time, 0.0):
        return

    _fire_t = maxf(fire_cooldown, 0.0)
    _shoot.shoot(target_in_range)


func _reset_aim() -> void:
    _aim_target = null
    _aim_elapsed = 0.0


func _get_target_in_range() -> CharacterBody2D:
    if _targeting == null:
        return null

    if _targeting.has_method("get"):
        return _targeting.get("current_target") as CharacterBody2D

    if _targeting.has_method("get_current_target"):
        return _targeting.call("get_current_target") as CharacterBody2D

    return null


func _bounded_direction(dir: Vector2) -> Vector2:
    if dir.length() <= 0.001:
        return Vector2.ZERO

    var ndir: Vector2 = dir.normalized()

    if _bounds.size.length() <= 1.0:
        return ndir

    var pos: Vector2 = _host.global_position
    var steer: Vector2 = Vector2(
        _axis_steer(pos.x, _bounds.position.x, _bounds.end.x),
        _axis_steer(pos.y, _bounds.position.y, _bounds.end.y)
    )

    if steer.length() <= 0.001:
        return ndir

    var mixed: Vector2 = ndir + steer * bounds_steer_strength
    return mixed.normalized() if mixed.length() > 0.001 else steer.normalized()


func _axis_steer(v: float, min_v: float, max_v: float) -> float:
    var zone: float = maxf(bounds_soft_zone, 1.0)

    var d_left: float = v - min_v
    if d_left < zone:
        return _falloff((zone - d_left) / zone)

    var d_right: float = max_v - v
    if d_right < zone:
        return -_falloff((zone - d_right) / zone)

    return 0.0


func _falloff(t: float) -> float:
    var x: float = clampf(t, 0.0, 1.0)
    return x * x


func _find_nearest_player() -> CharacterBody2D:
    var players: Array[Node] = get_tree().get_nodes_in_group(player_group)
    if players.is_empty():
        return null

    var best: CharacterBody2D = null
    var best_d2: float = INF
    var o: Vector2 = _host.global_position

    for n: Node in players:
        var p: CharacterBody2D = n as CharacterBody2D
        if p == null or not is_instance_valid(p):
            continue
        var d2: float = o.distance_squared_to(p.global_position)
        if d2 < best_d2:
            best_d2 = d2
            best = p

    return best


func _random_unit() -> Vector2:
    var a: float = _rng.randf() * TAU
    return Vector2(cos(a), sin(a))
