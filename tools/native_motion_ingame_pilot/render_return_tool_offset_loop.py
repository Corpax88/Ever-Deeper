"""One source-timed native loop of the frozen hinge control and return path.

Fifty equal time steps include the .42 hit progress exactly. Native phase uses
the existing clock mapping. No interpolated keyframes, gameplay input, impact
serial, presentation latch, transition, production or performance claim.
"""
from pathlib import Path
from types import SimpleNamespace
import hashlib
import json
import os
import runpy
import sys
import bpy
from mathutils import Matrix

HERE = Path(__file__).resolve().parent
arguments = sys.argv[sys.argv.index('--') + 1:]
i = arguments.index('--keyframe-result')
reference_path = Path(arguments[i + 1])
del arguments[i:i + 2]
reference_bytes = reference_path.read_bytes()
reference_sha = hashlib.sha256(reference_bytes).hexdigest()
assert reference_sha == '63159410a569f86dd66b08fc7b5960d7dcae63e92ae3cf2028b7825d57fb6351'
reference = json.loads(reference_bytes)
assert reference['complete'] and reference['rendered']
assert reference['executed_source_sha'] == '47b2094c9b79703788c65c9dfbded48a41bc1ad2'
assert hashlib.sha256((HERE / 'render_return_tool_offset_keyframes.py').read_bytes()).hexdigest() == reference['observer_sha256']
prior_bytes = (reference_path.parent / 'replay/return-offset-final.json').read_bytes()
assert hashlib.sha256(prior_bytes).hexdigest() == reference['replay_final_sha256']
prior = json.loads(prior_bytes)

output = Path(arguments[arguments.index('--output') + 1])
assert not output.exists(), 'Use a fresh output directory'
base_arguments = list(arguments)
base_arguments[base_arguments.index('--output') + 1] = str(output / 'replay')
sys.argv = ['blender', '--', *base_arguments]
base = runpy.run_path(str(HERE / 'probe_return_tool_offset.py'))
replay_bytes = (output / 'replay/return-offset-final.json').read_bytes()
replay = json.loads(replay_bytes)
for key in ('source_hashes', 'control_source_hashes', 'model_sha256',
            'gear_sha256', 'candidate_count', 'amplitude', 'grip_span',
            'target_ground', 'protected_bones', 'dense_evaluated_poses',
            'critical_poses', 'unchanged_control_recovery',
            'all_bone_endpoint_0_1_error', 'original_recovery_restore_matrix_error'):
    assert replay[key] == prior[key], ('Frozen replay differs', key)
assert sorted(replay['input_reports'].values()) == sorted(prior['input_reports'].values())

control, candidate = base['control'], base['candidate']
env, native = control['env'], control['native']
rig, rest, scene = base['rig'], control['rest'], env['s']
sample, apply = base['sample'], base['apply']
matrix_error = control['matrix_error']
saved = {bone.name: bone.matrix.copy() for bone in rig.pose.bones}
assert scene.render.resolution_x == scene.render.resolution_y == 200
assert scene.render.resolution_percentage == 100 and scene.render.film_transparent
assert env['a'].gameplay_mine_cycle == .68 and env['a'].gameplay_hit_phase == .42
clock = SimpleNamespace(gear='worn', speed=340., mine_duration=.68, mine_hit_phase=.42)
count, cycle = 50, .68
assert abs(count * 17 / 1250 - cycle) < 1e-12
assert abs(native.Transition.phase_at(clock, 'mine', 0., 21 * 17 / 1250) - .55) < 1e-12
assert native.Transition.phase_at(clock, 'mine', 0., cycle) == 0.

