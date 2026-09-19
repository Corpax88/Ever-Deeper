"""Preview-only actual native poses after the independent analytic gate.

This changes study ordering only; full geometry and visual gates are still
required before any full bank, game film or production acceptance.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import runpy
import subprocess
import sys

import bpy
from mathutils import Matrix, Quaternion

ROOT = Path('/workspace/scratch/eb19e34b942d/ever-deeper')
HERE = ROOT/'tools/native_motion_ingame_pilot'
CANDIDATE = Path('/tmp/pivot-return-16H-plan/pivot_return_motion.py')
sys.path[:0] = [str(CANDIDATE.parent), str(HERE), str(ROOT/'tools/hero_v28')]
from clear_return_motion import ClearReturnMotion
from pivot_return_motion import PivotReturnMotion
from coordinated_body_motion import CoordinatedBodyMotion
from transported_forearm_frame_pose import align_right_forearm

parser = argparse.ArgumentParser(description=__doc__)
for name in ('native-tools', 'pivot', 'reference', 'audit', 'output'):
    parser.add_argument('--'+name, type=Path, required=True)
parser.add_argument('--motion', choices=('translation', 'pivot'), default='translation')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
motion_class = PivotReturnMotion if args.motion == 'pivot' else ClearReturnMotion
assert args.motion == 'pivot'
motion_source = CANDIDATE
assert sha(motion_source) == 'b36388c96ac5ded535d88aff4bbb6bf07594cca39fb61e2de09a6cced4983993'
assert not args.output.exists()
assert sha(bpy.data.filepath) == '94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert sha(args.native_tools/'worn/hero.blend') == '0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
assert sha(args.reference) == '01deebd09118b07c8d1917b85ca167700c0f2de04ade7c1313dd9f79d0087a2e'
assert sha(args.pivot) == 'cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
audit = json.loads(args.audit.read_text())
assert audit['passed_analytic'], 'Independent full-arm analytic gate has not passed'
assert not audit['passed_geometry'], 'This helper is expressly for preview before full geometry'
assert audit['candidate_sha256'] == sha(motion_source), 'Audit belongs to a different candidate'
reference = json.loads(args.reference.read_text())
sources = dict(reference['render_provenance'])
for name, value in sources.items():
    assert sha(ROOT/name) == value, name
for path in (Path(__file__), motion_source, CANDIDATE.parent/'transported_forearm_frame_pose.py'):
    sources[str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path)] = sha(path)
inputs = [json.loads((HERE/name).read_text()) for name in
          ('working-surface-selection.json', 'upper-body-hinge-selection.json')]
inputs.append(json.loads(args.pivot.read_text()))
old, motion = CoordinatedBodyMotion(*inputs), motion_class(*inputs)
args.output.mkdir(parents=True)
report = dict(complete=False, passed_geometry=False, passed_analytic=True, preview_only=True, visual_accepted=False,
              production_accepted=False, source_hashes=sources,
              source_sha=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              independent_audit_sha256=sha(args.audit), selection=motion.selection(),
              candidate_sha256=sha(motion_source), motion_kind=args.motion,
              scope='Preview-only five native poses before full rig/alpha validation; no bank authorization, temporal score or production approval', renders=[])


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
    checks = align_right_forearm(rig, env['rest'], pose)
    return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}, checks


try:
    phases = (.720689655172414, .157142857142857, .209523809523810, .231092436974790, .288095238095238)
    for phase in phases:
        pose, prior = motion.sample('mine', phase), old.sample('mine', phase)
        before, _ = apply(prior)
        actual, forearm = apply(pose)
        protected = [name for name in actual if not name.startswith(('upper.', 'lower.', 'hand.'))
                     and name not in ('tool', 'bit', 'body', 'head')]
        error = max(matrix_error(before[name], actual[name]) for name in protected)
        joint = prior['torso'] @ motion.body_joint
        body_turn = (Matrix.Translation(joint)
                     @ Matrix.Rotation(motion.body_yaw(phase), 4, 'Z')
                     @ Matrix.Translation(-joint))
        planned_body_error = max(matrix_error(body_turn @ before[n], actual[n]) for n in ('body', 'head'))
        body_joint_error = (pose['torso'] @ motion.body_joint-joint).length
        assert max(planned_body_error, body_joint_error) < 1e-5
        turn = (Quaternion(motion.pivot_axis, motion.turn_angle(phase))
                if args.motion == 'pivot' else Quaternion())
        orientation = max((pose[k]-turn@prior[k]).length for k in ('axis', 'tool_normal'))
        if args.motion == 'pivot':
            assert (pose['rear']-prior['rear']-motion.return_translation(phase)).length < 1e-6
        grip = max((((actual['hand.'+s] @ rig.data.bones['hand.'+s].matrix_local.inverted())
                     @ env['rest']['grips'][s])-pose['grips'][s]).length for s in ('R', 'L'))
        reach = max((v[2]-v[0]).length for v in pose['arms'].values())
        assert max(error, grip, orientation) < 1e-5 and reach < .70
        env['blink'](0.)
        for modifier in env['skin']:
            modifier.show_viewport = True
        bpy.context.view_layer.update()
        name = f'mine-{round(phase*1000):03d}'
        png = args.output/(name+'.png')
        scene.render.filepath = str(png)
        env['mask'].base_path = str(args.output)
        env['mask'].file_slots[0].path = 'mask-'+name+'-'
        scene.frame_current = 1
        bpy.ops.render.render(write_still=True)
        report['renders'].append(dict(phase=phase, path=png.name, sha256=sha(png),
                                      protected_matrix_error=error, planned_body_matrix_error=planned_body_error,
                                      body_joint_error=body_joint_error, body_yaw_degrees=math.degrees(motion.body_yaw(phase)), grip_error=grip,
                                      orientation_error=orientation, reach=reach, forearm=forearm))
        save()
    for path, value in sources.items():
        assert sha(ROOT/path) == value, path
    report['complete'] = True
    save()
    print('CLEAR_RETURN_POSES_COMPLETE', len(report['renders']), flush=True)
except Exception as error:
    report.update(rejected=True, error=str(error))
    save()
    raise
