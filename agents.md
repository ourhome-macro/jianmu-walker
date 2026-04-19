# agents.md

> 适用项目：`《建木行者》DEMO`  
> 适用引擎：`Godot 4.x`  
> 版本：`v1.1`  
> 日期：`2026-04-18`

本文档用于指导《建木行者》DEMO 在 Godot 中的人类开发者与 AI 编码代理协作。目标不是泛化描述玩法，而是把现有剧情稿与动作素材稳定落地为 Godot 4 可运行的 DEMO，并约束后续代码、场景、资源与测试方式。

---

## 1. 开发目标（Godot 程序侧）

### 1.1 里程碑目标

- **M1：核心可玩**
  - 主角可操作：移动、攻击、闪避、格挡
  - 小怪具备完整战斗闭环：索敌、追击、攻击、受击、死亡
- **M2：BOSS 可通关**
  - BOSS 三阶段基础逻辑成立
  - 胜负流程、血条、基础演出可跑通
- **M3：DEMO 全流程串联**
  - 教学 → 小怪 → BOSS → 崩塌下坠 → 标题收束
  - 流程触发点可在 Godot 数据层配置

### 1.2 成功标准

- 在普通 PC 上稳定运行，目标 60 FPS
- 全流程从开场到结尾无阻断性 Bug
- 以下关键机制可在 Godot 场景内验证：
  - 完美闪避触发时停
  - 完美弹反触发反击/穿刺
  - BOSS 在 60% / 25% 阶段切换稳定

---

## 2. 代理协作规则（Human + AI）

### 2.1 角色分工

- **系统代理（System Agent）**
  - 负责状态机、角色控制、判定、数值配置、Autoload、信号总线
- **动画接入代理（Animation Agent）**
  - 负责 PNG 序列或图集导入、`SpriteFrames` 生成、动作命名映射、关键帧标注
- **战斗调参代理（Combat Agent）**
  - 负责前后摇、冷却、伤害、硬直、霸体、判定窗口与打击反馈
- **流程代理（Flow Agent）**
  - 负责关卡触发、剧情节点、过场、UI 提示、场景切换控制
- **QA 代理（QA Agent）**
  - 负责回归清单、复现步骤、日志记录、风险追踪

> 同一任务可由一个代理完成，但提交内容必须覆盖其责任清单。

### 2.2 工作方式（强制）

每次开发任务都按以下结构提交：

1. **输入**：目标功能、关联资源、前置条件
2. **实现**：改动文件列表 + 核心逻辑说明
3. **验证**：最小可复现测试步骤 + 结果
4. **风险**：已知问题、临时方案、后续建议

### 2.3 禁止事项

- 禁止直接改剧情原意来规避 Godot 实现难点
- 禁止未记录情况下硬编码关键战斗数值
- 禁止资源命名混乱，同一动作不得出现多套引擎侧命名
- 禁止提交无法在 Godot 编辑器打开或运行的主分支代码

---

## 3. Godot 工程契约

> 当前仓库还没有完整 Godot 工程骨架，本节作为首版 Godot 规范基线。

### 3.1 目录建议

```text
res://
  docs/
    agents.md
    combat-spec.md
    event-flow.md
    animation-map.json
  assets/
    player/
    enemy/
    boss/
    fx/
    ui/
  scenes/
    actors/
      player/
      enemy/
      boss/
      companion/
    combat/
    flow/
    ui/
    debug/
  scripts/
    actors/
    combat/
    core/
    flow/
    ui/
  data/
    combat/
    animation/
    dialogue/
    flow/
  autoload/
    event_bus.gd
    game_state.gd
    scene_router.gd
    debug_flags.gd
  tests/
```

### 3.2 场景、节点与脚本约定

- 可战斗角色根节点统一使用 `CharacterBody2D`
- 非战斗伴随单位可使用 `Node2D` 或 `CharacterBody2D`
- 可视表现优先使用 `AnimatedSprite2D + SpriteFrames`
- 复杂过场、镜头、特效编排使用 `AnimationPlayer`
- 攻击判定、受击判定、交互判定统一使用 `Area2D`
- HUD 和提示统一挂在 `CanvasLayer`
- 全局事件总线统一由 `autoload/event_bus.gd` 提供

推荐角色子节点结构：

```text
Player.tscn
  Player                    # CharacterBody2D
    Visual                  # AnimatedSprite2D
    Hurtbox                 # Area2D
    HitboxRoot              # Node2D
    Guardbox                # Area2D，可选
    Sensors                 # Node2D
    Timers                  # Node
    Audio                   # Node
```

### 3.3 命名规范

- 场景文件：`snake_case.tscn`
- 脚本文件：`snake_case.gd`
- GDScript 变量、函数、信号、`Resource` 字段：`snake_case`
- 节点名：`PascalCase`
- 状态常量：`UPPER_SNAKE_CASE`
- 动画名：`entity_action_variant`
  - 例：`player_attack_light_1`
  - 例：`boss_attack_burst`
