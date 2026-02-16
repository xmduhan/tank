extends Node
class_name AiSlowdownComponent
## 敌人“瞄准延迟”组件：
## - 当 targeting 选中目标后，持续瞄准 aim_time 秒
## - 瞄准完成后调用 shoot.shoot(target)
## - 若目标切换/丢失/失效，则取消本次瞄准

@export var aim_time: float = 3.0

@export_group("Node Paths")
@export var targeting_path: NodePath = NodePath("../targeting")
@export var shoot_path: NodePath = NodePath("../shoot")

var _host: Node
var _targeting: Node
var _shoot: ShootComponent

var _aiming_target: CharacterBody2D = null
var _timer: SceneTreeTimer = null
var _aim_token: int = 0


func _ready() -> void:
    _host = get_parent()
    assert(_host != null, "AiSlowdownComponent must be a child of an enemy host node.")

    _targeting = get_node_or_null(targeting_path)
    _shoot = get_node_or_null(shoot_path) as ShootComponent

    assert(_targeting != null, "AiSlowdownComponent: targeting not found (check targeting_path).")
    assert(_shoot != null, "AiSlowdownComponent: shoot not found (check shoot_path).")

    if _targeting.has_signal("target_changed"):
        _targeting.connect("target_changed", Callable(self, "_on_target_changed"))
    else:
        push_warning("AiSlowdownComponent: targeting has no signal 'target_changed'.")

    _begin_aiming(_get_current_target())


func _exit_tree() -> void:
    _cancel_aiming()


func _on_target_changed(new_target: CharacterBody2D) -> void:
    _begin_aiming(new_target)


func _begin_aiming(target: CharacterBody2D) -> void:
    _cancel_aiming()

    if not is_instance_valid(target):
        return

    _aiming_target = target
    _aim_token += 1
    var token := _aim_token

    _timer = get_tree().create_timer(maxf(aim_time, 0.0))
    _timer.timeout.connect(func() -> void:
        if token != _aim_token:
            return
        _fire_if_still_valid()
    )


func _cancel_aiming() -> void:
    _aiming_target = null
    _timer = null
    _aim_token += 1


func _fire_if_still_valid() -> void:
    var target := _aiming_target
    if not is_instance_valid(target):
        _cancel_aiming()
        return

    if _shoot == null:
        _cancel_aiming()
        return

    _shoot.shoot(target)


func _get_current_target() -> CharacterBody2D:
    if _targeting == null:
        return null

    if _targeting.has_method("get"):
        return _targeting.get("current_target") as CharacterBody2D

    if _targeting.has_method("get_current_target"):
        return _targeting.call("get_current_target") as CharacterBody2D

    return null
