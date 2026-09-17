"""Native hinge-control/candidate keyframes from a frozen geometry review.

This is an offline pose render, not a gameplay capture or animation approval.
"""
from pathlib import Path
import hashlib
import json
import os
import runpy
import sys
import bpy
from mathutils import Matrix

HERE = Path(__file__).resolve().parent
arguments = sys.argv[sys.argv.index('--') + 1:]
def take(name):
    i = arguments.index(name)
    value = arguments[i + 1]
    del arguments[i:i + 2]
    return value

late_path = Path(take('--late-result'))
late_sha = take('--late-result-sha256')
late_bytes = late_path.read_bytes()
assert hashlib.sha256(late_bytes).hexdigest() == late_sha
late = json.loads(late_bytes)
assert late['complete'] and not late['rendered']
assert late['candidate_count'] == 1 and late['amplitude'] == 1.
assert hashlib.sha256((HERE / 'probe_return_tool_offset_late.py').read_bytes()).hexdigest() == late['observer_sha256']
prior_replay_bytes = (late_path.parent / 'replay/return-offset-final.json').read_bytes()
assert hashlib.sha256(prior_replay_bytes).hexdigest() == late['replay_final_sha256']
prior_replay = json.loads(prior_replay_bytes)
phases = [0., .125, .375, .55, .625, .6875, .75, .78125, .8125,
          .82, .828125, .875, .90625, .9375, .9921875]
assert late['phases'] == phases

output = Path(arguments[arguments.index('--output') + 1])
assert not output.exists()
base_arguments = list(arguments)
base_arguments[base_arguments.index('--output') + 1] = str(output / 'replay')
sys.argv = ['blender', '--', *base_arguments]
base = runpy.run_path(str(HERE / 'probe_return_tool_offset.py'))
replay_path = output / 'replay/return-offset-final.json'
replay_bytes = replay_path.read_bytes()
replay = json.loads(replay_bytes)
for key in ('source_hashes', 'control_source_hashes', 'model_sha256',
            'gear_sha256', 'candidate_count', 'amplitude', 'grip_span',
            'target_ground', 'protected_bones', 'dense_evaluated_poses',
            'critical_poses', 'unchanged_control_recovery',
            'all_bone_endpoint_0_1_error', 'original_recovery_restore_matrix_error'):
    assert replay[key] == prior_replay[key], ('Frozen replay differs', key)
assert sorted(replay['input_reports'].values()) == sorted(prior_replay['input_reports'].values())

control = base['control']
env = control['env']
rig, scene = base['rig'], env['s']
sample, apply, candidate = base['sample'], base['apply'], base['candidate']
dense = {row['phase']: row for row in replay['dense_evaluated_poses']}
assert all(q in dense for q in phases)
assert scene.render.resolution_x == scene.render.resolution_y == 200
assert scene.render.resolution_percentage == 100
assert scene.render.film_transparent
before = {bone.name: bone.matrix.copy() for bone in rig.pose.bones}
report = {
    'complete': False, 'rendered': True, 'readability_accepted': False,
    'executed_source_sha': replay['executed_source_sha'],
    'source_tree': replay['source_tree'],
    'observer_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'late_result_sha256': late_sha,
    'replay_final_sha256': hashlib.sha256(replay_bytes).hexdigest(),
    'source_hashes': replay['source_hashes'],
    'control_source_hashes': replay['control_source_hashes'],
    'model_sha256': replay['model_sha256'], 'gear_sha256': replay['gear_sha256'],
    'candidate_count': 1, 'amplitude': 1., 'phases': phases,
    'render_engine': scene.render.engine,
    'native_resolution': [200, 200], 'frames': [],
    'scope': 'Original native camera, model, gear, materials, lighting and 200px scale. '
             'Fifteen candidate keyframes, with unchanged hinge-control comparisons '
             'for changed poses; control is not the published native trajectory. '
             'No gameplay, transition, continuous-motion or production acceptance.',
}
progress = output / 'native-keyframes-progress.json'
for q in phases:
    original, _, _, _, _ = sample(q)
    posed, offset = candidate.sample(original, q, control['target'])
    variants = [('candidate', posed, 'after_matrices')]
    if not .125 <= q <= .625:
        variants.insert(0, ('hinge-control', original, 'before_matrices'))
    for variant, pose, matrix_key in variants:
        apply(pose)
        env['blink'](0.)
        error = max(control['matrix_error'](Matrix(dense[q][matrix_key][bone.name]), bone.matrix)
                    for bone in rig.pose.bones)
        assert error < 1e-5, (q, variant, error)
        for modifier in env['skin']:
            modifier.show_viewport = True
        bpy.context.view_layer.update()
        key = f'{variant}-q{round(q * 1000000):06}'
        png = output / (key + '.png')
        mask = output / ('mask-' + key + '-0001.png')
        scene.render.filepath = str(png)
        env['mask'].base_path = str(output)
        env['mask'].file_slots[0].path = 'mask-' + key + '-'
        scene.frame_current = 1
        bpy.ops.render.render(write_still=True)
        files = []
        for path in (png, mask):
            with path.open('rb') as handle:
                os.fsync(handle.fileno())
            data = path.read_bytes()
            assert data[:8] == b'\x89PNG\r\n\x1a\n'
            assert int.from_bytes(data[16:20], 'big') == 200
            assert int.from_bytes(data[20:24], 'big') == 200
            files.append({'path': path.name, 'bytes': len(data),
                          'sha256': hashlib.sha256(data).hexdigest()})
        report['frames'].append({'phase': q, 'variant': variant,
                                 'actual_rig_reference_error': error,
                                 'native': control['native'].frame_metadata(pose, control['ground']),
                                 'files': files})
        progress.write_text(json.dumps(report, indent=2) + '\n')
        print('RETURN_NATIVE_KEYFRAME', variant, q, flush=True)
assert len(report['frames']) == 26
original, _, _, _, _ = sample(.8125)
apply(original)
restore_error = max(control['matrix_error'](before[n], rig.pose.bones[n].matrix) for n in before)
assert restore_error < 1e-5
report['original_recovery_restore_matrix_error'] = restore_error
report['complete'] = True
pending = output / 'native-keyframes-final.json.pending'
final = output / 'native-keyframes-final.json'
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
print('RETURN_NATIVE_KEYFRAMES_FINAL_SHA256', hashlib.sha256(data).hexdigest(), len(data), flush=True)
