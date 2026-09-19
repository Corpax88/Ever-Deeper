"""Export one immutable PivotReturnMotion candidate without applying the rig."""
import bpy
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys

import numpy as np

ROOT = Path('/workspace/scratch/eb19e34b942d/ever-deeper')
OUT = Path('/tmp/pivot-return-16H-independent')
HERE = ROOT / 'tools/native_motion_ingame_pilot'
TEMP = Path('/tmp/pivot-return-16H-plan')
BODY_PLAN = Path('/tmp/pivot-return-16E-plan')
TOOL_PLAN = Path('/tmp/pivot-return-16D-plan')
EXPECTED = 'b36388c96ac5ded535d88aff4bbb6bf07594cca39fb61e2de09a6cced4983993'
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
OUT.mkdir(parents=True, exist_ok=True)
assert sha(TEMP / 'pivot_return_motion.py') == EXPECTED
assert sha(TEMP / 'transported_forearm_frame_pose.py') == '5958d0561396daf2abcc2e28c81e75c3132b1dfc03f0b48aceb9e2892f9b4477'
assert sha(bpy.data.filepath) == '94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
sys.path[:0] = [str(TEMP), str(HERE), str(ROOT / 'tools/hero_v28')]
from pivot_return_motion import PivotReturnMotion
import pivot_return_motion
assert Path(pivot_return_motion.__file__).resolve() == TEMP/'pivot_return_motion.py'
assert sha(TOOL_PLAN/'curve-report.json') == '388a82adc3376af8848c8cce90ea49353a7a0fb1ad9d82b1d7525e8d6fcf2a6e'
assert sha(BODY_PLAN/'body-curve-report.json') == '23b1180f41516807755ac6f035d69ac67011806bb706ce6b4ce7f721f519bfb6'
curve=json.loads((TOOL_PLAN/'curve-report.json').read_text())
from coordinated_body_motion import CoordinatedBodyMotion
from loop_flow_motion import CYCLE_SECONDS, native_phase
import premium_motion as pm
import motion_v9

input_paths = [HERE / 'working-surface-selection.json', HERE / 'upper-body-hinge-selection.json',
               Path('/workspace/scratch/eb19e34b942d/recovery/pivot-report.json')]
inputs = [json.loads(p.read_text()) for p in input_paths]
old, new = CoordinatedBodyMotion(*inputs), PivotReturnMotion(*inputs)
T = CYCLE_SECONDS
grid = sorted(set([min(T, i / 1200) for i in range(math.ceil(T * 1200) + 1)] +
                  [min(T, i / hz) for hz in (60, 120) for i in range(math.ceil(T * hz) + 1)]))
phases = [native_phase(t / T) for t in grid] + [i / 500 for i in range(501)]
phases += [.08, .30, .40, .55, .625, .86, 0., 1., .3928571428571429, PivotReturnMotion.END_PHASE]
phases += [row['phase'] for row in curve['rows']]
record=json.loads(Path('/tmp/ever-deeper-loop-flow-20260919/pivot-game-16G/native-ingame.json').read_text())
phases += [s['visual']['sample_phase'] for s in record['samples'] if s['visual']['state']=='mine']
for x in sorted(set(PivotReturnMotion.KNOTS)):
    seconds=PivotReturnMotion.START_SECONDS+x*(PivotReturnMotion.END_SECONDS-PivotReturnMotion.START_SECONDS)
    q=native_phase((seconds/T)%1.)
    phases.extend([math.nextafter(q,-math.inf),q,math.nextafter(q,math.inf)])
arrays = {}
weights = []
turn_angles=[]
body_yaws=[]
return_translations=[]

def add(prefix, p):
    values = {
        'arms': [[list(v) for v in p['arms'][s]] for s in ('R', 'L')],
        'legs': [[list(v) for v in p['legs'][s]] for s in ('R', 'L')],
        'radials': [list(p['radials'][s]) for s in ('R', 'L')],
        'grips': [list(p['grips'][s]) for s in ('R', 'L')],
        'hand_axes': [list(p['hand_axes'][s]) for s in ('R', 'L')],
        'rear': list(p['rear']),
        'body': [[list(row) for row in p[k]] for k in ('torso', 'head')],
        'foot_rotations': [[list(row) for row in p['foot_rotations'][s]] for s in ('R', 'L')],
        'tool': [list(row) for row in pm.tool_frame(p['axis'], p['tool_normal'])],
        'contacts': [p['contacts'][s] for s in ('R', 'L')],
        'right_forearm_basis': [list(row) for row in p.get('right_forearm_basis',np.eye(3))],
        'has_right_forearm_basis': 'right_forearm_basis' in p,
        'left_upper_transport': [list(row) for row in p.get('left_upper_transport',np.eye(3))],
        'has_left_upper_transport': 'left_upper_transport' in p,
        'left_upper_original_axis': list(p.get('left_upper_original_axis',(0.,0.,0.))),
        'left_upper_reference_denominator': p.get('left_upper_reference_denominator',0.),
        'right_forearm_reference_denominator': p.get('right_forearm_reference_denominator',0.),
        'right_forearm_original_radial_projection': p.get('right_forearm_original_radial_projection',0.),
    }
    for k, v in values.items():
        arrays.setdefault(prefix + '_' + k, []).append(v)

