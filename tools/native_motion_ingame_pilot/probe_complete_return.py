"""Bounded native test of one complete return, using the original rig and art.

Recorded hit geometry is a frozen projection reference, not gameplay or physical
collision proof. Keep partial results and reject nonzero if any setup or rig
check fails. No transition bank or production assets are changed by this probe.
"""
from pathlib import Path
import argparse
import hashlib
import json
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
for name in ('native-tools', 'pivot-report', 'cap-proof', 'recorded', 'control', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert not args.output.exists(), 'Use a fresh output directory'
args.output.mkdir(parents=True)
stage, last_phase = 'bindings', None
report = {'complete': False, 'passed_geometry': False, 'rendered': False,
          'samples': [], 'renders': [], 'seams': [],
          'actual_gameplay_run': False, 'visual_accepted': False,
          'production_accepted': False, 'scope': __doc__}


def save(name):
    with (args.output / name).open('w') as file:
        json.dump(report, file, indent=2)
        file.write('\n')
        file.flush()
        os.fsync(file.fileno())


def apply(pose):
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(pose)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}


def project(point, bounds):
    projected = world_to_camera_view(scene, camera, point)
    x, y, w, h = bounds
    return [x + projected.x * w, y + (1. - projected.y) * h]


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
    grip_error = max((((matrices['hand.' + side] @ rig.data.bones['hand.' + side].matrix_local.inverted())
                       @ env['rest']['grips'][side]) - pose['grips'][side]).length for side in native.SIDES)
    length_error = max(abs((rig.pose.bones[n].tail - rig.pose.bones[n].head).length - rig.data.bones[n].length)
                       for n in ('upper.R', 'lower.R', 'upper.L', 'lower.L'))
    alphas = []
    for a, b, c in triangles:
        va, vb, vc = (skin @ vertices[n] for n in (a, b, c))
        for i in range(5):
            for j in range(5 - i):
                point = va * (i / 4.) + vb * (j / 4.) + vc * (1. - (i + j) / 4.)
                alphas.append(alpha(project(point, draw['framing']['subjects']['hero_and_tool'])))
    return {'cap_binding_error': (cap - expected).length, 'grip_error': grip_error,
            'arm_length_error': length_error,
            'maximum_arm_reach': max((c-a).length for a, b, c in pose['arms'].values()),
            'cap_samples': len(alphas), 'frozen_ore_overlap_samples': sum(v > .5 for v in alphas),
            'max_frozen_ore_alpha': max(alphas), 'cap_center': list(cap),
            'cap_center_screen160': project(cap, [0., 0., 160., 160.]),
            'tool_skin_matrix': [list(row) for row in skin],
            'arm_joints': {s: [list(p) for p in pose['arms'][s]] for s in native.SIDES},
            'matrices': {n: [list(row) for row in m] for n, m in matrices.items()},
            'native': native.frame_metadata(pose, motion.ground)}


def matrix_error(before, after, names):
    return max(abs(before[n][i][j] - after[n][i][j]) for n in names for i in range(4) for j in range(4))


