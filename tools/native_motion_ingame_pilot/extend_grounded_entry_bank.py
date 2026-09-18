"""Replace only the studied first-entry clip, reusing verified native images.

The original07 bank and119-frame route are immutable inputs. Predict the exact
new83-cell route before capture; every permitted cell must have a real image.
The13 matching09 preview poses are reused, and only its missing endpoint is
rendered. All other state images retain their exact original bytes.
"""
import argparse,copy,hashlib,json,runpy,shutil,subprocess,sys
from pathlib import Path
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
ROOT=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
NAME='walk_to_mine-625000'
p=argparse.ArgumentParser(description=__doc__)
for n in ('native-tools','pivot','reference','bank-report','preview','recorded','output'):
    p.add_argument('--'+n,type=Path,required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);assert not a.output.exists();a.output.mkdir(parents=True)
out=a.output/'worn';out.mkdir()
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(a.bank_report)=='1b200676de36637d41798e05aeefcae6d7072fe63ce5ee8dc808986685b08e2c'
assert sha(a.reference)=='9c55037f59bceaa2424a2d5c23744964f5b2da10d32994ee8814d0422dddd940'
assert sha(a.recorded)=='65528376612e44c37311775b1df1833e900c5a5a4b3aa1d84fda6f807f733ad0'
assert sha(a.pivot)=='cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
old=json.loads(a.reference.read_text());bank=json.loads(a.bank_report.read_text())
preview=json.loads((a.preview/'report.json').read_text());recorded=json.loads(a.recorded.read_text())
assert bank['complete'] and bank['passed_geometry'] and old['loop_flow_study']['report_sha256']==sha(a.bank_report)
assert preview['complete'] and len(preview['renders'])==19 and recorded['passed'] and len(recorded['samples'])==119
assert sha(bpy.data.filepath)==bank['model_sha256'] and sha(a.native_tools/'worn/hero.blend')==bank['gear_sha256']
sources=dict(bank['source_hashes']);sources.update(preview['source_hashes'])
for path in (Path(__file__),HERE/'grounded_entry_transition.py'):sources[str(path.relative_to(ROOT))]=sha(path)
for path,h in sources.items():assert sha(ROOT/path)==h,path
r={'complete':False,'visual_accepted':False,'production_accepted':False,
   'source_sha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
   'source_hashes':sources,'reference_manifest_sha256':sha(a.reference),'reference_report_sha256':sha(a.recorded),
   'reference_bank_report_sha256':sha(a.bank_report),'preview_report_sha256':sha(a.preview/'report.json'),
   'scope':'One recorded entry;83 planned route cells only. Other inputs and states remain unaccepted.',
   'entry_frames':[],'planned_draws':[]}
def save():(a.output/'report.json').write_text(json.dumps(r,indent=2)+'\n')
sys.argv=['blender','--','--native-tools',str(a.native_tools),'--output',str(a.output/'setup'),
          '--gear','worn','--direction','up','--native-motion-pilot','--native-states','idle',
          '--native-loop-counts','idle=1','--validate-only','--threads','2']
env=runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'));sys.path.insert(0,str(HERE))
from body_weight_motion import BodyWeightMotion
from grounded_entry_transition import GroundedEntryTransition
import native_motion as native
args=[json.loads((HERE/'working-surface-selection.json').read_text()),json.loads((HERE/'upper-body-hinge-selection.json').read_text()),json.loads(a.pivot.read_text())]
motion=BodyWeightMotion(*args,contact_turn=True);clip=GroundedEntryTransition(motion,.625)
env['view']('up',(6,6));scene,rig,camera=env['s'],env['r'],env['c']
times=[i/60 for i in range(13)]+[clip.duration];phases=[t/clip.duration for t in times]
def project(v):
    p=world_to_camera_view(scene,camera,Vector(v));return Vector((p.x*160,(1-p.y)*160))
def apply(pose):
    for mod in env['skin']:mod.show_viewport=False
    p=dict(pose);p['head']=p['head']@env['head_offset'];env['apply'](p)
    return {b.name:b.matrix.copy() for b in rig.pose.bones}
r['projection']={'origin':list(project((0,0,0))),
                 'basis':[list(project(v)-project((0,0,0))) for v in ((1,0,0),(0,1,0),(0,0,1))],
                 'scope':'Original orthographic camera,160px packed cell; affine native point projection'}
