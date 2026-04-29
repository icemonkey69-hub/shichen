# 3D 模型预览器（F6）

这是独立预览工具，不接入主场景启动流程。打开 `res://combat_visual_editor/model_viewer/model_viewer.tscn` 后按 F6 运行当前场景。

## 新资源管线

- 人物与动作目录：`E:/Godot/model_3D/Ai_Model`
- 武器目录：`E:/Godot/model_3D/Ai_weapons`
- 配置输出目录：`res://assets/heroes/models_3d/`

每个白模/角色使用一个独立文件夹，例如：

```text
E:/Godot/model_3D/Ai_Model/Knight_A/
  Knight_A_benti.glb
  Knight_A_Idle.glb
  Knight_A_Run.fbx
  Knight_A_Attack_01.glb
```

本体规则只认 `*_benti.glb` / `*_benti.fbx`。同文件夹内其他 GLB/GLTF/FBX 都是动作文件，包括 `*_Idle`。

武器模型放入：

```text
E:/Godot/model_3D/Ai_weapons/
```

武器支持 GLB/GLTF/FBX，预期为无动作、无骨骼模型。F6 可选择左右手武器，并保存左右手位移、旋转、缩放微调。

## FBX 支持

Godot 预览时会通过 `E:/Blender/blender.exe` 临时把 FBX 转成 GLB，缓存到 `E:/Godot/model_3D/F6_Cache`。模型改动后如果预览没刷新，删除该缓存目录即可重新转换。

也可以手动运行：

```text
E:/Godot/model_3D/一键处理F6模型资源.bat
```

它会预先处理 `E:/Godot/model_3D/Ai_Model`，把非本体动作文件转成轻量 animation-only GLB 缓存，减少 F6 首次打开时的等待。

## 保存内容

点击“生成配置”会写入：

- `res://assets/heroes/models_3d/<ID>/monster_profile.json`
- `res://assets/heroes/models_3d/index.json`

配置会记录角色路径、左右手武器路径、动作名、体型缩放、武器微调、攻击编排和命中帧，后续游戏运行时可按 ID 读取使用。