- 全局事件名：`domain.action.result`
  - 例：`boss.phase.enter`

### 3.4 时间与判定单位

- 设计文档与配置资源统一使用 **毫秒 ms**
- Godot API 中的 `Timer.wait_time`、Tween、动画速度使用秒，需要在运行时换算
- 角色移动与判定刷新默认在 `_physics_process(delta)` 中驱动
- 判定窗口、无敌时间、冷却时间必须进入 `Resource` 或配置文件，不得散落在脚本常量里

### 3.5 Autoload 建议

- `EventBus`
  - 负责跨场景信号广播和一次性流程事件派发
- `GameState`
  - 负责当前流程阶段、通关状态、调试开关、Boss 阶段等全局状态
- `SceneRouter`
  - 负责 DEMO 主流程场景切换与异步加载
- `DebugFlags`
  - 负责无敌、跳关、锁血、显示碰撞框等开发期开关

---

## 4. 实体行为规范（Godot FSM 契约）

## 4.1 主角 Player

### 必备状态

- `IDLE`
- `MOVE`
- `ATTACK_LIGHT_CHAIN`
- `DODGE`
- `GUARD`
- `PARRY_SUCCESS`
- `HURT`
- `DEAD`

### 推荐场景职责

- `Player.gd`
  - 负责输入读取、朝向、位移、状态切换
- `PlayerCombat.gd`
  - 负责攻击段、命中窗口、受击、霸体、完美判定
- `AnimatedSprite2D`
  - 负责基础动作播放
- `AnimationPlayer`（可选）
  - 负责复合特效、镜头震动、特殊演出

### 初版参数（Godot 数据层）

- `perfect_dodge_window_ms`: `150`
- `perfect_parry_window_ms`: `400`
- `invincible_ms_on_dodge`: `200`
- `time_stop_ms_on_perfect_dodge`: `2000`

### 本地信号建议

- `perfect_dodge`
- `perfect_parry`
- `attack_hit`
- `hp_zero`

### 对外全局事件

- `player.dodge.perfect`
- `player.parry.perfect`
- `player.attack.hit`
- `player.hp.zero`

### 实现约束

- 输入统一走 Godot `InputMap`
- 完美闪避建议通过全局时停控制器降低 `Engine.time_scale`，不要直接依赖 `get_tree().paused`
- 命中帧优先通过 `AnimatedSprite2D.frame_changed` 或 `AnimationPlayer` 事件轨驱动
- 无敌帧必须显式可视化到调试面板

---

## 4.2 废土僧侣 Enemy（基础敌人）

### 必备状态

- `IDLE`
- `CHASE`
- `ATTACK_1`
- `ATTACK_2`
- `HURT`
- `DEAD`

### 初版数值（可配置）

- `hp`: `80`
- `move_speed`: `80`
- `detect_range`: `400`
- `attack_range`: `60`
- `disengage_range`: `600`
- `attack_cooldown_ms`: `1500`
- `hurt_stun_ms`: `400`

### Godot 实现备注

- 索敌范围优先用 `Area2D` 或距离检查实现，二选一即可，不要双重逻辑冲突
- 追击位移走 `_physics_process(delta)` 与 `move_and_slide()`
- `ATTACK_1` 与 `ATTACK_2` 交替释放
- `ATTACK_2` 可由持续伤害 `Area2D` + 毒雾特效模拟
- `HURT` 若没有独立素材，可先用闪白 Shader + 短暂停顿替代，但必须在风险里记录

---

## 4.3 BOSS：癫狂的克雷兹

### 必备状态

- `IDLE`
- `CHASE`
- `ATTACK_SLAM_3`
- `ATTACK_SWEEP`
- `ATTACK_JUMP`
- `ATTACK_GRAB`
- `ATTACK_BURST`
- `HURT`
- `DEAD`

### 可选强化状态

- `ATTACK_FRENZY`
  - 属于阶段 2 后半段或阶段 3 的强化动作
  - 若素材不足，可先用现有攻击资源复用实现，不单独阻塞主流程

### 阶段阈值

- `PHASE_1`: `hp > 60%`
- `PHASE_2`: `25% < hp <= 60%`
- `PHASE_3`: `hp <= 25%`

### 关键约束

- 阶段切换必须触发一次性全局事件：`boss.phase.enter`
- `ATTACK_BURST` 必须支持“可被完美弹反打断”的配置开关
- `DEAD` 必须与特效播放、流程推进、场景切换解耦
- BOSS 的攻击选择与阶段逻辑放在同一控制器中，不要把阶段切换写散到多个脚本

### Godot 实现备注

- BOSS 场景建议拆成：
  - `BossKreiz.gd`
  - `BossBrain.gd`
  - `BossCombat.gd`
  - `BossPhaseController.gd`
