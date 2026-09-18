"""Read-only evaluated-scene observation of the rejected .40 load pose.

No new angle or candidate is selected. Actual evaluated meshes, 200px native
pixel-center masks, first-hit depths, and rigid world vertices are retained to
explain this pose. Head-only counterfactual analysis is possible only after
the head-group inventory is checked. A moved tool with newly solved arms needs
a new scene/render; these partial depth maps cannot approve that later scene.
Materials/antialiasing are not ray tested.
"""
from pathlib import Path
from collections import Counter
import argparse
import hashlib
import json
import math
import os
import runpy
import subprocess
import sys
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from bpy_extras.object_utils import world_to_camera_view

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser(description=__doc__)
for name in ('native-tools', 'pivot-report', 'shoulder-proof', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert not args.output.exists()
assert sha(args.shoulder_proof) == '59a12debb1fa6aa8954c88da40e86c5e1fd34b337e3da73bfea0890eb98ff141'
assert sha(args.pivot_report) == 'cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
proof = json.loads(args.shoulder_proof.read_text())
assert proof['complete'] and proof['passed_geometry'] and proof['rendered']
assert sha(Path(bpy.data.filepath)) == proof['model_sha256']
assert sha(args.native_tools / 'worn/hero.blend') == proof['gear_sha256']
for relative, digest in proof['source_hashes'].items():
    assert sha(ROOT / relative) == digest, relative
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--output', str(args.output / 'scene-setup'), '--gear', 'worn',
            '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT / 'tools/hero_v28/export_hero.py'))
sys.path.insert(0, str(HERE))
from shoulder_load_motion import ShoulderLoadMotion
motion = ShoulderLoadMotion(json.loads((HERE / 'working-surface-selection.json').read_text()),
                            json.loads((HERE / 'upper-body-hinge-selection.json').read_text()),
                            json.loads(args.pivot_report.read_text()))
env['view']('up', (6, 6))
scene, camera, rig = env['s'], env['c'], env['r']
assert scene.render.resolution_x == scene.render.resolution_y == 200
pose = motion.sample('mine', .40)
for modifier in env['skin']:
    modifier.show_viewport = False
posed = dict(pose)
posed['head'] = posed['head'] @ env['head_offset']
env['apply'](posed)
reference = next(row for row in proof['samples'] if row['phase'] == .40)
matrix_error = max(abs(rig.pose.bones[n].matrix[i][j] - m[i][j])
                   for n, m in reference['after_matrices'].items() for i in range(4) for j in range(4))
assert matrix_error < 1e-5
for modifier in env['skin']:
    modifier.show_viewport = True
env['blink'](0.)
bpy.context.view_layer.update()
group_names = ('hero_head', 'tool_head', 'shaft', 'hand_R', 'hand_L')
vertices = {name: [] for name in group_names}
triangles = {name: [] for name in group_names}
objects = []
all_vertices, all_triangles, owners = [], [], []
depsgraph = bpy.context.evaluated_depsgraph_get()
for obj in scene.objects:
    if obj.type != 'MESH' or obj.hide_render:
        continue
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    mesh.calc_loop_triangles()
    vs = [evaluated.matrix_world @ v.co for v in mesh.vertices]
    ts = [tuple(t.vertices) for t in mesh.loop_triangles]
    groups = [g.name for g in obj.vertex_groups]
    selected = []
    if 'head' in groups:
        selected.append('hero_head')
    if obj.name == 'original relief head worn':
        selected.append('tool_head')
    if obj.name == 'round source-textured shaft':
        selected.append('shaft')
    for side in ('R', 'L'):
        if 'hand.' + side in groups:
            selected.append('hand_' + side)
    offset = len(all_vertices)
    all_vertices.extend(vs)
    all_triangles.extend(tuple(i + offset for i in t) for t in ts)
    owners.extend(obj.name for t in ts)
    for name in selected:
        offset = len(vertices[name])
        vertices[name].extend(vs)
        triangles[name].extend(tuple(i + offset for i in t) for t in ts)
    objects.append({'name': obj.name, 'groups': groups, 'observed_groups': selected,
                    'vertices': len(vs), 'triangles': len(ts)})
    evaluated.to_mesh_clear()
assert len(objects) == 629 and len(all_triangles) == 2714340
assert all(vertices[name] and triangles[name] for name in group_names)
full = BVHTree.FromPolygons(all_vertices, all_triangles, all_triangles=True)
transform = camera.matrix_world.copy()
direction = (transform.to_3x3() @ Vector((0., 0., -1.))).normalized()
size, scale = 200, camera.data.ortho_scale
report = {'complete': False, 'source_sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
          'source_tree': subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=ROOT, text=True).strip(),
          'observer_sha256': sha(__file__), 'proof_sha256': sha(args.shoulder_proof),
          'bound_source_hashes': proof['source_hashes'],
          'model_sha256': proof['model_sha256'], 'gear_sha256': proof['gear_sha256'],
          'original_pose_matrix_error': matrix_error, 'phase': .40,
          'camera': {'matrix_world': [list(row) for row in transform], 'ortho_scale': scale,
                     'resolution': [200, 200], 'ray_direction': list(direction)},
          'evaluated_objects': objects, 'object_count': len(objects), 'triangle_count': len(all_triangles),
          'groups': {}, 'rendered': False, 'new_candidate_selected': False,
          'scene_mesh_selection': 'Evaluated view-layer geometry of scene MESH objects with obj.hide_render == false',
          'limits': ['200px native pixel centers only; no packed160 sampling/filtering proof.',
                     'Viewport/render modifier equivalence, camera-ray flags and collection/instance '
                     'visibility are not separately audited. This tree is not proof of renderer equivalence; '
                     'the already retained beauty originals remain the visual evidence.',
                     'Part/scene depth is populated only where the present part is hit; '
                     'it does not cover newly occupied pixels after a move.',
                     'Head-group coverage is not yet certified as the complete helmet/head. '
                     'Inspect all evaluated object names/groups before a head-only clearance inference.',
                     'Only the five selected groups retain world vertices. No future full-scene '
                     'clearance/visibility or changed-arm result can be inferred from these caches.'],
          'scope': 'One already-rendered/rejected pose. Hero-head group includes every visible mesh '
                   'with a head vertex group; object inventory is retained for coverage review. '
                   'First-hit test includes all meshes selected by the stated scene rule. Pixel-center '
                   'geometry ignores materials, transparency and antialiasing. No motion, '
                   'continuous collision, ore-depth or visual acceptance.'}