report = {
    'complete': False, 'rendered': True, 'motion_accepted': False,
    'readability_accepted': False, 'gameplay_capture': False,
    'executed_source_sha': replay['executed_source_sha'],
    'source_tree': replay['source_tree'],
    'observer_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'keyframe_result_sha256': reference_sha,
    'replay_final_sha256': hashlib.sha256(replay_bytes).hexdigest(),
    'source_hashes': replay['source_hashes'],
    'control_source_hashes': replay['control_source_hashes'],
    'clock_source_sha256': hashlib.sha256(Path(native.__file__).read_bytes()).hexdigest(),
    'model_sha256': replay['model_sha256'], 'gear_sha256': replay['gear_sha256'],
    'candidate_count': 1, 'amplitude': 1., 'native_resolution': [200, 200],
    'render_engine': scene.render.engine,
    'timing': {'cycle_seconds': cycle, 'gameplay_hit_progress': .42,
               'native_hit_phase': .55, 'frames_per_cycle': count,
               'seconds_per_frame_fraction': [17, 1250],
               'encoding_frame_rate_fraction': [1250, 17],
               'phase_source': 'native_motion.Transition.phase_at',
               'actual_impact_serial_or_presentation_latch_simulated': False,
               'scope': 'Offline continuous clock samples; encoding cadence is not game FPS.'},
    'scope': 'Original model/camera/materials/lighting. Each pose actually applied '
             'and rendered at its source-derived time. Hinge-control is the previous '
             'study trajectory, not the published baseline. No image interpolation, '
             'idle/walk transition, impact event, in-game or performance approval.',
    'samples': [], 'frames': [],
}
progress = output / 'native-loop-progress.json'
first_matrices = {}
for index in range(count):
    seconds = index * 17 / 1250
    q = native.Transition.phase_at(clock, 'mine', 0., seconds)
    original, _, _, old_cap, _ = sample(q)
    posed, offset = candidate.sample(original, q, control['target'])
    assert native.frame_metadata(posed, control['ground'])['feet'] == native.frame_metadata(original, control['ground'])['feet']
    apply(original)
    before = {bone.name: bone.matrix.copy() for bone in rig.pose.bones}
    apply(posed)
    after = {bone.name: bone.matrix.copy() for bone in rig.pose.bones}
    fixed_error = max(matrix_error(before[n], after[n]) for n in replay['protected_bones'])
    rigid_error = max(matrix_error(Matrix.Translation(offset) @ before[n], after[n])
                      for n in ('tool', 'hand.R', 'hand.L'))
    grip_error = max((((after['hand.' + s] @ rig.data.bones['hand.' + s].matrix_local.inverted())
                      @ rest['grips'][s]) - posed['grips'][s]).length for s in native.SIDES)
    arm_names = ('upper.R', 'lower.R', 'upper.L', 'lower.L')
    length_error = max(abs((rig.pose.bones[n].tail - rig.pose.bones[n].head).length
                           - rig.data.bones[n].length) for n in arm_names)
    cap = after['tool'] @ rig.data.bones['tool'].matrix_local.inverted() @ control['center_rest']
    cap_error = (cap - old_cap - offset).length
    reach = max((c - a).length for a, _, c in posed['arms'].values())
    zero_window = .125 <= q <= .625
    zero_error = max(matrix_error(before[n], after[n]) for n in before) if zero_window else None
    errors = [fixed_error, rigid_error, grip_error, length_error, cap_error]
    if zero_window:
        assert posed is original and offset.length == 0.
        errors.append(zero_error)
    assert max(errors) < 1e-5 and reach < .71, (index, q, errors, reach)
    if index == 0:
        first_matrices = {'hinge-control': before, 'candidate': after}
        initial = prior['dense_evaluated_poses'][0]
        for current, key in ((before, 'before_matrices'), (after, 'after_matrices')):
            assert max(matrix_error(current[n], Matrix(initial[key][n])) for n in current) < 1e-5
    report['samples'].append({
        'index': index, 'time_seconds': seconds, 'gameplay_progress': seconds / cycle,
        'native_phase': q, 'offset': list(offset),
        'protected_bone_error': fixed_error, 'rigid_tool_hand_error': rigid_error,
        'actual_grip_error': grip_error, 'actual_arm_length_error': length_error,
        'actual_cap_error': cap_error, 'maximum_arm_reach': reach,
        'zero_window_all_bone_error': zero_error,
        'before_matrices': {n: control['rows'](m) for n, m in before.items()},
        'after_matrices': {n: control['rows'](m) for n, m in after.items()},
    })
    for variant, pose, expected in (('hinge-control', original, before), ('candidate', posed, after)):
        apply(pose)
        env['blink'](0.)
        render_error = max(matrix_error(expected[bone.name], bone.matrix) for bone in rig.pose.bones)
        assert render_error < 1e-5
        for modifier in env['skin']:
            modifier.show_viewport = True
        bpy.context.view_layer.update()
        key = f'{variant}-{index:04}'
        paths = [output / (key + '.png'), output / ('mask-' + key + '-0001.png')]
        scene.render.filepath = str(paths[0])
        env['mask'].base_path = str(output)
        env['mask'].file_slots[0].path = 'mask-' + key + '-'
        scene.frame_current = 1
        bpy.ops.render.render(write_still=True)
        files = []
        for path in paths:
            with path.open('rb') as handle:
                os.fsync(handle.fileno())
            data = path.read_bytes()
            assert data[:8] == b'\x89PNG\r\n\x1a\n'
            assert [int.from_bytes(data[a:a + 4], 'big') for a in (16, 20)] == [200, 200]
            files.append({'path': path.name, 'bytes': len(data),
                          'sha256': hashlib.sha256(data).hexdigest()})
        report['frames'].append({'index': index, 'variant': variant,
                                 'time_seconds': seconds, 'native_phase': q,
                                 'actual_render_matrix_error': render_error, 'files': files})
        progress.write_text(json.dumps(report, indent=2) + '\n')
        print('RETURN_NATIVE_LOOP_FRAME', variant, index, q, flush=True)
assert len(report['samples']) == 50 and len(report['frames']) == 100
original, _, _, _, _ = sample(native.Transition.phase_at(clock, 'mine', 0., cycle))
posed, _ = candidate.sample(original, 0., control['target'])
endpoint_errors = {}
for variant, pose in (('hinge-control', original), ('candidate', posed)):
    apply(pose)
    endpoint_errors[variant] = max(matrix_error(first_matrices[variant][n], rig.pose.bones[n].matrix)
                                   for n in first_matrices[variant])
assert max(endpoint_errors.values()) < 1e-5
report['time_zero_cycle_endpoint_errors'] = endpoint_errors
original, _, _, _, _ = sample(.8125)
apply(original)
restore_error = max(matrix_error(saved[n], rig.pose.bones[n].matrix) for n in saved)
assert restore_error < 1e-5
report['original_recovery_restore_matrix_error'] = restore_error
report['complete'] = True
pending = output / 'native-loop-final.json.pending'
final = output / 'native-loop-final.json'
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
print('RETURN_NATIVE_LOOP_FINAL_SHA256', hashlib.sha256(data).hexdigest(), len(data), flush=True)
