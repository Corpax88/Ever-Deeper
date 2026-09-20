"""Render finite, reversible native walk/rest ports for the approved Flow20 bank.

The reviewed study21 adapter owns full-bone endpoint preservation. This exporter
reuses that adapter without altering any approved loop image or source pose.
"""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--native-tools', type=Path, required=True)
p.add_argument('--baseline-root', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--render', action='store_true')
args = p.parse_args(sys.argv[sys.argv.index('--')+1:])
args.output.mkdir(parents=True, exist_ok=False)
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--baseline-root', str(args.baseline_root), '--output', str(args.output/'adapter')]
adapter = runpy.run_path(str(ROOT/'tools/native_motion_ingame_pilot/studies/transitions_21/render_edges.py'))
env, scene = adapter['env'], adapter['scene']
motion, phase = adapter['motion'], adapter['phase']
sample_legacy = adapter['legacy_pose']
apply_family, mix, install = [adapter[k] for k in ('apply_family', 'mix', 'install')]
matrices, difference, temporal = [adapter[k] for k in ('matrices', 'difference', 'temporal')]
blend_matrix, lighting = adapter['blend_matrix'], adapter['lighting']
report = dict(complete=False, approved_loop_changed=False, production_accepted=False,
              anchor=adapter['report']['anchor'], edges={}, renders=[], geometry={}, temporal={},
              source_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())

def save():
    (args.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')

try:
    target = motion.sample('mine', phase(0.))
    mb = apply_family(target, 'flow20')
    for name, state, cell in [('idle', 'idle', 0), ('walk0', 'walk', 0), ('walk24', 'walk', 24)]:
        source = sample_legacy('up', state, cell/60.)
        ma = apply_family(source, 'legacy')
        steps = 18
        duration = steps/60.
        report['edges'][name] = dict(source_state=state, source_cell=cell, source_direction='up',
                                    target_state='flow', target_cell=0, steps=steps, duration=duration)
        rows = []
        for i in range(61):
            u = i/60.
            w = adapter['pm'].smooth(u)
            pose = mix(source, target, w, u, step_crouch=.025)
            check = install(pose, source, target, ma, mb, w)
            if i in (0, 60):
                check['endpoint_matrix_error'] = difference(matrices(), ma if i == 0 else mb)
                assert check['endpoint_matrix_error'] < 1e-5
            rows.append(dict(seconds=u*duration, **check))
        report['geometry'][name] = rows
        report['temporal'][name] = temporal(rows)
        assert max(v['degrees_per_second'] for v in report['temporal'][name].values()) < 3600, name
        save()
        if not args.render:
            continue
        for i in range(steps+1):
            u = i/steps
            w = adapter['pm'].smooth(u)
            pose = mix(source, target, w, u, step_crouch=.025)
            check = install(pose, source, target, ma, mb, w)
            for light, matrix in lighting(source, 'legacy').items():
                scene.objects[light].matrix_world = blend_matrix(matrix, lighting(target, 'flow20')[light], w)
            for modifier in env['skin']:
                modifier.show_viewport = True
            env['blink'](0.)
            bpy.context.view_layer.update()
            filename = f'{name}-{i:03d}'
            scene.render.filepath = str(args.output/(filename+'.png'))
            env['mask'].base_path = str(args.output)
            env['mask'].file_slots[0].path = 'mask-'+filename+'-'
            scene.frame_current = 1
            bpy.ops.render.render(write_still=True)
            report['renders'].append(dict(edge=name, step=i, file=filename+'.png', **check))
            save()
    report['complete'] = True
    save()
    print('FLOW_GRAPH_NATIVE_COMPLETE', len(report['renders']), flush=True)
except Exception as exc:
    report['error'] = str(exc)
    save()
    raise
