"""Build only the91cell recorded route for contact13/grounded exit14."""
import argparse,copy,hashlib,json,runpy,shutil,subprocess,sys
from pathlib import Path
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
ROOT=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE),str(ROOT/'tools/hero_v28')]
from body_weight_motion import BodyWeightMotion
from contact_roll_motion import ContactRollMotion
from grounded_entry_transition import GroundedEntryTransition
from grounded_exit_transition import GroundedExitTransition
from forearm_frame_pose import align_right_forearm
import native_motion as native
NAME='mine_to_walk-625000';ENTRY='walk_to_mine-625000'
p=argparse.ArgumentParser(description=__doc__)
for n in ('native-tools','pivot','reference','recorded','contact-proof','exit-proof','output'):
    p.add_argument('--'+n,type=Path,required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);assert not a.output.exists();a.output.mkdir(parents=True)
out=a.output/'worn';out.mkdir()
sha=lambda x:hashlib.sha256(Path(x).read_bytes()).hexdigest()
assert sha(a.reference)=='dac5af7ff97782e2eb8bb7b5bcffc55e4948632a8c1972935d397cec67030ef4'
assert sha(a.recorded)=='d0a9b21b7159f6d1540b147ec5dd7f754df3ebf36684a1514d00167d54c2b61c'
assert sha(a.pivot)=='cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
assert sha(bpy.data.filepath)=='94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert sha(a.native_tools/'worn/hero.blend')=='0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
reference=json.loads(a.reference.read_text());recorded=json.loads(a.recorded.read_text())
assert recorded['passed'] and len(recorded['samples'])==119
sources=dict(reference['render_provenance'])
for proof_path in (a.contact_proof,a.exit_proof):
    proof=json.loads(proof_path.read_text());assert proof['complete'] and proof['passed_geometry'] and len(proof['renders'])==3
    for path,h in proof['source_hashes'].items():assert sha(ROOT/path)==h,path
    sources.update(proof['source_hashes'])
for path,h in sources.items():assert sha(ROOT/path)==h,path
sources[str(Path(__file__).relative_to(ROOT))]=sha(__file__)
for path in (HERE/'pilot_visual.gd',HERE/'capture.gd'):
    sources[str(path.relative_to(ROOT))]=sha(path)
inputs=[json.loads((HERE/n).read_text()) for n in ('working-surface-selection.json','upper-body-hinge-selection.json')]+[json.loads(a.pivot.read_text())]
old=BodyWeightMotion(*inputs,contact_turn=True);motion=ContactRollMotion(*inputs)
oldclips={ENTRY:GroundedEntryTransition(old,.625),NAME:old.transition('mine',.625,'walk'),
          'idle_to_walk-055556':old.transition('idle',.055556,'walk')}
clips={ENTRY:GroundedEntryTransition(motion,.625),NAME:GroundedExitTransition(motion),
       'idle_to_walk-055556':motion.transition('idle',.055556,'walk')}
assert clips[NAME].destination_offset.length<1e-8, 'Only the zero-offset recorded exit is supported'
# Resolve the original exact idle source phase from the reference metadata.
for provider,dest in ((old,oldclips),(motion,clips)):
    meta=reference['directions']['up']['transitions']['idle_to_walk-055556']
    dest['idle_to_walk-055556']=provider.transition('idle',meta['source_phase'],'walk')
times=[i/60 for i in range(14)]+[clips[NAME].duration]
m=copy.deepcopy(reference);m['states'][NAME].update(count=len(times),phases=[t/clips[NAME].duration for t in times])
meta=clips[NAME].metadata();meta['destination_offset_pixels']=reference['directions']['up']['transitions'][NAME]['destination_offset_pixels']
m['directions']['up']['transitions'][NAME]=meta
r={'complete':False,'visual_accepted':False,'production_accepted':False,
   'source_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
   'source_hashes':sources,'reference_manifest_sha256':sha(a.reference),'reference_report_sha256':sha(a.recorded),
   'contact_proof_sha256':sha(a.contact_proof),'exit_proof_sha256':sha(a.exit_proof),
   'scope':'Only91cells on the119frame original09route. Other cells are retained but forbidden; no production adoption.',
   'planned_draws':[],'frame_checks':[],'rendered_cells':[],'retained_forbidden_cells':[]}
def save():(a.output/'report.json').write_text(json.dumps(r,indent=2)+'\n')
allowed=set()
for i,sample in enumerate(recorded['samples']):
    v=sample['visual'];state,index=v['state'],v['local_frame']
    if 95<=i<108:state,index=NAME,i-94
    allowed.add(f'{state}:{index}')
    r['planned_draws'].append({'sample':i,'state':state,'index':index,'original_state':v['state'],
                              'original_index':v['local_frame'],'sprite_position':v['sprite_position'],
                              'retained_offset':v['retained_offset']})
assert len(allowed)==91
oldframes={(f['state'],f['index']):f for f in reference['frames']}
frames=[];offset=0
for state,info in m['states'].items():
    info['offset']=offset;offset+=info['count']
    if state==NAME:
        prototype=next(f for f in reference['frames'] if f['state']==NAME)
        for index,t in enumerate(times):
            f=copy.deepcopy(prototype);f.update(index=index,time=t,phase=t/clips[NAME].duration);frames.append(f)
    else:frames.extend(copy.deepcopy(f) for f in reference['frames'] if f['state']==state)
assert len(frames)==229
sys.argv=['blender','--','--native-tools',str(a.native_tools),'--output',str(a.output/'setup'),
          '--gear','worn','--direction','up','--native-motion-pilot','--native-states','idle',
          '--native-loop-counts','idle=1','--validate-only','--threads','2']
