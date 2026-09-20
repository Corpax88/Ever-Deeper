"""Derive a review-only Worn runtime mesh from the approved native asset.

Run in Blender, with the approved source loaded for --prepare-only, or the saved
prepared.blend loaded for --bake-only. Never overwrites the native source.
"""
import argparse
from array import array
import hashlib
import json
import math
from pathlib import Path
import runpy
import sys

import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
HERO = HERE.parent
sys.path.insert(0, str(HERO))
import native_motion
import premium_motion
import locomotion
import motion_v3

LOD_NAME = "Native_Runtime_Worn_LOD"
SOURCE_TAG = "native_runtime_source"
SOURCE_INDEX = "native_runtime_source_index"
CHANNELS = ("albedo", "roughness", "metallic", "cloth", "normal", "ao")


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def matrix_data(value):
    return [list(row) for row in value]


def triangles(mesh):
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def targets(p, rig, rest):
    """The same complete target matrices as native_pose.create_applier."""
    mats = {b.name: b.matrix_local.copy() for b in rig.data.bones}
    result = {name: value.copy() for name, value in mats.items()}
    result["body"] = p["torso"] @ mats["body"]
    result["head"] = p["head"] @ mats["head"]
    before = motion_v3.frame_matrix(rest["axis"], rest["tool_normal"])
    after = motion_v3.frame_matrix(p["axis"], p["tool_normal"])
    result["tool"] = (after @ before.inverted()).to_4x4() @ mats["tool"]
    result["tool"].translation = p["rear"]
    for side in ("R", "L"):
        a, b, c = p["arms"][side]
        hip, knee, ankle = p["legs"][side]
        for name, start, end in (("upper."+side, a, b), ("lower."+side, b, c),
                                 ("thigh."+side, hip, knee), ("shin."+side, knee, ankle)):
            bone = rig.data.bones[name]
            result[name] = (bone.tail_local-bone.head_local).rotation_difference(end-start).to_matrix().to_4x4() @ mats[name]
            result[name].translation = start
        result["foot."+side] = p["foot_rotations"][side].to_4x4() @ mats["foot."+side]
        result["foot."+side].translation = ankle
        before = motion_v3.frame_matrix(rest["hand_axes"][side], rest["radials"][side])
        after = motion_v3.frame_matrix(p["hand_axes"][side], p["radials"][side])
        result["hand."+side] = (after @ before.inverted()).to_4x4() @ mats["hand."+side]
        result["hand."+side].translation = c
    return result


def export_motion(namespace, output):
    rig = namespace["r"]
    namespace["view"]("right", (-6, -1))
    ground = namespace["ground_vector"]("right")
    camera = bpy.context.scene.camera
    samples = {}
    hand_local = None
    max_hand_frame_error = 0.0
    for state, phases in (("idle", [i/24 for i in range(24)]),
                           ("walk", [i/96 for i in range(96)]),
                           ("mine", sorted(set([i/128 for i in range(128)] + [.24, .40, .55, .575, .68, .82])))):
        samples[state] = []
        for phase in phases:
            pose = native_motion.sample("worn", state, phase, ground, 340.)
            pose["head"] = pose["head"] @ namespace["head_offset"]
            matrices = targets(pose, rig, namespace["rest"])
            grip_frames = {side: matrices["tool"].inverted() @ matrices["hand."+side] for side in ("R", "L")}
            if hand_local is None:
                hand_local = grip_frames
            for side in grip_frames:
                max_hand_frame_error = max(max_hand_frame_error, max(abs(grip_frames[side][i][j]-hand_local[side][i][j]) for i in range(4) for j in range(4)))
            samples[state].append(dict(phase=phase, bones={name:matrix_data(value) for name,value in matrices.items()},
                                       contacts=pose["contacts"], feet=native_motion.frame_metadata(pose, ground)["feet"]))
    assert max_hand_frame_error < 1e-5, ("Hands are not rigidly attached to the genuine tool", max_hand_frame_error)
    data = dict(schema=1, gear="worn", approved=False, direction="right", authored_speed=340., stride_pixels=88.,
                ground_per_pixel=list(ground), ground=locomotion.GROUND, boot_hull=locomotion.BOOT_HULL,
                heading=matrix_data(premium_motion.heading_matrix(ground).to_4x4()),
                flat_entry_phase=native_motion.flat_entry_phase(ground, 340.),
                camera={"world_matrix":matrix_data(camera.matrix_world), "ortho_size":camera.data.ortho_scale},
                rest={b.name:matrix_data(b.matrix_local) for b in rig.data.bones},
                tails={b.name:list(b.tail_local) for b in rig.data.bones},
                parents={b.name:b.parent.name if b.parent else None for b in rig.data.bones},
                hand_local={side:matrix_data(value) for side,value in hand_local.items()},
                max_hand_frame_error=max_hand_frame_error, samples=samples,
                reference_poses=[{"state":"idle","phase":0.}, {"state":"walk","phase":0.},
                                 {"state":"walk","phase":.25}, {"state":"mine","phase":.4375}, {"state":"mine","phase":.55}])
    (output/"motion.json").write_text(json.dumps(data, separators=(",", ":"))+"\n")


