"""One restart from an actual stop-bridge draw, before runtime integration.

This diagnoses the existing Transition blend before adding any runtime bank.
The ore projection is a counterfactual with a frozen captured sprite transform,
not a physical collision test or an actual in-game cancellation.
"""
from pathlib import Path
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
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser()
for name in ('native-tools', 'pivot-report', 'reference-manifest', 'recorded',
             'target-identity', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert not args.output.exists(), 'Use a fresh output directory'
assert sha(args.reference_manifest) == 'ea62b3acf19ff83b0d61e4088771217d03ce2de21fbba16b6274c55fd66c5571'
assert sha(args.recorded) == '8eb9f33452a3c76d644bb1cc6bc7af73495c672394596e1b9d37d780a056ef8c'
reference = json.loads(args.reference_manifest.read_text())
recorded = json.loads(args.recorded.read_text())
identity = json.loads(args.target_identity.read_text())
assert len(reference['frames']) == 194 and reference['rendered']
assert recorded['source_sha'] == '7e59fcc57e6a00a4d5e2d987c8ddd06aa36627ee'
assert recorded['passed'] and not recorded['failures']
assert recorded['route'] == identity['route']
draw = recorded['samples'][47]
assert draw['visual']['state'] == 'mine_to_idle-392857' and draw['visual']['is_bridge']
assert draw['visual']['actually_presented'] and draw['visual']['logical_state'] == 'idle'
assert draw['target_hp'] == 950 and draw['relative_impact_serial'] == 0
assert draw['mining_elapsed'] == draw['mining_progress'] == 0.
assert abs(draw['visual']['bridge_elapsed'] - .05) < 1e-12
phase = min(reference['states'][draw['visual']['state']]['phases'], key=lambda p: abs(p - draw['visual']['sample_phase']))
assert abs(phase - draw['visual']['sample_phase']) < 1e-12
assert sha(args.pivot_report) == reference['render_provenance']['pivot_report_sha256']
source_hashes = dict(reference['render_provenance']['source_hashes'])
source_hashes[str(Path(__file__).relative_to(ROOT))] = sha(Path(__file__))
source_hashes[str((HERE / 'interrupted_return_motion.py').relative_to(ROOT))] = sha(HERE / 'interrupted_return_motion.py')
for relative, digest in source_hashes.items():
    assert sha(ROOT / relative) == digest, relative
surface = json.loads((HERE / 'working-surface-selection.json').read_text())
hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
pivot = json.loads(args.pivot_report.read_text())
assert sha(Path(bpy.data.filepath)) == surface['model_sha256']
assert sha(args.native_tools / 'worn/hero.blend') == surface['gear_sha256']
texture = ROOT / identity['texture_path'].removeprefix('res://')
assert sha(texture) == identity['texture_sha256']
ore = bpy.data.images.load(str(texture), check_existing=False)
tw, th = ore.size
rgba = list(ore.pixels)
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--output', str(args.output / 'scene-setup'), '--gear', 'worn',
            '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT / 'tools/hero_v28/export_hero.py'))
sys.path.insert(0, str(HERE))
from return_tool_offset_motion import FrozenReturnMotion
from interrupted_return_motion import InterruptedReturnTransition
import native_motion as native
import premium_motion as pm

motion = FrozenReturnMotion(surface, hinge, pivot)
previous = motion.transition('mine', .392857142857143, 'idle')
clip = InterruptedReturnTransition(motion, previous, draw['visual']['state'], phase)
env['view']('up', (6, 6))
scene, camera, rig = env['s'], env['c'], env['r']
assert env['m']['directions']['up']['ground_anchor'] == reference['directions']['up']['ground_anchor']
assert scene.render.resolution_x == scene.render.resolution_y == 200
assert scene.cycles.samples == 8 and abs(clip.duration - .12) < 1e-12
for modifier in env['skin']:
    modifier.show_viewport = False
bpy.context.view_layer.update()
head = bpy.data.objects[surface['working_surface']['head_object']]
evaluated = head.evaluated_get(bpy.context.evaluated_depsgraph_get())
mesh = evaluated.to_mesh()
mesh.calc_loop_triangles()
triangle_ids = surface['working_surface']['source_triangle_indices']
triangles = [tuple(mesh.loop_triangles[i].vertices) for i in triangle_ids]
vertex_ids = sorted({i for tri in triangles for i in tri})
assert vertex_ids == sorted(surface['working_surface']['source_vertex_indices'])
rest_vertices = {i: evaluated.matrix_world @ mesh.vertices[i].co for i in vertex_ids}
evaluated.to_mesh_clear()
areas = [((rest_vertices[b] - rest_vertices[a]).cross(rest_vertices[c] - rest_vertices[a])).length * .5
         for a, b, c in triangles]
rest_center = sum(((rest_vertices[a] + rest_vertices[b] + rest_vertices[c]) * (area / 3.)
                   for (a, b, c), area in zip(triangles, areas)), Vector()) / sum(areas)
local_cap = Vector(surface['working_surface']['surface_center_tool_local'])
tool_bind_inverse = rig.data.bones['tool'].matrix_local.inverted()


def apply(pose):
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(pose)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}


