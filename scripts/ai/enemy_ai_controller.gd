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
    _move.direction = _wander_direction()

    if allow_fire:
        _try_fire_if_in_range()


func _do_chase(allow_fire: bool) -> void:
    if not is_instance_valid(_target):
        _move.direction = _wander_direction()
        return

    var to_target: Vector2 = _target.global_position - _host.global_position
    var dist: float = to_target.length()

    _move.direction = _compute_move_dir(to_target, dist)

    if allow_fire:
        _try_fire_if_in_range()


func _do_standby() -> void:
    _move.direction = _wander_direction()
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
