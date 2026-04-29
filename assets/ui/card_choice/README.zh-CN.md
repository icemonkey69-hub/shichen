# 神权三选一 UI 资源目录

该目录用于存放 `F3` 调试神权三选一界面的正式美术资源。

正式资源尺寸、安全区、拉伸方式见：

- `ASSET_SPEC.zh-CN.md`

卡槽 prefab 场景：

- `res://scenes/ui/神权三选一卡牌.tscn`

## 当前结构

- `backgrounds/`
  - 三选一整屏背景氛围图
- `buttons/`
  - 刷新按钮、功能按钮相关位图资源
- `frames/`
  - 卡框、底板、装饰边框资源
- `icons/`
  - 神权三选一卡牌使用的专用图标资源
- `icons/sample/`
  - 当前用于 UI 演示和调试的样例神权图标
- `icons/generated/`
  - 后续批量生成的正式神权图标建议放这里

## 当前已接入资源

- `backgrounds/god_demon_choice_bg_v1.png`
  - 当前 F3 三选一界面的静态主背景图；运行时不再叠加背景动效
- `frames/tier_1_white.png` ~ `frames/tier_6_red.png`
  - 当前三选一卡面的六阶正式卡框装饰；六阶均为独立设计，不再使用白框换色方案
- `buttons/refresh_button_normal.png`
  - 刷新按钮默认态位图；内容已由新版资源直接覆盖
- `buttons/refresh_button_hover.png`
  - 刷新按钮悬停/高亮态位图；内容已由新版资源直接覆盖
- `buttons/refresh_button_disabled.png`
  - 刷新按钮禁用态位图
- 刷新按钮表现
  - 当前三态图已改为命运齿轮祭坛风格，中心暗色铭牌留给 `刷新` 文字，悬停态增强金光
- 卡牌选中反馈
  - 当前由 `res://assets/shaders/card_choice_selected_highlight.gdshader` 根据卡框透明通道生成边缘高亮、斜向扫光和点击爆闪，不再启用整块蒙版或序列帧
- `icons/sample/titan_heart_icon_v1.png`
  - 当前示例神权 `泰坦心脏` 使用的演示图标

## 接入约定

- `game.gd` 当前会优先读取卡牌表中的 `icon` 字段
- `神权三选一.tscn` 中的 `卡牌一..卡牌九` 均应实例化 `神权三选一卡牌.tscn`
- 如果卡牌表没有填写 `icon`，则会继续走原有的 `assets/ui/icons/cards/`
- 另外保留了一个演示映射：
  - `泰坦心脏 -> res://assets/ui/card_choice/icons/sample/titan_heart_icon_v1.png`

## 后续建议

- 正式量产时，把每张神权的正式图标统一放到：
  - `assets/ui/icons/cards/`
  - 或 `assets/ui/card_choice/icons/generated/`
- 若后续决定把三选一与收藏界面统一使用同一套图标，推荐最终收口到：
  - `assets/ui/icons/cards/`
