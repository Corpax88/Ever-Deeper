"""Render the frozen Worn/up motion into one explicit gameplay trial bank.

Canonical poses contain no transition destination offset. Original scene,
camera, materials, rig and packing are retained. This is one target-bound
trial, not a production or arbitrary-input approval.
"""
from pathlib import Path
from types import SimpleNamespace
import argparse
import hashlib
import json
import math
import os
import runpy
import subprocess
import sys

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser()
for name in ('native-tools', 'pivot-report', 'loop-result', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert not args.output.exists(), 'Use a fresh render directory'
surface = json.loads((HERE / 'working-surface-selection.json').read_text())
hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
pivot = json.loads(args.pivot_report.read_text())
assert sha(Path(bpy.data.filepath)) == surface['model_sha256']
assert sha(args.native_tools / 'worn/hero.blend') == surface['gear_sha256']
assert sha(args.loop_result) == 'd30fdffe5a1782dc847ebef4dfaff8af3b937069ec36dd741b9abc8c90b44770'
reference = json.loads(args.loop_result.read_text())
assert reference['complete'] and reference['rendered']
for name, digest in {**reference['source_hashes'], **reference['control_source_hashes']}.items():
    assert sha(HERE / name) == digest, name
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--output', str(args.output / 'scene-setup'), '--gear', 'worn',
            '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT / 'tools/hero_v28/export_hero.py'))
sys.path.insert(0, str(HERE))
from return_tool_offset_motion import FrozenReturnMotion
import native_motion as native

motion = FrozenReturnMotion(surface, hinge, pivot)
env['view']('up', (6, 6))
scene, rig, rest = env['s'], env['r'], env['rest']
assert (env['ground_vector']('up') - motion.ground).length < 1e-7
out = args.output / 'worn'
out.mkdir()
matrix_error = lambda a, b: max(abs(a[i][j] - b[i][j]) for i in range(4) for j in range(4))


def apply(pose):
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(pose)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}


loop_errors = []
for row in reference['samples']:
    matrices = apply(motion.sample('mine', row['native_phase']))
    error = max(matrix_error(matrices[n], Matrix(row['after_matrices'][n])) for n in matrices)
    loop_errors.append(error)
    assert error < 1e-5, ('Recovered frozen pose differs', row['index'], error)

clips = {}
for source, phase, target in [('idle', 0., 'walk'), ('walk', .625, 'mine'), ('mine', .625, 'walk')]:
    name = f'{source}_to_{target}-{round(phase * 1000000):06}'
    clips[name] = motion.transition(source, phase, target)
clock = SimpleNamespace(gear='worn', speed=340., mine_duration=.68, mine_hit_phase=.42)
mine_phases = [native.Transition.phase_at(clock, 'mine', 0., i * .68 / 50) for i in range(50)]
assert abs(mine_phases[26] - .6275862068965518) < 1e-12
mine_phases[26] = .625
mine_phases.append(clips['walk_to_mine-625000'].metadata()['destination_phase'])
phase_bank = {'idle': [0.], 'walk': sorted({i / 16 for i in range(16)} | {.4}),
              'mine': sorted(mine_phases)}
for name, clip in clips.items():
    phases = {0., .25, .5, .75, 1.}
    if 'mine' in name:
        phases |= {(k / 60) / clip.duration for k in range(1, math.ceil(clip.duration * 60))
                   if k / 60 < clip.duration}
    phase_bank[name] = sorted(phases)
assert sum(map(len, phase_bank.values())) == 92
m = env['m']
m['rendered'] = False
m['frames'] = []
m['states'] = {}
m['directions']['up']['transitions'] = {}
offset = 0
for name, phases in phase_bank.items():
    info = {'offset': offset, 'count': len(phases), 'phases': phases, 'loop': name not in clips}
    offset += len(phases)
    if name in clips:
        clip = clips[name]
        info['duration_source'] = 'directions.<direction>.transitions.<state>.duration'
        meta = clip.metadata()
        zero = world_to_camera_view(scene, env['c'], Vector())
        shifted = world_to_camera_view(scene, env['c'], clip.destination_offset)
        meta['destination_offset_pixels'] = [(shifted.x - zero.x) * 160, -(shifted.y - zero.y) * 160]
        m['directions']['up']['transitions'][name] = meta
    else:
        info['duration'] = native.state_duration(name, 340., .68)
    m['states'][name] = info
