"""Retarget a licensed source clip onto the unchanged approved 17-bone rig.
The result is an isolated task-bank candidate, never a replacement rig.
"""
import bpy,json,math,hashlib,copy,os
from pathlib import Path
from mathutils import Matrix,Vector,Quaternion
ROOT=Path(os.environ['HERO_WORKDIR']).resolve()
out=ROOT/'candidate-v2';out.mkdir(exist_ok=True)
data=json.loads((ROOT/'native-input/motion.json').read_text())
bank=json.loads((ROOT/'native-input/tasks.json').read_text())
rest={n:Matrix(m) for n,m in data['rest'].items()}
idle={n:Matrix(m) for n,m in bank['samples']['idle'][0]['bones'].items()}
def frame(chain,j):
 y=(chain[j+1]-chain[j]).normalized();z=(chain[1]-chain[0]).cross(chain[2]-chain[1]).normalized()
 if z.length<.5:z=Vector((1,0,0))
 return Matrix((y.cross(z),y,z)).transposed()
def set_chain(b,names,points,old):
 oldpts=[old[n].translation for n in names]
 for j,n in enumerate(names[:2]):
  basis=frame(points,j)@frame(oldpts,j).inverted()@old[n].to_3x3()
  b[n]=basis.to_4x4();b[n].translation=points[j]
 b[names[2]].translation=points[2]
def arm(b,side,old):
 names=['upper.'+side,'lower.'+side,'hand.'+side]
 a,c=b[names[0]].translation,b[names[2]].translation
 axis=(c-a).normalized();distance=(c-a).length
 assert distance<.70999,('arm reach',side,distance)
 oldpts=[old[n].translation for n in names]
 radial=oldpts[1]-oldpts[0];radial=(radial-axis*radial.dot(axis)).normalized()
 along=(distance*distance+.36**2-.35**2)/(2*distance)
 middle=a+axis*along+radial*math.sqrt(max(0,.36**2-along**2))
 set_chain(b,names,[a,middle,c],old)
def record(b,phase,contacts,release=0):
 return {'phase':phase,'bones':{n:[list(v) for v in m] for n,m in b.items()},'contacts':contacts,'support_release':release}
bpy.context.scene.render.fps=60
bpy.context.scene.render.fps_base=1.0
bpy.context.scene.unit_settings.scale_length=1.0
before=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'inputs/Quaternius-Standard.glb'))
source=next(o for o in bpy.data.objects if o not in before and o.type=='ARMATURE')
source.animation_data.action=bpy.data.actions['Jog_Fwd_Loop']
start,end=source.animation_data.action.frame_range
source_rest={n:b.matrix_local.copy() for n,b in source.data.bones.items()}
scale=.364/((source_rest['DEF-thigh.L'].translation-source_rest['DEF-shin.L'].translation).length+(source_rest['DEF-shin.L'].translation-source_rest['DEF-foot.L'].translation).length)
def source_delta(name):
 return source.pose.bones[name].matrix.to_quaternion()@source_rest[name].to_quaternion().inverted()
def attenuate(q,w):return Quaternion().slerp(q,w)
# Keep the stocky miner's fitted boots and original contact trajectory. Human
# ankle proportions/foot roll proved unsuitable in the first rendered retarget.
# Transfer the source's cyclic torso counter-rotation, removing its static lean.
angles=[]
for i in range(96):
 t=start+i/96*(end-start);bpy.context.scene.frame_set(int(t),subframe=t-int(t));bpy.context.view_layer.update()
 angles.append(Vector(source_delta('DEF-spine.003').to_euler('XYZ')))
average=sum(angles,Vector())/len(angles)
walk=[]
for i,row in enumerate(bank['samples']['walk']):
 b={n:Matrix(m) for n,m in row['bones'].items()}
 from mathutils import Euler
 angle=(angles[i]-average)*.38
 rotation=Euler(tuple(angle),'XYZ').to_matrix().to_4x4()
 pivot=b['body'].translation.copy()
 delta=Matrix.Translation(pivot)@rotation@Matrix.Translation(-pivot)
 for n in ['body','head','tool','upper.R','lower.R','hand.R','upper.L','lower.L','hand.L']:b[n]=delta@b[n]
 walk.append(record(b,row['phase'],row['contacts']))
