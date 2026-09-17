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
for name in ('native-tools','project','recorded','target-identity','pivot-report','inventory-report','output'):
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
    'source_hashes':{n:sha(HERE/n) for n in ('cache_upper_body_geometry.py','fixed_cap_pivot_pose.py','working_surface_arc.py','map_up_contact.py','probe_up_occlusion.py')},
    'model_sha256':mapped['loaded']['report']['model_sha256'],
    'gear_sha256':mapped['loaded']['report']['gear_sha256'],
    'inventory_sha256':sha(args.inventory_report), 'pivot_report_sha256':sha(args.pivot_report),
    'reference_phase':.55, 'reference_head_matrix':[list(r) for r in pose['head']],
    'reference_actual_head_bone_matrix':[list(r) for r in rig.pose.bones['head'].matrix],
    'camera':mapped['loaded']['report']['camera'], 'objects':[],
    'scope':'All evaluated vertices from every actual head-only object, including ears, face, beard, hair and complete helmet. No body/arm occlusion, lighting or recognizability proof. Rigid matrix transport requires the verified head-only weight and modifier constraints below; final selected pose still needs the real rig/full-scene gate.'}
output = args.output/'head-geometry.json'
output.write_text(json.dumps(report,indent=2)+'\n')
objects = [o for o in env['s'].objects if o.type == 'MESH' and not o.hide_render]
assert len(objects) == 629
selected = [o for o in objects if any(g.name == 'head' for g in o.vertex_groups)]
assert {o.name for o in selected} == set(expected_head)
depsgraph = bpy.context.evaluated_depsgraph_get()
arrays = []; offset = 0
for obj in sorted(selected,key=lambda o:o.name):
    assert [g.name for g in obj.vertex_groups] == ['head']
    head_index = obj.vertex_groups['head'].index
    assert all(len(v.groups) == 1 and v.groups[0].group == head_index and abs(v.groups[0].weight-1.) < 1e-8 for v in obj.data.vertices), obj.name
    # With only the one rigid armature modifier, transporting every evaluated
    # vertex by the changed head matrix is an exact rigid model, not a proxy
    # based on the helmet dome or a fitted sphere.
    modifiers = [{'type':m.type,'name':m.name,'show_viewport':m.show_viewport,'show_render':m.show_render} for m in obj.modifiers]
    assert len(obj.modifiers) == 1 and obj.modifiers[0].type == 'ARMATURE' and obj.modifiers[0].object == rig, (obj.name,modifiers)
    assert obj.modifiers[0].show_viewport and obj.modifiers[0].show_render
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh(); mesh.calc_loop_triangles()
    assert len(mesh.vertices) == expected_head[obj.name]['vertices']
    assert len(mesh.loop_triangles) == expected_head[obj.name]['triangles']
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
report['complete'] = True
output.write_text(json.dumps(report,indent=2)+'\n')
print('COMPLETE_HEAD_GEOMETRY_CACHE',len(selected),len(vertices),report['evaluated_triangles'],flush=True)
