import argparse
import os
import sys
import traceback

import bpy


SCENE_EXTS = {".fbx", ".glb", ".gltf"}


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


def _mesh_objects():
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def _triangle_count() -> int:
    total = 0
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for obj in _mesh_objects():
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        try:
            total += sum(len(poly.vertices) - 2 for poly in mesh.polygons)
        finally:
            evaluated.to_mesh_clear()
    return total


def _decimate_meshes(ratio: float, target_triangles: int) -> None:
    before = max(_triangle_count(), 1)
    if target_triangles > 0:
        ratio = min(ratio, max(0.01, float(target_triangles) / float(before)))
    ratio = max(0.01, min(float(ratio), 1.0))
    if ratio >= 0.999:
        return

    for obj in _mesh_objects():
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        modifier = obj.modifiers.new(name="Codex_Decimate", type="DECIMATE")
        modifier.ratio = ratio
        modifier.use_collapse_triangulate = True
        try:
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        except Exception:
            print(f"[warn] modifier_apply failed, leaving modifier for export: {obj.name}")
        obj.select_set(False)


def _export_glb(output_path: str) -> None:
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format="GLB",
        export_animations=True,
        export_skins=True,
        export_apply=True,
    )


def reduce_one(source_path: str, output_path: str, ratio: float, target_triangles: int) -> None:
    _clear_scene()
    _import_source(source_path)
    before = _triangle_count()
    _decimate_meshes(ratio, target_triangles)
    after = _triangle_count()
    _export_glb(output_path)
    print(f"[ok] {source_path}")
    print(f"     triangles: {before} -> {after}")
    print(f"     output: {output_path}")


def _iter_scene_files(root_dir: str):
    for folder, _dirs, files in os.walk(root_dir):
        files.sort()
        for file_name in files:
            base_name = os.path.splitext(file_name)[0].lower()
            if base_name.endswith("_low") or "_low_" in base_name:
                continue
            if os.path.splitext(file_name)[1].lower() in SCENE_EXTS:
                yield os.path.join(folder, file_name)


def _default_output_path(source_path: str, suffix: str) -> str:
    folder = os.path.dirname(source_path)
    base = os.path.splitext(os.path.basename(source_path))[0]
    if base.lower().endswith("_benti"):
        base = f"{base[:-6]}{suffix}_benti"
        return os.path.join(folder, f"{base}.glb")
    return os.path.join(folder, f"{base}{suffix}.glb")


def _batch(root_dir: str, ratio: float, target_triangles: int, suffix: str, only_benti: bool) -> int:
    converted = 0
    skipped = 0
    failed = 0
    for source_path in _iter_scene_files(root_dir):
        base = os.path.splitext(os.path.basename(source_path))[0].lower()
        if only_benti and not base.endswith("_benti"):
            skipped += 1
            continue
        output_path = _default_output_path(source_path, suffix)
        if os.path.abspath(output_path) == os.path.abspath(source_path):
            skipped += 1
            continue
        try:
            reduce_one(source_path, output_path, ratio, target_triangles)
            converted += 1
        except Exception:
            failed += 1
            traceback.print_exc()
    print(f"Done. converted={converted}, skipped={skipped}, failed={failed}")
    return 1 if failed else 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Reduce GLB/FBX mesh triangles with Blender decimate.")
    parser.add_argument("source", help="Source file or directory.")
    parser.add_argument("--output", default="", help="Output GLB path for a single source file.")
    parser.add_argument("--ratio", type=float, default=0.25, help="Decimate ratio. 0.25 keeps roughly 25%%.")
    parser.add_argument("--target-triangles", type=int, default=0, help="Optional max target triangle count.")
    parser.add_argument("--suffix", default="_low", help="Output suffix for batch/default output.")
    parser.add_argument("--batch", action="store_true", help="Treat source as a directory.")
    parser.add_argument("--only-benti", action="store_true", help="Batch only *_benti model files.")
    args = parser.parse_args(argv)

    source = os.path.abspath(args.source)
    if args.batch:
        if not os.path.isdir(source):
            print(f"Directory not found: {source}")
            return 2
        return _batch(source, args.ratio, args.target_triangles, args.suffix, args.only_benti)

    if not os.path.isfile(source):
        print(f"Source file not found: {source}")
        return 2
    output = os.path.abspath(args.output) if args.output else _default_output_path(source, args.suffix)
    reduce_one(source, output, args.ratio, args.target_triangles)
    return 0


if __name__ == "__main__":
    if "--" in sys.argv:
        cli_args = sys.argv[sys.argv.index("--") + 1 :]
    else:
        cli_args = sys.argv[1:]
    try:
        raise SystemExit(main(cli_args))
    except Exception:
        traceback.print_exc()
        raise SystemExit(1)
