"""Single return candidate: dense actual rig, then only .8125 full geometry.

First execute the unchanged ff96066 control. This wrapper never renders an
image, changes production assets, or promotes geometry to readability approval.
All original input reports must be recovered exactly before execution.
"""
from pathlib import Path
import hashlib
import json
import os
import runpy
import sys
from mathutils import Matrix

HERE = Path(__file__).resolve().parent
arguments = sys.argv[sys.argv.index('--') + 1:]
output_index = arguments.index('--output') + 1
output = Path(arguments[output_index])
assert not output.exists(), 'Use a fresh output directory'
control_arguments = list(arguments)
control_arguments[output_index] = str(output / 'control')
sys.argv = ['blender', '--', *control_arguments]
control = runpy.run_path(str(HERE / 'probe_upper_body_hinge_scene.py'))
control_file = output / 'control/hinge-scene-final.json'
control_bytes = control_file.read_bytes()
closed = json.loads(control_bytes)
assert closed['complete'] is True and closed['rendered'] is False
old_recovery = next(r for r in closed['critical_poses'] if r['phase'] == .8125)
assert old_recovery['hands']['R']['visible_pixel_centers'] == 0
assert old_recovery['hands']['L']['visible_pixel_centers'] == 6
assert [r['pixel_count'] for r in old_recovery['connections']['components']] == [94, 17, 3]

import return_tool_offset_pose as candidate

sample = control['sample']
apply = control['apply']
rig, rest = control['rig'], control['rest']
native = control['native']
matrix_error = control['matrix_error']
mapped, captured = control['mapped'], control['captured']
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
changed_bones = {'upper.R', 'lower.R', 'hand.R', 'upper.L', 'lower.L', 'hand.L', 'tool'}
protected = set(rig.pose.bones.keys()) - changed_bones
assert {'root', 'hips', 'body', 'head', 'foot.R', 'foot.L'} <= protected
report = {
    'complete': False, 'rendered': False, 'readability_accepted': False,
    'executed_source_sha': closed['executed_source_sha'],
    'source_tree': closed['source_tree'],
    'source_hashes': {n: sha(HERE / n) for n in
                      ('probe_return_tool_offset.py', 'return_tool_offset_pose.py')},
    'control_final_sha256': hashlib.sha256(control_bytes).hexdigest(),
    'control_source_hashes': closed['source_hashes'],
    'input_reports': closed['input_reports'],
    'model_sha256': closed['model_sha256'], 'gear_sha256': closed['gear_sha256'],
    'candidate_count': 1, 'amplitude': 1., 'grip_span': .145,
    'target_ground': list(control['target']),
    'protected_bones': sorted(protected), 'dense_evaluated_poses': [],
    'critical_poses': [],
    'scope': 'One frozen rigid return translation; .125-.625 is exactly '
             'unchanged. Recovery cap contract is old cap plus offset. '
             'No render, controller, idle transition, all-tool or publication approval.',
}
progress = output / 'return-offset-progress.json'


def write_progress():
    progress.write_text(json.dumps(report, indent=2) + '\n')