for q in phases:
    q = float(q)
    p0=old.sample('mine',q)
    try:
        p=new.sample('mine',q)
    except Exception as error:
        failure=dict(complete=True,passed_analytic=False,passed_geometry=False,candidate_rig_evaluated=False,rendered=False,candidate_sha256=EXPECTED,phase=q,angle_radians=new.turn_angle(q),body_yaw_radians=new.body_yaw(q),error=str(error),completed_samples=len(weights),old_arms={s:[list(v) for v in p0['arms'][s]] for s in ('R','L')},old_grips={s:list(v) for s,v in p0['grips'].items()},old_rear=list(p0['rear']))
        (OUT/'export-failure.json').write_text(json.dumps(failure,indent=2)+'\n')
        np.savez_compressed(OUT/'partial-kinematics.npz',**{k:np.array(v) for k,v in arrays.items()},phases=np.array(phases[:len(weights)]),weights=np.array(weights))
        raise
    add('old',p0)
    add('new',p)
    weights.append(new.clearance_weight(q))
    turn_angles.append(new.turn_angle(q))
    body_yaws.append(new.body_yaw(q))
    return_translations.append(list(new.return_translation(q)))

def pose_error(a, b):
    errors = []
    for key in ('torso', 'head'):
        errors.append(max(abs(a[key][i][j] - b[key][i][j]) for i in range(4) for j in range(4)))
    for key in ('rear', 'axis', 'tool_normal'):
        errors.append((a[key] - b[key]).length)
    for key in ('grips', 'hand_axes', 'radials'):
        errors.extend((a[key][s] - b[key][s]).length for s in ('R', 'L'))
    for key in ('arms', 'legs'):
        errors.extend((a[key][s][i] - b[key][s][i]).length for s in ('R', 'L') for i in range(3))
    for s in ('R', 'L'):
        errors.extend(abs(a['foot_rotations'][s][i][j] - b['foot_rotations'][s][i][j]) for i in range(3) for j in range(3))
    errors.append(float(a['contacts'] != b['contacts']))
    errors.append(float(('right_forearm_basis' in a) != ('right_forearm_basis' in b)))
    errors.append(float(('left_upper_transport' in a) != ('left_upper_transport' in b)))
    return max(errors)

nonmine = {state: max(pose_error(old.sample(state, i / 500), new.sample(state, i / 500))
                      for i in range(501)) for state in ('idle', 'walk')}
rig = bpy.data.objects['EverDeeper_Hero_Rig']
rest = motion_v9.rest('pickaxe')
axes = {name + side: list((rig.data.bones[name + side].tail_local - rig.data.bones[name + side].head_local).normalized())
        for name in ('upper.', 'lower.') for side in ('R', 'L')}
arrays.update(phases=np.array(phases), times=np.array(grid), weights=np.array(weights),turn_angles=np.array(turn_angles),body_yaws=np.array(body_yaws),return_translations=np.array(return_translations))
np.savez_compressed(OUT / 'analytic-kinematics.npz', **{k: np.array(v) for k, v in arrays.items()})
sources = {}
for module in list(sys.modules.values()):
    file = getattr(module, '__file__', None)
    if file:
        p = Path(file).resolve()
        if p.suffix == '.py' and p.is_relative_to(ROOT):
            relative = str(p.relative_to(ROOT))
            sources[relative] = sha(p)
            target = OUT / 'source' / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(p.read_bytes())
for p in input_paths:
    target = OUT / 'inputs' / p.name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(p.read_bytes())
assert sha(TEMP / 'pivot_return_motion.py') == EXPECTED
assert sha(TEMP / 'transported_forearm_frame_pose.py') == '5958d0561396daf2abcc2e28c81e75c3132b1dfc03f0b48aceb9e2892f9b4477'
for name in ('pivot_return_motion.py','transported_forearm_frame_pose.py','translation-fit.json'):
    (OUT/'inputs'/name).write_bytes((TEMP/name).read_bytes())
for name in ('body-curve-report.json','body-corridor.json','fit_body_yaw.py','derive_body_corridor.py'):
    (OUT/'inputs'/name).write_bytes((BODY_PLAN/name).read_bytes())
(OUT/'inputs'/'curve-report.json').write_bytes((TOOL_PLAN/'curve-report.json').read_bytes())
meta = dict(frame_helper_sha256=sha(TEMP/'transported_forearm_frame_pose.py'),body_joint_local=list(old.body_joint),body_fit_sha256=sha(BODY_PLAN/'body-curve-report.json'),candidate_source_path=str(TEMP/'pivot_return_motion.py'),fit_sha256=sha(TOOL_PLAN/'curve-report.json'),repo_candidate_sha256=sha(HERE/'pivot_return_motion.py'),complete=True, rendered=False, candidate_rig_evaluated=False,
            candidate_sha256=EXPECTED, source_hashes=sources,
            source_head=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
            script_sha256=sha(__file__), native_sha256=sha(bpy.data.filepath),
            inputs={str(p): sha(p) for p in input_paths},
            cycle_seconds=T, regular_time_samples=len(grid), dense_phase_samples=501,
            total_mine_samples=len(phases), rest_axes=axes,
            rest_radials={s: list(rest['radials'][s]) for s in ('R', 'L')},
            nonmine_maximum_error=nonmine, selection=new.selection(),
            data_sha256=sha(OUT / 'analytic-kinematics.npz'))
(OUT / 'analytic-export.json').write_text(json.dumps(meta, indent=2) + '\n')
print('PIVOT_ANALYTIC_EXPORT_COMPLETE', json.dumps({k: v for k, v in meta.items() if k not in ('source_hashes', 'rest_axes', 'rest_radials', 'selection')}), flush=True)
