extends Node
## 玩家坦克控制器：负责将输入转化为移动指令；空格触发答题，答对后才射击。

const TARGET_MATH_PROMPT_SCENE: PackedScene = preload("res://scenes/ui/aim.tscn")
const PAUSE_SNAPSHOT_SCENE: PackedScene = preload("res://scripts/utils/pause_snapshot.tscn")

@export_group("Screen Bounds")
@export var screen_margin: float = 18.0

@onready var _host: CharacterBody2D = get_parent() as CharacterBody2D
@onready var _move: MoveComponent = _host.get_node("movable") as MoveComponent
@onready var _attack_range: Area2D = _host.get_node_or_null("targeting")
@onready var _shoot: ShootComponent = _host.get_node_or_null("shoot") as ShootComponent

var _math_prompt: TargetMathPromptDrawn
var _pause: PauseSnapshot

var _pending_shot_target: CharacterBody2D = null
var _asking: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE

    assert(_host != null, "Controller: host 必须是 CharacterBody2D。")
    assert(_move != null, "Controller: 未找到兄弟节点 'movable'(MoveComponent)。")
    assert(_shoot != null, "Controller: 未找到兄弟节点 'shoot'(ShootComponent)。")

    _ensure_pause_snapshot()
    _ensure_math_prompt()


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed):
        return

    if _asking:
        if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
            get_viewport().set_input_as_handled()
        return

    match event.keycode:
        KEY_TAB:
            _try_cycle_target()
        KEY_SPACE:
            _try_shoot_with_math_gate()


func _physics_process(_delta: float) -> void:
    _move.direction = _get_movement_direction()
    _clamp_to_screen_bounds()


func _clamp_to_screen_bounds() -> void:
    var vp: Viewport = get_viewport()
    if vp == null:
        return
    WorldBounds.clamp_body_to_visible_rect(_host, vp, screen_margin)


func _get_movement_direction() -> Vector2:
    var x: float = 0.0
    var y: float = 0.0

    x += _axis_value(KEY_A, KEY_D)
    y += _axis_value(KEY_W, KEY_S)

    x += _axis_value(KEY_H, KEY_L)
    y += _axis_value(KEY_K, KEY_J)

    return Vector2(clampf(x, -1.0, 1.0), clampf(y, -1.0, 1.0))


func _axis_value(negative_key: Key, positive_key: Key) -> float:
    return float(Input.is_key_pressed(positive_key)) - float(Input.is_key_pressed(negative_key))


func _try_cycle_target() -> void:
    if _attack_range != null and _attack_range.has_method("cycle_target"):
        _attack_range.cycle_target()


func _try_shoot_with_math_gate() -> void:
    if _attack_range == null or _shoot == null:
        return

    var target: CharacterBody2D = _get_current_target()
    if not is_instance_valid(target):
        return

    _pending_shot_target = target
    _asking = true

    if is_instance_valid(_pause):
        _pause.begin()

    _math_prompt.popup_for_target(target)
    get_viewport().set_input_as_handled()


func _get_current_target() -> CharacterBody2D:
    if _attack_range == null:
        return null

    if _attack_range.has_method("get"):
        return _attack_range.get("current_target") as CharacterBody2D

    if _attack_range.has_method("get_current_target"):
        return _attack_range.call("get_current_target") as CharacterBody2D

    return null


func _ensure_math_prompt() -> void:
    if is_instance_valid(_math_prompt):
        return

    var world: Node = SceneTreeUtils.safe_world(self)
    if world == null:
        world = get_parent()

    _math_prompt = TARGET_MATH_PROMPT_SCENE.instantiate() as TargetMathPromptDrawn
    assert(_math_prompt != null, "Controller: TargetMathPrompt instantiate failed.")
    world.add_child(_math_prompt)

    _math_prompt.answered_correct.connect(_on_math_correct)
    _math_prompt.answered_wrong.connect(_on_math_wrong)
    _math_prompt.canceled.connect(_on_math_canceled)


func _ensure_pause_snapshot() -> void:
    if is_instance_valid(_pause):
        return

    var world: Node = SceneTreeUtils.safe_world(self)
    if world == null:
        world = get_parent()

    _pause = PAUSE_SNAPSHOT_SCENE.instantiate() as PauseSnapshot
    assert(_pause != null, "Controller: PauseSnapshot instantiate failed.")
    world.add_child(_pause)


func _resume_game_if_needed() -> void:
    if is_instance_valid(_pause):
        _pause.end()


func _on_math_correct() -> void:
    _asking = false
    _resume_game_if_needed()

    var target: CharacterBody2D = _pending_shot_target
    _pending_shot_target = null
    if is_instance_valid(target):
        _shoot.shoot(target)


func _on_math_wrong() -> void:
    _asking = true


func _on_math_canceled() -> void:
    _asking = false
    _pending_shot_target = null
    _resume_game_if_needed()