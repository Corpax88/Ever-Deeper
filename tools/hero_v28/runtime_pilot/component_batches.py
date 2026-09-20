"""Project native materials without moving geometry or re-encoding normals.

Only mutually unreachable original components share a bake. Inactive receiver
UVs are outside the atlas. AO deliberately uses the existing assembled path.
"""
from contextlib import ExitStack, contextmanager
import hashlib
import time

import numpy as np

import constant_donor_probe as probe

SOURCE_INDEX = 'native_runtime_source_index'
RAY_REACH = .018 + .040


def fingerprint(mesh):
    digest = hashlib.sha256()
    for collection, name, width, dtype in (
        (mesh.vertices, 'co', 3, np.float32),
        (mesh.corner_normals, 'vector', 3, np.float32),
        (mesh.loops, 'vertex_index', 1, np.int32),
        (mesh.polygons, 'loop_start', 1, np.int32),
        (mesh.polygons, 'loop_total', 1, np.int32),
    ):
        digest.update(probe.get_array(collection, name, width, dtype).tobytes())
    return digest.hexdigest()


class ComponentBatches:
    def __init__(self, scene, target, sources):
        import bpy

        self.mesh = target.data
        self.uv = self.mesh.uv_layers.active
        self.original_uv = probe.get_array(self.uv.data, 'uv', 2, np.float32)
        self.geometry_sha = fingerprint(self.mesh)
        self.transforms = {o: np.asarray(o.matrix_world).copy() for o in sources}
        attribute = self.mesh.attributes.get(SOURCE_INDEX)
        if attribute is None or attribute.domain != 'FACE' or attribute.data_type != 'INT':
            raise ValueError('Missing exact native receiver ownership')
        self.source_by_id = {int(o.get(SOURCE_INDEX, -1)): o for o in sources}
        if len(self.source_by_id) != len(sources) or set(self.source_by_id) != set(range(len(sources))):
            raise ValueError('Native source ownership is incomplete or duplicated')
        face_ids = probe.get_array(attribute.data, 'value', 1, np.int32)
        if set(np.unique(face_ids)) != set(self.source_by_id):
            raise ValueError('Native source and receiver ownership differ')
        self.loop_ids = np.repeat(face_ids, probe.get_array(self.mesh.polygons, 'loop_total', 1, np.int32))
        loops = probe.get_array(self.mesh.loops, 'vertex_index', 1, np.int32)
        vertices = probe.get_array(self.mesh.vertices, 'co', 3, np.float32)
        world = np.asarray(target.matrix_world)
        corners = vertices[loops].astype(np.float64) @ world[:3, :3].T + world[:3, 3]
        low = np.full((len(sources), 3), np.inf)
        high = np.full((len(sources), 3), -np.inf)
        np.minimum.at(low, self.loop_ids, corners)
        np.maximum.at(high, self.loop_ids, corners)
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        for index, source in self.source_by_id.items():
            evaluated = source.evaluated_get(depsgraph)
            mesh = evaluated.to_mesh()
            try:
                points = probe.get_array(mesh.vertices, 'co', 3, np.float32).astype(np.float64)
                matrix = np.asarray(evaluated.matrix_world)
                points = points @ matrix[:3, :3].T + matrix[:3, 3]
                low[index] = np.minimum(low[index], points.min(0))
                high[index] = np.maximum(high[index], points.max(0))
            finally:
                evaluated.to_mesh_clear()
        if not np.isfinite(low).all() or not np.isfinite(high).all():
            raise ValueError('Nonfinite native component bounds')
        # Expand both boxes by the full ray reach plus rounding slack.
        low -= RAY_REACH + 1e-5
        high += RAY_REACH + 1e-5
        overlap = np.all(low[:, None, :] <= high[None, :, :], axis=2) & np.all(high[:, None, :] >= low[None, :, :], axis=2)
        groups = []
        for index in sorted(self.source_by_id, key=lambda i: (-int(overlap[i].sum()), i)):
            for group in groups:
                if not overlap[index, group].any():
                    group.append(index)
                    break
            else:
                groups.append([index])
        for group in groups:
            assert int(overlap[np.ix_(group, group)].sum()) == len(group)
        assert sorted(i for group in groups for i in group) == list(range(len(sources)))
        self.groups = groups
        self.report = {'strategy': 'native_spatially_disjoint_components_v1',
            'source_count': len(sources), 'group_count': len(groups),
            'source_index_attribute': SOURCE_INDEX, 'expanded_ray_reach': RAY_REACH + 1e-5,
            'groups': [[self.source_by_id[i].name for i in group] for group in groups],
            'geometry_normals_topology_sha256_before': self.geometry_sha,
            'restored_original_transforms': False, 'restored_original_uv': False,
            'geometry_normals_topology_unchanged': False, 'batches': []}

    def activate(self, group):
        active = np.isin(self.loop_ids, group)
        masked = np.full_like(self.original_uv, 2.0)
        masked[active] = self.original_uv[active]
        self.uv.data.foreach_set('uv', masked.ravel())
        self.mesh.update()

    def restore(self):
        self.uv.data.foreach_set('uv', self.original_uv.ravel())
        self.mesh.update()
        self.report['restored_original_uv'] = bool(np.array_equal(
            probe.get_array(self.uv.data, 'uv', 2, np.float32), self.original_uv))
        self.report['restored_original_transforms'] = all(np.array_equal(np.asarray(o.matrix_world), m)
            for o, m in self.transforms.items())
        after = fingerprint(self.mesh)
        self.report['geometry_normals_topology_sha256_after'] = after
        self.report['geometry_normals_topology_unchanged'] = after == self.geometry_sha
        if not all(self.report[key] for key in ('restored_original_uv', 'restored_original_transforms', 'geometry_normals_topology_unchanged')):
            raise ValueError('Native receiver or source data changed during component bake')


