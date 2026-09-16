"""Export the approved native Gruvepappa v28 with the existing real tool motion."""
import bpy, sys, math, json, argparse, hashlib
from pathlib import Path
from mathutils import Vector, Matrix
from bpy_extras.object_utils import world_to_camera_view
ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
import motion_v9, motion_v3, premium_motion, locomotion, native_motion
from native_pose import create_applier
from eyelids import create_blink
from hero_expression_v7 import blink_at

ap=argparse.ArgumentParser()
ap.add_argument('--native-tools',type=Path,required=True)
ap.add_argument('--output',type=Path,required=True)
ap.add_argument('--gear',default='iron',choices=list(motion_v3.PROFILES))
ap.add_argument('--review',action='store_true')
ap.add_argument('--premium-pilot',action='store_true')
ap.add_argument('--gait-pilot',action='store_true')
ap.add_argument('--native-motion-pilot',action='store_true')
ap.add_argument('--native-speed',type=float,default=340.)
ap.add_argument('--gameplay-mine-cycle',type=float,default=.68)
ap.add_argument('--gameplay-hit-phase',type=float,default=.42)
ap.add_argument('--native-states',default='idle,walk,mine,idle_to_walk,walk_to_idle,walk_to_mine,mine_to_walk,mine_to_idle')
ap.add_argument('--native-loop-counts',default='',help='Bounded pilot samples, e.g. idle=1,walk=16,mine=16')
ap.add_argument('--transition-phases',default='0,.125,.25,.375,.5,.625,.75,.875')
ap.add_argument('--transition-fps',type=float,default=60.)
ap.add_argument('--validate-only',action='store_true')
ap.add_argument('--direction',default='all')
ap.add_argument('--threads',type=int,default=2)
a=ap.parse_args(sys.argv[sys.argv.index('--')+1:])
assert sum((a.premium_pilot,a.gait_pilot,a.native_motion_pilot)) <= 1
assert not (a.review and a.native_motion_pilot), 'Native motion pilot uses genuine 200px frames'
assert a.native_speed>0 and a.transition_fps>0
s=bpy.context.scene;r=bpy.data.objects['EverDeeper_Hero_Rig'];kind=a.gear;family=motion_v3.PROFILES[kind]['family']
out=a.output/kind;out.mkdir(parents=True,exist_ok=True)
template=ROOT.parent.parent/'assets/hero/dad'/kind/'manifest.json'
fingerprint=hashlib.sha256(b''.join(p.read_bytes() for p in sorted(ROOT.glob('*.py')))+Path(bpy.data.filepath).read_bytes()+(ROOT/'gear_profiles.json').read_bytes()+(a.native_tools/kind/'hero.blend').read_bytes()+template.read_bytes()+str((a.review,a.premium_pilot,a.gait_pilot,a.native_motion_pilot,a.native_speed,a.native_states,a.native_loop_counts,a.transition_phases,a.transition_fps,a.direction,a.gameplay_mine_cycle,a.gameplay_hit_phase)).encode()).hexdigest()
stamp=out/'render-config.sha256'
if stamp.exists():assert stamp.read_text()==fingerprint,'Output belongs to a different render configuration'
else:stamp.write_text(fingerprint)
head_offset=r.pose.bones['head'].matrix@r.data.bones['head'].matrix_local.inverted()
r.animation_data_clear()
for b in r.pose.bones:b.matrix_basis=Matrix.Identity(4)
for o in list(s.objects):
 if o.type=='MESH' and any(g.name.startswith('hand.') or g.name in ['tool','bit'] for g in o.vertex_groups):
  bpy.data.objects.remove(o,do_unlink=True)
bpy.context.view_layer.update()
base_meshes=[o for o in s.objects if o.type=='MESH']
old_rest={b.name:b.matrix_local.copy() for b in r.data.bones}
with bpy.data.libraries.load(str(a.native_tools/kind/'hero.blend'),link=False) as (src,dst):dst.objects=src.objects
loaded=[o for o in dst.objects if o]
source_rig=next(o for o in loaded if o.type=='ARMATURE')
new_bones={b.name:(b.matrix_local.copy(),b.length) for b in source_rig.data.bones}
keep=[]
for o in loaded:
 if o.type=='MESH' and any(g.name.startswith('hand.') or g.name in ['tool','bit'] for g in o.vertex_groups):
  s.collection.objects.link(o);keep.append(o)
  for mod in o.modifiers:
   if mod.type=='ARMATURE':mod.object=r
  if any(g.name.startswith('hand.') for g in o.vertex_groups):
   o.data.materials.clear();o.data.materials.append(bpy.data.materials['v19 warm living skin'])
   for f in o.data.polygons:f.material_index=0
 else:
  if o!=source_rig:bpy.data.objects.remove(o,do_unlink=True)
