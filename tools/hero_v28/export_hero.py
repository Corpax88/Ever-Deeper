"""Export the approved native Gruvepappa v28 with the existing real tool motion."""
import bpy, sys, math, json, argparse, hashlib
from pathlib import Path
from mathutils import Vector, Matrix
from bpy_extras.object_utils import world_to_camera_view
ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
import motion_v9, motion_v3
from native_pose import create_applier
from eyelids import create_blink
from hero_expression_v7 import blink_at

ap=argparse.ArgumentParser()
ap.add_argument('--native-tools',type=Path,required=True)
ap.add_argument('--output',type=Path,required=True)
ap.add_argument('--gear',default='iron',choices=list(motion_v3.PROFILES))
ap.add_argument('--review',action='store_true')
ap.add_argument('--direction',default='all')
ap.add_argument('--threads',type=int,default=2)
a=ap.parse_args(sys.argv[sys.argv.index('--')+1:])
s=bpy.context.scene;r=bpy.data.objects['EverDeeper_Hero_Rig'];kind=a.gear;family=motion_v3.PROFILES[kind]['family']
out=a.output/kind;out.mkdir(parents=True,exist_ok=True)
fingerprint=hashlib.sha256(b''.join(p.read_bytes() for p in sorted(ROOT.glob('*.py')))+Path(bpy.data.filepath).read_bytes()+str(a.review).encode()).hexdigest()
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
def pose(t,mode):
 p=motion_v9.directional_sample(t,mode,family,'down')
 if family=='drill':p['bit_angle']=t*math.tau*motion_v3.PROFILES[kind]['rotor_rps'] if mode=='mine' else 0
 p['head']=p['head']@head_offset
 for m in skin:m.show_viewport=False
 apply(p)
 blink(max(blink_at(t,.40),blink_at(t,3.13)) if mode=='idle' else 0)
 for m in skin:m.show_viewport=True
 bpy.context.view_layer.update()
 return p
template=ROOT.parent.parent/'assets/hero/dad'/kind/'manifest.json'
m=json.loads(template.read_text())
m['cell']=[200,200];m['source']='approved native Gruvepappa v28';m['poses_are_real']=True;m['frames']=[];m.pop('qa',None)
error=0.0
views=[('down',(1.6,-6)),('left',(6,-1)),('up',(6,6)),('right',(-6,-1))]
views=[v for v in views if a.direction in ['all',v[0]]]
def view(direction,xy):
 c.location=(*xy,7.0 if direction=='up' else 4.5);c.rotation_euler=(Vector((0,-.10,.98))-c.location).to_track_quat('-Z','Y').to_euler()
 rot=Matrix.Rotation(math.atan2(xy[1],xy[0])+math.pi/2,3,'Z')
 for name,pos in lights.items():
  o=s.objects[name];o.location=rot@pos;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
 bpy.context.view_layer.update()
 anchor=world_to_camera_view(s,c,Vector((0,0,0)))
 m['directions'][direction]={'ground_anchor':[anchor.x*200,(1-anchor.y)*200]}
for mode,info in m['states'].items():
 times=info['times'];indices=list(range(len(times)))
 if a.review:indices=([0,6] if mode=='idle' else [len(times)//4] if mode=='walk' else [0,round(len(times)*.30),round(len(times)*.55),round(len(times)*.80)])
 for i in indices:
  t=times[i];p=pose(t,mode)
  for side in ['R','L']:
   b=r.pose.bones['hand.'+side];delta=b.matrix@r.data.bones[b.name].matrix_local.inverted()
   error=max(error,(delta@rest['grips'][side]-p['grips'][side]).length)
  for direction,xy in views:
   view(direction,xy)
   key=f'{direction}-{mode}-{i:03}'
   s.render.filepath=str(out/(key+'.png'));mask.file_slots[0].path='mask-'+key+'-';s.frame_current=1
   done=out/(key+'.done')
   if not (done.exists() and (out/(key+'.png')).exists() and (out/('mask-'+key+'-0001.png')).exists()):
    bpy.ops.render.render(write_still=True)
    done.write_text(fingerprint)
   m['frames'].append({'direction':direction,'state':mode,'index':i,'path':key+'.png','mask':'mask-'+key+'-0001.png'})
   print('FRAME_OK',kind,key,flush=True)
 assert error<1e-5,error
 print('STATE_RENDERED',kind,mode,flush=True)
m['max_grip_error']=error
(out/('review-manifest.json' if a.review else 'manifest.json')).write_text(json.dumps(m,indent=2)+'\n')
print('HERO_V28_REVIEW_COMPLETE' if a.review else 'HERO_V28_EXPORT_COMPLETE',kind,len(m['frames']),flush=True)
