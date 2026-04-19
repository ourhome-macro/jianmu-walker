# 《建木行者》DEMO（Godot 4.x）

一个 2D 动作叙事垂直切片项目，目标是在 12-15 分钟内完成“教学 - 战斗 - BOSS - 崩塌 - 收束”的完整体验。

## 项目定位

- 引擎版本：`Godot 4.6`（兼容 Godot 4.x）
- 项目类型：`2D 动作 + 叙事 DEMO`
- 当前主入口：`res://scenes/flow/demo_root.tscn`
- 核心目标：验证主角战斗闭环、BOSS 三阶段与主流程串联可稳定运行

## 故事背景

在文明断代后的近未来，世界被一棵跨越地脉与天空的巨树“建木”维系。建木不仅是神话遗物，更像一台仍在运行的世界级中枢：它记录时代、输送能量，也悄悄改写记忆。

玩家扮演一名失忆的行者，在纯白空间中被“建木机器人”唤醒。机器人声称你与建木存在旧日连接，而这条连接正在被未知干扰撕裂。为了确认自身身份与世界真相，你必须先掌握战斗本能，穿过被污染的废土区域，直面失控个体“癫狂的克雷兹”。

克雷兹并非单纯怪物，而是崩坏链路中的“活体症状”。当他在战斗末段失控，世界结构开始坍塌，玩家坠入多时代重叠的断层景象：赛博都市、蒸汽城、荒原与水乡在同一颗星球上并置闪回。结尾处，建木仅留下一段断续求救：

“建木……还活着……找到……我……”

这段 DEMO 的叙事目标，是让玩家明确三件事：

- 建木是世界核心，不是单纯背景设定
- 主角与建木、与旧时代冲突存在直接关系
- 克雷兹之战只是“开始”，真正威胁来自更深层的系统失控

## 核心体验流程

1. 苏醒引导
2. 战斗教学（攻击 / 闪避 / 格挡）
3. 废土僧侣战
4. 克雷兹 BOSS 战（3 阶段）
5. 世界崩塌下坠
6. 标题与悬念收束

## 运行方式

### 方式 1：Godot 编辑器运行

1. 用 Godot 打开目录 `E:\godot\game\game`
2. 运行项目（F5）

### 方式 2：命令行无头校验

```powershell
godot.exe --headless --path E:\godot\game\game --quit
```

用于快速检查工程配置与脚本加载是否正常。

## 默认键位

项目会在运行时通过 `DemoRoot._ensure_input_map()` 自动补齐输入映射：

- `A` / `←`：左移
- `D` / `→`：右移
- `Space` / `W` / `↑`：跳跃
- `J` / `Z`：攻击
- `K` / `X`：闪避
- `L` / `C`：格挡
- `Enter`：确认
- `Esc`：暂停 / 菜单

## 当前实现范围（MVP）

- 主流程阶段：`tutorial` / `enemy` / `boss` / `collapse` / `ending`
- 已接入主角、基础敌人、BOSS 三类核心战斗角色
- 通过 `EventBus` 串联流程事件与跨系统通信
- 已具备 Windows 导出预设（见 `export_presets.cfg`）

## 关键文档

- `docs/agents.md`：协作规则与工程契约
- `docs/demo_spec.md`：DEMO 目标与分段设计
- `docs/combat-spec.md`：战斗参数与机制约束
- `docs/event-flow.md`：事件流与阶段触发
- `docs/animation-map.json`：动画命名与判定帧映射

## 目录结构（核心）

```text
game/
├─ assets/              # 美术、音频、特效资源
├─ autoload/            # 全局单例（EventBus / GameState / TimeDirector）
├─ scenes/              # 场景资源（flow、actors、ui）
├─ scripts/             # 脚本（actors、flow、ui、core）
├─ docs/                # 规格与协作文档
├─ project.godot        # 工程配置
└─ export_presets.cfg   # 导出配置
```

## 开发约定（摘录）

- 输入统一走 `InputMap`
- 战斗关键数值必须配置化，避免散落硬编码
- 跨场景广播优先走 `EventBus`
- 动画命名、事件命名、资源路径需与 `docs/` 文档一致

## 导出说明

`export_presets.cfg` 已包含 Windows 导出配置，默认目标示例：`build/jianmu_mvp.exe`。

正式导出前建议检查：

- 版本号与产品信息
- 图标与启动画面
- 资源过滤与导出路径
