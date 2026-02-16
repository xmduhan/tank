extends Node2D
class_name TargetMathPromptDrawn
## 纯帧绘制的答题提示（无 GUI 控件）：
## - _draw 绘制题目与输入框
## - _unhandled_input 捕获数字/退格/回车/ESC
## - 跟随目标位置

signal answered_correct
signal answered_wrong
signal canceled

@export var max_operand: int = 10
@export var y_offset: float = 85.0

@export_group("Style")
@export var font_size: int = 18
@export var padding: Vector2 = Vector2(10.0, 8.0)
@export var corner_radius: float = 8.0
@export var panel_color: Color = Color(0.06, 0.06, 0.08, 0.82)
@export var border_color: Color = Color(1, 1, 1, 0.18)
@export var text_color: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var hint_color: Color = Color(1, 1, 1, 0.55)
@export var input_bg: Color = Color(0, 0, 0, 0.35)
@export var input_border: Color = Color(1, 1, 1, 0.22)
@export var caret_color: Color = Color(1, 1, 1, 0.9)

@export_group("Layout")
@export var input_width: float = 78.0
@export var input_height: float = 24.0
@export var caret_blink_hz: float = 2.8

var _expected: int = 0
var _question: String = ""
var _typed: String = ""

var _active: bool = false
var _target: Node2D = null

var _caret_phase: float = 0.0

var _font: Font


func _ready() -> void:
    visible = false
    top_level = true
    set_process(true)
    set_process_unhandled_input(true)

    var df := ThemeDB.fallback_font
    if df != null:
        _font = df


func popup_for_target(target: Node2D) -> void:
    if not is_instance_valid(target):
        return

    _target = target
    _generate_question()
    _typed = ""

    visible = true
    _active = true
    _caret_phase = 0.0

    _update_position()
    queue_redraw()


func hide_prompt() -> void:
    visible = false
    _active = false
    _target = null
    _typed = ""
    queue_redraw()


func _process(delta: float) -> void:
    if not _active:
        return

    if not is_instance_valid(_target):
        hide_prompt()
        canceled.emit()
        return

    _update_position()

    _caret_phase += delta * TAU * caret_blink_hz
    queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return

    if event is InputEventKey and event.pressed:
        var k := event as InputEventKey

        if k.keycode == KEY_ESCAPE:
            hide_prompt()
            canceled.emit()
            get_viewport().set_input_as_handled()
            return

        if k.keycode in [KEY_ENTER, KEY_KP_ENTER]:
            _submit_if_possible()
            get_viewport().set_input_as_handled()
            return

        if k.keycode == KEY_BACKSPACE:
            if not _typed.is_empty():
                _typed = _typed.substr(0, _typed.length() - 1)
                queue_redraw()
            get_viewport().set_input_as_handled()
            return

        var digit := _keycode_to_digit(k.keycode)
        if digit != -1:
            if _typed.length() < 6:
                _typed += str(digit)
                queue_redraw()
            get_viewport().set_input_as_handled()
            return


func _submit_if_possible() -> void:
    var s := _typed.strip_edges()
    if s.is_empty():
        answered_wrong.emit()
        return

    if not s.is_valid_int():
        _typed = ""
        answered_wrong.emit()
        return

    var v := int(s)
    if v == _expected:
        hide_prompt()
        answered_correct.emit()
        return

    _typed = ""
    answered_wrong.emit()


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
        _question = "%d + %d =" % [a, b]
        return

    if a < b:
        var tmp := a
        a = b
        b = tmp
    _expected = a - b
    _question = "%d - %d =" % [a, b]


func _keycode_to_digit(keycode: int) -> int:
    match keycode:
        KEY_0, KEY_KP_0: return 0
        KEY_1, KEY_KP_1: return 1
        KEY_2, KEY_KP_2: return 2
        KEY_3, KEY_KP_3: return 3
        KEY_4, KEY_KP_4: return 4
        KEY_5, KEY_KP_5: return 5
        KEY_6, KEY_KP_6: return 6
        KEY_7, KEY_KP_7: return 7
        KEY_8, KEY_KP_8: return 8
        KEY_9, KEY_KP_9: return 9
        _: return -1


func _draw() -> void:
    if not _active:
        return

    var question := _question
    var answer := _typed
    var hint := "Enter 提交  Esc 取消  Backspace 删除"

    var f := _font
    if f == null:
        return

    var q_size := f.get_string_size(question, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
    var h_size := f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(12, font_size - 4)))

    var panel_w := padding.x * 2.0 + q_size.x + 8.0 + input_width
    var panel_h := padding.y * 2.0 + maxf(q_size.y, input_height) + 6.0 + h_size.y

    var rect := Rect2(Vector2(-panel_w * 0.5, -panel_h * 0.5), Vector2(panel_w, panel_h))
    draw_round_rect(rect, corner_radius, panel_color)
    draw_round_rect(rect, corner_radius, border_color, false, 1.0)

    var base_x := rect.position.x + padding.x
    var base_y := rect.position.y + padding.y + q_size.y

    draw_string(f, Vector2(base_x, base_y), question, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

    var input_pos := Vector2(base_x + q_size.x + 8.0, base_y - q_size.y + (q_size.y - input_height) * 0.5)
    var input_rect := Rect2(input_pos, Vector2(input_width, input_height))
    draw_round_rect(input_rect, 6.0, input_bg)
    draw_round_rect(input_rect, 6.0, input_border, false, 1.0)

    var a_fs := font_size
    var text_inset := Vector2(6.0, (input_height + a_fs) * 0.5 - 3.0)
    var text_origin := input_rect.position + text_inset

    draw_string(f, text_origin, answer, HORIZONTAL_ALIGNMENT_LEFT, input_width - 8.0, a_fs, text_color)

    var caret_on := sin(_caret_phase) > 0.0
    if caret_on:
        var a_size := f.get_string_size(answer, HORIZONTAL_ALIGNMENT_LEFT, -1, a_fs)
        var cx := minf(input_rect.position.x + 6.0 + a_size.x + 1.0, input_rect.end.x - 6.0)
        var cy0 := input_rect.position.y + 4.0
        var cy1 := input_rect.end.y - 4.0
        draw_line(Vector2(cx, cy0), Vector2(cx, cy1), caret_color, 1.0)

    var hint_y := rect.position.y + padding.y + maxf(q_size.y, input_height) + 6.0 + h_size.y
    draw_string(f, Vector2(base_x, hint_y), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(12, font_size - 4)), hint_color)
