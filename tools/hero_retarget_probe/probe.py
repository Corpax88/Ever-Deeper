"""Small, isolated donor-motion trial on the approved hero and Worn tool.

No gameplay, production atlas or original Blender file is changed. The donor
supplies torso/limb motion; the native hands retain their original closed grips.
"""
import argparse
import copy
import hashlib
import json
import math
from pathlib import Path
import runpy
import sys
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('--glb', type=Path, required=True)
p.add_argument('--native-tools', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--fit-grips', action='store_true')
p.add_argument('--chop-driver', choices=('wrist-pair', 'right-hand'), default='wrist-pair')
p.add_argument('--max-tool-correction', type=float, default=.10,
               help='Study gate in native model units, not visual acceptance')
p.add_argument('--render', choices=('none', 'keys'), default='none')
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
assert not a.output.exists(), 'Use a fresh attempt directory'
a.output.mkdir(parents=True)
model_hash = hashlib.sha256(Path(bpy.data.filepath).read_bytes()).hexdigest()
assert model_hash == '94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
donor_hash = hashlib.sha256(a.glb.read_bytes()).hexdigest()
assert donor_hash == '8cee20ab1bc55130092447e810e26df22dd2803eccc54f52137a7d54d7ab88a8', 'Expected the verified UAL2 Standard donor'
sys.argv = ['blender', '--', '--native-tools', str(a.native_tools), '--output', str(a.output/'setup'),
            '--gear', 'worn', '--native-motion-pilot', '--native-states', 'idle',
            '--native-loop-counts', 'idle=1', '--direction', 'up', '--validate-only', '--threads', '2']
env = runpy.run_path(str(ROOT/'tools/hero_v28/export_hero.py'))
rig, scene, native_rest = env['r'], env['s'], env['rest']
import motion_v2
import motion_v3

for m in env['skin']:
    m.show_viewport = False
before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(a.glb))
added = set(bpy.data.objects) - before
donor = next(x for x in added if x.type == 'ARMATURE')
for x in added:
    if x.type == 'MESH':
        x.hide_render = True
        x.hide_set(True)
donor.animation_data_create()
donor.animation_data.use_nla = False
rest_bones = {b.name: b.matrix_local.copy() for b in donor.data.bones}
native_bones = {b.name: b.matrix_local.copy() for b in rig.data.bones}
src_arm = sum(donor.data.bones[n].length for n in ('upperarm_r','lowerarm_r'))
arm_scale = (.36 + .35) / src_arm
leg_scale = (.180 + .184) / sum(donor.data.bones[n].length for n in ('thigh_r','calf_r'))
T = Matrix.Translation
Z = Vector((0,0,1))
forward = Vector((0,-1,0))
native_frame = motion_v3.frame_matrix(native_rest['axis'], native_rest['tool_normal'])
records = []

def source_pose(action_name, phase):
    action = bpy.data.actions[action_name]
    donor.animation_data.action = action
    donor.animation_data.action_slot = action.slots[0]
    lo, hi = action.frame_range
    f = lo + phase*(hi-lo)
    scene.frame_set(int(f), subframe=f-int(f))
    return {b.name: b.matrix.copy() for b in donor.pose.bones}

def rotation(m, name):
    return m[name].to_quaternion() @ rest_bones[name].to_quaternion().inverted()

def limb_direction(m, name):
    return (m[name].to_3x3() @ Vector((0,1,0))).normalized()

