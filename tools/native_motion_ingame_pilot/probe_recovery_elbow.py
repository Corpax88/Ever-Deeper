"""Read-only geometry discriminator for the rejected Worn/up recovery pose.

Run the exact retained hinge control first, then swivel only the right elbow
around its fixed shoulder-wrist axis by +/-25 degrees at phase .8125. This is
not an animation, pose-owner change, render or production candidate.
"""
from pathlib import Path
import hashlib
import json
import os
import runpy
import sys
from mathutils import Quaternion

HERE = Path(__file__).resolve().parent
arguments = sys.argv[sys.argv.index('--') + 1:]
output_index = arguments.index('--output') + 1
output = Path(arguments[output_index])
assert not output.exists(), 'Use a fresh discriminator output directory'
control_arguments = list(arguments)
control_arguments[output_index] = str(output / 'control')
sys.argv = ['blender', '--', *control_arguments]
control = runpy.run_path(str(HERE / 'probe_upper_body_hinge_scene.py'))
control_file = output / 'control/hinge-scene-final.json'
control_bytes = control_file.read_bytes()
closed = json.loads(control_bytes)
assert closed['complete'] is True and closed['rendered'] is False
original = next(row for row in closed['critical_poses'] if row['phase'] == .8125)
assert original['hands']['R']['visible_pixel_centers'] == 0
assert original['hands']['L']['visible_pixel_centers'] == 6
assert [row['pixel_count'] for row in original['connections']['components']] == [94, 17, 3]

sample = control['sample']
apply = control['apply']
rig = control['rig']
mapped = control['mapped']
captured = control['captured']
matrix_error = control['matrix_error']
expected_objects = control['expected_objects']
p, _, _, _, _ = sample(.8125)
apply(p)
before = {bone.name: bone.matrix.copy() for bone in rig.pose.bones}
assert {'upper.R', 'lower.R', 'hand.R'} <= set(before)
protected = set(before) - {'upper.R', 'lower.R'}
shoulder, elbow, wrist = p['arms']['R']
axis = (wrist - shoulder).normalized()

report = {
    'complete': False,
    'rendered': False,
    'readability_accepted': False,
    'executed_source_sha': closed['executed_source_sha'],
    'source_tree': closed['source_tree'],
    'probe_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'control_final_sha256': hashlib.sha256(control_bytes).hexdigest(),
    'control_phase': original,
    'phase': .8125,
    'angles_degrees': [-25, 25],
    'protected_bones': sorted(protected),
    'cases': [],
    'scope': 'One right-elbow degree of freedom only; every other pose field, '
             'shoulder/wrist, both actual hands, torso/head/root/feet/tool and '
             'working-cap trajectory remain fixed. Two static diagnostic poses '
             'do not define a continuous recovery, demonstrate native-image '
             'readability or approve an animation.',
}
for degrees in report['angles_degrees']:
    rotation = Quaternion(axis, degrees * 3.141592653589793 / 180.)
    changed = dict(p)
    changed['arms'] = dict(p['arms'])
    changed['arms']['R'] = (shoulder, shoulder + rotation @ (elbow - shoulder), wrist)
    assert all(changed[key] is value for key, value in p.items() if key != 'arms')
    assert changed['arms']['L'] is p['arms']['L']
    apply(changed)
    after = {bone.name: bone.matrix.copy() for bone in rig.pose.bones}
    error = max(matrix_error(before[name], after[name]) for name in protected)
    lengths = {name: (rig.pose.bones[name].tail - rig.pose.bones[name].head).length
               for name in ('upper.R', 'lower.R')}
    length_error = max(abs(value - rig.data.bones[name].length)
                       for name, value in lengths.items())
    analytic_length_error = max(
        abs((changed['arms']['R'][i + 1] - changed['arms']['R'][i]).length
            - (p['arms']['R'][i + 1] - p['arms']['R'][i]).length)
        for i in (0, 1))
    assert max(error, length_error, analytic_length_error) < 1e-5
    captured.clear()
    parts = mapped['measure_parts'](changed, mapped['sample'])
    assert len(captured) == 1
    full, _, owners, objects = captured[0]
    assert {row['name']: row for row in objects} == expected_objects
    assert parts['object_count'] == 629 and parts['evaluated_triangles'] == 2714340
    hands = {side: control['hand_visibility'](side, full, owners) for side in ('R', 'L')}
    connections = control['connections'](parts['parts'], hands, changed)
    row = {
        'angle_degrees': degrees,
        'shoulder': list(shoulder), 'wrist': list(wrist),
        'elbow_before': list(elbow), 'elbow_after': list(changed['arms']['R'][1]),
        'protected_bone_matrix_error': error,
        'actual_arm_length_error': length_error,
        'analytic_arm_length_error': analytic_length_error,
        'before_matrices': {name: control['rows'](m) for name, m in before.items()},
        'after_matrices': {name: control['rows'](m) for name, m in after.items()},
        'parts': parts, 'hands': hands, 'connections': connections,
    }
    report['cases'].append(row)
    (output / 'elbow-progress.json').write_text(json.dumps(report, indent=2) + '\n')
    print('RECOVERY_ELBOW_GEOMETRY', degrees,
          [(side, h['visible_pixel_centers'], h['projected_pixel_centers'])
           for side, h in hands.items()], flush=True)
    captured.clear()
    del full, owners, objects

apply(p)
assert max(matrix_error(before[name], rig.pose.bones[name].matrix)
           for name in before) < 1e-5
report['original_pose_restored'] = True
report['complete'] = True
final = output / 'elbow-final.json'
pending = output / 'elbow-final.json.pending'
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
print('RECOVERY_ELBOW_FINAL_SHA256', hashlib.sha256(data).hexdigest(), len(data), flush=True)
