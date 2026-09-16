"""Review-only constant-material donor merge; never saves or exports a blend.

Run ``bake`` inside Blender with prepared.blend loaded. Run ``compare`` with
ordinary Python + NumPy. See CONSTANT-DONOR-PROBE.md for isolated commands.
"""
from contextlib import contextmanager
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys
import time
import zlib

import numpy as np


SOURCE_TAG = "native_runtime_source"
TARGET_NAME = "Native_Runtime_Worn_LOD"
SAMPLE_NAMES = (
    "v14 flat work boot sole R",  # Bevel.
    "v17 rounded jaw beard",  # Solidify + Subdivision; unused TexCoord.
    "v26 fitted short hair roots",  # Solidify.
    "v17 fine curved facial groom",  # Three constant materials.
)
NORMAL_TOLERANCE = 3e-4  # Custom split normals are encoded, not lossless floats.
RGB_OUTPUT_CONTRACT = "opaque_rgb8_srgb_albedo_linear_data_v1"
DATA_CHANNELS = ("roughness", "metallic", "cloth", "normal", "ao")


def digest(path):
    result = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def write_json(path, value):
    Path(path).write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")


def animated(data):
    animation = getattr(data, "animation_data", None)
    return bool(animation and (animation.action or animation.drivers or animation.nla_tracks))


def opaque_material_audit(material):
    """Prove live opaque RGB use before replacing any source output for baking.

    Connected color/roughness/normal inputs are allowed. Alpha and transmission
    must be authored constants on the actual surface BSDF. Unused nodes do not
    affect the decision; unsupported output graphs fail closed.
    """
    if material is None or not material.use_nodes or material.node_tree is None:
        raise ValueError("Opaque RGB requires a node material")
    tree = material.node_tree
    if animated(material) or animated(tree):
        raise ValueError("Opaque RGB rejects animated/driven material: " + material.name)
    outputs = [node for node in tree.nodes
               if node.type == "OUTPUT_MATERIAL" and node.is_active_output]
    if len(outputs) != 1 or outputs[0].mute:
        raise ValueError("Opaque RGB requires one active unmuted output: " + material.name)
    output = outputs[0]
    for name in ("Volume", "Displacement"):
        socket = output.inputs.get(name)
        if socket is not None and (socket.is_linked or len(socket.links)):
            raise ValueError("Opaque RGB rejects connected " + name + ": " + material.name)
    surface = output.inputs.get("Surface")
    if surface is None or len(surface.links) != 1:
        raise ValueError("Opaque RGB requires one surface link: " + material.name)
    link = surface.links[0]
    node = link.from_node
    if (not link.is_valid or getattr(link, "is_muted", False) or node.mute
            or node.type != "BSDF_PRINCIPLED" or link.from_socket.name != "BSDF"):
        raise ValueError("Opaque RGB requires direct active Principled surface: " + material.name)
    values = {}
    for name, expected in (("Alpha", 1.0), ("Transmission Weight", 0.0)):
        socket = node.inputs.get(name)
        if (socket is None or socket.is_linked or len(socket.links)
                or float(socket.default_value) != expected):
            raise ValueError(f"Opaque RGB requires unlinked {name}={expected}: {material.name}")
        values[name] = {"linked": False, "value": float(socket.default_value)}
    return {"material": material.name, "principled": node.name, "inputs": values}


def opaque_sources_audit(sources):
    materials = set()
    for source in sources:
        if not source.material_slots or any(slot.material is None for slot in source.material_slots):
            raise ValueError("Opaque RGB rejects missing source materials: " + source.name)
        materials.update(slot.material for slot in source.material_slots)
    if not materials:
        raise ValueError("Opaque RGB requires source materials")
    rows = [opaque_material_audit(material) for material in sorted(materials, key=lambda item: item.name)]
    return {"all_sources_opaque": True, "source_count": len(sources),
            "material_count": len(rows), "materials": rows}


