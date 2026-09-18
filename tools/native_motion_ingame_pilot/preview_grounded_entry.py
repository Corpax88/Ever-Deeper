"""Render the first direct-entry study through the original first contact time."""
import argparse,hashlib,json,runpy,subprocess,sys
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
p=argparse.ArgumentParser(description=__doc__)
for n in ('native-tools','pivot','output'):p.add_argument('--'+n,type=Path,required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);assert not a.output.exists();a.output.mkdir(parents=True)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(bpy.data.filepath)=='94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert sha(a.native_tools/'worn/hero.blend')=='0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
assert sha(a.pivot)=='cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
source_paths=[Path(__file__),HERE/'grounded_entry_transition.py',HERE/'body_weight_motion.py',HERE/'side_return_motion.py',HERE/'loop_flow_motion.py']
source_paths += [ROOT/'tools/hero_v28'/n for n in ('native_pose.py','native_motion.py','premium_motion.py')]
r={'complete':False,'visual_accepted':False,'production_accepted':False,
   'scope':'19 actual native poses through the first contact; last interval is2.2667ms, not a uniform-fps video. No gameplay or temporal acceptance.',
   'source_base':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
   'source_hashes':{str(p.relative_to(ROOT)):sha(p) for p in source_paths},'renders':[]}
sys.argv=['blender','--','--native-tools',str(a.native_tools),'--output',str(a.output/'setup'),
          '--gear','worn','--direction','up','--native-motion-pilot','--native-states','idle',
          '--native-loop-counts','idle=1','--validate-only','--threads','2']
env=runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'))
sys.path.insert(0,str(HERE))
from body_weight_motion import BodyWeightMotion
from grounded_entry_transition import GroundedEntryTransition
args=[json.loads((HERE/'working-surface-selection.json').read_text()),json.loads((HERE/'upper-body-hinge-selection.json').read_text()),json.loads(a.pivot.read_text())]
motion=BodyWeightMotion(*args,contact_turn=True);clip=GroundedEntryTransition(motion,.625)
r['metadata']=clip.metadata()
env['view']('up',(6,6));scene,rig=env['s'],env['r']
def apply(pose):
    for m in env['skin']:m.show_viewport=False
    p=dict(pose);p['head']=p['head']@env['head_offset'];env['apply'](p)
    return {b.name:b.matrix.copy() for b in rig.pose.bones}
try:
    for i,t in enumerate([j/60 for j in range(18)]+[.42*.68]):
        lower=clip.lower_pose(t)
        expected=apply(lower)
        pose=clip.sample(t) if t<=clip.duration else clip._canonical(t)
        actual=apply(pose)
        protected=max(abs(actual[n][x][y]-expected[n][x][y]) for n in ('root','hips','thigh.R','shin.R','foot.R','thigh.L','shin.L','foot.L') for x in range(4) for y in range(4))
        grip=max((((actual['hand.'+s]@rig.data.bones['hand.'+s].matrix_local.inverted())@env['rest']['grips'][s])-pose['grips'][s]).length for s in ('R','L'))
        length=max(abs((rig.pose.bones[n].tail-rig.pose.bones[n].head).length-rig.data.bones[n].length) for n in ('upper.R','lower.R','upper.L','lower.L','thigh.R','shin.R','thigh.L','shin.L'))
        assert max(protected,grip,length)<1e-5,(i,t,protected,grip,length)
        env['blink'](0.)
        for m in env['skin']:m.show_viewport=True
        bpy.context.view_layer.update()
        name=f'entry-{i:03d}';png=a.output/(name+'.png')
        scene.render.filepath=str(png);env['mask'].base_path=str(a.output);env['mask'].file_slots[0].path='mask-'+name+'-';scene.frame_current=1
        bpy.ops.render.render(write_still=True)
        r['renders'].append({'index':i,'seconds':t,'mining_phase':clip.phase_at('mine',0.,t),'entry_active':t<=clip.duration,
                             'path':png.name,'sha256':sha(png),'protected_lower_error':protected,'grip_error':grip,'limb_length_error':length})
        (a.output/'report.json').write_text(json.dumps(r,indent=2)+'\n')
        print('GROUNDED_ENTRY_FRAME',i,t,flush=True)
    for p,h in r['source_hashes'].items():assert sha(ROOT/p)==h,p
    r['complete']=True
finally:(a.output/'report.json').write_text(json.dumps(r,indent=2)+'\n')
