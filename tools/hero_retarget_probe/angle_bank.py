"""Render only cells used by one closed game route at a +25 degree view.

Untested cells are retained solely for bank layout; the capture fixture must
reject presentation of any cell outside rendered_cells. Never adopt this bank.
"""
import argparse
import copy
import hashlib
import json
import math
from pathlib import Path
import runpy
import sys
import zipfile

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--archive', type=Path, required=True)
p.add_argument('--native-tools', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args(sys.argv[sys.argv.index('--')+1:])
assert not a.output.exists()
a.output.mkdir(parents=True)
out = a.output/'worn'
out.mkdir()
sha = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
z = zipfile.ZipFile(a.archive)
raw = z.read('native-bank/complete-return-bank-final.json')
assert hashlib.sha256(raw).hexdigest() == '996ead7ae03620e4997b62f8789e2745fb591457f218172645340c1b5262c0a2'
saved = json.loads(raw)
assert sha(bpy.data.filepath) == saved['model_sha256']
assert sha(a.native_tools/'worn/hero.blend') == saved['gear_sha256']
reference = json.loads(z.read('native-bank/worn/pilot-manifest.json'))
game = json.loads(z.read('game-loop/native-ingame.json'))
assert game['passed'] and game['complete_return']
selected = {(s['visual']['state'], s['visual']['local_frame']) for s in game['samples']}
checks = {(r['state'], r['index']): r for r in saved['frame_checks']}
assert len(selected) == 76 and selected <= checks.keys()
sys.argv = ['blender', '--', '--native-tools', str(a.native_tools), '--output', str(a.output/'setup'),
            '--gear', 'worn', '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'))
scene, rig, camera = env['s'], env['r'], env['c']
env['view']('up', (6, 6))
target = Vector((0., -.10, .98))
camera.location = target+Matrix.Rotation(math.radians(25), 3, 'Z')@(camera.location-target)
camera.rotation_euler = (target-camera.location).to_track_quat('-Z', 'Y').to_euler()
bpy.context.view_layer.update()
anchor = world_to_camera_view(scene, camera, Vector())
rest = {b.name: b.matrix_local.copy() for b in rig.data.bones}
manifest = copy.deepcopy(reference)
manifest['frames'] = []
manifest['directions']['up']['ground_anchor'] = [anchor.x*200, (1-anchor.y)*200]
report = {'complete': False, 'angle_degrees': 25, 'script_sha256': sha(__file__),
          'saved_report_sha256': hashlib.sha256(raw).hexdigest(),
          'model_sha256': saved['model_sha256'], 'gear_sha256': saved['gear_sha256'],
          'rendered_cells': [], 'rendered_frames': [], 'retained_unusable_cells': [],
          'production_accepted': False, 'limits': 'One exact closed route only; unrendered cells forbidden in capture'}
for prior in reference['frames']:
    frame = copy.deepcopy(prior)
    identity = (frame['state'], frame['index'])
    cell = '%s:%d' % identity
    if identity in selected:
        row = checks[identity]
        matrices = {n: Matrix(v) for n, v in row['candidate_matrices'].items()}
        for modifier in env['skin']: modifier.show_viewport = False
        for b in rig.pose.bones:
            parent = b.parent
            b.matrix_basis = b.bone.convert_local_to_pose(matrices[b.name], rest[b.name],
                parent_matrix=matrices[parent.name] if parent else Matrix.Identity(4),
                parent_matrix_local=rest[parent.name] if parent else Matrix.Identity(4), invert=True)
        env['blink'](max(env['blink_at'](frame['phase']*3.6, .40), env['blink_at'](frame['phase']*3.6, 3.13)) if frame['state']=='idle' else 0.)
        for modifier in env['skin']: modifier.show_viewport = True
        bpy.context.view_layer.update()
        error = max(abs(b.matrix[i][j]-matrices[b.name][i][j]) for b in rig.pose.bones for i in range(4) for j in range(4))
        assert error < 1e-5
        key = 'angle-%s-%03d' % identity
        png, mask = out/(key+'.png'), out/('mask-'+key+'-0001.png')
        scene.render.filepath = str(png)
        env['mask'].base_path = str(out)
        env['mask'].file_slots[0].path = 'mask-'+key+'-'
        scene.frame_current = 1
        bpy.ops.render.render(write_still=True)
        frame.update(path=png.name, mask=mask.name, png_sha256=sha(png), mask_sha256=sha(mask))
        report['rendered_cells'].append(cell)
        report['rendered_frames'].append({'cell': cell, 'max_matrix_error': error, 'png_sha256': frame['png_sha256']})
    else:
        for key, digest in (('path','png_sha256'), ('mask','mask_sha256')):
            data = z.read('native-bank/worn/'+frame[key])
            assert hashlib.sha256(data).hexdigest() == frame[digest]
            (out/frame[key]).write_bytes(data)
        report['retained_unusable_cells'].append(cell)
    manifest['frames'].append(frame)
    (a.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')
assert len(report['rendered_cells']) == 76
report['complete'] = True
manifest['view_angle_study'] = report
manifest['motion']['full_input_coverage'] = False
manifest['render_provenance'] = {'study': 'view-angle-25', 'script_sha256': sha(__file__), 'pose_report_sha256': report['saved_report_sha256']}
(out/'pilot-manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
(a.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')
print('ANGLE_BANK_COMPLETE', len(report['rendered_cells']), flush=True)