def encode_opaque_rgb8(rgba, channel):
    """Encode independent RGB data; do not multiply or divide by bake alpha.

    Caller must first prove the live opaque material contract. Blender's raw
    buffer starts at the bottom row. PNG rows start at the top. Albedo is scene
    linear and uses the sRGB transfer; other supported maps retain linear data.
    Values outside [0, 1] are clipped for explicit RGB8 UNORM output.
    """
    rgba = np.asarray(rgba)
    if (rgba.ndim != 3 or rgba.shape[2] != 4 or min(rgba.shape[:2]) < 1
            or not np.isfinite(rgba).all()):
        raise ValueError("Expected a nonempty finite H x W x 4 image buffer")
    if channel != "albedo" and channel not in DATA_CHANNELS:
        raise ValueError("Unknown RGB data channel: " + channel)
    rgb = np.clip(rgba[:, :, :3].astype(np.float64), 0.0, 1.0)
    if channel == "albedo":
        rgb = np.where(rgb <= 0.0031308, 12.92 * rgb,
                       1.055 * np.power(rgb, 1.0 / 2.4) - 0.055)
    # Round nearest, half up; no scene view transform, dither or alpha operation.
    return np.floor(np.clip(rgb, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)[::-1].copy()


def opaque_rgb_png_payload(rgba, channel):
    """Return deterministic RGB8 PNG bytes using only NumPy and the stdlib."""
    encoded = encode_opaque_rgb8(rgba, channel)
    height, width, _ = encoded.shape

    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff))

    payload = b"\x89PNG\r\n\x1a\n"
    payload += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    if channel == "albedo":
        payload += chunk(b"sRGB", b"\x00")
    # Data maps deliberately have no sRGB/gamma declaration.
    scanlines = np.zeros((height, width * 3 + 1), dtype=np.uint8)
    scanlines[:, 1:] = encoded.reshape((height, width * 3))
    payload += chunk(b"IDAT", zlib.compress(scanlines.tobytes(), level=6))
    payload += chunk(b"IEND", b"")
    return payload, encoded


def write_opaque_rgb_png(path, rgba, channel):
    """Write a new opaque map; retain the raw RGBA evidence separately."""
    payload, encoded = opaque_rgb_png_payload(rgba, channel)
    with Path(path).open("xb") as stream:
        stream.write(payload)
    rgb = np.asarray(rgba)[:, :, :3]
    return {"contract": RGB_OUTPUT_CONTRACT, "file": Path(path).name,
            "png_sha256": hashlib.sha256(payload).hexdigest(),
            "encoded_rgb_sha256": hashlib.sha256(encoded.tobytes()).hexdigest(),
            "png_color_type": 2, "bit_depth": 8, "alpha_channel": False,
            "transfer": "scene_linear_to_srgb" if channel == "albedo" else "linear_data",
            "png_row_order": "top_to_bottom", "alpha_operation": "none",
            "rgb_components_below_zero": int(np.count_nonzero(rgb < 0)),
            "rgb_components_above_one": int(np.count_nonzero(rgb > 1))}


def constant_material_audit(material):
    """Fail closed on the live output graph, not the presence of unused nodes.

    This deliberately accepts only a directly connected, entirely unlinked
    Principled BSDF. It does not attempt to prove arbitrary node graphs constant.
    """
    if material is None or not material.use_nodes or material.node_tree is None:
        return {"eligible": False, "reason": "Missing node material"}
    tree = material.node_tree
    if animated(material) or animated(tree):
        return {"eligible": False, "reason": "Animated or driven material/node tree"}
    outputs = [node for node in tree.nodes
               if node.type == "OUTPUT_MATERIAL" and node.is_active_output]
    if len(outputs) != 1:
        return {"eligible": False, "reason": "Expected one active Material Output"}
    output = outputs[0]
    if output.mute:
        return {"eligible": False, "reason": "Muted Material Output"}
    for name in ("Volume", "Displacement"):
        socket = output.inputs.get(name)
        if socket is not None and (socket.is_linked or len(socket.links)):
            return {"eligible": False, "reason": "Connected " + name}
        value = getattr(socket, "default_value", None)
        if name == "Displacement" and value is not None:
            components = value if hasattr(value, "__len__") else [value]
            if any(abs(float(component)) > 1e-12 for component in components):
                return {"eligible": False, "reason": "Nonzero displacement default"}
    surface = output.inputs.get("Surface")
    if surface is None or len(surface.links) != 1:
        return {"eligible": False, "reason": "Expected one Surface link"}
    link = surface.links[0]
    node = link.from_node
    if (not link.is_valid or getattr(link, "is_muted", False) or node.mute
            or node.type != "BSDF_PRINCIPLED" or link.from_socket.name != "BSDF"):
        return {"eligible": False, "reason": "Surface is not a direct active Principled BSDF"}
    linked = [socket.name for socket in node.inputs if socket.is_linked or len(socket.links)]
    if linked:
        return {"eligible": False, "reason": "Connected Principled inputs", "inputs": linked}
    # An authored constant normal/tangent would require an explicit coordinate
    # interpretation. Native qualifying materials use the implicit geometry normal.
    for socket in node.inputs:
        if socket.name in ("Normal", "Coat Normal", "Tangent"):
            value = getattr(socket, "default_value", None)
            if value is not None and any(abs(float(component)) > 1e-12 for component in value):
                return {"eligible": False, "reason": "Nonzero normal/tangent default: " + socket.name}
    return {"eligible": True, "principled": node.name,
            "unused_nodes": [other.name for other in tree.nodes if other not in (node, output)]}


