# staging 目录说明

这里存放的是从主策划总表 `英雄战歌2.xlsx` 导出的中间层 `xlsx`。

## 这些文件的用途

- 保留主设计稿原始字段和原始语义
- 作为字段映射参考
- 作为整理正式运行时表前的过渡资料

## 当前中间层表

- `heroes_source.xlsx`
- `weapons_source.xlsx`
- `waves_source.xlsx`
- `cards_source.xlsx`
- `kill_rewards_source.xlsx`
- `attributes_source.xlsx`
- `attribute_formulas_source.xlsx`
- `sigils_source.xlsx`
- `sword_shield_source.xlsx`
- `rules_source.xlsx`
- `attribute_questions.xlsx`
- `design_questions.xlsx`
- `attribute_resolution.xlsx`

## 正确用法

1. 先看这里的 `*_source.xlsx`
2. 再对照 `res://Excel/*.xlsx` 标准源表
3. 按字段映射文档做清洗
4. 最后导出到 `res://data/tables/*.json`

## 注意

- 这里不是 Godot 运行时直接读取的目录
- 这里更像“设计中间层”和“确认记录”
