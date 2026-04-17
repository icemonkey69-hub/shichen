import argparse
import os
import re
import sys
import traceback
from dataclasses import dataclass

import bpy
from mathutils import Vector


SUPPORTED_EXTS = {".glb", ".gltf", ".fbx"}


@dataclass
class ImportJob:
    key: str
    base_path: str
    action_paths: list[str]


@dataclass
class ResolvedJob:
    rig_base_path: str
    texture_donor_path: str
    action_paths: list[str]


def _parse_args() -> argparse.Namespace:
    argv: list[str] = []
    if "--" in sys.argv:
        argv = sys.argv[sys.argv.index("--") + 1 :]
    parser = argparse.ArgumentParser(description="Build NewModel character GLBs from source body + Mixamo clips.")
    parser.add_argument("--input-root", required=True, help="Input root, e.g. E:/Godot/test")
    parser.add_argument("--output-dir", required=True, help="Output character dir in project")
    parser.add_argument(
        "--max-texture-size",
        type=int,
        default=1024,
        help="Resize textures larger than this size before export. 0 disables resize.",
    )
    parser.add_argument(
        "--target-max-dimension",
        type=float,
        default=0.0,
        help="Auto-scale character so its mesh max dimension matches this value. 0 disables.",
    )
    return parser.parse_args(argv)


def _sanitize_name(name: str) -> str:
    raw = name.strip()
    raw = re.sub(r"[^\w\-]+", "_", raw, flags=re.UNICODE)
    raw = raw.strip("_")
    return raw or "model"


def _stem_lower(path: str) -> str:
    return os.path.splitext(os.path.basename(path))[0].lower()


def _ext_lower(path: str) -> str:
    return os.path.splitext(path)[1].lower()


def _ext_priority(path: str) -> int:
    ext = _ext_lower(path)
    if ext == ".glb":
        return 0
    if ext == ".gltf":
        return 1
    if ext == ".fbx":
        return 2
    return 99


def _list_supported_files(dir_path: str) -> list[str]:
    files: list[str] = []
    if not os.path.isdir(dir_path):
        return files
    for name in sorted(os.listdir(dir_path)):
        full = os.path.join(dir_path, name)
        if not os.path.isfile(full):
            continue
        if _ext_lower(full) not in SUPPORTED_EXTS:
            continue
        files.append(full)
    return files


def _pick_base(files: list[str], group_key_lower: str) -> str | None:
    if not files:
        return None

    def sort_key(path: str) -> tuple[int, int, int, str]:
        stem = _stem_lower(path)
        exact = 0 if stem == group_key_lower else 1
        has_suffix = 0 if "_" not in stem and "-" not in stem else 1
        return (exact, has_suffix, _ext_priority(path), stem)

    ordered = sorted(files, key=sort_key)
    return ordered[0] if ordered else None


def _infer_group_from_stem(stem: str) -> str:
    lower = stem.lower()
    if "_" in lower:
        return lower.split("_", 1)[0]
    if "-" in lower:
        return lower.split("-", 1)[0]
    return lower


def _collect_jobs(input_root: str) -> list[ImportJob]:
    jobs: list[ImportJob] = []
    taken_keys: set[str] = set()

    for entry in sorted(os.listdir(input_root)):
        sub_dir = os.path.join(input_root, entry)
        if not os.path.isdir(sub_dir):
            continue
        files = _list_supported_files(sub_dir)
        if not files:
            continue
        key = entry.lower().strip()
        base = _pick_base(files, key)
        if base is None:
            continue
        actions = [f for f in files if os.path.abspath(f) != os.path.abspath(base)]
        jobs.append(ImportJob(key=key, base_path=base, action_paths=actions))
        taken_keys.add(key)

    root_files = _list_supported_files(input_root)
    grouped: dict[str, list[str]] = {}
    for path in root_files:
        key = _infer_group_from_stem(_stem_lower(path))
        grouped.setdefault(key, []).append(path)

    for key in sorted(grouped.keys()):
        if key in taken_keys:
            continue
        files = grouped[key]
        base = _pick_base(files, key)
        if base is None:
            continue
        actions = [f for f in files if os.path.abspath(f) != os.path.abspath(base)]
        jobs.append(ImportJob(key=key, base_path=base, action_paths=actions))

    return jobs


