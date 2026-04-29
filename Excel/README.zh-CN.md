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
- `actions#动作.xlsx`（模型行为动作映射；行为树状态 -> F6 动作文件名）

## 动作表说明
- `actions#动作.xlsx` 用于配置每个 `model_id` 在行为状态下播放哪个 F6 动作文件名。
- 动作名建议直接填写 F6 下拉里看到的文件名，例如 `sishuang_run`、`sishuang_jump`、`sishuang_death`。
- `jump` 现在按完整动作配置，不再拆 `jump_1/jump_2/jump_3`。
- `default_fps`：该模型动作默认 FPS，用于把帧号换算成秒；空白默认 30。
- `<状态>_start_frame / <状态>_end_frame`：动作裁剪区间，用于跳过 AI 动作文件前后多余帧；目前已接入 `idle/move/attack/death/jump`，空白表示不裁剪。
- `jump_start_frame / jump_end_frame / jump_fps`：跳跃动作专用裁剪与 FPS；例如完整跳跃前面有跑动帧时，可把 `jump_start_frame` 填到真正起跳前一帧附近。
- `jump_ignore_collision_frame`：跳跃动作播放到这一帧后开始无视碰撞盒；空白则沿用旧流程，起跳立即关闭碰撞。
- `jump_land_frame`：跳跃动作播放到这一帧视为落地并恢复碰撞；空白则沿用旧流程，跳跃结束恢复碰撞。
- `death_loop` 通常填 `FALSE`，死亡动作不循环；`idle_loop/move_loop/stun_loop` 通常填 `TRUE`。

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
- `model_id` 作为预览与战斗统一 3D 配置来源，对应 `assets/heroes/models_3d/index.json`
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

## 3D 资源说明
- 当前使用 F6 3D 模型配置管线，不再维护 2D 像素序列帧管线。
- 角色与怪物的 `model_id` 统一对接 `assets/heroes/models_3d/index.json`。
- 新增角色或怪物时，先把白模和动作放入 `E:/Godot/model_3D/Ai_Model/<角色文件夹>/`，在 F6 生成对应 ID 配置。