def project(point):
    q = world_to_camera_view(scene, camera, point)
    x, y, w, h = draw['framing']['subjects']['hero_and_tool']
    return [x + q.x * w, y + (1. - q.y) * h]


def alpha(point):
    x, y, w, h = draw['framing']['subjects']['actual_resource_sprite']
    u, v = (point[0] - x) / w, (point[1] - y) / h
    if not (0. <= u < 1. and 0. <= v < 1.):
        return 0.
    return rgba[(min(th - 1, int((1. - v) * th)) * tw + min(tw - 1, int(u * tw))) * 4 + 3]


def measure(pose):
    matrices = apply(pose)
    skin = matrices['tool'] @ tool_bind_inverse
    center = skin @ rest_center
    expected = pose['rear'] + pm.tool_frame(pose['axis'], pose['tool_normal']) @ local_cap
    error = (center - expected).length
    assert error < 1e-5, ('Actual cap binding', error)
    grip_error = max((((matrices['hand.' + side] @ rig.data.bones['hand.' + side].matrix_local.inverted())
                       @ env['rest']['grips'][side]) - pose['grips'][side]).length for side in native.SIDES)
    assert grip_error < 1e-5
    projected = []
    for a, b, c in triangles:
        va, vb, vc = (skin @ rest_vertices[i] for i in (a, b, c))
        for i in range(5):
            for j in range(5 - i):
                projected.append(project(va * (i / 4.) + vb * (j / 4.) + vc * (1. - (i + j) / 4.)))
    alphas = [alpha(p) for p in projected]
    return {'cap_centroid': list(center), 'cap_centroid_screen': project(center),
            'cap_binding_error': error, 'grip_error': grip_error,
            'cap_samples': len(alphas), 'max_ore_alpha': max(alphas),
            'ore_overlap_samples': sum(a > .5 for a in alphas),
            'tool_skin_matrix': [list(row) for row in skin],
            'native': native.frame_metadata(pose, motion.ground)}


endpoint_errors = []
for t in (0., clip.duration):
    actual = apply(clip.sample(t))
    expected_pose = (previous.sample(.05) if t == 0. else
                     pm.translate_pose(motion.sample('mine', clip.metadata()['destination_phase']), clip.destination_offset))
    expected = apply(expected_pose)
    error = max(abs(actual[n][i][j] - expected[n][i][j]) for n in actual for i in range(4) for j in range(4))
    assert error < 1e-5
    endpoint_errors.append(error)
control = measure(motion.sample('mine', .55))
assert control['max_ore_alpha'] > .5, 'Positive contact control must hit the same captured ore alpha'
times = sorted({i / 600 for i in range(73)} | {1 / 60, 2 / 60, 4 / 60, 5 / 60, 7 / 60})
rows = [{'seconds': t, 'target_phase': clip.phase_at('mine', 0., t),
         'source_weight': 1. - native.gait.smoother(t / clip.body_duration),
         **measure(clip.sample(t))} for t in times]