bank['samples']['walk']=walk
bank['stride_native']=float(bank['stride_pixels'])*Vector(bank['ground_per_pixel']).length
# Retain authored stride for first A/B: avoid conflating cadence with pose quality.
# Source-proportioned foot travel and stance slip are recorded for subsequent fit.
mine=[];max_reach=0
grips={s:idle['tool'].inverted()@idle['hand.'+s] for s in ['R','L']}
# Hand-authored tool-space action: anticipation, two-handed impact at the actual
# .42 gameplay hit phase, follow-through, recoil, then settle. No free-hand swap.
# phase, tool Y/Z, tool X-rotation, body lean, body height, upper-body twist
keys=[(0,-.47,1.02,2.48,.015,.585,.04),
      (.23,-.50,1.39,1.02,-.06,.588,.12),
      (.31,-.53,1.38,1.17,-.035,.576,.08),
      (.42,-.62,.91,3.00,.20,.542,-.07),
      (.49,-.63,.85,3.12,.225,.532,-.09),
      (.60,-.57,.97,2.75,.125,.562,-.035),
      (.84,-.47,1.02,2.48,.015,.585,.04),
      (1,-.47,1.02,2.48,.015,.585,.04)]
def interpolate(phase):
 for a,c in zip(keys,keys[1:]):
  if a[0]<=phase<=c[0]:
   t=(phase-a[0])/(c[0]-a[0]);t=t*t*(3-2*t)
   return [a[j]+(c[j]-a[j])*t for j in range(1,len(a))]
for i in range(50):
 phase=i/50;ty,tz,pitch,lean,height,twist=interpolate(phase)
 old=idle;b={n:m.copy() for n,m in idle.items()}
 yaw=Matrix.Rotation(twist,4,'Z');tilt=Matrix.Rotation(lean,4,'X')
 b['body']=(yaw@tilt)@idle['body'];b['body'].translation=Vector((0,-.025*max(0,lean/.2),height))
 body_delta=b['body']@idle['body'].inverted();b['head']=body_delta@idle['head']
 b['tool']=yaw@Matrix.Rotation(pitch,4,'X');b['tool'].translation=yaw@Vector((-.03,ty,tz))
 for side in ['R','L']:
  b['upper.'+side].translation=body_delta@idle['upper.'+side].translation
  b['hand.'+side]=b['tool']@grips[side]
 for iteration in range(12):
  pull=Vector()
  for side in ['R','L']:
   d=b['hand.'+side].translation-b['upper.'+side].translation
   if d.length>.702:pull-=d.normalized()*(d.length-.702)
  if pull.length<1e-6:break
  b['tool'].translation+=pull
  for side in ['R','L']:b['hand.'+side].translation+=pull
 for side in ['R','L']:
  max_reach=max(max_reach,(b['hand.'+side].translation-b['upper.'+side].translation).length);arm(b,side,old)
 # Subtle pelvis sink follows the torso without moving either planted boot.
 hip_drop=(height-.585)*.60
 for side in ['R','L']:
  names=['thigh.'+side,'shin.'+side,'foot.'+side]
  hip=b[names[0]].translation.copy();hip.z+=hip_drop
  foot=b[names[2]].translation.copy();axis=(foot-hip).normalized();distance=(foot-hip).length
  radial=Vector((0,-1,0));radial=(radial-axis*radial.dot(axis)).normalized()
  along=(distance*distance+.180**2-.184**2)/(2*distance)
  knee=hip+axis*along+radial*math.sqrt(max(0,.180**2-along**2))
  set_chain(b,names,[hip,knee,foot],idle)
 b['hips'].translation.z+=hip_drop
 mine.append(record(b,phase,{'R':True,'L':True},0))
bank['samples']['mine']=mine
cap=Matrix(mine[21]['bones']['tool'])@Vector(bank['tool_cap_local']);bank['reference_contact']=list(cap)
bank['approved']=False;bank['limits']='Fitted original lower-body contacts, source-derived torso counter-motion, authored two-handed mining; isolated candidate pending gameplay and visual review.'
path=out/'tasks.json';path.write_text(json.dumps(bank,separators=(',',':')))
report={'source_clip':'Jog_Fwd_Loop','source_zip_sha256':'18ff1a7215f4852b320203e8aaf02a1578b5c8eef9027fbaedfcedc7b85a3ac2','source_license':'CC0-1.0','target_rest_unchanged':True,'leg_scale':scale,'stride_pixels':bank['stride_pixels'],'max_arm_reach':max_reach,'tasks_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'walk_feet':[{side:[row['bones']['foot.'+side][k][3] for k in range(3)] for side in ['R','L']} for row in walk], 'method':'Original fitted lower-body path with source cyclic torso motion; authored rigid two-hand swing'}
(out/'motion-build.json').write_text(json.dumps(report,indent=2));print('MOTION_CANDIDATE_COMPLETE',report['tasks_sha256'],max_reach)
