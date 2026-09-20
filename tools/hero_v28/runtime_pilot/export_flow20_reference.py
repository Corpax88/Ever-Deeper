"""Export actual approved Flow20 bone matrices for a bounded renderer comparison.

This does not implement runtime transitions. The released support hand is copied
from the custom native applier, never forced back onto the tool by the old solver.
"""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import sys

import bpy

ROOT = Path(__file__).resolve().parents[3]
p = argparse.ArgumentParser()
p.add_argument('--native-tools', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
args = p.parse_args(sys.argv[sys.argv.index('--')+1:])
original = json.loads((args.output/'motion.json').read_text())
assert not (args.output/'motion-before-flow20.json').exists()
sys.argv = ['blender','--','--native-tools',str(args.native_tools),
    '--output',str(args.output/'flow20-native-check'),'--check-only','--continuous-return']
base = runpy.run_path(str(ROOT/'tools/native_motion_ingame_pilot/studies/overhead_swing_18/render_preview.py'))
rig, scene, motion = [base[k] for k in ('rig','scene','motion')]
from simple_swing import phase
rows = []
for cell in range(50):
    pose = motion.sample('mine', phase(cell/50.))
    base['apply'](pose)
    rows.append({'phase':cell/50.,'bones':{b.name:[list(r) for r in b.matrix]
        for b in rig.pose.bones}})
rest = {b.name:[list(r) for r in b.matrix_local] for b in rig.data.bones}
rest_error = max(abs(rest[n][i][j]-original['rest'][n][i][j])
    for n in rest for i in range(4) for j in range(4))
assert rest_error < 1e-6, ('Native bind changed', rest_error)
data = dict(original)
data.update(direction='up', action='approved_flow20_reference', reference_only=True,
    camera={'world_matrix':[list(r) for r in scene.camera.matrix_world],
            'ortho_size':scene.camera.data.ortho_scale},
    samples={'idle':[dict(rows[0],phase=0.)], 'mine':rows},
    reference_poses=[{'state':'mine','phase':i/50.,'native_cell':i} for i in (0,12,17,21,35)],
    lights=[{'name':o.name,'position':list(o.matrix_world.translation),
             'color':list(o.data.color),'energy':o.data.energy} for o in scene.objects if o.type=='LIGHT'],
    rest_error=rest_error, approved=False,
    limits='Five-pose render comparison only. Idle is the Flow20 start pose for initialization; no gameplay controller.',
    exporter_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
(args.output/'motion-before-flow20.json').write_text(json.dumps(original,separators=(',',':'))+'\n')
(args.output/'motion.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
print('FLOW20_RUNTIME_REFERENCE_EXPORTED',len(rows),flush=True)