def object_budget(name, count, ratio, geometry_policy="legacy_budget"):
    lower = name.lower()
    if geometry_policy == "legacy_budget" and any(token in lower for token in ("iris", "pupil", "eye light", "eye white", "mouth crease")):
        return min(count, max(500, round(count*.35)))
    floor = 24 if count < 1000 else 160
    if "unified expressive face" in lower:
        return min(count, 28000)
    if "fine curved facial groom" in lower:
        return min(count, 22000)
    if "rounded jaw beard" in lower:
        return min(count, 10000)
    if "short hair fibers" in lower:
        return min(count, 7000)
    if "five digit hand" in lower:
        return min(count, 4500)
    if geometry_policy == "native_components":
        return count
    return min(count, max(floor, round(count*ratio)))


def weld_identical_deformation(mesh):
    """Close coincident seams only within identical skinning assignments.

    Native donors are never touched. This runs only on dense derived copies,
    before reduction; material/corner data are retained by BMesh.
    """
    import bmesh

    before = len(mesh.vertices)
    if mesh.has_custom_normals:
        return {"before": before, "after": before,
                "skipped": "Authored custom split normals remain unchanged"}
    bm = bmesh.new()
    try:
        bm.from_mesh(mesh)
        deform = bm.verts.layers.deform.active
        pending = set(bm.verts)
        components = protected = 0
        targetmap = {}
        while pending:
            stack = [pending.pop()]
            cells = {}
            components += 1
            while stack:
                vertex = stack.pop()
                for edge in vertex.link_edges:
                    other = edge.other_vert(vertex)
                    if other in pending:
                        pending.remove(other)
                        stack.append(other)
                # Keep separate shells/strands, open boundaries, hard normals,
                # UV seams and material boundaries exactly as authored.
                if (any(not edge.smooth or edge.seam or edge.is_boundary for edge in vertex.link_edges)
                        or any(not face.smooth for face in vertex.link_faces)
                        or len({face.material_index for face in vertex.link_faces}) != 1):
                    protected += 1
                    continue
                weights = tuple(sorted(vertex[deform].items())) if deform is not None else ()
                material_index = vertex.link_faces[0].material_index
                # Quantization only proposes candidates; the distance is still
                # checked. Missing a boundary-cell pair conservatively retains it.
                cell = tuple(round(float(value) / 1e-6) for value in vertex.co)
                candidates = cells.setdefault((weights, material_index, cell), [])
                match = next((other for other in candidates
                              if (vertex.co-other.co).length_squared <= 1e-12), None)
                if match is None:
                    candidates.append(vertex)
                else:
                    targetmap[vertex] = match
        # One mesh mutation avoids repeating whole-mesh operator bookkeeping
        # separately for thousands of disconnected native groom strands.
        if targetmap:
            bmesh.ops.weld_verts(bm, targetmap=targetmap)
        bm.to_mesh(mesh)
    finally:
        bm.free()
    mesh.update()
    return {"before": before, "after": len(mesh.vertices), "distance": 1e-6,
            "components": components, "protected_vertices": protected,
            "deformation_contract": "identical_weights_within_one_component_only",
            "seam_contract": "open_boundary_hard_normal_uv_and_material_seams_untouched"}


