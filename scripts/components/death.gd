extends Node
class_name DeathFxComponent
## 死亡特效组件：
## - 监听同级 health(HealthComponent) 的 died 信号
## - 在宿主位置生成殉爆特效
## - 可选：销毁宿主

@export var explosion_scene: PackedScene = preload("res://scenes/effects/tank_explosion.tscn")
@export var free_host_on_death: bool = true

var _host: Node2D
var _health: Node

func _ready() -> void:
    _host = get_parent() as Node2D
    assert(_host != null, "DeathFxComponent must be a child of a Node2D/CharacterBody2D host.")

    _health = _host.get_node_or_null("health")
    assert(_health != null, "DeathFxComponent: sibling node 'health' not found.")

    if _health.has_signal("died"):
        _health.connect("died", Callable(self, "_on_died"))
    else:
        push_warning("DeathFxComponent: health has no signal 'died'.")


func _on_died() -> void:
    _spawn_explosion()
    if free_host_on_death and is_instance_valid(_host):
        _host.queue_free()


func _spawn_explosion() -> void:
    if explosion_scene == null or not is_instance_valid(_host):
        return

    var fx := explosion_scene.instantiate() as Node2D
    if fx == null:
        return

    var world := _host.get_tree().current_scene
    if world == null:
        world = _host.get_parent()
    if world == null:
        return

    world.add_child(fx)
    fx.global_position = _host.global_position
