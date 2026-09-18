"""Render one closed +25 degree Worn/up experiment, never a production bank.

Preflight all reference poses and bridges on the original rig. Re-render changed
cells presented by the actual route; reuse exact unchanged poses. Every other
cell remains forbidden in the existing capture guard.
"""
import argparse
import copy
import hashlib
import json
import math
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import traceback
import bpy
from mathutils import Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
p = argparse.ArgumentParser(description=__doc__)
for name in ('native-tools', 'pivot', 'reference', 'pose-report', 'recorded', 'output'):
    p.add_argument('--'+name, type=Path, required=True)
a = p.parse_args(sys.argv[sys.argv.index('--')+1:])
assert not a.output.exists(), 'Use a fresh output directory'
a.output.mkdir(parents=True)
out = a.output/'worn'
out.mkdir()
sha = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
stage = 'binding'
report = {'complete':False, 'passed_geometry':False, 'rendered':False,
          'visual_accepted':False, 'production_accepted':False, 'angle_degrees':25,
          'frame_checks':[], 'transitions':{}, 'rendered_cells':[],
          'changed_rendered_cells':[], 'reused_cells':[], 'retained_unusable_cells':[]}


def save():
    (a.output/'report.json').write_text(json.dumps(report,indent=2)+'\n')


def apply(pose):
    for modifier in env['skin']: modifier.show_viewport = False
    posed = dict(pose)
    posed['head'] = posed['head'] @ env['head_offset']
    env['apply'](posed)
    return {b.name:b.matrix.copy() for b in rig.pose.bones}


def difference(before,after,names=None):
    return max(abs(before[n][i][j]-after[n][i][j]) for n in (names or before)
               for i in range(4) for j in range(4))


def measure(pose,matrices):
    grip = max((((matrices['hand.'+s] @ rig.data.bones['hand.'+s].matrix_local.inverted())
                  @ env['rest']['grips'][s])-pose['grips'][s]).length for s in native.SIDES)
    length = max(abs((rig.pose.bones[n].tail-rig.pose.bones[n].head).length-rig.data.bones[n].length)
                 for n in ('upper.R','lower.R','upper.L','lower.L'))
    reach = max((c-b).length for b,elbow,c in pose['arms'].values())
    assert grip < 1e-5 and length < 1e-5 and reach < .70999, (grip,length,reach)
    return {'grip_error':grip,'arm_length_error':length,'maximum_arm_reach':reach}


def clips_for(provider):
    clips = {}
    for name,meta in reference['directions']['up']['transitions'].items():
        if name == 'mine_to_idle-523810':
            clips[name] = ShownPoseCancelTransition(provider,meta['source_phase'])
        elif meta.get('source_is_bridge',False):
            clips[name] = InterruptedReturnTransition(provider,clips[meta['source_state']],meta['source_state'],meta['source_phase'])
        else:
            clips[name] = provider.transition(meta['source_state'],meta['source_phase'],meta['target_state'])
    return clips


