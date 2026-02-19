extends CanvasLayer
class_name SettingsMenu

signal settings_applied(desired: int, total: int)
signal closed

@onready var _root: Control = $Root as Control
@onready var _desired: SpinBox = $Root/Panel/VBox/Grid/DesiredSpin as SpinBox
@onready var _total: SpinBox = $Root/Panel/VBox/Grid/TotalSpin as SpinBox
@onready var _apply_btn: Button = $Root/Panel/VBox/Buttons/ApplyBtn as Button
@onready var _cancel_btn: Button = $Root/Panel/VBox/Buttons/CancelBtn as Button

var _open: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

    _apply_btn.pressed.connect(_on_apply_pressed)
    _cancel_btn.pressed.connect(_on_cancel_pressed)

    _root.gui_input.connect(_on_root_gui_input)

    _sync_from_settings()


func open_menu() -> void:
    _sync_from_settings()

    visible = true
    _open = true

    if get_tree() != null:
        get_tree().paused = true

    _desired.grab_focus()


func close_menu() -> void:
    visible = false
    _open = false

    if get_tree() != null:
        get_tree().paused = false

    closed.emit()


func _on_root_gui_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_settings"):
        close_menu()
        get_viewport().set_input_as_handled()
        return

    if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
        close_menu()
        get_viewport().set_input_as_handled()


func _on_cancel_pressed() -> void:
    close_menu()


func _on_apply_pressed() -> void:
    var desired: int = int(_desired.value)
    var total: int = int(_total.value)

    if Settings != null:
        Settings.apply_and_save(desired, total)

    settings_applied.emit(desired, total)
    close_menu()


func _sync_from_settings() -> void:
    if Settings == null:
        return

    _desired.min_value = float(Settings.MIN_ENEMY_DESIRED)
    _desired.max_value = float(Settings.MAX_ENEMY_DESIRED)
    _total.min_value = float(Settings.MIN_ENEMY_TOTAL)
    _total.max_value = float(Settings.MAX_ENEMY_TOTAL)

    _desired.value = float(Settings.enemy_desired_count)
    _total.value = float(Settings.enemy_total_count)