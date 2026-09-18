"""One held-source C0 cancellation from the actually shown late-windup pose.

This compares one shown-pose source against the closed continuing-source diagnosis.
It deliberately stops incoming velocity; the target idle clock still advances.
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
import traceback
import sys
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser()
for name in ('native-tools', 'pivot-report', 'reference-manifest', 'recorded',
             'cap-proof', 'bank-result', 'control', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert not args.output.exists(), 'Use a fresh output directory'
args.output.mkdir(parents=True)
stage, last_seconds = 'source-bindings', None
source_hashes, rows, endpoint_errors = {}, [], []
report = {'complete': False, 'passed_geometry': False, 'rendered': False,
          'samples': rows, 'endpoint_matrix_errors': endpoint_errors, 'renders': [],
          'actual_cancel_gameplay_run': False, 'visual_accepted': False,
          'production_accepted': False}

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
    arm_error = max(abs((rig.pose.bones[n].tail - rig.pose.bones[n].head).length - rig.data.bones[n].length)
                    for n in ('upper.R', 'lower.R', 'upper.L', 'lower.L'))
    reach = max((c-a).length for a, b, c in pose['arms'].values())
    assert arm_error < 1e-5 and reach < .71 - 1e-5
    projected = []
    for a, b, c in triangles:
        va, vb, vc = (skin @ rest_vertices[i] for i in (a, b, c))
        for i in range(5):
            for j in range(5 - i):
                projected.append(project(va * (i / 4.) + vb * (j / 4.) + vc * (1. - (i + j) / 4.)))
    alphas = [alpha(p) for p in projected]
    return {'cap_centroid': list(center), 'cap_centroid_screen': project(center),
            'cap_binding_error': error, 'grip_error': grip_error,
            'arm_length_error': arm_error, 'maximum_arm_reach': reach,
            'arm_joints': {s: [list(v) for v in chain] for s, chain in pose['arms'].items()},
            'matrices': {n: [list(r) for r in m] for n, m in matrices.items()},
            'cap_samples': len(alphas), 'max_ore_alpha': max(alphas),
            'ore_overlap_samples': sum(a > .5 for a in alphas),
            'tool_skin_matrix': [list(row) for row in skin],
            'native': native.frame_metadata(pose, motion.ground)}


try:
    assert sha(args.reference_manifest) == '1546d3e7532794b9d7347909d06530d6c57e78c688918c3f21b9e0e7953599e8'
    assert sha(args.recorded) == '7af8b241fef765da879bc5c3429130e493c0126827e0f7fef448549fce15558a'
    assert sha(args.cap_proof) == '3da98249b71b0d05053ef0f30e4def8b6007b0650cd7aaf2078b89a592233f2e'
    assert sha(args.bank_result) == '7062e9d1c23ed7d5a2ac0b8494a64ae3e65ca1e4ff6a62cb3e35d71f1a109962'
    report.update(source_sha=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                  recorded_sha256=sha(args.recorded), reference_sha256=sha(args.reference_manifest),
                  cap_proof_sha256=sha(args.cap_proof), bank_result_sha256=sha(args.bank_result))
    assert sha(args.control) == 'bae5f87341c7cc24b6253a285be594a0435c40412929a23258a86aa563dad48a'
    control_report = json.loads(args.control.read_text())
    assert control_report['complete'] and control_report['passed_geometry'] and control_report['rendered']
    assert not control_report['projected_clear_at_sampled_points']
    report['unchanged_transition_control_sha256'] = sha(args.control)
    reference = json.loads(args.reference_manifest.read_text())
    recorded = json.loads(args.recorded.read_text())
    cap_proof = json.loads(args.cap_proof.read_text())
    bank_result = json.loads(args.bank_result.read_text())
    assert len(reference['frames']) == 206 and reference['rendered'] and bank_result['complete']
    assert recorded['source_sha'] == '97131ba7ea3a97bf443f19d6b938ce31bb2f0731'
    assert recorded['passed'] and recorded['cross_shoulder_load']
    draw = recorded['samples'][49]
    next_draw = recorded['samples'][50]
    assert draw == control_report['source_draw']
    assert draw['visual']['state'] == 'mine' and not draw['visual']['is_bridge']
    assert draw['target_hp'] == 950 and draw['relative_impact_serial'] == 0
    assert abs(draw['mining_elapsed'] - 17 / 60) < 1e-12
    assert next_draw['visual']['presenting_impact'] and next_draw['target_hp'] == 946
    assert next_draw['relative_physics_tick'] == draw['relative_physics_tick'] + 1
    phase = reference['states']['mine']['phases'][draw['visual']['local_frame']]
    assert abs(phase - draw['visual']['sample_phase']) < 1e-12
    assert abs(phase - .5238095238095238) < 1e-12
    assert sha(args.pivot_report) == reference['render_provenance']['pivot_report_sha256']
    source_hashes = dict(reference['render_provenance']['source_hashes'])
    source_hashes[str(Path(__file__).relative_to(ROOT))] = sha(Path(__file__))
    helper = HERE / 'shown_pose_cancel_transition.py'
    source_hashes[str(helper.relative_to(ROOT))] = sha(helper)
    for relative, digest in source_hashes.items():
        assert sha(ROOT / relative) == digest, relative
    source_cell = next(f for f in reference['frames'] if f['state'] == 'mine' and f['index'] == draw['visual']['local_frame'])
    source_check = next(f for f in bank_result['frame_checks'] if f['state'] == 'mine' and f['index'] == draw['visual']['local_frame'])
    assert sha(args.reference_manifest.parent / source_cell['path']) == source_cell['png_sha256']
    assert sha(args.recorded.parent / recorded['captures'][49]['path']) == recorded['captures'][49]['sha256']
    surface = json.loads((HERE / 'working-surface-selection.json').read_text())
    hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
    pivot = json.loads(args.pivot_report.read_text())
    assert sha(Path(bpy.data.filepath)) == surface['model_sha256']
    assert sha(args.native_tools / 'worn/hero.blend') == surface['gear_sha256']
    texture = ROOT / 'assets/endless/node-deep-alloy-v1.png'
    assert sha(texture) == cap_proof['ore_texture_sha256']
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
    from cross_shoulder_load_motion import CrossShoulderLoadMotion
    from shown_pose_cancel_transition import ShownPoseCancelTransition
    import native_motion as native
    import premium_motion as pm

    stage = 'motion-and-transition-setup'
    motion = CrossShoulderLoadMotion(surface, hinge, pivot)
    clip = ShownPoseCancelTransition(motion, phase)
    env['view']('up', (6, 6))
    scene, camera, rig = env['s'], env['c'], env['r']
    assert env['m']['directions']['up']['ground_anchor'] == reference['directions']['up']['ground_anchor']
    assert scene.render.resolution_x == scene.render.resolution_y == 200
    assert scene.cycles.samples == 8 and abs(clip.duration - .12) < 1e-12
    triangle_ids = cap_proof['cap_triangle_ids']
    triangles = cap_proof['cap_triangles']
    rest_vertices = {int(i): Vector(v) for i, v in cap_proof['cap_rest_vertices'].items()}
    rest_center = Vector(cap_proof['cap_rest_center'])
    local_cap = Vector(surface['working_surface']['surface_center_tool_local'])
    tool_bind_inverse = rig.data.bones['tool'].matrix_local.inverted()
    stage = 'endpoint-checks'
    for t in (0., clip.duration):
        last_seconds = t
        actual = apply(clip.sample(t))
        expected_pose = (motion.sample('mine', phase) if t == 0. else
                         pm.translate_pose(motion.sample('idle', clip.metadata()['destination_phase']), clip.destination_offset))
        expected = apply(expected_pose)
        error = max(abs(actual[n][i][j] - expected[n][i][j]) for n in actual for i in range(4) for j in range(4))
        assert error < 1e-5
        endpoint_errors.append(error)
    stage, last_seconds = 'contact-control', None
    control = measure(motion.sample('mine', .55))
    report['positive_contact_control'] = control
    assert control['max_ore_alpha'] > .5, 'Positive contact control must hit the same captured ore alpha'
    nominal_seconds_to_damage_threshold = .68 * .42 - draw['mining_elapsed']
    represented_pose_remaining_to_contact = (.55 - phase) / .55 * .68 * .42
    assert 0. < nominal_seconds_to_damage_threshold < 1 / 60
    stage, last_seconds = 'source-bank-binding', 0.
    source_measured = measure(clip.sample(0.))
    source_tool_matrix_error = max(abs(source_measured['tool_skin_matrix'][i][j] - source_check['tool_skin_matrix'][i][j]) for i in range(4) for j in range(4))
    assert source_tool_matrix_error < 1e-5
    for side in native.SIDES:
        for actual, expected in zip(source_measured['arm_joints'][side], source_check['arm_joints'][side]):
            assert (Vector(actual) - Vector(expected)).length < 1e-5
    source_soles = {s: Vector(source_measured['native']['feet'][s]['sole_point']) for s in native.SIDES}
    times = sorted({i / 600 for i in range(73)} | {1 / 60, 2 / 60, 4 / 60, 5 / 60, 7 / 60,
                    nominal_seconds_to_damage_threshold, represented_pose_remaining_to_contact})
    stage = 'dense-measurement'
    for t in times:
        last_seconds = t
        rows.append({'seconds': t, 'source_phase': clip.phase_at('mine', phase, t),
                     'source_weight': 1. - native.gait.smoother(t / clip.body_duration),
                     **measure(clip.sample(t))})
    assert [r['seconds'] for r in rows] == [r['seconds'] for r in control_report['samples']]
    endpoint_control_errors = []
    for row, old_row in ((rows[0], control_report['samples'][0]), (rows[-1], control_report['samples'][-1])):
        error = max(abs(row['matrices'][n][i][j] - old_row['matrices'][n][i][j])
                    for n in row['matrices'] for i in range(4) for j in range(4))
        assert error < 1e-5
        endpoint_control_errors.append(error)
    report['original_transition_endpoint_errors'] = endpoint_control_errors
    max_sole_displacement = max((Vector(row['native']['feet'][s]['sole_point']) - source_soles[s]).length
                                for row in rows for s in native.SIDES)
    assert max_sole_displacement < 1e-5
    report.update({'complete': False, 'passed_geometry': True, 'rendered': False, 'source_sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'source_hashes': source_hashes, 'recorded_sha256': sha(args.recorded),
              'reference_sha256': sha(args.reference_manifest), 'cap_proof_sha256': sha(args.cap_proof),
              'bank_result_sha256': sha(args.bank_result), 'source_cell': source_cell,
              'source_tool_matrix_error': source_tool_matrix_error, 'max_sole_displacement': max_sole_displacement,
              'nominal_seconds_to_damage_threshold': nominal_seconds_to_damage_threshold,
              'next_observed_damage_tick_seconds': 1 / 60,
              'represented_pose_remaining_to_contact': represented_pose_remaining_to_contact,
              'ore_texture_sha256': sha(texture), 'model_sha256': surface['model_sha256'],
              'gear_sha256': surface['gear_sha256'], 'source_draw': draw,
              'transition': clip.metadata(), 'cap_triangle_ids': triangle_ids,
              'cap_triangles': triangles, 'cap_rest_vertices': {str(i): list(v) for i, v in rest_vertices.items()},
              'cap_rest_center': list(rest_center), 'endpoint_matrix_errors': endpoint_errors,
              'positive_contact_control': control, 'samples': rows, 'renders': [],
              'actual_cancel_gameplay_run': False, 'visual_accepted': False, 'production_accepted': False,
              'projected_clear_at_sampled_points': all(r['max_ore_alpha'] <= .5 for r in rows),
              'scope': 'One C0 held-source late cancel from captured sample49, last real draw before damage50. Dense native cap samples against frozen draw49 ore alpha; '
                       'no alpha filtering, occlusion, physical 3D collision, moving ore, controller input or publication approval. '
                       'Original native isolated images follow; runtime and bank are unchanged.'})
    stage = 'render'
    for label, t in [('source', 0.), ('middle', .05), ('next-draw', 1 / 60), ('idle-end', clip.duration)]:
        last_seconds = t
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
        print('SHOWN_POSE_CANCEL_FRAME', label, flush=True)
    stage, last_seconds = 'final-source-binding', None
    for relative, digest in source_hashes.items():
        assert sha(ROOT / relative) == digest, relative
    report['complete'] = True
    report['stage'] = 'complete'
    report['rendered'] = True
    with (args.output / 'shown-pose-cancel-final.json').open('w') as f:
        json.dump(report, f, indent=2)
        f.write('\n')
        f.flush()
        os.fsync(f.fileno())
    print('SHOWN_POSE_CANCEL_COMPLETE', report['projected_clear_at_sampled_points'], flush=True)
except Exception as error:
    failed = dict(report)
    failed.update(complete=False, rejected=True, stage=stage, failure=str(error),
                  traceback=traceback.format_exc(), source_hashes=source_hashes,
                  last_seconds=last_seconds, samples=rows,
                  endpoint_matrix_errors=endpoint_errors)
    with (args.output / 'shown-pose-cancel-rejected.json').open('w') as f:
        json.dump(failed, f, indent=2)
        f.write('\n')
        f.flush()
        os.fsync(f.fileno())
    raise
