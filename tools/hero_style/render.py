"""Render a source-only material study using the unchanged approved v28 exporter setup."""
import bpy,sys,json,hashlib,argparse
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument('--native-tools',required=True)
p.add_argument('--output',required=True)
p.add_argument('--style',choices=['baseline','matte','paint','integrated','relief','world'],default='matte')
p.add_argument('--directions',default='down')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:])
export=Path(__file__).resolve().parents[1]/'hero_v28/export_hero.py'
sys.argv=['blender','--','--native-tools',a.native_tools,'--output',a.output,'--gear','iron','--review','--threads','4']
namespace={'__file__':str(export),'__name__':'__hero_review__'}
exec(compile(export.read_text().split('for mode,info in m[\'states\'].items():')[0],str(export),'exec'),namespace)
s=namespace['s'];out=namespace['out'];pose=namespace['pose'];view=namespace['view']

def geometry_digest():
 h=hashlib.sha256()
 for o in sorted(s.objects,key=lambda o:o.name):
  if o.type=='MESH':
   h.update(o.name.encode())
   for v in o.data.vertices:h.update(str(tuple(v.co)).encode())
  if o.type=='ARMATURE':
   for b in o.data.bones:h.update(str((b.name,tuple(tuple(row) for row in b.matrix_local))).encode())
 return h.hexdigest()