def classify_sources(sources):
    materials = {slot.material for source in sources for slot in source.material_slots
                 if slot.material is not None}
    audits = {material: constant_material_audit(material) for material in materials}
    accepted, rejected = [], []
    for source in sources:
        slots = list(source.material_slots)
        eligible = bool(slots) and all(slot.material is not None
                                      and audits[slot.material]["eligible"] for slot in slots)
        (accepted if eligible else rejected).append(source)
    return accepted, rejected, {material.name: audit for material, audit in audits.items()}


def get_array(collection, property_name, width, dtype):
    data = np.empty(len(collection) * width, dtype=dtype)
    collection.foreach_get(property_name, data)
    return data.reshape((-1, width)) if width > 1 else data


def evaluated_piece(source, depsgraph, material_map, materials):
    """Copy evaluated polygons/loops unchanged, then transform their geometry.

    Building triangle polygons here changes Blender's smooth-normal fans. Even
    explicit custom normals could not recover those fans within the checked
    tolerance. Keep native polygons and use tessellation only for validation.
    """
    evaluated = source.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=depsgraph)
    try:
        mesh.calc_loop_triangles()
        matrix = np.asarray(evaluated.matrix_world, dtype=np.float64)
        linear = matrix[:3, :3]
        determinant = float(np.linalg.det(linear))
        if not np.isfinite(matrix).all() or abs(determinant) < 1e-12:
            raise ValueError("Singular/nonfinite world transform: " + source.name)
        local = get_array(mesh.vertices, "co", 3, np.float32).astype(np.float64)
        positions = local @ linear.T + matrix[:3, 3]
        positions32 = positions.astype(np.float32)
        loops = get_array(mesh.loops, "vertex_index", 1, np.int32)
        loop_edges = get_array(mesh.loops, "edge_index", 1, np.int32)
        edges = get_array(mesh.edges, "vertices", 2, np.int32)
        edge_sharp = get_array(mesh.edges, "use_edge_sharp", 1, np.bool_)
        loop_starts = get_array(mesh.polygons, "loop_start", 1, np.int32)
        loop_counts = get_array(mesh.polygons, "loop_total", 1, np.int32)
        triangles = get_array(mesh.loop_triangles, "vertices", 3, np.int32)
        triangle_polygons = get_array(mesh.loop_triangles, "polygon_index", 1, np.int32)
        corner_normals = get_array(mesh.corner_normals, "vector", 3, np.float32)
        if len(corner_normals) != len(mesh.loops):
            raise ValueError("Missing evaluated corner normals: " + source.name)
        normals = corner_normals.astype(np.float64)
        # Row vectors: inverse-transpose normal transform is multiplication by inverse.
        normals = normals @ np.linalg.inv(linear)
        lengths = np.linalg.norm(normals, axis=1)
        if not np.isfinite(normals).all() or np.any(lengths < 1e-12):
            raise ValueError("Undefined/nonfinite evaluated normal: " + source.name)
        normals = normals / lengths[:, None]
        if determinant < 0:
            # Keep the first polygon corner; reverse the remaining winding and
            # its outgoing edges, with matching per-corner normal permutation.
            for start, count in zip(loop_starts, loop_counts):
                stop = start + count
                order = np.concatenate(([start], np.arange(stop - 1, start, -1)))
                loops[start:stop] = loops[order]
                normals[start:stop] = normals[order]
                loop_edges[start:stop] = loop_edges[start:stop][::-1]
            triangles = triangles[:, [0, 2, 1]]
        slots = list(evaluated.material_slots)
        slot_mapping = []
        for slot in slots:
            material = slot.material
            # Do not link evaluated/COW material IDs into a new main-database mesh.
            if material is not None:
                material = material.original
            if material is None or not constant_material_audit(material)["eligible"]:
                raise ValueError("Evaluated material no longer qualifies: " + source.name)
            key = material.as_pointer()
            if key not in material_map:
                material_map[key] = len(materials)
                materials.append(material)
            slot_mapping.append(material_map[key])
        material_indices = get_array(mesh.polygons, "material_index", 1, np.int32)
        if len(material_indices) and int(material_indices.max()) >= len(slot_mapping):
            raise ValueError("Invalid evaluated material index: " + source.name)
        material_indices = np.asarray(slot_mapping, dtype=np.int32)[material_indices]
        smooth = get_array(mesh.polygons, "use_smooth", 1, np.bool_)
        return {
            "positions": positions32, "loops": loops, "loop_edges": loop_edges,
            "edges": edges, "edge_sharp": edge_sharp,
            "loop_starts": loop_starts, "loop_counts": loop_counts,
            "triangles": triangles, "triangle_polygons": triangle_polygons,
            "normals": normals.astype(np.float32),
            "materials": material_indices, "smooth": smooth,
            "record": {"source": source.name, "vertices": len(positions),
                       "polygons": len(loop_counts), "corners": len(loops),
                       "triangles": len(triangles), "negative_transform": determinant < 0,
                       "world_matrix": matrix.tolist(),
                       "position_roundoff_max": float(np.max(np.abs(positions - positions32)))},
        }
    finally:
        evaluated.to_mesh_clear()


