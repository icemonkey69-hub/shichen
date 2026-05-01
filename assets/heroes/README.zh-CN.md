# 英雄与塔资源目录

这里存放战斗运行时直接读取的 2D 单位资源。旧 3D / 三渲二管线已废弃。

## 当前目录

- `Models_2d/`：守护者 2D 动画资源，文件夹名格式为 `<ID>_备注`，ID 对应 `bloodlines.model_id`
- `point_2d/`：塔 2D 动画资源，文件夹名格式为 `<ID>_备注`，ID 对应 `bloodlines.model_id_point`
- `portraits/`：角色选择头像、立绘、小卡面

## 文件夹规则

- 运行时只读取文件夹名前缀 ID，`_` 后文字仅用于备注
- 每个模型文件夹内可放横向序列帧图或单帧图
- 文件名包含 `idle/tower` 作为待机，`run/walk/move` 作为移动，`attack/shoot/melee/cast` 作为攻击，`death/die` 作为死亡
- 没有某类动画时会回落到待机动画
