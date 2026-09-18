"""Three existing poses at one higher native rendering quality.

No motion, camera, geometry, material or game-size change. This diagnoses
sampling blur separately from actual occlusion; it is not a new motion bank.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import runpy
import subprocess
import sys
import bpy

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser()
for name in ('native-tools', 'pivot-report', 'reference-manifest', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert not args.output.exists()
reference = json.loads(args.reference_manifest.read_text())
assert reference['rendered'] and len(reference['frames']) == 92
assert sha(args.pivot_report) == reference['render_provenance']['pivot_report_sha256']
for relative, digest in reference['render_provenance']['source_hashes'].items():
    assert sha(ROOT / relative) == digest, relative
surface = json.loads((HERE / 'working-surface-selection.json').read_text())
hinge = json.loads((HERE / 'upper-body-hinge-selection.json').read_text())
pivot = json.loads(args.pivot_report.read_text())
assert sha(Path(bpy.data.filepath)) == surface['model_sha256']
assert sha(args.native_tools / 'worn/hero.blend') == surface['gear_sha256']
packed = json.loads((HERE / 'assets/worn/manifest.json').read_text())
assert packed['directions']['up']['ground_anchor'] == [v * .8 for v in reference['directions']['up']['ground_anchor']]
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--output', str(args.output / 'scene-setup'), '--gear', 'worn',
            '--direction', 'up', '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT / 'tools/hero_v28/export_hero.py'))
sys.path.insert(0, str(HERE))
from return_tool_offset_motion import FrozenReturnMotion
import native_motion as native

motion = FrozenReturnMotion(surface, hinge, pivot)
env['view']('up', (6, 6))
scene, rig = env['s'], env['r']
assert env['m']['directions']['up']['ground_anchor'] == reference['directions']['up']['ground_anchor']
scene.render.resolution_x = scene.render.resolution_y = 400
scene.cycles.samples = 32
report = {'complete': False, 'motion_changed': False, 'runtime_changed': False,
          'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
          'reference_manifest_sha256': sha(args.reference_manifest),
          'observer_sha256': sha(Path(__file__)),
          'source_hashes': reference['render_provenance']['source_hashes'],
          'model_sha256': surface['model_sha256'], 'gear_sha256': surface['gear_sha256'],
          'old_raster': [200, 200], 'old_cycles_samples': 8,
          'new_raster': [400, 400], 'new_cycles_samples': 32,
          'denoise': scene.cycles.use_denoising, 'final_comparison_cell': [160, 160],
          'packed_ground_anchor_unchanged': packed['directions']['up']['ground_anchor'],
          'transition_offsets_unchanged': {name: v['destination_offset_pixels'] for name, v in
                                         packed['directions']['up']['transitions'].items()},
          'scope': 'Three existing native poses, later downsampled to the same160px cell. '
                   'Higher sampling cannot reveal physically hidden hands/tool. No production approval.',
          'frames': []}
for label, phase in [('windup', .130952380952381), ('contact', .55), ('return', .813793103448276)]:
    matches = [f for f in reference['frames'] if f['state'] == 'mine' and abs(f['phase'] - phase) < 1e-10]
    assert len(matches) == 1
    prior = matches[0]
    assert sha(args.reference_manifest.parent / prior['path']) == prior['png_sha256']
    assert sha(args.reference_manifest.parent / prior['mask']) == prior['mask_sha256']
    pose = motion.sample('mine', prior['phase'])
    assert native.frame_metadata(pose, motion.ground) == prior['native']
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(pose)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    env['blink'](0.)
    grip_error = max((((rig.pose.bones['hand.' + side].matrix @ rig.data.bones['hand.' + side].matrix_local.inverted())
                       @ env['rest']['grips'][side]) - pose['grips'][side]).length for side in native.SIDES)
    assert grip_error < 1e-5
    for modifier in env['skin']:
        modifier.show_viewport = True
    bpy.context.view_layer.update()
    png = args.output / (label + '-400.png')
    mask = args.output / ('mask-' + label + '-0001.png')
    scene.render.filepath = str(png)
    env['mask'].base_path = str(args.output)
    env['mask'].file_slots[0].path = 'mask-' + label + '-'
    scene.frame_current = 1
    bpy.ops.render.render(write_still=True)
    for file in (png, mask):
        with file.open('rb') as f:
            os.fsync(f.fileno())
    report['frames'].append({'label': label, 'phase': prior['phase'], 'grip_error': grip_error,
        'reference_frame': prior, 'color': png.name, 'color_sha256': sha(png),
        'cloth': mask.name, 'cloth_sha256': sha(mask)})
    (args.output / 'quality-progress.json').write_text(json.dumps(report, indent=2) + '\n')
    print('RETURN_QUALITY_FRAME', label, flush=True)
for relative, digest in report['source_hashes'].items():
    assert sha(ROOT / relative) == digest
report['complete'] = True
with (args.output / 'quality-final.json').open('w') as file:
    file.write(json.dumps(report, indent=2) + '\n')
    file.flush()
    os.fsync(file.fileno())
print('RETURN_QUALITY_COMPLETE', sha(args.output / 'quality-final.json'), flush=True)
