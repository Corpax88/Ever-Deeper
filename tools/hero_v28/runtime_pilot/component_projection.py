"""Isolate native source/target pairs temporarily for material projection.

All native originals are restored. Only a disposable target mesh is moved.
AO deliberately stays assembled so genuine inter-part occlusion is retained.
"""
from contextlib import contextmanager
import math

import numpy as np

from constant_donor_probe import get_array

SOURCE_INDEX = 'native_runtime_source_index'


def translation_invariant_materials(sources):
    """Reject live coordinate inputs whose value changes with object location."""
    allowed_coordinates = {'Object', 'Generated', 'UV', 'Normal'}
    for material in {slot.material for o in sources for slot in o.material_slots}:
        outputs = [n for n in material.node_tree.nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output]
        pending, seen = list(outputs), set()
        while pending:
            node = pending.pop()
            if node in seen: continue
            seen.add(node)
            if node.type in {'GROUP', 'TEX_ENVIRONMENT', 'TEX_SKY', 'OBJECT_INFO', 'CAMERA', 'LIGHT_PATH', 'PARTICLE_INFO', 'HAIR_INFO', 'TEX_WHITE_NOISE'}:
                raise ValueError('Unproven translated shader: '+material.name+'/'+node.type)
            if node.type == 'TEX_COORD':
                used = {s.name for s in node.outputs if s.is_linked}
                if node.object is not None or node.from_instancer or not used.issubset(allowed_coordinates):
                    raise ValueError('World-dependent coordinate: '+material.name)
            if node.type == 'NEW_GEOMETRY':
                used = {s.name for s in node.outputs if s.is_linked}
                if not used.issubset({'Normal', 'True Normal', 'Tangent', 'Parametric'}):
                    raise ValueError('World-dependent geometry shader: '+material.name)
            for socket in node.inputs:
                for link in socket.links: pending.append(link.from_node)


def transform_properties(obj):
    return {name: getattr(obj, name).copy() if hasattr(getattr(obj, name), 'copy') else tuple(getattr(obj, name))
            for name in ('location', 'rotation_euler', 'rotation_quaternion', 'rotation_axis_angle', 'scale')}


@contextmanager
def isolated_components(scene, target, sources, channel):
    import bpy
    from mathutils import Vector

    if channel == 'ao':
        yield {'strategy': 'assembled_native_ao', 'source_count': len(sources),
               'reason': 'Preserve native inter-part occlusion.'}
        return
    translation_invariant_materials(sources)
    mesh = target.data
    attribute = mesh.attributes.get(SOURCE_INDEX)
    if attribute is None or attribute.domain != 'FACE' or attribute.data_type != 'INT':
        raise ValueError('Prepared target has no exact native component ownership')
    source_by_index = {int(o.get(SOURCE_INDEX, -1)): o for o in sources}
    if len(source_by_index) != len(sources) or set(source_by_index) != set(range(len(sources))):
        raise ValueError('Native source indices must be unique and complete')
    face_ids = get_array(attribute.data, 'value', 1, np.int32)
    if set(np.unique(face_ids)) != set(source_by_index):
        raise ValueError('Target/source ownership mismatch')
    loops = get_array(mesh.loops, 'vertex_index', 1, np.int32)
    counts = get_array(mesh.polygons, 'loop_total', 1, np.int32)
    loop_ids = np.repeat(face_ids, counts)
    vertex_ids = np.full(len(mesh.vertices), -1, dtype=np.int32)
    vertex_ids[loops] = loop_ids
    if not np.array_equal(vertex_ids[loops], loop_ids):
        raise ValueError('A target vertex is shared between native source components')
    # Geometry is prepared in native bind pose; moving object transforms must
    # never alter an active animated deformation or camera-dependent shader.
    for rig in (o for o in scene.objects if o.type == 'ARMATURE'):
        for bone in rig.pose.bones:
            if max(abs(bone.matrix[i][j]-bone.bone.matrix_local[i][j]) for i in range(4) for j in range(4)) > 1e-5:
                raise ValueError('Component isolation requires exact native bind pose')
    bpy.context.view_layer.update()
    original_world = {o: o.matrix_world.copy() for o in sources}
    original_properties = {o: transform_properties(o) for o in sources}
    original_vertices = get_array(mesh.vertices, 'co', 3, np.float32)
    original_normals = get_array(mesh.corner_normals, 'vector', 3, np.float32)
    # Every part starts inside the same native bounding box. A uniform cell
    # larger than that box plus both ray ranges proves other parts unreachable.
    points = np.asarray([list(o.matrix_world @ Vector(c)) for o in sources for c in o.bound_box])
    span = points.max(0)-points.min(0)
    spacing = math.ceil(float(span.max()) + 2*(.018+.040) + .1)
    side = math.ceil(len(sources)**(1/3))
    offsets = np.asarray([[(i % side)-(side-1)/2,
                           ((i//side) % side)-(side-1)/2,
                           (i//(side*side))-(side-1)/2] for i in range(len(sources))], dtype=np.float64)*spacing
    local_offsets = offsets @ np.asarray(target.matrix_world.inverted().to_3x3()).T
    moved = original_vertices.astype(np.float64)
    assigned = vertex_ids >= 0
    moved[assigned] += local_offsets[vertex_ids[assigned]]
    moved32 = moved.astype(np.float32)
    roundoff = float(np.abs(moved32.astype(np.float64)-moved).max())
    if roundoff > 3e-6: raise ValueError('Translated target precision exceeded3e-6')
    def depth(o):
        result = 0
        while o.parent is not None: result += 1; o = o.parent
        return result
    ordered = sorted(sources, key=depth)
    report = {'strategy': 'exact_native_source_components', 'source_count': len(sources),
              'source_index_attribute': SOURCE_INDEX, 'spacing': spacing,
              'native_bounds_span': span.tolist(),
              'minimum_other_component_gap': float(spacing-span.max()),
              'target_translation_roundoff_max': roundoff,
              'unreferenced_vertices_unchanged': int((~assigned).sum()),
              'restored_original_transforms': False}
    try:
        mesh.vertices.foreach_set('co', moved32.ravel())
        mesh.update()
        mesh.normals_split_custom_set(original_normals)
        mesh.update()
        normal_error = float(np.abs(get_array(mesh.corner_normals, 'vector', 3, np.float32)-original_normals).max())
        report['target_corner_normal_error_max'] = normal_error
        if normal_error > 3e-4:
            raise ValueError('Translated target corner normals exceeded unchanged3e-4 bound')
        for o in ordered:
            matrix = original_world[o].copy()
            matrix.translation += Vector(offsets[int(o[SOURCE_INDEX])])
            o.matrix_world = matrix
        bpy.context.view_layer.update()
        for i, o in source_by_index.items():
            expected = np.asarray(original_world[o]).copy(); expected[:3, 3] += offsets[i]
            if np.max(np.abs(np.asarray(o.matrix_world)-expected)) > 3e-6:
                raise ValueError('Native source translation changed beyond rounding: '+o.name)
        yield report
    finally:
        mesh.vertices.foreach_set('co', original_vertices.ravel())
        mesh.update()
        for o in ordered:
            for name, value in original_properties[o].items(): setattr(o, name, value)
        bpy.context.view_layer.update()
        report['restored_original_transforms'] = all(
            np.array_equal(np.asarray(o.matrix_world), np.asarray(original_world[o])) for o in sources)
        if not report['restored_original_transforms']:
            raise ValueError('Native source transforms did not restore exactly')
