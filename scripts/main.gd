extends Node2D

@export var desired_enemy_count: int = 4
@export var total_enemy_count: int = 20

const _RESTART_KEYS: Array[int] = [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
const WorldBounds := preload("res://scripts/utils/world_bounds.gd")

var _game_over: bool = false
var _end_layer: CanvasLayer
var _end_label: Label


func _ready() -> void:
    randomize()
    _build_end_ui()

    var spawner := _setup_enemy_spawner()
    _spawn_player_tank(_get_screen_center_world())
    _wire_victory_and_defeat(spawner)


func _unhandled_input(event: InputEvent) -> void:
    if not _game_over:
        return
    if event is InputEventKey and event.pressed and event.keycode in _RESTART_KEYS:
        get_viewport().set_input_as_handled()
        _restart()


func _setup_enemy_spawner() -> EnemySpawner:
    var spawner := EnemySpawner.new()
    add_child(spawner)

    spawner.desired_enemy_count = desired_enemy_count
    spawner.total_enemies_to_spawn = total_enemy_count
    return spawner


func _spawn_player_tank(pos: Vector2) -> CharacterBody2D:
    var player := load("res://scenes/units/tank/player.tscn").instantiate() as CharacterBody2D
    add_child(player)
    player.global_position = pos
    return player


func _get_screen_center_world() -> Vector2:
    var vp := get_viewport()
    if vp == null:
        return Vector2.ZERO

    var rect := WorldBounds.get_visible_world_rect(vp)
    return rect.get_center() if rect.size.length() > 1.0 else Vector2.ZERO


func _wire_victory_and_defeat(spawner: EnemySpawner) -> void:
    if is_instance_valid(spawner) and spawner.has_signal("victory"):
        spawner.victory.connect(_on_victory)

    var player := _find_player()
    if not is_instance_valid(player):
        return

    var health := player.get_node_or_null("health") as HealthComponent
    if health != null:
        health.died.connect(_on_defeat)


func _find_player() -> CharacterBody2D:
    var players := get_tree().get_nodes_in_group("player")
    for n in players:
        var p := n as CharacterBody2D
        if is_instance_valid(p):
            return p
    return null


func _on_victory() -> void:
    _end_game("Victory!\nAll enemies destroyed.\n\nPress SPACE to restart")


func _on_defeat() -> void:
    _end_game("Defeat!\nPlayer destroyed.\n\nPress SPACE to restart")


func _end_game(message: String) -> void:
    if _game_over:
        return
    _game_over = true

    get_tree().paused = true
    _show_end_message(message)


func _restart() -> void:
    get_tree().paused = false
    _game_over = false
    get_tree().reload_current_scene()


func _build_end_ui() -> void:
    _end_layer = CanvasLayer.new()
    _end_layer.layer = 1000
    add_child(_end_layer)

    var root := Control.new()
    root.name = "EndUIRoot"
    root.anchor_left = 0.0
    root.anchor_top = 0.0
    root.anchor_right = 1.0
    root.anchor_bottom = 1.0
    root.offset_left = 0.0
    root.offset_top = 0.0
    root.offset_right = 0.0
    root.offset_bottom = 0.0
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _end_layer.add_child(root)

    var panel := PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = 0.0
    panel.offset_top = 0.0
    panel.offset_right = 0.0
    panel.offset_bottom = 0.0

    root.add_child(panel)

    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.04, 0.04, 0.05, 0.85)
    sb.border_color = Color(1, 1, 1, 0.18)
    sb.border_width_left = 2
    sb.border_width_top = 2
    sb.border_width_right = 2
    sb.border_width_bottom = 2
    sb.corner_radius_top_left = 12
    sb.corner_radius_top_right = 12
    sb.corner_radius_bottom_left = 12
    sb.corner_radius_bottom_right = 12
    sb.content_margin_left = 18
    sb.content_margin_right = 18
    sb.content_margin_top = 14
    sb.content_margin_bottom = 14
    panel.add_theme_stylebox_override("panel", sb)

    _end_label = Label.new()
    _end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _end_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _end_label.custom_minimum_size = Vector2(520, 0)
    _end_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(_end_label)

    _end_layer.visible = false


func _show_end_message(message: String) -> void:
    if _end_layer == null or _end_label == null:
        return
    _end_label.text = message
    _end_layer.visible = true