try:
    assert sha(a.pivot) == 'cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
    assert sha(a.pose_report) == '996ead7ae03620e4997b62f8789e2745fb591457f218172645340c1b5262c0a2'
    reference = json.loads(a.reference.read_text())
    saved = json.loads(a.pose_report.read_text())
    recorded = json.loads(a.recorded.read_text())
    assert reference['view_angle_study']['complete'] and reference['view_angle_study']['angle_degrees'] == 25
    assert recorded['passed'] and recorded['view_angle_probe'] and recorded['complete_return']
    selected = {(r['visual']['state'],r['visual']['local_frame']) for r in recorded['samples']}
    assert len(selected) == 76
    assert selected == {tuple((s.rsplit(':',1)[0],int(s.rsplit(':',1)[1]))) for s in reference['view_angle_study']['rendered_cells']}
    assert sha(bpy.data.filepath) == saved['model_sha256']
    assert sha(a.native_tools/'worn/hero.blend') == saved['gear_sha256']
    sources = dict(saved['source_hashes'])
    for path in (Path(__file__),HERE/'loop_flow_motion.py'):
        sources[str(path.relative_to(ROOT))] = sha(path)
    for path,digest in sources.items(): assert sha(ROOT/path) == digest, path
    report.update(source_sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
                  source_hashes=sources,inputs={str(v):sha(v) for v in (a.reference,a.pose_report,a.pivot,a.recorded)},
                  model_sha256=saved['model_sha256'],gear_sha256=saved['gear_sha256'])
    stage = 'scene-setup'
    sys.argv = ['blender','--','--native-tools',str(a.native_tools),'--output',str(a.output/'setup'),
                '--gear','worn','--direction','up','--native-motion-pilot','--native-states','idle',
                '--native-loop-counts','idle=1','--validate-only','--threads','2']
    env = runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'))
    sys.path.insert(0,str(HERE))
    from complete_return_motion import CompleteReturnMotion
    from loop_flow_motion import LoopFlowMotion
    from interrupted_return_motion import InterruptedReturnTransition
    from shown_pose_cancel_transition import ShownPoseCancelTransition
    import native_motion as native
    import premium_motion as pm
    surface = json.loads((HERE/'working-surface-selection.json').read_text())
    hinge = json.loads((HERE/'upper-body-hinge-selection.json').read_text())
    pivot = json.loads(a.pivot.read_text())
    old, motion = CompleteReturnMotion(surface,hinge,pivot),LoopFlowMotion(surface,hinge,pivot)
    report['selection'] = motion.selection()
    env['view']('up',(6,6))
    scene,rig,camera = env['s'],env['r'],env['c']
    target = Vector((0.,-.10,.98))
    camera.location = target+Matrix.Rotation(math.radians(25),3,'Z')@(camera.location-target)
    camera.rotation_euler = (target-camera.location).to_track_quat('-Z','Y').to_euler()
    bpy.context.view_layer.update()
    anchor = world_to_camera_view(scene,camera,Vector())
    assert max(abs(x-y) for x,y in zip([anchor.x*200,(1-anchor.y)*200],reference['directions']['up']['ground_anchor'])) < 1e-5
    old_clips,clips = clips_for(old),clips_for(motion)
    protected = ('root','hips','body','head','thigh.R','shin.R','foot.R','thigh.L','shin.L','foot.L')
    stage = 'transition-preflight'
    for name,clip in clips.items():
        assert clip.metadata() == old_clips[name].metadata(), name
        rows = []
        for k in range(73):
            elapsed = clip.duration*k/72
            before = apply(old_clips[name].sample(elapsed))
            pose = clip.sample(elapsed)
            after = apply(pose)
            row = {'elapsed':elapsed,**measure(pose,after),'protected_error':difference(before,after,protected)}
            assert row['protected_error'] < 1e-5, (name,row)
            if k in (0,72):
                expected = clip.source if k == 0 else pm.translate_pose(motion.sample(clip.target_state,clip.metadata()['destination_phase']),clip.destination_offset)
                row['endpoint_error'] = difference(after,apply(expected))
                assert row['endpoint_error'] < 1e-5, (name,row)
            rows.append(row)
        report['transitions'][name] = rows
    stage = 'cell-preflight'
    stored = {(r['state'],r['index']):r for r in saved['frame_checks']}
    poses = {}
    for prior in reference['frames']:
        state,q,index = prior['state'],prior['phase'],prior['index']
        before = apply(old_clips[state].sample(q*old_clips[state].duration) if state in clips else old.sample(state,q))
        expected = {n:Matrix(v) for n,v in stored[(state,index)]['candidate_matrices'].items()}
        assert difference(before,expected) < 1e-5, (state,index,'baseline reconstruction')
        pose = clips[state].sample(q*clips[state].duration) if state in clips else motion.sample(state,q)
        after = apply(pose)
        row = {'state':state,'phase':q,'index':index,**measure(pose,after),
               'protected_error':difference(before,after,protected),'all_bone_difference':difference(before,after),
               'candidate_matrices':{n:[list(r) for r in m] for n,m in after.items()}}
        assert row['protected_error'] < 1e-5, row
        poses[(state,index)] = pose
        report['frame_checks'].append(row)
    report['passed_geometry'] = True
    save()
    stage = 'render-changed-selected-cells'
    manifest = copy.deepcopy(reference)
    manifest['frames'] = []
    for prior,check in zip(reference['frames'],report['frame_checks']):
        state,q,index = prior['state'],prior['phase'],prior['index']
        key = (state,index)
        cell = '%s:%d' % key
        frame = copy.deepcopy(prior)
        if key in selected and check['all_bone_difference'] != 0.:
            pose = poses[key]
            apply(pose)
            env['blink'](0.)
            for modifier in env['skin']: modifier.show_viewport = True
            bpy.context.view_layer.update()
            name = 'loop-flow-%s-%03d' % key
            png,mask = out/(name+'.png'),out/('mask-'+name+'-0001.png')
            scene.render.filepath = str(png)
            env['mask'].base_path = str(out)
            env['mask'].file_slots[0].path = 'mask-'+name+'-'
            scene.frame_current = 1
            bpy.ops.render.render(write_still=True)
            frame.update(path=png.name,mask=mask.name,png_sha256=sha(png),mask_sha256=sha(mask),
                         native=native.frame_metadata(pose,motion.ground),contacts=pose['contacts'])
            report['changed_rendered_cells'].append(cell)
        else:
            for name,digest in (('path','png_sha256'),('mask','mask_sha256')):
                source = a.reference.parent/prior[name]
                assert sha(source) == prior[digest], source
                shutil.copyfile(source,out/source.name)
            report['reused_cells' if key in selected else 'retained_unusable_cells'].append(cell)
        if key in selected: report['rendered_cells'].append(cell)
        manifest['frames'].append(frame)
        save()
        print('LOOP_FLOW_CELL',cell,'new' if cell in report['changed_rendered_cells'] else 'reused',flush=True)
    assert len(manifest['frames']) == 218 and len(report['rendered_cells']) == 76
    for path,digest in sources.items(): assert sha(ROOT/path) == digest, path
    report.update(complete=True,rendered=True)
    save()
    manifest['historical_render_fingerprint'] = manifest['render_fingerprint']
    manifest['render_fingerprint'] = sha(a.output/'report.json')
    manifest['loop_flow_study'] = {'report_sha256':sha(a.output/'report.json'),'selection':motion.selection(),
                                  'visual_accepted':False,'production_accepted':False}
    manifest['view_angle_study']['rendered_cells'] = report['rendered_cells']
    manifest['render_provenance'] = report['source_hashes']
    manifest['motion']['full_input_coverage'] = False
    (out/'pilot-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('LOOP_FLOW_BANK_COMPLETE',len(report['changed_rendered_cells']),flush=True)
except Exception as error:
    report.update(rejected=True,failure_stage=stage,failure=str(error),traceback=traceback.format_exc())
    save()
    raise
