extends RefCounted
class_name SceneTreeUtils

## 在一些时机（节点未进树/切场景/暂停）get_tree() 可能为 null。
## 这里集中提供“安全 world”选择逻辑，避免到处写重复判断（DRY）。
static func safe_world(from_node: Node) -> Node:
    if from_node == null:
        return null

    var tree := from_node.get_tree()
    if tree != null:
        var cs := tree.current_scene
        if cs != null:
            return cs

    # owner 在实例化场景中通常指向场景根；比 parent 更接近“世界根”
    if from_node.owner != null:
        return from_node.owner

    return from_node.get_parent()


static func add_child_to_world(from_node: Node, child: Node) -> bool:
    if child == null:
        return false

    var world := safe_world(from_node)
    if world == null:
        return false

    world.add_child(child)
    return true
