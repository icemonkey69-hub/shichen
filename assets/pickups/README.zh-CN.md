# 拾取物资产管线

## 资源入口
- 金币：`res://assets/pickups/gold/Gold_Resource_Highlight.png`
- 经验：`res://assets/pickups/exp/Meat_Resource.png`

外部素材先复制到 `assets/pickups/` 后再由场景或脚本引用，不直接引用 `Tiny Swords (Free Pack)` 原始目录。

## 表现规则
- 金币图是横向序列帧，运行时按单帧高度自动切成正方形帧并循环播放。
- 经验图当前是单帧资源。
- 金币和经验都使用 `res://pickup.tscn` / `res://pickup.gd`。

## 玩法规则
- 怪物死亡后生成金币/经验拾取物。
- 拾取物短暂弹开后停留在地面。
- 守护者进入吸附范围后，拾取物才会朝守护者磁吸。
- 拾取到账后，金币/经验仍写入当前局资源和塔的成长体系。
