# 《建木行者》DEMO 动作推导讨论方案（Godot 版）

> 依据文档：`《建木行者》DEMO.md`、`agents.md`  
> 依据素材：`player/`、`enemy/`、`boss/` 现有目录  
> 目标：`形成 Godot 可执行的动作映射与补资源清单`

---

## 1. Summary

后续动作讨论统一按“以文档目标为准、以现有素材为基础、以 Godot 落地为约束”的原则推进。

本方案输出的不是泛泛而谈的动作设计，而是一份可以直接指导 Godot 实装的映射规范：

- 哪些动作可直接导入 Godot 并生成 `SpriteFrames`
- 哪些动作可通过现有素材复用、判定变化、特效补充落地
- 哪些动作必须补资源，否则会阻塞主流程或严重影响辨识度

---

## 2. Godot 实施基线

### 2.1 动画载体

- 实体基础动作优先使用 `AnimatedSprite2D + SpriteFrames`
- 复杂节点联动、镜头演出、BOSS 大招过程使用 `AnimationPlayer`
- 攻击命中、位移锁定、音效帧、特效帧优先记录在数据层，不写死在脚本 if/else 中

### 2.2 资源来源约束

- `.ase` / `.aseprite` 视为源文件，不作为运行时依赖
- 运行时统一使用：
  - PNG 序列
  - 或已确认切帧规格的图集 PNG
- 命名必须能稳定映射到 Godot 动画名

### 2.3 目标产物

建议最终固定为以下三类产物：

- `res://docs/animation-map.json`
- `res://data/animation/*.tres`
- `res://data/combat/*.tres`

推荐字段：

- `entity`
- `state`
- `animation_name`
- `source_kind`
- `source_path`
- `frame_count`
- `fps`
- `loop`
- `hit_frames`
- `event_frames`
- `notes`

### 2.4 判断标签

- **可直接落地**
  - 现有素材可直接生成 Godot 动画
- **可替代落地**
  - 可通过复用已有动作、判定变化、镜头、滤镜、特效补足
- **必须补充**
  - 缺失独立动作或关键可读性，继续复用会明显损伤体验

---

## 3. 当前素材形态判断

### 3.1 主角 `player/主角zip/`

现有内容：

- `攻击png/`
- `atk 2 png/`
- `带刀奔跑png/`
- `防御png/防御.ase`
- `per 防御 png/`
- `闪避png/闪避.ase`
- `受击png/受击.ase`

判断：

- 主角资源以“拆开的 PNG 序列 + 少量 ase 源文件”为主
- 在 Godot 中最适合直接做成 `SpriteFrames`
- 首要工作不是重做动作，而是把 `.ase` 导出为统一命名的运行时序列

### 3.2 小怪 `enemy/小怪/`

现有内容：

- `Idle.png`
- `Walk.png`
- `Attack_1.png`
- `Attack_2.png`
- `Run+attack.png`
- `Dead.png`

判断：

- 小怪资源更像“单张图集”而不是拆开的多文件序列
- Godot 接入前必须先确认：
  - 单帧尺寸
  - 横向/纵向帧数
  - 是否含空白边
- 在未确认切帧规则前，不应在文档里写死 `hframes` / `vframes`

### 3.3 BOSS `boss/`

现有内容：

- `boss walk png/`
- `boss攻击png/`
- `boss震地png/`
- `boss死亡png/`
- `boss boom! png/`
- `boom特效png/`

判断：

- BOSS 资源已覆盖移动、攻击、震地、死亡、爆炸特效
- 但并未完整覆盖文档里所有技能的独立动作语义
- Godot 落地必须区分“动作帧复用”与“机制表现补足”

---

## 4. 主角动作映射表

| 文档动作 | Godot 动画名 | 当前资源 | 结论 | Godot 落地方式 |
| --- | --- | --- | --- | --- |
| 待机 | `player_idle` | 无独立待机目录 | 可替代落地 | 首版可冻结 `带刀奔跑1` 或防御首帧，后续建议补独立呼吸待机 |
| 移动 | `player_move` | `player/主角zip/带刀奔跑png/` | 可直接落地 | 生成 `SpriteFrames`，循环播放 |
| 轻攻击 1 | `player_attack_light_1` | `player/主角zip/攻击png/` | 可直接落地 | 命中帧记录到 `animation-map.json` |
| 轻攻击 2 | `player_attack_light_2` | `player/主角zip/atk 2 png/` | 可直接落地 | 作为第二段连击 |
| 轻攻击 3 | `player_attack_light_3` | 无独立第三套 | 可替代落地 | 可拆分现有第二段后半段，或对第一段变速复用；需在 `combat-spec` 里明确是否接受 |
| 闪避 | `player_dodge` | `player/主角zip/闪避png/闪避.ase` | 可直接落地 | 先导出为 PNG 序列再导入 Godot |
| 格挡 | `player_guard` | `player/主角zip/防御png/防御.ase` | 可直接落地 | 先导出为 PNG 序列；常驻防御可停在末帧 |
| 完美弹反 | `player_parry_success` | `player/主角zip/per 防御 png/` | 可直接落地 | 用独立动画强化完美弹反反馈 |
| 受击 | `player_hurt` | `player/主角zip/受击png/受击.ase` | 可直接落地 | 先导出为 PNG 序列 |
| 死亡 | `player_dead` | 无 | 可替代落地 | 首版可用 `player_hurt` 末帧 + 黑屏 / 倒地，不应阻塞 DEMO |

主角结论：

