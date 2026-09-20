"""Export native task-space metadata for the isolated Flow20 motion solver.

No new images, geometry or approved reference matrices are produced or replaced.
The fifty Flow20 matrices must reproduce the retained reference exactly.
"""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
p = argparse.ArgumentParser()
p.add_argument('--native-tools', type=Path, required=True)
p.add_argument('--candidate', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
args = p.parse_args(sys.argv[sys.argv.index('--')+1:])
args.output.mkdir(parents=True, exist_ok=False)
reference = json.loads((args.candidate/'motion.json').read_text())
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools), '--output',
            str(args.output/'native-check'), '--check-only', '--continuous-return']
base = runpy.run_path(str(ROOT/'tools/native_motion_ingame_pilot/studies/overhead_swing_18/render_preview.py'))
env, rig, scene, motion = [base[k] for k in ('env', 'rig', 'scene', 'motion')]
from simple_swing import phase
import native_motion
import premium_motion

ground = env['ground_vector']('up')
samples = {}
reference_error = 0.
for mode, count in [('mine', 50), ('idle', 24), ('walk', 96)]:
    samples[mode] = []
    for i in range(count):
        at = i/count
        pose = (motion.sample('mine', phase(at)) if mode == 'mine' else
                native_motion.sample('worn', mode, at, ground, 340., direction='up'))
        (base['apply'] if mode == 'mine' else base['base_apply'])(pose)
        bones = {b.name:[list(row) for row in b.matrix] for b in rig.pose.bones}
        if mode == 'mine':
            expected = reference['samples']['mine'][i]['bones']
            error = max(abs(bones[n][r][c]-expected[n][r][c]) for n in bones for r in range(4) for c in range(4))
            reference_error = max(reference_error, error)
            assert error < 1e-6, ('Flow20 source matrices changed', i, error)
        row = dict(phase=at, bones=bones, contacts=pose['contacts'],
                   support_release=pose.get('support_release', 0.))
        samples[mode].append(row)

pose = motion.sample('mine', phase(.42))
base['apply'](pose)
cap = pose['rear']+premium_motion.tool_frame(pose['axis'],pose['tool_normal'])@motion.local_cap
tool_cap = rig.pose.bones['tool'].matrix.inverted()@cap
data = dict(schema=1, scope='isolated-native-motion-pilot', approved=False,
            reference_sha256=hashlib.sha256((args.candidate/'motion.json').read_bytes()).hexdigest(),
            exporter_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            reference_matrix_error=reference_error, samples=samples,
            tool_cap_local=list(tool_cap), reference_contact=list(cap),
            walking_heading=[list(row) for row in premium_motion.heading_matrix(ground)],
            ground_per_pixel=list(ground), stride_pixels=88.,
            flat_entry_phase=native_motion.flat_entry_phase(ground,340.),
            limits='Task metadata and actual bone matrices only; no renderer/gameplay acceptance.')
(args.output/'tasks.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
print('NATIVE_MOTION_TASKS_COMPLETE', len(samples['mine']), reference_error, flush=True)
