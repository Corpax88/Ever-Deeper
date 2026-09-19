"""Check one coordinated-body candidate, then optionally render three poses."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(ROOT/'tools/hero_v28')]
from contact_roll_motion import ContactRollMotion
from coordinated_body_motion import CoordinatedBodyMotion, CoordinatedEntryTransition
from forearm_frame_pose import align_right_forearm
from grounded_entry_transition import GroundedEntryTransition

parser = argparse.ArgumentParser(description=__doc__)
for name in ('native-tools', 'pivot', 'reference', 'output'):
    parser.add_argument('--'+name, type=Path, required=True)
parser.add_argument('--render', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
assert not args.output.exists()
args.output.mkdir(parents=True)
sha = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
assert sha(bpy.data.filepath) == '94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert sha(args.native_tools/'worn/hero.blend') == '0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
assert sha(args.reference) == '7ccc38204999c8eee8278dcb67dd9010422b5c8ca27a40998dc06bbc059fd495'
assert sha(args.pivot) == 'cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
reference = json.loads(args.reference.read_text())
sources = dict(reference['render_provenance'])
for path, value in sources.items():
    assert sha(ROOT/path) == value, path
for path in (Path(__file__), HERE/'coordinated_body_motion.py'):
    sources[str(path.relative_to(ROOT))] = sha(path)
inputs = [json.loads((HERE/name).read_text()) for name in
          ('working-surface-selection.json', 'upper-body-hinge-selection.json')]
inputs.append(json.loads(args.pivot.read_text()))
old, motion = ContactRollMotion(*inputs), CoordinatedBodyMotion(*inputs)
old_entry, entry = GroundedEntryTransition(old, .625), CoordinatedEntryTransition(motion, .625)
report = dict(complete=False, passed_geometry=False, visual_accepted=False,
              production_accepted=False, source_hashes=sources,
              source_sha=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              reference_manifest_sha256=sha(args.reference), metadata=entry.metadata(),
              scope='One body timing study; three native poses are not a temporal score',
              samples=[], renders=[])


def save():
    (args.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')


def matrix_error(a, b):
    return max(abs(a[i][j]-b[i][j]) for i in range(4) for j in range(4))


try:
    for kind in ('entry', 'cycle'):
        for i in range(501):
            phase = i/500
            before = old_entry.sample(phase*entry.duration) if kind == 'entry' else old.sample('mine', phase)
            pose = entry.sample(phase*entry.duration) if kind == 'entry' else motion.sample('mine', phase)
            reach = max((v[2]-v[0]).length for v in pose['arms'].values())
            feet = max((pose['legs'][s][j]-before['legs'][s][j]).length for s in ('R', 'L') for j in range(3))
            tool = max((pose[key]-before[key]).length for key in ('rear', 'axis', 'tool_normal'))
            pivot = (pose['torso']@motion.body_joint-before['torso']@motion.body_joint).length
            assert reach < .70 and max(feet, tool, pivot) < 1e-5, (kind, phase, reach, feet, tool, pivot)
            report['samples'].append(dict(kind=kind, phase=phase, reach=reach,
                                          feet_error=feet, tool_error=tool, pivot_error=pivot))
    for phase in (.20, .40, .55):
        assert matrix_error(old.sample('mine', phase)['torso'], motion.sample('mine', phase)['torso']) < 1e-5
    report['passed_geometry'] = True
    save()
    if args.render:
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
            checks = align_right_forearm(rig, env['rest'], pose)
            return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}, checks

        for kind, value in (('entry', 6/60), ('entry', 11/60), ('mine', .45)):
            pose = entry.sample(value) if kind == 'entry' else motion.sample('mine', value)
            prior = old_entry.sample(value) if kind == 'entry' else old.sample('mine', value)
            before, _ = apply(prior)
            actual, forearm = apply(pose)
            protected = ('root', 'hips', 'thigh.R', 'shin.R', 'foot.R', 'thigh.L', 'shin.L', 'foot.L', 'tool')
            protected_error = max(matrix_error(before[name], actual[name]) for name in protected)
            grip_error = max((((actual['hand.'+side] @ rig.data.bones['hand.'+side].matrix_local.inverted())
                              @ env['rest']['grips'][side])-pose['grips'][side]).length for side in ('R', 'L'))
            assert max(protected_error, grip_error) < 1e-5
            env['blink'](0.)
            for modifier in env['skin']:
                modifier.show_viewport = True
            bpy.context.view_layer.update()
            name = f'{kind}-{round(value*1000):03d}'
            png = args.output/(name+'.png')
            scene.render.filepath = str(png)
            env['mask'].base_path = str(args.output)
            env['mask'].file_slots[0].path = 'mask-'+name+'-'
            scene.frame_current = 1
            bpy.ops.render.render(write_still=True)
            report['renders'].append(dict(kind=kind, value=value, path=png.name, sha256=sha(png),
                                          protected_matrix_error=protected_error, grip_error=grip_error,
                                          forearm=forearm))
            save()
    for path, value in sources.items():
        assert sha(ROOT/path) == value, path
    report['complete'] = True
    save()
    print('COORDINATED_BODY_COMPLETE', len(report['samples']), len(report['renders']), flush=True)
except Exception as error:
    report.update(rejected=True, error=str(error))
    save()
    raise