def _resolve_job_sources(job: ImportJob) -> ResolvedJob:
    all_paths: list[str] = [job.base_path] + job.action_paths
    key_lower = job.key.lower()

    fbx_paths = [p for p in all_paths if _ext_lower(p) == ".fbx"]
    glb_paths = [p for p in all_paths if _ext_lower(p) in {".glb", ".gltf"}]

    rig_base_path = job.base_path
    if fbx_paths:
        exact_fbx = [p for p in fbx_paths if _stem_lower(p) == key_lower]
        idle_b_fbx = [p for p in fbx_paths if _stem_lower(p) in {f"{key_lower}_idle_b", f"{key_lower}-idle_b"}]
        skin_fbx = [p for p in fbx_paths if "skin" in _stem_lower(p)]
        tpose_fbx = [
            p for p in fbx_paths if any(token in _stem_lower(p) for token in ["tpose", "tpose", "bind", "rig", "idle"])
        ]
        if idle_b_fbx:
            rig_base_path = sorted(idle_b_fbx)[0]
        elif exact_fbx:
            rig_base_path = exact_fbx[0]
        elif skin_fbx:
            rig_base_path = sorted(skin_fbx)[0]
        elif tpose_fbx:
            rig_base_path = sorted(tpose_fbx)[0]
        else:
            rig_base_path = sorted(fbx_paths)[0]

    texture_donor_path = ""
    if glb_paths:
        exact_glb = [p for p in glb_paths if _stem_lower(p) == key_lower]
        if exact_glb:
            texture_donor_path = exact_glb[0]
        else:
            texture_donor_path = sorted(glb_paths)[0]

    action_paths: list[str] = []
    for path in sorted(all_paths):
        if texture_donor_path and os.path.abspath(path) == os.path.abspath(texture_donor_path):
            continue
        ext = _ext_lower(path)
        if ext not in SUPPORTED_EXTS:
            continue
        action_paths.append(path)

    return ResolvedJob(
        rig_base_path=rig_base_path,
        texture_donor_path=texture_donor_path,
        action_paths=action_paths,
    )


def _clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _import_scene(path: str) -> tuple[list[bpy.types.Object], list[bpy.types.Action]]:
    before_objects = {obj.name_full for obj in bpy.data.objects}
    before_actions = {act.name_full for act in bpy.data.actions}

    ext = _ext_lower(path)
    if ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    else:
        bpy.ops.import_scene.gltf(filepath=path)

    new_objects = [obj for obj in bpy.data.objects if obj.name_full not in before_objects]
    new_actions = [act for act in bpy.data.actions if act.name_full not in before_actions]
    return new_objects, new_actions


def _find_primary_armature(objects: list[bpy.types.Object]) -> bpy.types.Object | None:
    armatures = [obj for obj in objects if obj.type == "ARMATURE"]
    if not armatures:
        return None
    armatures.sort(key=lambda o: len(o.data.bones), reverse=True)
    return armatures[0]


def _collect_meshes_for_armature(armature_obj: bpy.types.Object) -> list[bpy.types.Object]:
    meshes: list[bpy.types.Object] = []
    for obj in bpy.data.objects:
        if obj.type != "MESH":
            continue
        linked = False
        for mod in obj.modifiers:
            if mod.type == "ARMATURE" and mod.object == armature_obj:
                linked = True
                break
        if linked or obj.parent == armature_obj:
            meshes.append(obj)
    return meshes


def _collect_meshes_from_objects(objects: list[bpy.types.Object]) -> list[bpy.types.Object]:
    return [obj for obj in objects if obj.type == "MESH"]


def _derive_action_name(group_key: str, action_path: str) -> str:
    stem = os.path.splitext(os.path.basename(action_path))[0]
    lower_stem = stem.lower()
    if lower_stem.startswith(group_key + "_"):
        stem = stem[len(group_key) + 1 :]
    elif lower_stem.startswith(group_key + "-"):
        stem = stem[len(group_key) + 1 :]
    stem = _sanitize_name(stem)
    return stem or "anim"


def _unique_action_name(base_name: str) -> str:
    if bpy.data.actions.get(base_name) is None:
        return base_name
    index = 2
    while True:
        candidate = f"{base_name}_{index}"
        if bpy.data.actions.get(candidate) is None:
            return candidate
        index += 1


