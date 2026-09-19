"""Reject one lateral contact proposal analytically, then render at most3poses."""
import argparse,hashlib,json,runpy,subprocess,sys
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE),str(ROOT/'tools/hero_v28')]
from body_weight_motion import BodyWeightMotion
from contact_clearance_motion import ContactClearanceMotion
from loop_flow_motion import native_phase
import premium_motion as pm
p=argparse.ArgumentParser(description=__doc__)
for n in ('native-tools','pivot','output'):p.add_argument('--'+n,type=Path,required=True)
p.add_argument('--render',action='store_true')
p.add_argument('--lower-contact',action='store_true')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);assert not a.output.exists();a.output.mkdir(parents=True)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(bpy.data.filepath)=='94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert sha(a.native_tools/'worn/hero.blend')=='0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
assert sha(a.pivot)=='cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
args=[json.loads((HERE/'working-surface-selection.json').read_text()),json.loads((HERE/'upper-body-hinge-selection.json').read_text()),json.loads(a.pivot.read_text())]
old=BodyWeightMotion(*args,contact_turn=True);new=ContactClearanceMotion(*args)
if a.lower_contact:
    from lower_contact_motion import LowerContactMotion
    new=LowerContactMotion(*args)
paths=[Path(__file__),HERE/'contact_clearance_motion.py',HERE/'body_weight_motion.py',HERE/'side_return_motion.py',HERE/'loop_flow_motion.py',ROOT/'tools/hero_v28/export_hero.py',ROOT/'tools/hero_v28/native_pose.py',ROOT/'tools/hero_v28/native_motion.py',ROOT/'tools/hero_v28/premium_motion.py']
if a.lower_contact:paths.append(HERE/'lower_contact_motion.py')
r={'complete':False,'passed_geometry':False,'visual_accepted':False,'production_accepted':False,
   'source_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
   'source_hashes':{str(p.relative_to(ROOT)):sha(p) for p in paths},
   'selection':new.selection(),'scope':'One contact-local trial;401clock samples plus exact knots; at most3native stills. Not a game bank or temporal approval.',
   'samples':[],'renders':[]}
r['cap_rule']='Exact prescribed lower-contact translation' if a.lower_contact else 'Original cap centroid fixed'
def save():(a.output/'report.json').write_text(json.dumps(r,indent=2)+'\n')
try:
    for q in sorted({native_phase(i/400) for i in range(401)}|{.40,.50,.55,.625,.70,.86}):
        before,after=old.sample('mine',q),new.sample('mine',q)
        cap=lambda pose:pose['rear']+pm.tool_frame(pose['axis'],pose['tool_normal'])@new.local_cap
        expected_shift=new.contact_offset(q) if a.lower_contact else cap(before)*0.
        cap_error=(cap(before)+expected_shift-cap(after)).length
        if a.lower_contact:
            assert max((before[n]-after[n]).length for n in ('axis','tool_normal'))<2e-6
        body_error=max(abs(before[n][i][j]-after[n][i][j]) for n in ('torso','head') for i in range(4) for j in range(4))
        legs_error=max((v-w).length for side in ('R','L') for v,w in zip(before['legs'][side],after['legs'][side]))
        feet_error=max(abs(before['foot_rotations'][s][i][j]-after['foot_rotations'][s][i][j]) for s in ('R','L') for i in range(3) for j in range(3))
        lengths=max(abs((b-a).length-u) for chain in after['arms'].values() for a,b,u in zip(chain,chain[1:],(.36,.35)))
        reach=max((w-s).length for s,e,w in after['arms'].values())
        assert max(cap_error,body_error,legs_error,feet_error,lengths)<2e-6,(q,cap_error,body_error,legs_error,feet_error,lengths)
        assert reach<.70,(q,reach,'Conservative10mm arm-extension margin')
        if q<=.40 or q>=(.86 if a.lower_contact else .70):
            assert max((before[n]-after[n]).length for n in ('rear','axis','tool_normal'))<1e-7
        r['samples'].append({'phase':q,'cap_error':cap_error,'expected_cap_shift':list(expected_shift),'actual_cap_shift':list(cap(after)-cap(before)),'protected_error':max(body_error,legs_error,feet_error),'arm_length_error':lengths,'max_arm_reach':reach})
    r['passed_geometry']=True;save()
    if a.render:
        sys.argv=['blender','--','--native-tools',str(a.native_tools),'--output',str(a.output/'setup'),'--gear','worn','--direction','up','--native-motion-pilot','--native-states','idle','--native-loop-counts','idle=1','--validate-only','--threads','2']
        env=runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'));env['view']('up',(6,6));scene,rig=env['s'],env['r']
        def apply(pose):
            for mod in env['skin']:mod.show_viewport=False
            posed=dict(pose);posed['head']=posed['head']@env['head_offset'];env['apply'](posed)
            return {b.name:b.matrix.copy() for b in rig.pose.bones}
        for q in (.50,.55,.625):
            expected=apply(old.sample('mine',q));pose=new.sample('mine',q);actual=apply(pose)
            # The tool and its optional child bit intentionally rotate rigidly.
            protected=[n for n in expected if n not in ('upper.R','lower.R','hand.R','upper.L','lower.L','hand.L','tool','bit')]
            error=max(abs(actual[n][i][j]-expected[n][i][j]) for n in protected for i in range(4) for j in range(4))
            grip=max((((actual['hand.'+s]@rig.data.bones['hand.'+s].matrix_local.inverted())@env['rest']['grips'][s])-pose['grips'][s]).length for s in ('R','L'))
            length=max(abs((rig.pose.bones[n].tail-rig.pose.bones[n].head).length-rig.data.bones[n].length) for n in ('upper.R','lower.R','upper.L','lower.L'))
            actual_frame=(actual['tool'].to_3x3()@rig.data.bones['tool'].matrix_local.to_3x3().inverted()
                          @pm.tool_frame(env['rest']['axis'],env['rest']['tool_normal']))
            actual_cap=actual['tool'].translation+actual_frame@new.local_cap
            before=old.sample('mine',q)
            old_cap=before['rear']+pm.tool_frame(before['axis'],before['tool_normal'])@new.local_cap
            if a.lower_contact:old_cap+=new.contact_offset(q)
            actual_cap_error=(actual_cap-old_cap).length
            assert max(error,grip,length,actual_cap_error)<1e-5,(q,error,grip,length,actual_cap_error)
            env['blink'](0.)
            for mod in env['skin']:mod.show_viewport=True
            bpy.context.view_layer.update();name=f'contact-{round(q*1000):03d}';png=a.output/(name+'.png')
            scene.render.filepath=str(png);env['mask'].base_path=str(a.output);env['mask'].file_slots[0].path='mask-'+name+'-';scene.frame_current=1
            bpy.ops.render.render(write_still=True)
            r['renders'].append({'phase':q,'path':png.name,'sha256':sha(png),'protected_rig_error':error,'grip_error':grip,'length_error':length,'actual_tool_cap_error':actual_cap_error});save()
    for p,h in r['source_hashes'].items():assert sha(ROOT/p)==h,p
    r['complete']=True;save();print('CONTACT_CLEARANCE_COMPLETE',len(r['samples']),len(r['renders']),flush=True)
except Exception as e:
    r.update(rejected=True,error=str(e));save();raise
