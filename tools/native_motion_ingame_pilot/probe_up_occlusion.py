"""Evaluated native mesh occlusion, not a rendered image or a visual verdict.

Runs in Blender with the approved .blend already open. Reuses the exact exporter
scene assembly, real gear, camera and native pose applier without rendering.
Rays sample native camera pixel centers; material transparency, antialiasing,
lighting and final in-game scale still require the actual native image gate.
"""
from pathlib import Path
import argparse
import collections
import hashlib
import json
import runpy
import sys
import time
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

parser = argparse.ArgumentParser()
parser.add_argument('--native-tools', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--setup-only', action='store_true', help='Expose the evaluated scene and measurement helpers to another diagnostic')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ROOT = Path(__file__).resolve().parents[1] / 'hero_v28'
args.output.mkdir(parents=True, exist_ok=True)
original_model = Path(bpy.data.filepath)
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools), '--output', str(args.output/'scene-load'),
            '--gear', 'worn', '--native-motion-pilot', '--native-up-working-plane', '--direction', 'up',
            '--native-states', 'mine', '--native-loop-counts', 'mine=1', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT/'export_hero.py'))
scene, camera = env['s'], env['c']
env['view']('up', (6, 6))


def category(obj):
    groups = {g.name for g in obj.vertex_groups}
    if groups.intersection(('tool', 'bit')):
        return 'tool'
    if any(g.startswith('hand.') for g in groups):
        return 'hands'
    if any(g.startswith('lower.') for g in groups):
        return 'forearms'
    if any(g.startswith('upper.') for g in groups):
        return 'upper_arms'
    return 'body_or_other'


def mesh_trees():
    depsgraph = bpy.context.evaluated_depsgraph_get()
    vertices, triangles, owners = [], [], []
    group_vertices = {k:[] for k in ('tool', 'hands', 'forearms')}
    group_triangles = {k:[] for k in group_vertices}
    objects = []
    for obj in scene.objects:
        if obj.type != 'MESH' or obj.hide_render:
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        vs = [evaluated.matrix_world@v.co for v in mesh.vertices]
        ts = [tuple(t.vertices) for t in mesh.loop_triangles]
        kind = category(obj)
        offset = len(vertices)
        vertices.extend(vs)
        triangles.extend(tuple(v+offset for v in t) for t in ts)
        owners.extend((obj.name, kind) for _ in ts)
        if kind in group_vertices:
            offset = len(group_vertices[kind])
            group_vertices[kind].extend(vs)
            group_triangles[kind].extend(tuple(v+offset for v in t) for t in ts)
        objects.append({'name':obj.name, 'category':kind, 'vertices':len(vs), 'triangles':len(ts),
                        'groups':[g.name for g in obj.vertex_groups]})
        evaluated.to_mesh_clear()
    all_mesh = BVHTree.FromPolygons(vertices, triangles, all_triangles=True)
    groups = {k:BVHTree.FromPolygons(group_vertices[k], group_triangles[k], all_triangles=True) for k in group_vertices}
    return all_mesh, groups, owners, objects


def measure():
    all_mesh, groups, owners, objects = mesh_trees()
    report = {k:{'projected_pixel_centers':0, 'visible_pixel_centers':0, 'occluders':collections.Counter(), 'pixels':[]} for k in groups}
    transform = camera.matrix_world.copy()
    direction = (transform.to_3x3()@Vector((0, 0, -1))).normalized()
    size, scale = 200, camera.data.ortho_scale
    for y in range(size):
        for x in range(size):
            origin = transform@Vector((((x+.5)/size-.5)*scale, (.5-(y+.5)/size)*scale, 0))
            first = None
            for name, tree in groups.items():
                hit = tree.ray_cast(origin, direction, 100)
                if hit[0] is None:
                    continue
                d = report[name]
                d['projected_pixel_centers'] += 1
                d['pixels'].append((x, y))
                if first is None:
                    first = all_mesh.ray_cast(origin, direction, 100)
                assert first[0] is not None
                owner, kind = owners[first[2]]
                if kind == name or abs(first[3]-hit[3]) < 1e-5:
                    d['visible_pixel_centers'] += 1
                else:
                    d['occluders'][owner] += 1
    for data in report.values():
        pixels = data.pop('pixels')
        data['projected_bounds'] = [min(p[0] for p in pixels), min(p[1] for p in pixels), max(p[0] for p in pixels)+1, max(p[1] for p in pixels)+1] if pixels else None
        data['visible_fraction'] = data['visible_pixel_centers']/data['projected_pixel_centers'] if pixels else None
        data['occluders'] = dict(data['occluders'].most_common())
    return report, objects


report = {'rendered':False, 'evaluated_native_mesh':True,
          'purpose':'Geometric occlusion at exact camera pixel centers, not material/lighting/antialias visibility or readability approval',
          'native_source_checkpoint':'354bc9bd04953f4e20e23c2eef87d1affe686ab2',
          'model_sha256':hashlib.sha256(original_model.read_bytes()).hexdigest(),
          'gear_sha256':hashlib.sha256((args.native_tools/'worn/hero.blend').read_bytes()).hexdigest(),
          'source_hashes':{str(p.relative_to(ROOT.parent.parent)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'native_motion.py', ROOT/'export_hero.py', Path(__file__)]},
          'camera':{'position':list(camera.location), 'rotation':list(camera.rotation_euler), 'ortho_scale':camera.data.ortho_scale, 'pixel_grid':[200,200]},
          'cases':[]}
started = time.monotonic()
for enabled in (() if args.setup_only else (False, True)):
    env['a'].native_up_working_plane = enabled
    for phase in (.375, .55, .625):
        pose = env['pose'](phase, 'mine', 'up')
        values, objects = measure()
        case = {'working_plane_v1':enabled, 'phase':phase, 'rear':list(pose['rear']), 'axis':list(pose['axis']),
                'measurements':values}
        report['cases'].append(case)
        report['evaluated_objects'] = objects
        (args.output/'occlusion.json').write_text(json.dumps(report, indent=2)+'\n')
        print('OCCLUSION_CASE', json.dumps(case), flush=True)
report['elapsed_seconds'] = time.monotonic()-started
report['complete'] = True
(args.output/'occlusion.json').write_text(json.dumps(report, indent=2)+'\n')
print('NATIVE_OCCLUSION_COMPLETE', len(report['cases']), report['elapsed_seconds'], flush=True)
