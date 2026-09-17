"""Actual rig and mesh rays for one math-selected fixed-cap tool pivot.

No image rendering. The same target, torso, head, feet and cap-centroid path
remain fixed; changed terminal orientation is explicitly measured separately.
"""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import subprocess
import sys
import bpy
from mathutils import Matrix, Vector

parser=argparse.ArgumentParser()
for name in ('native-tools','project','recorded','target-identity','head-topology','pivot-report','output'):
    parser.add_argument('--'+name,type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
executed_source_sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
assert not subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip(), 'Native rig study requires a saved clean checkpoint'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
math_report=json.loads(args.pivot_report.read_text())
assert math_report['complete'] and math_report['pose_helper_sha256']==sha(HERE/'fixed_cap_pivot_pose.py')
matches=[r for r in math_report['cases'] if r['yaw_about_world_z_degrees']==15 and r['contact_pitch_degrees']==45]
assert len(matches)==1 and matches[0]['passed'] and matches[0]['samples']==135
rotation=Matrix(matches[0]['rigid_rotation'])
selection_path=HERE/'working-surface-selection.json'
assert sha(selection_path)=='040729e088dc006b73bfc368367ec49897456d11da3cb5f039c18b2883cbcd39'
selection=json.loads(selection_path.read_text())
topology=json.loads(args.head_topology.read_text())
center_rest=Vector(topology['intended_working_surface']['area_centroid_native_rest_world'])
args.output.mkdir(parents=True,exist_ok=True)
sys.argv=['blender','--','--native-tools',str(args.native_tools),'--project',str(args.project),
          '--recorded',str(args.recorded),'--target-identity',str(args.target_identity),
          '--output',str(args.output/'scene-load'),'--setup-only']
mapped=runpy.run_path(str(HERE/'map_up_contact.py'))
sys.path.insert(0,str(HERE))
import fixed_cap_pivot_pose
env=mapped['env'];rig,rest=env['r'],env['rest'];native,pm=env['native_motion'],env['premium_motion']
ground,target=Vector(selection['unchanged_ground']),Vector(selection['target_ground'])
local_cap=Vector(selection['working_surface']['surface_center_tool_local'])
local_normal=Vector(selection['working_surface']['surface_normal_tool_local'])


def sample(q):
    return fixed_cap_pivot_pose.sample(q,ground,target,selection['contact'],local_cap,rotation)


def apply(p):
    for modifier in env['skin']:modifier.show_viewport=False
    posed=dict(p);posed['head']=posed['head']@env['head_offset'];env['apply'](posed)
    return rig.pose.bones['tool'].matrix@rig.data.bones['tool'].matrix_local.inverted()


report={'complete':False,'rendered':False,'visually_accepted':False,
        'source_base':'7b1a5ddac56db30dc245f8ddc652b3d2acba73a1',
        'executed_source_sha':executed_source_sha,'working_tree_clean_before':True,
        'source_hashes':{n:sha(HERE/n) for n in ['probe_fixed_cap_occlusion.py','fixed_cap_pivot_pose.py','working_surface_arc.py','map_up_contact.py']},
        'pivot_math_report_sha256':sha(args.pivot_report),'topology_sha256':sha(args.head_topology),
        'selection':matches[0],'model_sha256':mapped['loaded']['report']['model_sha256'],
        'gear_sha256':mapped['loaded']['report']['gear_sha256'],
        'target_identity_sha256':sha(args.target_identity),'original_capture_sha256':sha(args.recorded),
        'dense_evaluated_poses':[],'max_grip_error':0.,'max_reach':0.,
        'max_evaluated_body_head_foot_matrix_error':0.,'max_evaluated_working_cap_centroid_error':0.,
        'occlusion':[],'trajectory':[],
        'limit':'Actual ray geometry, not rendered recognizability. The cap centroid path is fixed; the terminal patch normal and boundary change with the rigid pivot. No runtime or 3D ore surface claim.'}
phases=sorted(set([i/128 for i in range(129)]+[.24,.4,.55,.575,.625,.68,.82]))
for q in phases:
    p,original,protected,cap=sample(q)
    for key in ('torso','head','legs','foot_rotations','contacts'):assert p[key] is original[key]
    assert native.frame_metadata(p,ground)['feet']==native.frame_metadata(protected,ground)['feet']
    apply(original)
    names=['body','head','foot.R','foot.L']
    before={name:rig.pose.bones[name].matrix.copy() for name in names}
    skin=apply(p)
    matrix_error=max(abs(rig.pose.bones[name].matrix[i][j]-before[name][i][j]) for name in names for i in range(4) for j in range(4))
    cap_error=(skin@center_rest-cap).length
    grip=max(((rig.pose.bones['hand.'+s].matrix@rig.data.bones['hand.'+s].matrix_local.inverted())@rest['grips'][s]-p['grips'][s]).length for s in native.SIDES)
    reach=max((c-a).length for a,b,c in p['arms'].values())
    row={'phase':q,'normalized_phase':q%1.,'actual_grip_error':grip,'maximum_arm_reach':reach,
         'evaluated_body_head_foot_matrix_error':matrix_error,'evaluated_cap_centroid_error':cap_error,
         'working_cap_centroid':list(cap),'actual_evaluated_cap_centroid':list(skin@center_rest)}
    report['dense_evaluated_poses'].append(row)
    report['max_grip_error']=max(report['max_grip_error'],grip)
    report['max_reach']=max(report['max_reach'],reach)
    report['max_evaluated_body_head_foot_matrix_error']=max(report['max_evaluated_body_head_foot_matrix_error'],matrix_error)
    report['max_evaluated_working_cap_centroid_error']=max(report['max_evaluated_working_cap_centroid_error'],cap_error)
    if not (max(matrix_error,cap_error,grip)<1e-5 and reach<.71):
        report['failure']={'phase':q,'values':row}
        (args.output/'fixed-cap-native.json').write_text(json.dumps(report,indent=2)+'\n')
        raise AssertionError((q,row))
assert len(report['dense_evaluated_poses'])==135
(args.output/'fixed-cap-native.json').write_text(json.dumps(report,indent=2)+'\n')
for q in (.375,.55):
    p,_,_,cap=sample(q)
    parts=mapped['measure_parts'](p,mapped['sample'])
    groups,objects=mapped['loaded']['measure']()
    assert parts['object_count']==len(objects)==629
    assert parts['evaluated_triangles']==sum(o['triangles'] for o in objects)==2714340
    report['occlusion'].append({'phase':q,'parts':parts,'tool_hand_forearm_groups':groups})
    (args.output/'fixed-cap-native.json').write_text(json.dumps(report,indent=2)+'\n')
surface_vertices=[Vector(v) for v in topology['intended_working_surface']['rest_vertices'].values()]
for i in range(301):
    q=.4+.15*i/300
    p,_,_,cap=sample(q)
    skin=apply(p)
    alpha=max(mapped['ore_alpha'](mapped['scene_point'](mapped['project'](skin@v),mapped['sample']),mapped['sample']) for v in [center_rest,*surface_vertices])
    report['trajectory'].append({'phase':q,'cap_center_native_pixel':mapped['project'](cap),'maximum_cap_vertex_or_center_ore_alpha':alpha})
report['first_sampled_cap_alpha_phase']=next((r['phase'] for r in report['trajectory'] if r['maximum_cap_vertex_or_center_ore_alpha']>.5),None)
p,_,_,cap=sample(.55);_,_,_,before=sample(.55-.0001)
velocity=(cap-before)/(.0001*.68*.42/.55)
normal=pm.tool_frame(p['axis'],p['tool_normal'])@local_normal
report['contact_approach']={'native_velocity':list(velocity),'geometric_outward_normal':list(normal),
                            'outward_normal_dot_incoming_velocity':normal.dot(velocity)}
report['complete']=True
(args.output/'fixed-cap-native.json').write_text(json.dumps(report,indent=2)+'\n')
print('FIXED_CAP_NATIVE_COMPLETE',len(report['dense_evaluated_poses']),report['max_grip_error'],flush=True)
