"""Read the complete actual head geometry once; no BVH, image or asset export.

This private analysis cache contains evaluated vertex positions for conservative
footprint screening only. It is not a mesh replacement, LOD or visibility proof.
"""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import subprocess
import sys
import bpy
import numpy as np
from mathutils import Matrix, Vector

parser = argparse.ArgumentParser()
for name in ('native-tools','project','recorded','target-identity','pivot-report','inventory-report','modifier-report','joint-report','hinge-report','output'):
    parser.add_argument('--'+name,type=Path,required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
head = subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
assert not subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).strip(), 'Cache requires a clean saved source'
pivots = json.loads(args.pivot_report.read_text())
assert pivots['complete'] and pivots['pose_helper_sha256'] == sha(HERE/'fixed_cap_pivot_pose.py')
choices = [r for r in pivots['cases'] if r['yaw_about_world_z_degrees'] == 15 and r['contact_pitch_degrees'] == 45]
assert len(choices) == 1 and choices[0]['passed']
inventory = json.loads(args.inventory_report.read_text())['evaluated_objects']
expected_head = {r['name']:r for r in inventory if 'head' in r['groups']}
assert len(inventory) == 629 and len(expected_head) == 179
assert sum(r['triangles'] for r in expected_head.values()) == 2217334
assert all(r['groups'] == ['head'] for r in expected_head.values())
assert sha(args.modifier_report) == 'd42918f95771f1ef57a98235dbe0177c2536788a12faf29a2890af8816302283'
expected_modifiers = json.loads(args.modifier_report.read_text())['original_modifier_inventory']
assert set(expected_modifiers) == set(expected_head)
joints = json.loads(args.joint_report.read_text())
assert joints['complete'] and joints['model_sha256'] == '94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
hinge_report = json.loads(args.hinge_report.read_text())
assert hinge_report['complete'] and hinge_report['source_hashes']['upper_body_hinge_pose.py'] == sha(HERE/'upper_body_hinge_pose.py')
transport_cases = [r for r in hinge_report['cases'] if r['side_lean_degrees'] == 14 and r['local_twist_degrees'] == -12]
assert len(transport_cases) == 1 and transport_cases[0]['passed']
selection_path = HERE/'working-surface-selection.json'
assert sha(selection_path) == '040729e088dc006b73bfc368367ec49897456d11da3cb5f039c18b2883cbcd39'
selection = json.loads(selection_path.read_text())
args.output.mkdir(parents=True,exist_ok=True)
sys.argv = ['blender','--','--native-tools',str(args.native_tools),'--project',str(args.project),
            '--recorded',str(args.recorded),'--target-identity',str(args.target_identity),
            '--output',str(args.output/'scene-load'),'--setup-only']
mapped = runpy.run_path(str(HERE/'map_up_contact.py'))
sys.path.insert(0,str(HERE))
import fixed_cap_pivot_pose
import upper_body_hinge_pose
env = mapped['env']; rig = env['r']
pose, _, _, cap = fixed_cap_pivot_pose.sample(
    .55,Vector(selection['unchanged_ground']),Vector(selection['target_ground']),
    selection['contact'],Vector(selection['working_surface']['surface_center_tool_local']),
    Matrix(choices[0]['rigid_rotation']))
for modifier in env['skin']:
    modifier.show_viewport = False
applied = dict(pose); applied['head'] = applied['head']@env['head_offset']; env['apply'](applied)
for modifier in env['skin']:
    modifier.show_viewport = True
bpy.context.view_layer.update()
report = {
    'complete':False, 'rendered':False, 'bvh_built':False, 'asset_exported':False,
    'executed_source_sha':head, 'working_tree_clean_before':True,
    'source_hashes':{n:sha(HERE/n) for n in ('cache_upper_body_geometry.py','upper_body_hinge_pose.py','fixed_cap_pivot_pose.py','working_surface_arc.py','map_up_contact.py','probe_up_occlusion.py')},
    'model_sha256':mapped['loaded']['report']['model_sha256'],
    'gear_sha256':mapped['loaded']['report']['gear_sha256'],
    'inventory_sha256':sha(args.inventory_report), 'pivot_report_sha256':sha(args.pivot_report),
    'exact_modifier_inventory_sha256':sha(args.modifier_report),
    'joint_report_sha256':sha(args.joint_report), 'hinge_report_sha256':sha(args.hinge_report),
    'reference_phase':.55, 'reference_head_matrix':[list(r) for r in pose['head']],
    'reference_actual_head_bone_matrix':[list(r) for r in rig.pose.bones['head'].matrix],
    'camera':mapped['loaded']['report']['camera'], 'objects':[],
    'scope':'All evaluated vertices from every actual head-only object, including ears, face, beard, hair and complete helmet. No body/arm occlusion, lighting or recognizability proof. Exact immutable modifier stacks and full evaluated head weights are checked; rigid transport is directly compared against one actual second evaluated pose, not asserted from modifier names. This is conservative shortlist screening only; the final selected pose still needs the real rig/full-scene gate.'}
output = args.output/'head-geometry.json'
output.write_text(json.dumps(report,indent=2)+'\n')
objects = [o for o in env['s'].objects if o.type == 'MESH' and not o.hide_render]
assert len(objects) == 629
selected = [o for o in objects if any(g.name == 'head' for g in o.vertex_groups)]
assert {o.name for o in selected} == set(expected_head)
report['original_modifier_inventory'] = {
    o.name:[{'type':m.type,'name':m.name,'show_viewport':m.show_viewport,'show_render':m.show_render}
            for m in o.modifiers] for o in sorted(selected,key=lambda o:o.name)}