def _extract_action_from_imported(
    imported_objects: list[bpy.types.Object], imported_actions: list[bpy.types.Action]
) -> bpy.types.Action | None:
    arm = _find_primary_armature(imported_objects)
    if arm is not None and arm.animation_data is not None and arm.animation_data.action is not None:
        return arm.animation_data.action
    if imported_actions:
        imported_actions.sort(key=lambda a: (a.frame_range[1] - a.frame_range[0]), reverse=True)
        return imported_actions[0]
    return None


def _add_action_to_nla(armature_obj: bpy.types.Object, action_obj: bpy.types.Action, desired_name: str) -> str:
    armature_obj.animation_data_create()
    copied = action_obj.copy()
    copied.name = _unique_action_name(desired_name)
    copied.use_fake_user = True
    track = armature_obj.animation_data.nla_tracks.new()
    track.name = copied.name
    strip = track.strips.new(copied.name, 1, copied)
    strip.name = copied.name
    strip.blend_type = "REPLACE"
    strip.extrapolation = "NOTHING"
    return copied.name


def _safe_remove_objects(objects: list[bpy.types.Object]) -> None:
    for obj in objects:
        if obj.name in bpy.data.objects:
            bpy.data.objects.remove(obj, do_unlink=True)


def _prune_scene_to_base(base_armature: bpy.types.Object, base_meshes: list[bpy.types.Object]) -> int:
    keep_names = {base_armature.name}
    keep_names.update([mesh.name for mesh in base_meshes if mesh.name in bpy.data.objects])
    removed = 0
    for obj in list(bpy.data.objects):
        if obj.name in keep_names:
            continue
        bpy.data.objects.remove(obj, do_unlink=True)
        removed += 1
    return removed


def _purge_orphan_data() -> None:
    try:
        bpy.data.orphans_purge(do_recursive=True)
    except Exception:
        pass


def _collect_unique_materials(meshes: list[bpy.types.Object]) -> list[bpy.types.Material]:
    mats: list[bpy.types.Material] = []
    seen: set[str] = set()
    for mesh_obj in meshes:
        if mesh_obj.type != "MESH" or mesh_obj.data is None:
            continue
        for mat in mesh_obj.data.materials:
            if mat is None:
                continue
            if mat.name_full in seen:
                continue
            seen.add(mat.name_full)
            mats.append(mat)
    return mats


def _apply_materials_to_meshes(target_meshes: list[bpy.types.Object], donor_materials: list[bpy.types.Material]) -> int:
    if not donor_materials:
        return 0
    changed = 0
    for mesh_obj in target_meshes:
        if mesh_obj.type != "MESH" or mesh_obj.data is None:
            continue
        slot_count = len(mesh_obj.data.materials)
        if slot_count <= 0:
            mesh_obj.data.materials.append(donor_materials[0])
            changed += 1
            continue
        for i in range(slot_count):
            mat = donor_materials[min(i, len(donor_materials) - 1)]
            if mesh_obj.data.materials[i] != mat:
                mesh_obj.data.materials[i] = mat
                changed += 1
    return changed


def _mesh_bounds(meshes: list[bpy.types.Object]) -> tuple[Vector, Vector] | None:
    if not meshes:
        return None
    min_v = Vector((1e9, 1e9, 1e9))
    max_v = Vector((-1e9, -1e9, -1e9))
    has_vertex = False
    for mesh_obj in meshes:
        if mesh_obj.type != "MESH" or mesh_obj.data is None:
            continue
        mw = mesh_obj.matrix_world
        for corner in mesh_obj.bound_box:
            v = mw @ Vector(corner)
            min_v.x = min(min_v.x, v.x)
            min_v.y = min(min_v.y, v.y)
            min_v.z = min(min_v.z, v.z)
            max_v.x = max(max_v.x, v.x)
            max_v.y = max(max_v.y, v.y)
            max_v.z = max(max_v.z, v.z)
            has_vertex = True
    if not has_vertex:
        return None
    return min_v, max_v


def _apply_scale(objects: list[bpy.types.Object], scale_factor: float) -> None:
    if not objects or abs(scale_factor - 1.0) < 1e-4:
        return
    active_obj = bpy.context.view_layer.objects.active
    if active_obj is not None:
        try:
            if active_obj.mode != "OBJECT":
                bpy.ops.object.mode_set(mode="OBJECT")
        except Exception:
            pass
    bpy.ops.object.select_all(action="DESELECT")
    valid: list[bpy.types.Object] = []
    for obj in objects:
        if obj.name in bpy.data.objects:
            obj.select_set(True)
            valid.append(obj)
    if not valid:
        return
    bpy.context.view_layer.objects.active = valid[0]
    for obj in valid:
        obj.scale *= scale_factor
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)


