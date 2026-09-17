"""Reach audit for a native side-working stroke; no scene/renderer needed."""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
args.output.parent.mkdir(parents=True, exist_ok=True)
sys.argv = ['blender', '--', '--output', str(args.output.parent/'constant-plane-controls.json')]
anatomy = runpy.run_path(str(HERE/'probe_up_anatomy.py'))


def contact_weight(phase):
    phase %= 1.
    if phase <= .4:
        return 0.
    if phase < .55:
        x = (phase-.4)/.15
    elif phase <= .625:
        return 1.
    elif phase < .82:
        x = (.82-phase)/(.82-.625)
    else:
        return 0.
    return x*x*(3.-2.*x)


report = {'rendered':False, 'evaluated_native_rig':False,
          'purpose':'Source-pose reach audit for a genuine lateral stroke. No visual or evaluated-attachment approval.',
          'source_base':'354bc9bd04953f4e20e23c2eef87d1affe686ab2',
          'envelope':{'zero_through':.4, 'smooth_to_contact':.55, 'hold_through':.625, 'smooth_return_by':.82},
          'source_hashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [Path(__file__), HERE/'probe_up_anatomy.py']},
          'cases':[]}
for yaw in (-35, -45):
    for before in (-.30, -.35):
        for contact in (-.45, -.50, -.55):
            for roll in (0, 20, 30):
                row = {'yaw_degrees':yaw, 'windup_lateral':before, 'contact_lateral':contact, 'windup_retreat':.1, 'contact_retreat':.15,
                       'tool_roll_degrees':roll, 'passed':True, 'samples':0, 'max_reach':0., 'max_segment_error':0.}
                for phase, original in anatomy['originals']:
                    w = contact_weight(phase)
                    lateral, retreat = before+(contact-before)*w, .10+.05*w
                    try:
                        p = anatomy['anatomical_pose'](original, yaw, lateral, retreat, roll)
                        assert p['axis'] is original['axis']
                        for field in ('legs', 'foot_rotations', 'contacts'):
                            assert p[field] is original[field]
                        for a, b, c in p['arms'].values():
                            row['max_reach'] = max(row['max_reach'], (c-a).length)
                            row['max_segment_error'] = max(row['max_segment_error'], abs((b-a).length-.36), abs((c-b).length-.35))
                        row['samples'] += 1
                    except Exception as error:
                        row.update(passed=False, failure_phase=phase, failure=repr(error))
                        break
                report['cases'].append(row)
args.output.write_text(json.dumps(report, indent=2)+'\n')
print('CONTACT_ENVELOPE_REACH', json.dumps({'cases':len(report['cases']), 'passed':sum(r['passed'] for r in report['cases'])}), flush=True)
