"""Append exactly one C0 late-cancel clip to the closed cross-shoulder bank.

All 206 earlier cells and their metadata remain unchanged. Only twelve cells
for the actually observed .5238095238 mine-to-idle source are rendered. The
closed 75-time native diagnosis is a prerequisite, not gameplay acceptance.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import os
import runpy
import shutil
import subprocess
import sys
import traceback
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser(description=__doc__)
for name in ('native-tools', 'pivot-report', 'reference-manifest', 'proof', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert not args.output.exists(), 'Use a fresh output directory'
args.output.mkdir(parents=True)
stage, current_phase = 'bindings', None
report = {'complete': False, 'rendered': False, 'passed_geometry': False,
          'frame_checks': [], 'rendered_frames': [], 'reused_frames': [],
          'visual_accepted': False, 'production_accepted': False,
          'scope': 'One C0 held-source late stop; original 206 cells unchanged. No actual input or publication approval.'}


def save(path, value):
    with path.open('w') as f:
        json.dump(value, f, indent=2)
        f.write('\n')
        f.flush()
        os.fsync(f.fileno())


def apply(pose):
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(pose)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    return {b.name: b.matrix.copy() for b in rig.pose.bones}


try:
    assert sha(args.reference_manifest) == '1546d3e7532794b9d7347909d06530d6c57e78c688918c3f21b9e0e7953599e8'
    assert sha(args.proof) == '5e83af66e1db2ddfcdb518550fa2177ce96aabe1693f2a3e6b720ab7d4e7a937'
    reference = json.loads(args.reference_manifest.read_text())
    proof = json.loads(args.proof.read_text())
    assert reference['rendered'] and len(reference['frames']) == 206
    assert proof['complete'] and proof['rendered'] and proof['passed_geometry']
    assert proof['projected_clear_at_sampled_points'] and len(proof['samples']) == 75
    assert proof['reference_sha256'] == sha(args.reference_manifest)
    assert proof['transition']['incoming_source_velocity_continuous'] is False
    sources = dict(reference['render_provenance']['source_hashes'])
    for relative, digest in proof['source_hashes'].items():
        assert relative not in sources or sources[relative] == digest
        sources[relative] = digest
    sources[str(Path(__file__).relative_to(ROOT))] = sha(Path(__file__))
    for relative, digest in sources.items():
        assert sha(ROOT / relative) == digest, relative
    assert sha(args.pivot_report) == reference['render_provenance']['pivot_report_sha256']
    surface = json.loads((HERE / 'working-surface-selection.json').read_text())
    hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
    pivot = json.loads(args.pivot_report.read_text())
    assert sha(Path(bpy.data.filepath)) == surface['model_sha256'] == proof['model_sha256']
    assert sha(args.native_tools / 'worn/hero.blend') == surface['gear_sha256'] == proof['gear_sha256']
    report.update(source_sha=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                  source_tree=subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=ROOT, text=True).strip(),
                  source_hashes=sources, reference_sha256=sha(args.reference_manifest),
                  proof_sha256=sha(args.proof))
    stage = 'scene-setup'
    sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
                '--output', str(args.output / 'scene-setup'), '--gear', 'worn',
                '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
                '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
    env = runpy.run_path(str(ROOT / 'tools/hero_v28/export_hero.py'))
    sys.path.insert(0, str(HERE))
    from cross_shoulder_load_motion import CrossShoulderLoadMotion
    from shown_pose_cancel_transition import ShownPoseCancelTransition
    import native_motion as native
    motion = CrossShoulderLoadMotion(surface, hinge, pivot)
    clip = ShownPoseCancelTransition(motion, proof['transition']['source_phase'])
    assert clip.metadata() == proof['transition']
    env['view']('up', (6, 6))
    scene, rig = env['s'], env['r']
    assert env['m']['directions']['up']['ground_anchor'] == reference['directions']['up']['ground_anchor']
    assert scene.render.resolution_x == scene.render.resolution_y == 200 and scene.cycles.samples == 8
    out = args.output / 'worn'
    out.mkdir()
    name = 'mine_to_idle-523810'
    assert name not in reference['states']
    phases = list(reference['states']['mine_to_idle-392857']['phases'])
    assert len(phases) == 12
    meta = clip.metadata()
    zero = world_to_camera_view(scene, env['c'], Vector())
    shifted = world_to_camera_view(scene, env['c'], clip.destination_offset)
    meta['destination_offset_pixels'] = [(shifted.x-zero.x)*160, -(shifted.y-zero.y)*160]
    report['transition'] = meta
    stage = 'cell-preflight'
    poses = []
    source_soles = {s: Vector(proof['samples'][0]['native']['feet'][s]['sole_point']) for s in native.SIDES}
    for index, phase in enumerate(phases):
        current_phase = phase
        pose = clip.sample(phase * clip.duration)
        matrices = apply(pose)
        grip = max((((matrices['hand.' + s] @ rig.data.bones['hand.' + s].matrix_local.inverted())
                     @ env['rest']['grips'][s]) - pose['grips'][s]).length for s in native.SIDES)
        length = max(abs((rig.pose.bones[n].tail - rig.pose.bones[n].head).length - rig.data.bones[n].length)
                     for n in ('upper.R', 'lower.R', 'upper.L', 'lower.L'))
        reach = max((c-a).length for a, b, c in pose['arms'].values())
        feet = native.frame_metadata(pose, motion.ground)
        sole = max((Vector(feet['feet'][s]['sole_point']) - source_soles[s]).length for s in native.SIDES)
        assert grip < 1e-5 and length < 1e-5 and reach < .71 - 1e-5 and sole < 1e-5
        row = {'state': name, 'index': index, 'phase': phase, 'seconds': phase * clip.duration,
               'grip_error': grip, 'arm_length_error': length, 'maximum_arm_reach': reach,
               'sole_displacement': sole, 'native': feet,
               'arm_joints': {s: [list(v) for v in chain] for s, chain in pose['arms'].items()},
               'tool_skin_matrix': [list(r) for r in matrices['tool'] @ rig.data.bones['tool'].matrix_local.inverted()]}
        if index in (0, 11):
            expected = proof['samples'][0 if index == 0 else -1]['matrices']
            error = max(abs(matrices[n][i][j] - expected[n][i][j]) for n in matrices for i in range(4) for j in range(4))
            assert error < 1e-5
            row['proof_endpoint_matrix_error'] = error
        report['frame_checks'].append(row)
        poses.append(pose)
    report['passed_geometry'] = True
    stage = 'copy-existing-originals'
    m = copy.deepcopy(reference)
    m['rendered'] = False
    for frame in reference['frames']:
        for field, digest in [('path', 'png_sha256'), ('mask', 'mask_sha256')]:
            src = args.reference_manifest.parent / frame[field]
            assert sha(src) == frame[digest]
            shutil.copyfile(src, out / frame[field])
        report['reused_frames'].append({'state': frame['state'], 'index': frame['index'], 'png_sha256': frame['png_sha256'], 'mask_sha256': frame['mask_sha256']})
    m['states'][name] = {'offset': 206, 'count': 12, 'phases': phases, 'loop': False,
                         'duration_source': 'directions.<direction>.transitions.<state>.duration'}
    m['directions']['up']['transitions'][name] = meta
    m['motion'].update(frames_per_direction=218, full_input_coverage=False, production_approved=False)
    m['render_provenance']['source_hashes'] = sources
    m['render_provenance'].update(base_git_head=report['source_sha'], source_tree=report['source_tree'],
        reference_sha256=sha(args.reference_manifest), shown_pose_cancel_proof_sha256=sha(args.proof))
    m['render_fingerprint'] = hashlib.sha256((sha(args.reference_manifest) + sha(args.proof) + sha(Path(__file__))).encode()).hexdigest()
    m['shown_pose_cancel_extension'] = {'source_sha': report['source_sha'], 'proof_sha256': sha(args.proof),
        'reference_sha256': sha(args.reference_manifest), 'state': name,
        'reference_render_provenance': reference['render_provenance'],
        'continuity': 'C0; mining-source velocity interrupted at release',
        'reused_frames': 206, 'added_frames': 12, 'visual_accepted': False, 'production_accepted': False}
    stage = 'render'
    for index, (phase, pose) in enumerate(zip(phases, poses)):
        current_phase = phase
        apply(pose)
        env['blink'](0.)
        for modifier in env['skin']:
            modifier.show_viewport = True
        bpy.context.view_layer.update()
        key = f'up-shown-cancel-{index:03}'
        png, mask = out / (key + '.png'), out / ('mask-' + key + '-0001.png')
        scene.render.filepath = str(png)
        env['mask'].base_path = str(out)
        env['mask'].file_slots[0].path = 'mask-' + key + '-'
        scene.frame_current = 1
        bpy.ops.render.render(write_still=True)
        frame = {'direction': 'up', 'state': name, 'index': index, 'phase': phase, 'time': phase * clip.duration,
                 'path': png.name, 'mask': mask.name, 'png_sha256': sha(png), 'mask_sha256': sha(mask),
                 'native': report['frame_checks'][index]['native'], 'contacts': pose['contacts'],
                 'ground_root_pixels': pose['transition_metadata']['target_root_pixels']}
        m['frames'].append(frame)
        report['rendered_frames'].append(frame)
        save(args.output / 'shown-cancel-bank-progress.json', report)
        print('SHOWN_CANCEL_BANK_FRAME', index, flush=True)
    stage, current_phase = 'final-binding', None
    assert m['frames'][:206] == reference['frames'] and len(m['frames']) == 218
    for state in reference['states']:
        assert m['states'][state] == reference['states'][state]
    for state in reference['directions']['up']['transitions']:
        assert m['directions']['up']['transitions'][state] == reference['directions']['up']['transitions'][state]
    for relative, digest in sources.items():
        assert sha(ROOT / relative) == digest, relative
    for frame in m['frames']:
        for field, digest in [('path', 'png_sha256'), ('mask', 'mask_sha256')]:
            path = out / frame[field]
            assert sha(path) == frame[digest]
            with path.open('rb') as f:
                os.fsync(f.fileno())
    m['rendered'] = True
    save(out / 'pilot-manifest.json', m)
    report.update(complete=True, rendered=True, manifest_sha256=sha(out / 'pilot-manifest.json'))
    save(args.output / 'shown-cancel-bank-final.json', report)
    print('SHOWN_CANCEL_BANK_COMPLETE', 218, flush=True)
except Exception as error:
    report.update(complete=False, rejected=True, stage=stage, phase=current_phase,
                  failure=str(error), traceback=traceback.format_exc())
    save(args.output / 'shown-cancel-bank-rejected.json', report)
    raise
