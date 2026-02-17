extends Node2D
class_name TargetMathPromptDrawn
## 纯帧绘制的答题提示（无 GUI 控件）：
## - _draw 绘制题目与输入框
## - _unhandled_input 捕获数字/退格/回车/ESC
## - 可选：固定屏幕居中 or 跟随目标位置

signal answered_correct
signal answered_wrong
signal canceled

const QUESTION_PREFIX: String = "射击诸元: "

@export var max_operand: int = 10
@export var y_offset: float = 85.0

@export_group("Layout")
@export var center_on_screen: bool = true
@export var input_width: float = 360.0
@export var input_height: float = 92.0
@export var caret_blink_hz: float = 2.8

@export_group("Style")
@export var font_size: int = 72
@export var hint_font_size: int = 30
@export var padding: Vector2 = Vector2(30.0, 22.0)
@export var corner_radius: float = 18.0

## 提升整体透明度（更不透明、更“实”）
@export var panel_color: Color = Color(0.06, 0.06, 0.08, 0.93)
@export var border_color: Color = Color(1, 1, 1, 0.24)
@export var text_color: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var hint_color: Color = Color(1, 1, 1, 0.68)

## 输入框背景色：提高 alpha 让输入框更明显
@export var input_bg: Color = Color(0.02, 0.02, 0.03, 0.55)
@export var input_border: Color = Color(1, 1, 1, 0.32)
@export var caret_color: Color = Color(1, 1, 1, 0.9)

var _expected: int = 0
var _question: String = ""
var _typed: String = ""

var _active: bool = false
var _target: Node2D = null

var _caret_phase: float = 0.0

var _font: Font = null


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    visible = false
    top_level = true
    set_process(true)
    set_process_unhandled_input(true)

    var df: Font = ThemeDB.fallback_font
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

    if (not center_on_screen) and (not is_instance_valid(_target)):
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
        var k: InputEventKey = event as InputEventKey

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

        var digit: int = _keycode_to_digit(k.keycode)
        if digit != -1:
            if _typed.length() < 6:
                _typed += str(digit)
                queue_redraw()
            get_viewport().set_input_as_handled()
            return


func _submit_if_possible() -> void:
    var s: String = _typed.strip_edges()
    if s.is_empty():
        answered_wrong.emit()
        return

    if not s.is_valid_int():
        _typed = ""
        answered_wrong.emit()
        return

    var v: int = int(s)
    if v == _expected:
        hide_prompt()
        answered_correct.emit()
        return

    _typed = ""
    answered_wrong.emit()


func _update_position() -> void:
    if center_on_screen:
        _update_position_centered()
        return

    _update_position_follow_target()


func _update_position_centered() -> void:
    var vp: Viewport = get_viewport()
    if vp == null:
        return
    global_position = vp.get_visible_rect().get_center()


func _update_position_follow_target() -> void:
    if not is_instance_valid(_target):
        return
    global_position = _target.global_position + Vector2(0.0, -y_offset)


func _generate_question() -> void:
    var a: int = randi_range(0, max_operand)
    var b: int = randi_range(0, max_operand)
    var is_add: bool = (randi() % 2) == 0

    if is_add:
        _expected = a + b
        _question = "%d + %d =" % [a, b]
        return

    if a < b:
        var tmp: int = a
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


func _question_text() -> String:
    return "%s%s" % [QUESTION_PREFIX, _question]


func _draw() -> void:
    if not _active:
        return

    var question: String = _question_text()
    var answer: String = _typed
    var hint: String = "Enter 提交  Esc 取消  Backspace 删除"

    var f: Font = _font
    if f == null:
        return

    var q_fs: int = max(font_size, 12)
    var h_fs: int = max(hint_font_size, 12)

    var q_size: Vector2 = f.get_string_size(question, HORIZONTAL_ALIGNMENT_LEFT, -1, q_fs)
    var h_size: Vector2 = f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, h_fs)

    var panel_w: float = padding.x * 2.0 + q_size.x + 16.0 + input_width
    var panel_h: float = padding.y * 2.0 + maxf(q_size.y, input_height) + 14.0 + h_size.y

    var rect: Rect2 = Rect2(Vector2(-panel_w * 0.5, -panel_h * 0.5), Vector2(panel_w, panel_h))
    _draw_round_rect(rect, corner_radius, panel_color)
    _draw_round_rect(rect, corner_radius, border_color, false, 1.0)

    var base_x: float = rect.position.x + padding.x
    var base_y: float = rect.position.y + padding.y + q_size.y

    draw_string(f, Vector2(base_x, base_y), question, HORIZONTAL_ALIGNMENT_LEFT, -1, q_fs, text_color)

    var input_pos: Vector2 = Vector2(
        base_x + q_size.x + 16.0,
        base_y - q_size.y + (q_size.y - input_height) * 0.5
    )
    var input_rect: Rect2 = Rect2(input_pos, Vector2(input_width, input_height))

    _draw_input_box(input_rect)

    var a_fs: int = q_fs
    var text_inset: Vector2 = Vector2(14.0, (input_height + a_fs) * 0.5 - 6.0)
    var text_origin: Vector2 = input_rect.position + text_inset

    draw_string(f, text_origin, answer, HORIZONTAL_ALIGNMENT_LEFT, input_width - 16.0, a_fs, text_color)

    var caret_on: bool = sin(_caret_phase) > 0.0
    if caret_on:
        var a_size: Vector2 = f.get_string_size(answer, HORIZONTAL_ALIGNMENT_LEFT, -1, a_fs)
        var cx: float = minf(input_rect.position.x + 14.0 + a_size.x + 1.0, input_rect.end.x - 14.0)
        var cy0: float = input_rect.position.y + 10.0
        var cy1: float = input_rect.end.y - 10.0
        draw_line(Vector2(cx, cy0), Vector2(cx, cy1), caret_color, 4.0)

    var hint_y: float = rect.position.y + padding.y + maxf(q_size.y, input_height) + 14.0 + h_size.y
    draw_string(f, Vector2(base_x, hint_y), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, h_fs, hint_color)


func _draw_input_box(input_rect: Rect2) -> void:
    if input_bg.a > 0.001:
        _draw_round_rect(input_rect, 12.0, input_bg)
    _draw_round_rect(input_rect, 12.0, input_border, false, 1.0)


func _draw_round_rect(rect: Rect2, radius: float, color: Color, filled: bool = true, border_width: float = 1.0) -> void:
    radius = maxf(radius, 0.0)

    if radius <= 0.01:
        draw_rect(rect, color, filled, border_width)
        return

    var sb: StyleBoxFlat = StyleBoxFlat.new()
    sb.bg_color = color

    sb.corner_radius_top_left = int(radius)
    sb.corner_radius_top_right = int(radius)
    sb.corner_radius_bottom_left = int(radius)
    sb.corner_radius_bottom_right = int(radius)

    if filled:
        sb.border_width_left = 0
        sb.border_width_top = 0
        sb.border_width_right = 0
        sb.border_width_bottom = 0
    else:
        var w: int = int(maxf(border_width, 1.0))
        sb.border_width_left = w
        sb.border_width_top = w
        sb.border_width_right = w
        sb.border_width_bottom = w
        sb.border_color = color
        sb.bg_color = Color(0, 0, 0, 0)

    draw_style_box(sb, rect)