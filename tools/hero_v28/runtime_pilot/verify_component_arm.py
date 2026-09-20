"""Compare matched albedo against three unchanged native arm donors, same UVs."""
import argparse
import json
from pathlib import Path
import sys
from types import SimpleNamespace

import bpy
import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import component_batches as components
import constant_donor_probe as probe

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--candidate', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
args = p.parse_args(sys.argv[sys.argv.index('--')+1:])
assert Path(bpy.data.filepath).resolve() == args.candidate.resolve()/'prepared.blend'
report = json.loads((args.candidate/'transfer-albedo/report.json').read_text())
assert report['status'] == 'complete'
assert report['signature']['prepared_sha256'] == probe.digest(args.candidate/'prepared.blend')
scene = bpy.context.scene
sources = sorted((o for o in scene.objects if o.type == 'MESH' and o.get(probe.SOURCE_TAG)), key=lambda o:o.name)
target = scene.objects[probe.TARGET_NAME]
plan = components.ComponentBatches(scene, target, sources)
names = ['v11 fitted forearm R', 'v14 broad folded cuff R', 'v15 softly rounded sleeve R']
size = report['signature']['size']
args.output.mkdir(exist_ok=False)
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 8
scene.cycles.use_adaptive_sampling = False
scene.cycles.use_denoising = False
scene.cycles.seed = 0
scene.render.threads_mode = 'FIXED'
scene.render.threads = 8
with np.load(args.candidate/'transfer-albedo/unpadded-rgba.npz') as archive:
    candidate = archive['rgba']
    candidate_coverage = archive['coverage']
original = target.data
working = original.copy()
target.data = working
material = bpy.data.materials.new('REVIEW_arm_receiver')
material.use_nodes = True
working.materials.clear()
working.materials.append(material)
for polygon in working.polygons:
    polygon.material_index = 0
texture = material.node_tree.nodes.new('ShaderNodeTexImage')
material.node_tree.nodes.active = texture
image = bpy.data.images.new('REVIEW_original_arm', width=size, height=size, alpha=True, float_buffer=True)
image.colorspace_settings.name = 'Non-Color'
texture.image = image
# Ownership/UV masking applies to the disposable receiver, never native sources.
plan = components.ComponentBatches(scene, target, sources)
rows = []
from contextlib import ExitStack
from export_runtime import source_material_override
try:
    for name in names:
        source = scene.objects[name]
        plan.activate([int(source[components.SOURCE_INDEX])])
        with ExitStack() as restorers:
            for other in sources:
                if other != source:
                    restorers.callback(setattr, other, 'hide_render', other.hide_render)
                    other.hide_render = True
            for obj in bpy.context.selected_objects:
                obj.select_set(False)
            source.select_set(True)
            target.select_set(True)
            bpy.context.view_layer.objects.active = target
            options = dict(type='EMIT', use_selected_to_active=True, use_clear=True, use_cage=False,
                cage_extrusion=.018, max_ray_distance=.040, margin=0,
                target='IMAGE_TEXTURES', save_mode='INTERNAL', uv_layer=plan.uv.name)
            materials = {slot.material for slot in source.material_slots}
            with components.white_surfaces(materials):
                bpy.ops.object.bake(**options)
            coverage = components.read_image(image, size)[:, :, 0] > .5
            image.colorspace_settings.name = 'sRGB'
            with ExitStack() as shaders:
                for mat in materials:
                    shaders.callback(source_material_override(mat, 'albedo'))
                bpy.ops.object.bake(**options)
            actual = components.read_image(image, size)
            image.colorspace_settings.name = 'Non-Color'
        np.savez_compressed(args.output/(name.replace(' ', '-')+'.npz'), rgba=actual, coverage=coverage)
        coverage &= candidate_coverage
        interior = coverage.copy()
        for dy, dx in ((-1,0),(1,0),(0,-1),(0,1),(-2,0),(2,0),(0,-2),(0,2)):
            interior &= np.roll(coverage, (dy,dx), axis=(0,1))
        interior[:2] = interior[-2:] = False
        interior[:, :2] = interior[:, -2:] = False
        a = probe.encode_opaque_rgb8(actual, 'albedo')
        b = probe.encode_opaque_rgb8(candidate, 'albedo')
        delta = np.abs(a.astype(np.int16)-b.astype(np.int16))[interior[::-1]]
        assert len(delta) > 1000
        rows.append({'source': name, 'interior_texels': len(delta),
            'maximum_rgb8_difference': int(delta.max()),
            'different_rgb8_texels': int(np.any(delta > 0,axis=1).sum()),
            'texels_over_one_rgb8_step': int(np.any(delta > 1,axis=1).sum()),
            'passed': bool(delta.max() <= 1)})
finally:
    plan.restore()
    target.data = original
    bpy.data.meshes.remove(working)
    bpy.data.materials.remove(material)
    bpy.data.images.remove(image)
result = {'prepared_sha256': report['signature']['prepared_sha256'], 'script_sha256': probe.digest(__file__),
    'matched_report_sha256': probe.digest(args.candidate/'transfer-albedo/report.json'),
    'sources': rows, 'source_uv_restoration': plan.report, 'passed': all(r['passed'] for r in rows),
    'limits': 'Three separate original donors, matching new UVs, eroded interior only. Not full art acceptance.'}
probe.write_json(args.output/'comparison.json', result)
print('NATIVE_ARM_COMPONENT_COMPARISON', json.dumps(rows), result['passed'], flush=True)
if not result['passed']:
    raise SystemExit(2)
