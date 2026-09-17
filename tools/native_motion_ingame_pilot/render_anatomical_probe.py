"""Five genuine native poses after geometric selection; never a gameplay run."""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import subprocess
import sys
import bpy

parser = argparse.ArgumentParser()
parser.add_argument('--native-tools', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--source-sha', required=True)
parser.add_argument('--validate-only', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
selection_path = HERE/'anatomical-probe-selection.json'
selection = json.loads(selection_path.read_text())
assert selection['visually_accepted'] is False
assert selection['phases'] == [.125, .375, .55, .625, .8125]
assert subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip() == args.source_sha
if not args.validate_only:
    assert not subprocess.check_output(['git','status','--porcelain'], cwd=ROOT, text=True).strip(), 'Graphical probe requires the saved clean checkpoint'
args.output.mkdir(parents=True, exist_ok=True)
sys.argv = ['blender', '--', '--output', str(args.output/'target-controls.json')]
envelope = runpy.run_path(str(HERE/'probe_contact_envelope.py'))
anatomy = envelope['anatomy']
spec = selection['specification']
matches = [c for c in envelope['report']['cases'] if all(c[k] == v for k, v in spec.items())]
assert len(matches) == 1 and matches[0]['passed'] and matches[0]['samples'] == 135
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools), '--output', str(args.output/'scene-load'), '--setup-only']
loaded = runpy.run_path(str(HERE/'probe_up_occlusion.py'))
env, ground = loaded['env'], anatomy['GROUND']
rig, rest = env['r'], env['rest']
assert loaded['report']['model_sha256'] == selection['model_sha256']
assert loaded['report']['gear_sha256'] == selection['gear_sha256']
files = [Path(__file__), selection_path, HERE/'probe_up_anatomy.py', HERE/'probe_contact_envelope.py', HERE/'probe_up_occlusion.py', ROOT/'tools/hero_v28/native_motion.py', ROOT/'tools/hero_v28/export_hero.py']
source_hashes = {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
fingerprint = hashlib.sha256(json.dumps({'source_hashes':source_hashes, 'selection':selection}, sort_keys=True).encode()).hexdigest()
report = {'complete':False, 'rendered':not args.validate_only, 'source_sha':args.source_sha,
          'source_hashes':source_hashes, 'fingerprint':fingerprint, 'selection':selection,
          'blender':bpy.app.version_string, 'dense_native_poses_evaluated':0, 'max_grip_error':0.,
          'bone_matrix_gate':1e-5, 'shaft_axis_and_complete_feet_unchanged':True,
          'native_gameplay_or_transition_coverage':False, 'frames':[]}


def pose(phase):
    original = env['native_motion'].sample('worn', 'mine', phase, ground, 340.)
    w = envelope['contact_weight'](phase)
    lateral = spec['windup_lateral']+(spec['contact_lateral']-spec['windup_lateral'])*w
    retreat = spec['windup_retreat']+(spec['contact_retreat']-spec['windup_retreat'])*w
    p = anatomy['anatomical_pose'](original, spec['yaw_degrees'], lateral, retreat, spec['tool_roll_degrees'])
    for field in ('legs', 'foot_rotations', 'contacts'):
        assert p[field] is original[field]
    assert p['axis'] is original['axis']
    assert env['native_motion'].frame_metadata(p, ground)['feet'] == env['native_motion'].frame_metadata(original, ground)['feet']
    p['head'] = p['head']@env['head_offset']
    env['apply'](p)
    grip = max(((rig.pose.bones['hand.'+s].matrix@rig.data.bones['hand.'+s].matrix_local.inverted())@rest['grips'][s]-p['grips'][s]).length for s in ('R', 'L'))
    assert grip < 1e-5
    report['max_grip_error'] = max(report['max_grip_error'], grip)
    return p


for modifier in env['skin']:
    modifier.show_viewport = False
for phase, _ in anatomy['originals']:
    pose(phase)
    report['dense_native_poses_evaluated'] += 1
assert report['dense_native_poses_evaluated'] == 135
for index, phase in enumerate(selection['phases']):
    for modifier in env['skin']:
        modifier.show_viewport = False
    p = pose(phase)
    env['blink'](0.)
    for modifier in env['skin']:
        modifier.show_viewport = True
    bpy.context.view_layer.update()
    key = f'up-anatomical-{index:02}-q{round(phase*1000000):06}'
    frame = {'index':index, 'phase':phase, 'path':key+'.png', 'mask':'mask-'+key+'-0001.png',
             'native':env['native_motion'].frame_metadata(p, ground), 'rear':list(p['rear']),
             'axis':list(p['axis']), 'tool_normal':list(p['tool_normal'])}
    if not args.validate_only:
        env['s'].render.filepath = str(args.output/frame['path'])
        env['mask'].base_path = str(args.output)
        env['mask'].file_slots[0].path = 'mask-'+key+'-'
        env['s'].frame_current = 1
        bpy.ops.render.render(write_still=True)
        frame['png_sha256'] = hashlib.sha256((args.output/frame['path']).read_bytes()).hexdigest()
        frame['mask_sha256'] = hashlib.sha256((args.output/frame['mask']).read_bytes()).hexdigest()
    report['frames'].append(frame)
    (args.output/'anatomical-probe.json').write_text(json.dumps(report, indent=2)+'\n')
    print('ANATOMICAL_PROBE_POSE' if args.validate_only else 'ANATOMICAL_PROBE_FRAME', phase, flush=True)
report['complete'] = True
(args.output/'anatomical-probe.json').write_text(json.dumps(report, indent=2)+'\n')
print('ANATOMICAL_PROBE_COMPLETE', len(report['frames']), report['max_grip_error'], flush=True)
