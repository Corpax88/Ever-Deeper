"""One contour-derived cross-shoulder load, dense rig checks and seven native stills.

The ore relation uses a frozen real hit draw as a counterfactual projection.
It is not a new game capture or a physical contact/occlusion approval. Failed
geometry is retained in a closed result and no image bank is adopted here.
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
import traceback

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser(description=__doc__)
for name in ('native-tools', 'pivot-report', 'cap-proof', 'recorded', 'rejected-load', 'visibility', 'hull-clearance', 'axis-proposal', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert not args.output.exists(), 'Use a fresh output directory'
assert sha(args.pivot_report) == 'cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
assert sha(args.cap_proof) == '3da98249b71b0d05053ef0f30e4def8b6007b0650cd7aaf2078b89a592233f2e'
assert sha(args.recorded) == 'b77a5c950b306181970942e1601979531ccfa3d1159bf402f2e5a0cca94345d7'
cap_proof = json.loads(args.cap_proof.read_text())
recorded = json.loads(args.recorded.read_text())
assert recorded['passed'] and recorded['verify_contact_frames']
draw = recorded['samples'][65]
assert draw['visual']['presenting_impact'] and draw['visual']['sample_phase'] == .55
assert draw['resource_hit_presentation']['phase'] == 'contact'
surface = json.loads((HERE / 'working-surface-selection.json').read_text())
hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
pivot = json.loads(args.pivot_report.read_text())
assert sha(Path(bpy.data.filepath)) == surface['model_sha256'] == cap_proof['model_sha256']
assert sha(args.native_tools / 'worn/hero.blend') == surface['gear_sha256'] == cap_proof['gear_sha256']
selection = json.loads((HERE / 'cross-shoulder-load-selection.json').read_text())
for path, key in ((args.rejected_load, 'rejected_load_sha256'),
                  (args.visibility, 'unchanged_visibility_sha256'),
                  (args.hull_clearance, 'hull_clearance_sha256'),
                  (args.axis_proposal, 'axis_proposal_sha256')):
    assert sha(path) == selection[key], str(path)
rejected = json.loads(args.rejected_load.read_text())
hull = json.loads(args.hull_clearance.read_text())
assert rejected['complete'] and rejected['passed_geometry'] and not rejected['visual_accepted']
assert selection['extra_world_z_lift'] == hull['required_world_z_lift']
assert selection['native200_projected_hull_gap'] == hull['native_pixel_gap']
assert abs(selection['extra_world_z_lift'] -
           (selection['head_hull_required_shift200'] + selection['native200_projected_hull_gap']) /
           selection['vertical_pixels200_per_native_unit']) < 1e-12
source_hashes = dict(rejected['source_hashes'])
assert all(source_hashes.get(k) == v for k, v in cap_proof['source_hashes'].items())
for relative, digest in source_hashes.items():
    assert sha(ROOT / relative) == digest, relative
for name in ('cross_shoulder_load_motion.py', 'cross-shoulder-load-selection.json', 'probe_cross_shoulder_load.py'):
    source_hashes[str((HERE / name).relative_to(ROOT))] = sha(HERE / name)
texture = ROOT / 'assets/endless/node-deep-alloy-v1.png'
assert sha(texture) == cap_proof['ore_texture_sha256']
ore = bpy.data.images.load(str(texture), check_existing=False)
tw, th = ore.size
rgba = list(ore.pixels)
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--output', str(args.output / 'scene-setup'), '--gear', 'worn',
            '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT / 'tools/hero_v28/export_hero.py'))
sys.path.insert(0, str(HERE))
from cross_shoulder_load_motion import CrossShoulderLoadMotion
import native_motion as native
import premium_motion as pm

motion = CrossShoulderLoadMotion(surface, hinge, pivot)
env['view']('up', (6, 6))
scene, camera, rig = env['s'], env['c'], env['r']
assert scene.render.resolution_x == scene.render.resolution_y == 200
assert scene.cycles.samples == 8
tool_inverse = rig.data.bones['tool'].matrix_local.inverted()
vertices = {int(k): Vector(v) for k, v in cap_proof['cap_rest_vertices'].items()}
triangles = cap_proof['cap_triangles']
center = Vector(cap_proof['cap_rest_center'])
protected = ['root', 'hips', 'body', 'head', 'thigh.R', 'shin.R', 'foot.R', 'thigh.L', 'shin.L', 'foot.L']
observed = [*protected, 'tool', 'upper.R', 'lower.R', 'hand.R', 'upper.L', 'lower.L', 'hand.L']


def apply(pose):
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(pose)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}


def matrix_error(left, right):
    return max(abs(left[i][j] - right[i][j]) for i in range(4) for j in range(4))


def project(point, bounds):
    q = world_to_camera_view(scene, camera, point)
    x, y, w, h = bounds
    return [x + q.x * w, y + (1. - q.y) * h]


def alpha(point):
    x, y, w, h = draw['framing']['subjects']['actual_resource_sprite']
    u, v = (point[0] - x) / w, (point[1] - y) / h
    if not (0. <= u < 1. and 0. <= v < 1.):
        return 0.
    return rgba[(min(th - 1, int((1. - v) * th)) * tw + min(tw - 1, int(u * tw))) * 4 + 3]


def measure(pose, matrices):
    skin = matrices['tool'] @ tool_inverse
    cap = skin @ center
    expected = pose['rear'] + pm.tool_frame(pose['axis'], pose['tool_normal']) @ motion.local_cap
    cap_error = (cap - expected).length
    grip_error = max((((matrices['hand.' + side] @ rig.data.bones['hand.' + side].matrix_local.inverted())
                       @ env['rest']['grips'][side]) - pose['grips'][side]).length for side in native.SIDES)
    lengths = {n: (rig.pose.bones[n].tail - rig.pose.bones[n].head).length
               for n in ('upper.R', 'lower.R', 'upper.L', 'lower.L')}
    length_error = max(abs(v - rig.data.bones[n].length) for n, v in lengths.items())
    alphas = []
    for a, b, c in triangles:
        va, vb, vc = (skin @ vertices[n] for n in (a, b, c))
        for i in range(5):
            for j in range(5 - i):
                point = va * (i / 4.) + vb * (j / 4.) + vc * (1. - (i + j) / 4.)
                alphas.append(alpha(project(point, draw['framing']['subjects']['hero_and_tool'])))
    start = project(pose['rear'], [0., 0., 160., 160.])
    end = project(pose['rear'] + pose['axis'], [0., 0., 160., 160.])
    return {'cap_binding_error': cap_error, 'grip_error': grip_error,
            'arm_length_error': length_error,
            'maximum_arm_reach': max((c-a).length for a, b, c in pose['arms'].values()),
            'cap_samples': len(alphas), 'frozen_ore_overlap_samples': sum(v > .5 for v in alphas),
            'max_frozen_ore_alpha': max(alphas), 'cap_center': list(cap),
            'cap_center_screen160': project(cap, [0., 0., 160., 160.]),
            'projected_shaft_degrees': math.degrees(math.atan2(end[1]-start[1], end[0]-start[0])),
            'tool_skin_matrix': [list(row) for row in skin],
            'native': native.frame_metadata(pose, motion.ground)}


report = {'complete': False, 'passed_geometry': False, 'rendered': False,
          'source_sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
          'source_tree': subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=ROOT, text=True).strip(),
          'source_hashes': source_hashes, 'selection': motion.selection(),
          'inputs': {str(p): sha(p) for p in (args.pivot_report, args.cap_proof, args.recorded, args.rejected_load, args.visibility, args.hull_clearance, args.axis_proposal)},
          'model_sha256': surface['model_sha256'], 'gear_sha256': surface['gear_sha256'],
          'ore_texture_sha256': sha(texture), 'frozen_game_draw': draw,
          'samples': [], 'renders': [], 'visual_accepted': False, 'production_accepted': False,
          'scope': 'One rigid-tool/attached-hand backswing proposal. Same original camera, model, '
                   'materials, torso/head, roots and feet. Counterfactual ore alpha uses one frozen '
                   'real hit draw, not a new game frame, continuous collision or full-scene occlusion proof. '
                   'Changed windup invalidates old cancellation/entry/restart bank approvals.'}


def save(filename):
    p = args.output / filename
    with p.open('w') as file:
        json.dump(report, file, indent=2); file.write('\n'); file.flush(); os.fsync(file.fileno())


try:
    phases = sorted({i / 128 for i in range(129)} | {0., .125, .2310924369747899, .24, .39285714285714285, .40, .48, .55, .575, .625, .8125})
    for q in phases:
        old = motion.original.sample('mine', q)
        before = apply(old)
        control = measure(old, before)
        pose = motion.sample('mine', q)
        after = apply(pose)
        candidate = measure(pose, after)
        error = max(matrix_error(before[n], after[n]) for n in protected)
        all_error = max(matrix_error(before[n], after[n]) for n in before)
        row = {'phase': q, 'protected_matrix_error': error,
               'all_bone_difference': all_error, 'control': control, 'candidate': candidate,
               'before_matrices': {n: [list(r) for r in before[n]] for n in observed},
               'after_matrices': {n: [list(r) for r in after[n]] for n in observed},
               'control_arm_joints': {s: [list(p) for p in old['arms'][s]] for s in native.SIDES},
               'candidate_arm_joints': {s: [list(p) for p in pose['arms'][s]] for s in native.SIDES}}
        report['samples'].append(row)
        assert max(error, candidate['cap_binding_error'], candidate['grip_error'], candidate['arm_length_error']) < 1e-5, row
        assert candidate['maximum_arm_reach'] < .71 - 1e-5, row
        assert abs((pose['grips']['R'] - pose['grips']['L']).length - .145) < 1e-6
        if q % 1. == 0. or q >= .55:
            assert all_error == 0., ('Original start/contact/recovery changed', q, all_error)
    report['passed_geometry'] = True
    save('cross-shoulder-load-progress.json')
    for q in (.2310924369747899, .40, .48, .55):
        for label in (('control', 'candidate') if q < .55 else ('shared-contact',)):
            pose = (motion.original if label == 'control' else motion).sample('mine', q)
            apply(pose)
            env['blink'](0.)
            for modifier in env['skin']:
                modifier.show_viewport = True
            bpy.context.view_layer.update()
            key = f'{label}-{round(q * 1000000):06}'
            png = args.output / (key + '.png')
            mask = args.output / ('mask-' + key + '-0001.png')
            scene.render.filepath = str(png)
            env['mask'].base_path = str(args.output)
            env['mask'].file_slots[0].path = 'mask-' + key + '-'
            scene.frame_current = 1
            bpy.ops.render.render(write_still=True)
            for path in (png, mask):
                with path.open('rb') as file:
                    os.fsync(file.fileno())
            report['renders'].append({'variant': label, 'phase': q,
                                      'png': png.name, 'png_sha256': sha(png),
                                      'mask': mask.name, 'mask_sha256': sha(mask)})
            save('cross-shoulder-load-progress.json')
    for relative, digest in source_hashes.items():
        assert sha(ROOT / relative) == digest, relative
    report.update(complete=True, rendered=True)
    save('cross-shoulder-load-final.json')
    print('CROSS_SHOULDER_LOAD_COMPLETE', len(report['samples']), len(report['renders']), flush=True)
except Exception as error:
    report.update(complete=True, failure=str(error), failure_phase=q, traceback=traceback.format_exc())
    save('cross-shoulder-load-rejected.json')
    raise
