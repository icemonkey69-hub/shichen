# 血脉图标目录

角色选择界面的血脉按钮会从这里读取 icon。

## 读取优先级
1. `bloodlines.icon`
2. `bloodlines.id`
3. `bloodlines.model_id`

示例：
- 若 `icon = 1001`，会优先查找 `res://assets/ui/icons/bloodlines/1001.png`
- 同名也支持 `webp / jpg / jpeg / svg`

## 建议规格
- 推荐尺寸：`128x128`
- 背景：透明
- 构图：尽量居中，避免贴边
