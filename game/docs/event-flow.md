# 《建木行者》MVP Event Flow

## 流程顺序

1. `tutorial`
   - 建木唤醒玩家
   - 完成攻击 / 闪避 / 格挡
   - 用训练斩击完成一次完美闪避和一次完美弹反
2. `enemy`
   - 生成废土僧侣
   - 玩家击败僧侣
3. `boss`
   - 切入克雷兹战
   - BOSS 依次进入 3 个阶段
4. `collapse`
   - BOSS 死亡
   - 背景切换四个时代的断层坠落
5. `ending`
   - 星球与建木显露
   - 标题与求救讯号收束

## 当前事件

- `flow.tutorial.end`
- `enemy.spawned`
- `enemy.hp.zero`
- `flow.enemy_wave.clear`
- `flow.boss.start`
- `boss.phase.enter`
- `boss.hp.zero`
- `flow.boss.defeated`
- `flow.collapse.start`
- `flow.demo.end`
- `player.attack.hit`
- `player.dodge.perfect`
- `player.parry.perfect`
- `player.hp.zero`

## 事件来源

- `Player`
  - 普攻命中
  - 完美闪避
  - 完美弹反
  - 死亡
- `EnemyMonk`
  - 死亡
- `BossKreiz`
  - 阶段切换
  - 死亡
- `DemoRoot`
  - 教学完成
  - 小怪战完成
  - BOSS 战开始 / 完成
  - 崩塌开始
  - DEMO 结束

## 事件去重

- `boss.phase.enter` 通过 `EventBus.emit_game_event(..., once_key)` 去重
- `flow` 级事件在 `DemoRoot` 里只触发一次

