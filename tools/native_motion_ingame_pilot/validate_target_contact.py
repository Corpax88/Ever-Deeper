"""Headless real-rig/part-occlusion/working-end check; never renders images."""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import sys
import bpy
from mathutils import Vector

parser = argparse.ArgumentParser()
parser.add_argument('--native-tools',type=Path,required=True)
parser.add_argument('--project',type=Path,required=True)
parser.add_argument('--recorded',type=Path,required=True)
parser.add_argument('--target-identity',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
args.output.mkdir(parents=True,exist_ok=True)
sys.argv = ['blender','--','--native-tools',str(args.native_tools),'--project',str(args.project),
            '--recorded',str(args.recorded),'--target-identity',str(args.target_identity),'--output',str(args.output/'scene-load'),'--setup-only']
mapped = runpy.run_path(str(HERE/'map_up_contact.py'))
sys.path.insert(0,str(HERE))
import target_contact_pose
env,ground = mapped['env'],mapped['ground']
ready_path = HERE/'contact-arc-readiness.json'
ready = json.loads(ready_path.read_text())
target = Vector(ready['target_ground_vector'])
spec = dict(lateral=-.12,forward=-.4,height=1.15,pitch_degrees=10,roll_degrees=0)
phases = sorted(set([i/128 for i in range(129)]+[.24,.4,.55,.575,.625,.68,.82]))
report = {'complete':False,'rendered':False,'visually_accepted':False,'purpose':'Evaluate one downward-working-end candidate before any image trial',
          'source_base':'bbf18271b6fdb760f3567bf60c960188d5e0f1a6',
          'source_hashes':{name:hashlib.sha256((HERE/name).read_bytes()).hexdigest() for name in ['validate_target_contact.py','target_contact_pose.py','map_up_contact.py','contact-arc-readiness.json']},
          'source_candidate_change':'This +10deg/height1.15/zero-roll case is distinct from the earlier -10deg/height1.0/roll30 target-math proposal. No earlier images are relabeled.',
          'all_phases_projected_into_fixed_recorded_impact_rectangle':True,
          'projection_frame':50,'trajectory_is_actual_runtime_replay':False,
          'specification':spec,'target_ground':list(target),'unchanged_ground':list(ground),
          'model_sha256':mapped['loaded']['report']['model_sha256'],'gear_sha256':mapped['loaded']['report']['gear_sha256'],
          'production_manifest_sha256':mapped['sha'](mapped['production_manifest_path']),
          'dense_evaluated_poses':0,'max_grip_error':0.,'max_reach':0.,'complete_original_lower_body_retained':True,'phases':[]}
rig,rest = env['r'],env['rest']
for modifier in env['skin']: modifier.show_viewport=False
for q in phases:
    p,original=target_contact_pose.sample(q,ground,target,spec)
    for key in ('legs','foot_rotations','contacts'): assert p[key] is original[key]
    assert env['native_motion'].frame_metadata(p,ground)['feet']==env['native_motion'].frame_metadata(original,ground)['feet']
    for a,b,c in p['arms'].values():report['max_reach']=max(report['max_reach'],(c-a).length)
    posed=dict(p);posed['head']=posed['head']@env['head_offset'];env['apply'](posed)
    grip=max(((rig.pose.bones['hand.'+side].matrix@rig.data.bones['hand.'+side].matrix_local.inverted())@rest['grips'][side]-p['grips'][side]).length for side in ('R','L'))
    assert grip<1e-5
    report['max_grip_error']=max(report['max_grip_error'],grip);report['dense_evaluated_poses']+=1
assert report['dense_evaluated_poses']==135
for q in (.375,.55,.625):
    p,_=target_contact_pose.sample(q,ground,target,spec)
    measure=mapped['measure_parts'](p,mapped['sample'])
    assert measure['object_count']==629 and measure['evaluated_triangles']==2714340
    report['phases'].append({'phase':q,**measure})
    (args.output/'target-native-validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print('TARGET_NATIVE_PARTS',q,flush=True)
contact=next(p for p in report['phases'] if p['phase']==.55)
head=next(p for p in contact['parts'] if 'head' in p['object'])
p,_=target_contact_pose.sample(.55,ground,target,spec)
frame=env['premium_motion'].tool_frame(p['axis'],p['tool_normal'])
tips=[]
for tip in head['head_normal_extrema_not_collision_contacts']:
    local=frame.transposed()@(Vector(tip['native_world'])-p['rear'])
    surface=frame.transposed()@Vector(tip['native_surface_normal'])
    def at(q):
        pose,_=target_contact_pose.sample(q,ground,target,spec)
        rotation=env['premium_motion'].tool_frame(pose['axis'],pose['tool_normal'])
        return pose['rear']+rotation@local,rotation@surface
    before,_=at(.55-.0001);point,normal=at(.55)
    velocity=(point-before)/(.0001*.68*.42/.55)
    trajectory=[]
    for q in (.375,.4,.45,.5,.525,.54,.55,.575,.625):
        vertex,n=at(q);xy=mapped['project'](vertex);screen=mapped['scene_point'](xy,mapped['sample'])
        trajectory.append({'phase':q,'native_world':list(vertex),'native_pixel':xy,'ore_alpha_at_projection':mapped['ore_alpha'](screen,mapped['sample'])})
    tips.append({'selector':tip['selector'],'evaluated_mesh_vertex_index':tip['evaluated_mesh_vertex_index'],
                 'surface_normal_at_contact':list(normal),'adjacent_faces_at_contact':tip['adjacent_faces'],
                 'incoming_velocity_native_per_second':list(velocity),'outward_normal_dot_incoming_velocity':normal.dot(velocity),
                 'trajectory':trajectory})
report['head_end_approach']=tips
report['surface_boundary']='Native head vertices/normals are evaluated; the ore is a 2D asset, so alpha overlap and projected approach are not 3D physical collision proof.'
report['complete']=True
(args.output/'target-native-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('TARGET_NATIVE_VALIDATION_COMPLETE',report['dense_evaluated_poses'],report['max_grip_error'],flush=True)
