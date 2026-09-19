"""Exact native pose adapters for two observed interruption/entry seams.

Keeps the approved FlowSwing20 bank byte-identical. A sparse edge bank is
explicitly scoped by source family/cell, direction and gameplay clock.
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
from bpy_extras.object_utils import world_to_camera_view

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
parser = argparse.ArgumentParser()
parser.add_argument('--native-tools', type=Path, required=True)
parser.add_argument('--baseline-root', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--render', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
args.output.mkdir(parents=True, exist_ok=False)
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools),
            '--output', str(args.output/'setup'), '--check-only', '--continuous-return']
old = runpy.run_path(str(HERE.parent/'transition_19/render_walk_bridge.py'))
base = old['base']
env, motion, rig, scene = [base[n] for n in ('env', 'motion', 'rig', 'scene')]
pm, legacy, phase, blend_matrix = [old[n] for n in ('pm', 'motion_v9', 'phase', 'blend_matrix')]
SIDES = ('R', 'L')
ARMS = old['ARM']
views = {'up': (6,6), 'down': (1.6,-6), 'left': (6,-1), 'right': (-6,-1)}
reference_camera = scene.camera.matrix_world.to_3x3().copy()
reference_lights = {o.name:o.matrix_world.copy() for o in scene.objects if o.type=='LIGHT'}
conversions = {}
legacy_lights = {}
for direction, xy in views.items():
    env['view'](direction, xy)
    conversions[direction] = reference_camera@scene.camera.matrix_world.to_3x3().transposed()
    legacy_lights[direction] = {o.name:conversions[direction].to_4x4()@o.matrix_world
                               for o in scene.objects if o.type=='LIGHT'}
env['view']('up', (0., math.sqrt(72)))

def legacy_pose(direction, state, seconds):
    p = legacy.sample(seconds, state, 'pickaxe')
    r = conversions[direction]
    q = dict(p)
    for k in ('torso', 'head'): q[k] = r.to_4x4()@p[k]
    for k in ('rear', 'axis', 'tool_normal'): q[k] = r@p[k]
    for k in ('grips', 'hand_axes', 'radials'):
        q[k] = {s:r@v for s,v in p[k].items()}
    for k in ('arms', 'legs'):
        q[k] = {s:tuple(r@v for v in c) for s,c in p[k].items()}
    q['foot_rotations'] = {s:r@p.get('foot_rotations',{}).get(s,Matrix.Identity(3)) for s in SIDES}
    q['_legacy'] = (direction,seconds,state)
    return q

def matrices():
    return {b.name:b.matrix.copy() for b in rig.pose.bones}

def apply_family(p, family, parameter=0.):
    if family == 'flow20': base['apply'](p)
    elif family == 'walk19': old['apply'](p, parameter)
    else:
        direction,seconds,state = p['_legacy']
        base['base_apply'](legacy.sample(seconds,state,'pickaxe'))
        # The legacy rest-axis bone solver is not rotation-equivariant.
        # Rotate its actual matrices, not just its IK target positions.
        r = conversions[direction].to_4x4()
        set_matrices({n:r@m for n,m in matrices().items()})
    return matrices()

def set_matrices(target):
    for bone in rig.pose.bones:
        parent = bone.parent
        bone.matrix_basis = bone.bone.convert_local_to_pose(target[bone.name],bone.bone.matrix_local,
            parent_matrix=target[parent.name] if parent else Matrix.Identity(4),
            parent_matrix_local=parent.bone.matrix_local if parent else Matrix.Identity(4),invert=True)
    bpy.context.view_layer.update()

def chain_frame(chain):
    root, elbow, tip = chain
    axis = (tip-root).normalized()
    radial = elbow-root
    radial -= axis*radial.dot(axis)
    assert radial.length > .01, ('undefined elbow plane', radial.length)
    radial.normalize()
    return Matrix((axis, radial, axis.cross(radial))).transposed().to_quaternion()

def plane_pole(a,b,root,tip,w):
    frame = chain_frame(a).slerp(chain_frame(b),w).to_matrix()
    axis = (tip-root).normalized()
    assert frame.col[0].dot(axis)>-.95, 'chain transport antipode'
    radial = frame.col[0].rotation_difference(axis)@frame.col[1]
    return root+radial

def segment_frame(chain,j):
    y = (chain[j+1]-chain[j]).normalized()
    z = (chain[1]-chain[0]).cross(chain[2]-chain[1]).normalized()
    x = y.cross(z).normalized()
    return Matrix((x,y,z)).transposed()

def mix(a, b, w, u):
    if w <= 0: return a
    if w >= 1: return b
    q = dict(a)
    for k in ('torso', 'head'): q[k] = blend_matrix(a[k], b[k], w)
    qa = pm.tool_frame(a['axis'], a['tool_normal']).to_quaternion()
    qb = pm.tool_frame(b['axis'], b['tool_normal']).to_quaternion()
    tool = qa.slerp(qb, w).to_matrix()
    entry = '_legacy' in a and '_legacy' not in b
    ar,br,body = [p['torso'].to_3x3() for p in (a,b,q)]
    if entry:
        ta,tb = ar.transposed()@qa.to_matrix(),br.transposed()@qb.to_matrix()
        tool = body@ta.to_quaternion().slerp(tb.to_quaternion(),w).to_matrix()
    q['rear'] = a['rear'].lerp(b['rear'], w)
    q['axis'], q['tool_normal'] = tool.col[0], tool.col[2]
    for k in ('grips', 'hand_axes', 'radials', 'arms', 'legs', 'foot_rotations'): q[k] = {}
    for s, sign in [('R',-1),('L',1)]:
        # Interpolate grip offsets in the rigid tool frame; two attached
        # hands remain attached instead of cutting across a rotating shaft.
        ga = qa.to_matrix().transposed()@(a['grips'][s]-a['rear'])
        gb = qb.to_matrix().transposed()@(b['grips'][s]-b['rear'])
        q['grips'][s] = q['rear']+tool@ga.lerp(gb,w)
        ha = pm.tool_frame(a['hand_axes'][s],a['radials'][s]).to_quaternion()
        hb = pm.tool_frame(b['hand_axes'][s],b['radials'][s]).to_quaternion()
        hand = ha.slerp(hb,w).to_matrix()
        axis, radial = hand.col[0], hand.col[2]
        if entry:
            if s=='R':
                axis = tool.col[0]
                ra = qa.to_matrix().transposed()@a['radials'][s]
                rb = qb.to_matrix().transposed()@b['radials'][s]
                radial = tool@ra.slerp(rb,w).normalized()
            else:
                la,lb = ar.transposed()@ha.to_matrix(),br.transposed()@hb.to_matrix()
                hand = body@la.to_quaternion().slerp(lb.to_quaternion(),w).to_matrix()
                axis,radial = hand.col[0],hand.col[2]
        q['hand_axes'][s], q['radials'][s] = axis, radial
        wrist = q['grips'][s]+radial*.122-axis.cross(radial)*sign*.015-axis*.005
        shoulder = q['torso']@Vector((sign*.355,-.04,1.05))
        if entry:
            # The carry-to-raised pose must go around the shoulder rather
            # than interpolate its wrist through it. Preserve interpolated
            # arm reach on a torso-relative spherical path. The support
            # hand releases into the approved sink's free-hand position.
            va = ar.transposed()@(a['arms'][s][2]-a['arms'][s][0])
            vb = br.transposed()@(b['arms'][s][2]-b['arms'][s][0])
            assert va.normalized().dot(vb.normalized())>-.98
            reach = va.length+(vb.length-va.length)*w
            wrist = shoulder+body@(va.normalized().slerp(vb.normalized(),w)*reach)
            q['grips'][s] = wrist-radial*.122+axis.cross(radial)*sign*.015+axis*.005
            if s=='R': q['rear'] = q['grips'][s]
        # World-space elbow interpolation can cross the shoulder/wrist line
        # and flip the bend plane. Interpolate complete chain frames, then
        # transport their radial onto the actual current wrist axis.
        source_chain,target_chain = a['arms'][s],b['arms'][s]
        if entry:
            source_chain = tuple(q['torso']@a['torso'].inverted()@v for v in source_chain)
            target_chain = tuple(q['torso']@b['torso'].inverted()@v for v in target_chain)
        pole = plane_pole(source_chain,target_chain,shoulder,wrist,w)
        q['arms'][s] = (shoulder,pm.solve(shoulder,wrist,pole,.36,.35),wrist)
        # Brake/turn with alternating planted feet. The first direct blend
        # slid both ankles by about9px while the gameplay root was stationary.
        # Left steps first; right stays fixed until left has landed.
        step = min(1.,max(0.,u*2 if s=='L' else (u-.5)*2))
        foot_w = pm.smooth(step)
        hip = a['legs'][s][0].lerp(b['legs'][s][0],w)
        foot = a['legs'][s][2].lerp(b['legs'][s][2],foot_w)
        foot += Vector((0,0,.035*math.sin(math.pi*step)))
        pole = plane_pole(a['legs'][s],b['legs'][s],hip,foot,w)
        q['legs'][s] = (hip,pm.solve(hip,foot,pole,.180,.184),foot)
        q['foot_rotations'][s] = a['foot_rotations'][s].to_quaternion().slerp(b['foot_rotations'][s].to_quaternion(),foot_w).to_matrix()
    return q

def install(p, a, b, ma, mb, w):
    base['base_apply'](p)
    target = matrices()
    for family,prefixes in [('arms',('upper','lower')),('legs',('thigh','shin'))]:
        for side in SIDES:
            for j,prefix in enumerate(prefixes):
                name = prefix+'.'+side
                # Preserve each endpoint's local bone roll. A chain-relative
                # frame avoids projecting a distant slerped bone axis through
                # an antipode and does not inherit the legacy rest-axis flip.
                ra = segment_frame(a[family][side],j).transposed()@ma[name].to_3x3()
                rb = segment_frame(b[family][side],j).transposed()@mb[name].to_3x3()
                roll = ra.to_quaternion().slerp(rb.to_quaternion(),w).to_matrix()
                target[name] = (segment_frame(p[family][side],j)@roll).to_4x4()
                target[name].translation = p[family][side][j]
    for name in ('root','hips'):
        target[name] = blend_matrix(ma[name],mb[name],w)
    set_matrices(target)
    reach = max((c[2]-c[0]).length for c in p['arms'].values())
    grip = max((((rig.pose.bones['hand.'+s].matrix@rig.data.bones['hand.'+s].matrix_local.inverted())
                  @env['rest']['grips'][s])-p['grips'][s]).length for s in SIDES)
    assert reach < .70, ('reach',reach)
    assert grip < 1e-5, ('hand error',grip)
    return {'reach':reach,'grip':grip,
            'reach_by_side':{s:(c[2]-c[0]).length for s,c in p['arms'].items()},
            'feet_pixels':{s:project(p['legs'][s][2]) for s in SIDES},
            'bone_quaternions':{n:list(m.to_quaternion()) for n,m in matrices().items()},
            'arm_quaternions':{n:list(rig.pose.bones[n].matrix.to_quaternion()) for n in ARMS}}

def project(v):
    q = world_to_camera_view(scene,scene.camera,v)
    return [q.x*160,(1-q.y)*160]

def difference(a,b):
    return max(abs(a[n][i][j]-b[n][i][j]) for n in a for i in range(4) for j in range(4))

def lighting(p,family):
    return legacy_lights[p['_legacy'][0]] if family=='legacy' else reference_lights

def temporal(rows):
    # Quaternion signs represent the same rotation; compare normalized
    # absolute dot products. These limits catch flips, not visual quality.
    peaks = {}
    for a,b in zip(rows,rows[1:]):
        for name,qa in a['bone_quaternions'].items():
            qb = b['bone_quaternions'][name]
            dot = sum(x*y for x,y in zip(qa,qb))/math.sqrt(sum(x*x for x in qa)*sum(x*x for x in qb))
            angle = math.degrees(2*math.acos(min(1.,abs(dot))))
            if angle>peaks.get(name,{}).get('degrees',-1):
                peaks[name] = {'degrees':angle,'seconds':b['seconds'],
                               'degrees_per_second':angle/(b['seconds']-a['seconds'])}
    return peaks

report = {'complete':False,'scope':'Two exact observed seams; no arbitrary input coverage',
          'approved_loop_changed':False,'anchor':base['report']['ground_anchor_160'],
          'source_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'geometry':{},'temporal':{},'renders':[],'edges':{},'production_accepted':False}
def save(): (args.output/'report.json').write_text(json.dumps(report,indent=2)+'\n')

try:
    interrupt = json.loads(Path(str(args.baseline_root)+'-interrupt','report.json').read_text())
    entry = json.loads(Path(str(args.baseline_root)+'-walk-entry','report.json').read_text())
    # The almost-half-turn brake needs time for two visible planted steps.
    # Nine frames exceeded45deg in one arm at60Hz despite continuous IK.
    cases = [('interrupt',interrupt,90,14),('walk-entry',entry,8,8)]
    for name,capture,event,steps in cases:
        shown = capture['samples'][event-1]
        first = capture['samples'][event]
        if name == 'interrupt':
            cell = shown['transition']['walk_bridge_cell']
            assert shown['transition']['walk_bridge_active'] and cell==6, shown
            source, source_w = old['sample'](cell/60)
            source_family = 'walk19'
            ma = apply_family(source,'walk19',source_w)
            destination_direction = first['direction']
            def destination(t, end=False):
                return legacy_pose(destination_direction,'idle',0.),'legacy'
            desc = {'family':'walk19','cell':cell,'direction':shown['direction'],
                    'target_state':'idle','target_direction':destination_direction,
                    'target_idle_cell':0,'target_sample_time':0.,'target_idle_seconds':.15}
        else:
            assert shown['production_state']=='walk' and shown['direction']=='up', shown
            cell = shown['production_frame']
            source = legacy_pose('up','walk',cell/60)
            source_family = 'legacy'
            ma = apply_family(source,'legacy')
            initial_progress = first['progress']-1/60/.68
            assert abs(initial_progress)<.001, first
            sink_progress = round((initial_progress+steps/60/.68)*50)/50
            def destination(t, end=False):
                # A fixed future sample avoids switching the shortest-path
                # quaternion branch as a moving sink crosses a half-turn.
                # It is exactly the approved cell presented at completion.
                return motion.sample('mine',phase(sink_progress)),'flow20'
            desc = {'family':'legacy-walk','cell':cell,'direction':'up',
                    'target_state':'mine','target_direction':'up','target_start_progress':initial_progress,
                    'target_cell':round(sink_progress*50),'target_progress':sink_progress}
        duration = steps/60
        desc.update(duration=duration,steps=steps,source_game_frame=event-1,
                    source_report_sha256=hashlib.sha256(Path(str(args.baseline_root)+'-'+name,'report.json').read_bytes()).hexdigest())
        report['edges'][name]=desc
        rows=[]
        # Gate actual complete-bone endpoint identity and native reach before
        # any PNG rendering. Contact paths are recorded, not called foot-lock proof.
        for i in range(61):
            t=duration*i/60;w=pm.smooth(t/duration)
            target,family=destination(t,i==60)
            mb=apply_family(target,family)
            p=mix(source,target,w,t/duration)
            check=install(p,source,target,ma,mb,w)
            if i in (0,60):
                error=difference(matrices(),ma if i==0 else mb)
                assert error<1e-5, ('endpoint mismatch',name,i,error)
                check['endpoint_matrix_error']=error
            rows.append({'seconds':t,**check})
            planted = 'R' if i<=30 else 'L'
            fixed = source if planted=='R' else target
            assert (p['legs'][planted][2]-fixed['legs'][planted][2]).length<1e-6
            assert max(abs(p['foot_rotations'][planted][j][k]-fixed['foot_rotations'][planted][j][k]) for j in range(3) for k in range(3))<1e-6
            check['planted_side']=planted
        report['geometry'][name]=rows
        report['temporal'][name]={'substeps':temporal(rows)}
        frame_rows=[]
        for i in range(steps+1):
            t=i/60;w=pm.smooth(t/duration)
            target,family=destination(t,i==steps);mb=apply_family(target,family)
            p=mix(source,target,w,t/duration)
            frame_rows.append({'seconds':t,**install(p,source,target,ma,mb,w)})
        report['temporal'][name]['frames_60hz']=temporal(frame_rows)
        save()
        assert max(v['degrees_per_second'] for v in report['temporal'][name]['substeps'].values())<3600, ('substep rotation spike',name)
        assert max(v['degrees'] for v in report['temporal'][name]['frames_60hz'].values())<45, ('frame rotation spike',name)
        if args.render:
            for i in range(steps+1):
                t=i/60;w=pm.smooth(t/duration)
                target,family=destination(t,i==steps);mb=apply_family(target,family)
                p=mix(source,target,w,t/duration);check=install(p,source,target,ma,mb,w)
                source_lights,target_lights=lighting(source,source_family),lighting(target,family)
                for light,matrix in source_lights.items():
                    scene.objects[light].matrix_world=blend_matrix(matrix,target_lights[light],w)
                for mod in env['skin']:mod.show_viewport=True
                env['blink'](0.);bpy.context.view_layer.update()
                filename=f'{name}-{i:03d}'
                scene.render.filepath=str(args.output/(filename+'.png'))
                env['mask'].base_path=str(args.output);env['mask'].file_slots[0].path='mask-'+filename+'-'
                scene.frame_current=1
                bpy.ops.render.render(write_still=True)
                report['renders'].append({'edge':name,'step':i,'seconds':t,'file':filename+'.png',**check});save()
    report['complete']=True;save()
    print('TRANSITION21_NATIVE_COMPLETE',len(report['renders']),flush=True)
except Exception as exc:
    report['error']=str(exc);save();raise
