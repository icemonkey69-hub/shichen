# 3D模型配置目录

此目录用于存放战斗视觉编辑器生成的 3D 怪物/英雄配置。

## 目录约定

- 每个配置一个 ID 文件夹，例如：`1001/`
- 配置文件固定名：`monster_profile.json`
- 汇总索引：`index.json`

## 命名建议

- 建议使用纯数字 ID（如 `1001`、`1002`）
- 可附带中文备注，显示名示例：`1001-小骷髅`

## 来源

- 编辑器场景：`res://combat_visual_editor/model_viewer/model_viewer.tscn`
- 生成按钮会把当前可视化结果直接写入本目录