- 血条 UI 与 BOSS 本体通过信号连接，不要让 UI 反向查询 BOSS 内部字段
- 大招与阶段演出优先通过 `AnimationPlayer`、`Camera2D`、`GPUParticles2D` 协同实现

---

## 4.4 建木机器人（伴随 AI）

### 必备状态

- `IDLE`
- `SPEAKING`
- `WARNING`
- `DISABLED`

### 关键功能

- 对话队列：支持打字机效果、跳过、回调
- 跟随插值：平滑位置与朝向，不参与战斗碰撞
- 剧情强制失效：BOSS 入侵后切到 `DISABLED`

### Godot 实现备注

- 对话建议拆为：
  - `DialogueController` 管文本队列
  - `JianmuBot` 管状态与视觉表现
- 跟随运动可使用 `lerp` / `move_toward`
- 对话气泡、提示文本挂在 `CanvasLayer` 或角色头顶 UI 节点，避免混进战斗逻辑脚本

---

## 5. 资源接入规范（Godot 导入基线）

### 5.1 当前已知素材目录

- `boss/`
- `enemy/`
- `player/`

### 5.2 导入原则

- 运行时资源优先使用 PNG 序列或图集，不依赖 `.ase` / `.aseprite` 源文件直接运行
- 同一动作的帧必须能被自然数字顺序读取，禁止出现 `1,10,11,2` 的导入歧义
- `AnimatedSprite2D` 负责基础帧动画，复杂节点联动交给 `AnimationPlayer`
- 每个动作至少标注：
  - 起手关键帧
  - 命中关键帧
  - 收招关键帧
  - 是否循环
  - 推荐播放 FPS

### 5.3 命名映射文件（建议必须有）

建议新增：`res://docs/animation-map.json`

字段示例：

- `entity`
- `state`
- `animation_name`
- `source_kind`
  - `sequence`
  - `spritesheet`
- `source_path`
- `frame_count`
- `fps`
- `loop`
- `hit_frames`
- `event_frames`
- `notes`

### 5.4 资源导入补充约束

- 小怪如果是单张图集，必须记录切帧尺寸，不要只写文件名
- 战斗相关动画命中窗口不能只记在脑子里，必须进入 `animation-map.json` 或对应 `Resource`
- 资源重命名后必须同步更新文档和 Godot 引用路径

---

## 6. 流程触发与信号总线

### 6.1 主流程事件（最小集）

- `flow.tutorial.start`
- `flow.tutorial.end`
- `flow.enemy_wave.clear`
- `flow.boss.start`
- `flow.boss.defeated`
- `flow.collapse.start`
- `flow.demo.end`

### 6.2 Godot 事件设计原则

- 本地系统之间优先用 Godot `signal`
- 跨场景、跨系统广播再走 `EventBus`
- 事件只描述“发生了什么”，不写“谁来处理”
- 一次性事件必须在 `EventBus` 或 `GameState` 中去重

---

## 7. 调试与测试要求

### 7.1 调试面板（开发期强制）

建议独立场景：`res://scenes/debug/debug_overlay.tscn`

实时显示：

- 当前状态
- 当前动画名 / 当前帧
- HP / Stamina
- 当前无敌剩余时间
- 完美判定窗口倒计时
- 当前流程事件

### 7.2 回归测试最小清单

- 主角可完成 3 击连段，且不会丢段
- 完美闪避触发时停并自动恢复
- 完美弹反可触发高伤反击
- 小怪在索敌/脱战边界不抖动
- BOSS 在 60% / 25% 阶段切换稳定
- BOSS 死亡后流程可进入崩塌段

### 7.3 Bug 记录模板

- `标题`
- `复现步骤`
- `期望结果`
- `实际结果`
- `出现频率`
- `日志/截图`
- `责任模块`

---

## 8. 开发优先级（建议）

1. 主角基础战斗闭环：输入 → 动画 → 判定 → 反馈
2. 小怪 AI + 战斗闭环
3. BOSS 单阶段可打通
4. BOSS 三阶段与演出
5. 完美闪避 / 弹反手感调优
6. 全流程串联与性能优化

---

## 9. Definition of Done（DoD）

一个功能仅在满足以下全部条件时视为完成：

- Godot 项目可运行，无阻断性错误
- 关键配置项可在数据层调整
- 至少 1 条正常路径 + 1 条边界路径验证通过
- 已补充必要文档：状态、参数、事件、限制
- 不破坏既有流程，且完成回归验证

---

## 10. 下一步建议（落地文档）

建议在本文件基础上继续新增三份 Godot 子文档：

- `res://docs/combat-spec.md`
- `res://docs/event-flow.md`
- `res://docs/animation-map.json`

若后续规则冲突，优先级为：

`combat-spec` > `event-flow` > `animation-map` > `agents`
