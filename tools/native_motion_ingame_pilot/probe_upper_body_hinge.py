"""Cheap reach/joint/projection probe; no native mesh or visibility verdict."""
from pathlib import Path
import argparse
import hashlib
import json
import sys
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

parser = argparse.ArgumentParser()
for name in ('joint-report', 'pivot-report', 'output'):
    parser.add_argument('--'+name, type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent/'hero_v28'))
sys.path.insert(0, str(HERE))
import native_motion as native
import premium_motion as pm
import upper_body_hinge_pose

sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
selection_path = HERE/'working-surface-selection.json'
assert sha(selection_path) == '040729e088dc006b73bfc368367ec49897456d11da3cb5f039c18b2883cbcd39'
selection = json.loads(selection_path.read_text())
joints = json.loads(args.joint_report.read_text())
assert joints['complete'] and joints['model_sha256'] == '94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
assert joints['bones']['body']['parent'] == 'root'
pivot_report = json.loads(args.pivot_report.read_text())
assert pivot_report['complete'] and pivot_report['pose_helper_sha256'] == sha(HERE/'fixed_cap_pivot_pose.py')
pivots = [r for r in pivot_report['cases'] if r['yaw_about_world_z_degrees'] == 15 and r['contact_pitch_degrees'] == 45]
assert len(pivots) == 1 and pivots[0]['passed']
tool_rotation = Matrix(pivots[0]['rigid_rotation'])
ground, target = Vector(selection['unchanged_ground']), Vector(selection['target_ground'])
local_cap = Vector(selection['working_surface']['surface_center_tool_local'])
body_joint = Vector(joints['body_joint_local'])
head_joint = Vector(joints['bones']['head']['head_local'])

scene = bpy.context.scene
data = bpy.data.cameras.new('ReadOnlyProjection'); data.type = 'ORTHO'; data.ortho_scale = 2.9
camera = bpy.data.objects.new('ReadOnlyProjection', data); scene.collection.objects.link(camera)
camera.location = (6,6,7)
camera.rotation_euler = (Vector((0,-.1,.98))-camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera = camera; scene.render.resolution_x = scene.render.resolution_y = 200
bpy.context.view_layer.update()


def project(point):
    p = world_to_camera_view(scene, camera, point)
    return [p.x*200, (1-p.y)*200]


def matrix_error(a, b):
    return max(abs(a[i][j]-b[i][j]) for i in range(len(a)) for j in range(len(a[i])))


phases = sorted(set([i/128 for i in range(129)]+[.24,.4,.55,.575,.625,.68,.82]))
report = {
    'complete':False, 'rendered':False, 'evaluated_native_rig_or_mesh':False,
    'source_base':'66bb10e1d821268ecda8a00a4048e6612874ed00',
    'source_hashes':{n:sha(HERE/n) for n in ('probe_upper_body_hinge.py','upper_body_hinge_pose.py','fixed_cap_pivot_pose.py','working_surface_arc.py')},
    'joint_report_sha256':sha(args.joint_report), 'pivot_report_sha256':sha(args.pivot_report),
    'selection_sha256':sha(selection_path), 'body_joint_local':list(body_joint),
    'scope':'Analytic native two-arm reach and exact joint/protected-field constraints. The entire head/ear/hair/helmet mesh must be checked separately before selecting an arc. No geometric or rendered visibility acceptance.',
    'weight_knots':[[0,0],[.125,1],[.625,1],[.82,0],[1,0]],
    'rotation_order':'Rest-local Z twist first, then rest-local Y side lean, around the measured body bone head; composed on the right of the original torso matrix.',
    'cases':[]}
for lean, twist in [(0,0), *[(a,b) for a in (6,10,14) for b in (-12,0,12)]]:
    row = {'side_lean_degrees':lean, 'local_twist_degrees':twist, 'passed':False,
           'samples':0, 'max_reach':0., 'max_segment_error':0., 'max_joint_error':0.,
           'max_head_body_relative_error':0., 'max_shoulder_error':0., 'poses':[]}
    try:
        for q in phases:
            p, original, protected, cap, delta = upper_body_hinge_pose.sample(
                q, ground, target, selection['contact'], local_cap, tool_rotation,
                body_joint, lean, twist)
            for key in original:
                if key not in ('torso','head','arms'):
                    assert p[key] is original[key], ('Unexpected replaced pose field', key)
            assert native.frame_metadata(p,ground)['feet'] == native.frame_metadata(protected,ground)['feet']
            joint_error = (p['torso']@body_joint-original['torso']@body_joint).length
            relative_error = matrix_error(p['torso'].inverted()@p['head'], original['torso'].inverted()@original['head'])
            shoulder_error = max((p['arms'][s][0]-delta@original['arms'][s][0]).length for s in native.SIDES)
            row['max_joint_error'] = max(row['max_joint_error'], joint_error)
            row['max_head_body_relative_error'] = max(row['max_head_body_relative_error'], relative_error)
            row['max_shoulder_error'] = max(row['max_shoulder_error'], shoulder_error)
            reach = max((c-a).length for a,b,c in p['arms'].values())
            segment_error = max(max(abs((b-a).length-.36),abs((c-b).length-.35)) for a,b,c in p['arms'].values())
            row['max_reach'] = max(row['max_reach'], reach)
            row['max_segment_error'] = max(row['max_segment_error'], segment_error)
            assert max(joint_error, relative_error, shoulder_error, segment_error) < 1e-5
            assert reach < .71
            row['samples'] += 1
        for q in (.125,.375,.55,.625,.8125):
            p, original, _, cap, delta = upper_body_hinge_pose.sample(
                q, ground, target, selection['contact'], local_cap, tool_rotation,
                body_joint, lean, twist)
            row['poses'].append({'phase':q, 'weight':upper_body_hinge_pose.action_weight(q),
                'head_matrix':[list(r) for r in p['head']],
                'torso_matrix':[list(r) for r in p['torso']],
                'rear_world':list(p['rear']), 'axis_world':list(p['axis']),
                'grips_world':{s:list(p['grips'][s]) for s in native.SIDES},
                'head_joint_pixel':project(p['head']@head_joint),
                'original_head_joint_pixel':project(original['head']@head_joint),
                'grips_pixel':{s:project(p['grips'][s]) for s in native.SIDES},
                'cap_center_pixel':project(cap),
                'maximum_arm_reach':max((c-a).length for a,b,c in p['arms'].values()),
                'world_delta':[list(r) for r in delta]})
        row['passed'] = True
    except Exception as error:
        row['failed_phase'] = q; row['failure'] = repr(error)
    report['cases'].append(row)
report['complete'] = True
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps(report,indent=2)+'\n')
print('UPPER_BODY_HINGE_MATH_COMPLETE',sum(r['passed'] for r in report['cases']),len(report['cases']),flush=True)
