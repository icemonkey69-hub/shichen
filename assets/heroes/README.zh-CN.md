# 英雄资源目录

这里存放英雄相关的运行时资源。

子目录：
- `sprites/`：角色序列帧、动作图集
- `portraits/`：头像、立绘、小卡面
- `models_3d/`：3D模型预设配置（由战斗视觉编辑器生成）

说明：
- `sprites/` 里的文件名可以直接作为 `model_id`
- 例如 `1004.png` 对应 `model_id = 1004`
- `models_3d/` 里按 ID 建目录，例如 `1001/monster_profile.json`
- 可在编辑器里给配置写中文备注，显示名形如 `1001-小骷髅`
- 统一索引文件：`models_3d/index.json`