def prepare(args):
    source = Path(bpy.data.filepath)
    geometry_policy = getattr(args, "geometry_policy", "legacy_budget")
    assert geometry_policy in ("legacy_budget", "native_components")
    assert source.name != "prepared.blend", "Preparation requires the original native source"
    assert args.native_tools is not None
    namespace_args = ["export_hero.py", "--", "--native-tools", str(args.native_tools),
                      "--output", str(args.output/"preparation"), "--gear", "worn", "--native-motion-pilot",
                      "--direction", "right", "--native-states", "idle", "--native-loop-counts", "idle=1", "--validate-only"]
    sys.argv = namespace_args
    namespace = runpy.run_path(str(HERO/"export_hero.py"), run_name="__main__")
    export_motion(namespace, args.output)
    rig = namespace["r"]
    for bone in rig.pose.bones:
        bone.matrix_basis = Matrix.Identity(4)
    sources = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.hide_render]
    original_materials = {m for o in sources for m in o.data.materials if m}
    for source_object in sources:
        source_object[SOURCE_TAG] = True
        for modifier in source_object.modifiers:
            modifier.show_viewport = modifier.show_render
            if modifier.type == "SUBSURF":
                modifier.levels = modifier.render_levels
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    evaluated_counts = {}
    for obj in sources:
        evaluated = obj.evaluated_get(deps)
        mesh = evaluated.to_mesh()
        evaluated_counts[obj.name] = triangles(mesh)
        evaluated.to_mesh_clear()
    total = sum(evaluated_counts.values())
    ratio = args.triangle_budget / total
    derived, inventory = [], []
    for index, original in enumerate(sources):
        original[SOURCE_INDEX] = index
        count = evaluated_counts[original.name]
        lod = original.copy()
        lod.data = original.data.copy()
        lod.name = "RuntimeLOD_" + original.name
        lod[SOURCE_TAG] = False
        bpy.context.scene.collection.objects.link(lod)
        bpy.ops.object.select_all(action="DESELECT")
        lod.select_set(True)
        bpy.context.view_layer.objects.active = lod
        for modifier in list(lod.modifiers):
            if modifier.type != "ARMATURE":
                if modifier.show_render:
                    bpy.ops.object.modifier_apply(modifier=modifier.name)
                else:
                    lod.modifiers.remove(modifier)
        budget = object_budget(original.name, count, ratio, geometry_policy)
        weld = None
        if count > budget:
            if geometry_policy == "native_components":
                print("NATIVE_DENSE_COPY_START", original.name, count, flush=True)
                weld = weld_identical_deformation(lod.data)
            reduce = lod.modifiers.new("Native derived review LOD", "DECIMATE")
            reduce.ratio = max(.001, budget/count)
            reduce.use_collapse_triangulate = True
            bpy.ops.object.modifier_apply(modifier=reduce.name)
        actual = triangles(lod.data)
        # Face ownership survives joining and is independent of shared materials.
        owner = lod.data.attributes.new(SOURCE_INDEX, "INT", "FACE")
        owner.data.foreach_set("value", array("i", [index]) * len(lod.data.polygons))
        if geometry_policy == "native_components" and count > budget:
            print("NATIVE_DENSE_COPY_COMPLETE", original.name, actual, weld, flush=True)
        inventory.append(dict(source=original.name, source_index=index, raw_triangles=triangles(original.data), source_triangles=count,
                              budget=budget, actual_triangles=actual, raw_vertices=len(original.data.vertices),
                              geometry_policy=geometry_policy, weld=weld,
                              source_uv_layers=list(original.data.uv_layers.keys())))
        derived.append(lod)
        if index % 50 == 0:
            print("NATIVE_RUNTIME_LOD_PART", index, len(sources), flush=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in derived:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = derived[0]
    bpy.ops.object.join()
    target = bpy.context.view_layer.objects.active
    target.name = LOD_NAME
    target[SOURCE_TAG] = False
    for uv in list(target.data.uv_layers):
        target.data.uv_layers.remove(uv)
    target.data.uv_layers.new(name="NativeRuntimeAtlas")
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=args.atlas_island_margin, area_weight=.2,
                             correct_aspect=True, scale_to_bounds=True)
    bpy.ops.object.mode_set(mode="OBJECT")
    preparation = dict(source=str(source), source_sha256=digest(source), original_tool_sha256=digest(args.native_tools/"worn"/"hero.blend"),
                       source_files={str(p.relative_to(HERO)):digest(p) for p in sorted(HERO.rglob("*.py"))},
                       source_triangles=total, derived_triangles=triangles(target.data), source_materials=sorted(m.name for m in original_materials),
                       source_objects=len(sources), derived_objects=1, texture_size=args.texture_size,
                       requested_triangle_budget=args.triangle_budget, parts=inventory, rendered=False, approved=False,
                       geometry_policy=geometry_policy,
                       source_index_attribute=SOURCE_INDEX, atlas_island_margin=args.atlas_island_margin,
                       limits="Native-derived geometry and numeric inventory. No visual, runtime or performance acceptance.")
    (args.output/"preparation.json").write_text(json.dumps(preparation, indent=2)+"\n")
    bpy.context.scene["native_runtime_preparation"] = str(args.output/"preparation.json")
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output/"prepared.blend"))
    print("NATIVE_RUNTIME_PREPARED", preparation["derived_triangles"], "triangles", flush=True)