before=geometry_digest()
changes=[]
if a.style in ['matte','paint','integrated','relief','world']:
 # Keep authored base-color textures, cut studio sparkle and rim lighting.
 for light in [o for o in s.objects if o.type=='LIGHT']:
  if 'rim' in light.name:light.data.energy=0.0
  if 'key' in light.name:light.data.energy=470.0;light.data.color=(1.0,.93,.83);light.data.size=5.0
  if 'fill' in light.name:light.data.energy=105.0;light.data.color=(.78,.86,1.0)
 for mat in bpy.data.materials:
  if not mat.use_nodes:continue
  for bsdf in [n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED']:
   # Preserve pupils, eye highlights, lamp glass and emission.
   if any(w in mat.name.lower() for w in ['iris','irises','pupil','eye light','lamp glass']):continue
   rough=bsdf.inputs['Roughness'];metal=bsdf.inputs['Metallic'];spec=bsdf.inputs['Specular IOR Level']
   for inp in [rough,metal,spec]:
    for link in list(inp.links):mat.node_tree.links.remove(link)
   rough.default_value=.94
   metal.default_value=.08 if 'brass' in mat.name.lower() else 0.0
   spec.default_value=.06
   # Micro-bump resolved as glossy noise at game scale; preserve painted color texture.
   for link in list(bsdf.inputs['Normal'].links):mat.node_tree.links.remove(link)
   changes.append(mat.name)
 s.view_settings.look='AgX - Medium High Contrast'
 s.view_settings.exposure=.12


if a.style in ['paint','integrated','relief']:
 # Three broad color planes plus object-anchored mottling. No mesh/rig changes.
 for mat in bpy.data.materials:
  if not mat.use_nodes:continue
  if any(w in mat.name.lower() for w in ['iris','irises','pupil','eye','lamp glass','studio']):continue
  ns=mat.node_tree.nodes;ls=mat.node_tree.links
  bsdf=next((n for n in ns if n.type=='BSDF_PRINCIPLED'),None)
  if bsdf is None:continue
  output=next((n for n in ns if n.type=='OUTPUT_MATERIAL' and n.is_active_output),None)
  if output is None:continue
  base=bsdf.inputs['Base Color']
  source=base.links[0].from_socket if base.is_linked else None
  rgb=ns.new('ShaderNodeRGB');rgb.outputs[0].default_value=base.default_value
  if source is None:source=rgb.outputs[0]
  geom=ns.new('ShaderNodeNewGeometry')
  dot=ns.new('ShaderNodeVectorMath');dot.operation='DOT_PRODUCT';dot.name='Art light direction';dot.inputs[1].default_value=(-.43,-.64,.63);ls.new(geom.outputs['Normal'],dot.inputs[0])
  remap=ns.new('ShaderNodeMapRange');remap.inputs['From Min'].default_value=-1;remap.inputs['From Max'].default_value=1;ls.new(dot.outputs['Value'],remap.inputs['Value'])
  ramp=ns.new('ShaderNodeValToRGB');ramp.color_ramp.interpolation='EASE'
  stops=[(0,(.27,.32,.33,1)),(.40,(.27,.32,.33,1)),(.46,(.64,.68,.59,1)),(.72,(.64,.68,.59,1)),(.79,(1.08,1.00,.80,1)),(1,(1.08,1.00,.80,1))]
  for el in list(ramp.color_ramp.elements)[2:]:ramp.color_ramp.elements.remove(el)
  for i,(pos,col) in enumerate(stops):
   el=ramp.color_ramp.elements[i] if i<2 else ramp.color_ramp.elements.new(pos)
   el.position=pos;el.color=col
  ls.new(remap.outputs['Result'],ramp.inputs[0])
  mix=ns.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
  ls.new(source,mix.inputs[1]);ls.new(ramp.outputs['Color'],mix.inputs[2])
  tex=ns.new('ShaderNodeTexCoord');noise=ns.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=18;noise.inputs['Detail'].default_value=1.0;noise.inputs['Roughness'].default_value=.55
  ls.new(tex.outputs['Generated'],noise.inputs['Vector'])
  nr=ns.new('ShaderNodeMapRange');nr.inputs['To Min'].default_value=.78;nr.inputs['To Max'].default_value=1.20;ls.new(noise.outputs['Fac'],nr.inputs['Value'])
  grain=ns.new('ShaderNodeMixRGB');grain.blend_type='MULTIPLY';grain.inputs[0].default_value=.55 if 'skin' in mat.name else 1
  ls.new(mix.outputs[0],grain.inputs[1]);ls.new(nr.outputs['Result'],grain.inputs[2])
  ao=ns.new('ShaderNodeAmbientOcclusion');ao.inputs['Distance'].default_value=.12;ao.samples=8
  shade=ns.new('ShaderNodeMixRGB');shade.blend_type='MULTIPLY';shade.inputs[0].default_value=.62
  ls.new(grain.outputs[0],shade.inputs[1]);ls.new(ao.outputs['AO'],shade.inputs[2])
  emit=ns.new('ShaderNodeEmission');emit.inputs['Strength'].default_value=1.1;ls.new(shade.outputs[0],emit.inputs['Color'])
  if a.style in ['integrated','relief']:
   # Restore controlled directional relief; keep the broad painted response.
   metal_kind=any(w in mat.name.lower() for w in ['brass','helmet','iron'])
   bsdf.inputs['Roughness'].default_value=.72 if metal_kind else .92
   bsdf.inputs['Metallic'].default_value=.22 if metal_kind else 0.0
   bsdf.inputs['Specular IOR Level'].default_value=.14 if metal_kind else .07
   bump=ns.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.12;bump.inputs['Distance'].default_value=.035 if metal_kind else .016
   ls.new(noise.outputs['Fac'],bump.inputs['Height']);ls.new(bump.outputs['Normal'],bsdf.inputs['Normal'])
   combine=ns.new('ShaderNodeMixShader');combine.inputs[0].default_value=.54
   ls.new(bsdf.outputs['BSDF'],combine.inputs[1]);ls.new(emit.outputs[0],combine.inputs[2]);ls.new(combine.outputs[0],output.inputs['Surface'])
  else:ls.new(emit.outputs[0],output.inputs['Surface'])
 s.view_settings.look='AgX - Medium High Contrast'
 s.view_settings.exposure=.18

if a.style == 'relief':
 # Medium, object-anchored painted folds survive the 160px export. The original
 # mesh, rest rig and pose are untouched; each broad surface gets its own shader.
 for obj in list(s.objects):
  if obj.type!='MESH':continue
  sleeve='softly rounded sleeve' in obj.name
  boot=obj.name.startswith(('rounded worn boot','boot upper'))
  coat=obj.name=='coat body'
  helmet=obj.name=='iron dome'
  if not any([sleeve,boot,coat,helmet]):continue
  mat=obj.data.materials[0].copy();mat.name='Style relief '+obj.name
  obj.data.materials[0]=mat
  ns=mat.node_tree.nodes;ls=mat.node_tree.links
  bsdf=next(n for n in ns if n.type=='BSDF_PRINCIPLED')
  emit=next(n for n in ns if n.type=='EMISSION')
  combine=next(n for n in ns if n.type=='MIX_SHADER')
  tex=ns.new('ShaderNodeTexCoord')
  noise=ns.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=5.5;noise.inputs['Detail'].default_value=1.3
  ls.new(tex.outputs['Generated'],noise.inputs['Vector'])
  if helmet:
   # Broken, broad worn-metal response rather than the old sharp studio hotspot.
   combine.inputs[0].default_value=.18
   bsdf.inputs['Metallic'].default_value=.26
   bsdf.inputs['Specular IOR Level'].default_value=.25
   rough=ns.new('ShaderNodeMapRange');rough.inputs['To Min'].default_value=.45;rough.inputs['To Max'].default_value=.83
   ls.new(noise.outputs['Fac'],rough.inputs['Value']);ls.new(rough.outputs[0],bsdf.inputs['Roughness'])
   bump=next(n for n in ns if n.type=='BUMP');bump.inputs['Strength'].default_value=.22;bump.inputs['Distance'].default_value=.028
   ls.new(noise.outputs['Fac'],bump.inputs['Height'])
   continue
  direction=ns.new('ShaderNodeVectorMath');direction.operation='DOT_PRODUCT'
  direction.inputs[1].default_value=(.15,.42,1.0) if sleeve else (.1,.75,.40) if boot else (.18,.1,1.0)
  ls.new(tex.outputs['Generated'],direction.inputs[0])
  jitter=ns.new('ShaderNodeMath');jitter.operation='MULTIPLY';jitter.inputs[1].default_value=.14
  ls.new(noise.outputs['Fac'],jitter.inputs[0])
  coord=ns.new('ShaderNodeMath');coord.operation='ADD';ls.new(direction.outputs['Value'],coord.inputs[0]);ls.new(jitter.outputs[0],coord.inputs[1])
  source_bsdf=bsdf.inputs['Base Color'].links[0].from_socket
  source_emit=emit.inputs['Color'].links[0].from_socket
  for center,width in ([(.43,.10),(.85,.065)] if sleeve else [(.56,.095),(.84,.055)] if boot else [(.37,.065),(.66,.06)]):
   delta=ns.new('ShaderNodeMath');delta.operation='SUBTRACT';delta.inputs[1].default_value=center;ls.new(coord.outputs[0],delta.inputs[0])
   absolute=ns.new('ShaderNodeMath');absolute.operation='ABSOLUTE';ls.new(delta.outputs[0],absolute.inputs[0])
   ramp=ns.new('ShaderNodeValToRGB');ramp.color_ramp.interpolation='EASE'
   for i,(pos,value) in enumerate([(0,.36),(.018,.46),(width*.62,1.18),(width,1.0)]):
    el=ramp.color_ramp.elements[i] if i<2 else ramp.color_ramp.elements.new(pos)
    el.position=pos;el.color=(value,value,value,1)
   ls.new(absolute.outputs[0],ramp.inputs[0])
   for source,target in [(source_bsdf,bsdf.inputs['Base Color']),(source_emit,emit.inputs['Color'])]:
    painted=ns.new('ShaderNodeMixRGB');painted.blend_type='MULTIPLY';painted.inputs[0].default_value=.75 if sleeve else .65
    ls.new(source,painted.inputs[1]);ls.new(ramp.outputs[0],painted.inputs[2]);ls.new(painted.outputs[0],target)
   source_bsdf=bsdf.inputs['Base Color'].links[0].from_socket
   source_emit=emit.inputs['Color'].links[0].from_socket
  # Irregular broad wear, shared by the diffuse and painted components.
  wear=ns.new('ShaderNodeMapRange');wear.inputs['To Min'].default_value=.62;wear.inputs['To Max'].default_value=1.38
  ls.new(noise.outputs['Fac'],wear.inputs['Value'])
  for source,target in [(source_bsdf,bsdf.inputs['Base Color']),(source_emit,emit.inputs['Color'])]:
   varied=ns.new('ShaderNodeMixRGB');varied.blend_type='MULTIPLY';varied.inputs[0].default_value=.75
   ls.new(source,varied.inputs[1]);ls.new(wear.outputs[0],varied.inputs[2]);ls.new(varied.outputs[0],target)
  ao=next(n for n in ns if n.type=='AMBIENT_OCCLUSION');ao.inputs['Distance'].default_value=.19
  changes.append(mat.name)

if a.style == 'world':
 # Material-specific, object-anchored wear. Original authored color maps are retained.
 # No emission shading: native diffuse relief must survive the 160px cell.
 for mat in bpy.data.materials:
  if not mat.use_nodes:continue
  name=mat.name.lower()
  if any(w in name for w in ['iris','pupil','eye','lamp glass','studio']):continue
  ns=mat.node_tree.nodes;ls=mat.node_tree.links
  bs=next((n for n in ns if n.type=='BSDF_PRINCIPLED'),None)
  if bs is None:continue
  cloth=any(w in name for w in ['woven','lining','cloth','workwear'])
  metal=any(w in name for w in ['iron','brass','metal','steel'])
  hair=any(w in name for w in ['hair','beard','brow'])
  leather=any(w in name for w in ['leather','boot','belt','strap'])
  skin='skin' in name
  tex=ns.new('ShaderNodeTexCoord')
  mapping=ns.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY'
  mapping.inputs[1].default_value=(1,1,3.5) if cloth else (5,5,.7) if hair else (1,1,1)
  ls.new(tex.outputs['Generated'],mapping.inputs[0])
  coarse=ns.new('ShaderNodeTexNoise');coarse.inputs['Scale'].default_value=9 if cloth else 14 if metal else 18 if hair else 8
  coarse.inputs['Detail'].default_value=2.2;coarse.inputs['Roughness'].default_value=.7
  ls.new(mapping.outputs['Vector'],coarse.inputs['Vector'])
  fine=ns.new('ShaderNodeTexNoise');fine.inputs['Scale'].default_value=95 if cloth else 65
  fine.inputs['Detail'].default_value=2;ls.new(mapping.outputs['Vector'],fine.inputs['Vector'])
  ramp=ns.new('ShaderNodeValToRGB');ramp.color_ramp.interpolation='EASE'
  lo,hi=(.44,1.5) if cloth else (.36,1.7) if metal else (.74,1.20) if leather else (.45,1.35) if hair else (.90,1.08)
  ramp.color_ramp.elements[0].position=.28;ramp.color_ramp.elements[0].color=(lo,lo*.98,lo*.94,1)
  ramp.color_ramp.elements[1].position=.72;ramp.color_ramp.elements[1].color=(hi,hi*.98,hi*.91,1)
  ls.new(coarse.outputs['Fac'],ramp.inputs[0])
  base=bs.inputs['Base Color'];src=base.links[0].from_socket if base.is_linked else None
  if src is None:
   rgb=ns.new('ShaderNodeRGB');rgb.outputs[0].default_value=base.default_value;src=rgb.outputs[0]
  var=ns.new('ShaderNodeMixRGB');var.blend_type='MULTIPLY';var.inputs[0].default_value=1
  ls.new(src,var.inputs[1]);ls.new(ramp.outputs[0],var.inputs[2])
  ao=ns.new('ShaderNodeAmbientOcclusion');ao.inputs['Distance'].default_value=.16;ao.samples=16
  shade=ns.new('ShaderNodeMixRGB');shade.blend_type='MULTIPLY';shade.inputs[0].default_value=.6 if skin else .78
  ls.new(var.outputs[0],shade.inputs[1]);ls.new(ao.outputs['AO'],shade.inputs[2]);ls.new(shade.outputs[0],base)
  bump=ns.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.42 if cloth or hair else .26 if metal else .16 if leather else .06
  bump.inputs['Distance'].default_value=.035 if cloth else .018 if metal or hair or leather else .006
  ls.new(coarse.outputs['Fac'],bump.inputs['Height'])
  micro=ns.new('ShaderNodeBump');micro.inputs['Strength'].default_value=.16 if cloth else .10
  micro.inputs['Distance'].default_value=.007 if cloth else .003
  ls.new(fine.outputs['Fac'],micro.inputs['Height']);ls.new(bump.outputs['Normal'],micro.inputs['Normal']);ls.new(micro.outputs['Normal'],bs.inputs['Normal'])
  bs.inputs['Metallic'].default_value=.66 if metal else 0
  bs.inputs['Specular IOR Level'].default_value=.40 if metal else .15 if leather else .08
  rough=ns.new('ShaderNodeMapRange');rough.inputs['To Min'].default_value=.27 if metal else .76 if leather else .9
  rough.inputs['To Max'].default_value=.65 if metal else .96
  ls.new(coarse.outputs['Fac'],rough.inputs['Value']);ls.new(rough.outputs[0],bs.inputs['Roughness'])
  changes.append(mat.name)
 for light in [o for o in s.objects if o.type=='LIGHT']:
  if 'key' in light.name:light.data.energy=640;light.data.size=3.0;light.data.color=(1,.91,.77)
  if 'fill' in light.name:light.data.energy=80;light.data.color=(.67,.78,1)
 s.view_settings.look='AgX - Medium High Contrast';s.view_settings.exposure=.15

assert before==geometry_digest(),'Style operation altered geometry or rest rig'
model_after=geometry_digest()
# Keep the model fingerprint independent of a temporary render-only shadow receiver.
if a.style in ['integrated','relief','world']:
 for light in [o for o in s.objects if o.type=='LIGHT']:
  if 'rim' in light.name:light.data.energy=45
 # A soft contact-only compositing shadow. No catcher plane can tint the cell.
 nodes=s.node_tree.nodes;links=s.node_tree.links
 shadow_mask=nodes.new('CompositorNodeEllipseMask');shadow_mask.width=.23;shadow_mask.height=.035
 shadow_blur=nodes.new('CompositorNodeBlur');shadow_blur.filter_type='GAUSS';shadow_blur.size_x=9;shadow_blur.size_y=5
 links.new(shadow_mask.outputs['Mask'],shadow_blur.inputs['Image'])
 strength=nodes.new('CompositorNodeMath');strength.operation='MULTIPLY';strength.inputs[1].default_value=.28
 links.new(shadow_blur.outputs[0],strength.inputs[0])
 shadow=nodes.new('CompositorNodeSetAlpha');shadow.inputs['Image'].default_value=(.004,.007,.006,1)
 links.new(strength.outputs[0],shadow.inputs['Alpha'])
 over=nodes.new('CompositorNodeAlphaOver');over.inputs[0].default_value=1
 links.new(shadow.outputs[0],over.inputs[1]);links.new(namespace['layers'].outputs['Image'],over.inputs[2]);links.new(over.outputs[0],namespace['composite'].inputs[0])
s.cycles.samples=48
s.render.use_persistent_data=True
s.render.resolution_x=s.render.resolution_y=480
# Diagnostic alpha renders, separate from the existing atlases.
results=[]
for direction,xy in [('down',(1.6,-6)),('left',(6,-1)),('up',(6,6))]:
 if direction not in a.directions.split(','):continue
 pose(0.0,'idle');view(direction,xy)
 if a.style in ['integrated','relief','world']:
  anchor=namespace['m']['directions'][direction]['ground_anchor']
  shadow_mask.x=anchor[0]/200;shadow_mask.y=1-anchor[1]/200
 s.render.filepath=str(out/(direction+'-idle-000.png'))
 namespace['mask'].file_slots[0].path='mask-'+direction+'-idle-000-'
 bpy.ops.render.render(write_still=True)
 results.append({'path':s.render.filepath,'sha256':hashlib.sha256(Path(s.render.filepath).read_bytes()).hexdigest()})
(out/'style-report.json').write_text(json.dumps({'style':a.style,'model_sha256':hashlib.sha256(Path(bpy.data.filepath).read_bytes()).hexdigest(),'geometry_before':before,'geometry_after':model_after,'changed_materials':sorted(set(changes)),'model_geometry_unchanged':True,'camera_and_native_pose':'unchanged v28 exporter','files':results},indent=2))
if a.style in ['integrated','relief','world']:
 bpy.ops.wm.save_as_mainfile(filepath=str(out/'Ever-Deeper-hero-material-study.blend'))
print('STYLE_RENDER_COMPLETE',a.style)
