"""Source-only rigid-tool orientations around the preserved working-cap path.

No native scene load, evaluated mesh, material, image or runtime change. This
shortlist must still pass the real rig/occluder and original-image gates.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import sys
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
sys.path.insert(0,str(HERE.parents[0]/'hero_v28'))
sys.path.insert(0,str(HERE))
import native_motion as native
import premium_motion as pm
import working_surface_arc
import fixed_cap_pivot_pose

selection_path = HERE/'working-surface-selection.json'
assert hashlib.sha256(selection_path.read_bytes()).hexdigest() == '040729e088dc006b73bfc368367ec49897456d11da3cb5f039c18b2883cbcd39'
selection = json.loads(selection_path.read_text())
ground, target = Vector(selection['unchanged_ground']), Vector(selection['target_ground'])
local_cap = Vector(selection['working_surface']['surface_center_tool_local'])
local_normal = Vector(selection['working_surface']['surface_normal_tool_local'])
base_frame = Matrix(selection['contact']['tool_frame'])
scene = bpy.context.scene
data = bpy.data.cameras.new('ReadOnlyProjection');data.type='ORTHO';data.ortho_scale=2.9
camera = bpy.data.objects.new('ReadOnlyProjection',data);scene.collection.objects.link(camera)
camera.location=(6,6,7);camera.rotation_euler=(Vector((0,-.1,.98))-camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera=camera;scene.render.resolution_x=scene.render.resolution_y=200
bpy.context.view_layer.update()


def project(point):
    p = world_to_camera_view(scene,camera,point)
    return [p.x*200,(1-p.y)*200]


def pivot_sample(q, delta):
    return fixed_cap_pivot_pose.sample(q,ground,target,selection['contact'],local_cap,delta)


phases = sorted(set([i/128 for i in range(129)]+[.24,.4,.55,.575,.625,.68,.82]))
report = {'complete':False,'rendered':False,'evaluated_native_rig_or_mesh':False,
          'source_base':'7b1a5ddac56db30dc245f8ddc652b3d2acba73a1',
          'script_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'pose_helper_sha256':hashlib.sha256((HERE/'fixed_cap_pivot_pose.py').read_bytes()).hexdigest(),
          'selection_sha256':hashlib.sha256(selection_path.read_bytes()).hexdigest(),
          'purpose':'Bound a genuine rigid-tool pivot about the same working-cap centroid trajectory, preserving torso/head/root/feet and using real analytic arm IK.',
          'surface_limit':'The centroid stays fixed; the actual terminal patch orientation changes. No projected alpha, 3D ore surface or image acceptance is inferred.',
          'cases':[]}
heading = math.atan2(target.x,-target.y)
for yaw_degrees,pitch_degrees in [(0,30),*[(y,p) for y in (0,15,30) for p in (45,60,75)]]:
    yaw = heading+math.radians(yaw_degrees);pitch=math.radians(pitch_degrees)
    direction=Vector((math.sin(yaw),-math.cos(yaw),0))
    axis=Vector((direction.x*math.cos(pitch),direction.y*math.cos(pitch),math.sin(pitch)))
    normal=Vector((direction.x*math.sin(pitch),direction.y*math.sin(pitch),-math.cos(pitch)))
    target_frame=pm.tool_frame(axis,normal)
    delta=target_frame@base_frame.transposed()
    row={'yaw_about_world_z_degrees':yaw_degrees,'contact_pitch_degrees':pitch_degrees,
         'rigid_rotation':[list(r) for r in delta],'passed':False,'samples':0,
         'max_reach':0.,'max_segment_error':0.,'max_working_cap_centroid_displacement':0.,'poses':[]}
    try:
        for q in phases:
            p,original,protected,cap=pivot_sample(q,delta)
            for key in ('torso','head','legs','foot_rotations','contacts'):assert p[key] is original[key]
            assert native.frame_metadata(p,ground)['feet']==native.frame_metadata(protected,ground)['feet']
            frame=pm.tool_frame(p['axis'],p['tool_normal'])
            row['max_working_cap_centroid_displacement']=max(row['max_working_cap_centroid_displacement'],(p['rear']+frame@local_cap-cap).length)
            for a,b,c in p['arms'].values():
                row['max_reach']=max(row['max_reach'],(c-a).length)
                row['max_segment_error']=max(row['max_segment_error'],abs((b-a).length-.36),abs((c-b).length-.35))
            row['samples']+=1
        for q in (.125,.375,.55,.625,.8125):
            p,original,_,cap=pivot_sample(q,delta)
            row['poses'].append({'phase':q,'rear':list(p['rear']),'rear_pixel':project(p['rear']),
                                 'original_rear_pixel':project(original['rear']),
                                 'support_grip_pixel':project(p['grips']['L']),
                                 'cap_center':list(cap),'cap_center_pixel':project(cap),
                                 'shaft_projection_px_per_native_unit':math.dist(project(p['rear']),project(p['rear']+p['axis']))})
        p,_,_,cap=pivot_sample(.55,delta);_,_,_,before=pivot_sample(.55-.0001,delta)
        velocity=(cap-before)/(.0001*.68*.42/.55)
        outward=pm.tool_frame(p['axis'],p['tool_normal'])@local_normal
        row['working_surface_outward_normal_dot_incoming_velocity']=outward.dot(velocity)
        assert row['max_working_cap_centroid_displacement']<1e-6
        row['passed']=True
    except Exception as error:
        row['failed_phase']=q;row['failure']=repr(error)
    report['cases'].append(row)
report['complete']=True
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps(report,indent=2)+'\n')
print('FIXED_CAP_PIVOT_MATH_COMPLETE',sum(r['passed'] for r in report['cases']),len(report['cases']),flush=True)