for name in group_names:
    vs, ts = vertices[name], triangles[name]
    tree = BVHTree.FromPolygons(vs, ts, all_triangles=True)
    isolated = np.zeros((size, size), dtype=np.uint8)
    visible = np.zeros((size, size), dtype=np.uint8)
    part_depth = np.full((size, size), np.nan, dtype=np.float32)
    scene_depth = np.full((size, size), np.nan, dtype=np.float32)
    owned = {r['name'] for r in objects if name in r['observed_groups']}
    occluders = Counter()
    projected = []
    for point in vs:
        q = world_to_camera_view(scene, camera, point)
        projected.append((q.x * size, (1. - q.y) * size))
    bounds = [min(p[0] for p in projected), min(p[1] for p in projected),
              max(p[0] for p in projected), max(p[1] for p in projected)]
    for y in range(max(0, math.floor(bounds[1])), min(size, math.ceil(bounds[3]))):
        for x in range(max(0, math.floor(bounds[0])), min(size, math.ceil(bounds[2]))):
            origin = transform @ Vector((((x + .5) / size - .5) * scale,
                                         (.5 - (y + .5) / size) * scale, 0.))
            hit = tree.ray_cast(origin, direction, 100.)
            if hit[0] is None:
                continue
            first = full.ray_cast(origin, direction, 100.)
            assert first[0] is not None
            isolated[y, x] = 1
            part_depth[y, x], scene_depth[y, x] = hit[3], first[3]
            if owners[first[2]] in owned or abs(first[3] - hit[3]) < 1e-5:
                visible[y, x] = 1
            else:
                occluders[owners[first[2]]] += 1
    file = args.output / (name + '-geometry.npz')
    np.savez_compressed(file, world_vertices=np.asarray(vs, dtype=np.float32),
                        triangles=np.asarray(ts, dtype=np.int32),
                        projected_vertices=np.asarray(projected, dtype=np.float64),
                        projected_mask=isolated, visible_mask=visible,
                        part_depth=part_depth, scene_depth=scene_depth)
    with file.open('rb') as f:
        os.fsync(f.fileno())
    report['groups'][name] = {'objects': sorted(owned), 'vertices': len(vs), 'triangles': len(ts),
                              'bounds200': bounds, 'projected_pixel_centers': int(isolated.sum()),
                              'visible_pixel_centers': int(visible.sum()),
                              'occluders': dict(occluders.most_common()),
                              'geometry': file.name, 'geometry_sha256': sha(file)}
    print('LOAD_VISIBILITY_GROUP', name, int(isolated.sum()), int(visible.sum()), flush=True)
for relative, digest in proof['source_hashes'].items():
    assert sha(ROOT / relative) == digest, relative
report['complete'] = True
file = args.output / 'shoulder-visibility-final.json'
with file.open('w') as f:
    json.dump(report, f, indent=2); f.write('\n'); f.flush(); os.fsync(f.fileno())
print('LOAD_VISIBILITY_COMPLETE', sha(file), flush=True)
