extends Node2D

@export var desired_enemy_count: int = 4
@export var total_enemy_count: int = 20

const _RESTART_KEYS: Array[int] = [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
const _END_PANEL_MIN_SIZE: Vector2 = Vector2(560.0, 180.0)

const _BGM_STREAM: AudioStream = preload("res://assets/audio/music/backgroud.mp3")

# 音量减半≈-6dB：-14 -> -20
const _BGM_VOLUME_DB: float = -20.0
const _BGM_FADE_IN: float = 0.45

const _VICTORY_SFX: AudioStream = preload("res://assets/audio/sfx/victory.wav")
const _FAIL_SFX: AudioStream = preload("res://assets/audio/sfx/fail.wav")

const _RADAR_SFX: AudioStream = preload("res://assets/audio/sfx/radar.wav")
const _RADAR_KEY: StringName = &"radar"
const _RADAR_VOLUME_DB: float = -18.0
const _RADAR_FADE_IN: float = 0.08
const _RADAR_FADE_OUT: float = 0.10
const _RADAR_PITCH_NORMAL: float = 1.0
const _RADAR_PITCH_AIMING: float = 2.0

const _END_LABEL_FONT_SIZE: int = 44
const _END_LABEL_LINE_SPACING: float = 6.0

# 游戏结束后：BGM 继续播放但音量为原来的 1/3
const _END_BGM_LINEAR_SCALE: float = 1.0 / 3.0
const _END_BGM_DB_DELTA: float = -9.542425094 # 20 * log10(1/3)
const _END_BGM_FADE_SECONDS: float = 0.25

var _game_over: bool = false
var _end_layer: CanvasLayer
var _end_label: Label
var _end_panel: PanelContainer

# Radar arbitration state
var _radar_has_target: bool = false
var _radar_is_aiming: bool = false


func _ready() -> void:
    # Main 不应全程 ALWAYS。暂停时应随世界一起停。
    # “暂停界面/答题界面”自身使用 ALWAYS 即可继续工作。
    process_mode = Node.PROCESS_MODE_PAUSABLE
    randomize()

    # 仅用于 game over 时接收重开输入；暂停期间不需要 Main 处理输入
    set_process_unhandled_input(true)

    _ensure_audio_manager()
    _start_bgm()

    _build_end_ui()

    var spawner: EnemySpawner = _setup_enemy_spawner()
    _spawn_player_tank(_get_screen_center_world())
    _wire_victory_and_defeat(spawner)

    _wire_radar_audio_global()


func _unhandled_input(event: InputEvent) -> void:
    if not _game_over:
        return
    if event is InputEventKey and event.pressed and event.keycode in _RESTART_KEYS:
        get_viewport().set_input_as_handled()
        _restart()


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        _layout_end_ui_centered()


func _ensure_audio_manager() -> void:
    if AudioManager.is_ready():
        return

    var world: Node = get_tree().current_scene
    if world == null:
        world = self

    var mgr: AudioManager = AudioManager.ensure(world)
    mgr.bus_sfx = &"Master"
    mgr.bus_music = &"Master"
    mgr.default_sfx_volume_db = -6.0
    mgr.loop_volume_db = -12.0


func _start_bgm() -> void:
    AudioManager.play_music(_BGM_STREAM, _BGM_VOLUME_DB, _BGM_FADE_IN)


func _setup_enemy_spawner() -> EnemySpawner:
    var spawner: EnemySpawner = EnemySpawner.new()
    add_child(spawner)

    spawner.desired_enemy_count = desired_enemy_count
    spawner.total_enemies_to_spawn = total_enemy_count
    return spawner


func _spawn_player_tank(pos: Vector2) -> CharacterBody2D:
    var player: CharacterBody2D = load("res://scenes/units/tank/player.tscn").instantiate() as CharacterBody2D
    add_child(player)
    player.global_position = pos
    return player


func _get_screen_center_world() -> Vector2:
    var vp: Viewport = get_viewport()
    if vp == null:
        return Vector2.ZERO

    var rect: Rect2 = WorldBounds.get_visible_world_rect(vp)
    return rect.get_center() if rect.size.length() > 1.0 else Vector2.ZERO


func _wire_victory_and_defeat(spawner: EnemySpawner) -> void:
    if is_instance_valid(spawner) and spawner.has_signal("victory"):
        spawner.victory.connect(_on_victory)

    var player: CharacterBody2D = _find_player()
    if not is_instance_valid(player):
        return

    var health: HealthComponent = player.get_node_or_null("health") as HealthComponent
    if health != null:
        health.died.connect(_on_defeat)


func _find_player() -> CharacterBody2D:
    var players: Array[Node] = get_tree().get_nodes_in_group("player")
    for n: Node in players:
        var p: CharacterBody2D = n as CharacterBody2D
        if is_instance_valid(p):
            return p
    return null


func _on_victory() -> void:
    _play_end_sfx(_VICTORY_SFX)
    _end_game("胜利！\n已消灭全部敌人。\n\n按空格键重新开始")


func _on_defeat() -> void:
    _play_end_sfx(_FAIL_SFX)
    _end_game("失败！\n玩家已被摧毁。\n\n按空格键重新开始")


func _play_end_sfx(stream: AudioStream) -> void:
    if stream == null:
        return

    # 用 CanvasLayer 作为 host（ALWAYS），避免“马上 paused”导致音效不触发/不稳定
    var host: Node = _end_layer if is_instance_valid(_end_layer) else self
    AudioManager.play_sfx_2d(host, stream, -6.0)


func _end_game(message: String) -> void:
    if _game_over:
        return
    _game_over = true

    _duck_bgm_for_end_state()

    get_tree().paused = true
    _show_end_message(message)


func _duck_bgm_for_end_state() -> void:
    # 继续播放同一首 BGM，但把音量降为原来的 1/3（线性）
    # 通过重新调用 play_music 让 AudioManager 用 tween 平滑切到新音量
    var end_db: float = _BGM_VOLUME_DB + _END_BGM_DB_DELTA
    AudioManager.play_music(_BGM_STREAM, end_db, _END_BGM_FADE_SECONDS)


func _restart() -> void:
    get_tree().paused = false
    _game_over = false
    get_tree().reload_current_scene()


func _build_end_ui() -> void:
    _end_layer = CanvasLayer.new()
    _end_layer.layer = 1000
    add_child(_end_layer)

    var root: Control = Control.new()
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

    _end_panel = PanelContainer.new()
    _end_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _end_panel.custom_minimum_size = _END_PANEL_MIN_SIZE

    _end_panel.anchor_left = 0.5
    _end_panel.anchor_top = 0.5
    _end_panel.anchor_right = 0.5
    _end_panel.anchor_bottom = 0.5
    root.add_child(_end_panel)

    var sb: StyleBoxFlat = StyleBoxFlat.new()
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
    _end_panel.add_theme_stylebox_override("panel", sb)

    _end_label = Label.new()
    _end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _end_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _end_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # 字体调大（仅覆盖该 Label，不影响全局主题）
    _end_label.add_theme_font_size_override("font_size", _END_LABEL_FONT_SIZE)
    _end_label.add_theme_constant_override("line_spacing", int(_END_LABEL_LINE_SPACING))

    _end_panel.add_child(_end_label)

    _end_layer.visible = false
    _layout_end_ui_centered()


func _layout_end_ui_centered() -> void:
    if _end_panel == null:
        return

    var size: Vector2 = _end_panel.custom_minimum_size
    if size.x <= 1.0 or size.y <= 1.0:
        size = _END_PANEL_MIN_SIZE

    _end_panel.offset_left = -size.x * 0.5
    _end_panel.offset_top = -size.y * 0.5
    _end_panel.offset_right = size.x * 0.5
    _end_panel.offset_bottom = size.y * 0.5


func _show_end_message(message: String) -> void:
    if _end_layer == null or _end_label == null:
        return
    _end_label.text = message
    _layout_end_ui_centered()
    _end_layer.visible = true


# ─────────────────────────────────────────────────────────────
# Radar audio: global wiring + arbitration
# ─────────────────────────────────────────────────────────────

func set_radar_aiming(active: bool) -> void:
    if _radar_is_aiming == active:
        return
    _radar_is_aiming = active
    _update_radar_loop()


func _wire_radar_audio_global() -> void:
    _scan_and_wire_targeting()
    child_entered_tree.connect(_on_node_entered_tree)


func _on_node_entered_tree(node: Node) -> void:
    _wire_targeting_under(node)


func _scan_and_wire_targeting() -> void:
    _wire_targeting_under(self)


func _wire_targeting_under(root: Node) -> void:
    if root == null:
        return

    for n: Node in _walk(root):
        var t: TargetingComponent = n as TargetingComponent
        if t == null:
            continue
        if not t.target_changed.is_connected(_on_any_target_changed):
            t.target_changed.connect(_on_any_target_changed)


func _walk(root: Node) -> Array[Node]:
    var out: Array[Node] = []
    var stack: Array[Node] = [root]
    while not stack.is_empty():
        var n: Node = stack.pop_back()
        out.append(n)
        for c: Node in n.get_children():
            stack.append(c)
    return out


func _on_any_target_changed(new_target: CharacterBody2D) -> void:
    _radar_has_target = is_instance_valid(new_target)
    _update_radar_loop()


func _update_radar_loop() -> void:
    if _radar_has_target:
        var pitch: float = _RADAR_PITCH_AIMING if _radar_is_aiming else _RADAR_PITCH_NORMAL
        AudioManager.play_loop(_RADAR_KEY, _RADAR_SFX, _RADAR_VOLUME_DB, _RADAR_FADE_IN, pitch)
    else:
        AudioManager.stop_loop(_RADAR_KEY, _RADAR_FADE_OUT)