- 已具备 DEMO 首版主战斗闭环所需的大部分核心动作
- 主要缺口不是战斗基础动作，而是待机与专用死亡表现
- 如果首版只要求 3 击连段，当前素材可通过 2 套攻击 + 1 套复用落地

---

## 5. 废土僧侣动作映射表

| 文档动作 | Godot 动画名 | 当前资源 | 结论 | Godot 落地方式 |
| --- | --- | --- | --- | --- |
| 待机 | `enemy_idle` | `enemy/小怪/Idle.png` | 可直接落地 | 若为图集，需先确认切帧规格 |
| 追击 | `enemy_chase` | `enemy/小怪/Walk.png` | 可直接落地 | 作为 `CHASE` 循环动画 |
| 攻击 1 | `enemy_attack_1` | `enemy/小怪/Attack_1.png` | 可直接落地 | 近身挥击 |
| 攻击 2 | `enemy_attack_2` | `enemy/小怪/Attack_2.png` | 可直接落地 | 可配合 `Area2D` 与毒雾特效做持续伤害 |
| 扑杀 / 抱擒 | `enemy_attack_lunge` | `enemy/小怪/Run+attack.png` | 可替代落地 | 可承担前扑或突进攻击，不一定单列进首版 FSM |
| 受击 | `enemy_hurt` | 无独立资源 | 可替代落地 | 首版可用闪白 Shader + 短暂停顿 + 当前动作打断 |
| 死亡 | `enemy_dead` | `enemy/小怪/Dead.png` | 可直接落地 | 播放后停末帧或释放崩解特效 |

小怪结论：

- 现有资源足够支撑基础敌人首版闭环
- 最大不确定项是切帧规则，而不是动作种类
- 受击动作缺口可以先用程序反馈补足，不应阻塞 M1

---

## 6. 克雷兹 BOSS 动作映射表

| 文档动作 | Godot 动画名 | 当前资源 | 结论 | Godot 落地方式 |
| --- | --- | --- | --- | --- |
| 待机 | `boss_idle` | 无独立待机目录 | 可替代落地 | 可用走路首帧或攻击前摇首帧静置 |
| 追击 | `boss_chase` | `boss/boss png/boss walk png/` | 可直接落地 | `CHASE` 循环动画 |
| 横扫 | `boss_attack_sweep` | `boss/boss png/boss攻击png/` | 可替代落地 | 作为通用重挥动作使用，命中范围由判定控制 |
| 三连砸 | `boss_attack_slam_3` | `boss/boss png/boss攻击png/` + `boss震地png/` | 可替代落地 | 可用一次挥砸动作循环三次，第三段叠加震地效果 |
| 跳跃砸地 | `boss_attack_jump` | `boss/boss png/boss震地png/` | 可替代落地 | 起跳过程可代码驱动或镜头遮挡，落地段用震地动画承担 |
| 冲锋抓取 | `boss_attack_grab` | 无独立资源 | 必须补充 | 抓取是高辨识动作，长期复用会影响可读性 |
| 癫狂乱舞 | `boss_attack_frenzy` | 无独立资源 | 可替代落地 | 首版可复用普通攻击并叠加红色拖影、加速与震屏 |
| 深红爆发 | `boss_attack_burst` | `boss boom! png/` + `boom特效png/` | 可替代落地 | 动作起手可复用普通攻击或震地，核心由能量环特效完成 |
| 受击 | `boss_hurt` | 无独立资源 | 可替代落地 | 首版可用受击闪白或短停，不要求独立硬直动画 |
| 死亡 | `boss_dead` | `boss/boss png/boss死亡png/` | 可直接落地 | 死亡末段可叠加爆散特效 |

BOSS 结论：

- BOSS 当前资源足以先做出“能打”的版本
- 现阶段最该补的是 `ATTACK_GRAB`，因为它既影响识别，也影响招式差异化
- `ATTACK_BURST` 的成立更多依赖 Godot 特效、时间控制和碰撞逻辑，而不是单独一段动作帧

---

## 7. Godot 实装优先级

1. 先把所有“可直接落地”的动作导入为 `SpriteFrames`
2. 再为每个动作补 `fps`、`loop`、`hit_frames`
3. 再处理“可替代落地”的动作复用方案
4. 最后列出“必须补充”的资源清单并回传美术 / 动画侧

---

## 8. Test Cases

### 8.1 主角

- `player_attack_light_1` 与 `player_attack_light_2` 能否顺利接段
- `player_attack_light_3` 的复用方案是否会让动作阅读混乱
- `player_guard` 是否能承担普通格挡
- `player_parry_success` 是否能明显区分完美弹反
- `player_dodge` 是否只靠机制 + 滤镜 + 时停即可成立

### 8.2 小怪

- `enemy_idle`、`enemy_chase`、`enemy_attack_1` 是否能完整切换
- `enemy_attack_2` 是否适合作为毒雾 / 喷吐判定
- `enemy_attack_lunge` 是否真的需要进首版 FSM，还是留到强化版

### 8.3 BOSS

- `boss_attack_sweep` 与 `boss_attack_slam_3` 复用后是否仍可区分
- `boss_attack_jump` 只用落地段时，玩家是否能看懂前摇
- `boss_attack_burst` 的特效与判定环是否足够支撑阶段 3 核心体验

---

## 9. Assumptions

- 当前讨论只基于仓库中已展开的文件，不假设压缩包里还有关键补充动作
- “可替代落地”允许使用 Godot 的判定、滤镜、震屏、拖影、时停、粒子、能量环补足动作语义
- 下一轮动作讨论应直接产出 `animation-map.json` 草案，而不是继续泛谈剧情
