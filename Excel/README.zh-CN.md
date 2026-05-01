# Excel 源表说明（当前版）

这里维护所有可导出为 `data/tables/*.json` 的正式源表。

## 命名规则
- 文件名格式：`英文结构名#中文名.xlsx`
- 例如：`heroes#英雄.xlsx`、`waves#波次.xlsx`
- 导出脚本只取 `#` 前英文名作为 JSON 文件名。

## 导表流程
1. 修改 `Excel/*.xlsx`
2. 双击 `Excel/一键导出JSON.bat`
3. 检查 `data/tables/*.json`

## 当前正式维护表
- `attributes#属性.xlsx`
- `attribute_formulas#属性公式.xlsx`
- `heroes#英雄.xlsx`
- `bloodlines#血脉.xlsx`
- `projectiles#飞行物.xlsx`
- `weapons#武器.xlsx`
- `weapon_growth#武器成长.xlsx`（局内武器金币成长配置）
- `enemies#怪物.xlsx`
- `waves#波次.xlsx`
- `cards#卡牌.xlsx`
- `challenges#挑战.xlsx`
- `kill_rewards#杀敌奖励.xlsx`
- `levelup#等级.xlsx`
- `talents#局外成长.xlsx`
- `runtime_constants#运行时常量.xlsx`（运行时常量 / 概率 / 冷却参数）

## 角色选择核心主表（优先编辑）
- `heroes#英雄.xlsx`
- `bloodlines#血脉.xlsx`

## 下一阶段优先表
- `weapons#武器.xlsx`
  - 下一阶段用于实现 `MD-03 武器系统` 第一版：局内可花金币成长武器 `剑&盾`
  - 若现有字段不足以表达升级花费、等级、成长曲线、每级效果，可新增独立表，例如 `weapon_growth#武器成长.xlsx`
  - 新增或修改字段后，必须重新执行 `Excel/一键导出JSON.bat` 并检查 `data/tables/*.json`
- `weapon_growth#武器成长.xlsx`
  - 第一版从 `Excel/staging/sword_shield_source.xlsx` 清洗生成
  - 第 1 行为英文运行时字段，第 2 行为类型，第 3 行为中文说明，第 4 行开始为数据
  - `stat_*_value` 已按运行时实际值存储；例如攻击速度 `3` 会导出为 `0.03`

## 已移除的旧表
- `template_bloodline_options#模板血脉选项(角色选择核心).xlsx`

## 已移除的旧方案表（不再维护）
- `weapon_loadouts#武器组合.xlsx`
- `template_weapon_options#模板武器选项.xlsx`

## 角色选择界面相关字段
- `heroes#英雄.xlsx`
- 不再维护 `primary_attr`（主属性已改为由血脉决定）
- 不再维护基础战斗属性（`base_str/base_agi/base_int/base_hp/base_mana/move_speed/attack_damage/attack_interval/attack_range`）
- 不再维护 `model_id`（基础模型改由血脉表提供）
- 不再维护 `preview_model_id`
- 不再维护 `body_color`
- 不再维护 Q/W/R 技能列（已迁移到血脉表）
- 已接入 `portrait_icon`
- 保留 `accent_color`（模板展示色，可用于边框/强调）
- 新增 `bloodline_ids`：逗号分隔血脉 ID 列表（例如 `1,2,5`）
- 新增 `ban`（或 `Ban`）字段：`1/true` 表示禁用模板，运行时不显示
- `bloodlines#血脉.xlsx`
- 新增并维护 `primary_attr`（`str/agi/int`）
- 新增并维护基础战斗属性（`base_str/base_agi/base_int/base_hp/base_mana/move_speed/attack_damage/attack_interval/attack_range`）
- `model_id` 对应守护者 2D 资源：`assets/heroes/Models_2d/<ID>_备注/`
- `model_id_point` 对应塔 2D 资源：`assets/heroes/point_2d/<ID>_备注/`
- 不再维护 `preview_model_id`
- 新增并维护 `q_skill_name / q_skill_description / q_skill_icon`
- 新增并维护 `w_skill_name / w_skill_description / w_skill_icon`
- 新增并维护 `r_skill_name / r_skill_description / r_skill_icon`
- 新增并维护 `skill_group_id / skill_group_name`（汇总信息展示）
- 已新增 `icon`
- 新增 `ban`（或 `Ban`）字段：`1/true` 表示禁用血脉，运行时不显示
- 血脉 icon 读取优先级：`icon` 字段 -> `bloodline.id` -> `bloodline.model_id`
- 图标默认目录：
- 英雄头像：`assets/heroes/portraits/`
- 血脉图标：`assets/ui/icons/bloodlines/`
- 技能图标：`assets/ui/icons/skills/`

## 2D 资源说明
- 3D / 三渲二 / F6 动作表管线已废弃，不再维护 `actions#动作.xlsx`。
- 敌人：怪物表 `enemies.model_id` 对应 `assets/enemies/Models_2d/<ID>_备注/`
- 守护者：血脉表 `bloodlines.model_id` 对应 `assets/heroes/Models_2d/<ID>_备注/`
- 塔：血脉表 `bloodlines.model_id_point` 对应 `assets/heroes/point_2d/<ID>_备注/`
- 文件夹名只用 `_` 前 ID 做匹配，后半段仅作为人工备注。
- 模型文件夹可选添加 `anim_config.json`，用于单独指定动画文件、帧率、帧尺寸、缩放和视觉偏移；没有配置时按文件名自动识别。

## 敌人行为说明
- `enemies#怪物.xlsx` 可新增 `behavior_id` 字段；当前不填也能运行，默认 `melee_chaser`。
- `melee_chaser` 是普通近战追击塔的行为。
- 后续远程怪、Boss、特殊怪优先新增独立行为脚本，再由表里 `behavior_id` 选择，不继续把差异逻辑堆进 `enemy.gd`。
