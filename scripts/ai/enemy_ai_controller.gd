extends Node
class_name EnemyAIController
## 敌人 AI（四状态）：
## - 梦游：随机游走，不追不打
## - 追逐：只追玩家，不开火
## - 待命：随机游走；玩家进入射程才攻击；不主动追
## - 疯狂：主动追击玩家并开火
##
## 依赖：
## - 同级 movable: MoveComponent
## - 同级 targeting: TargetingComponent(Area2D，可选但建议)
## - 同级 shoot: ShootComponent

const EnemyAIStates := preload("res://scripts/ai/enemy_ai_states.gd")
const WorldBounds := preload("res://scripts/utils/world_bounds.gd")

@export_group("Targeting")
@export var player_group: StringName = &"player"
@export var retarget_interval: float = 0.35

@export_group("Movement")
@export var stop_distance: float = 220.0
@export var jitter_strength: float = 0.18
@export var jitter_interval: float = 0.9

@export_group("Combat")
@export var fire_cooldown: float = 0.7

@export_group("State Machine")
@export var state_switch_interval: float = 3.0

@export_group("Screen Bounds")
## 额外向内收缩的边界（像素）。越大越“保守”，越不贴边。
@export var screen_margin: float = 18.0
## 边界“回弹/转向”强度：越大越不容易越界。
@export var bounds_steer_strength: float = 1.35
## 离边界多近开始施加 steering（像素）。
@export var bounds_soft_zone: float = 90.0

@onready var _host: CharacterBody2D = get_parent() as CharacterBody2D
@onready var _move: MoveComponent = _host.get_node_or_null("movable") as MoveComponent
@onready var _targeting: Area2D = _host.get_node_or_null("targeting") as Area2D
@onready var _shoot: ShootComponent = _host.get_node_or_null("shoot") as ShootComponent

var _target: CharacterBody2D = null
var _retarget_t: float = 0.0
var _fire_t: float = 0.0

var _jitter_t: float = 0.0
var _jitter: Vector2 = Vector2.ZERO

var _state_t: float = 0.0
var _state: int = EnemyAIStates.State.DREAM
var _rng := RandomNumberGenerator.new()

var _bounds: Rect2 = Rect2()


func _ready() -> void:
    assert(_host != null)
    assert(_move != null, "EnemyAIController: missing sibling 'movable'(MoveComponent).")
    assert(_shoot != null, "EnemyAIController: missing sibling 'shoot'(ShootComponent).")

    _rng.randomize()
    _pick_new_state(true)


func _physics_process(delta: float) -> void:
    _tick_timers(delta)
    _update_jitter_if_needed()
    _update_target_if_needed()
    _update_world_bounds()

    _apply_state_behavior(delta)


func _tick_timers(delta: float) -> void:
    _retarget_t -= delta
    _fire_t -= delta
    _jitter_t -= delta
    _state_t -= delta

    if _state_t <= 0.0:
        _pick_new_state()


func _pick_new_state(force: bool = false) -> void:
    _state_t = maxf(state_switch_interval, 0.05)
    var next := EnemyAIStates.pick_state(_rng)
    if force:
        _state = next
        return

    _state = next


func _update_jitter_if_needed() -> void:
    if _jitter_t > 0.0:
        return
    _jitter_t = jitter_interval
    _jitter = _random_unit() * jitter_strength


func _update_target_if_needed() -> void:
    if _retarget_t > 0.0:
        return
    _retarget_t = retarget_interval
    _target = _find_nearest_player()


func _update_world_bounds() -> void:
    var vp := get_viewport()
    if vp == null:
        return

    var visible := WorldBounds.get_visible_world_rect(vp)
    if visible.size.length() <= 1.0:
        return

    var inset := _compute_inset_margin()
    _bounds = WorldBounds.inset_rect(visible, inset)


func _compute_inset_margin() -> Vector2:
    var host_radius := _estimate_host_radius()
    var m := maxf(screen_margin, 0.0) + host_radius
    return Vector2(m, m)


