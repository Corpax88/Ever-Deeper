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
selected = [scene.objects[name] for name in names]
# The native cloth output is exactly white on these three original donors and
# therefore measures actual hits independently of alpha or albedo brightness.
assert {slot.material.name for o in selected for slot in o.material_slots}.issubset(
    {'v19 woven forest workwear', 'v19 soft olive sleeve lining'})
try:
    plan.activate([int(o[components.SOURCE_INDEX]) for o in selected])
    for channel in ('albedo', 'cloth'):
        probe.bake_probe(SimpleNamespace(output=args.output/channel, scope='sample', mode='separate',
            donor=names, channel=channel, size=report['signature']['size'], samples=8, threads=8,
            donor_strategy='object_coordinates', projection_strategy='assembled', unmerged_donor=[]))
finally:
    plan.restore()
with np.load(args.output/'cloth/rgba.npz') as archive:
    coverage = archive['rgba'][:, :, 0] > .5
with np.load(args.output/'albedo/rgba.npz') as archive:
    actual = archive['rgba']
with np.load(args.candidate/'transfer-albedo/unpadded-rgba.npz') as archive:
    candidate = archive['rgba']
    coverage &= archive['coverage']
# Omit raster-edge/padding texels for the native interior comparison.
interior = coverage.copy()
for dy, dx in ((-1,0),(1,0),(0,-1),(0,1),(-2,0),(2,0),(0,-2),(0,2)):
    shifted = np.roll(coverage, (dy,dx), axis=(0,1))
    interior &= shifted
interior[:2] = interior[-2:] = False
interior[:, :2] = interior[:, -2:] = False
a = probe.encode_opaque_rgb8(actual, 'albedo')
b = probe.encode_opaque_rgb8(candidate, 'albedo')
delta = np.abs(a.astype(np.int16)-b.astype(np.int16))[interior[::-1]]
assert len(delta) > 10000
result = {'prepared_sha256': report['signature']['prepared_sha256'], 'script_sha256': probe.digest(__file__),
    'matched_report_sha256': probe.digest(args.candidate/'transfer-albedo/report.json'),
    'sources': names, 'interior_texels': len(delta), 'maximum_rgb8_difference': int(delta.max()),
    'different_rgb8_texels': int(np.any(delta > 0,axis=1).sum()),
    'texels_over_one_rgb8_step': int(np.any(delta > 1,axis=1).sum()),
    'source_uv_restoration': plan.report, 'passed': bool(delta.max() <= 1),
    'limits': 'Three original donors, matching new UVs, eroded interior only. Not full art acceptance.'}
probe.write_json(args.output/'comparison.json', result)
print('NATIVE_ARM_COMPONENT_COMPARISON', result['interior_texels'], result['maximum_rgb8_difference'], result['passed'], flush=True)
if not result['passed']:
    raise SystemExit(2)
