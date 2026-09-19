"""Preflight one220ms upper exit and render only three diagnostic poses."""
import argparse,hashlib,json,runpy,subprocess,sys
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE),str(ROOT/'tools/hero_v28')]
from contact_roll_motion import ContactRollMotion
from grounded_exit_transition import GroundedExitTransition
from forearm_frame_pose import align_right_forearm
import premium_motion as pm
p=argparse.ArgumentParser(description=__doc__)
for n in ('native-tools','pivot','reference','output'):p.add_argument('--'+n,type=Path,required=True)
p.add_argument('--render',action='store_true')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);assert not a.output.exists();a.output.mkdir(parents=True)
sha=lambda x:hashlib.sha256(Path(x).read_bytes()).hexdigest()
assert sha(bpy.data.filepath)=='94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert sha(a.native_tools/'worn/hero.blend')=='0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
assert sha(a.reference)=='dac5af7ff97782e2eb8bb7b5bcffc55e4948632a8c1972935d397cec67030ef4'
assert sha(a.pivot)=='cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
reference=json.loads(a.reference.read_text())
inputs=[json.loads((HERE/n).read_text()) for n in ('working-surface-selection.json','upper-body-hinge-selection.json')]+[json.loads(a.pivot.read_text())]
motion=ContactRollMotion(*inputs);clip=GroundedExitTransition(motion)
files=[Path(__file__),HERE/'grounded_exit_transition.py',HERE/'grounded_entry_transition.py',HERE/'forearm_frame_pose.py',HERE/'contact_roll_motion.py',HERE/'lower_contact_motion.py',HERE/'body_weight_motion.py',HERE/'return_tool_offset_motion.py',ROOT/'tools/hero_v28/native_motion.py',ROOT/'tools/hero_v28/native_pose.py',ROOT/'tools/hero_v28/export_hero.py']
r={'complete':False,'visual_accepted':False,'production_accepted':False,
   'source_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
   'source_hashes':{str(f.relative_to(ROOT)):sha(f) for f in files},
   'reference_manifest_sha256':sha(a.reference),'metadata':clip.metadata(),
   'scope':'Continuous geometry plus three original-quantized lower-body native poses; no runtime or temporal approval',
   'samples':[],'renders':[]}
def save():(a.output/'report.json').write_text(json.dumps(r,indent=2)+'\n')
def difference(x,y):return max(abs(x[i][j]-y[i][j]) for i in range(4) for j in range(4))
try:
    # Independently bind sprite-local lower endpoint to canonical walking.
    canonical=pm.translate_pose(motion.sample('walk',clip.lower.phase_at('walk',clip.lower.target_phase,clip.lower.duration)),clip.lower.destination_offset)
    lower_end=clip.lower.sample(clip.lower.duration)
    r['lower_handoff_error']=max(difference(lower_end['torso'],canonical['torso']),
        max((lower_end['legs'][s][i]-canonical['legs'][s][i]).length for s in ('R','L') for i in range(3)))
    assert r['lower_handoff_error']<1e-5
    for i in range(401):
        t=clip.duration*i/400;pose=clip.sample(t);lower=clip.lower_pose(t)
        reach=max((chain[2]-chain[0]).length for chain in pose['arms'].values())
        legs=max((pose['legs'][s][j]-lower['legs'][s][j]).length for s in ('R','L') for j in range(3))
        assert reach<.70 and legs<1e-5,(t,reach,legs)
        r['samples'].append({'seconds':t,'max_arm_reach':reach,'lower_leg_error':legs})
    r['endpoint_errors']=[]
    for t,target in ((0.,clip.source),(clip.duration,clip.destination)):
        pose=clip.sample(t)
        error=max(difference(pose['torso'],target['torso']),difference(pose['head'],target['head']),
                  max((pose[n]-target[n]).length for n in ('rear','axis','tool_normal')))
        assert error<1e-5,(t,error);r['endpoint_errors'].append(error)
    r['passed_geometry']=True;save()
    if a.render:
        sys.argv=['blender','--','--native-tools',str(a.native_tools),'--output',str(a.output/'setup'),'--gear','worn','--direction','up','--native-motion-pilot','--native-states','idle','--native-loop-counts','idle=1','--validate-only','--threads','2']
        env=runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'));env['view']('up',(6,6));scene,rig=env['s'],env['r']
        def apply(pose):
            for m in env['skin']:m.show_viewport=False
            pp=dict(pose);pp['head']=pp['head']@env['head_offset'];env['apply'](pp)
            check=align_right_forearm(rig,env['rest'],pose)
            return {b.name:b.matrix.copy() for b in rig.pose.bones},check
        for t in (.05,7/60,.20):
            lower,state,index=clip.quantized_lower_pose(t,reference)
            before,_=apply(lower);pose=clip.sample(t,lower_override=lower);actual,forearm=apply(pose)
            protected=('root','hips','thigh.R','shin.R','foot.R','thigh.L','shin.L','foot.L')
            error=max(difference(before[n],actual[n]) for n in protected)
            grip=max((((actual['hand.'+s]@rig.data.bones['hand.'+s].matrix_local.inverted())@env['rest']['grips'][s])-pose['grips'][s]).length for s in ('R','L'))
            assert max(error,grip)<1e-5,(t,error,grip)
            env['blink'](0.)
            for m in env['skin']:m.show_viewport=True
            bpy.context.view_layer.update();name=f'exit-{round(t*1000):03d}';png=a.output/(name+'.png')
            scene.render.filepath=str(png);env['mask'].base_path=str(a.output);env['mask'].file_slots[0].path='mask-'+name+'-';scene.frame_current=1
            bpy.ops.render.render(write_still=True)
            r['renders'].append({'seconds':t,'path':png.name,'sha256':sha(png),'original_lower_cell':[state,index],
                                 'protected_lower_rig_error':error,'grip_error':grip,'forearm':forearm});save()
    for f,h in r['source_hashes'].items():assert sha(ROOT/f)==h,f
    r['complete']=True;save();print('GROUNDED_EXIT_COMPLETE',len(r['samples']),len(r['renders']),flush=True)
except Exception as e:
    r.update(rejected=True,error=str(e));save();raise
