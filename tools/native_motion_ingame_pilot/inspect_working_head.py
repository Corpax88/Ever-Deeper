"""Read native head topology/winding without changing the asset or rendering."""
from pathlib import Path
import argparse
import collections
import hashlib
import json
import sys
import bpy
from mathutils import Vector

parser=argparse.ArgumentParser()
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
source=Path(bpy.data.filepath)
assert hashlib.sha256(source.read_bytes()).hexdigest()=='0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
obj=bpy.data.objects['original relief head worn']
mesh=obj.data
mesh.calc_loop_triangles()
vertices=[obj.matrix_world@v.co for v in mesh.vertices]
triangles=[tuple(t.vertices) for t in mesh.loop_triangles]
edges=collections.defaultdict(list)
adjacency=collections.defaultdict(set)
for i,triangle in enumerate(triangles):
    for a,b in zip(triangle,triangle[1:]+triangle[:1]):
        edges[tuple(sorted((a,b)))].append((i,a,b))
        adjacency[a].add(b);adjacency[b].add(a)
unseen=set(range(len(vertices)));components=[]
while unseen:
    todo=[unseen.pop()];component=set(todo)
    while todo:
        for vertex in adjacency[todo.pop()]:
            if vertex in unseen:unseen.remove(vertex);component.add(vertex);todo.append(vertex)
    components.append(component)
origin=sum(vertices,Vector())/len(vertices)
volume=sum((vertices[a]-origin).dot((vertices[b]-origin).cross(vertices[c]-origin))/6 for a,b,c in triangles)
boundary=[edge for edge,faces in edges.items() if len(faces)==1]
nonmanifold=[edge for edge,faces in edges.items() if len(faces)!=2]
inconsistent=[edge for edge,faces in edges.items() if len(faces)==2 and faces[0][1:]==faces[1][1:]]
tool_index=obj.vertex_groups['tool'].index
weights=[sum(g.weight for g in v.groups if g.group==tool_index) for v in mesh.vertices]
other_weights=max((sum(g.weight for g in v.groups if g.group!=tool_index) for v in mesh.vertices),default=0.)
assert len(vertices)==7540 and len(triangles)==15076
assert min(weights)==max(weights)==1. and other_weights==0.
component_reports=[]
for component in components:
    faces=[t for t in triangles if t[0] in component]
    center=sum((vertices[v] for v in component),Vector())/len(component)
    signed_volume=sum((vertices[a]-center).dot((vertices[b]-center).cross(vertices[c]-center))/6 for a,b,c in faces)
    component_reports.append({'vertices':len(component),'triangles':len(faces),'signed_volume':signed_volume})
consistent_closed = len(components)==1 and not nonmanifold and not inconsistent
orientation={0:1}
pending=[0]
face_neighbors=collections.defaultdict(list)
for faces in edges.values():
    if len(faces)!=2:continue
    left,right=faces
    relation=-1 if left[1:]==right[1:] else 1
    face_neighbors[left[0]].append((right[0],relation))
    face_neighbors[right[0]].append((left[0],relation))
conflicts=[]
while pending:
    face=pending.pop()
    for neighbor,relation in face_neighbors[face]:
        desired=orientation[face]*relation
        if neighbor in orientation:
            if orientation[neighbor]!=desired:conflicts.append([face,neighbor])
        else:orientation[neighbor]=desired;pending.append(neighbor)
assert len(orientation)==len(triangles) and not conflicts and not nonmanifold
oriented_volume=sum(orientation[i]*(vertices[a]-origin).dot((vertices[b]-origin).cross(vertices[c]-origin))/6 for i,(a,b,c) in enumerate(triangles))
if oriented_volume<0:
    orientation={i:-sign for i,sign in orientation.items()}
    oriented_volume=-oriented_volume
assert oriented_volume>0
oriented_normals=[]
for i,(a,b,c) in enumerate(triangles):
    oriented_normals.append(((vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])*orientation[i]).normalized())
