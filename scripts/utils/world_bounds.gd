extends RefCounted
class_name WorldBounds

## 获取当前视口在世界坐标系下的可见矩形（Canvas/2D）。
## 说明：
## - 适用于 Node2D/CharacterBody2D 等 2D 场景
## - Godot 4: get_canvas_transform().affine_inverse() 可将屏幕坐标转到世界坐标
static func get_visible_world_rect(viewport: Viewport) -> Rect2:
    if viewport == null:
        return Rect2()

    var canvas_xform_inv: Transform2D = viewport.get_canvas_transform().affine_inverse()
    var size: Vector2 = viewport.get_visible_rect().size

    var p0: Vector2 = canvas_xform_inv * Vector2(0.0, 0.0)
    var p1: Vector2 = canvas_xform_inv * Vector2(size.x, 0.0)
    var p2: Vector2 = canvas_xform_inv * Vector2(0.0, size.y)
    var p3: Vector2 = canvas_xform_inv * Vector2(size.x, size.y)

    var min_x := minf(minf(p0.x, p1.x), minf(p2.x, p3.x))
    var max_x := maxf(maxf(p0.x, p1.x), maxf(p2.x, p3.x))
    var min_y := minf(minf(p0.y, p1.y), minf(p2.y, p3.y))
    var max_y := maxf(maxf(p0.y, p1.y), maxf(p2.y, p3.y))

    return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


## 收缩 rect（向内缩 margin），margin 可以是 Vector2(左右,上下)
static func inset_rect(rect: Rect2, margin: Vector2) -> Rect2:
    var m := Vector2(maxf(margin.x, 0.0), maxf(margin.y, 0.0))
    var out := Rect2(rect.position + m, rect.size - m * 2.0)
    if out.size.x < 1.0:
        out.size.x = 1.0
    if out.size.y < 1.0:
        out.size.y = 1.0
    return out


static func clamp_point_to_rect(p: Vector2, rect: Rect2) -> Vector2:
    return Vector2(
        clampf(p.x, rect.position.x, rect.end.x),
        clampf(p.y, rect.position.y, rect.end.y)
    )
