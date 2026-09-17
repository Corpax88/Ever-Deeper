"""Five original native poses for one saved working-surface selection.

No production export, replay, asset replacement or ordinary-input claim.
"""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import subprocess
import sys
import bpy
from mathutils import Vector

parser = argparse.ArgumentParser()
parser.add_argument('--native-tools', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--source-sha', required=True)
parser.add_argument('--validate-only', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
selection_path = HERE/'working-surface-selection.json'
selection = json.loads(selection_path.read_text())
assert selection['visually_accepted'] is False
assert selection['phases'] == [.125, .375, .55, .625, .8125]
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip() == args.source_sha
assert not subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip(), 'Requires the saved clean checkpoint'
args.output.mkdir(parents=True,exist_ok=True)
sys.argv = ['blender','--','--native-tools',str(args.native_tools),'--output',str(args.output/'scene-load'),'--setup-only']
loaded = runpy.run_path(str(HERE/'probe_up_occlusion.py'))
sys.path.insert(0,str(HERE))
import working_surface_arc
env = loaded['env']
ground, target = Vector(selection['unchanged_ground']), Vector(selection['target_ground'])
contact = selection['contact']
assert (env['ground_vector']('up')-ground).length < 1e-8
assert loaded['report']['model_sha256'] == selection['model_sha256']
assert loaded['report']['gear_sha256'] == selection['gear_sha256']
files = sorted((ROOT/'tools/hero_v28').glob('*.py'))+[Path(__file__), selection_path, HERE/'working_surface_arc.py', HERE/'probe_up_occlusion.py']
source_hashes = {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
assert source_hashes['tools/native_motion_ingame_pilot/working_surface_arc.py'] == selection['pose_source_sha256']
fingerprint = hashlib.sha256(json.dumps({'source_hashes':source_hashes,'selection':selection},sort_keys=True).encode()).hexdigest()
rig, rest = env['r'], env['rest']
report = {'complete':False,'rendered':not args.validate_only,'source_sha':args.source_sha,
          'source_hashes':source_hashes,'fingerprint':fingerprint,'selection':selection,
          'blender':bpy.app.version_string,'dense_evaluated_poses':0,'max_grip_error':0.,
          'max_reach':0.,'complete_original_lower_body_retained':True,
          'native_gameplay_or_transition_coverage':False,'frames':[]}


def pose(q):
    p, original = working_surface_arc.sample(q,ground,target,contact)
    for key in ('legs','foot_rotations','contacts'): assert p[key] is original[key]
    assert env['native_motion'].frame_metadata(p,ground)['feet'] == env['native_motion'].frame_metadata(original,ground)['feet']
    for a,b,c in p['arms'].values(): report['max_reach'] = max(report['max_reach'],(c-a).length)
    posed = dict(p)
    posed['head'] = posed['head']@env['head_offset']
    env['apply'](posed)
    grip = max(((rig.pose.bones['hand.'+s].matrix@rig.data.bones['hand.'+s].matrix_local.inverted())@rest['grips'][s]-p['grips'][s]).length for s in ('R','L'))
    assert grip < 1e-5
    report['max_grip_error'] = max(report['max_grip_error'],grip)
    return p


for modifier in env['skin']: modifier.show_viewport = False
for q in sorted(set([i/128 for i in range(129)]+[.24,.4,.55,.575,.625,.68,.82])):
    pose(q)
    report['dense_evaluated_poses'] += 1
assert report['dense_evaluated_poses'] == 135
for index,q in enumerate(selection['phases']):
    for modifier in env['skin']: modifier.show_viewport = False
    p = pose(q)
    env['blink'](0.)
    for modifier in env['skin']: modifier.show_viewport = True
    bpy.context.view_layer.update()
    key = f'up-working-surface-{index:02}-q{round(q*1000000):06}'
    frame = {'index':index,'phase':q,'path':key+'.png','mask':'mask-'+key+'-0001.png',
             'native':env['native_motion'].frame_metadata(p,ground),'rear':list(p['rear']),
             'axis':list(p['axis']),'tool_normal':list(p['tool_normal'])}
    if not args.validate_only:
        env['s'].render.filepath = str(args.output/frame['path'])
        env['mask'].base_path = str(args.output)
        env['mask'].file_slots[0].path = 'mask-'+key+'-'
        env['s'].frame_current = 1
        bpy.ops.render.render(write_still=True)
        frame['png_sha256'] = hashlib.sha256((args.output/frame['path']).read_bytes()).hexdigest()
        frame['mask_sha256'] = hashlib.sha256((args.output/frame['mask']).read_bytes()).hexdigest()
    report['frames'].append(frame)
    (args.output/'working-surface-probe.json').write_text(json.dumps(report,indent=2)+'\n')
report['complete'] = True
(args.output/'working-surface-probe.json').write_text(json.dumps(report,indent=2)+'\n')
print('WORKING_SURFACE_PROBE_COMPLETE',len(report['frames']),report['max_grip_error'],flush=True)
