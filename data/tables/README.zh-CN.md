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
- `runtime_constants.json`（运行时常量 / 概率 / 冷却参数）

## 表数据规则
- 运行时不为必填数值字段做静默默认值；缺字段、空值、非法数值应视为数据错误，优先修 Excel 源表并重新导出。
- `waves.total` 必须显式填写数字；`0` 不再表示空值，若需要不限总数，应后续新增明确规则字段。
- `waves.special_spawn_time=0` 且 `waves.special_spawn_count=0` 表示本波没有插刷；有 `special_enemy_id` 时二者必须大于 0。

## 对应源表
- `runtime_constants.json` 来源于 `res://Excel/runtime_constants#运行时常量.xlsx`

## 角色选择界面相关 JSON
- `heroes.json`：模板名称/描述/头像/展示色、`bloodline_ids`（可选血脉ID列表）与 `ban`（禁用开关）
- `bloodlines.json`：血脉主属性、基础战斗属性、Q/W/R 名称描述图标、`skill_group_id/name`、`model_id`、`model_id_point`、颜色、icon、`ban`（禁用开关）
- 怪物表 `enemies.model_id` 对应敌人 2D 资源：`res://assets/enemies/Models_2d/<ID>_备注/`
- 血脉表 `bloodlines.model_id` 对应守护者 2D 资源：`res://assets/heroes/Models_2d/<ID>_备注/`
- 血脉表 `bloodlines.model_id_point` 对应塔 2D 资源：`res://assets/heroes/point_2d/<ID>_备注/`
- `enemies.behavior_id` 对应敌人行为脚本，当前默认 `melee_chaser`；旧表缺失该字段时自动使用默认行为

## 敌人行为字段
- `behavior_id=melee_chaser`：普通近战追击行为，敌人追塔、蓄力、命中、恢复
- 后续远程怪 / Boss / 特殊怪新增行为脚本后，再在 `enemies#怪物.xlsx` 中填对应 ID
- 不建议把所有特殊规则继续写进 `enemy.gd`；`enemy.gd` 只保留通用生命周期

## 2D 动画配置
- 详细规则见 `res://assets/2D单位动画管线.zh-CN.md`
- 每个 2D 模型文件夹可选添加 `anim_config.json`
- 没有 `anim_config.json` 时，仍按文件名关键词自动识别：`idle/tower`、`run/walk/move`、`attack/shoot/melee/cast`、`death/die`
- 有 `anim_config.json` 时，可单独配置动画文件、帧率、循环、帧宽高、显示缩放和视觉偏移
