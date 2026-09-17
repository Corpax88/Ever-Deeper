"""Headless native contact-plane selection. No bitmap or rendered output."""
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
anatomy = runpy.run_path(str(HERE/'probe_up_anatomy.py'))
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools), '--output', str(args.output/'scene'), '--setup-only']
occlusion = runpy.run_path(str(HERE/'probe_up_occlusion.py'))
env = occlusion['env']
rig, rest = env['r'], env['rest']
ground = env['ground_vector']('up')
assert (ground-anatomy['GROUND']).length < 1e-8
report = {'complete':False, 'rendered':False, 'evaluated_native_rig_and_mesh':True,
          'source_base':'354bc9bd04953f4e20e23c2eef87d1affe686ab2',
          'source_hashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [Path(__file__), HERE/'probe_up_anatomy.py', HERE/'probe_up_occlusion.py']},
          'purpose':'Select a reachable native torso/hand plane with a real wrist roll, preserving the shaft aim and full feet. Geometric visibility is not visual/contact acceptance.',
          'model_sha256':occlusion['report']['model_sha256'], 'gear_sha256':occlusion['report']['gear_sha256'],
          'camera':occlusion['report']['camera'], 'target_cases':[], 'visibility_cases':[]}
started = time.monotonic()
for yaw, lateral, retreat, roll in [(-35, -.45, .15, 0), (-35, -.45, .15, 30), (-45, -.50, .15, 30)]:
    spec = {'upper_body_yaw_degrees':yaw, 'local_lateral':lateral, 'local_retreat':retreat, 'tool_roll_degrees':roll}
    case = {**spec, 'passed':True, 'sample_count':0, 'max_reach':0., 'max_segment_error':0.}
    for phase, original in anatomy['originals']:
        try:
            p = anatomy['anatomical_pose'](original, yaw, lateral, retreat, roll)
            assert p['axis'] is original['axis']
            for field in ('legs', 'foot_rotations', 'contacts'):
                assert p[field] is original[field]
            for a, b, c in p['arms'].values():
                case['max_reach'] = max(case['max_reach'], (c-a).length)
                case['max_segment_error'] = max(case['max_segment_error'], abs((b-a).length-.36), abs((c-b).length-.35))
            assert abs(p['axis'].dot(p['tool_normal'])) < 1e-6
            case['sample_count'] += 1
        except Exception as error:
            case.update(passed=False, failure_phase=phase, failure=repr(error))
            break
    report['target_cases'].append(case)
    if not case['passed']:
        continue
    original = env['native_motion'].sample('worn', 'mine', .55, ground, 340.)
    p = anatomy['anatomical_pose'](original, yaw, lateral, retreat, roll)
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
    record = {**spec, 'phase':.55, 'evaluated_hand_grip_error':grip,
              'rear':list(p['rear']), 'axis':list(p['axis']), 'tool_normal':list(p['tool_normal']),
              'native_feet':env['native_motion'].frame_metadata(p, ground)['feet'],
              'measurements':values, 'evaluated_object_count':len(objects), 'evaluated_triangle_count':sum(o['triangles'] for o in objects)}
    report['visibility_cases'].append(record)
    report['evaluated_objects'] = objects
    (args.output/'contact-visibility.json').write_text(json.dumps(report, indent=2)+'\n')
    print('CONTACT_VISIBILITY_CASE', json.dumps(record), flush=True)
report['complete'] = True
report['elapsed_seconds'] = time.monotonic()-started
(args.output/'contact-visibility.json').write_text(json.dumps(report, indent=2)+'\n')
print('CONTACT_VISIBILITY_COMPLETE', len(report['visibility_cases']), report['elapsed_seconds'], flush=True)
