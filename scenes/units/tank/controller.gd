extends Node
## 玩家坦克控制器，负责将输入转化为移动指令和技能操作。

@onready var _move: MoveComponent = get_parent().get_node("movable") as MoveComponent
@onready var _attack_range: Area2D = get_parent().get_node_or_null("attack_range")
@onready var _shoot: ShootComponent = get_parent().get_node_or_null("shoot") as ShootComponent


func _ready() -> void:
    assert(_move != null, "Controller: 未找到兄弟节点 'movable'(MoveComponent)。")
    assert(_shoot != null, "Controller: 未找到兄弟节点 'shoot'(ShootComponent)。")


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed):
        return

    match event.keycode:
        KEY_TAB:
            _try_cycle_target()
        KEY_SPACE:
            _try_shoot()


func _physics_process(_delta: float) -> void:
    _move.direction = _get_movement_direction()


## 采集 WASD 输入并返回归一化后的方向向量，防止斜向移动速度大于轴向。
func _get_movement_direction() -> Vector2:
    var direction := Vector2.ZERO

    if Input.is_key_pressed(KEY_A):
        direction.x -= 1
    if Input.is_key_pressed(KEY_D):
        direction.x += 1
    if Input.is_key_pressed(KEY_W):
        direction.y -= 1
    if Input.is_key_pressed(KEY_S):
        direction.y += 1

    return direction


## 安全地请求攻击范围组件切换瞄准目标。
func _try_cycle_target() -> void:
    if _attack_range and _attack_range.has_method("cycle_target"):
        _attack_range.cycle_target()


## 空格：对当前锁定目标执行一次射击（特效 + 到达后结算伤害）
func _try_shoot() -> void:
    if _attack_range == null or _shoot == null:
        return

    var target: CharacterBody2D = null
    if "current_target" in _attack_range:
        target = _attack_range.get("current_target") as CharacterBody2D
    else:
        if _attack_range.has_method("get_current_target"):
            target = _attack_range.call("get_current_target") as CharacterBody2D

    if not is_instance_valid(target):
        return

    _shoot.shoot(target)