def canonical_tessellation(triangles, polygons):
    """Ignore triangle ordering/cyclic rotation; retain winding and owner face."""
    first = np.argmin(triangles, axis=1)
    columns = (first[:, None] + np.arange(3)[None, :]) % 3
    ordered = np.take_along_axis(triangles, columns, axis=1)
    rows = np.column_stack((polygons, ordered))
    return rows[np.lexsort((rows[:, 3], rows[:, 2], rows[:, 1], rows[:, 0]))]


def create_merged_donor(scene, sources):
    """Create an unparented static helper; do not modify or weld native meshes."""
    import bpy
    from mathutils import Matrix

    bpy.context.view_layer.update()
    # A merged object's ray participation must not change AO/visibility. Keep
    # these properties only when the originals agree; do not silently choose one.
    object_properties = ("visible_camera", "visible_diffuse", "visible_glossy",
                         "visible_transmission", "visible_volume_scatter", "visible_shadow",
                         "is_holdout", "is_shadow_catcher")
    cycles_properties = ("shadow_terminator_geometry_offset", "shadow_terminator_shading_offset")
    settings = {}
    for owner_name, names in (("object", object_properties), ("cycles", cycles_properties)):
        for name in names:
            owners = sources if owner_name == "object" else [getattr(source, "cycles", None) for source in sources]
            if not all(owner is not None and hasattr(owner, name) for owner in owners):
                continue
            values = [getattr(owner, name) for owner in owners]
            if any(value != values[0] for value in values[1:]):
                raise ValueError("Donors differ in ray/shading property: " + owner_name + "." + name)
            settings[(owner_name, name)] = values[0]
    for source in sources:
        for modifier in source.modifiers:
            if modifier.show_viewport != modifier.show_render:
                raise ValueError("Viewport/render modifier mismatch: " + source.name + "/" + modifier.name)
            if modifier.type == "SUBSURF" and modifier.show_render and modifier.levels != modifier.render_levels:
                raise ValueError("Viewport/render subdivision mismatch: " + source.name)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    material_map, materials, pieces = {}, [], []
    for source in sources:
        pieces.append(evaluated_piece(source, depsgraph, material_map, materials))
    vertex_offset = edge_offset = loop_offset = polygon_offset = 0
    for piece in pieces:
        piece["loops"] += vertex_offset
        piece["edges"] += vertex_offset
        piece["triangles"] += vertex_offset
        piece["loop_edges"] += edge_offset
        piece["loop_starts"] += loop_offset
        piece["triangle_polygons"] += polygon_offset
        vertex_offset += len(piece["positions"])
        edge_offset += len(piece["edges"])
        loop_offset += len(piece["loops"])
        polygon_offset += len(piece["loop_counts"])
    loops = np.concatenate([piece["loops"] for piece in pieces])
    edges = np.concatenate([piece["edges"] for piece in pieces])
    loop_edges = np.concatenate([piece["loop_edges"] for piece in pieces])
    loop_starts = np.concatenate([piece["loop_starts"] for piece in pieces])
    loop_counts = np.concatenate([piece["loop_counts"] for piece in pieces])
    edge_sharp = np.concatenate([piece["edge_sharp"] for piece in pieces])
    smooth = np.concatenate([piece["smooth"] for piece in pieces])
    normals = np.concatenate([piece["normals"] for piece in pieces])
    positions = np.concatenate([piece["positions"] for piece in pieces])
    expected_triangles = np.concatenate([piece["triangles"] for piece in pieces])
    expected_triangle_polygons = np.concatenate([piece["triangle_polygons"] for piece in pieces])
    polygon_count = len(loop_counts)
    mesh = bpy.data.meshes.new("REVIEW_constant_donor_mesh")
    helper = None
    try:
        mesh.vertices.add(len(positions))
        mesh.edges.add(len(edges))
        mesh.loops.add(len(loops))
        mesh.polygons.add(polygon_count)
        mesh.vertices.foreach_set("co", positions.ravel())
        mesh.edges.foreach_set("vertices", edges.ravel())
        mesh.edges.foreach_set("use_edge_sharp", edge_sharp)
        mesh.loops.foreach_set("vertex_index", loops)
        mesh.loops.foreach_set("edge_index", loop_edges)
        mesh.polygons.foreach_set("loop_start", loop_starts)
        mesh.polygons.foreach_set("loop_total", loop_counts)
        mesh.polygons.foreach_set("use_smooth", smooth)
        for material in materials:
            mesh.materials.append(material)
        expected_materials = np.concatenate([piece["materials"] for piece in pieces])
        mesh.polygons.foreach_set("material_index", expected_materials)
        mesh.update()
        if mesh.validate(verbose=False, clean_customdata=False):
            raise ValueError("Merged evaluated surface required mesh repair; refusing bake")
        mesh.normals_split_custom_set(normals)
        mesh.update()
        actual_normals = get_array(mesh.corner_normals, "vector", 3, np.float32)
        normal_error = float(np.max(np.abs(actual_normals - normals)))
        if normal_error > NORMAL_TOLERANCE:
            raise ValueError(f"Corner-normal preservation error {normal_error:.8g}")
        if not np.array_equal(get_array(mesh.vertices, "co", 3, np.float32), positions):
            raise ValueError("Merged positions changed")
        for collection, name, width, dtype, expected in (
            (mesh.loops, "vertex_index", 1, np.int32, loops),
            (mesh.loops, "edge_index", 1, np.int32, loop_edges),
            (mesh.edges, "vertices", 2, np.int32, edges),
            (mesh.polygons, "loop_start", 1, np.int32, loop_starts),
            (mesh.polygons, "loop_total", 1, np.int32, loop_counts),
            (mesh.polygons, "use_smooth", 1, np.bool_, smooth),
            (mesh.edges, "use_edge_sharp", 1, np.bool_, edge_sharp),
        ):
            if not np.array_equal(get_array(collection, name, width, dtype), expected):
                raise ValueError("Merged polygon/loop/edge data changed: " + name)
        if not np.array_equal(get_array(mesh.polygons, "material_index", 1, np.int32), expected_materials):
            raise ValueError("Merged material assignments changed")
        mesh.calc_loop_triangles()
        actual_triangles = get_array(mesh.loop_triangles, "vertices", 3, np.int32)
        actual_triangle_polygons = get_array(mesh.loop_triangles, "polygon_index", 1, np.int32)
        if not np.array_equal(canonical_tessellation(actual_triangles, actual_triangle_polygons),
                              canonical_tessellation(expected_triangles, expected_triangle_polygons)):
            raise ValueError("Merged evaluated tessellation changed")
        helper = bpy.data.objects.new("REVIEW_constant_donor", mesh)
        helper.matrix_world = Matrix.Identity(4)
        for (owner_name, name), value in settings.items():
            setattr(helper if owner_name == "object" else helper.cycles, name, value)
        helper[SOURCE_TAG] = False
        scene.collection.objects.link(helper)
        stats = {"source_count": len(sources), "triangles": len(actual_triangles),
                 "polygons": polygon_count, "corners": len(loops),
                 "vertices": len(positions), "material_count": len(materials),
                 "polygon_topology_preserved": True, "tessellation_preserved": True,
                 "corner_normal_error_max": normal_error,
                 "normal_tolerance": NORMAL_TOLERANCE,
                 "parts": [piece["record"] for piece in pieces]}
        return helper, stats
    except Exception:
        if helper is not None:
            bpy.data.objects.remove(helper, do_unlink=True)
        bpy.data.meshes.remove(mesh)
        raise