def _fit_model_scale(base_armature: bpy.types.Object, base_meshes: list[bpy.types.Object], target_max_dimension: float) -> float:
    if target_max_dimension <= 0.0:
        return 1.0
    bounds = _mesh_bounds(base_meshes)
    if bounds is None:
        return 1.0
    min_v, max_v = bounds
    size = max_v - min_v
    current_max = max(size.x, size.y, size.z)
    if current_max <= 1e-5:
        return 1.0
    scale_factor = target_max_dimension / current_max
    scale_factor = max(0.25, min(4.0, scale_factor))
    scale_targets: list[bpy.types.Object] = [base_armature]
    for mesh in base_meshes:
        if mesh.parent is not None:
            continue
        linked_to_armature = False
        for mod in mesh.modifiers:
            if mod.type == "ARMATURE" and mod.object == base_armature:
                linked_to_armature = True
                break
        if not linked_to_armature:
            scale_targets.append(mesh)
    _apply_scale(scale_targets, scale_factor)
    return scale_factor


def _optimize_images(max_texture_size: int) -> int:
    if max_texture_size <= 0:
        return 0
    changed = 0
    for image in bpy.data.images:
        if image is None:
            continue
        if image.size[0] <= 0 or image.size[1] <= 0:
            continue
        width = int(image.size[0])
        height = int(image.size[1])
        longest = max(width, height)
        if longest <= max_texture_size:
            continue
        scale = float(max_texture_size) / float(longest)
        new_w = max(1, int(round(width * scale)))
        new_h = max(1, int(round(height * scale)))
        try:
            image.scale(new_w, new_h)
            changed += 1
        except Exception:
            continue
    return changed


def _export_glb(output_path: str, export_objects: list[bpy.types.Object]) -> None:
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    active_obj = bpy.context.view_layer.objects.active
    if active_obj is not None:
        try:
            if active_obj.mode != "OBJECT":
                bpy.ops.object.mode_set(mode="OBJECT")
        except Exception:
            pass
    bpy.ops.object.select_all(action="DESELECT")
    valid_objects: list[bpy.types.Object] = []
    for obj in export_objects:
        if obj.name in bpy.data.objects:
            obj.select_set(True)
            valid_objects.append(obj)
    if not valid_objects:
        raise RuntimeError("No export objects selected.")
    bpy.context.view_layer.objects.active = valid_objects[0]

    kwargs = {
        "filepath": output_path,
        "export_format": "GLB",
        "use_selection": True,
        "export_apply": False,
        "export_animations": True,
        "export_nla_strips": True,
        "export_skins": True,
        "export_cameras": False,
        "export_lights": False,
        "export_materials": "EXPORT",
        "export_image_format": "AUTO",
        "export_jpeg_quality": 85,
    }

    try_modes = ["NLA_TRACKS", "ACTIONS", None]
    last_error: Exception | None = None
    for mode in try_modes:
        try:
            if mode is None:
                bpy.ops.export_scene.gltf(**kwargs)
            else:
                bpy.ops.export_scene.gltf(export_animation_mode=mode, **kwargs)
            return
        except Exception as exc:
            last_error = exc
            continue
    if last_error is not None:
        raise last_error
    raise RuntimeError("GLB export failed for unknown reason.")


