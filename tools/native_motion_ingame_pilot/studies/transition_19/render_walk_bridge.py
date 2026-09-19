"""One exact native18B→legacy down-walk bridge; no production replacement.

The destination is expressed in the18B camera coordinate system, preserving
its original projected pose and walking phase. Every image is a rig render.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import runpy
import sys

import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
S18 = HERE.parent / 'overhead_swing_18'
sys.path[:0] = [str(S18), str(ROOT/'tools/hero_v28')]
from simple_swing import phase, blend_matrix
import motion_v9
import premium_motion as pm

parser = argparse.ArgumentParser()
parser.add_argument('--native-tools', required=True, type=Path)
parser.add_argument('--output', required=True, type=Path)
parser.add_argument('--check-only', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
args.output.mkdir(parents=True, exist_ok=False)
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--output', str(args.output/'base-check'), '--check-only']
base = runpy.run_path(str(S18/'render_preview.py'))
env, motion, rig, scene = [base[k] for k in ('env', 'motion', 'rig', 'scene')]
camera_rotation = scene.camera.matrix_world.to_3x3().copy()
env['view']('down', (1.6, -6))
legacy_rotation = scene.camera.matrix_world.to_3x3().copy()
env['view']('up', (0., math.sqrt(72)))
conversion = camera_rotation @ legacy_rotation.transposed()
source = motion.sample('mine', phase(.62))
base['apply'](source)
source_matrices = {b.name:b.matrix.copy() for b in rig.pose.bones}
ARM = ('upper.R', 'lower.R', 'upper.L', 'lower.L')
DURATION = .20
SPEED = 340.
STRIDE = 144.

def transform(p):
    r = conversion
    q = dict(p)
    for k in ('torso', 'head'): q[k] = r.to_4x4() @ p[k]
    for k in ('rear', 'axis', 'tool_normal'): q[k] = r @ p[k]
    for k in ('grips', 'hand_axes', 'radials'):
        q[k] = {s:r@v for s,v in p[k].items()}
    for k in ('arms', 'legs'):
        q[k] = {s:tuple(r@v for v in chain) for s,chain in p[k].items()}
    q['foot_rotations'] = {s:r for s in ('R','L')}
    return q

def sample(seconds):
    w = pm.smooth(seconds/DURATION)
    # Same distance-driven phase and .8s source pose as the legacy consumer.
    walk_phase = seconds*SPEED/STRIDE
    target = transform(motion_v9.sample(walk_phase*.8, 'walk', 'pickaxe'))
    if seconds <= 0: return source, w
    if seconds >= DURATION: return target, w
    q = dict(source)
    for k in ('torso', 'head'): q[k] = blend_matrix(source[k],target[k],w)
    qa = pm.tool_frame(source['axis'],source['tool_normal']).to_quaternion()
    qb = pm.tool_frame(target['axis'],target['tool_normal']).to_quaternion()
    tool = qa.slerp(qb,w).to_matrix()
    q['rear'] = source['rear'].lerp(target['rear'],w)
    q['axis'],q['tool_normal'] = tool.col[0],tool.col[2]
    q['grips'],q['hand_axes'],q['radials'],q['arms'],q['legs'],q['foot_rotations'] = {},{},{},{},{},{}
    for side, sign in [('R',-1),('L',1)]:
        a,b = source,target
        q['grips'][side] = q['rear'] if side=='R' else a['grips'][side].lerp(q['rear']+q['axis']*.145,w)
        hand_a = pm.tool_frame(a['hand_axes'][side],a['radials'][side]).to_quaternion()
        hand_b = pm.tool_frame(b['hand_axes'][side],b['radials'][side]).to_quaternion()
        hand = hand_a.slerp(hand_b,w).to_matrix()
        axis,radial = hand.col[0],hand.col[2]
        q['hand_axes'][side],q['radials'][side] = axis,radial
        wrist = q['grips'][side]+radial*.122-axis.cross(radial)*sign*.015-axis*.005
        shoulder = q['torso']@Vector((sign*.355,-.04,1.05))
        pole = a['arms'][side][1].lerp(b['arms'][side][1],w)
        q['arms'][side] = (shoulder,pm.solve(shoulder,wrist,pole,.36,.35),wrist)
        hip = a['legs'][side][0].lerp(b['legs'][side][0],w)
        foot = a['legs'][side][2].lerp(b['legs'][side][2],w)
        pole = a['legs'][side][1].lerp(b['legs'][side][1],w)
        q['legs'][side] = (hip,pm.solve(hip,foot,pole,.180,.184),foot)
        q['foot_rotations'][side] = a['foot_rotations'][side].to_quaternion().slerp(b['foot_rotations'][side].to_quaternion(),w).to_matrix()
    return q,w

def apply(p,w):
    for mod in env['skin']: mod.show_viewport=False
    base['base_apply'](p)
    targets = {b.name:b.matrix.copy() for b in rig.pose.bones}
    carry = p['torso'].to_3x3()@source['torso'].to_3x3().inverted()
    for name in ARM:
        s=name[-1];j=0 if name.startswith('upper') else 1
        old=carry@(source['arms'][s][j+1]-source['arms'][s][j]).normalized()
        new=(p['arms'][s][j+1]-p['arms'][s][j]).normalized()
        frame=old.rotation_difference(new).to_matrix()@carry@source_matrices[name].to_3x3()
        targets[name]=frame.to_quaternion().slerp(targets[name].to_quaternion(),w).to_matrix().to_4x4()
        targets[name].translation=p['arms'][s][j]
    for bone in rig.pose.bones:
        parent=bone.parent
        bone.matrix_basis=bone.bone.convert_local_to_pose(targets[bone.name],bone.bone.matrix_local,
            parent_matrix=targets[parent.name] if parent else Matrix.Identity(4),
            parent_matrix_local=parent.bone.matrix_local if parent else Matrix.Identity(4),invert=True)
    bpy.context.view_layer.update()
    reach=max((c[2]-c[0]).length for c in p['arms'].values())
    grip=max((((rig.pose.bones['hand.'+s].matrix@rig.data.bones['hand.'+s].matrix_local.inverted())
              @env['rest']['grips'][s])-p['grips'][s]).length for s in ('R','L'))
    assert reach < .70, ('Reach',reach)
    assert grip < 1e-5, ('Grip',grip)
    return {'reach':reach,'grip':grip}

report={'complete':False,'duration':DURATION,'source_cell':31,'source_progress':.62,
        'destination_direction':'down','walk_phase_start':0.,'walk_stride':STRIDE,
        'anchor':base['report']['ground_anchor_160'],'geometry':[],'renders':[],
        'source_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'production_accepted':False}
def save(): (args.output/'report.json').write_text(json.dumps(report,indent=2)+'\n')
try:
    for i in range(61):
        t=DURATION*i/60;p,w=sample(t)
        report['geometry'].append({'seconds':t,**apply(p,w)})
    save()
    if not args.check_only:
        for i in range(13):
            t=i/60;p,w=sample(t);geometry=apply(p,w)
            for mod in env['skin']:mod.show_viewport=True
            env['blink'](0.);bpy.context.view_layer.update()
            name=f'frame-{i:04d}'
            scene.render.filepath=str(args.output/(name+'.png'))
            env['mask'].base_path=str(args.output);env['mask'].file_slots[0].path='mask-'+name+'-'
            scene.frame_current=1
            bpy.ops.render.render(write_still=True)
            report['renders'].append({'file':name+'.png','seconds':t,**geometry});save()
    report['complete']=True;save()
    print('WALK_BRIDGE_COMPLETE',len(report['renders']),flush=True)
except Exception as exc:
    report['error']=str(exc);save();raise