@contextmanager
def merged_donors(scene, sources):
    """Hide only these original donors, retain their data, restore on every exit."""
    import bpy

    saved = [(source, source.hide_render) for source in sources]
    helper, stats = create_merged_donor(scene, sources)
    try:
        for source, _ in saved:
            source.hide_render = True
        bpy.context.view_layer.update()
        yield helper, stats
    finally:
        for source, hidden in saved:
            source.hide_render = hidden
        mesh = helper.data
        bpy.data.objects.remove(helper, do_unlink=True)
        bpy.data.meshes.remove(mesh)
        bpy.context.view_layer.update()


@contextmanager
def unchanged_donors(sources):
    yield None, {"source_count": len(sources), "merged": False}


def bake_probe(args):
    import bpy

    started = time.perf_counter()
    repo = Path(__file__).resolve().parents[3]
    source_path = Path(bpy.data.filepath).resolve()
    output = args.output.resolve()
    if source_path.name != "prepared.blend":
        raise ValueError("Load the private prepared.blend checkpoint")
    if output.is_relative_to(repo):
        raise ValueError("Private bake evidence must be outside the git checkout")
    if output.exists() and any(output.iterdir()):
        raise ValueError("Use a new empty output directory for each run")
    output.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    target = scene.objects.get(TARGET_NAME)
    if target is None or target.type != "MESH":
        raise ValueError("Prepared runtime target is missing")
    sources = sorted((obj for obj in scene.objects if obj.type == "MESH"
                      and bool(obj.get(SOURCE_TAG, False))), key=lambda obj: obj.name)
    # Validate the original live shaders before any EMIT bake override.
    opacity_audit = opaque_sources_audit(sources)
    eligible, rejected, material_audit = classify_sources(sources)
    eligible_by_name = {obj.name: obj for obj in eligible}
    names = sorted(eligible_by_name) if args.scope == "full" else list(args.donor or SAMPLE_NAMES)
    if len(names) != len(set(names)) or len(names) < 2:
        raise ValueError("Choose at least two distinct constant-material donors")
    missing = [name for name in names if name not in eligible_by_name]
    if missing:
        raise ValueError("Missing or nonconstant donors: " + repr(missing))
    group = [eligible_by_name[name] for name in sorted(names)]
    if any(obj.hide_render or not obj.visible_get() for obj in sources):
        raise ValueError("Prepared donors must already be visible; visibility will not be broadened")
    selected = sources if args.scope == "full" else group
    other_selected = [obj for obj in selected if obj not in group]
    signature = {
        "prepared_sha256": digest(source_path), "script_sha256": digest(__file__),
        "target": target.name, "scope": args.scope, "channel": args.channel,
        "group": [obj.name for obj in group],
        "projection_sources": [obj.name for obj in selected],
        "all_scene_sources": [obj.name for obj in sources],
        "size": args.size, "samples": args.samples, "threads": args.threads,
        "seed": 0, "cage_extrusion": .018, "max_ray_distance": .040,
        "margin": 8, "blender": bpy.app.version_string,
        "float_image_buffer": True, "persistent_data": False, "device": "CPU",
        "blender_build": bpy.app.build_hash.decode("ascii"),
        "output_contract": RGB_OUTPUT_CONTRACT,
    }
    report = {"approved": False, "status": "preparing", "mode": args.mode,
              "signature": signature, "eligible_sources": len(eligible),
              "unchanged_coordinate_dependent_sources": len(rejected),
              "material_audit": material_audit,
              "opacity_audit": opacity_audit,
              "limits": "Isolated offline donor experiment. No visual, animation or runtime performance acceptance."}
    report_path = output / "report.json"
    write_json(report_path, report)
    original_mesh = target.data
    original_active_material = target.active_material_index
    original_selection = [(obj, obj.select_get()) for obj in scene.objects]
    original_active = bpy.context.view_layer.objects.active
    working_mesh = original_mesh.copy()
    material = bpy.data.materials.new("REVIEW_probe_target")
    material.use_nodes = True
    image = None
    restorers = []
    try:
        target.data = working_mesh
        working_mesh.materials.clear()
        working_mesh.materials.append(material)
        for polygon in working_mesh.polygons:
            polygon.material_index = 0
        if working_mesh.uv_layers.active is None:
            raise ValueError("Target has no active atlas UV")
        image = bpy.data.images.new("REVIEW_probe_rgba", width=args.size, height=args.size,
                                    alpha=True, float_buffer=True)
        image.alpha_mode = "STRAIGHT"
        image.colorspace_settings.name = "sRGB" if args.channel == "albedo" else "Non-Color"
        texture = material.node_tree.nodes.new("ShaderNodeTexImage")
        texture.image = image
        material.node_tree.nodes.active = texture
        report["target_opacity_audit"] = opaque_material_audit(material)
        scene.render.engine = "CYCLES"
        scene.cycles.device = "CPU"
        scene.cycles.samples = args.samples
        scene.cycles.use_adaptive_sampling = False
        scene.cycles.use_denoising = False
        scene.cycles.seed = 0
        scene.cycles.use_animated_seed = False
        scene.render.threads_mode = "FIXED"
        scene.render.threads = args.threads
        scene.render.use_persistent_data = False
        context = merged_donors(scene, group) if args.mode == "merged" else unchanged_donors(group)
        build_start = time.perf_counter()
        with context as (helper, stats):
            report["donor_build_seconds"] = time.perf_counter() - build_start
            report["merge"] = stats
            donors = other_selected + ([helper] if helper is not None else group)
            report["bake_source_count"] = len(donors)
            for obj in bpy.context.selected_objects:
                obj.select_set(False)
            for obj in donors:
                obj.select_set(True)
            target.select_set(True)
            bpy.context.view_layer.objects.active = target
            if args.channel in ("albedo", "roughness", "metallic", "cloth"):
                sys.path.insert(0, str(Path(__file__).resolve().parent))
                from export_runtime import source_material_override
                for source_material in sorted({slot.material for obj in sources for slot in obj.material_slots
                                               if slot.material is not None}, key=lambda item: item.name):
                    restorers.append(source_material_override(source_material, args.channel))
            report["status"] = "baking"
            write_json(report_path, report)
            print("CONSTANT_DONOR_PROBE_START", args.mode, args.channel, len(donors), flush=True)
            bake_start = time.perf_counter()
            bpy.ops.object.bake(
                type="NORMAL" if args.channel == "normal" else "AO" if args.channel == "ao" else "EMIT",
                use_selected_to_active=True, use_clear=True, use_cage=False,
                cage_extrusion=.018, max_ray_distance=.040, margin=8,
                normal_space="TANGENT", normal_r="POS_X", normal_g="POS_Y", normal_b="POS_Z",
                target="IMAGE_TEXTURES", save_mode="INTERNAL", uv_layer=working_mesh.uv_layers.active.name,
            )
            report["bake_seconds"] = time.perf_counter() - bake_start
            rgba = np.empty(args.size * args.size * 4, dtype=np.float32)
            image.pixels.foreach_get(rgba)
            rgba = rgba.reshape((args.size, args.size, 4))
            if not np.isfinite(rgba).all():
                raise ValueError("Nonfinite baked RGBA values")
            report["alpha_covered_pixels"] = int(np.count_nonzero(rgba[:, :, 3] > 0))
            if not report["alpha_covered_pixels"]:
                raise ValueError("Empty bake cannot establish parity")
            np.savez_compressed(output / "rgba.npz", rgba=rgba)
            # Preserve the legacy serialization as failure/diagnostic evidence.
            # It must never be confused with the corrected opaque data map.
            image.filepath_raw = str(output / (args.channel + "-raw-rgba.png"))
            image.file_format = "PNG"
            image.save()
            report["legacy_rgba_png"] = args.channel + "-raw-rgba.png"
            report["rgb_output"] = write_opaque_rgb_png(output / (args.channel + ".png"),
                                                       rgba, args.channel)
        report["status"] = "complete"
    except Exception as error:
        report["status"] = "failed"
        report["error"] = str(error)
        raise
    finally:
        for restore in reversed(restorers):
            restore()
        target.data = original_mesh
        target.active_material_index = original_active_material
        bpy.data.meshes.remove(working_mesh)
        bpy.data.materials.remove(material)
        if image is not None:
            bpy.data.images.remove(image)
        for obj, selected_before in original_selection:
            obj.select_set(selected_before)
        bpy.context.view_layer.objects.active = original_active
        report["total_seconds"] = time.perf_counter() - started
        report["original_target_data_restored"] = target.data == original_mesh
        write_json(report_path, report)
    print("CONSTANT_DONOR_PROBE_COMPLETE", json.dumps({key: report[key] for key in
          ("mode", "bake_source_count", "donor_build_seconds", "bake_seconds", "total_seconds")}), flush=True)


