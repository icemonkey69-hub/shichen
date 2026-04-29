import os
import sys
import traceback

import bpy


SCENE_EXTS = {".fbx", ".glb", ".gltf"}
ACTION_HINTS = {
    "attack",
    "block",
    "cast",
    "dance",
    "death",
    "die",
    "dodge",
    "fall",
    "hit",
    "hurt",
    "jump",
    "kick",
    "punch",
    "run",
    "shoot",
    "slash",
    "spell",
    "victory",
    "walk",
}


def _clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def _import_source(source_path: str) -> None:
    ext = os.path.splitext(source_path)[1].lower()
    if ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=source_path)
        return
    if ext in {".glb", ".gltf"}:
        bpy.ops.import_scene.gltf(filepath=source_path)
        return
    raise RuntimeError(f"Unsupported source format: {source_path}")


def _strip_scene_to_animation_only() -> None:
    for obj in list(bpy.context.scene.objects):
        if obj.type != "ARMATURE":
            bpy.data.objects.remove(obj, do_unlink=True)

    for datablock_collection in (
        bpy.data.meshes,
        bpy.data.materials,
        bpy.data.images,
        bpy.data.textures,
        bpy.data.lights,
        bpy.data.cameras,
    ):
        for datablock in list(datablock_collection):
            if datablock.users == 0:
                datablock_collection.remove(datablock)


def _export_glb(output_path: str, animation_only: bool) -> None:
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format="GLB",
        export_animations=True,
        export_skins=True,
    )


def convert_one(source_path: str, output_path: str, animation_only: bool) -> None:
    _clear_scene()
    _import_source(source_path)
    if animation_only:
        _strip_scene_to_animation_only()
    _export_glb(output_path, animation_only)


def _sanitize_cache_name(source_path: str) -> str:
    text = source_path.replace("\\", "/")
    result = []
    for char in text:
        if char.isalnum():
            result.append(char)
        else:
            result.append("_")
    name = "".join(result)
    if len(name) > 140:
        name = name[-140:]
    return name


def _is_primary_model(folder: str, source_path: str) -> bool:
    folder_name = os.path.basename(folder).lower()
    base_name = os.path.splitext(os.path.basename(source_path))[0].lower()
    return (
        base_name == f"{folder_name}_benti"
        or base_name.endswith("_benti")
    )


def _looks_like_action_file(source_path: str) -> bool:
    base_name = os.path.splitext(os.path.basename(source_path))[0].lower()
    return any(hint in base_name for hint in ACTION_HINTS)


def _iter_scene_files(root_dir: str):
    for folder, _dirs, files in os.walk(root_dir):
        files.sort()
        for file_name in files:
            if os.path.splitext(file_name)[1].lower() in SCENE_EXTS:
                yield folder, os.path.join(folder, file_name)


def batch_ai_model(root_dir: str, cache_dir: str) -> int:
    root_dir = os.path.abspath(root_dir)
    cache_dir = os.path.abspath(cache_dir)
    if not os.path.isdir(root_dir):
        print(f"AI model directory not found: {root_dir}")
        return 2
    os.makedirs(cache_dir, exist_ok=True)

    converted = 0
    skipped = 0
    failed = 0
    for folder, source_path in _iter_scene_files(root_dir):
        is_primary = _is_primary_model(folder, source_path)
        animation_only = not is_primary
        if is_primary and os.path.splitext(source_path)[1].lower() in {".glb", ".gltf"}:
            skipped += 1
            print(f"[skip main glb] {source_path}")
            continue

        suffix = "_anim" if animation_only else "_full"
        output_path = os.path.join(cache_dir, f"{_sanitize_cache_name(source_path)}{suffix}.glb")
        if os.path.isfile(output_path):
            skipped += 1
            print(f"[cache exists] {output_path}")
            continue

        print(f"[convert {'anim' if animation_only else 'full'}] {source_path}")
        try:
            convert_one(source_path, output_path, animation_only)
            converted += 1
        except Exception:
            failed += 1
            traceback.print_exc()

    print(f"Done. converted={converted}, skipped={skipped}, failed={failed}")
    return 1 if failed > 0 else 0


def main() -> int:
    if "--" not in sys.argv:
        print("Usage: blender --background --python model_viewer_fbx_to_glb.py -- <source> <output.glb> [--animation-only]")
        print("   or: blender --background --python model_viewer_fbx_to_glb.py -- --batch-ai-model <Ai_Model> <F6_Cache>")
        return 2

    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) >= 3 and args[0] == "--batch-ai-model":
        return batch_ai_model(args[1], args[2])

    if len(args) < 2:
        print("Missing source/output arguments.")
        return 2

    source_path = os.path.abspath(args[0])
    output_path = os.path.abspath(args[1])
    animation_only = "--animation-only" in args[2:]
    if not os.path.isfile(source_path):
        print(f"Source file not found: {source_path}")
        return 2

    convert_one(source_path, output_path, animation_only)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        traceback.print_exc()
        raise SystemExit(1)
