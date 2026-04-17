# UI 图标目录

这里存放界面使用的图标资源。

当前约定的子目录：
- `cards/`：卡牌图标
- `bloodlines/`：血脉图标
- `skills/`：Q / W / R 等技能图标

推荐规范：
- 格式优先 `PNG`，也支持 `WEBP` / `SVG`
- 尽量透明底
- 优先正方形
- 常用尺寸建议 `128x128`

运行时读取规则：
- 如果表里写的是 `res://...`，就直接按完整路径加载
- 如果只写一个名字或数字 ID，就会去对应目录里按同名查找
- 例如 `icon = frost_bloodline` 会查找 `bloodlines/frost_bloodline.png`