def read_image(image, size):
    rgba = np.empty(size * size * 4, dtype=np.float32)
    image.pixels.foreach_get(rgba)
    return rgba.reshape((size, size, 4))


@contextmanager
def white_surfaces(materials):
    """An explicit emitted-white donor hit probe, independent of bake alpha."""
    with ExitStack() as restorers:
        for material in materials:
            nodes, links = material.node_tree.nodes, material.node_tree.links
            output = next(n for n in nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output)
            old_links = [(link.from_socket, link.to_socket) for link in output.inputs['Surface'].links]
            emission = nodes.new('ShaderNodeEmission')
            emission.inputs['Color'].default_value = (1, 1, 1, 1)
            links.new(emission.outputs[0], output.inputs['Surface'])
            def restore(nodes=nodes, links=links, node=emission, old=old_links):
                nodes.remove(node)
                for a, b in old:
                    links.new(a, b)
            restorers.callback(restore)
        yield


def pad_uncovered(rgba, coverage, radius=8):
    """Copy the nearest covered texel in a bounded Euclidean disk, outside only."""
    output = rgba.copy()
    filled = coverage.copy()
    height, width = coverage.shape
    offsets = sorted((dx*dx+dy*dy, dy, dx) for dy in range(-radius, radius+1)
                     for dx in range(-radius, radius+1) if 0 < dx*dx+dy*dy <= radius*radius)
    for _, dy, dx in offsets:
        dest = (slice(max(0, dy), min(height, height+dy)), slice(max(0, dx), min(width, width+dx)))
        src = (slice(max(0, -dy), min(height, height-dy)), slice(max(0, -dx), min(width, width-dx)))
        use = coverage[src] & ~filled[dest]
        output[dest][use] = rgba[src][use]
        filled[dest][use] = True
    assert np.array_equal(output[coverage], rgba[coverage])
    return output, int((filled & ~coverage).sum())


