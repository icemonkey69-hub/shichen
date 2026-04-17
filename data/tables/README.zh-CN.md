# data/tables 说明（当前版）

这里是 Godot 运行时真实读取的 JSON 表。

## 数据流
1. 策划维护：`res://英雄战歌2.xlsx`
2. 项目源表：`res://Excel/*.xlsx`
3. 导出脚本：`res://Excel/一键导出JSON.bat`
4. 运行时读取：`res://data/tables/*.json`（`DataTable`）

## 原则
- 运行时不直接读 `xlsx`
- 运行时不直接读 `csv`
- 所有玩法系统统一从本目录读 JSON

## 当前常用表
- `heroes.json`
- `bloodlines.json`
- `projectiles.json`
- `weapons.json`
- `enemies.json`
- `waves.json`
- `cards.json`
- `challenges.json`
- `kill_rewards.json`
- `levelup.json`
- `talents.json`
- `actions.json`（3D非攻击状态动作映射）

## 角色选择界面相关 JSON
- `heroes.json`：模板名称/描述/头像/展示色、`bloodline_ids`（可选血脉ID列表）与 `ban`（禁用开关）
- `bloodlines.json`：血脉主属性、基础战斗属性、Q/W/R 名称描述图标、`skill_group_id/name`、`model_id`、颜色、icon、`ban`（禁用开关）
