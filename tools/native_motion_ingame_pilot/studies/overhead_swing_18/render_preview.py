"""Render authored key poses or one real loop on the approved Blender model."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import runpy
import sys

import bpy
from mathutils import Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
sys.path[:0]=[str(HERE),str(ROOT/'tools/native_motion_ingame_pilot'),str(ROOT/'tools/hero_v28')]
from simple_swing import SimpleSwing,phase,CYCLE
from forearm_frame_pose import align_right_forearm
import native_motion

parser=argparse.ArgumentParser()
parser.add_argument('--native-tools',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
parser.add_argument('--loop',action='store_true')
parser.add_argument('--check-only',action='store_true')
parser.add_argument('--azimuth',type=float,default=90.)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
args.output.mkdir(parents=True,exist_ok=False)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(bpy.data.filepath)=='94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert sha(args.native_tools/'worn/hero.blend')=='0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
motion=SimpleSwing(json.loads((HERE/'anchors.json').read_text()))
report=dict(complete=False,production_accepted=False,continuous_video_review=False,
            source={p.name:sha(p) for p in HERE.glob('*') if p.is_file()},renders=[],geometry=[])
def save():
    (args.output/'report.json').write_text(json.dumps(report,indent=2)+'\n')

sys.argv=['blender','--','--native-tools',str(args.native_tools),'--output',str(args.output/'setup'),
          '--gear','worn','--direction','up','--native-motion-pilot','--native-states','idle',
          '--native-loop-counts','idle=1','--validate-only','--threads','2']
env=runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'))
angle=math.radians(args.azimuth)
env['view']('up',(math.sqrt(72)*math.cos(angle),math.sqrt(72)*math.sin(angle)))
report['camera_azimuth_degrees']=args.azimuth
rig,scene=env['r'],env['s']
anchor=world_to_camera_view(scene,scene.camera,Vector((0,0,0)))
report['ground_anchor_160']=[anchor.x*160,(1-anchor.y)*160]
for mod in env['skin']: mod.show_viewport=False

def base_apply(p):
    supplied=dict(p);supplied['head']=p['head']@env['head_offset']
    env['apply'](supplied)

base_apply(motion.contact)
align_right_forearm(rig,env['rest'],motion.contact)
reference={n:rig.pose.bones[n].matrix.copy() for n in ('upper.R','lower.R','upper.L','lower.L')}
contact_axes={n:(motion.contact['arms'][n[-1]][1 if n.startswith('upper') else 2]
                 -motion.contact['arms'][n[-1]][0 if n.startswith('upper') else 1]).normalized() for n in reference}

def apply(p):
    for mod in env['skin']: mod.show_viewport=False
    base_apply(p)
    target={b.name:b.matrix.copy() for b in rig.pose.bones}
    carry=p['torso'].to_3x3()@motion.contact['torso'].to_3x3().inverted()
    for n,m in reference.items():
        s=n[-1];j=0 if n.startswith('upper') else 1
        old=carry@contact_axes[n]
        new=(p['arms'][s][j+1]-p['arms'][s][j]).normalized()
        assert 1+old.dot(new)>.05,('Arm reference antipode',n)
        frame=old.rotation_difference(new).to_matrix()@carry@m.to_3x3()
        target[n]=frame.to_4x4();target[n].translation=p['arms'][s][j]
    for b in rig.pose.bones:
        parent=b.parent
        b.matrix_basis=b.bone.convert_local_to_pose(target[b.name],b.bone.matrix_local,
            parent_matrix=target[parent.name] if parent else Matrix.Identity(4),
            parent_matrix_local=parent.bone.matrix_local if parent else Matrix.Identity(4),invert=True)
    bpy.context.view_layer.update()
    grip=max((((rig.pose.bones['hand.'+s].matrix@rig.data.bones['hand.'+s].matrix_local.inverted())
        @env['rest']['grips'][s])-p['grips'][s]).length for s in native_motion.SIDES)
    assert grip<1e-5,('Grip',grip)
    reach=max((c[2]-c[0]).length for c in p['arms'].values())
    assert reach<.70,('Reach',reach)
    return dict(reach=reach,grip=grip,hand_contact=p.get('hand_contact'),
                support_release=p.get('support_release'),
                tool_cap=list(p['rear']+motion.frame(p['axis'])@motion.local_cap),
                arm_quaternions={n:list(rig.pose.bones[n].matrix.to_quaternion()) for n in reference})

try:
    # One cheap check for real anatomical failures before rendering four images.
    for i in range(121):
        t=i/120
        p=motion.sample('mine',phase(t))
        report['geometry'].append(dict(progress=t,**apply(p)))
    save()
    # Fifty samples put gameplay contact .42 exactly at frame21.
    times=[] if args.check_only else ([i/50 for i in range(50)] if args.loop else motion.review_times)
    for i,t in enumerate(times):
        p=motion.sample('mine',phase(t));check=apply(p)
        for mod in env['skin']:mod.show_viewport=True
        env['blink'](0.);bpy.context.view_layer.update()
        name=f'frame-{i:04d}'
        scene.render.filepath=str(args.output/(name+'.png'))
        env['mask'].base_path=str(args.output);env['mask'].file_slots[0].path='mask-'+name+'-'
        scene.frame_current=1
        bpy.ops.render.render(write_still=True)
        report['renders'].append(dict(file=name+'.png',progress=t,seconds=t*CYCLE,**check))
        save()
    report['complete']=True;save()
    print('OVERHEAD_SWING_COMPLETE',len(report['renders']),flush=True)
except Exception as exc:
    report['error']=str(exc);save();raise
