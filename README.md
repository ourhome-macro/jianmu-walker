# 《建木行者》Jianmu Walker

一个基于 **Godot 4.x** 的 2D 动作叙事 DEMO 项目。  
本项目围绕“建木（世界核心巨树）”展开，当前目标是完成一段 **12-15 分钟** 的可玩垂直切片。

## 项目亮点

- 动作战斗核心：普攻、闪避、格挡、完美闪避、完美弹反
- 事件驱动流程：教学 -> 小怪 -> BOSS -> 崩塌下坠 -> 结尾收束
- 多风格叙事演出：白域数据空间、废土战场、红域裂口、四界坠落
- 已有完整素材基础：玩家 / 小怪 / BOSS / 特效 / 背景分层

## 故事与流程

玩家在一片数据白域中苏醒，与“建木机器人”建立连接后开始战斗适应训练。  
训练完成后进入废土区域，击败“废土僧侣”，并逐步触发主角的模糊记忆。  
随后切入核心战斗，迎战 BOSS“癫狂的克雷兹”，经历三阶段压迫与反击。  
击败 BOSS 后世界崩塌，主角坠入四个时代的断层场景（桥都 / 石锈镇 / 龙溪 / 烬城）。  
最终镜头拉向星球与建木，留下“建木仍存活”的求救悬念。

## 核心玩法

- 普攻连段：3 段近战攻击
- 闪避：短暂无敌位移
- 格挡：防守减伤
- 完美闪避：命中前约 `150ms` 触发，带时停反馈
- 完美弹反：命中前约 `400ms` 触发，形成高收益反击

## 默认操作（键盘）

- `A` / `←`：向左移动
- `D` / `→`：向右移动
- `W` / `↑` / `Space`：跳跃
- `J` / `Z`：攻击
- `K` / `X`：闪避
- `L` / `C`：格挡
- `Enter`：确认 / 重新开始（结尾）
- `Esc`：暂停菜单

## 快速开始

1. 安装 Godot 4.x（推荐与项目配置一致的 4.6 系列）。
2. 打开 Godot，导入目录：`game/`（即 [project.godot](E:\godot\game\game\project.godot) 所在目录）。
3. 运行主场景：`res://scenes/flow/demo_root.tscn`（已在项目中设为默认启动场景）。

## 项目结构

- `game/`：Godot 工程目录
- `game/scenes/`：场景（流程、角色等）
- `game/scripts/`：核心脚本（flow、actors、ui、core、world）
- `game/autoload/`：全局单例（事件总线、游戏状态、时间控制）
- `game/assets/`：运行时资源（角色、BOSS、背景、音频、特效）
- `game/docs/`：设计与实现文档（战斗规格、事件流、动作映射）
- `player/` `enemy/` `boss/`：原始或中间素材目录（含 `.ase/.aseprite` 与 PNG 源）

## 当前实现状态

- 已串通主流程场景与事件：`tutorial` -> `enemy` -> `boss` -> `collapse` -> `ending`
- 已实现核心角色：`Player` / `EnemyMonk` / `BossKreiz`
- 已接入全局系统：`EventBus`、`GameState`、`TimeDirector`
- 已完成 BOSS 阶段切换、结尾演出与重开流程

## 文档索引

- DEMO 总体设定：[《建木行者》DEMO.md](E:\godot\game\《建木行者》DEMO.md)
- 战斗规格：[combat-spec.md](E:\godot\game\game\docs\combat-spec.md)
- 事件流：[event-flow.md](E:\godot\game\game\docs\event-flow.md)
- 协作规范：[agents.md](E:\godot\game\game\docs\agents.md)
- 动作规划：[action_plan.md](E:\godot\game\game\docs\action_plan.md)

## 已知风险与后续方向

- 部分原始素材仍为 `.ase/.aseprite`，建议统一导出为运行时 PNG 序列
- 个别动作（如 BOSS 抓取等）仍有进一步独立化空间
- 后续可继续推进：
  - 战斗数值调优与手感打磨
  - 调试面板与自动化回归清单
  - 性能与演出质量优化（尤其阶段切换与崩塌段）

