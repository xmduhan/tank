extends RefCounted
class_name DrawUtils

## 画圆角矩形（填充或描边）
## - canvas_item: Node，必须是 CanvasItem（Node2D/Control 等）
## - rect: Rect2
## - fill_color: Color
## - radius: 圆角半径
## - filled: true=填充；false=描边
## - border_width: 描边线宽（filled=false 时生效）
static func draw_round_rect(
        canvas_item: Object,
        rect: Rect2,
        fill_color: Color,
        radius: float = 8.0,
        filled: bool = true,
        border_width: float = 1.0
) -> void:
    if canvas_item == null:
        return
    if not (canvas_item is CanvasItem):
        return

    var ci := canvas_item as CanvasItem
    var r := maxf(0.0, radius)

    # Godot 4: CanvasItem.draw_style_box(style, rect) 可用于圆角矩形绘制
    var sb := StyleBoxFlat.new()
    sb.bg_color = fill_color
    sb.set_corner_radius_all(int(round(r)))

    if filled:
        sb.border_width_left = 0
        sb.border_width_top = 0
        sb.border_width_right = 0
        sb.border_width_bottom = 0
    else:
        var bw:int = max(1, int(round(border_width)))
        sb.bg_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.0)
        sb.border_color = fill_color
        sb.border_width_left = bw
        sb.border_width_top = bw
        sb.border_width_right = bw
        sb.border_width_bottom = bw

    ci.draw_style_box(sb, rect)