func _estimate_host_radius() -> float:
    if _host == null:
        return 0.0

    var shape_node := _host.get_node_or_null("shape") as CollisionShape2D
    if shape_node == null or shape_node.shape == null:
        return 34.0

    var s := shape_node.shape
    if s is CircleShape2D:
        return (s as CircleShape2D).radius
    if s is RectangleShape2D:
        var ext := (s as RectangleShape2D).size * 0.5
        return maxf(ext.x, ext.y)

    return 34.0


func _apply_state_behavior(_delta: float) -> void:
    match _state:
        EnemyAIStates.State.DREAM:
            _do_wander(false)
        EnemyAIStates.State.CHASE:
            _do_chase(false)
        EnemyAIStates.State.STANDBY:
            _do_standby()
        EnemyAIStates.State.MADNESS:
            _do_chase(true)
        _:
            _do_wander(false)


func _do_wander(allow_fire: bool) -> void:
    _move.direction = _bounded_direction(_wander_direction())

    if allow_fire:
        _try_fire_if_in_range()


func _do_chase(allow_fire: bool) -> void:
    if not is_instance_valid(_target):
        _move.direction = _bounded_direction(_wander_direction())
        return

    var to_target: Vector2 = _target.global_position - _host.global_position
    var dist: float = to_target.length()

    _move.direction = _bounded_direction(_compute_move_dir(to_target, dist))

    if allow_fire:
        _try_fire_if_in_range()


func _do_standby() -> void:
    _move.direction = _bounded_direction(_wander_direction())
    _try_fire_if_in_range()


func _try_fire_if_in_range() -> void:
    if _fire_t > 0.0:
        return

    var target := _get_target_in_range()
    if not is_instance_valid(target):
        return

    _fire_t = fire_cooldown
    _shoot.shoot(target)


func _get_target_in_range() -> CharacterBody2D:
    if _targeting == null:
        return null

    if _targeting.has_method("get"):
        return _targeting.get("current_target") as CharacterBody2D

    if _targeting.has_method("get_current_target"):
        return _targeting.call("get_current_target") as CharacterBody2D

    return null


func _wander_direction() -> Vector2:
    var dir := _jitter
    if dir.length() <= 0.001:
        dir = _random_unit() * 0.75
    return dir.normalized()


func _compute_move_dir(to_target: Vector2, dist: float) -> Vector2:
    if dist <= 0.001:
        return Vector2.ZERO

    if dist <= stop_distance:
        return Vector2.ZERO

    var dir := to_target.normalized()
    dir = (dir + _jitter).normalized()
    return dir


func _bounded_direction(dir: Vector2) -> Vector2:
    if dir.length() <= 0.001:
        return Vector2.ZERO

    if _bounds.size.length() <= 1.0:
        return dir.normalized()

    var pos := _host.global_position

    var steer := Vector2.ZERO
    steer.x += _axis_steer(pos.x, _bounds.position.x, _bounds.end.x)
    steer.y += _axis_steer(pos.y, _bounds.position.y, _bounds.end.y)

    if steer.length() <= 0.001:
        return dir.normalized()

    var mixed := (dir.normalized() + steer * bounds_steer_strength)
    if mixed.length() <= 0.001:
        return steer.normalized()
    return mixed.normalized()


func _axis_steer(v: float, min_v: float, max_v: float) -> float:
    var zone := maxf(bounds_soft_zone, 1.0)

    var d_left := v - min_v
    if d_left < zone:
        return _falloff((zone - d_left) / zone)

    var d_right := max_v - v
    if d_right < zone:
        return -_falloff((zone - d_right) / zone)

    return 0.0


func _falloff(t: float) -> float:
    var x := clampf(t, 0.0, 1.0)
    return x * x


func _find_nearest_player() -> CharacterBody2D:
    var players := get_tree().get_nodes_in_group(player_group)
    if players.is_empty():
        return null

    var best: CharacterBody2D = null
    var best_d2: float = INF
    var o := _host.global_position

    for n in players:
        var p := n as CharacterBody2D
        if p == null:
            continue
        if not is_instance_valid(p):
            continue
        var d2 := o.distance_squared_to(p.global_position)
        if d2 < best_d2:
            best_d2 = d2
            best = p

    return best


func _random_unit() -> Vector2:
    var a := _rng.randf() * TAU
    return Vector2(cos(a), sin(a))
