extends Node
class_name PauseSnapshot
## 统一暂停/恢复工具：
## - begin(): 记录当前 paused 状态，并将 SceneTree.paused 设为 true
## - end(): 恢复到 begin() 之前的 paused 状态
##
## 设计目标：
## - UI 弹窗出现时暂停世界
## - UI 自身可用 PROCESS_MODE_ALWAYS 继续收输入/绘制
## - 允许嵌套调用 begin()/end()（引用计数）

var _depth: int = 0
var _paused_before: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func begin() -> void:
    var tree: SceneTree = get_tree()
    if tree == null:
        return

    if _depth == 0:
        _paused_before = tree.paused
        tree.paused = true

    _depth += 1


func end() -> void:
    var tree: SceneTree = get_tree()
    if tree == null:
        return

    if _depth <= 0:
        _depth = 0
        return

    _depth -= 1
    if _depth == 0:
        tree.paused = _paused_before


func reset() -> void:
    _depth = 0
    var tree: SceneTree = get_tree()
    if tree != null:
        tree.paused = _paused_before