seed_face=10295
plane_origin=vertices[triangles[seed_face][0]]
plane_normal=oriented_normals[seed_face]
cap_faces={seed_face};todo=[seed_face]
while todo:
    face=todo.pop()
    for neighbor,_ in face_neighbors[face]:
        if neighbor in cap_faces:continue
        if oriented_normals[neighbor].dot(plane_normal)<1.-1e-6:continue
        if max(abs((vertices[v]-plane_origin).dot(plane_normal)) for v in triangles[neighbor])>1e-5:continue
        cap_faces.add(neighbor);todo.append(neighbor)
cap_area=0.;cap_center=Vector()
for face in cap_faces:
    a,b,c=(vertices[v] for v in triangles[face])
    area=(b-a).cross(c-a).length/2
    cap_area+=area;cap_center+=(a+b+c)*(area/3)
cap_center/=cap_area
cap_vertices=sorted(set(v for i in cap_faces for v in triangles[i]))
cap={'name':'lower tapered end flat terminal surface',
     'seed_triangle_index':seed_face,'triangle_indices':sorted(cap_faces),
     'vertex_indices':cap_vertices,'area':cap_area,'area_centroid_native_rest_world':list(cap_center),
     'geometric_outward_normal_native_rest_world':list(plane_normal),
     'rest_vertices':{str(v):list(vertices[v]) for v in cap_vertices},
     'definition':'The connected coplanar terminal patch containing lower-end triangle 10295; orientations are reconstructed in analysis from the unchanged closed mesh.'}
surfaces=[]
for vertex_index in (426,5267):
    face_values=[];area_vector=Vector()
    for i,triangle in enumerate(triangles):
        if vertex_index not in triangle:continue
        a,b,c=(vertices[j] for j in triangle)
        oriented_cross=(b-a).cross(c-a)*orientation[i]
        area_vector+=oriented_cross
        face_values.append({'triangle_index':i,'vertex_indices':list(triangle),
                            'source_winding_sign':orientation[i],
                            'geometric_outward_normal':list(oriented_cross.normalized()),
                            'triangle_area':oriented_cross.length/2})
    surfaces.append({'vertex_index':vertex_index,'native_rest_world':list(vertices[vertex_index]),
                     'source_vertex_normal':list(obj.matrix_world.to_3x3()@mesh.vertices[vertex_index].normal),
                     'geometric_outward_area_normal':list(area_vector.normalized()),'adjacent_faces':face_values})
report={'complete':True,'rendered':False,'asset_changed':False,
        'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'executed_script_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'object':obj.name,'vertices':len(vertices),'triangles':len(triangles),'edges':len(edges),
        'euler_characteristic':len(vertices)-len(edges)+len(triangles),'connected_components':len(components),
        'boundary_edges':len(boundary),'nonmanifold_edges':len(nonmanifold),'inconsistently_directed_edges':len(inconsistent),
        'components':component_reports,'nonmanifold_edge_examples':nonmanifold[:20],
        'inconsistent_edge_examples':inconsistent[:20],
        'single_closed_consistently_wound_mesh':consistent_closed,
        'signed_world_volume':volume,'object_matrix_determinant':obj.matrix_world.determinant(),
        'topology_winding':('outward' if volume>0 else 'inward') if consistent_closed else 'unresolved',
        'geometric_outward_normal_factor':(1 if volume>0 else -1) if consistent_closed else None,
        'diagnostic_consistent_orientation':{'closed_orientable':True,'orientation_conflicts':len(conflicts),
            'positive_signed_volume':oriented_volume,'triangles_reversed_in_analysis':sum(sign<0 for sign in orientation.values()),
            'method':'Propagate opposite directed edges across the unchanged closed surface; choose the positive-volume orientation. Only analysis vectors are reoriented; no mesh, normals or materials are written.'},
        'bound_head_end_surfaces':surfaces,
        'intended_working_surface':cap,
        'all_vertices_rigid_tool_weight':1.,'other_bone_weights':other_weights,
        'modifiers':[{'name':m.name,'type':m.type} for m in obj.modifiers],
        'meaning':'Topology is measured without assuming a closed consistently wound head. A normal factor is withheld unless that topology gate passes; source mesh, materials and renderer are unchanged.',
        'limits':'This identifies topology orientation, not a physical ore surface or visual/motion acceptance.'}
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps(report,indent=2)+'\n')
print('NATIVE_HEAD_TOPOLOGY_COMPLETE',volume,report['topology_winding'],flush=True)
