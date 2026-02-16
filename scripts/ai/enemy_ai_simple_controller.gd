extends Node
class_name EnemyAISimpleController
## 敌人 AI（无状态）：
## - 移动：只走上下左右（不允许斜走）
## - 节奏：走 1 秒，停 1 秒（循环）
## - 战斗：目标进入射程后，需瞄准 3 秒才可开火；目标切换/丢失则重置瞄准
##
## 依赖（同级）：
## - movable: MoveComponent
## - targeting: TargetingComponent(Area2D)
## - shoot: ShootComponent

@export_group("Targeting")
@export var retarget_interval: float = 0.35

@export_group("Movement")
@export var walk_seconds: float = 1.0
@export var stop_seconds: float = 1.0
@export var jitter_interval: float = 0.8

@export_group("Combat")
@export var aim_time: float = 3.0
@export var fire_cooldown: float = 0.7

@onready var _host: CharacterBody2D = get_parent() as CharacterBody2D
@onready var _move: MoveComponent = _host.get_node_or_null("movable") as MoveComponent
@onready var _targeting: Area2D = _host.get_node_or_null("targeting") as Area2D
@onready var _shoot: ShootComponent = _host.get_node_or_null("shoot") as ShootComponent

var _retarget_t: float = 0.0
var _fire_t: float = 0.0

var _jitter_t: float = 0.0
var _jitter_dir: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()

var _pace_t: float = 0.0
var _is_walking: bool = true

var _aim_t: float = 0.0
var _aim_target: CharacterBody2D = null


func _ready() -> void:
    assert(_host != null)
    assert(_move != null, "EnemyAISimpleController: missing sibling 'movable'(MoveComponent).")
    assert(_shoot != null, "EnemyAISimpleController: missing sibling 'shoot'(ShootComponent).")

    _rng.randomize()
    _reset_pace()


func _physics_process(delta: float) -> void:
    _tick_timers(delta)
    _update_jitter_if_needed()

    var target := _get_target_in_range()
    _tick_aim(delta, target)

    _move.direction = _compute_move_direction(target)

    _try_fire(target)


func _tick_timers(delta: float) -> void:
    _retarget_t -= delta
    _fire_t -= delta
    _jitter_t -= delta

    _pace_t -= delta
    if _pace_t <= 0.0:
        _is_walking = not _is_walking
        _pace_t = _pace_duration()


func _pace_duration() -> float:
    return maxf(walk_seconds if _is_walking else stop_seconds, 0.0)


func _reset_pace() -> void:
    _is_walking = true
    _pace_t = _pace_duration()


func _update_jitter_if_needed() -> void:
    if _jitter_t > 0.0:
        return
    _jitter_t = maxf(jitter_interval, 0.05)
    _jitter_dir = _random_cardinal()


func _random_cardinal() -> Vector2:
    match _rng.randi_range(0, 3):
        0: return Vector2.RIGHT
        1: return Vector2.LEFT
        2: return Vector2.DOWN
        3: return Vector2.UP
    return Vector2.RIGHT


func _get_target_in_range() -> CharacterBody2D:
    if _targeting == null:
        return null

    if _targeting.has_method("get"):
        return _targeting.get("current_target") as CharacterBody2D

    if _targeting.has_method("get_current_target"):
        return _targeting.call("get_current_target") as CharacterBody2D

    return null


func _tick_aim(delta: float, target: CharacterBody2D) -> void:
    if not is_instance_valid(target):
        _aim_t = 0.0
        _aim_target = null
        return

    if _aim_target != target:
        _aim_target = target
        _aim_t = 0.0

    _aim_t += delta


func _compute_move_direction(target: CharacterBody2D) -> Vector2:
    if not _is_walking:
        return Vector2.ZERO

    var dir := _jitter_dir
    if is_instance_valid(target):
        var to_target := target.global_position - _host.global_position
        dir = _quantize_to_cardinal(to_target)

        if dir == Vector2.ZERO:
            dir = _jitter_dir

    return dir


func _quantize_to_cardinal(v: Vector2) -> Vector2:
    if v.length_squared() <= 0.0001:
        return Vector2.ZERO

    if absf(v.x) >= absf(v.y):
        return Vector2.RIGHT if v.x >= 0.0 else Vector2.LEFT

    return Vector2.DOWN if v.y >= 0.0 else Vector2.UP


func _try_fire(target: CharacterBody2D) -> void:
    if _fire_t > 0.0:
        return
    if not is_instance_valid(target):
        return

    if _aim_t < maxf(aim_time, 0.0):
        return

    _fire_t = maxf(fire_cooldown, 0.0)
    _shoot.shoot(target)
