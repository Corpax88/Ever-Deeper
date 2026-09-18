"""Extend the reviewed Worn/up bank with native rest and stop/start clips.

Reuse every prior render byte. Only the original idle timeline, exact new
endpoints and five explicitly named clips are rendered. No production assets,
model, camera, mining pose, mechanical clock or existing bridge are changed.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import math
import os
import runpy
import shutil
import subprocess
import sys
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser()
for name in ('native-tools', 'pivot-report', 'reference-manifest', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert not args.output.exists(), 'Use a fresh output directory'
reference = json.loads(args.reference_manifest.read_text())
assert sha(args.reference_manifest) == '98aef75d77e95a03d5cd13b2493f8c7f37dc83681ea2df8182de20871b6bcc91'
assert reference['rendered'] and len(reference['frames']) == 92
assert sha(args.pivot_report) == reference['render_provenance']['pivot_report_sha256']
for relative, digest in reference['render_provenance']['source_hashes'].items():
    assert sha(ROOT / relative) == digest, relative
surface = json.loads((HERE / 'working-surface-selection.json').read_text())
hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
pivot = json.loads(args.pivot_report.read_text())
assert sha(Path(bpy.data.filepath)) == surface['model_sha256']
assert sha(args.native_tools / 'worn/hero.blend') == surface['gear_sha256']
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--output', str(args.output / 'scene-setup'), '--gear', 'worn',
            '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT / 'tools/hero_v28/export_hero.py'))
sys.path.insert(0, str(HERE))
from return_tool_offset_motion import FrozenReturnMotion
from hero_expression_v7 import blink_at
import native_motion as native
import premium_motion as pm

motion = FrozenReturnMotion(surface, hinge, pivot)
env['view']('up', (6, 6))
scene, rig = env['s'], env['r']
assert env['m']['directions']['up']['ground_anchor'] == reference['directions']['up']['ground_anchor']
assert scene.render.resolution_x == scene.render.resolution_y == 200
assert scene.cycles.samples == 8
out = args.output / 'worn'
out.mkdir()
m = copy.deepcopy(reference)
m['rendered'] = False
m['frames'] = []
observer_hash = sha(Path(__file__))
m['render_fingerprint'] = hashlib.sha256((sha(args.reference_manifest) + observer_hash).encode()).hexdigest()
m['idle_extension'] = {'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
    'observer_sha256': observer_hash, 'reference_sha256': sha(args.reference_manifest),
    'reused_frames': [], 'new_frames': [], 'endpoint_matrix_errors': {},
    'scope': 'Bounded Worn/up stop, rest, restart and walk-stop; not arbitrary input coverage'}
clips = {}
for source, phase, target in [('mine', .625, 'idle'), ('walk', .625, 'idle'),
                              ('idle', 0., 'mine'), ('idle', .12 / 3.6, 'walk'),
                              ('idle', .2 / 3.6, 'walk')]:
    name = f'{source}_to_{target}-{round(phase * 1000000):06}'
    clips[name] = motion.transition(source, phase, target)
phases = {name: list(info['phases']) for name, info in m['states'].items()}
idle_times = json.loads((ROOT / 'assets/hero/dad/worn/manifest.json').read_text())['states']['idle']['times']
phases['idle'] = sorted({t / 3.6 for t in idle_times} |
                       {clip.metadata()['destination_phase'] for clip in clips.values() if clip.target_state == 'idle'})
phases['mine'] = sorted(set(phases['mine']) | {clips['idle_to_mine-000000'].metadata()['destination_phase']})
for name, clip in clips.items():
    phases[name] = sorted({0., .25, .5, .75, 1.} |
                         {(k / 60) / clip.duration for k in range(1, math.ceil(clip.duration * 60))
                          if k / 60 < clip.duration})
    meta = clip.metadata()
    zero = world_to_camera_view(scene, env['c'], Vector())
    shifted = world_to_camera_view(scene, env['c'], clip.destination_offset)
    meta['destination_offset_pixels'] = [(shifted.x - zero.x) * 160, -(shifted.y - zero.y) * 160]
    m['directions']['up']['transitions'][name] = meta
offset = 0
for name, samples in phases.items():
    info = m['states'].setdefault(name, {})
    info.update({'offset': offset, 'count': len(samples), 'phases': samples, 'loop': name in ('idle', 'walk', 'mine')})
    if name in clips:
        info['duration_source'] = 'directions.<direction>.transitions.<state>.duration'
    offset += len(samples)
assert offset < 200
m['motion'].update({'frames_per_direction': offset, 'idle_timeline': 'original 24 times plus exact native stop endpoints',
                    'idle_cycle_seconds': 3.6, 'full_input_coverage': False, 'production_approved': False})


def apply(pose):
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(pose)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}


for name, clip in clips.items():
    errors = []
    for elapsed in (0., clip.duration):
        actual = apply(clip.sample(elapsed))
        expected_pose = (motion.sample(clip.source_state, clip.source_phase) if elapsed == 0. else
                         pm.translate_pose(motion.sample(clip.target_state, clip.metadata()['destination_phase']), clip.destination_offset))
        expected = apply(expected_pose)
        error = max(abs(actual[n][i][j] - expected[n][i][j]) for n in actual for i in range(4) for j in range(4))
        errors.append(error)
        assert error < 1e-5, (name, elapsed, error)
    m['idle_extension']['endpoint_matrix_errors'][name] = errors

for state, samples in phases.items():
    for index, phase in enumerate(samples):
        prior = [f for f in reference['frames'] if f['state'] == state and f['phase'] == phase]
        if prior:
            assert len(prior) == 1
            frame = copy.deepcopy(prior[0])
            frame['index'] = index
            for key, checksum in [('path', 'png_sha256'), ('mask', 'mask_sha256')]:
                source = args.reference_manifest.parent / frame[key]
                assert sha(source) == frame[checksum]
                shutil.copyfile(source, out / source.name)
            m['frames'].append(frame)
            m['idle_extension']['reused_frames'].append({'state': state, 'phase': phase, 'path': frame['path'], 'sha256': frame['png_sha256']})
            continue
        pose = clips[state].sample(phase * clips[state].duration) if state in clips else motion.sample(state, phase)
        matrices = apply(pose)
        error = max((((matrices['hand.' + side] @ rig.data.bones['hand.' + side].matrix_local.inverted())
                       @ env['rest']['grips'][side]) - pose['grips'][side]).length for side in native.SIDES)
        assert error < 1e-5
        m['max_grip_error'] = max(m['max_grip_error'], error)
        blink_time = phase * 3.6
        env['blink'](max(blink_at(blink_time, .40), blink_at(blink_time, 3.13)) if state == 'idle' else 0.)
        for modifier in env['skin']:
            modifier.show_viewport = True
        bpy.context.view_layer.update()
        key = f'up-rest-extension-{state}-{index:03}'
        png, mask = out / (key + '.png'), out / ('mask-' + key + '-0001.png')
        scene.render.filepath = str(png)
        env['mask'].base_path = str(out)
        env['mask'].file_slots[0].path = 'mask-' + key + '-'
        scene.frame_current = 1
        bpy.ops.render.render(write_still=True)
        seconds = phase * (clips[state].duration if state in clips else m['states'][state]['duration'])
        if state == 'mine':
            seconds = .68 * (phase / .55 * .42 if phase <= .55 else .42 + (phase - .55) / .45 * .58)
        frame = {'direction': 'up', 'state': state, 'index': index, 'phase': phase, 'time': seconds,
            'path': png.name, 'mask': mask.name, 'png_sha256': sha(png), 'mask_sha256': sha(mask),
            'native': native.frame_metadata(pose, motion.ground), 'contacts': pose['contacts'],
            'ground_root_pixels': pose.get('transition_metadata', {}).get('target_root_pixels', 0.)}
        m['frames'].append(frame)
        m['idle_extension']['new_frames'].append({'state': state, 'phase': phase, 'path': png.name, 'grip_error': error})
        (out / 'render-progress.json').write_text(json.dumps(m, indent=2) + '\n')
        print('RETURN_IDLE_FRAME', state, index, phase, flush=True)
assert len(m['idle_extension']['reused_frames']) == 92
assert len(m['frames']) == offset
for relative, digest in reference['render_provenance']['source_hashes'].items():
    assert sha(ROOT / relative) == digest
assert sha(Path(__file__)) == observer_hash
for frame in m['frames']:
    for key, checksum in [('path', 'png_sha256'), ('mask', 'mask_sha256')]:
        file = out / frame[key]
        with file.open('rb') as handle:
            os.fsync(handle.fileno())
        assert sha(file) == frame[checksum]
m['rendered'] = True
with (out / 'pilot-manifest.json').open('w') as file:
    file.write(json.dumps(m, indent=2) + '\n')
    file.flush()
    os.fsync(file.fileno())
print('RETURN_IDLE_COMPLETE', offset, len(m['idle_extension']['new_frames']), sha(out / 'pilot-manifest.json'), flush=True)