def retarget(action, phase):
    m = source_pose(action, phase)
    result = copy.deepcopy(native_rest)
    displacement = (m['pelvis'].translation-rest_bones['pelvis'].translation)*leg_scale
    body_rot = rotation(m, 'spine_03')
    body_pivot = native_bones['body'].translation
    torso = T(displacement) @ T(body_pivot) @ body_rot.to_matrix().to_4x4() @ T(-body_pivot)
    head_rot = rotation(m, 'Head')
    head_pivot = torso @ native_bones['head'].translation
    result['torso'] = torso
    result['head'] = T(head_pivot) @ head_rot.to_matrix().to_4x4() @ T(-native_bones['head'].translation)
    hip_rot = rotation(m, 'pelvis')
    result['foot_rotations'] = {}
    for side in ('R','L'):
        s = side.lower()
        hip0 = native_bones['thigh.'+side].translation
        hip = native_bones['hips'].translation + hip_rot @ (hip0-native_bones['hips'].translation) + displacement
        knee = hip + limb_direction(m,'thigh_'+s)*.180
        ankle = knee + limb_direction(m,'calf_'+s)*.184
        result['legs'][side] = (hip,knee,ankle)
        result['foot_rotations'][side] = rotation(m,'foot_'+s).to_matrix()
    # This first compatibility probe keeps the lower ankle at the original
    # floor height. It is not a sole-contact solver or an accepted game gait.
    lift = min(native_bones['foot.'+s].translation.z for s in ('R','L')) - min(result['legs'][s][2].z for s in ('R','L'))
    offset = Vector((0,0,lift))
    result['torso'] = T(offset) @ result['torso']
    result['head'] = T(offset) @ result['head']
    for side in ('R','L'):
        result['legs'][side] = tuple(v+offset for v in result['legs'][side])
    torso = result['torso']
    shoulders = {s: torso @ native_bones['upper.'+s].translation for s in ('R','L')}
    src_mid = (m['hand_r'].translation+m['hand_l'].translation)*.5
    src_shoulder = (m['upperarm_r'].translation+m['upperarm_l'].translation)*.5
    center = (shoulders['R']+shoulders['L'])*.5 + (src_mid-src_shoulder)*arm_scale
    axis = (m['hand_l'].translation-m['hand_r'].translation).normalized()
    if action == 'TreeChopping_Loop' and a.chop_driver == 'right-hand':
        # Actual source poses show a one-handed chop, with the free hand about
        # one body-width away. Its wrist pair cannot define a tool shaft.
        # Use the chopping fist's knuckle line; preserve its right wrist path.
        axis = (m['index_01_r'].translation-m['pinky_01_r'].translation).normalized()
    normal = body_rot @ forward
    normal = (normal-axis*normal.dot(axis)).normalized()
    tool_rotation = motion_v3.frame_matrix(axis,normal) @ native_frame.inverted()
    rear = center-axis*.0725
    radial = {s: tool_rotation @ native_rest['radials'][s] for s in ('R','L')}
    wrist_offsets = {}
    for s,sign in (('R',-1),('L',1)):
        wrist_offsets[s] = axis*(.145 if s=='L' else 0) + radial[s]*.122 - axis.cross(radial[s])*sign*.015 - axis*.005
    if action == 'TreeChopping_Loop' and a.chop_driver == 'right-hand':
        right_wrist = shoulders['R'] + (m['hand_r'].translation-m['upperarm_r'].translation)*arm_scale
        rear = right_wrist-wrist_offsets['R']
    raw_reach = {s: (rear+wrist_offsets[s]-shoulders[s]).length for s in ('R','L')}
    original_rear = rear.copy()
    if a.fit_grips:
        # Projection of one rigid tool translation into both native arm reach
        # balls. Both grips move together; limb lengths and hand meshes stay fixed.
        for _ in range(12):
            for s in ('R','L'):
                v = rear+wrist_offsets[s]-shoulders[s]
                if v.length > .69:
                    rear -= v.normalized()*(v.length-.69)
    reach = {s: (rear+wrist_offsets[s]-shoulders[s]).length for s in ('R','L')}
    feasible = all(.011 < v < .7099 for v in reach.values())
    result.update(rear=rear, axis=axis, tool_normal=normal)
    result['grips'] = {'R':rear,'L':rear+axis*.145}
    result['radials'] = radial
    result['hand_axes'] = {s:axis for s in ('R','L')}
    if feasible:
        for s in ('R','L'):
            wrist = rear+wrist_offsets[s]
            donor_elbow = m['lowerarm_'+s.lower()].translation
            donor_shoulder = m['upperarm_'+s.lower()].translation
            pole = shoulders[s] + (donor_elbow-donor_shoulder)*arm_scale
            elbow = motion_v2.solve(shoulders[s], wrist, pole, .36, .35)
            result['arms'][s] = (shoulders[s],elbow,wrist)
    metric = {'action':action,'phase':phase,'raw_reach':raw_reach,'reach':reach,
              'tool_translation_correction':(rear-original_rear).length,'feasible':feasible,
              'source_wrist_gap':(m['hand_l'].translation-m['hand_r'].translation).length,
              'tool_rear':list(rear),'tool_axis':list(axis),'floor_lift':lift}
    return result,metric

# First measure the actual complete cycles before any expensive image output.
cache = {}
for action in ('Walk_Carry_Loop','TreeChopping_Loop'):
    for i in range(33):
        pose,metric = retarget(action,i/32)
        records.append(metric)
        cache[(action,i)] = pose
report = {'model_sha256':model_hash,'donor_sha256':donor_hash,
          'native_bones':len(rig.data.bones),'donor_bones':len(donor.data.bones),
          'arm_scale':arm_scale,'leg_scale':leg_scale,'fit_grips':a.fit_grips,'chop_driver':a.chop_driver,
          'all_reachable':all(x['feasible'] for x in records),
          'max_raw_reach':max(max(x['raw_reach'].values()) for x in records),
          'max_tool_translation_correction':max(x['tool_translation_correction'] for x in records),
          'records':records,'rendered':False,'production_accepted':False,
          'known_limits':['ankle-height floor approximation; sole contact unverified',
                          'stock chopping is not yet aligned to the gameplay impact phase',
                          'no actual-game transfer or arbitrary interruption acceptance']}
report['max_tool_correction_limit'] = a.max_tool_correction
report['correction_within_limit'] = report['max_tool_translation_correction'] <= a.max_tool_correction
report['source_duration_seconds'] = {
    name: float(bpy.data.actions[name].frame_range[1]-bpy.data.actions[name].frame_range[0]) /
          (scene.render.fps/scene.render.fps_base)
    for name in ('Walk_Carry_Loop','TreeChopping_Loop')}
(a.output/'probe.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ('records','known_limits')}),flush=True)
if a.render != 'none' and report['all_reachable'] and report['correction_within_limit']:
    env['view']('up',(6,6))
    scene.render.resolution_x = scene.render.resolution_y = 256
    scene.cycles.samples = 4
    scene.render.threads = 2
    scene.render.film_transparent = False
    for node in list(scene.node_tree.nodes):
        if node.type == 'OUTPUT_FILE':
            scene.node_tree.nodes.remove(node)
    poses=[('Walk_Carry_Loop',i/32) for i in (0,8,16)] + [('TreeChopping_Loop',i/32) for i in (0,8,16,24,32)]
    frames=[]
    for index,(action,phase) in enumerate(poses):
        pose,metric=retarget(action,phase)
        posed=copy.deepcopy(pose)
        posed['head']=posed['head'] @ env['head_offset']
        for modifier in env['skin']: modifier.show_viewport=False
        env['apply'](posed)
        for modifier in env['skin']: modifier.show_viewport=True
        bpy.context.view_layer.update()
        path=a.output/('frame-%03d.png'%index)
        scene.render.filepath=str(path)
        bpy.ops.render.render(write_still=True)
        frames.append({'frame':index,'action':action,'phase':phase,'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    report.update(rendered=True,frames=frames)
    (a.output/'probe.json').write_text(json.dumps(report,indent=2)+'\n')
