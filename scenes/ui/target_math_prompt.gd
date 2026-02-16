extends Control
class_name TargetMathPrompt

signal answered_correct
signal answered_wrong
signal canceled

@export var max_operand: int = 10
@export var y_offset: float = 85.0

var _expected: int = 0
var _active: bool = false
var _target: Node2D = null

@onready var _panel: Panel = $Panel
@onready var _question_label: Label = $Panel/HBox/Question
@onready var _answer: LineEdit = $Panel/HBox/Answer


func _ready() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    set_process_unhandled_input(true)

    _answer.text_submitted.connect(_on_text_submitted)
    _answer.mouse_filter = Control.MOUSE_FILTER_STOP


func popup_for_target(target: Node2D) -> void:
    if not is_instance_valid(target):
        return

    _target = target
    _generate_question()
    _answer.clear()

    visible = true
    _active = true

    _panel.grab_focus()
    _answer.grab_focus()
    _update_position()


func hide_prompt() -> void:
    visible = false
    _active = false
    _target = null
    _answer.clear()


func _process(_delta: float) -> void:
    if not _active:
        return
    if not is_instance_valid(_target):
        hide_prompt()
        canceled.emit()
        return
    _update_position()


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        hide_prompt()
        canceled.emit()
        get_viewport().set_input_as_handled()


func _update_position() -> void:
    if not is_instance_valid(_target):
        return
    global_position = _target.global_position + Vector2(0.0, -y_offset)


func _generate_question() -> void:
    var a := randi_range(0, max_operand)
    var b := randi_range(0, max_operand)
    var is_add := (randi() % 2) == 0

    if is_add:
        _expected = a + b
        _question_label.text = "%d + %d =" % [a, b]
        return

    if a < b:
        var tmp := a
        a = b
        b = tmp
    _expected = a - b
    _question_label.text = "%d - %d =" % [a, b]


func _on_text_submitted(text: String) -> void:
    if not _active:
        return

    var s := text.strip_edges()
    if s.is_empty():
        return

    if not s.is_valid_int():
        _answer.clear()
        answered_wrong.emit()
        _answer.grab_focus()
        return

    var v := int(s)
    if v == _expected:
        hide_prompt()
        answered_correct.emit()
        return

    _answer.clear()
    answered_wrong.emit()
    _answer.grab_focus()