# Transfer the same arm-local cloth and forearm geometry into the drill rest frame.
if family=='drill':
 changes={n:new_bones[n][0]@old_rest[n].inverted() for n in old_rest if n.startswith(('upper.','lower.','hand.'))}
 for o in base_meshes:
  if not any(g.name in changes for g in o.vertex_groups):continue
  inv=o.matrix_world.inverted()
  for v in o.data.vertices:
   q=o.matrix_world@v.co;res=Vector();total=0
   for group in v.groups:
    name=o.vertex_groups[group.group].name
    res+=(changes.get(name,Matrix.Identity(4))@q)*group.weight;total+=group.weight
   if total:v.co=inv@(res/total)
  o.data.update()
 bpy.ops.object.select_all(action='DESELECT');r.select_set(True);bpy.context.view_layer.objects.active=r;bpy.ops.object.mode_set(mode='EDIT')
 for n,(mat,length) in new_bones.items():
  if not n.startswith(('upper.','lower.','hand.')) and n not in ['tool','bit']:continue
  b=r.data.edit_bones.get(n) or r.data.edit_bones.new(n)
  b.matrix=mat;b.length=length
  if n=='bit':b.parent=r.data.edit_bones['tool']
 bpy.ops.object.mode_set(mode='OBJECT')
bpy.data.objects.remove(source_rig,do_unlink=True)
for o in s.objects:
 if o.type=='MESH' and not o.vertex_groups:o.hide_render=True
s.render.film_transparent=True
s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGBA'
s.render.resolution_x=s.render.resolution_y=480 if a.review else 200;s.render.resolution_percentage=100
s.render.threads_mode='FIXED';s.render.threads=a.threads
s.cycles.samples=16 if a.review else 8;s.cycles.use_denoising=True;s.render.use_persistent_data=True
s.use_nodes=True;n=s.node_tree.nodes;n.clear();links=s.node_tree.links
layers=n.new('CompositorNodeRLayers');composite=n.new('CompositorNodeComposite');links.new(layers.outputs['Image'],composite.inputs[0])
vl=s.view_layers[0]
if not vl.aovs.get('DadCloth'):
 v=vl.aovs.add();v.name='DadCloth';v.type='VALUE'
for name in ['v19 woven forest workwear','v19 soft olive sleeve lining']:
 m=bpy.data.materials.get(name)
 if m:
  node=m.node_tree.nodes.new('ShaderNodeOutputAOV');node.aov_name='DadCloth';node.inputs['Value'].default_value=1
bpy.context.view_layer.update()
mask=n.new('CompositorNodeOutputFile');mask.base_path=str(out);mask.format.file_format='PNG';mask.format.color_mode='BW';mask.format.color_depth='8';links.new(layers.outputs['DadCloth'],mask.inputs[0])
data=bpy.data.cameras.new('Hero_Game_Camera');data.type='ORTHO';data.ortho_scale=2.9
c=bpy.data.objects.new('Hero_Game_Camera',data);s.collection.objects.link(c);s.camera=c
lights={o.name:o.location.copy() for o in s.objects if o.type=='LIGHT'}
blink=create_blink(r)
rest=motion_v9.rest(family);apply=create_applier(r,rest)
skin=[m for o in s.objects for m in o.modifiers if m.type=='ARMATURE' and m.show_viewport]
def ground_vector(direction):
 origin=world_to_camera_view(s,c,Vector((0,0,0)))
 dx=(world_to_camera_view(s,c,Vector((1,0,0)))-origin)*160
 dy=(world_to_camera_view(s,c,Vector((0,1,0)))-origin)*160
 jacobian=Matrix(((dx.x,dy.x),(-dx.y,-dy.y)))
 screen=Vector({'down':(0,1),'up':(0,-1),'left':(-1,0),'right':(1,0)}[direction])
 ground=jacobian.inverted()@screen
 return Vector((ground.x,ground.y,0))