try:
    m=copy.deepcopy(old)
    m['states'][NAME].update(count=len(times),phases=phases)
    m['directions']['up']['transitions'][NAME]=clip.metadata()
    # The old native and pixel offsets are the same retained plant. Their timing
    # moves into the baked upper-body bridge until the later canonical handoff.
    old_meta=old['directions']['up']['transitions'][NAME]
    assert clip.metadata()['destination_offset_native']==old_meta['destination_offset_native']
    m['directions']['up']['transitions'][NAME]['destination_offset_pixels']=old_meta['destination_offset_pixels']
    new_frames=[]
    prototype=next(f for f in old['frames'] if f['state']==NAME)
    for index,t in enumerate(times):
        lower=apply(clip.lower_pose(t));pose=clip.sample(t);matrices=apply(pose)
        protected=max(abs(matrices[n][x][y]-lower[n][x][y]) for n in ('root','hips','thigh.R','shin.R','foot.R','thigh.L','shin.L','foot.L') for x in range(4) for y in range(4))
        grip=max((((matrices['hand.'+s]@rig.data.bones['hand.'+s].matrix_local.inverted())@env['rest']['grips'][s])-pose['grips'][s]).length for s in ('R','L'))
        length=max(abs((rig.pose.bones[n].tail-rig.pose.bones[n].head).length-rig.data.bones[n].length) for n in ('upper.R','lower.R','upper.L','lower.L','thigh.R','shin.R','thigh.L','shin.L'))
        assert max(protected,grip,length)<1e-5,(index,protected,grip,length)
        name=f'grounded-entry-{index:03d}';png=out/(name+'.png');mask=out/('mask-'+name+'-0001.png')
        if index<13:
            prior=preview['renders'][index]
            assert abs(prior['seconds']-t)<1e-12 and sha(a.preview/prior['path'])==prior['sha256']
            shutil.copyfile(a.preview/prior['path'],png)
            shutil.copyfile(a.preview/('mask-'+Path(prior['path']).stem+'-0001.png'),mask)
            provenance='Verified09 actual native pose at identical elapsed time'
        else:
            env['blink'](0.)
            for mod in env['skin']:mod.show_viewport=True
            bpy.context.view_layer.update()
            scene.render.filepath=str(png);env['mask'].base_path=str(out);env['mask'].file_slots[0].path='mask-'+name+'-';scene.frame_current=1
            bpy.ops.render.render(write_still=True)
            provenance='New actual07load endpoint with retained lower-body offset'
        frame=copy.deepcopy(prototype)
        frame.update(index=index,phase=phases[index],time=t,path=png.name,mask=mask.name,png_sha256=sha(png),mask_sha256=sha(mask),
                     native=native.frame_metadata(pose,motion.ground),contacts=pose['contacts'],ground_root_pixels=0.)
        new_frames.append(frame)
        r['entry_frames'].append({'index':index,'seconds':t,'provenance':provenance,'png_sha256':sha(png),'mask_sha256':sha(mask),
                                  'protected_lower_error':protected,'grip_error':grip,'limb_length_error':length})
    m['frames']=[];offset=0
    for state,info in m['states'].items():
        info['offset']=offset;offset+=info['count']
        frames=new_frames if state==NAME else [f for f in old['frames'] if f['state']==state]
        if state!=NAME:
            for f in frames:
                for key,hkey in [('path','png_sha256'),('mask','mask_sha256')]:
                    source=a.reference.parent/f[key];assert sha(source)==f[hkey];shutil.copyfile(source,out/f[key])
        m['frames'].extend(frames)
    assert len(m['frames'])==224
    old_frames={(f['state'],f['index']):f for f in old['frames']}
    candidates={(f['state'],f['index']):f for f in m['frames']}
    valid=set(old['loop_flow_study']['rendered_cells'])
    valid={s for s in valid if not s.startswith(NAME+':')}|{f'{NAME}:{i}' for i in range(14)}
    active=started=False;incoming=None;incoming_retained=None;allowed=set()
    for i,sample in enumerate(recorded['samples']):
        v=sample['visual'];state=v['state'];index=v['local_frame'];q=v['requested_phase'];placement=Vector(v['sprite_position']);retained=Vector(v['retained_offset'])
        if not started and state==NAME:
            active=started=True;incoming=Vector(v['sprite_position']);incoming_retained=retained.copy()
        if active and sample['mining_elapsed']>=clip.duration:active=False
        if active:
            state=NAME;q=sample['mining_elapsed']/clip.duration
            index=min(range(len(phases)),key=lambda j:abs(phases[j]-q));placement=incoming.copy();retained=incoming_retained.copy()
        cell=f'{state}:{index}';assert cell in valid,cell;allowed.add(cell)
        before=old_frames[(v['state'],v['local_frame'])];after=candidates[(state,index)]
        feet=[]
        for side in ('R','L'):
            for point in ('ankle','sole_point'):
                left=project(before['native']['feet'][side][point])+Vector(v['sprite_position'])
                right=project(after['native']['feet'][side][point])+placement
                error=(left-right).length
                assert error<.0002,(i,side,point,error)
                feet.append({'side':side,'point':point,'before':list(left),'after':list(right),'error_pixels':error})
        r['planned_draws'].append({'sample':i,'state':state,'local_frame':index,'requested_phase':q,'sample_phase':after['phase'],
                                   'sprite_position':list(placement),'retained_offset':list(retained),'entry_active':active,'changed_selection':(state,index)!=(v['state'],v['local_frame']),
                                   'projected_lower_body_points':feet})
    assert len(allowed)==83 and len(r['planned_draws'])==119
    r.update(complete=True,entry_duration=clip.duration,rendered_cells=sorted(allowed),valid_rendered_cells=sorted(valid),
             replaced_clip=NAME,reused_preview_frames=13,newly_rendered_frames=1)
    for path,h in sources.items():assert sha(ROOT/path)==h,path
    save()
    m['historical_render_fingerprint']=m['render_fingerprint'];m['render_fingerprint']=sha(a.output/'report.json')
    m['render_provenance']=sources
    m['loop_flow_study'].update(report_sha256=sha(a.output/'report.json'),rendered_cells=sorted(allowed),grounded_entry_study=True,
                                reference_report_sha256=sha(a.recorded),entry_duration=clip.duration,replaced_clip=NAME,
                                visual_accepted=False,production_accepted=False)
    (out/'pilot-manifest.json').write_text(json.dumps(m,indent=2)+'\n')
    print('GROUNDED_ENTRY_BANK_COMPLETE',len(allowed),len(m['frames']),flush=True)
except Exception as e:
    r.update(rejected=True,error=str(e));save();raise
