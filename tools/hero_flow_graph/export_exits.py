"""Immediate native take-off from every approved displayed mining frame.

Moving feet leave the ground during the short transfer. No stationary recovery
is dragged along with a moving gameplay root. Edges are reversible finite paths.
"""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--native-tools', type=Path, required=True)
p.add_argument('--baseline-root', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--render', action='store_true')
p.add_argument('--approved-flow', type=Path, required=True)
args = p.parse_args(sys.argv[sys.argv.index('--')+1:])
args.output.mkdir(parents=True, exist_ok=False)
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--baseline-root', str(args.baseline_root), '--output', str(args.output/'adapter')]
a = runpy.run_path(str(ROOT/'tools/native_motion_ingame_pilot/studies/transitions_21/render_edges.py'))
env, scene = a['env'], a['scene']
steps = 12
duration = .18
distance = duration*340.
assert hashlib.sha256((args.approved_flow/'atlas.png').read_bytes()).hexdigest() == '6a869dc427d9d0e66c2582f02be9c6719842e8878dc88af7426d4dc1da70fca1'
source = a['legacy_pose']('up', 'walk', .2)
ma = a['apply_family'](source, 'legacy')
cases = []
report = dict(complete=False, anchor=a['report']['anchor'], edges={}, renders=[], temporal={}, geometry={},
              speed=340., distance_pixels=distance, duration=duration, failures=[], production_accepted=False,
              source_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())

def save():
    (args.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')

def pose_at(target, mb, u):
    reverse = 1.-u
    w = a['pm'].smooth(reverse)
    pose = a['mix'](source, target, w, reverse, step_crouch=.025, airborne=True)
    check = a['install'](pose, source, target, ma, mb, w)
    return w, check

for cell in range(50):
    name = f'exit{cell:02d}'
    target = a['motion'].sample('mine', a['phase'](cell/50.))
    mb = a['apply_family'](target, 'flow20')
    report['edges'][name] = dict(source_cell=cell, target_walk_cell=12, steps=steps,
                               duration=duration, distance_pixels=distance)
    try:
        rows = []
        for i in range(41):
            u = i/40.
            _, check = pose_at(target, mb, u)
            if i in (0, 40):
                check['endpoint_matrix_error'] = a['difference'](a['matrices'](), mb if i == 0 else ma)
                assert check['endpoint_matrix_error'] < 1e-5
            rows.append(dict(seconds=u*duration, **check))
        report['geometry'][name] = rows
        report['temporal'][name] = a['temporal'](rows)
        peak = max(v['degrees_per_second'] for v in report['temporal'][name].values())
        assert peak < 3600, ('rotation spike', peak)
        cases.append((name, target, mb))
    except Exception as exc:
        report['failures'].append(dict(edge=name, error=str(exc)))
    save()
assert not report['failures'], report['failures']
if args.render:
    for name, target, mb in cases:
        for i in range(steps+1):
            u = i/steps
            w, check = pose_at(target, mb, u)
            for light, matrix in a['lighting'](source, 'legacy').items():
                scene.objects[light].matrix_world = a['blend_matrix'](matrix, a['lighting'](target, 'flow20')[light], w)
            for modifier in env['skin']: modifier.show_viewport = True
            env['blink'](0.)
            bpy.context.view_layer.update()
            filename = f'{name}-{i:03d}'
            scene.render.filepath = str(args.output/(filename+'.png'))
            env['mask'].base_path = str(args.output)
            env['mask'].file_slots[0].path = 'mask-'+filename+'-'
            scene.frame_current = 1
            if i == 0:
                source_file = args.approved_flow/f'frame-{int(name[-2:]):04d}.png'
                source_mask = next(args.approved_flow.glob('mask-'+source_file.stem+'-*.png'))
                shutil.copyfile(source_file, args.output/(filename+'.png'))
                shutil.copyfile(source_mask, args.output/('mask-'+filename+'-0001.png'))
            elif i == steps and name != 'exit00':
                shutil.copyfile(args.output/f'exit00-{steps:03d}.png', args.output/(filename+'.png'))
                shutil.copyfile(args.output/f'mask-exit00-{steps:03d}-0001.png', args.output/('mask-'+filename+'-0001.png'))
            else:
                bpy.ops.render.render(write_still=True)
            report['renders'].append(dict(edge=name, step=i, file=filename+'.png', **check))
        save()
report['complete'] = True
save()
print('FLOW_GRAPH_EXITS_COMPLETE', len(report['renders']), flush=True)