def compare_probes(args):
    reports = [json.loads((directory / "report.json").read_text()) for directory in (args.separate, args.merged)]
    first, second = reports
    if first["mode"] != "separate" or second["mode"] != "merged":
        raise ValueError("Supply separate then merged output directories")
    if any(report["status"] != "complete" for report in reports):
        raise ValueError("Both probes must have completed")
    if first["signature"] != second["signature"]:
        raise ValueError("Different prepared source, script, target, donors, channel or settings")
    arrays = []
    for directory in (args.separate, args.merged):
        with np.load(directory / "rgba.npz") as archive:
            arrays.append(archive["rgba"].astype(np.float64))
    a, b = arrays
    if a.shape != b.shape or not all(np.isfinite(array).all() for array in arrays):
        raise ValueError("Mismatched or nonfinite RGBA arrays")
    delta = np.abs(a - b)
    union = (a[:, :, 3] > 0) | (b[:, :, 3] > 0)
    if not union.any():
        raise ValueError("Two empty bakes cannot establish parity")
    result = {
        "approved": False, "signature": first["signature"],
        "rgba_space": "Blender image-buffer RGBA; RGB scene-linear for albedo, not encoded PNG bytes",
        "rgba_exact_equal": bool(np.array_equal(a, b)),
        "rgba_max_abs": float(delta.max()),
        "rgba_max_abs_per_channel": delta.max(axis=(0, 1)).tolist(),
        "rgba_rmse_per_channel": np.sqrt(np.mean(delta * delta, axis=(0, 1))).tolist(),
        "raw_rgb_exact_equal": bool(np.array_equal(a[:, :, :3], b[:, :, :3])),
        "raw_rgb_max_abs": float(delta[:, :, :3].max()),
        "covered_union_pixels": int(union.sum()),
        "different_pixels": int(np.count_nonzero(np.any(delta > 0, axis=2))),
        "different_alpha_pixels": int(np.count_nonzero(delta[:, :, 3] > 0)),
        "separate": {key: first[key] for key in ("bake_source_count", "donor_build_seconds", "bake_seconds", "total_seconds")},
        "merged": {key: second[key] for key in ("bake_source_count", "donor_build_seconds", "bake_seconds", "total_seconds")},
        "limits": "One offline pair; includes no runtime/FPS evidence. AO sample noise can differ after regrouping.",
    }
    if args.max_abs is not None:
        result["max_abs_limit"] = args.max_abs
        result["within_requested_limit"] = bool(delta.max() <= args.max_abs)
    if first["signature"].get("output_contract") == RGB_OUTPUT_CONTRACT:
        encoded_arrays = []
        for directory, report, rgba in zip((args.separate, args.merged), reports, arrays):
            if not report.get("opacity_audit", {}).get("all_sources_opaque"):
                raise ValueError("Missing live source opacity guard")
            if not report.get("target_opacity_audit"):
                raise ValueError("Missing live target opacity guard")
            saved = report["rgb_output"]
            channel = report["signature"]["channel"]
            payload, encoded = opaque_rgb_png_payload(rgba, channel)
            payload_hash = hashlib.sha256(payload).hexdigest()
            if (saved["contract"] != RGB_OUTPUT_CONTRACT
                    or saved["png_sha256"] != payload_hash
                    or digest(directory / saved["file"]) != payload_hash
                    or saved["encoded_rgb_sha256"] != hashlib.sha256(encoded.tobytes()).hexdigest()):
                raise ValueError("Saved opaque RGB output differs from the guarded raw buffer")
            encoded_arrays.append(encoded)
        encoded_delta = np.abs(encoded_arrays[0].astype(np.int16) - encoded_arrays[1].astype(np.int16))
        result["opaque_rgb_output"] = {
            "contract": RGB_OUTPUT_CONTRACT,
            "encoded_rgb_exact_equal": bool(np.array_equal(*encoded_arrays)),
            "encoded_rgb_max_abs_byte": int(encoded_delta.max()),
            "different_rgb_pixels": int(np.count_nonzero(np.any(encoded_delta > 0, axis=2))),
            "saved_pngs_verified_against_raw_buffers": True,
            "limits": "Corrected opaque RGB output contract. Does not turn a failed raw-RGBA criterion into a pass.",
        }
    if args.require_rgb_exact:
        if "opaque_rgb_output" not in result:
            raise ValueError("Exact encoded RGB comparison requires guarded opaque RGB output reports")
        result["opaque_rgb_output"]["required_exact_equal"] = True
    write_json(args.output, result)
    print(json.dumps(result, indent=2))
    if args.max_abs is not None and not result["within_requested_limit"]:
        raise SystemExit(2)
    if args.require_rgb_exact and not result["opaque_rgb_output"]["encoded_rgb_exact_equal"]:
        raise SystemExit(2)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    bake = subparsers.add_parser("bake")
    bake.add_argument("--mode", choices=("separate", "merged"), required=True)
    bake.add_argument("--output", type=Path, required=True)
    bake.add_argument("--scope", choices=("sample", "full"), default="sample")
    bake.add_argument("--donor", action="append", help="Exact sample donor name; repeat for each donor")
    bake.add_argument("--channel", choices=("albedo", "roughness", "metallic", "cloth", "normal", "ao"), default="albedo")
    bake.add_argument("--size", type=int, default=256)
    bake.add_argument("--samples", type=int, default=8)
    bake.add_argument("--threads", type=int, default=2)
    compare = subparsers.add_parser("compare")
    compare.add_argument("separate", type=Path)
    compare.add_argument("merged", type=Path)
    compare.add_argument("--output", type=Path, required=True)
    compare.add_argument("--max-abs", type=float, help="Optional explicit linear RGBA difference limit")
    compare.add_argument("--require-rgb-exact", action="store_true",
                         help="Require exact guarded opaque RGB8 output; raw RGBA remains separately reported")
    arguments = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    args = parser.parse_args(arguments)
    if args.command == "bake":
        if args.scope == "full" and args.donor:
            parser.error("--donor applies only to sample scope")
        if not 32 <= args.size <= 2048 or not 1 <= args.samples <= 64 or not 1 <= args.threads <= 8:
            parser.error("size 32..2048, samples 1..64 and threads 1..8 are required")
        bake_probe(args)
    else:
        if args.max_abs is not None and (not np.isfinite(args.max_abs) or args.max_abs < 0):
            parser.error("--max-abs must be finite and nonnegative")
        compare_probes(args)


if __name__ == "__main__":
    main()
