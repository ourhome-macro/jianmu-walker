- # 《建木行者》DEMO（Godot 版本）

  > 类型：`2D 动作叙事 DEMO`  
  > 引擎：`Godot 4.x`  
  > 目标时长：`12-15 分钟`  
  > 文档用途：`产品流程 + Godot 落地规格`

  ---

  ## 1. DEMO 目标

  本 DEMO 的目标不是做完整长线内容，而是用 Godot 跑通一段可玩的垂直切片，让玩家在 12-15 分钟内体验到：

  - 神秘苏醒与建木机器人引导
  - 主角基础战斗教学
  - 废土僧侣的小规模战斗
  - 癫狂的克雷兹 BOSS 战
  - 世界崩塌与多时代下坠
  - 以标题和悬念收束

  核心体验顺序为：

  **神秘苏醒 → 战斗教学 → 诡异小怪 → BOSS 激战 → 世界崩塌 → 多时代下坠 → 悬念标题**

  ---

  ## 2. 核心玩法信息卡

  ### 2.1 玩家能力

  - 普通攻击：直剑连段，首版目标 3 击
  - 普通闪避：快速位移，带短暂无敌
  - 格挡：减免伤害，消耗资源或进入防守硬直
  - 完美闪避：命中前 `150ms` 闪避，触发时停
  - 完美弹反：命中前 `400ms` 点按格挡，触发高伤反击 / 穿刺

  ### 2.2 Godot 输入映射建议

  - `move_left`
  - `move_right`
  - `move_up`
  - `move_down`
  - `attack`
  - `dodge`
  - `guard`
  - `interact`
  - `confirm`
  - `skip_dialog`
  - `pause`

  ### 2.3 关键实现约束

  - 玩家输入必须统一经由 Godot `InputMap`
  - 判定层与剧情层分离，流程推进依赖事件，不直接硬绑角色脚本
  - 完美闪避的时停建议使用全局时间缩放控制，而不是直接暂停整棵场景树

  ---

  ## 3. 叙事设定与角色对应

  ### 3.1 角色映射

  - 建木机器人：伴随 AI / 教学与剧情引导者
  - 废土僧侣：基础敌人 / 小怪教学战
  - 癫狂的克雷兹：BOSS / DEMO 中段核心战斗

  ### 3.2 核心伏笔

  - 建木 = 神树 = 世界核心
  - 主角过去与 DUGUANG 街头有关
  - 克雷兹遗言“这是开始”
  - 建木在结尾发出求救

  ---

  ## 4. DEMO 主流程（Godot 场景拆分）

  > 场景名仅为建议，后续若改目录，以 `event-flow.md` 为准。

  ### 4.1 苏醒与教学（约 2 分钟）

  #### 剧情内容

  - 冷白闪过，数字符号在纯白空间中穿梭
  - 建木机器人飘至主角肩侧，确认链接成功
  - 玩家看到手中木质剑柄的直剑
  - 建木机器人引导进行攻击、闪避、格挡教学
  - 完美闪避触发时停，世界变为深蓝
  - 完美弹反触发穿刺式反击

  #### Godot 落地建议

  - 主场景建议：`res://scenes/flow/tutorial_room.tscn`
  - 控制器建议：
    - `TutorialController.gd`
    - `DialogueController.gd`
    - `TrainingDummySpawner.gd`
  - 关键节点建议：
    - `Player`
    - `JianmuBot`
    - `PromptLayer`
    - `TutorialMarkers`
    - `Camera2D`
    - `ColorRect`（闪白 / 深蓝滤镜）

  #### 关键事件

  - `flow.tutorial.start`
  - `player.dodge.perfect`
  - `player.parry.perfect`
  - `flow.tutorial.end`

  #### 完成条件

  - 玩家完成一次普通攻击
  - 玩家完成一次闪避
  - 玩家完成一次格挡
  - 玩家至少成功触发一次完美闪避和一次完美弹反

  ---

  ### 4.2 废土僧侣战（约 2 分钟）

  #### 剧情内容

  - 建木机器人生成废土世界怪物
  - 漆黑焦红的人形僧侣现身，胸腔裂开，无面
  - 玩家与其进行第一场正式战斗
  - 击败后僧侣崩解为黑红碎片
  - 对话引出主角过去的模糊记忆

  #### Godot 落地建议

  - 主场景建议：`res://scenes/flow/enemy_arena.tscn`
  - 控制器建议：
    - `EnemyEncounterController.gd`
    - `MemoryFlashController.gd`
  - 关键节点建议：
    - `Player`
    - `EnemySpawner`
    - `JianmuBot`
    - `Camera2D`
    - `HudLayer`

  #### 敌人动作要求

  - 近身挥击
  - 毒雾 / 喷吐类范围攻击
  - 受击与死亡反馈

  #### 关键事件

  - `enemy.spawned`
  - `enemy.hp.zero`
  - `flow.enemy_wave.clear`

  #### 完成条件

  - 玩家击败废土僧侣
  - 记忆闪回正常播放
  - 对话结束后流程推进到 BOSS 场

  ---

  ### 4.3 克雷兹 BOSS 战（约 5 分钟）

  #### 剧情内容

  - 建木机器人遭到干扰并坠地
  - 深红数据光点出现，警报拉响
  - 克雷兹从地面炸裂中登场
  - 玩家进入 DEMO 核心战斗

  #### BOSS 招式目标

  - 钢管三连砸
  - 横扫
  - 冲锋抓取
  - 跳跃砸地
  - 癫狂乱舞（可作为阶段 2 后半段强化表现）
  - 深红爆发（阶段 3 核心演出）

  #### 阶段契约

  - `PHASE_1`: `hp > 60%`
  - `PHASE_2`: `25% < hp <= 60%`
  - `PHASE_3`: `hp <= 25%`

  > “癫狂乱舞”可作为阶段 2 后半段动作选择权重提升，不单独改变阶段阈值。

  #### Godot 落地建议

  - 主场景建议：`res://scenes/flow/boss_arena.tscn`
  - 控制器建议：
    - `BossEncounterController.gd`
    - `BossPhaseController.gd`
    - `BossHudController.gd`
  - 关键节点建议：
    - `BossKreiz`
    - `BossHealthBar`
    - `ArenaTriggers`
    - `Camera2D`
    - `ShakeController`
    - `FxRoot`

  #### 关键事件

  - `flow.boss.start`
  - `boss.phase.enter`
  - `boss.hp.zero`
  - `flow.boss.defeated`

  #### 完成条件

  - BOSS 三阶段都能进入
  - 深红爆发可正常触发，且可配置为允许完美弹反打断
  - 死亡后不锁流程，稳定进入崩塌段

  ---

  ### 4.4 世界崩塌与下坠（约 1 分钟）

  #### 剧情内容

  - 主角拍打失去反应的建木机器人
  - 地面瞬间碎裂，主角开始下坠
  - 背景快速闪过四个时代与同一棵巨树的不同形态
    - 赛博都市
    - 蒸汽之城
    - 废土世界
    - 东方墨乡
  - 建木的声音断续恢复

  #### Godot 落地建议

  - 主场景建议：`res://scenes/flow/collapse_fall.tscn`
  - 表现层建议：
    - `ParallaxBackground`
    - `AnimationPlayer`
    - `Tween`
    - `CanvasLayer`
    - `Camera2D`
    - `AudioStreamPlayer`

  #### 关键事件

  - `flow.collapse.start`
  - `flow.fall.segment_changed`

  #### 完成条件

  - 下坠段可从 BOSS 死亡稳定进入
  - 四段视觉切换顺序正确
  - 建木恢复中的语音 / 文字提示正常播放

  ---

  ### 4.5 标题与悬念（约 20 秒）

  #### 剧情内容

  - 穿出云层，显露蓝绿色星球
  - 某个故事已经在过去悄然结束，从现在开始，就是你将行的道路了。
  - 标题浮现
  - 黑屏后传来机械音：“这是……我们世界的第一次建交……通过建木……”

  #### Godot 落地建议

  - 主场景建议：`res://scenes/flow/demo_ending.tscn`
  - 表现层建议：
    - `AnimationPlayer`
    - `TitleCard`
    - `AudioBus` 渐弱与黑屏控制

  #### 关键事件

  - `flow.demo.end`

  #### 完成条件

  - 标题完整出现
  - 黑屏语音能稳定播放
  - DEMO 结束后可回到标题或结束页

  ---

  ## 5. 系统实现基线（Godot）

  ### 5.1 主循环结构

  - 启动场景建议：`boot.tscn`
  - 运行时总场景建议：`demo_root.tscn`
  - 主流程推荐由一个 `FlowController` 统一管理，而不是把切场逻辑塞进角色脚本

  ### 5.2 玩家战斗系统

  - 主角根节点使用 `CharacterBody2D`
  - 动作播放优先 `AnimatedSprite2D`
  - 攻击判定、受击判定使用 `Area2D`
  - 状态驱动优先显式状态机，不建议在 `_physics_process` 里堆条件分支

  ### 5.3 完美闪避实现建议

  - 使用 `HitStopController` 或等价全局控制器统一管理时停
  - 时停阶段降低 `Engine.time_scale` 到极低值，而非直接置 0
  - UI、剧情恢复计时、必要特效要能选择不受时间缩放影响

  ### 5.4 完美弹反实现建议

  - 格挡输入进入短窗口
  - 在窗口内命中攻击判定则触发 `perfect_parry`
  - 反击可通过：
    - 播放专属动作
    - 强制位移到目标前
    - 触发高伤害与穿刺特效

  ### 5.5 UI 与提示

  - 血条、教学提示、对话、调试信息统一在 `CanvasLayer`
  - 教学提示必须支持出现、消失、完成勾选
  - BOSS 血条与 BOSS 本体之间通过信号同步

  ---

  ## 6. 当前素材对 DEMO 的支撑判断

  ### 6.1 主角

  已有明确素材方向：

  - 攻击
  - 第二套攻击
  - 奔跑
  - 防御
  - 完美防御
  - 闪避
  - 受击

  当前风险：

  - 缺独立待机与死亡资源
  - 部分源文件仍是 `.ase` / `.aseprite`，需要在 Godot 项目落地前统一导出运行时资源

  ### 6.2 废土僧侣

  已有明确素材方向：

  - Idle
  - Walk
  - Attack_1
  - Attack_2
  - Run+attack
  - Dead

  当前风险：

  - 受击表现可能需要补充或用 Shader 闪白替代
  - 单张 PNG 是否为图集仍需切帧确认

  ### 6.3 克雷兹 BOSS

  已有明确素材方向：

  - 行走
  - 普通攻击
  - 震地
  - 死亡
  - 爆炸特效

  当前风险：

  - 抓取、跳跃起手、明确的乱舞独立动作不足
  - 大招需要更多流程演出与特效配合，不是单靠一组动作帧就能成立

  ---

  ## 7. DEMO 完成判定

  以下内容全部满足，才视为 DEMO 主流程完成：

  - 玩家能从开场完整打到结尾
  - 三个核心机制可感知：普攻、完美闪避、完美弹反
  - 小怪与 BOSS 都可稳定击败
  - BOSS 阶段切换、崩塌下坠、标题收束无阻断
  - 关键配置项已进入数据层，不依赖硬编码
  - 文档、事件名、动画名、资源名在 Godot 中保持一致
