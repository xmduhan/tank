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


## 估算 CharacterBody2D 的“半径”（用于边界收缩，避免碰撞体出屏幕）
static func estimate_body_radius(body: Node2D, shape_node_path: NodePath = NodePath("shape"), fallback: float = 34.0) -> float:
    if body == null:
        return fallback

    var shape_node := body.get_node_or_null(shape_node_path) as CollisionShape2D
    if shape_node == null or shape_node.shape == null:
        return fallback

    var s := shape_node.shape
    if s is CircleShape2D:
        return (s as CircleShape2D).radius
    if s is RectangleShape2D:
        var ext := (s as RectangleShape2D).size * 0.5
        return maxf(ext.x, ext.y)

    return fallback


## 将 body 的 global_position 夹紧到“当前可见世界矩形（考虑 margin + 碰撞半径）”内
static func clamp_body_to_visible_rect(
    body: CharacterBody2D,
    viewport: Viewport,
    screen_margin: float = 18.0,
    shape_node_path: NodePath = NodePath("shape"),
    fallback_radius: float = 34.0
) -> void:
    if body == null or viewport == null:
        return

    var visible := get_visible_world_rect(viewport)
    if visible.size.length() <= 1.0:
        return

    var r := estimate_body_radius(body, shape_node_path, fallback_radius)
    var m := maxf(screen_margin, 0.0) + maxf(r, 0.0)
    var bounds := inset_rect(visible, Vector2(m, m))

    body.global_position = clamp_point_to_rect(body.global_position, bounds)