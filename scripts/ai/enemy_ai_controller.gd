extends Node
class_name EnemyAIController
## 简单敌人 AI：
## - 找最近的玩家
## - 朝玩家移动（保持一定距离）
## - 若在攻击范围内则自动开火（复用 ShootComponent）
##
## 依赖：
## - 同级 movable: MoveComponent
## - 同级 targeting: TargetingComponent(Area2D，可选但建议)
## - 同级 shoot: ShootComponent

@export_group("Targeting")
@export var player_group: StringName = &"player"
@export var retarget_interval: float = 0.35

@export_group("Movement")
@export var stop_distance: float = 220.0
@export var jitter_strength: float = 0.18
@export var jitter_interval: float = 0.9

@export_group("Combat")
@export var fire_cooldown: float = 0.7

@onready var _host: CharacterBody2D = get_parent() as CharacterBody2D
@onready var _move: MoveComponent = _host.get_node_or_null("movable") as MoveComponent
@onready var _targeting: Area2D = _host.get_node_or_null("targeting") as Area2D
@onready var _shoot: ShootComponent = _host.get_node_or_null("shoot") as ShootComponent

var _target: CharacterBody2D = null
var _retarget_t: float = 0.0
var _fire_t: float = 0.0

var _jitter_t: float = 0.0
var _jitter: Vector2 = Vector2.ZERO


func _ready() -> void:
    assert(_host != null)
    assert(_move != null, "EnemyAIController: missing sibling 'movable'(MoveComponent).")
    assert(_shoot != null, "EnemyAIController: missing sibling 'shoot'(ShootComponent).")
    randomize()


func _physics_process(delta: float) -> void:
    _retarget_t -= delta
    _fire_t -= delta
    _jitter_t -= delta

    if _retarget_t <= 0.0:
        _retarget_t = retarget_interval
        _target = _find_nearest_player()

    if _jitter_t <= 0.0:
        _jitter_t = jitter_interval
        _jitter = _random_unit() * jitter_strength

    if not is_instance_valid(_target):
        _move.direction = Vector2.ZERO
        return

    var to_target: Vector2 = _target.global_position - _host.global_position
    var dist: float = to_target.length()

    _move.direction = _compute_move_dir(to_target, dist)

    if _can_fire_at(_target, dist):
        _try_fire(_target)


func _compute_move_dir(to_target: Vector2, dist: float) -> Vector2:
    if dist <= 0.001:
        return Vector2.ZERO

    if dist <= stop_distance:
        return Vector2.ZERO

    var dir := to_target.normalized()
    dir = (dir + _jitter).normalized()
    return dir


func _can_fire_at(target: CharacterBody2D, _dist: float) -> bool:
    if _fire_t > 0.0:
        return false
    if not is_instance_valid(target):
        return false

    # 优先：目标必须在 TargetingComponent 里（更符合“攻击范围”设定）
    # 若没有 targeting，则允许直接射击（更鲁棒）
    if _targeting != null and _targeting.has_method("get"):
        var current: CharacterBody2D = _targeting.get("current_target") as CharacterBody2D
        return is_instance_valid(current) and current == target

    return true


func _try_fire(target: CharacterBody2D) -> void:
    _fire_t = fire_cooldown
    _shoot.shoot(target)


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
    var a := randf() * TAU
    return Vector2(cos(a), sin(a))