def _process_job(
    job: ImportJob, output_dir: str, max_texture_size: int, target_max_dimension: float
) -> tuple[str, int, int, float, int]:
    _clear_scene()

    resolved = _resolve_job_sources(job)

    selected_rig_path = resolved.rig_base_path
    base_objects, _ = _import_scene(selected_rig_path)
    base_armature = _find_primary_armature(base_objects)
    if base_armature is None:
        raise RuntimeError(f"No armature found in base file: {selected_rig_path}")
    base_meshes = _collect_meshes_from_objects(base_objects)
    skinned_meshes = _collect_meshes_for_armature(base_armature)
    if not skinned_meshes:
        raise RuntimeError(
            "Rig base has no skinned mesh. "
            "Please export XXX_Idle_B.fbx from Mixamo with 'With Skin'. "
            f"Current base: {selected_rig_path}"
        )
    base_armature.animation_data_create()
    applied_scale = _fit_model_scale(base_armature, base_meshes, target_max_dimension)

    donor_mat_count = 0
    if resolved.texture_donor_path and os.path.abspath(resolved.texture_donor_path) != os.path.abspath(selected_rig_path):
        donor_objects, donor_actions = _import_scene(resolved.texture_donor_path)
        donor_meshes = _collect_meshes_from_objects(donor_objects)
        donor_mats = _collect_unique_materials(donor_meshes)
        donor_mat_count = _apply_materials_to_meshes(base_meshes, donor_mats)
        _safe_remove_objects(donor_objects)
        for act in donor_actions:
            if act.name in bpy.data.actions and act.users <= 0:
                bpy.data.actions.remove(act)

    added_count = 0
    added_action_names: set[str] = set()
    if base_armature.animation_data is not None and base_armature.animation_data.action is not None:
        base_action = base_armature.animation_data.action
        base_action_name = _derive_action_name(job.key, selected_rig_path)
        _add_action_to_nla(base_armature, base_action, base_action_name)
        added_count += 1
        added_action_names.add(base_action_name.lower())
    base_armature.animation_data.action = None

    for action_path in sorted(resolved.action_paths):
        if os.path.abspath(action_path) == os.path.abspath(selected_rig_path):
            continue
        action_name = _derive_action_name(job.key, action_path)
        action_key = action_name.lower()
        if action_key in added_action_names:
            print(f"  [SKIP] duplicate action name: {os.path.basename(action_path)} -> {action_name}")
            continue
        imported_objects, imported_actions = _import_scene(action_path)
        source_action = _extract_action_from_imported(imported_objects, imported_actions)
        if source_action is None:
            _safe_remove_objects(imported_objects)
            print(f"[WARN] Skip action file (no action found): {action_path}")
            continue
        final_name = _add_action_to_nla(base_armature, source_action, action_name)
        added_count += 1
        added_action_names.add(action_key)
        print(f"  [ACTION] {os.path.basename(action_path)} -> {final_name}")
        _safe_remove_objects(imported_objects)

        for act in imported_actions:
            if act.name in bpy.data.actions and act.users <= 0:
                bpy.data.actions.remove(act)

    removed_scene_objects = _prune_scene_to_base(base_armature, base_meshes)
    _purge_orphan_data()

    export_nodes = [base_armature] + base_meshes
    optimized_images = _optimize_images(max_texture_size)
    out_name = f"{_sanitize_name(job.key)}.glb"
    out_path = os.path.join(output_dir, out_name)
    _export_glb(out_path, export_nodes)
    print(f"  [CLEANUP] removed scene objects: {removed_scene_objects}")
    return out_name, added_count, optimized_images, applied_scale, donor_mat_count


def main() -> None:
    args = _parse_args()
    input_root = os.path.abspath(args.input_root)
    output_dir = os.path.abspath(args.output_dir)
    max_texture_size = max(0, int(args.max_texture_size))
    target_max_dimension = max(0.0, float(args.target_max_dimension))

    if not os.path.isdir(input_root):
        raise RuntimeError(f"Input root not found: {input_root}")
    os.makedirs(output_dir, exist_ok=True)

    jobs = _collect_jobs(input_root)
    if not jobs:
        print(f"[WARN] No import jobs found under: {input_root}")
        return

    total = 0
    ok = 0
    failed = 0
    for job in jobs:
        total += 1
        try:
            print(f"[JOB] {job.key}")
            resolved_preview = _resolve_job_sources(job)
            print(f"  [RIG_BASE] {os.path.basename(resolved_preview.rig_base_path)}")
            if resolved_preview.texture_donor_path:
                print(f"  [TEX_DONOR] {os.path.basename(resolved_preview.texture_donor_path)}")
            output_name, action_count, optimized_images, applied_scale, donor_mat_count = _process_job(
                job, output_dir, max_texture_size, target_max_dimension
            )
            ok += 1
            print(
                f"[OK] {job.key} -> {output_name} "
                f"(actions={action_count}, optimized_textures={optimized_images}, "
                f"scale={applied_scale:.3f}, donor_material_slots={donor_mat_count}, "
                f"target_max_dim={target_max_dimension:.2f}, max_tex={max_texture_size})"
            )
        except Exception as exc:
            failed += 1
            print(f"[FAILED] {job.key}: {exc}")
            print(traceback.format_exc())

    print(f"[DONE] Total={total} Success={ok} Failed={failed}")
    if failed > 0:
        raise RuntimeError("Some jobs failed.")


if __name__ == "__main__":
    main()