endpoint_matrices = {}
for q in control['phases']:
    original, _, _, old_cap, _ = sample(q)
    posed, offset = candidate.sample(original, q, control['target'])
    for key, value in original.items():
        if key not in ('rear', 'grips', 'arms'):
            assert posed[key] is value, (q, key)
    zero_window = .125 <= q % 1. <= .625
    if zero_window:
        assert posed is original and offset.length == 0.
    assert native.frame_metadata(posed, control['ground'])['feet'] == native.frame_metadata(original, control['ground'])['feet']
    apply(original)
    before = {b.name: b.matrix.copy() for b in rig.pose.bones}
    if q == .8125:
        recovery_before = before
    apply(posed)
    after = {b.name: b.matrix.copy() for b in rig.pose.bones}
    fixed_error = max(matrix_error(before[n], after[n]) for n in protected)
    transform_error = max(matrix_error(Matrix.Translation(offset) @ before[n], after[n])
                          for n in ('tool', 'hand.R', 'hand.L'))
    measured_grips = {s: (after['hand.' + s] @ rig.data.bones['hand.' + s].matrix_local.inverted()) @ rest['grips'][s]
                      for s in native.SIDES}
    grip_error = max((measured_grips[s] - posed['grips'][s]).length for s in native.SIDES)
    intended_grip_error = max((posed['grips'][s] - original['grips'][s] - offset).length for s in native.SIDES)
    arm_names = ('upper.R', 'lower.R', 'upper.L', 'lower.L')
    actual_lengths = {n: (rig.pose.bones[n].tail - rig.pose.bones[n].head).length for n in arm_names}
    length_error = max(abs(v - rig.data.bones[n].length) for n, v in actual_lengths.items())
    reach = max((c - a).length for a, _, c in posed['arms'].values())
    measured_cap = after['tool'] @ rig.data.bones['tool'].matrix_local.inverted() @ control['center_rest']
    expected_cap = old_cap + offset
    cap_error = (measured_cap - expected_cap).length
    zero_error = max(matrix_error(before[n], after[n]) for n in before) if zero_window else None
    row = {'phase': q, 'weight': candidate.weight(q), 'offset': list(offset),
           'fixed_body_head_root_leg_matrix_error': fixed_error,
           'rigid_tool_hand_translation_error': transform_error,
           'actual_grip_error': grip_error, 'intended_grip_translation_error': intended_grip_error,
           'actual_arm_length_error': length_error, 'maximum_arm_reach': reach,
           'translated_cap_error': cap_error, 'zero_window_all_bone_error': zero_error,
           'before_matrices': {n: control['rows'](m) for n, m in before.items()},
           'after_matrices': {n: control['rows'](m) for n, m in after.items()},
           'actual_grips': {s: list(v) for s, v in measured_grips.items()},
           'actual_arm_lengths': actual_lengths,
           'old_cap_centroid': list(old_cap), 'expected_cap_centroid': list(expected_cap),
           'actual_cap_centroid': list(measured_cap)}
    report['dense_evaluated_poses'].append(row)
    errors = [fixed_error, transform_error, grip_error, intended_grip_error, length_error, cap_error]
    if zero_error is not None:
        errors.append(zero_error)
    if not (max(errors) < 1e-5 and reach < .71):
        report['failure'] = {'phase': q, 'metrics': row}
        write_progress()
        raise AssertionError(('Actual return rig constraint failed', q))
    if q in (0., 1.):
        endpoint_matrices[q] = after
assert len(report['dense_evaluated_poses']) == 135
endpoint_error = max(matrix_error(endpoint_matrices[0.][n], endpoint_matrices[1.][n]) for n in endpoint_matrices[0.])
assert endpoint_error < 1e-5
report['all_bone_endpoint_0_1_error'] = endpoint_error
write_progress()
print('RETURN_OFFSET_DENSE_RIG_COMPLETE', 135, flush=True)

original, _, _, _, _ = sample(.8125)
posed, offset = candidate.sample(original, .8125, control['target'])
apply(posed)
captured.clear()
parts = mapped['measure_parts'](posed, mapped['sample'])
assert len(captured) == 1
full, _, owners, objects = captured[0]
assert {r['name']: r for r in objects} == control['expected_objects']
assert parts['object_count'] == 629 and parts['evaluated_triangles'] == 2714340
hands = {s: control['hand_visibility'](s, full, owners) for s in native.SIDES}
report['critical_poses'].append({'phase': .8125, 'offset': list(offset),
                               'parts': parts, 'hands': hands,
                               'connections': control['connections'](parts['parts'], hands, posed)})
report['unchanged_control_recovery'] = old_recovery
report['late_phase_geometry_reviewed'] = False
report['next_gate'] = 'Independent .8125 geometry review before any late samples or images; reject absent/disconnected grips.'
captured.clear()
apply(original)
restore_error = max(matrix_error(recovery_before[n], rig.pose.bones[n].matrix) for n in recovery_before)
assert restore_error < 1e-5
report['original_recovery_restore_matrix_error'] = restore_error
report['original_recovery_pose_restored'] = True
report['complete'] = True
pending = output / 'return-offset-final.json.pending'
final = output / 'return-offset-final.json'
data = (json.dumps(report, indent=2) + '\n').encode()
with pending.open('xb') as handle:
    handle.write(data)
    handle.flush()
    os.fsync(handle.fileno())
os.replace(pending, final)
fd = os.open(output, os.O_RDONLY)
try:
    os.fsync(fd)
finally:
    os.close(fd)
assert final.read_bytes() == data
print('RETURN_OFFSET_FINAL_SHA256', hashlib.sha256(data).hexdigest(), len(data), flush=True)