def source_material_override(material, channel):
    """Temporarily expose original material channels as emission for transfer."""
    nodes, links = material.node_tree.nodes, material.node_tree.links
    output = next(n for n in nodes if n.type == "OUTPUT_MATERIAL" and n.is_active_output)
    original = [(link.from_socket, link.to_socket) for link in output.inputs["Surface"].links]
    principled = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    emission = nodes.new("ShaderNodeEmission")
    if channel == "cloth":
        source_name = material.get("native_donor_source_material", material.name)
        value = 1. if source_name in ("v19 woven forest workwear", "v19 soft olive sleeve lining") else 0.
        emission.inputs["Color"].default_value = (value, value, value, 1.)
    else:
        source = principled.inputs[{"albedo":"Base Color", "roughness":"Roughness", "metallic":"Metallic"}[channel]]
        if source.is_linked:
            links.new(source.links[0].from_socket, emission.inputs["Color"])
        else:
            value = source.default_value
            emission.inputs["Color"].default_value = value if hasattr(value, "__len__") else (value, value, value, 1.)
    links.new(emission.outputs[0], output.inputs["Surface"])
    def restore():
        nodes.remove(emission)
        for a, b in original:
            links.new(a, b)
    return restore


def bake(args):
    assert Path(bpy.data.filepath).name == "prepared.blend"
    prep = json.loads((args.output/"preparation.json").read_text())
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 8
    scene.cycles.use_denoising = False
    scene.render.threads_mode = "FIXED"
    scene.render.threads = args.threads
    scene.render.bake.use_selected_to_active = True
    scene.render.bake.use_clear = True
    scene.render.bake.margin = 8
    scene.render.bake.cage_extrusion = .018
    scene.render.bake.max_ray_distance = .040
    sources = [o for o in scene.objects if o.type == "MESH" and bool(o.get(SOURCE_TAG, False))]
    target = bpy.data.objects[LOD_NAME]
    source_materials = {m for o in sources for m in o.data.materials if m}
    target_material = bpy.data.materials.new("Native runtime baked material")
    target_material.use_nodes = True
    target.data.materials.clear()
    target.data.materials.append(target_material)
    for poly in target.data.polygons:
        poly.material_index = 0
    texture_node = target_material.node_tree.nodes.new("ShaderNodeTexImage")
    target_material.node_tree.nodes.active = texture_node
    bpy.ops.object.select_all(action="DESELECT")
    for obj in sources:
        obj.hide_render = False
        obj.select_set(True)
    target.select_set(True)
    bpy.context.view_layer.objects.active = target
    images = {}
    for channel in CHANNELS:
        path = args.output/(channel+".png")
        if path.exists():
            images[channel] = bpy.data.images.load(str(path), check_existing=False)
            images[channel].colorspace_settings.name = "sRGB" if channel == "albedo" else "Non-Color"
            continue
        image = bpy.data.images.new("Native baked "+channel, width=prep["texture_size"], height=prep["texture_size"], alpha=True)
        image.colorspace_settings.name = "sRGB" if channel == "albedo" else "Non-Color"
        texture_node.image = image
        restorers = []
        if channel in ("albedo", "roughness", "metallic", "cloth"):
            restorers = [source_material_override(m, channel) for m in source_materials]
        print("NATIVE_RUNTIME_BAKE_START", channel, flush=True)
        try:
            bpy.ops.object.bake(type="NORMAL" if channel == "normal" else "AO" if channel == "ao" else "EMIT")
        finally:
            for restore in restorers:
                restore()
        image.filepath_raw = str(path)
        image.file_format = "PNG"
        image.save()
        images[channel] = image
        print("NATIVE_RUNTIME_BAKE_COMPLETE", channel, flush=True)
    size = prep["texture_size"]
    packed = array("f", [0.])*(size*size*4)
    for index, channel in enumerate(("ao", "roughness", "metallic")):
        pixels = array("f", [0.])*(size*size*4)
        images[channel].pixels.foreach_get(pixels)
        packed[index::4] = pixels[::4]
    packed[3::4] = array("f", [1.])*(size*size)
    orm = bpy.data.images.new("Native runtime ORM", width=size, height=size, alpha=True)
    orm.colorspace_settings.name = "Non-Color"
    orm.pixels.foreach_set(packed)
    orm.filepath_raw = str(args.output/"orm.png")
    orm.file_format = "PNG"
    orm.save()
    nodes, links = target_material.node_tree.nodes, target_material.node_tree.links
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    texture_node.image = images["albedo"]
    links.new(texture_node.outputs["Color"], bsdf.inputs["Base Color"])
    for channel, socket in (("roughness", "Roughness"), ("metallic", "Metallic")):
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = images[channel]
        links.new(tex.outputs["Color"], bsdf.inputs[socket])
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = images["normal"]
    normal = nodes.new("ShaderNodeNormalMap")
    links.new(tex.outputs["Color"], normal.inputs["Color"])
    links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
    bpy.ops.object.select_all(action="DESELECT")
    target.select_set(True)
    rig = next(o for o in scene.objects if o.type == "ARMATURE")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    for obj in sources:
        obj.hide_render = True
    bpy.ops.export_scene.gltf(filepath=str(args.output/"worn-native-runtime.glb"), export_format="GLB", use_selection=True,
                              export_animations=False, export_skins=True, export_normals=True, export_tangents=True,
                              export_materials="EXPORT", export_yup=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output/"baked-candidate.blend"))
    report = dict(approved=False, gear="worn", texture_size=size, triangles=triangles(target.data),
                  material_surfaces=len(target.data.materials), bones=len(rig.data.bones),
                  files={p.name:digest(p) for p in [args.output/"worn-native-runtime.glb", args.output/"motion.json",
                                                   args.output/"albedo.png", args.output/"normal.png", args.output/"orm.png", args.output/"cloth.png"]},
                  source_sha256=prep["source_sha256"], limits="Exported native-derived candidate. Godot visual and performance gates remain.")
    (args.output/"candidate.json").write_text(json.dumps(report, indent=2)+"\n")
    print("NATIVE_RUNTIME_CANDIDATE_COMPLETE", json.dumps({k:report[k] for k in ("triangles", "material_surfaces", "bones")}), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--geometry-policy", choices=("legacy_budget", "native_components"), default="legacy_budget")
    parser.add_argument("--native-tools", type=Path)
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--bake-only", action="store_true")
    parser.add_argument("--triangle-budget", type=int, default=120000)
    parser.add_argument("--texture-size", type=int, default=1024)
    parser.add_argument("--atlas-island-margin", type=float, default=.0025)
    parser.add_argument("--threads", type=int, default=2)
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    assert args.prepare_only != args.bake_only
    assert 0 <= args.atlas_island_margin <= .01
    assert args.output.is_absolute() and not str(args.output).startswith(str(HERO.parent.parent/"assets"))
    args.output.mkdir(parents=True, exist_ok=True)
    prepare(args) if args.prepare_only else bake(args)


if __name__ == "__main__":
    main()
