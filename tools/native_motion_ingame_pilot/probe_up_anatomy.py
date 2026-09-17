"""Bounded anatomical target investigation; no images or runtime assets made."""
from pathlib import Path
import argparse
import hashlib
import json
import math
import sys
import bpy
from mathutils import Matrix, Vector

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ROOT = Path(__file__).resolve().parents[1] / 'hero_v28'
sys.path.insert(0, str(ROOT))
import native_motion as native
import premium_motion as pm
T = Matrix.Translation
GROUND = Vector((-.02208799682557583, -.022456128150224686, 0))


def anatomical_pose(original, yaw, lateral, retreat, tool_roll=0.):
    pivot = original['torso']@Vector((0, 0, .6))
    turn = T(pivot)@Matrix.Rotation(math.radians(yaw), 4, 'Z')@T(-pivot)
    torso = turn@original['torso']
    neck = torso@Vector((0, 0, 1.135))
    # Follow the anatomical neck location, counter-turn the gaze toward the
    # same up heading. No whole-character or camera heading change.
    head = T(neck)@Matrix.Rotation(math.radians(-yaw), 4, 'Z')@T(-neck)@turn@original['head']
    delta = pm.heading_matrix(GROUND)@Vector((lateral, retreat, 0))
    normal = (Matrix.Rotation(math.radians(tool_roll), 3, original['axis'])@original['tool_normal']
              if tool_roll else original['tool_normal'])
    solved = pm._assemble('worn', torso, head, original['rear']+delta,
                          original['axis'], normal,
                          {s:original['legs'][s][0] for s in native.SIDES},
                          {s:original['legs'][s][2] for s in native.SIDES},
                          original['bit_angle'], original['contacts'],
                          {s:original['legs'][s][1] for s in native.SIDES})
    p = dict(original)
    for field in ('torso', 'head', 'rear', 'tool_normal', 'grips', 'hand_axes', 'radials', 'arms'):
        p[field] = solved[field]
    return p


phases = sorted(set([i/128 for i in range(129)]+[.24, .40, .55, .575, .625, .68, .82]))
originals = [(q, native.sample('worn', 'mine', q, GROUND, 340.)) for q in phases]
report = {'rendered':False, 'evaluated_native_rig':False, 'purpose':'Native anatomical target reach only; selection still needs evaluated geometry, grip and actual images',
          'native_base':'354bc9bd04953f4e20e23c2eef87d1affe686ab2', 'phases':phases, 'cases':[],
          'source_hashes':{str(p.relative_to(ROOT.parent.parent)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'native_motion.py', ROOT/'premium_motion.py', Path(__file__)]}}
for yaw in (-15, -25, -35, -45):
    for lateral in (-.20, -.25, -.30, -.35, -.40):
        for retreat in (.05, .10, .15):
            row = {'upper_body_yaw_degrees':yaw, 'local_lateral':lateral, 'local_retreat':retreat,
                   'passed':True, 'sample_count':0, 'max_reach':0., 'max_arm_segment_error':0.,
                   'max_neck_translation':0.}
            for phase, original in originals:
                try:
                    p = anatomical_pose(original, yaw, lateral, retreat)
                    for field in ('legs', 'foot_rotations', 'contacts'):
                        assert p[field] is original[field]
                    assert p['axis'] is original['axis'] and p['tool_normal'] is original['tool_normal']
                    for a, b, c in p['arms'].values():
                        row['max_reach'] = max(row['max_reach'], (c-a).length)
                        row['max_arm_segment_error'] = max(row['max_arm_segment_error'], abs((b-a).length-.36), abs((c-b).length-.35))
                    row['max_neck_translation'] = max(row['max_neck_translation'],
                        (p['torso']@Vector((0,0,1.135))-original['torso']@Vector((0,0,1.135))).length)
                    row['sample_count'] += 1
                except Exception as error:
                    row.update(passed=False, failure_phase=phase, failure=repr(error))
                    break
            report['cases'].append(row)
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(report, indent=2)+'\n')
print('ANATOMY_TARGETS', json.dumps({'cases':len(report['cases']), 'passed':sum(c['passed'] for c in report['cases'])}), flush=True)