try:
    assert sha(args.pivot_report) == 'cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
    assert sha(args.cap_proof) == '3da98249b71b0d05053ef0f30e4def8b6007b0650cd7aaf2078b89a592233f2e'
    assert sha(args.recorded) == '7af8b241fef765da879bc5c3429130e493c0126827e0f7fef448549fce15558a'
    assert sha(args.control) == 'a949b7a944d6888ee9abc02656cbda844c07df611e23ec36766ee8b9d9454bce'
    control_report = json.loads(args.control.read_text())
    cap_proof = json.loads(args.cap_proof.read_text())
    recorded = json.loads(args.recorded.read_text())
    assert control_report['complete'] and control_report['passed_geometry'] and control_report['rendered']
    assert recorded['passed'] and recorded['verify_contact_frames'] and recorded['cross_shoulder_load']
    draw = recorded['samples'][50]
    assert draw['visual']['presenting_impact'] and draw['visual']['sample_phase'] == .55
    assert draw['resource_hit_presentation']['phase'] == 'contact'
    capture = recorded['captures'][50]
    assert capture['sample'] == 50 and sha(args.recorded.parent / capture['path']) == capture['sha256']
    source_hashes = dict(control_report['source_hashes'])
    for name in ('complete_return_motion.py', 'probe_complete_return.py'):
        source_hashes[str((HERE / name).relative_to(ROOT))] = sha(HERE / name)
    for relative, digest in source_hashes.items():
        assert sha(ROOT / relative) == digest, relative
    surface = json.loads((HERE / 'working-surface-selection.json').read_text())
    hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
    pivot = json.loads(args.pivot_report.read_text())
    assert sha(Path(bpy.data.filepath)) == surface['model_sha256'] == cap_proof['model_sha256']
    assert sha(args.native_tools / 'worn/hero.blend') == surface['gear_sha256'] == cap_proof['gear_sha256']
    texture = ROOT / 'assets/endless/node-deep-alloy-v1.png'
    assert sha(texture) == cap_proof['ore_texture_sha256']
    report.update(source_sha=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                  source_tree=subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=ROOT, text=True).strip(),
                  source_hashes=source_hashes,
                  inputs={str(p): sha(p) for p in (args.pivot_report, args.cap_proof, args.recorded, args.control)},
                  model_sha256=surface['model_sha256'], gear_sha256=surface['gear_sha256'],
                  ore_texture_sha256=sha(texture), frozen_game_draw=draw)
    stage = 'scene-setup'
    ore = bpy.data.images.load(str(texture), check_existing=False)
    tw, th = ore.size
    rgba = list(ore.pixels)
    sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
                '--output', str(args.output / 'scene-setup'), '--gear', 'worn',
                '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
                '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
    env = runpy.run_path(str(ROOT / 'tools/hero_v28/export_hero.py'))
    sys.path.insert(0, str(HERE))
    import native_motion as native
    import premium_motion as pm
    from cross_shoulder_load_motion import CrossShoulderLoadMotion
    from complete_return_motion import CompleteReturnMotion
    control = CrossShoulderLoadMotion(surface, hinge, pivot)
    motion = CompleteReturnMotion(surface, hinge, pivot)
    report['selection'] = motion.selection()
    env['view']('up', (6, 6))
    scene, camera, rig = env['s'], env['c'], env['r']
    assert scene.render.resolution_x == scene.render.resolution_y == 200 and scene.cycles.samples == 8
    tool_inverse = rig.data.bones['tool'].matrix_local.inverted()
    vertices = {int(k): Vector(v) for k, v in cap_proof['cap_rest_vertices'].items()}
    triangles = cap_proof['cap_triangles']
    center = Vector(cap_proof['cap_rest_center'])
    protected = ['root', 'hips', 'body', 'head', 'thigh.R', 'shin.R', 'foot.R', 'thigh.L', 'shin.L', 'foot.L']
    phase_set = {i / 128 for i in range(129)} | {r['phase'] for r in control_report['samples']}
    phase_set.update(s['visual']['sample_phase'] for s in recorded['samples'] if s['visual']['state'] == 'mine')
    phase_set.update((.6875, .75, .875, .96875))
    stage = 'dense-rig-checks'
    for q in sorted(phase_set):
        last_phase = q
        old_pose = control.sample('mine', q)
        before = apply(old_pose)
        old = measure(old_pose, before)
        pose = motion.sample('mine', q)
        after = apply(pose)
        new = measure(pose, after)
        row = {'phase': q, 'protected_matrix_error': matrix_error(before, after, protected),
               'all_bone_difference': matrix_error(before, after, before), 'control': old, 'candidate': new}
        report['samples'].append(row)
        assert max(row['protected_matrix_error'], new['cap_binding_error'], new['grip_error'], new['arm_length_error']) < 1e-5
        assert new['maximum_arm_reach'] < .71 - 1e-5
        assert abs((pose['grips']['R'] - pose['grips']['L']).length - .145) < 1e-6
        if .40 <= q <= .625:
            assert row['all_bone_difference'] == 0., ('Changed frozen load/contact/hold', q)
    stage = 'seam-checks'
    for q in (.625, 1.):
        last_phase = q
        middle = apply(motion.sample('mine', q))
        for h in (.001, .0005):
            left = apply(motion.sample('mine', q-h))
            right = apply(motion.sample('mine', q+h))
            # Native phase slopes differ before/after the mining-cycle seam.
            left_seconds = h * (.68 * (1.-.42) / (1.-.55))
            right_seconds = h * (.68 * .42 / .55) if q == 1. else left_seconds
            report['seams'].append({'phase': q, 'phase_step': h,
                'left_seconds': left_seconds, 'right_seconds': right_seconds,
                'left_matrices': {n: [list(r) for r in m] for n, m in left.items()},
                'middle_matrices': {n: [list(r) for r in m] for n, m in middle.items()},
                'right_matrices': {n: [list(r) for r in m] for n, m in right.items()},
                'left_matrix_error': matrix_error(left, middle, left),
                'right_matrix_error': matrix_error(right, middle, right)})
    zero = apply(motion.sample('mine', 0.))
    end = apply(motion.sample('mine', 1.))
    report['endpoint_all_bone_error'] = matrix_error(zero, end, zero)
    assert report['endpoint_all_bone_error'] == 0.
    idle = apply(control.sample('idle', 0.))
    report['rest_tool_matrix_error_vs_original_idle'] = matrix_error(zero, idle, ['tool'])
    assert report['rest_tool_matrix_error_vs_original_idle'] < 1e-6
    report['passed_geometry'] = True
    save('complete-return-progress.json')
    stage = 'native-renders'
    render_cases = [('candidate', q) for q in (0., .40, .55, .6875, .75, .875, .96875)]
    render_cases += [('control', .75), ('control', .96875)]
    for label, q in render_cases:
        last_phase = q
        apply((motion if label == 'candidate' else control).sample('mine', q))
        env['blink'](0.)
        for modifier in env['skin']:
            modifier.show_viewport = True
        bpy.context.view_layer.update()
        key = f'{label}-{round(q*1000000):06}'
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
        report['renders'].append({'variant': label, 'phase': q, 'png': png.name,
                                  'png_sha256': sha(png), 'mask': mask.name, 'mask_sha256': sha(mask)})
        save('complete-return-progress.json')
    stage, last_phase = 'closing-bindings', None
    for relative, digest in source_hashes.items():
        assert sha(ROOT / relative) == digest, relative
    report.update(complete=True, rendered=True)
    save('complete-return-final.json')
    print('COMPLETE_RETURN_CLOSED', len(report['samples']), len(report['renders']), flush=True)
except Exception as error:
    report.update(complete=False, rejected=True, failure=str(error), failure_stage=stage,
                  failure_phase=last_phase, traceback=traceback.format_exc())
    save('complete-return-rejected.json')
    raise
