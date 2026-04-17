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
- `enemies#怪物.xlsx`
- `waves#波次.xlsx`
- `cards#卡牌.xlsx`
- `challenges#挑战.xlsx`
- `kill_rewards#杀敌奖励.xlsx`
- `levelup#等级.xlsx`
- `talents#局外成长.xlsx`
- `actions#动作.xlsx`（3D非攻击状态动作映射）

## 角色选择核心主表（优先编辑）
- `heroes#英雄.xlsx`
- `bloodlines#血脉.xlsx`

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
- `model_id` 作为预览与战斗统一模型来源
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

## 3D动作表说明（actions）
- 导出目标：`data/tables/actions.json`
- 关键字段：
- `model_id`：对应 `assets/heroes/models_3d/index.json` 的 `profile_id`
- `idle/move/hit/stun/death/spawn/victory`：填写动作名字符串
- 攻击动作不在本表维护，仍由 `index.json.attack_plan` 负责。
- 动作字符串语法（运行时已支持）：
- 多动作随机：`idle_1, idle_2`（也支持 `|`、`和`、`与`）
- 串播序列：`death_1_1 > death_1_2`
- `death` 字段若填多个动作且未写 `>`，默认按“串播循环”处理
- 编号列写法（同样支持）：
- 待机随机：`idle_1`、`idle_2`（会合并成随机池）
- 死亡串播：`death_1_1`、`death_1_2`（按编号顺序串播循环）