env=runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'));env['view']('up',(6,6));scene,rig=env['s'],env['r']
def apply(pose,correct):
    for mod in env['skin']:mod.show_viewport=False
    pp=dict(pose);pp['head']=pp['head']@env['head_offset'];env['apply'](pp)
    if correct:align_right_forearm(rig,env['rest'],pose)
    return {b.name:b.matrix.copy() for b in rig.pose.bones}
def difference(x,y):return max(abs(x[i][j]-y[i][j]) for i in range(4) for j in range(4))
def project(v):
    p=world_to_camera_view(scene,env['c'],Vector(v));return Vector((p.x*160,(1-p.y)*160))
poses={};checks={}
try:
    for f in frames:
        state,index,q=f['state'],f['index'],f['phase'];cell=f'{state}:{index}'
        if cell not in allowed:continue
        if state==NAME:
            lower,lowerstate,lowerindex=clips[NAME].quantized_lower_pose(times[index],reference)
            pose=clips[NAME].sample(times[index],lower_override=lower)
            before=apply(lower,False)
        else:
            prior=oldclips[state].sample(q*oldclips[state].duration) if state in oldclips else old.sample(state,q)
            pose=clips[state].sample(q*clips[state].duration) if state in clips else motion.sample(state,q)
            before=apply(prior,False);lowerstate,lowerindex=state,index
        matrices=apply(pose,True)
        protected=['root','hips','thigh.R','shin.R','foot.R','thigh.L','shin.L','foot.L']
        if state!=NAME:protected+=['body','head']
        error=max(difference(before[n],matrices[n]) for n in protected)
        grip=max((((matrices['hand.'+s]@rig.data.bones['hand.'+s].matrix_local.inverted())@env['rest']['grips'][s])-pose['grips'][s]).length for s in ('R','L'))
        length=max(abs((rig.pose.bones[n].tail-rig.pose.bones[n].head).length-rig.data.bones[n].length) for n in ('upper.R','lower.R','upper.L','lower.L','thigh.R','shin.R','thigh.L','shin.L'))
        reach=max((v[2]-v[0]).length for v in pose['arms'].values())
        assert max(error,grip,length)<1e-5 and reach<.70,(cell,error,grip,length,reach)
        f['native']=native.frame_metadata(pose,motion.ground);f['contacts']=pose['contacts']
        row=dict(cell=cell,protected_matrix_error=error,grip_error=grip,limb_length_error=length,max_arm_reach=reach,
                 original_lower_cell=[lowerstate,lowerindex])
        r['frame_checks'].append(row);checks[cell]=row;poses[cell]=pose
    lookup={(f['state'],f['index']):f for f in frames}
    for draw in r['planned_draws']:
        prior=oldframes[(draw['original_state'],draw['original_index'])]
        candidate=lookup[(draw['state'],draw['index'])]
        error=max((project(prior['native']['feet'][s][point])-project(candidate['native']['feet'][s][point])).length
                  for s in ('R','L') for point in ('ankle','sole_point'))
        assert error<.0002,(draw['sample'],error)
        draw['projected_lower_point_error']=error
    r['passed_geometry']=True;save()
    for f in frames:
        state,index=f['state'],f['index'];cell=f'{state}:{index}'
        if cell in allowed:
            pose=poses[cell];apply(pose,True)
            blink_time=f['phase']*3.6
            env['blink'](max(env['blink_at'](blink_time,.40),env['blink_at'](blink_time,3.13)) if state=='idle' else 0.)
            for mod in env['skin']:mod.show_viewport=True
            bpy.context.view_layer.update();name=f'contact-exit-{state}-{index:03d}'
            png,mask=out/(name+'.png'),out/('mask-'+name+'-0001.png')
            scene.render.filepath=str(png);env['mask'].base_path=str(out);env['mask'].file_slots[0].path='mask-'+name+'-';scene.frame_current=1
            bpy.ops.render.render(write_still=True)
            f.update(path=png.name,mask=mask.name,png_sha256=sha(png),mask_sha256=sha(mask))
            r['rendered_cells'].append(cell)
        else:
            # New forbidden exit endpoints have no inherited image identity;
            # placeholders stay forbidden and are explicitly recorded as such.
            prior=oldframes.get((state,index),oldframes[(NAME,9)])
            for key,hkey in (('path','png_sha256'),('mask','mask_sha256')):
                source=a.reference.parent/prior[key];assert sha(source)==prior[hkey]
                shutil.copyfile(source,out/source.name);f[key]=source.name;f[hkey]=prior[hkey]
            r['retained_forbidden_cells'].append(cell)
        save();print('CONTACT_EXIT_CELL',cell,'rendered' if cell in allowed else 'forbidden',flush=True)
    for path,h in sources.items():assert sha(ROOT/path)==h,path
    assert set(r['rendered_cells'])==allowed
    r['complete']=True;save()
    m['frames']=frames;m['historical_render_fingerprint']=m['render_fingerprint'];m['render_fingerprint']=sha(a.output/'report.json')
    m['render_provenance']=sources;m['motion']['full_input_coverage']=False
    m['motion']['frames_per_direction']=len(frames)
    m['loop_flow_study'].update(report_sha256=sha(a.output/'report.json'),rendered_cells=sorted(allowed),
        selection=motion.selection(),forearm_frame_study=True,grounded_exit_study=True,
        exit_duration=clips[NAME].duration,lower_exit_duration=clips[NAME].lower.duration,
        contact_exit_reference_report_sha256=sha(a.recorded),visual_accepted=False,production_accepted=False)
    (out/'pilot-manifest.json').write_text(json.dumps(m,indent=2)+'\n')
    print('CONTACT_EXIT_BANK_COMPLETE',len(allowed),len(frames),flush=True)
except Exception as e:
    r.update(rejected=True,error=str(e));save();raise
