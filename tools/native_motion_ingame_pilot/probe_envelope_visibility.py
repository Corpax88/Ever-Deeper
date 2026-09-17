"""Evaluate reachable native contact envelopes. No images are rendered."""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import sys
import time
import bpy

parser = argparse.ArgumentParser()
parser.add_argument('--native-tools', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
args.output.mkdir(parents=True, exist_ok=True)
sys.argv = ['blender', '--', '--output', str(args.output/'target-controls.json')]
envelope = runpy.run_path(str(HERE/'probe_contact_envelope.py'))
anatomy = envelope['anatomy']
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools), '--output', str(args.output/'scene'), '--setup-only']
occlusion = runpy.run_path(str(HERE/'probe_up_occlusion.py'))
env, ground = occlusion['env'], anatomy['GROUND']
rig, rest = env['r'], env['rest']
report = {'complete':False, 'rendered':False, 'evaluated_native_rig_and_mesh':True,
          'source_base':'354bc9bd04953f4e20e23c2eef87d1affe686ab2',
          'source_hashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [Path(__file__), HERE/'probe_up_anatomy.py', HERE/'probe_up_occlusion.py', HERE/'probe_contact_envelope.py']},
          'purpose':'Reachable native stroke geometric visibility; actual image, material and ore-contact acceptance remains pending.',
          'model_sha256':occlusion['report']['model_sha256'], 'gear_sha256':occlusion['report']['gear_sha256'],
          'camera':occlusion['report']['camera'], 'cases':[]}
started = time.monotonic()


def inspect(spec, phase):
    original = env['native_motion'].sample('worn', 'mine', phase, ground, 340.)
    w = envelope['contact_weight'](phase)
    lateral = spec['windup_lateral']+(spec['contact_lateral']-spec['windup_lateral'])*w
    retreat = spec['windup_retreat']+(spec['contact_retreat']-spec['windup_retreat'])*w
    p = anatomy['anatomical_pose'](original, spec['yaw_degrees'], lateral, retreat, spec['tool_roll_degrees'])
    p['head'] = p['head']@env['head_offset']
    for modifier in env['skin']:
        modifier.show_viewport = False
    env['apply'](p)
    env['blink'](0.)
    for modifier in env['skin']:
        modifier.show_viewport = True
    bpy.context.view_layer.update()
    grip = max(((rig.pose.bones['hand.'+s].matrix@rig.data.bones['hand.'+s].matrix_local.inverted())@rest['grips'][s]-p['grips'][s]).length for s in ('R', 'L'))
    assert grip < 1e-5
    values, objects = occlusion['measure']()
    row = {'specification':spec, 'phase':phase, 'evaluated_hand_grip_error':grip,
           'actual_lateral':lateral, 'actual_retreat':retreat, 'rear':list(p['rear']),
           'axis':list(p['axis']), 'tool_normal':list(p['tool_normal']),
           'native_feet':env['native_motion'].frame_metadata(p, ground)['feet'],
           'measurements':values, 'evaluated_object_count':len(objects), 'evaluated_triangle_count':sum(o['triangles'] for o in objects)}
    report['cases'].append(row)
    report['evaluated_objects'] = objects
    (args.output/'visibility.json').write_text(json.dumps(report, indent=2)+'\n')
    print('ENVELOPE_VISIBILITY_CASE', json.dumps(row), flush=True)
    return row


for roll in (0, 20, 30):
    spec = next(c for c in envelope['report']['cases'] if c['yaw_degrees'] == -45 and c['windup_lateral'] == -.35 and c['contact_lateral'] == -.50 and c['tool_roll_degrees'] == roll)
    assert spec['passed'] and spec['samples'] == 135
    inspect(spec, .55)
selected = max(report['cases'], key=lambda row:row['measurements']['tool']['visible_fraction'])['specification']
for phase in (.375, .625):
    inspect(selected, phase)
report['selected_for_tiny_actual_image_probe_only'] = selected
report['complete'] = True
report['elapsed_seconds'] = time.monotonic()-started
(args.output/'visibility.json').write_text(json.dumps(report, indent=2)+'\n')
print('ENVELOPE_VISIBILITY_COMPLETE', len(report['cases']), report['elapsed_seconds'], flush=True)
