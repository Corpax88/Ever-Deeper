"""Rebuild the bounded Worn/up bank with one complete mining return.

Reconstruct every old and new pose, including entry, cancellation and an
interrupted stop. Reuse original PNG bytes only when all actual bone matrices
are identical. Preflight the real rig before rendering any changed cells.
This bank is diagnostic; earlier bank approvals do not transfer to new poses.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import os
import runpy
import shutil
import subprocess
import sys
import traceback
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser(description=__doc__)
for name in ('native-tools', 'pivot-report', 'reference-manifest', 'return-proof', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert not args.output.exists(), 'Use a fresh output directory'
args.output.mkdir(parents=True)
stage, current_cell = 'bindings', None
report = {'complete': False, 'passed_geometry': False, 'rendered': False,
          'visual_accepted': False, 'production_accepted': False,
          'transitions': {}, 'frame_checks': [], 'reused_frames': [], 'rendered_frames': []}

def apply(pose):
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(pose)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    return {b.name: b.matrix.copy() for b in rig.pose.bones}


def difference(a, b, names=None):
    return max(abs(a[n][i][j] - b[n][i][j]) for n in (names or a) for i in range(4) for j in range(4))


def measure(pose, matrices):
    grip = max((((matrices['hand.' + s] @ rig.data.bones['hand.' + s].matrix_local.inverted())
                 @ env['rest']['grips'][s]) - pose['grips'][s]).length for s in native.SIDES)
    length = max(abs((rig.pose.bones[n].tail - rig.pose.bones[n].head).length - rig.data.bones[n].length) for n in arm_bones)
    reach = max((c-a).length for a, b, c in pose['arms'].values())
    assert grip < 1e-5 and length < 1e-5 and reach < .71 - 1e-5, (grip, length, reach)
    return {'grip_error': grip, 'arm_length_error': length, 'maximum_arm_reach': reach,
            'arm_joints': {s: [list(v) for v in chain] for s, chain in pose['arms'].items()}}


def make_clips(provider):
    clips = {}
    for name, meta in reference['directions']['up']['transitions'].items():
        if name == 'mine_to_idle-523810':
            clips[name] = ShownPoseCancelTransition(provider, meta['source_phase'])
        elif meta.get('source_is_bridge', False):
            clips[name] = InterruptedReturnTransition(provider, clips[meta['source_state']], meta['source_state'], meta['source_phase'])
        else:
            clips[name] = provider.transition(meta['source_state'], meta['source_phase'], meta['target_state'])
    return clips


def save(path, value):
    with path.open('w') as f:
        json.dump(value, f, indent=2); f.write('\n'); f.flush(); os.fsync(f.fileno())


try:
    assert sha(args.reference_manifest) == 'e9ff20b5b2f87b84f1c0795c8d08ee839123352372fd0c933ec023c269ae42d2'
    assert sha(args.return_proof) == 'bac4a84bc61db02de2b862be3ae9493ce7c95872dc302c105495e43b9297dc80'
    reference = json.loads(args.reference_manifest.read_text())
    proof = json.loads(args.return_proof.read_text())
    assert reference['rendered'] and len(reference['frames']) == 218
    assert proof['complete'] and proof['passed_geometry'] and proof['rendered']
    assert not proof['visual_accepted'] and not proof['production_accepted']
    sources = dict(reference['render_provenance']['source_hashes'])
    for relative, digest in proof['source_hashes'].items():
        assert relative not in sources or sources[relative] == digest, relative
        sources[relative] = digest
    sources[str(Path(__file__).relative_to(ROOT))] = sha(Path(__file__))
    for relative, digest in sources.items():
        assert sha(ROOT / relative) == digest, relative
    assert sha(args.pivot_report) == reference['render_provenance']['pivot_report_sha256']
    surface = json.loads((HERE / 'working-surface-selection.json').read_text())
    hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
    pivot = json.loads(args.pivot_report.read_text())
    assert sha(Path(bpy.data.filepath)) == surface['model_sha256'] == proof['model_sha256']
    assert sha(args.native_tools / 'worn/hero.blend') == surface['gear_sha256'] == proof['gear_sha256']
    stage = 'scene-setup'
    sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
                '--output', str(args.output / 'scene-setup'), '--gear', 'worn',
                '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
                '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
    env = runpy.run_path(str(ROOT / 'tools/hero_v28/export_hero.py'))
    sys.path.insert(0, str(HERE))
    from cross_shoulder_load_motion import CrossShoulderLoadMotion
    from interrupted_return_motion import InterruptedReturnTransition
    from complete_return_motion import CompleteReturnMotion
    from shown_pose_cancel_transition import ShownPoseCancelTransition
    from hero_expression_v7 import blink_at
    import native_motion as native
    import premium_motion as pm

    control = CrossShoulderLoadMotion(surface, hinge, pivot)
    motion = CompleteReturnMotion(surface, hinge, pivot)
    env['view']('up', (6, 6))
    scene, rig = env['s'], env['r']
    assert env['m']['directions']['up']['ground_anchor'] == reference['directions']['up']['ground_anchor']
    assert scene.render.resolution_x == scene.render.resolution_y == 200 and scene.cycles.samples == 8
    out = args.output / 'worn'
    out.mkdir()
    protected = ('root', 'hips', 'body', 'head', 'thigh.R', 'shin.R', 'foot.R', 'thigh.L', 'shin.L', 'foot.L')
    arm_bones = ('upper.R', 'lower.R', 'upper.L', 'lower.L')

    report.update(source_sha=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                  source_tree=subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=ROOT, text=True).strip(),
                  source_hashes=sources, reference_sha256=sha(args.reference_manifest),
                  return_proof_sha256=sha(args.return_proof), selection=motion.selection(),
                  model_sha256=surface['model_sha256'], gear_sha256=surface['gear_sha256'],
                  scope='Bounded Worn/up full-return study; exact original rig, clocks and C0 held-source late cancel. No production acceptance.')
    stage = 'transition-preflight'
    clips, old_clips = make_clips(motion), make_clips(control)
    for name, clip in clips.items():
        current_cell = name
        meta = clip.metadata()
        zero = world_to_camera_view(scene, env['c'], Vector())
        shifted = world_to_camera_view(scene, env['c'], clip.destination_offset)
        meta['destination_offset_pixels'] = [(shifted.x-zero.x)*160, -(shifted.y-zero.y)*160]
        assert meta == reference['directions']['up']['transitions'][name], ('Timing/root metadata changed', name)
        rows = []
        report['transitions'][name] = {'metadata': meta, 'samples': rows}
        for k in range(73):
            elapsed = clip.duration * k / 72
            current_cell = [name, k, elapsed]
            old = apply(old_clips[name].sample(elapsed))
            pose = clip.sample(elapsed)
            matrices = apply(pose)
            row = {'elapsed': elapsed, **measure(pose, matrices),
                   'protected_matrix_error': difference(old, matrices, protected)}
            assert row['protected_matrix_error'] < 1e-5, (name, row)
            if k in (0, 72):
                expected = (clip.source if k == 0 else pm.translate_pose(
                    motion.sample(clip.target_state, meta['destination_phase']), clip.destination_offset))
                row['endpoint_matrix_error'] = difference(matrices, apply(expected))
                assert row['endpoint_matrix_error'] < 1e-5, (name, row)
            rows.append(row)

    stage = 'cell-preflight'
    poses = {}
    for frame in reference['frames']:
        state, phase = frame['state'], frame['phase']
        current_cell = [state, frame['index'], phase]
        old_pose = old_clips[state].sample(phase * old_clips[state].duration) if state in clips else control.sample(state, phase)
        pose = clips[state].sample(phase * clips[state].duration) if state in clips else motion.sample(state, phase)
        old = apply(old_pose)
        matrices = apply(pose)
        row = {'state': state, 'phase': phase, 'index': frame['index'], **measure(pose, matrices),
               'control_matrices': {n: [list(r) for r in m] for n, m in old.items()},
               'candidate_matrices': {n: [list(r) for r in m] for n, m in matrices.items()},
               'all_bone_difference': difference(old, matrices),
               'protected_matrix_error': difference(old, matrices, protected),
               'tool_skin_matrix': [list(r) for r in matrices['tool'] @ rig.data.bones['tool'].matrix_local.inverted()]}
        assert row['protected_matrix_error'] < 1e-5, row
        row['reuse_original_bytes'] = row['all_bone_difference'] == 0.
        poses[(state, frame['index'])] = pose
        report['frame_checks'].append(row)
    report['passed_geometry'] = True
    save(args.output / 'complete-return-bank-progress.json', report)
    m = copy.deepcopy(reference)
    m.update(rendered=False, frames=[], max_grip_error=max(r['grip_error'] for r in report['frame_checks']))
    m.setdefault('historical_reference_extensions', {}).update(
        {k: m.pop(k) for k in ('cross_shoulder_rebuild', 'shown_pose_cancel_extension') if k in m})
    m['render_provenance'] = {'base_git_head': report['source_sha'], 'source_tree': report['source_tree'],
        'source_hashes': sources, 'model_sha256': surface['model_sha256'], 'gear_sha256': surface['gear_sha256'],
        'pivot_report_sha256': sha(args.pivot_report), 'reference_sha256': sha(args.reference_manifest),
        'return_proof_sha256': sha(args.return_proof)}
    m['render_fingerprint'] = hashlib.sha256((sha(args.reference_manifest) + sha(Path(__file__)) + sha(args.return_proof)).encode()).hexdigest()
    m['motion'].update(full_input_coverage=False, production_approved=False, mining_bank='Same 52 clock samples; complete rest-to-rest return, frozen .40-.625 load/contact/hold')
    stage = 'render-changed-cells'
    for prior, check in zip(reference['frames'], report['frame_checks']):
        state, phase, index = prior['state'], prior['phase'], prior['index']
        current_cell = [state, index, phase]
        pose = poses[(state, index)]
        frame = copy.deepcopy(prior)
        if check['reuse_original_bytes']:
            for key, digest in (('path', 'png_sha256'), ('mask', 'mask_sha256')):
                source = args.reference_manifest.parent / prior[key]
                assert sha(source) == prior[digest], source
                shutil.copyfile(source, out / source.name)
            report['reused_frames'].append({'state': state, 'phase': phase, 'index': index, 'png_sha256': frame['png_sha256']})
        else:
            apply(pose)
            env['blink'](max(blink_at(phase*3.6, .40), blink_at(phase*3.6, 3.13)) if state == 'idle' else 0.)
            for modifier in env['skin']:
                modifier.show_viewport = True
            bpy.context.view_layer.update()
            key = f'up-complete-return-{state}-{index:03}'
            png, mask = out / (key + '.png'), out / ('mask-' + key + '-0001.png')
            scene.render.filepath = str(png)
            env['mask'].base_path = str(out)
            env['mask'].file_slots[0].path = 'mask-' + key + '-'
            scene.frame_current = 1
            bpy.ops.render.render(write_still=True)
            frame.update(path=png.name, mask=mask.name, png_sha256=sha(png), mask_sha256=sha(mask),
                         native=native.frame_metadata(pose, motion.ground), contacts=pose['contacts'],
                         ground_root_pixels=pose.get('transition_metadata', {}).get('target_root_pixels', 0.))
            report['rendered_frames'].append({'state': state, 'phase': phase, 'index': index, 'png_sha256': frame['png_sha256']})
        m['frames'].append(frame)
        save(out / 'render-progress.json', m)
        print('COMPLETE_RETURN_BANK_FRAME', state, index, 'reused' if check['reuse_original_bytes'] else 'rendered', flush=True)
    assert len(m['frames']) == 218
    stage, current_cell = 'final-binding', None
    for relative, digest in sources.items():
        assert sha(ROOT / relative) == digest, relative
    for frame in m['frames']:
        for key, digest in (('path', 'png_sha256'), ('mask', 'mask_sha256')):
            path = out / frame[key]
            assert sha(path) == frame[digest], path
            with path.open('rb') as f:
                os.fsync(f.fileno())
    report.update(complete=True, rendered=True)
    save(args.output / 'complete-return-bank-final.json', report)
    m['complete_return_rebuild'] = {'result_sha256': sha(args.output / 'complete-return-bank-final.json'),
        'reused_count': len(report['reused_frames']), 'rendered_count': len(report['rendered_frames']),
        'visual_accepted': False, 'production_accepted': False}
    m['rendered'] = True
    save(out / 'pilot-manifest.json', m)
    print('COMPLETE_RETURN_BANK_COMPLETE', len(m['frames']), len(report['rendered_frames']), sha(out / 'pilot-manifest.json'), flush=True)
except Exception as error:
    report.update(complete=False, rejected=True, failure_stage=stage, failure_cell=current_cell,
                  failure=str(error), traceback=traceback.format_exc())
    save(args.output / 'complete-return-bank-rejected.json', report)
    raise
