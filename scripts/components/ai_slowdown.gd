extends Node
class_name AISlowdownComponent
## 通用 AI 节流组件：通过“时间门”降低敌方 AI 的决策/动作频率。
## - 不依赖具体 AI 实现：尝试对常见方法进行包装，找不到就跳过
## - 仅对 enemy 分组默认启用（避免影响玩家）

const GameBalance := preload("res://scripts/config/game_balance.gd")


class TimerGate:
    var interval: float
    var _accum: float = 0.0

    func _init(p_interval: float) -> void:
        interval = maxf(p_interval, 0.0)

    func step(delta: float) -> bool:
        if interval <= 0.0:
            return true
        _accum += delta
        if _accum >= interval:
            _accum = 0.0
            return true
        return false


@export var only_for_enemy_group: bool = true

## 基础节流间隔（秒）。会再除以 ENEMY_TIME_SCALE（scale 越小 => 间隔越大）
@export var base_interval: float = 0.06

## 额外：将宿主的 MoveComponent.speed 乘以该倍率（默认从 GameBalance 取）
@export var move_speed_mult: float = GameBalance.ENEMY_MOVE_SPEED_MULT

## 额外：AI 开火/攻击动作节流加重（更慢）
@export var fire_interval_mult: float = GameBalance.ENEMY_FIRE_COOLDOWN_MULT


var _host: Node = null
var _gate_think: TimerGate
var _gate_fire: TimerGate


func _ready() -> void:
    _host = get_parent()
    if _host == null:
        return

    if only_for_enemy_group and not _host.is_in_group("enemy"):
        queue_free()
        return

    var scale := maxf(GameBalance.ENEMY_TIME_SCALE, 0.05)
    _gate_think = TimerGate.new(base_interval / scale)
    _gate_fire = TimerGate.new((base_interval * fire_interval_mult) / scale)

    _slow_move_component()
    _wrap_common_ai_methods()


func _slow_move_component() -> void:
    if _host == null:
        return

    var move := _host.get_node_or_null("movable")
    if move == null:
        return

    if move.has_variable("speed"):
        var s: float = float(move.get("speed"))
        move.set("speed", s * move_speed_mult)


func _wrap_common_ai_methods() -> void:
    # 尝试包装 controller 节点（如果存在），否则包装宿主
    var controller := _host.get_node_or_null("controller")
    var target := controller if controller != null else _host

    _wrap_method_if_exists(target, "_physics_process", _gate_think)
    _wrap_method_if_exists(target, "_process", _gate_think)

    # 常见的 AI 自定义方法名（存在就节流）
    for m in ["think", "tick_ai", "update_ai", "do_ai", "attack", "shoot", "try_shoot", "fire"]:
        _wrap_method_if_exists(target, m, _gate_fire if m in ["attack", "shoot", "try_shoot", "fire"] else _gate_think)


func _wrap_method_if_exists(obj: Object, method_name: String, gate: TimerGate) -> void:
    if obj == null or method_name.is_empty():
        return
    if not obj.has_method(method_name):
        return

    # Godot 没有运行时替换 GDScript 函数体的官方 API；
    # 这里采用“信号/回调不可侵入”的保守策略：把 Node 的 processing 降频。
    # 若方法是 _process/_physics_process：直接通过 set_*_process 降频即可；
    # 对其它方法：无法安全替换，故只对帧回调类生效（避免破坏逻辑）。
    if method_name == "_process":
        obj.set_process(true)
        obj.set_process_priority(obj.get_process_priority())
        set_process(true)
    elif method_name == "_physics_process":
        obj.set_physics_process(true)
        obj.set_physics_process_priority(obj.get_physics_process_priority())
        set_physics_process(true)


func _process(delta: float) -> void:
    # 降低 _process 回调频率：没到时间门就不做事（通过禁用/启用实现）
    if _host == null:
        return

    var controller := _host.get_node_or_null("controller")
    if controller == null:
        return

    if controller.is_processing():
        if not _gate_think.step(delta):
            controller.set_process(false)
    else:
        if _gate_think.step(delta):
            controller.set_process(true)


func _physics_process(delta: float) -> void:
    # 降低 _physics_process 回调频率
    if _host == null:
        return

    var controller := _host.get_node_or_null("controller")
    if controller == null:
        return

    if controller.is_physics_processing():
        if not _gate_think.step(delta):
            controller.set_physics_process(false)
    else:
        if _gate_think.step(delta):
            controller.set_physics_process(true)
