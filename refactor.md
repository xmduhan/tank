# 重构评估（需要，按优先级）

## P0 — 立即修复（防错/早暴露）
1) **修复缩进混用（Tab/Space）导致的潜在语法/风格问题**
   - `scripts/main.gd`：文件前半大量 `\t`，尾部 `_update_radar_loop()` 用空格缩进，存在一致性风险。
   - 目标：全项目统一 4 spaces；启用格式化/检查（至少对 `scripts/*.gd`）。

2) **修复/补全明显缺失方法（运行时必炸）**
   - `scripts/audio/audio_manager.gd`：`ensure()` 调用 `_find_existing_under()`，但该函数未定义为 static（实际是 static，OK），但更关键：`ensure()` 依赖 `SceneTreeUtils`，如果 `host.get_tree()` 为 null 会返回 null（目前有兜底但路径多）。
   - `scripts/main.gd`：调用了 `_wire_targeting_under`/`_walk` 等存在；但 `TargetingComponent` 的 `target_changed` 仅在 `_set_target` 触发，若目标从有效变无效时 `_purge_invalid()` 可能不会正确发射“target=null”的状态（目前会 `_set_target(_nearest())`，但当 nearest 为 null 时会 emit null；需要明确保障）。
   - 目标：对所有 `has_method("get")/call("get_current_target")` 的反射式访问改为强类型 API（见 P1-2）。

## P1 — 结构性重构（DRY/可维护性）
1) **统一“查找当前目标”的接口，移除反射式 get/call**
   - 重复点：`scenes/units/tank/controller.gd`、`scripts/ai/enemy_ai_controller.gd` 中 `_get_current_target/_get_target_in_range`。
   - 建议：在 `TargetingComponent` 提供 `get_current_target()` 明确方法（或只暴露 `current_target` 属性），其他地方强转 `TargetingComponent` 后直接访问。

2) **抽取“生成一次性特效并自动销毁”的公共基类/工具**
   - 重复点：`scenes/effects/spark.gd`、`scenes/effects/explosion.gd` 都有 `_find_particles()` + `create_timer(...).timeout.connect(queue_free)`。
   - 建议：新增 `scripts/utils/one_shot_fx.gd`（基类）或 `FxUtils.play_one_shot_particles(node, delay)`；两个特效脚本仅配置参数。

3) **抽取“在世界节点下生成子节点”的公共方法**
   - 重复点：大量 `var world: Node = SceneTreeUtils.safe_world(...)` + `world.add_child(...)`（Shoot/Death/Audio）。
   - 建议：用 `SceneTreeUtils.add_child_to_world(from_node, child)`（已存在）替换散落逻辑，并统一失败处理（失败就 push_error）。

4) **统一音频参数来源，减少硬编码分散**
   - 当前：`scripts/main.gd`、`scenes/audio/audio_manager.tscn`、`scripts/config/audio_config.gd` 三处分散。
   - 建议：只保留一个“真源”(single source of truth)：例如 `AudioConfig`；`Main._ensure_audio_manager()` 只应用 config；场景 tscn 只提供节点。

## P2 — 逻辑清晰度/边界一致性
1) **暂停策略集中化**
   - 现状：`PauseSnapshot` 暂停树但刻意不暂停 BGM；UI/输入节点设 ALWAYS；但不同脚本各自决定。
   - 建议：定义明确规则：
     - 世界节点：PAUSABLE
     - UI/音频：ALWAYS
     - 只由一个“PauseService”做 begin/end，并明确哪些音轨/loop 不受影响。

2) **将“雷达 loop 仲裁”与 `Main` 解耦**
   - 现状：`Main` 扫描并连接所有 `TargetingComponent.target_changed`，并维护 `_radar_has_target/_radar_is_aiming`。
   - 建议：独立 `RadarAudioController` 节点（ALWAYS），由 Main 挂载；或放入 AudioManager 的一个子模块，Main 只转发 `set_radar_aiming()`。

3) **敌人 AI：时间尺度/平衡参数集中**
   - 现状：`GameBalance` 有 ENEMY_*，但 `EnemyAIController` 又写死 `_move.speed = 50.0`、`fire_cooldown/aim_time` 默认。
   - 建议：EnemyAIController 统一从 `GameBalance` 派生（例如 ready 时乘以倍率），避免双来源。

## P3 — 质量与一致性（低风险收益）
1) **命名/文件组织一致性**
   - `scenes/ui/aim.*` 实际类名 `TargetMathPromptDrawn`，命名不一致。
   - 建议：统一为 `target_math_prompt_drawn.tscn/gd` 或类名改为 `AimPrompt`，减少认知负担。

2) **常量集中与去魔法数**
   - 射击/尾迹/特效/音量等魔法数较多（`ShootComponent`、`BulletTrail`、`Main`）。
   - 建议：把“可调参”集中到 `GameBalance/AudioConfig`，脚本保留默认但优先读配置。

3) **减少重复的“估算半径”实现**
   - `WorldBounds.estimate_body_radius()` 与 `EnemyAIController._estimate_host_radius()` 重复。
   - 建议：EnemyAIController 直接调用 `WorldBounds.estimate_body_radius(_host, NodePath("shape"))`。