output.write_text(json.dumps(report,indent=2)+'\n')
assert report['original_modifier_inventory'] == expected_modifiers
depsgraph = bpy.context.evaluated_depsgraph_get()
arrays = []; offset = 0
for obj in sorted(selected,key=lambda o:o.name):
    assert [g.name for g in obj.vertex_groups] == ['head']
    head_index = obj.vertex_groups['head'].index
    assert all(len(v.groups) == 1 and v.groups[0].group == head_index and abs(v.groups[0].weight-1.) < 1e-8 for v in obj.data.vertices), obj.name
    # Every complete stack is bound to the saved actual inventory, including
    # four post-armature beard/hair/spectacle stacks. A second real evaluated
    # pose below checks their transport instead of assuming commutation.
    modifiers = [{'type':m.type,'name':m.name,'show_viewport':m.show_viewport,'show_render':m.show_render} for m in obj.modifiers]
    assert modifiers == expected_modifiers[obj.name], (obj.name,modifiers)
    armatures = [m for m in obj.modifiers if m.type == 'ARMATURE']
    assert len(armatures) == 1 and armatures[0].object == rig
    assert all(m.show_viewport and m.show_render for m in obj.modifiers)
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh(); mesh.calc_loop_triangles()
    assert len(mesh.vertices) == expected_head[obj.name]['vertices']
    assert len(mesh.loop_triangles) == expected_head[obj.name]['triangles']
    assert all(len(v.groups) == 1 and v.groups[0].group == head_index and abs(v.groups[0].weight-1.) < 1e-8 for v in mesh.vertices), ('Evaluated head weights',obj.name)
    flat = np.empty(len(mesh.vertices)*3,dtype=np.float32)
    mesh.vertices.foreach_get('co',flat)
    local = flat.reshape(-1,3).astype(np.float64)
    matrix = np.asarray(evaluated.matrix_world,dtype=np.float64)
    world = local@matrix[:3,:3].T+matrix[:3,3]
    assert np.isfinite(world).all()
    arrays.append(world)
    report['objects'].append({'name':obj.name,'groups':['head'],'source_vertices':len(obj.data.vertices),
        'evaluated_vertices':len(mesh.vertices),'evaluated_triangles':len(mesh.loop_triangles),
        'cache_vertex_offset':offset,'cache_vertex_count':len(world), 'modifiers':modifiers,
        'object_matrix_world':[list(r) for r in evaluated.matrix_world],
        'materials':[slot.material.name if slot.material else None for slot in obj.material_slots]})
    offset += len(world)
    evaluated.to_mesh_clear()
vertices = np.concatenate(arrays)
cache = args.output/'complete-head-vertices.npz'
np.savez_compressed(cache,world_vertices=vertices)
report['cached_vertices'] = len(vertices)
report['evaluated_triangles'] = sum(r['evaluated_triangles'] for r in report['objects'])
report['vertex_dtype'] = str(vertices.dtype)
report['cache_sha256'] = sha(cache); report['cache_bytes'] = cache.stat().st_size
output.write_text(json.dumps(report,indent=2)+'\n')

# The largest retained side lean is a transport stress check, not a selected
# visual candidate. All 179 actual evaluated vertex arrays must match the
# transported reference, including the post-armature generated geometry.
check_pose, _, _, _, delta = upper_body_hinge_pose.sample(
    .55,Vector(selection['unchanged_ground']),Vector(selection['target_ground']),
    selection['contact'],Vector(selection['working_surface']['surface_center_tool_local']),
    Matrix(choices[0]['rigid_rotation']),Vector(joints['body_joint_local']),14,-12)
for modifier in env['skin']:
    modifier.show_viewport = False
check_applied = dict(check_pose); check_applied['head'] = check_applied['head']@env['head_offset']; env['apply'](check_applied)
for modifier in env['skin']:
    modifier.show_viewport = True
bpy.context.view_layer.update()
depsgraph = bpy.context.evaluated_depsgraph_get()
transform = np.asarray(check_pose['head']@pose['head'].inverted(),dtype=np.float64)
transport = {'phase':.55,'side_lean_degrees':14,'twist_degrees':-12,
             'maximum_world_vertex_error':0.,'checked_vertices':0,'objects':[]}
report['actual_evaluated_transport_check'] = transport
for obj, metadata in zip(sorted(selected,key=lambda o:o.name),report['objects']):
    assert obj.name == metadata['name']
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh(); mesh.calc_loop_triangles()
    assert len(mesh.vertices) == metadata['evaluated_vertices'] and len(mesh.loop_triangles) == metadata['evaluated_triangles']
    flat = np.empty(len(mesh.vertices)*3,dtype=np.float32); mesh.vertices.foreach_get('co',flat)
    matrix = np.asarray(evaluated.matrix_world,dtype=np.float64)
    actual = flat.reshape(-1,3).astype(np.float64)@matrix[:3,:3].T+matrix[:3,3]
    start, count = metadata['cache_vertex_offset'], metadata['cache_vertex_count']
    predicted = vertices[start:start+count]@transform[:3,:3].T+transform[:3,3]
    error = float(np.max(np.linalg.norm(actual-predicted,axis=1)))
    transport['objects'].append({'name':obj.name,'vertices':count,'maximum_world_vertex_error':error})
    transport['maximum_world_vertex_error'] = max(transport['maximum_world_vertex_error'],error)
    transport['checked_vertices'] += count
    evaluated.to_mesh_clear()
output.write_text(json.dumps(report,indent=2)+'\n')
assert transport['checked_vertices'] == len(vertices)
assert transport['maximum_world_vertex_error'] < 1e-5, transport['maximum_world_vertex_error']
report['complete'] = True
output.write_text(json.dumps(report,indent=2)+'\n')
print('COMPLETE_HEAD_GEOMETRY_CACHE',len(selected),len(vertices),report['evaluated_triangles'],flush=True)