m['motion'].update({'frames_per_direction': 92, 'source_phase_bank': [0., .625],
    'canonical_pose_contains_destination_offset': False,
    'mining_bank': '50 equal clock samples; index26 replaced by .625; exact entry endpoint added',
    'mine_time_metadata': 'inverse .42 gameplay progress to .55 native phase mapping',
    'scope': 'Worn/up, seed4608, fixture entry depth1, target depth2; endless_d000002_node_006 at [1760,1568], contact [1696,1648]',
    'full_input_coverage': False, 'production_approved': False})
m['render_provenance'] = {'base_git_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
    'model_sha256': surface['model_sha256'], 'gear_sha256': surface['gear_sha256'],
    'frozen_loop_sha256': sha(args.loop_result), 'frozen_loop_matrix_errors': loop_errors,
    'pivot_report_sha256': sha(args.pivot_report),
    'source_hashes': {str(p.relative_to(ROOT)): sha(p) for p in
        sorted((ROOT / 'tools/hero_v28').glob('*.py')) + sorted(HERE.glob('*.py')) + sorted(HERE.glob('*selection.json'))}}
m['max_grip_error'] = 0.
for state, phases in phase_bank.items():
    for index, phase in enumerate(phases):
        p = clips[state].sample(phase * clips[state].duration) if state in clips else motion.sample(state, phase)
        matrices = apply(p)
        error = max((((matrices['hand.' + side] @ rig.data.bones['hand.' + side].matrix_local.inverted())
                     @ rest['grips'][side]) - p['grips'][side]).length for side in native.SIDES)
        m['max_grip_error'] = max(m['max_grip_error'], error)
        assert error < 1e-5
        env['blink'](0.)
        for modifier in env['skin']:
            modifier.show_viewport = True
        bpy.context.view_layer.update()
        key = f'up-{state}-{index:03}'
        png, mask = out / (key + '.png'), out / ('mask-' + key + '-0001.png')
        scene.render.filepath = str(png)
        env['mask'].base_path = str(out)
        env['mask'].file_slots[0].path = 'mask-' + key + '-'
        scene.frame_current = 1
        bpy.ops.render.render(write_still=True)
        for path in (png, mask):
            with path.open('rb') as file:
                os.fsync(file.fileno())
        seconds = phase * (clips[state].duration if state in clips else m['states'][state]['duration'])
        if state == 'mine':
            seconds = .68 * (phase / .55 * .42 if phase <= .55 else .42 + (phase - .55) / .45 * .58)
        m['frames'].append({'direction': 'up', 'state': state, 'index': index, 'phase': phase,
            'time': seconds, 'path': png.name, 'mask': mask.name, 'png_sha256': sha(png), 'mask_sha256': sha(mask),
            'native': native.frame_metadata(p, motion.ground), 'contacts': p['contacts'],
            'ground_root_pixels': p.get('transition_metadata', {}).get('target_root_pixels', 0.)})
        (out / 'render-progress.json').write_text(json.dumps(m, indent=2) + '\n')
        print('RETURN_BANK_FRAME', state, index, phase, flush=True)
for relative, digest in m['render_provenance']['source_hashes'].items():
    assert sha(ROOT / relative) == digest, ('Source changed during rendering', relative)
m['rendered'] = True
pending = out / 'pilot-manifest.json.pending'
with pending.open('w') as file:
    file.write(json.dumps(m, indent=2) + '\n')
    file.flush()
    os.fsync(file.fileno())
os.replace(pending, out / 'pilot-manifest.json')
print('RETURN_BANK_COMPLETE', len(m['frames']), sha(out / 'pilot-manifest.json'), flush=True)
