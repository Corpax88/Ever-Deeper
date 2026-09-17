"""Actual native entry/exit rig constraints followed by bounded image samples.

Reuse the original scene setup, compare the shared mine resolver with all 50
actual frozen loop poses, then evaluate the two canonical mining bridges.
Rendering happens only after those geometry gates. No old bridge is reused.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import runpy
import subprocess
import sys
import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser()
for name in ('native-tools', 'project', 'recorded', 'target-identity',
             'pivot-report', 'loop-result', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
git = lambda *a: subprocess.check_output(['git', *a], cwd=ROOT, text=True).strip()
assert not git('status', '--porcelain')
assert not args.output.exists(), 'Use a fresh output directory'
assert sha(args.loop_result) == 'd30fdffe5a1782dc847ebef4dfaff8af3b937069ec36dd741b9abc8c90b44770'
reference = json.loads(args.loop_result.read_text())
assert reference['complete'] and reference['rendered']
replay_path = args.loop_result.parent / 'replay/return-offset-final.json'
assert sha(replay_path) == reference['replay_final_sha256']
replay = json.loads(replay_path.read_text())
assert sha(args.pivot_report) in replay['input_reports'].values()
for name, digest in {**reference['source_hashes'], **reference['control_source_hashes']}.items():
    assert sha(HERE / name) == digest, name
surface = json.loads((HERE / 'working-surface-selection.json').read_text())
hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
pivot = json.loads(args.pivot_report.read_text())
assert sha(HERE / 'upper_body_hinge_pose.py') == hinge['pose_helper_sha256']
assert sha(HERE / 'fixed_cap_pivot_pose.py') == hinge['fixed_cap_pose_helper_sha256']
args.output.mkdir(parents=True)
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--project', str(args.project), '--recorded', str(args.recorded),
            '--target-identity', str(args.target_identity),
            '--output', str(args.output / 'scene-load'), '--setup-only']
mapped = runpy.run_path(str(HERE / 'map_up_contact.py'))
sys.path.insert(0, str(HERE))
from return_tool_offset_motion import FrozenReturnMotion
import native_motion as native
import premium_motion as pm
import review_native_continuity as continuity

env = mapped['env']
rig, rest, scene = env['r'], env['rest'], env['s']
motion = FrozenReturnMotion(surface, hinge, pivot)
assert list(motion.target) == replay['target_ground']
assert mapped['loaded']['report']['model_sha256'] == reference['model_sha256']
assert mapped['loaded']['report']['gear_sha256'] == reference['gear_sha256']
assert scene.render.resolution_x == scene.render.resolution_y == 200
assert scene.render.resolution_percentage == 100 and scene.render.film_transparent
matrix_error = lambda a, b: max(abs(a[i][j] - b[i][j]) for i in range(4) for j in range(4))
rows = lambda m: [list(v) for v in m]


def apply(p):
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(p)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}


def measure(p):
    matrices = apply(p)
    grip_error = max((((matrices['hand.' + s] @ rig.data.bones['hand.' + s].matrix_local.inverted())
                       @ rest['grips'][s]) - p['grips'][s]).length for s in native.SIDES)
    arm_names = ('upper.R', 'lower.R', 'upper.L', 'lower.L')
    length_error = max(abs((rig.pose.bones[n].tail - rig.pose.bones[n].head).length
                           - rig.data.bones[n].length) for n in arm_names)
    reach = max((end - start).length for start, _, end in p['arms'].values())
    return matrices, {'grip_error': grip_error, 'arm_length_error': length_error,
                      'maximum_arm_reach': reach}


report = {'complete': False, 'rendered': False, 'gameplay_capture': False,
          'motion_accepted': False, 'production_accepted': False,
          'executed_source_sha': git('rev-parse', 'HEAD'), 'source_tree': git('rev-parse', 'HEAD^{tree}'),
          'source_hashes': {str(p.relative_to(ROOT)): sha(p) for p in
              [Path(__file__), HERE / 'return_tool_offset_motion.py', HERE / 'return_tool_offset_pose.py',
               HERE / 'upper_body_hinge_pose.py', HERE / 'fixed_cap_pivot_pose.py',
               HERE / 'working_surface_arc.py', HERE / 'working-surface-selection.json',
               HERE / 'upper-body-hinge-selection.json', Path(native.__file__), Path(pm.__file__)]},
          'input_hashes': {str(p): sha(p) for p in
              (args.recorded, args.target_identity, args.pivot_report, args.loop_result)},
          'model_sha256': reference['model_sha256'], 'gear_sha256': reference['gear_sha256'],
          'scope': 'Two canonical mining bridges only, walk .625 to mine and mine .625 to walk. '
                   'Original clock, feet, blend and root math. No idle stop, arbitrary interrupt, '
                   'canonical frame-bank quantization or ordinary-input gameplay acceptance.',
          'frozen_loop_matrix_errors': [], 'bridges': [], 'frames': []}
progress = args.output / 'transitions-progress.json'


def save_progress():
    progress.write_text(json.dumps(report, indent=2) + '\n')


# This verifies the new shared resolver against observed poses, without
# repeating the already closed full-scene visibility experiment.
for row in reference['samples']:
    matrices = apply(motion.sample('mine', row['native_phase']))
    error = max(matrix_error(matrices[n], Matrix(row['after_matrices'][n])) for n in matrices)
    assert error < 1e-5, (row['index'], error)
    report['frozen_loop_matrix_errors'].append(error)

clips = []
protected = ('root', 'hips', 'thigh.R', 'shin.R', 'foot.R', 'thigh.L', 'shin.L', 'foot.L')
for source, target in (('walk', 'mine'), ('mine', 'walk')):
    clip = motion.transition(source, .625, target)
    old = native.Transition('worn', source, .625, target, tuple(motion.ground), direction='up')
    assert clip.metadata() == old.metadata(), 'Unchanged clock/root/support contract'
    label = source + '-to-' + target
    info = {'name': label, 'metadata': clip.metadata(), 'samples': [], 'endpoint_errors': {}}
    clips.append((label, clip, info))
    for i in range(65):
        seconds = clip.duration * i / 64
        p = clip.sample(seconds)
        before = apply(old.sample(seconds))
        matrices, metrics = measure(p)
        metrics['old_lower_body_matrix_error'] = max(matrix_error(before[n], matrices[n]) for n in protected)
        assert max(metrics['grip_error'], metrics['arm_length_error'], metrics['old_lower_body_matrix_error']) < 1e-5
        assert metrics['maximum_arm_reach'] < .71, (label, i, metrics)
        info['samples'].append({'time_seconds': seconds, 'u': i / 64, **metrics,
                                'matrices': {n: rows(m) for n, m in matrices.items()},
                                'feet': native.frame_metadata(p, motion.ground)['feet']})
    start = apply(motion.sample(source, .625))
    end_phase = clip.phase_at(target, clip.target_phase, clip.duration)
    end = apply(pm.translate_pose(motion.sample(target, end_phase), clip.destination_offset))
    for key, expected, observed in (('start', start, info['samples'][0]), ('end', end, info['samples'][-1])):
        info['endpoint_errors'][key] = max(matrix_error(expected[n], Matrix(observed['matrices'][n])) for n in expected)
    assert max(info['endpoint_errors'].values()) < 1e-5
    # Second-order endpoint velocities use the same existing continuity
    # observer and world-root convention as the native motion owner.
    eps = .0001
    source_v = motion.ground * (340. if source == 'walk' else 0.)
    target_v = motion.ground * (340. if target == 'walk' else 0.)
    start_p, end_p = clip.sample(0.), clip.sample(clip.duration)
    before = [pm.translate_pose(motion.sample(source, clip.phase_at(source, .625, -k * eps)), -source_v * (k * eps)) for k in (1, 2)]
    following = [pm.translate_pose(clip.sample(k * eps), target_v * (k * eps)) for k in (1, 2)]
    previous = [pm.translate_pose(clip.sample(clip.duration - k * eps), -target_v * (k * eps)) for k in (1, 2)]
    after = [pm.translate_pose(motion.sample(target, clip.phase_at(target, clip.target_phase, clip.duration + k * eps)), clip.destination_offset + target_v * (k * eps)) for k in (1, 2)]
    velocities = {}
    for key, a, b in (('start', continuity.endpoint_velocity(start_p, *before, eps, True), continuity.endpoint_velocity(start_p, *following, eps)),
                      ('end', continuity.endpoint_velocity(end_p, *previous, eps, True), continuity.endpoint_velocity(end_p, *after, eps))):
        errors = {n: (a[n] - b[n]).length for n in a}
        velocities[key] = {'max_error': max(errors.values()), 'point': max(errors, key=errors.get), 'all_errors': errors}
    info['world_endpoint_velocity'] = velocities
    info['velocity_epsilon_seconds'] = eps
    assert max(v['max_error'] for v in velocities.values()) < .1, (label, velocities)
    report['bridges'].append(info)
    save_progress()
print('RETURN_TRANSITIONS_RIG_PASS', len(clips), 130, flush=True)

# Render exact bridge fractions plus actual 60 Hz time samples immediately
# before and after. These are local native cells; gameplay root movement is
# recorded, not pretended to be an observed in-game frame.
for label, clip, info in clips:
    times = sorted(set([-1 / 60, 0., *[clip.duration * i / 4 for i in range(1, 5)],
                        *[i / 60 for i in range(1, int(clip.duration * 60) + 3)]]))
    for index, seconds in enumerate(times):
        if seconds < 0.:
            state, phase = clip.source_state, clip.phase_at(clip.source_state, .625, seconds)
            p = motion.sample(state, phase)
            placement = motion.ground * (clip.speed * seconds if state == 'walk' else 0.)
        elif seconds <= clip.duration:
            state, phase, p = 'bridge', seconds / clip.duration, clip.sample(seconds)
            placement = motion.ground * (clip.speed * seconds if clip.target_state == 'walk' else 0.)
        else:
            state = clip.target_state
            phase = clip.phase_at(state, clip.target_phase, seconds)
            p = pm.translate_pose(motion.sample(state, phase), clip.destination_offset)
            placement = motion.ground * (clip.speed * seconds if state == 'walk' else 0.)
        matrices, metrics = measure(p)
        assert max(metrics['grip_error'], metrics['arm_length_error']) < 1e-5 and metrics['maximum_arm_reach'] < .71
        env['blink'](0.)
        for modifier in env['skin']:
            modifier.show_viewport = True
        bpy.context.view_layer.update()
        render_error = max(matrix_error(matrices[n], rig.pose.bones[n].matrix) for n in matrices)
        assert render_error < 1e-5
        key = f'{label}-{index:02}'
        paths = [args.output / (key + '.png'), args.output / ('mask-' + key + '-0001.png')]
        scene.render.filepath = str(paths[0])
        env['mask'].base_path = str(args.output)
        env['mask'].file_slots[0].path = 'mask-' + key + '-'
        scene.frame_current = 1
        bpy.ops.render.render(write_still=True)
        files = []
        for path in paths:
            with path.open('rb') as handle:
                os.fsync(handle.fileno())
            data = path.read_bytes()
            assert data[:8] == b'\x89PNG\r\n\x1a\n' and [int.from_bytes(data[i:i + 4], 'big') for i in (16, 20)] == [200, 200]
            files.append({'path': path.name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
        report['frames'].append({'bridge': label, 'index': index, 'seconds': seconds,
                                 'state': state, 'phase': phase, 'world_root_native': list(placement),
                                 'actual_render_matrix_error': render_error,
                                 'metrics': metrics, 'matrices': {n: rows(m) for n, m in matrices.items()}, 'files': files})
        save_progress()
        print('RETURN_TRANSITIONS_FRAME', label, index, seconds, state, phase, flush=True)
report['rendered'] = True
report['complete'] = True
pending = args.output / 'transitions-final.json.pending'
final = args.output / 'transitions-final.json'
data = (json.dumps(report, indent=2) + '\n').encode()
with pending.open('xb') as handle:
    handle.write(data)
    handle.flush()
    os.fsync(handle.fileno())
os.replace(pending, final)
fd = os.open(args.output, os.O_RDONLY)
try:
    os.fsync(fd)
finally:
    os.close(fd)
print('RETURN_TRANSITIONS_FINAL_SHA256', sha(final), len(data), flush=True)