def bake_components(scene, target, sources, mergeable, merge_context, args, image, report, report_path):
    import bpy
    from export_runtime import source_material_override

    batches = ComponentBatches(scene, target, sources)
    report['component_projection'] = batches.report
    report['donor_build_seconds'] = 0.0
    report['bake_seconds'] = 0.0
    report['bake_source_count'] = 0
    report['merge'] = {'strategy': 'per_disjoint_batch'}
    mergeable = set(mergeable)
    accumulated = np.zeros((args.size, args.size, 4), dtype=np.float32)
    covered = np.zeros((args.size, args.size), dtype=bool)
    coverage_image = bpy.data.images.new('REVIEW_native_hit_coverage', width=args.size,
        height=args.size, alpha=True, float_buffer=True)
    coverage_image.colorspace_settings.name = 'Non-Color'
    target_material = target.data.materials[0]
    texture = target_material.node_tree.nodes.active
    bake_options = dict(use_selected_to_active=True, use_clear=True, use_cage=False,
        cage_extrusion=.018, max_ray_distance=.040, margin=0,
        normal_space='TANGENT', normal_r='POS_X', normal_g='POS_Y', normal_b='POS_Z',
        target='IMAGE_TEXTURES', save_mode='INTERNAL', uv_layer=batches.uv.name)
    try:
        for number, group in enumerate(batches.groups):
            batches.activate(group)
            originals = [batches.source_by_id[i] for i in group]
            joined = [o for o in originals if o in mergeable]
            separate = [o for o in originals if o not in mergeable]
            started = time.perf_counter()
            context = merge_context(scene, joined) if args.mode == 'merged' and len(joined) > 1 else probe.unchanged_donors(joined)
            with context as (helper, stats), ExitStack() as restorers:
                report['donor_build_seconds'] += time.perf_counter() - started
                donors = separate + ([helper] if helper is not None else joined)
                report['bake_source_count'] = max(report['bake_source_count'], len(donors))
                # Nonselected native parts cannot contribute to EMIT/NORMAL.
                # Hide them only for this batch to avoid rebuilding their BVHs.
                for source in sources:
                    if source not in donors and not source.hide_render:
                        restorers.callback(setattr, source, 'hide_render', False)
                        source.hide_render = True
                for obj in bpy.context.selected_objects:
                    obj.select_set(False)
                for obj in donors:
                    obj.select_set(True)
                target.select_set(True)
                bpy.context.view_layer.objects.active = target
                donor_materials = {s.material for o in donors for s in o.material_slots}
                report['status'] = 'baking'
                probe.write_json(report_path, report)
                started = time.perf_counter()
                print('NATIVE_COMPONENT_BATCH', args.channel, number+1, len(batches.groups), len(originals), flush=True)
                texture.image = coverage_image
                with white_surfaces(donor_materials):
                    bpy.ops.object.bake(type='EMIT', **bake_options)
                hit = read_image(coverage_image, args.size)[:, :, 0] > .5
                texture.image = image
                if args.channel in ('albedo', 'roughness', 'metallic', 'cloth'):
                    for material in donor_materials:
                        restorers.callback(source_material_override(material, args.channel))
                bpy.ops.object.bake(type='NORMAL' if args.channel == 'normal' else 'EMIT',
                    **bake_options)
                elapsed = time.perf_counter()-started
                report['bake_seconds'] += elapsed
                current = read_image(image, args.size)
                overlap = hit & covered
                conflict = float(np.abs(current[overlap, :3]-accumulated[overlap, :3]).max()) if overlap.any() else 0.0
                new = hit & ~covered
                # Raster collisions between subpixel UV islands are recorded;
                # earlier measured texels are never overwritten or repainted.
                accumulated[new] = current[new]
                covered |= hit
                np.savez_compressed(args.output/('batch-%02d-hit.npz' % number), hit=hit)
                batches.report['batches'].append({'index': number, 'source_count': len(originals),
                    'donor_count': len(donors), 'seconds': elapsed, 'merge': stats,
                    'donor_hit_texels': int(hit.sum()), 'earlier_texel_collisions': int(overlap.sum()),
                    'collision_max_linear_rgb_difference': conflict})
    finally:
        batches.restore()
        texture.image = image
        bpy.data.images.remove(coverage_image)
    np.savez_compressed(args.output/'unpadded-rgba.npz', rgba=accumulated, coverage=covered)
    padded, count = pad_uncovered(accumulated, covered)
    batches.report.update(padding_radius=8, padding_pixels=count,
        covered_texels_unchanged=bool(np.array_equal(padded[covered], accumulated[covered])),
        coverage_contract='explicit_emitted_white_donor_hits_v1',
        coverage_limit='Subpixel atlas collisions are recorded separately; no visual acceptance claimed.')
    image.pixels.foreach_set(padded.ravel())
    return padded
