extends CanvasLayer
class_name MathPrompt

signal answered_correct
signal answered_wrong
signal canceled

@export var max_operand: int = 10

@onready var _panel: Panel = $Panel
@onready var _question_label: Label = $Panel/VBox/Question
@onready var _answer: LineEdit = $Panel/VBox/Answer

var _expected: int = 0
var _active: bool = false


func _ready() -> void:
    visible = false
    _answer.text_submitted.connect(_on_text_submitted)

    # 关键：让本 CanvasLayer 在 UI 聚焦时也能收到未处理输入（Esc 取消）
    _answer.mouse_filter = Control.MOUSE_FILTER_STOP
    _answer.top_level = false
    set_process_unhandled_input(true)


func popup_question() -> void:
    _generate_question()
    _answer.clear()
    visible = true
    _active = true
    _panel.grab_focus()
    _answer.grab_focus()


func hide_prompt() -> void:
    visible = false
    _active = false
    _answer.clear()


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return

    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        hide_prompt()
        canceled.emit()
        get_viewport().set_input_as_handled()


func _generate_question() -> void:
    var a := randi_range(0, max_operand)
    var b := randi_range(0, max_operand)
    var is_add := (randi() % 2) == 0

    if is_add:
        _expected = a + b
        _question_label.text = "%d + %d = ?" % [a, b]
        return

    if a < b:
        var tmp := a
        a = b
        b = tmp
    _expected = a - b
    _question_label.text = "%d - %d = ?" % [a, b]


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
