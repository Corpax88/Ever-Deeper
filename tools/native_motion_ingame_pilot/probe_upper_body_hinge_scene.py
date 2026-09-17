"""One saved anatomical hinge: real dense rig and five full-scene ray cases.

No image rendering. Original root/feet, rigid tool and working-cap path remain
fixed. Pixel-ray connectivity is recorded, never promoted to motion/readability
approval. The final complete receipt is distinct from progress snapshots.
"""
from pathlib import Path
import argparse
from collections import Counter
import hashlib
import json
import math
import os
import runpy
import subprocess
import sys
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

parser=argparse.ArgumentParser()
for name in ('native-tools','project','recorded','target-identity','pivot-report','joint-report','hinge-report','head-report','footprint-report','head-topology','inventory-report','output'):
    parser.add_argument('--'+name,type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[1]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
git=lambda *a:subprocess.check_output(['git',*a],cwd=ROOT,text=True).strip()
executed_head=git('rev-parse','HEAD');assert not git('status','--porcelain')
choice_path=HERE/'upper-body-hinge-selection.json';choice=json.loads(choice_path.read_text())
for path,key in ((args.joint_report,'joint_report_sha256'),(args.hinge_report,'hinge_math_report_sha256'),
                 (args.head_report,'closed_head_report_sha256'),(args.footprint_report,'complete_head_footprint_report_sha256'),
                 (args.head_topology,'working_surface_topology_sha256')):
    assert sha(path)==choice[key],(path,key)
assert sha(HERE/'upper_body_hinge_pose.py')==choice['pose_helper_sha256']
assert sha(HERE/'fixed_cap_pivot_pose.py')==choice['fixed_cap_pose_helper_sha256']
assert choice['side_lean_degrees']==10 and choice['local_twist_degrees']==-12
assert choice['critical_phases']==[.125,.375,.55,.625,.8125]
head_report=json.loads(args.head_report.read_text());assert head_report['complete']
assert sha(args.inventory_report)==head_report['inventory_sha256']
assert sha(args.pivot_report)==head_report['pivot_report_sha256']
hinge_report=json.loads(args.hinge_report.read_text())
analytic=[r for r in hinge_report['cases'] if r['side_lean_degrees']==10 and r['local_twist_degrees']==-12]
assert len(analytic)==1 and analytic[0]['passed'] and analytic[0]['samples']==135
pivots=json.loads(args.pivot_report.read_text())
pivot=[r for r in pivots['cases'] if r['yaw_about_world_z_degrees']==15 and r['contact_pitch_degrees']==45]
assert len(pivot)==1 and pivot[0]['passed']
rotation=Matrix(pivot[0]['rigid_rotation'])
surface=json.loads((HERE/'working-surface-selection.json').read_text())
topology=json.loads(args.head_topology.read_text())
center_rest=Vector(topology['intended_working_surface']['area_centroid_native_rest_world'])
inventory=json.loads(args.inventory_report.read_text())['evaluated_objects']
expected_objects={r['name']:r for r in inventory};assert len(expected_objects)==629
args.output.mkdir(parents=True,exist_ok=True)
sys.argv=['blender','--','--native-tools',str(args.native_tools),'--project',str(args.project),
          '--recorded',str(args.recorded),'--target-identity',str(args.target_identity),
          '--output',str(args.output/'scene-load'),'--setup-only']
mapped=runpy.run_path(str(HERE/'map_up_contact.py'))
sys.path.insert(0,str(HERE));import upper_body_hinge_pose
env=mapped['env'];rig,rest=env['r'],env['rest'];native=env['native_motion']
loaded=mapped['loaded'];scene,camera=env['s'],env['c']
ground,target=Vector(surface['unchanged_ground']),Vector(surface['target_ground'])
local_cap=Vector(surface['working_surface']['surface_center_tool_local'])
body_joint=Vector(choice['body_joint_local'])


def sample(q):
    return upper_body_hinge_pose.sample(q,ground,target,surface['contact'],local_cap,rotation,body_joint,10,-12)


def apply(p):
    for m in env['skin']:m.show_viewport=False
    posed=dict(p);posed['head']=posed['head']@env['head_offset'];env['apply'](posed)


def rows(matrix):return [list(r) for r in matrix]
def matrix_error(a,b):return max(abs(a[i][j]-b[i][j]) for i in range(4) for j in range(4))


protected_bones=['root','hips','thigh.R','shin.R','foot.R','thigh.L','shin.L','foot.L']
report={'complete':False,'rendered':False,'readability_accepted':False,'executed_source_sha':executed_head,
        'source_tree':git('rev-parse','HEAD^{tree}'),'working_tree_clean_before':True,
        'source_hashes':{n:sha(HERE/n) for n in ('probe_upper_body_hinge_scene.py','upper_body_hinge_pose.py','fixed_cap_pivot_pose.py','working_surface_arc.py','map_up_contact.py','probe_up_occlusion.py')},
        'selection_sha256':sha(choice_path),'selection':choice,
        'input_reports':{str(p):sha(p) for p in (args.joint_report,args.hinge_report,args.head_report,args.footprint_report,args.head_topology,args.inventory_report,args.recorded,args.target_identity,args.pivot_report)},
        'model_sha256':loaded['report']['model_sha256'],'gear_sha256':loaded['report']['gear_sha256'],
        'dense_evaluated_poses':[],'critical_poses':[],
        'scope':'Actual native bone/grip/working-cap constraints and all629-object pixel-ray occlusion. Connectivity is geometric evidence, not material, motion, physical ore-surface or native-image readability acceptance.'}
progress=args.output/'hinge-scene-progress.json'
phases=sorted(set([i/128 for i in range(129)]+[.24,.4,.55,.575,.625,.68,.82]))
for q in phases:
    p,original,protected,cap,delta=sample(q)
    for key in original:
        if key not in ('torso','head','arms'):assert p[key] is original[key],key
    assert native.frame_metadata(p,ground)['feet']==native.frame_metadata(protected,ground)['feet']
    apply(original)
    before={n:rig.pose.bones[n].matrix.copy() for n in [*protected_bones,'body','head','tool']}
    apply(p)
    after={n:rig.pose.bones[n].matrix.copy() for n in before}
    fixed_error=max(matrix_error(before[n],after[n]) for n in [*protected_bones,'tool'])
    joint_error=(after['body'].translation-before['body'].translation).length
    relative_before=before['body'].inverted()@before['head'];relative_after=after['body'].inverted()@after['head']
    relative_error=matrix_error(relative_before,relative_after)
    measured_grips={s:(after_hand@rig.data.bones['hand.'+s].matrix_local.inverted())@rest['grips'][s]
                    for s in native.SIDES for after_hand in [rig.pose.bones['hand.'+s].matrix.copy()]}
    grip_error=max((measured_grips[s]-p['grips'][s]).length for s in native.SIDES)
    lengths={n:(rig.pose.bones[n].tail-rig.pose.bones[n].head).length for n in ('upper.R','lower.R','upper.L','lower.L')}
    length_error=max(abs(v-rig.data.bones[n].length) for n,v in lengths.items())
    reach=max((c-a).length for a,b,c in p['arms'].values())
    measured_cap=after['tool']@rig.data.bones['tool'].matrix_local.inverted()@center_rest
    cap_error=(measured_cap-cap).length
    row={'phase':q,'normalized_phase':q%1.,'maximum_arm_reach':reach,
         'fixed_root_leg_sole_tool_matrix_error':fixed_error,'body_joint_error':joint_error,
         'head_body_relative_error':relative_error,'actual_grip_error':grip_error,
         'actual_arm_length_error':length_error,'actual_cap_centroid_error':cap_error,
         'before_matrices':{n:rows(m) for n,m in before.items()},'after_matrices':{n:rows(m) for n,m in after.items()},
         'expected_grips':{s:list(p['grips'][s]) for s in native.SIDES},'actual_grips':{s:list(v) for s,v in measured_grips.items()},
         'actual_arm_lengths':lengths,'rest_arm_lengths':{n:rig.data.bones[n].length for n in lengths},
         'expected_cap_centroid':list(cap),'actual_cap_centroid':list(measured_cap)}
    report['dense_evaluated_poses'].append(row)
    if not (max(fixed_error,joint_error,relative_error,grip_error,length_error,cap_error)<1e-5 and reach<.71):
        report['failure']={'phase':q,'metrics':row};progress.write_text(json.dumps(report,indent=2)+'\n');raise AssertionError((q,row))
assert len(report['dense_evaluated_poses'])==135
progress.write_text(json.dumps(report,indent=2)+'\n')
print('HINGE_DENSE_RIG_COMPLETE',len(phases),flush=True)

# Reuse the full tree already built by the unchanged tool observer. This keeps
# every original mesh in the test while avoiding a second 2.7M-triangle build.
original_mesh_trees=loaded['mesh_trees'];captured=[]
def retain_mesh_trees():
    trees=original_mesh_trees();captured.append(trees);return trees
loaded['mesh_trees']=retain_mesh_trees


def hand_visibility(side,full,owners):
    candidates=[o for o in scene.objects if o.type=='MESH' and not o.hide_render and [g.name for g in o.vertex_groups]==['hand.'+side]]
    assert len(candidates)==1
    obj=candidates[0];depsgraph=bpy.context.evaluated_depsgraph_get();evaluated=obj.evaluated_get(depsgraph)
    mesh=evaluated.to_mesh();mesh.calc_loop_triangles()
    vertices=[evaluated.matrix_world@v.co for v in mesh.vertices]
    tree=BVHTree.FromPolygons(vertices,[tuple(t.vertices) for t in mesh.loop_triangles],all_triangles=True)
    xy=[mapped['project'](v) for v in vertices]
    bounds=[min(p[0] for p in xy),min(p[1] for p in xy),max(p[0] for p in xy),max(p[1] for p in xy)]
    cam=camera.matrix_world.copy();direction=(cam.to_3x3()@Vector((0,0,-1))).normalized()
    projected=[];visible=[];occluders=Counter()
    for y in range(max(0,math.floor(bounds[1])),min(200,math.ceil(bounds[3]))):
        for x in range(max(0,math.floor(bounds[0])),min(200,math.ceil(bounds[2]))):
            origin=cam@Vector((((x+.5)/200-.5)*camera.data.ortho_scale,(.5-(y+.5)/200)*camera.data.ortho_scale,0))
            hit=tree.ray_cast(origin,direction,100)
            if hit[0] is None:continue
            projected.append([x,y]);first=full.ray_cast(origin,direction,100);assert first[0] is not None
            owner=owners[first[2]][0]
            if owner==obj.name or abs(first[3]-hit[3])<1e-5:visible.append([x,y])
            else:occluders[owner]+=1
    evaluated.to_mesh_clear()
    return {'object':obj.name,'projected_pixels':projected,'visible_pixels':visible,'projected_bounds':bounds,
            'occluders':dict(occluders.most_common()),'projected_pixel_centers':len(projected),'visible_pixel_centers':len(visible)}


def connections(parts,hands,p):
    masks={part['object']:{tuple(v) for v in part['visible_pixels']} for part in parts}
    masks.update({h['object']:{tuple(v) for v in h['visible_pixels']} for h in hands.values()})
    remaining=set().union(*masks.values());components=[]
    while remaining:
        seed=next(iter(remaining));remaining.remove(seed);component={seed};todo=[seed]
        while todo:
            x,y=todo.pop()
            for dx,dy in ((-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)):
                point=(x+dx,y+dy)
                if point in remaining:remaining.remove(point);component.add(point);todo.append(point)
        components.append({'pixel_count':len(component),'object_visible_pixels':{name:len(mask&component) for name,mask in masks.items()},'pixels':[list(v) for v in sorted(component)]})
    components.sort(key=lambda r:-r['pixel_count'])
    shaft=next(r for r in parts if r['object']=='round source-textured shaft')
    a=Vector(mapped['project'](p['rear']));b=Vector(mapped['project'](p['rear']+p['axis']));axis=b-a
    bins=[]
    for center in (0.,.145,.25,.35,.45,.55):
        def within(pixel):return abs((Vector((pixel[0]+.5,pixel[1]+.5))-a).dot(axis)/axis.length_squared-center)<=.04
        bins.append({'shaft_coordinate':center,'half_width':.04,'projected_pixels':sum(within(v) for v in shaft['projected_pixels']),
                     'visible_pixels':sum(within(v) for v in shaft['visible_pixels'])})
    return {'sampling':'Actual200px pixel-center masks with8-connected components; no antialiasing or color/material readability claim.',
            'components':components,'shaft_coordinate_bands':bins,'grips_native_pixels':{s:mapped['project'](p['grips'][s]) for s in native.SIDES}}


for q in choice['critical_phases']:
    p,_,_,_,_=sample(q);captured.clear()
    parts=mapped['measure_parts'](p,mapped['sample'])
    assert len(captured)==1
    full,_,owners,objects=captured[0]
    assert {r['name']:r for r in objects}==expected_objects
    assert parts['object_count']==629 and parts['evaluated_triangles']==2714340
    hands={s:hand_visibility(s,full,owners) for s in native.SIDES}
    report['critical_poses'].append({'phase':q,'parts':parts,'hands':hands,'connections':connections(parts['parts'],hands,p)})
    progress.write_text(json.dumps(report,indent=2)+'\n')
    shaft=next(r for r in parts['parts'] if r['object']=='round source-textured shaft')
    print('HINGE_CRITICAL_GEOMETRY',q,'shaft',shaft['visible_pixel_centers'],shaft['projected_pixel_centers'],
          'hands',[(s,hands[s]['visible_pixel_centers'],hands[s]['projected_pixel_centers']) for s in native.SIDES],flush=True)
    captured.clear()
    del full,owners,objects
report['complete']=True
final=args.output/'hinge-scene-final.json';temporary=args.output/'hinge-scene-final.json.pending'
assert not final.exists() and not temporary.exists()
data=(json.dumps(report,indent=2)+'\n').encode()
with temporary.open('xb') as handle:handle.write(data);handle.flush();os.fsync(handle.fileno())
os.replace(temporary,final);directory_fd=os.open(args.output,os.O_RDONLY)
try:os.fsync(directory_fd)
finally:os.close(directory_fd)
assert final.read_bytes()==data
print('HINGE_SCENE_FINAL_SHA256',sha(final),len(data),flush=True)