def pose(t,mode,direction):
 if a.native_motion_pilot:
  if mode in ('idle','walk','mine'):
   p=native_motion.sample(kind,mode,t,ground_vector(direction),a.native_speed)
  else:
   clip=native_clips[direction][mode]
   p=clip.sample(t*clip.duration)
 elif a.gait_pilot:
  p=locomotion.sample_walk(kind,t,ground_vector(direction),'run')
 elif a.premium_pilot:
  ground=ground_vector(direction)
  if mode=='walk_to_mine':
   p=premium_motion.blend(kind,premium_motion.sample(kind,'walk',.25,ground),premium_motion.sample(kind,'mine',.06,ground),t)
  elif mode=='mine_to_walk':
   p=premium_motion.blend(kind,premium_motion.sample(kind,'mine',.65,ground),premium_motion.sample(kind,'walk',.25,ground),t)
  else:p=premium_motion.sample(kind,mode,t,ground)
 else:
  p=motion_v9.directional_sample(t,mode,family,direction)
  if family=='drill':p['bit_angle']=t*math.tau*motion_v3.PROFILES[kind]['rotor_rps'] if mode=='mine' else 0
 p['head']=p['head']@head_offset
 for m in skin:m.show_viewport=False
 apply(p)
 blink_time=t*3.6 if a.native_motion_pilot else t
 blink(max(blink_at(blink_time,.40),blink_at(blink_time,3.13)) if mode=='idle' else 0)
 for m in skin:m.show_viewport=True
 bpy.context.view_layer.update()
 return p
m=json.loads(template.read_text())
m['cell']=[200,200];m['source']='approved native Gruvepappa v28';m['poses_are_real']=True;m['frames']=[];m.pop('qa',None)
if a.premium_pilot:
 m['pilot_only']=True
 m['states']={state:{'times':times} for state,times in {
  'idle':[0,.25,.5,.75],
  'walk':[i/48 for i in range(48)],
  'mine':sorted(set([i/48 for i in range(48)]+[.55])),
  'walk_to_mine':[i/6 for i in range(7)],
  'mine_to_walk':[i/6 for i in range(7)],
 }.items()}
if a.gait_pilot:
 m['pilot_only']=True
 m['states']={'walk':{'times':[i/48 for i in range(48)]}}
 m['gait']={'profile':'run','speed':200.,'stride':88.,'contact_ms':80.,'foot_roll':True}
error=0.0
views=[('down',(1.6,-6)),('left',(6,-1)),('up',(6,6)),('right',(-6,-1))]
views=[v for v in views if a.direction=='all' or v[0] in a.direction.split(',')]
assert views, 'No requested camera view'
def view(direction,xy):
 c.location=(*xy,7.0 if direction=='up' else 4.5);c.rotation_euler=(Vector((0,-.10,.98))-c.location).to_track_quat('-Z','Y').to_euler()
 rot=Matrix.Rotation(math.atan2(xy[1],xy[0])+math.pi/2,3,'Z')
 for name,pos in lights.items():
  o=s.objects[name];o.location=rot@pos;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
 bpy.context.view_layer.update()
 anchor=world_to_camera_view(s,c,Vector((0,0,0)))
 m['directions'].setdefault(direction,{})['ground_anchor']=[anchor.x*200,(1-anchor.y)*200]
native_clips={}
if a.native_motion_pilot:
 m['schema_version']=native_motion.SCHEMA_VERSION
 m['pilot_only']=True
 m['rendered']=not a.validate_only
 m['phase_domain']='normalized'
 m['motion']={'reference_speed':a.native_speed,'stride_pixels':locomotion.game_profile(a.native_speed).stride,
              'phase_source':'actual_gameplay_distance','heading':'one_camera_ground_heading_for_all_states',
              'transition_selection':'exact_authored_source_phase','production_approved':False,
              'interrupted_transition_coverage':False,
              'gameplay_mining_timing':{'cycle_seconds':a.gameplay_mine_cycle,'hit_phase':a.gameplay_hit_phase},
              'support_phase_windows':{'R':[0.,16./88.],'L':[.5,.5+16./88.]}}
 prior_states=m['states'];m['states']={};m['directions']={}
 selected=set(a.native_states.split(','))
 counts={item.split('=')[0]:int(item.split('=')[1]) for item in a.native_loop_counts.split(',') if item}
 assert all(key in ('idle','walk','mine') and 1<=value<=96 for key,value in counts.items())
 phases=sorted(set(float(v)%1. for v in a.transition_phases.split(',')))
 grounds={}
 for direction,xy in views:
  view(direction,xy);grounds[direction]=ground_vector(direction);native_clips[direction]={}
  m['directions'][direction]['transitions']={}
 offset=0
 for state in ('idle','walk','mine'):
  if state not in selected:continue
  duration=native_motion.state_duration(state,a.native_speed,float(prior_states['mine']['duration']))
  count=counts.get(state,int(prior_states[state]['count']))
  if state=='idle' and state not in counts:samples=[float(t)/duration for t in prior_states[state]['times']]
  else:
   samples=[i/count for i in range(count)]
   if state=='mine':samples[min(count-1,round(.55*count))]=.55
  m['states'][state]={'offset':offset,'count':count,'duration':duration,'phases':samples,'loop':True}
  offset+=count
 for source,target in (('idle','walk'),('walk','idle'),('walk','mine'),('mine','walk'),('mine','idle')):
  route=source+'_to_'+target
  if route not in selected:continue
  for phase in ([0.] if source=='idle' else phases):
   name=route+'-'+str(round(phase*1000000)).zfill(6)
   for direction in grounds:
    clip=native_motion.Transition(kind,source,phase,target,tuple(grounds[direction]),a.native_speed,a.gameplay_mine_cycle,a.gameplay_hit_phase)
    native_clips[direction][name]=clip
    meta=clip.metadata()
    view(direction,dict(views)[direction])
    zero=world_to_camera_view(s,c,Vector())
    shifted=world_to_camera_view(s,c,clip.destination_offset)
    meta['destination_offset_pixels']=[(shifted.x-zero.x)*160,-(shifted.y-zero.y)*160]
    m['directions'][direction]['transitions'][name]=meta
   duration=max(native_clips[d][name].duration for d in grounds)
   count=max(3,math.ceil(duration*a.transition_fps)+1)
   m['states'][name]={'offset':offset,'count':count,'phases':[i/(count-1) for i in range(count)],'loop':False,
                       'duration_source':'directions.<direction>.transitions.<state>.duration'}
   offset+=count
 m['motion']['source_phase_bank']=phases
 m['motion']['frames_per_direction']=offset
 m['render_fingerprint']=fingerprint
 assert m['states'], 'No native pilot states requested'
