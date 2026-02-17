extends Node
class_name ShootComponent
## 射击组件：
## - 炮塔朝向目标
## - 生成弹道 bullet_trail
## - 弹道到达后生成命中特效并扣血

@export var turret_path: NodePath
@export var muzzle_offset: Vector2 = Vector2(55, 0)

@export_group("Combat")
@export var damage: float = 101.0
@export var bullet_speed: float = 1000.0

@export_group("Effects")
@export var bullet_trail_scene: PackedScene = preload("res://scenes/effects/bullet_trail.tscn")
@export var hit_explosion_scene: PackedScene = preload("res://scenes/effects/explosion.tscn")

var _host: Node2D
var _turret: Node2D


func _ready() -> void:
    _host = get_parent() as Node2D
    assert(_host != null, "ShootComponent must be a child of a Node2D/CharacterBody2D host.")

    if turret_path.is_empty():
        _turret = _host.get_node_or_null("turret") as Node2D
    else:
        _turret = get_node_or_null(turret_path) as Node2D

    assert(_turret != null, "ShootComponent: turret not found, set turret_path or ensure sibling 'turret' exists.")


## 对目标开火：生成弹道；弹道到达后才结算伤害
func shoot(target: CharacterBody2D) -> void:
    if not is_instance_valid(target):
        return

    var start_pos: Vector2 = _get_muzzle_global_position()
    var end_pos: Vector2 = target.global_position

    _aim_turret_at(end_pos)

    if bullet_trail_scene == null:
        _apply_damage(target)
        _spawn_hit_explosion(end_pos)
        return

    var trail: Node = bullet_trail_scene.instantiate()
    var world: Node = SceneTreeUtils.safe_world(_host)
    if world == null:
        return

    world.add_child(trail)

    if trail.has_method("setup"):
        trail.call("setup", start_pos, end_pos, bullet_speed)

    if trail.has_signal("arrived"):
        trail.connect("arrived", Callable(self, "_on_trail_arrived").bind(target, end_pos))
    else:
        _apply_damage(target)
        _spawn_hit_explosion(end_pos)


func _on_trail_arrived(target: CharacterBody2D, hit_pos: Vector2) -> void:
    _spawn_hit_explosion(hit_pos)
    _apply_damage(target)


func _apply_damage(target: CharacterBody2D) -> void:
    if not is_instance_valid(target):
        return

    var health: HealthComponent = target.get_node_or_null("health") as HealthComponent
    if health == null:
        return

    health.damage(damage)


func _spawn_hit_explosion(pos: Vector2) -> void:
    if hit_explosion_scene == null:
        return

    var fx: Node2D = hit_explosion_scene.instantiate() as Node2D
    if fx == null:
        return

    var world: Node = SceneTreeUtils.safe_world(_host)
    if world == null:
        return

    world.add_child(fx)
    fx.global_position = pos


func _aim_turret_at(world_pos: Vector2) -> void:
    if not is_instance_valid(_turret):
        return
    _turret.global_rotation = (world_pos - _turret.global_position).angle()


func _get_muzzle_global_position() -> Vector2:
    var forward: Vector2 = Vector2.RIGHT.rotated(_turret.global_rotation)
    return _turret.global_position + forward * muzzle_offset.x + forward.orthogonal() * muzzle_offset.y