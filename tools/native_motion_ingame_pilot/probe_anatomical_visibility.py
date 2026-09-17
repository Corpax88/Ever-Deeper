"""Evaluate three bounded anatomical candidates without rendering any image."""
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
          'purpose':'Geometric occlusion of evaluated native mesh plus actual grip constraints. Image readability, materials and ore contact remain unaccepted.',
          'model_sha256':occlusion['report']['model_sha256'], 'gear_sha256':occlusion['report']['gear_sha256'],
          'camera':occlusion['report']['camera'], 'cases':[]}
started = time.monotonic()
for yaw, lateral, retreat in [(-25, -.30, .10), (-35, -.35, .10), (-45, -.40, .10)]:
    for phase in (.375, .55, .625):
        original = env['native_motion'].sample('worn', 'mine', phase, ground, 340.)
        p = anatomy['anatomical_pose'](original, yaw, lateral, retreat)
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
        case = {'upper_body_yaw_degrees':yaw, 'local_lateral':lateral, 'local_retreat':retreat, 'phase':phase,
                'evaluated_hand_grip_error':grip, 'rear':list(p['rear']), 'axis':list(p['axis']),
                'tool_axis_unchanged':p['axis'] == original['axis'],
                'native_feet':env['native_motion'].frame_metadata(p, ground)['feet'],
                'measurements':values, 'evaluated_object_count':len(objects), 'evaluated_triangle_count':sum(o['triangles'] for o in objects)}
        report['cases'].append(case)
        report['evaluated_objects'] = objects
        (args.output/'visibility.json').write_text(json.dumps(report, indent=2)+'\n')
        print('ANATOMY_VISIBILITY_CASE', json.dumps(case), flush=True)
report['complete'] = True
report['elapsed_seconds'] = time.monotonic()-started
(args.output/'visibility.json').write_text(json.dumps(report, indent=2)+'\n')
print('ANATOMY_VISIBILITY_COMPLETE', len(report['cases']), report['elapsed_seconds'], flush=True)
