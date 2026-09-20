"""Finish matched native maps using the measured albedo donor-hit masks.

Roughness, metallic and cloth are independent linear channels packed in one
emission pass. Normal projection shares the unchanged native geometry/rays.
AO keeps the assembled native scene and existing audited donor implementation.
"""
from contextlib import contextmanager, ExitStack
import argparse
import json
from pathlib import Path
import sys
import time
from types import SimpleNamespace

import bpy
import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import component_batches as components
import constant_donor_probe as probe
import export_runtime as exporter
import object_coordinate_donors as donors


@contextmanager
def packed_surfaces(materials, response=False):
    with ExitStack() as restorers:
        for material in materials:
            nodes, links = material.node_tree.nodes, material.node_tree.links
            output = next(n for n in nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output)
            principled = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
            old = [(link.from_socket, link.to_socket) for link in output.inputs['Surface'].links]
            combine = nodes.new('ShaderNodeCombineXYZ')
            emission = nodes.new('ShaderNodeEmission')
            names = ('Specular IOR Level', 'Coat Weight', 'Coat Roughness') if response else ('Roughness', 'Metallic')
            for index, name in enumerate(names):
                source = principled.inputs[name]
                if response and index == 0:
                    # Blender's IOR-level scales Fresnel F0 by twice its value.
                    # Godot SPECULAR scales dielectric F0 by0.08.
                    ior = principled.inputs['IOR']
                    assert not source.is_linked and not ior.is_linked, material.name
                    eta = float(ior.default_value)
                    combine.inputs[index].default_value = 2.0*float(source.default_value)*((eta-1.0)/(eta+1.0))**2/.08
                    continue
                if source.is_linked:
                    links.new(source.links[0].from_socket, combine.inputs[index])
                else:
                    combine.inputs[index].default_value = float(source.default_value)
            source_name = material.get('native_donor_source_material', material.name)
            if not response:
                combine.inputs[2].default_value = float(source_name in ('v19 woven forest workwear', 'v19 soft olive sleeve lining'))
            links.new(combine.outputs[0], emission.inputs['Color'])
            links.new(emission.outputs[0], output.inputs['Surface'])
            def restore(nodes=nodes, links=links, a=combine, b=emission, old=old):
                nodes.remove(a)
                nodes.remove(b)
                for first, second in old:
                    links.new(first, second)
            restorers.callback(restore)
        yield


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--threads', type=int, default=8)
    p.add_argument('--response', action='store_true', help='Only native specular F0, coat weight and coat roughness; preserve all existing maps/GLB')
    args = p.parse_args(sys.argv[sys.argv.index('--')+1:])
    output = args.output.resolve()
    assert Path(bpy.data.filepath).resolve() == output/'prepared.blend'
    albedo_path = output/'transfer-albedo/report.json'
    albedo = json.loads(albedo_path.read_text())
    signature = albedo['signature']
    assert albedo['status'] == 'complete' and signature['projection_strategy'] == 'matched_components'
    assert signature['donor_strategy'] == 'object_coordinates'
    assert albedo['mode'] == 'merged'
    assert signature['prepared_sha256'] == probe.digest(output/'prepared.blend')
    assert signature['projection_script_sha256'] == probe.digest(components.__file__)
    assert signature['strategy_sha256'] == probe.digest(donors.__file__)
    assert signature['script_sha256'] == probe.digest(probe.__file__)
    assert albedo['component_projection']['coverage_contract'] == 'explicit_emitted_white_donor_hits_v1'
    assert all(albedo['component_projection'][k] for k in ('restored_original_transforms',
        'restored_original_uv', 'geometry_normals_topology_unchanged', 'covered_texels_unchanged'))
    assert probe.digest(output/'albedo.png') == albedo['rgb_output']['png_sha256']
    evidence = output/('component-response' if args.response else 'component-companions')
    evidence.mkdir(exist_ok=False)
    report = {'status': 'preparing', 'approved': False, 'albedo_report_sha256': probe.digest(albedo_path),
        'source_sha256': probe.digest(__file__), 'binding': signature, 'batches': [], 'response': args.response,
        'limits': 'Offline native map transfer; no game, motion or performance acceptance.'}
    report_path = evidence/'report.json'
    probe.write_json(report_path, report)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = signature['samples']
    scene.cycles.use_adaptive_sampling = False
    scene.cycles.use_denoising = False
    scene.cycles.seed = 0
    scene.cycles.use_animated_seed = False
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = args.threads
    scene.render.use_persistent_data = False
    sources = sorted((o for o in scene.objects if o.type == 'MESH' and o.get(probe.SOURCE_TAG)), key=lambda o:o.name)
    probe.opaque_sources_audit(sources)
    eligible, _, _ = probe.classify_sources(sources, donors.material_audit)
    eligible = {o for o in eligible if o.name not in signature['explicitly_unmerged_sources']}
    assert sorted(o.name for o in eligible) == signature['group']
    target = scene.objects[probe.TARGET_NAME]
    original = target.data
    target.data = original.copy()
    working = target.data
    material = bpy.data.materials.new('REVIEW_companion_receiver')
    material.use_nodes = True
    working.materials.clear()
    working.materials.append(material)
    for polygon in working.polygons:
        polygon.material_index = 0
    size = signature['size']
    image = bpy.data.images.new('REVIEW_companion_map', width=size, height=size, alpha=True, float_buffer=True)
    image.colorspace_settings.name = 'Non-Color'
    texture = material.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image = image
    material.node_tree.nodes.active = texture
    plan = components.ComponentBatches(scene, target, sources)
    assert plan.report['groups'] == albedo['component_projection']['groups']
    assert plan.geometry_sha == albedo['component_projection']['geometry_normals_topology_sha256_before']
    report['component_projection'] = plan.report
    accumulated = {name: np.zeros((size, size, 4), dtype=np.float32) for name in (('packed',) if args.response else ('packed', 'normal'))}
    covered = np.zeros((size, size), dtype=bool)
    original_selection = [(o, o.select_get()) for o in scene.objects]
    original_active = bpy.context.view_layer.objects.active
    options = dict(use_selected_to_active=True, use_clear=True, use_cage=False,
        cage_extrusion=signature['cage_extrusion'], max_ray_distance=signature['max_ray_distance'], margin=0,
        normal_space='TANGENT', normal_r='POS_X', normal_g='POS_Y', normal_b='POS_Z',
        target='IMAGE_TEXTURES', save_mode='INTERNAL', uv_layer=plan.uv.name)
    try:
        for index, group in enumerate(plan.groups):
            plan.activate(group)
            mask_path = output/('transfer-albedo/batch-%02d-hit.npz' % index)
            with np.load(mask_path) as masks:
                mask = masks['hit']
            assert mask.dtype == bool and mask.shape == (size, size)
            assert int(mask.sum()) == albedo['component_projection']['batches'][index]['donor_hit_texels']
            assert int((mask & covered).sum()) == albedo['component_projection']['batches'][index]['earlier_texel_collisions']
            active = [plan.source_by_id[i] for i in group]
            joined = [o for o in active if o in eligible]
            separate = [o for o in active if o not in eligible]
            context = donors.merged_donors(scene, joined) if len(joined) > 1 else probe.unchanged_donors(joined)
            started = time.perf_counter()
            with context as (helper, stats), ExitStack() as restorers:
                actual = separate + ([helper] if helper is not None else joined)
                for source in sources:
                    if source not in actual and not source.hide_render:
                        restorers.callback(setattr, source, 'hide_render', False)
                        source.hide_render = True
                for obj in bpy.context.selected_objects:
                    obj.select_set(False)
                for obj in actual:
                    obj.select_set(True)
                target.select_set(True)
                bpy.context.view_layer.objects.active = target
                materials = {s.material for o in actual for s in o.material_slots}
                print('NATIVE_COMPANION_BATCH', index+1, len(plan.groups), flush=True)
                new = mask & ~covered
                with packed_surfaces(materials, response=args.response):
                    bpy.ops.object.bake(type='EMIT', **options)
                accumulated['packed'][new] = components.read_image(image, size)[new]
                if not args.response:
                    bpy.ops.object.bake(type='NORMAL', **options)
                    accumulated['normal'][new] = components.read_image(image, size)[new]
                covered |= mask
                report['batches'].append({'index': index, 'hit_mask_sha256': probe.digest(mask_path),
                    'seconds': time.perf_counter()-started, 'merge': stats})
                probe.write_json(report_path, report)
        with np.load(output/'transfer-albedo/unpadded-rgba.npz') as first:
            assert np.array_equal(first['coverage'], covered)
        for name, rgba in accumulated.items():
            np.savez_compressed(evidence/(name+'-unpadded.npz'), rgba=rgba, coverage=covered)
            accumulated[name], _ = components.pad_uncovered(rgba, covered)
        if args.response:
            # Reuse the audited linear-data codec; no color-space conversion.
            report['outputs'] = {'response': probe.write_opaque_rgb_png(evidence/'response.png', accumulated['packed'], 'roughness')}
            report['response_channels'] = ['native dielectric F0 /0.08', 'Coat Weight', 'Coat Roughness']
        else:
            report['outputs'] = {'normal': probe.write_opaque_rgb_png(output/'normal.png', accumulated['normal'], 'normal')}
            for index, name in enumerate(('roughness', 'metallic', 'cloth')):
                value = accumulated['packed'][:, :, index]
                rgba = np.ones((size, size, 4), dtype=np.float32)
                rgba[:, :, :3] = value[:, :, None]
                report['outputs'][name] = probe.write_opaque_rgb_png(output/(name+'.png'), rgba, name)
        report['status'] = 'complete'
    except Exception as error:
        report.update(status='failed', error=str(error))
        raise
    finally:
        try:
            plan.restore()
        finally:
            target.data = original
            bpy.data.meshes.remove(working)
            bpy.data.materials.remove(material)
            bpy.data.images.remove(image)
            for obj, selected in original_selection:
                obj.select_set(selected)
            bpy.context.view_layer.objects.active = original_active
            report['original_target_data_restored'] = target.data == original
            probe.write_json(report_path, report)
    if args.response:
        assert probe.digest(output/'albedo.png') == albedo['rgb_output']['png_sha256']
        print('NATIVE_COMPONENT_RESPONSE_COMPLETE', flush=True)
        return
    # Full assembled AO preserves actual native inter-component occlusion.
    probe.bake_probe(SimpleNamespace(output=output/'transfer-ao', scope='full', mode='merged',
        donor=None, channel='ao', size=size, samples=signature['samples'], threads=args.threads,
        donor_strategy='object_coordinates', projection_strategy='assembled',
        unmerged_donor=signature['explicitly_unmerged_sources']))
    import shutil
    shutil.copyfile(output/'transfer-ao/ao.png', output/'ao.png')
    exporter.bake(SimpleNamespace(output=output, threads=args.threads))
    print('NATIVE_COMPONENT_COMPANIONS_COMPLETE', flush=True)


if __name__ == '__main__':
    main()