for mode,info in m['states'].items():
 times=info['phases'] if a.native_motion_pilot else info['times'];indices=list(range(len(times)))
 if a.review:indices=([0,6] if mode=='idle' else [len(times)//4] if mode=='walk' else [0,round(len(times)*.30),round(len(times)*.55),round(len(times)*.80)])
 for i in indices:
  t=times[i]
  for direction,xy in views:
   view(direction,xy)
   p=pose(t,mode,direction)
   for side in ['R','L']:
    b=r.pose.bones['hand.'+side];delta=b.matrix@r.data.bones[b.name].matrix_local.inverted()
    error=max(error,(delta@rest['grips'][side]-p['grips'][side]).length)
   key=f'{direction}-{mode}-{i:03}'
   s.render.filepath=str(out/(key+'.png'));mask.file_slots[0].path='mask-'+key+'-';s.frame_current=1
   done=out/(key+'.done')
   if not a.validate_only and not (done.exists() and (out/(key+'.png')).exists() and (out/('mask-'+key+'-0001.png')).exists()):
    bpy.ops.render.render(write_still=True)
    done.write_text(fingerprint)
   sample={'direction':direction,'state':mode,'index':i,'time':t,'path':key+'.png','mask':'mask-'+key+'-0001.png'}
   if a.native_motion_pilot:
    duration=float(info['duration']) if 'duration' in info else native_clips[direction][mode].duration
    sample['phase']=t;sample['time']=t*duration
    sample['native']=native_motion.frame_metadata(p,ground_vector(direction))
    sample['contacts']=p['contacts']
    sample['ground_root_pixels']=p.get('transition_metadata',{}).get('target_root_pixels',0.)
    if not a.validate_only:
     sample['png_sha256']=hashlib.sha256((out/(key+'.png')).read_bytes()).hexdigest()
     sample['mask_sha256']=hashlib.sha256((out/sample['mask']).read_bytes()).hexdigest()
   if a.premium_pilot or a.gait_pilot:
    sample['feet']={side:list(world_to_camera_view(s,c,p['legs'][side][2])) for side in ['R','L']}
    sample['contacts']=p['contacts']
   m['frames'].append(sample)
   print('POSE_OK' if a.validate_only else 'FRAME_OK',kind,key,flush=True)
 assert error<1e-5,error
 print('STATE_POSES_VALIDATED' if a.validate_only else 'STATE_RENDERED',kind,mode,flush=True)
m['max_grip_error']=error
(out/('pose-manifest.json' if a.validate_only else 'pilot-manifest.json' if a.premium_pilot or a.gait_pilot or a.native_motion_pilot else 'review-manifest.json' if a.review else 'manifest.json')).write_text(json.dumps(m,indent=2)+'\n')
print('HERO_V28_POSE_CHECK_COMPLETE' if a.validate_only else 'HERO_V28_REVIEW_COMPLETE' if a.review else 'HERO_V28_EXPORT_COMPLETE',kind,len(m['frames']),flush=True)
