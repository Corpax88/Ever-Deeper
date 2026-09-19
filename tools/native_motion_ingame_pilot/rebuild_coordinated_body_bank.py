"""Patch the 24 changed cells into verified bank14; retain all other images."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(ROOT/'tools/hero_v28')]
from contact_roll_motion import ContactRollMotion
from coordinated_body_motion import CoordinatedBodyMotion, CoordinatedEntryTransition
from forearm_frame_pose import align_right_forearm
from grounded_entry_transition import GroundedEntryTransition
import native_motion as native

ENTRY = 'walk_to_mine-625000'
parser = argparse.ArgumentParser(description=__doc__)
for name in ('native-tools', 'pivot', 'reference', 'parent-report', 'recorded', 'proof', 'output'):
    parser.add_argument('--'+name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
assert not args.output.exists()
args.output.mkdir(parents=True)
out = args.output/'worn'
out.mkdir()
sha = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
assert sha(args.reference) == '7ccc38204999c8eee8278dcb67dd9010422b5c8ca27a40998dc06bbc059fd495'
assert sha(args.parent_report) == '830abf93b084e2aa5224bb84007754aeecb8e6677bb54b0c4a18d5606c525702'
assert sha(args.recorded) == 'aaa33522fb3a52169377e7920fd81e5489226f25213bbb3f0321625325c89336'
assert sha(args.pivot) == 'cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
assert sha(bpy.data.filepath) == '94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert sha(args.native_tools/'worn/hero.blend') == '0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
reference = json.loads(args.reference.read_text())
parent = json.loads(args.parent_report.read_text())
recorded = json.loads(args.recorded.read_text())
proof = json.loads(args.proof.read_text())
assert parent['complete'] and parent['passed_geometry']
assert recorded['passed'] and len(recorded['samples']) == 119
assert proof['complete'] and proof['passed_geometry'] and len(proof['renders']) == 3
for frame in proof['renders']:
    assert sha(args.proof.parent/frame['path']) == frame['sha256']
sources = dict(reference['render_provenance'])
sources.update(proof['source_hashes'])
for path, value in sources.items():
    assert sha(ROOT/path) == value, path
sources[str(Path(__file__).relative_to(ROOT))] = sha(__file__)
allowed = set(reference['loop_flow_study']['rendered_cells'])
actual_cells = {f"{sample['visual']['state']}:{sample['visual']['local_frame']}" for sample in recorded['samples']}
assert allowed == actual_cells and len(allowed) == 91
manifest = copy.deepcopy(reference)
inputs = [json.loads((HERE/name).read_text()) for name in
          ('working-surface-selection.json', 'upper-body-hinge-selection.json')]
inputs.append(json.loads(args.pivot.read_text()))
old, motion = ContactRollMotion(*inputs), CoordinatedBodyMotion(*inputs)
old_entry, entry = GroundedEntryTransition(old, .625), CoordinatedEntryTransition(motion, .625)
metadata = entry.metadata()
metadata['destination_offset_pixels'] = reference['directions']['up']['transitions'][ENTRY]['destination_offset_pixels']
manifest['directions']['up']['transitions'][ENTRY] = metadata
selected = {f"{f['state']}:{f['index']}" for f in manifest['frames']
            if f"{f['state']}:{f['index']}" in allowed and
            (f['state'] == ENTRY or (f['state'] == 'mine' and .20 < f['phase'] < .55))}
assert len(selected) == 24
report = dict(complete=False, passed_geometry=False, visual_accepted=False,
              production_accepted=False, source_hashes=sources,
              source_sha=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              reference_manifest_sha256=sha(args.reference), parent_report_sha256=sha(args.parent_report),
              reference_report_sha256=sha(args.recorded), proof_sha256=sha(args.proof),
              authorized_cells=sorted(allowed), changed_cells=sorted(selected),
              scope='24 changed cells; 67 authorized and 138 forbidden cells retain bank14 image hashes',
              frame_checks=[], rendered_cells=[], inherited_cells=[], planned_draws=[])


def save():
    (args.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')


def matrix_error(a, b):
    return max(abs(a[i][j]-b[i][j]) for i in range(4) for j in range(4))


sys.argv = ['blender', '--', '--native-tools', str(args.native_tools), '--output', str(args.output/'setup'),
            '--gear', 'worn', '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'))
env['view']('up', (6, 6))
scene, rig = env['s'], env['r']


def apply(pose):
    for modifier in env['skin']:
        modifier.show_viewport = False
    supplied = dict(pose)
    supplied['head'] = supplied['head'] @ env['head_offset']
    env['apply'](supplied)
    align_right_forearm(rig, env['rest'], pose)
    return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}


def project(point):
    p = world_to_camera_view(scene, env['c'], Vector(point))
    return Vector((p.x*160, (1-p.y)*160))


poses = {}
try:
    for frame in manifest['frames']:
        state, index, phase = frame['state'], frame['index'], frame['phase']
        cell = f'{state}:{index}'
        if cell not in selected:
            continue
        prior = old_entry.sample(phase*old_entry.duration) if state == ENTRY else old.sample(state, phase)
        pose = entry.sample(phase*entry.duration) if state == ENTRY else motion.sample(state, phase)
        before, actual = apply(prior), apply(pose)
        protected = ('root', 'hips', 'thigh.R', 'shin.R', 'foot.R', 'thigh.L', 'shin.L', 'foot.L', 'tool')
        error = max(matrix_error(before[name], actual[name]) for name in protected)
        grip = max((((actual['hand.'+side] @ rig.data.bones['hand.'+side].matrix_local.inverted())
                     @ env['rest']['grips'][side])-pose['grips'][side]).length for side in ('R', 'L'))
        reach = max((chain[2]-chain[0]).length for chain in pose['arms'].values())
        assert max(error, grip) < 1e-5 and reach < .70, (cell, error, grip, reach)
        frame['native'] = native.frame_metadata(pose, motion.ground)
        frame['contacts'] = pose['contacts']
        report['frame_checks'].append(dict(cell=cell, protected_matrix_error=error, grip_error=grip, reach=reach))
        poses[cell] = pose
    original = {(f['state'], f['index']): f for f in reference['frames']}
    updated = {(f['state'], f['index']): f for f in manifest['frames']}
    for number, sample in enumerate(recorded['samples']):
        visual = sample['visual']
        key = visual['state'], visual['local_frame']
        before, after = original[key], updated[key]
        error = max((project(before['native']['feet'][s][point])-project(after['native']['feet'][s][point])).length
                    for s in ('R', 'L') for point in ('ankle', 'sole_point'))
        assert error < .0002
        report['planned_draws'].append(dict(sample=number, state=key[0], index=key[1],
                                           projected_lower_point_error=error))
    report['passed_geometry'] = True
    save()
    for frame in manifest['frames']:
        cell = f"{frame['state']}:{frame['index']}"
        if cell in selected:
            apply(poses[cell])
            env['blink'](0.)
            for modifier in env['skin']:
                modifier.show_viewport = True
            bpy.context.view_layer.update()
            name = f"coordinated-{frame['state']}-{frame['index']:03d}"
            png, mask = out/(name+'.png'), out/('mask-'+name+'-0001.png')
            scene.render.filepath = str(png)
            env['mask'].base_path = str(out)
            env['mask'].file_slots[0].path = 'mask-'+name+'-'
            scene.frame_current = 1
            bpy.ops.render.render(write_still=True)
            frame.update(path=png.name, mask=mask.name, png_sha256=sha(png), mask_sha256=sha(mask))
            report['rendered_cells'].append(cell)
        else:
            for key, hash_key in (('path', 'png_sha256'), ('mask', 'mask_sha256')):
                source = args.reference.parent/frame[key]
                assert sha(source) == frame[hash_key]
                shutil.copyfile(source, out/source.name)
            report['inherited_cells'].append(dict(cell=cell, authorized=cell in allowed,
                                                   png_sha256=frame['png_sha256'], mask_sha256=frame['mask_sha256']))
        save()
    for path, value in sources.items():
        assert sha(ROOT/path) == value, path
    assert set(report['rendered_cells']) == selected
    report['complete'] = True
    save()
    manifest['historical_render_fingerprint'] = manifest['render_fingerprint']
    manifest['render_fingerprint'] = sha(args.output/'report.json')
    manifest['render_provenance'] = sources
    manifest['loop_flow_study'].update(report_sha256=sha(args.output/'report.json'),
                                       coordinated_body_study=True, selection=motion.selection(),
                                       changed_cells=sorted(selected),
                                       visual_accepted=False, production_accepted=False)
    (out/'pilot-manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('COORDINATED_BANK_COMPLETE', len(selected), len(manifest['frames']), flush=True)
except Exception as error:
    report.update(rejected=True, error=str(error))
    save()
    raise