report = {'complete': False, 'source_sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
          'source_hashes': source_hashes, 'recorded_sha256': sha(args.recorded),
          'reference_sha256': sha(args.reference_manifest), 'target_identity_sha256': sha(args.target_identity),
          'ore_texture_sha256': sha(texture), 'model_sha256': surface['model_sha256'],
          'gear_sha256': surface['gear_sha256'], 'source_draw': draw,
          'transition': clip.metadata(), 'cap_triangle_ids': triangle_ids,
          'cap_triangles': triangles, 'cap_rest_vertices': {str(i): list(v) for i, v in rest_vertices.items()},
          'cap_rest_center': list(rest_center), 'endpoint_matrix_errors': endpoint_errors,
          'positive_contact_control': control, 'samples': rows, 'renders': [],
          'projected_clear_at_sampled_points': all(r['max_ore_alpha'] <= .5 for r in rows),
          'scope': 'One active-bridge restart from captured sample47 at 50 ms. Dense native cap samples against frozen draw47 ore alpha; '
                   'no alpha filtering, occlusion, physical 3D collision, moving ore, controller input or publication approval. '
                   'Original native isolated images follow; runtime and bank are unchanged.'}
def matrices_at(pose):
    return {name: [list(row) for row in matrix] for name, matrix in apply(pose).items()}


def velocity(samples, h, side):
    # Second-order one-sided differences retain every observed rig component.
    a, b, c = samples
    weights = (-3., 4., -1.) if side == 'right' else (3., -4., 1.)
    return {name: [[sum(w * m[name][i][j] for w, m in zip(weights, (a, b, c))) / (2. * h)
                    for j in range(4)] for i in range(4)] for name in a}


continuity = []
for label, t in [('restart', 0.), ('old-stop-end', .07), ('new-mine-end', .12)]:
    row = {'join': label, 'seconds': t, 'differences': []}
    for h in (.001, .0005):
        left = [matrices_at(previous.sample(.05 - k * h) if t == 0. else clip.sample(t - k * h)) for k in range(3)]
        right = [matrices_at(motion.sample('mine', clip.phase_at('mine', 0., t + k * h))
                             if t == clip.duration else clip.sample(t + k * h)) for k in range(3)]
        va, vb = velocity(left, h, 'left'), velocity(right, h, 'right')
        row['differences'].append({'step_seconds': h, 'left_rig_samples': left, 'right_rig_samples': right,
            'position_max_component_difference': max(abs(left[0][n][i][j] - right[0][n][i][j]) for n in va for i in range(4) for j in range(4)),
            'velocity_max_component_difference': max(abs(va[n][i][j] - vb[n][i][j]) for n in va for i in range(4) for j in range(4))})
    continuity.append(row)
report['rig_continuity'] = continuity
report['continuity_limit'] = 'Finite-difference matrix observations at two steps; no new visual pass threshold or rendered smoothness claim.'
report['max_sole_displacement'] = max((Vector(r['native']['feet'][side]['sole_point']) - Vector(rows[0]['native']['feet'][side]['sole_point'])).length for r in rows for side in native.SIDES)
assert report['max_sole_displacement'] < 1e-5
for label, t in [('source', 0.), ('middle', .05), ('old-stop-end', .07), ('mine-end', clip.duration)]:
    apply(clip.sample(t))
    env['blink'](0.)
    for modifier in env['skin']:
        modifier.show_viewport = True
    bpy.context.view_layer.update()
    png = args.output / (label + '.png')
    mask = args.output / ('mask-' + label + '-0001.png')
    scene.render.filepath = str(png)
    env['mask'].base_path = str(args.output)
    env['mask'].file_slots[0].path = 'mask-' + label + '-'
    scene.frame_current = 1
    bpy.ops.render.render(write_still=True)
    for p in (png, mask):
        with p.open('rb') as f:
            os.fsync(f.fileno())
    report['renders'].append({'label': label, 'seconds': t, 'path': png.name, 'sha256': sha(png),
                              'mask': mask.name, 'mask_sha256': sha(mask)})
    print('BRIDGE_RESTART_FRAME', label, flush=True)
for relative, digest in source_hashes.items():
    assert sha(ROOT / relative) == digest, relative
report['complete'] = True
with (args.output / 'bridge-restart-final.json').open('w') as f:
    json.dump(report, f, indent=2)
    f.write('\n')
    f.flush()
    os.fsync(f.fileno())
print('BRIDGE_RESTART_COMPLETE', report['projected_clear_at_sampled_points'], flush=True)
