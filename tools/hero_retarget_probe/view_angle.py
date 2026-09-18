"""Render saved native poses at three elevations, without reauthoring motion."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import runpy
import subprocess
import sys

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--native-tools', type=Path, required=True)
p.add_argument('--saved-poses', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--azimuth-offsets', type=float, nargs='+',
               help='Instead of the elevation trial, try these offsets at the baseline elevation')
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
assert not a.output.exists(), 'Use a fresh output directory'
a.output.mkdir(parents=True)
digest = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
saved = json.loads(a.saved_poses.read_text())
assert saved['complete'] and saved['passed_geometry'] and saved['rendered']
assert digest(bpy.data.filepath) == saved['model_sha256']
assert digest(a.native_tools/'worn/hero.blend') == saved['gear_sha256']
chosen = [min((r for r in saved['frame_checks'] if r['state'] == state),
              key=lambda r: abs(r['phase']-phase))
          for state, phase in [('idle', 0.), ('mine', .40), ('mine', .55)]]
assert all(abs(row['phase']-phase) < .017 for row, phase in zip(chosen, (0., .40, .55)))
sys.argv = ['blender', '--', '--native-tools', str(a.native_tools),
            '--output', str(a.output/'setup'), '--gear', 'worn',
            '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--direction', 'up',
            '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'))
scene, rig, camera = env['s'], env['r'], env['c']
env['view']('up', (6, 6))
rest = {b.name: b.matrix_local.copy() for b in rig.data.bones}
scene.render.resolution_x = scene.render.resolution_y = 256
scene.cycles.samples = 4
scene.render.film_transparent = True
for node in list(scene.node_tree.nodes):
    if node.type == 'OUTPUT_FILE':
        scene.node_tree.nodes.remove(node)
target = Vector((0., -.10, .98))
radius = (camera.location-target).xy.length
baseline = math.degrees(math.atan2(camera.location.z-target.z, radius))
base_delta = camera.location-target
base_azimuth = math.atan2(base_delta.y, base_delta.x)
report = {'source_sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
          'script_sha256': digest(__file__), 'saved_pose_report_sha256': digest(a.saved_poses),
          'model_sha256': saved['model_sha256'], 'gear_sha256': saved['gear_sha256'],
          'blender': bpy.app.version_string, 'frames': [], 'production_accepted': False,
          'changed': 'camera azimuth only' if a.azimuth_offsets else 'camera elevation only',
          'preserved': 'saved bone matrices, orthographic scale and lighting',
          'limits': ['isolated stills, no new game test', 'changed projection requires target/ground-anchor integration',
                     'no timing, smoothness or interruption acceptance']}
views = [(baseline, offset) for offset in a.azimuth_offsets] if a.azimuth_offsets else [(e, 0.) for e in (baseline, 45., 55.)]
for view_index, (elevation, azimuth_offset) in enumerate(views):
    angle = base_azimuth+math.radians(azimuth_offset)
    camera.location.x = target.x+radius*math.cos(angle)
    camera.location.y = target.y+radius*math.sin(angle)
    camera.location.z = target.z+radius*math.tan(math.radians(elevation))
    camera.rotation_euler = (target-camera.location).to_track_quat('-Z', 'Y').to_euler()
    for pose_index, row in enumerate(chosen):
        matrices = {name: Matrix(value) for name, value in row['candidate_matrices'].items()}
        assert set(matrices) == set(rest)
        for modifier in env['skin']:
            modifier.show_viewport = False
        for bone in rig.pose.bones:
            parent = bone.parent
            bone.matrix_basis = bone.bone.convert_local_to_pose(
                matrices[bone.name], rest[bone.name],
                parent_matrix=matrices[parent.name] if parent else Matrix.Identity(4),
                parent_matrix_local=rest[parent.name] if parent else Matrix.Identity(4), invert=True)
        for modifier in env['skin']:
            modifier.show_viewport = True
        bpy.context.view_layer.update()
        error = max(abs(b.matrix[i][j]-matrices[b.name][i][j]) for b in rig.pose.bones
                    for i in range(4) for j in range(4))
        assert error < 1e-5, error
        path = a.output/('view-%d-pose-%d.png' % (view_index, pose_index))
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        report['frames'].append({'view': view_index, 'elevation_degrees': elevation,
            'azimuth_offset_degrees': azimuth_offset,
            'state': row['state'], 'phase': row['phase'], 'pose_matrix_error': error,
            'camera_location': list(camera.location), 'ortho_scale': camera.data.ortho_scale,
            'ground_anchor': list(world_to_camera_view(scene, camera, Vector())),
            'path': path.name, 'sha256': digest(path)})
        (a.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps({'rendered': len(report['frames']), 'views': views}), flush=True)
