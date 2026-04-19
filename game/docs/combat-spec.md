# 《建木行者》MVP Combat Spec

## 1. 输入

- `move_left`: `A` / `←`
- `move_right`: `D` / `→`
- `attack`: `J` / `Z`
- `dodge`: `K` / `X`
- `guard`: `L` / `C`
- `confirm`: `Enter` / `Space`
- `pause / restart`: `R`

## 2. 玩家

- 角色：`res://scenes/actors/player/player.tscn`
- 核心状态：`IDLE` `MOVE` `ATTACK` `DODGE` `GUARD` `PARRY` `HURT` `DEAD`
- 关键参数：
  - `max_hp`: `140`
  - `move_speed`: `245`
  - `dodge_speed`: `560`
  - `perfect_dodge_window_ms`: `150`
  - `perfect_parry_window_ms`: `400`
  - `invincible_ms_on_dodge`: `220`
- 连段：
  - `attack_1`: 轻斩，命中帧 `2-3`
  - `attack_2`: 前压二段，命中帧 `3-5`
  - `attack_3`: 复用第二套素材并提速，命中帧 `2-4`
- 缺失素材的处理：
  - `闪避`：用奔跑帧 + 残影 + 蓝白闪光补足
  - `常驻格挡`：用完美防御前 4 帧拆为 `guard_raise` / `guard_hold`
  - `受击`：用短停顿、染色和击退替代独立帧

## 3. 废土僧侣

- 角色：`res://scenes/actors/enemy/enemy_monk.tscn`
- 核心状态：`IDLE` `CHASE` `ATTACK` `HURT` `DEAD`
- 参数：
  - `max_hp`: `80`
  - `move_speed`: `86`
  - `detect_range`: `420`
  - `attack_range`: `86`
  - `attack_cooldown_ms`: `1500`
- 攻击：
  - `attack_1`: 近身挥击，命中帧 `1-2`
  - `attack_2`: 前压挥击，命中帧 `1-2`
- 完美弹反反馈：
  - 直接进入长硬直并承受额外 `28` 点伤害

## 4. 克雷兹

- 角色：`res://scenes/actors/boss/boss_kreiz.tscn`
- 核心状态：`IDLE` `CHASE` `SWEEP` `SLAM` `JUMP` `GRAB` `BURST` `STUN` `HURT` `DEAD`
- 参数：
  - `max_hp`: `320`
  - `move_speed`: `92`
  - `attack_range`: `136`
  - `detect_range`: `560`
  - `attack_cooldown_ms`: `1100`
- 阶段：
  - `Phase 1`: `hp > 60%`
  - `Phase 2`: `25% < hp <= 60%`
  - `Phase 3`: `hp <= 25%`
- 招式：
  - `sweep`: 横扫，命中帧 `3-4`
  - `slam`: 震地三连，命中帧 `8 / 12 / 16`
  - `jump`: 跳跃砸地，落地接 `slam`
  - `grab`: 冲刺抓取，命中帧 `2-4`
  - `burst`: 深红爆发，命中帧 `4-5`，允许完美弹反打断

## 5. 视觉反馈

- 时停：`TimeDirector.request_hit_stop`
- 屏闪：`TimeDirector.request_flash`
- 震屏：`TimeDirector.request_shake`
- 程序化补偿原则：
  - 没有独立动作帧时，优先补 `残影 / 屏闪 / 震屏 / FX`
  - 不用纯色方块或临时占位替代关键战斗演出

