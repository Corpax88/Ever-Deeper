"""Reproduce the original v9 pickaxe geometry from its original authoring code.

Only the original equipment functions are executed. The published hero and
approved animation are never regenerated. --verify-source compares against
the archived native .blend files before this build route can be accepted.
"""
import argparse, ast, hashlib, json, math, sys
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[2]
sys.path[:0]=[str(HERE),str(HERE.parent)]
import gear_v3, motion_v3, motion_v9

def construct(gear, work):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    references=work/'v3/references'
    references.parent.mkdir(parents=True,exist_ok=True)
    if not references.exists(): references.symlink_to(REPO/'assets/tools',target_is_directory=True)
    gear_v3.ROOT=work
    original=ast.parse((HERE/'build_hero_v3.py').read_text())
    functions={'material','register','sphere','cylinder','tube'}
    materials={'brass','brasslight','iron','steel'}
    nodes=[n for n in original.body if isinstance(n,ast.FunctionDef) and n.name in functions
           or isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id in materials for t in n.targets)]
    api={'bpy':bpy,'math':math,'Vector':Vector,'groups':{}}
    exec(compile(ast.Module(body=nodes,type_ignores=[]),str(HERE/'build_hero_v3.py'),'exec'),api)
    api['rest']=motion_v3.rest(gear)
    gear_v3.pickaxe(api,gear)
    bpy.context.view_layer.update()
    objects=list(api['groups']['tool'])
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:
        bpy.context.view_layer.objects.active=o; o.select_set(True)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        o.select_set(False)
    rest=motion_v9.rest('pickaxe'); old=motion_v3.rest(gear)
    shaft=next(o for o in objects if o.name.startswith('round source-textured shaft'))
    tail=min((shaft.matrix_world@v.co-old['rear']).dot(old['axis']) for v in shaft.data.vertices)
    shift=rest['rear']-old['rear']+rest['axis']*(-.073-tail)
    for o in objects:
        o.location+=shift
        o.vertex_groups.new(name='tool').add(list(range(len(o.data.vertices))),1,'REPLACE')
    bpy.context.view_layer.update()
    return objects

def snapshot(objects, inverse):
    result={}
    dg=bpy.context.evaluated_depsgraph_get()
    for o in objects:
        e=o.evaluated_get(dg); mesh=e.to_mesh()
        coords=[list(inverse@e.matrix_world@v.co) for v in mesh.vertices]
        # BMesh can reorder faces without changing the surface. Canonicalize
        # polygon order and cyclic starting corner, retaining winding and the
        # UV at each vertex (including seams), material and smooth flag.
        faces=[]
        for p in mesh.polygons:
            vertices=list(p.vertices)
            uvs=[list(mesh.uv_layers.active.data[i].uv) for i in p.loop_indices] if mesh.uv_layers.active else []
            start=vertices.index(min(vertices))
            faces.append((vertices[start:]+vertices[:start],uvs[start:]+uvs[:start],p.material_index,p.use_smooth))
        faces.sort(key=lambda p:p[0])
        uv=[corner for p in faces for corner in p[1]]
        polygons=[p[0] for p in faces]
        materials=[]
        for mat in mesh.materials:
            nodes=[]
            for n in mat.node_tree.nodes:
                inputs=[]
                for socket in n.inputs:
                    if hasattr(socket,'default_value'):
                        v=socket.default_value
                        try: v=list(v)
                        except TypeError: pass
                        if isinstance(v,(int,float,str,list)): inputs.append([socket.name,v])
                image=None
                if n.type=='TEX_IMAGE' and n.image:
                    import struct
                    image={'size':list(n.image.size),'colorspace':n.image.colorspace_settings.name,
                           'pixels_sha256':hashlib.sha256(struct.pack('<%sf'%len(n.image.pixels),*n.image.pixels)).hexdigest()}
                nodes.append([n.name,n.type,inputs,image])
            materials.append({'nodes':nodes,'links':[[l.from_node.name,l.from_socket.name,l.to_node.name,l.to_socket.name] for l in mat.node_tree.links]})
        result[o.name]={'coords':coords,'uv':uv,'faces':polygons,'materials':materials,'material_indices':[p[2:] for p in faces]}
        e.to_mesh_clear()
    return result

def verify(gear, source, work, inverse):
    bpy.ops.wm.open_mainfile(filepath=str(source/'v9'/gear/'hero.blend'))
    rig=bpy.data.objects['EverDeeper_Hero_Rig']; rig.animation_data_clear()
    for bone in rig.pose.bones: bone.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    actual=rig.data.bones['tool'].matrix_local
    assert max(abs(inverse.inverted()[i][j]-actual[i][j]) for i in range(4) for j in range(4))<1e-6
    expected=snapshot([o for o in bpy.context.scene.objects if o.type=='MESH' and o.vertex_groups.get('tool')],inverse)
    generated=snapshot(construct(gear,work),inverse)
    assert set(expected)==set(generated),(gear,set(expected)^set(generated))
    errors=[]
    for name,want in expected.items():
        got=generated[name]
        assert len(want['coords'])==len(got['coords']),(gear,name,'vertex count')
        errors.extend(abs(a-b) for va,vb in zip(want['coords'],got['coords']) for a,b in zip(va,vb))
        assert len(want['uv'])==len(got['uv'])
        if want['uv']:
            difference=max(abs(a-b) for va,vb in zip(want['uv'],got['uv']) for a,b in zip(va,vb))
            assert difference<1e-6,(gear,name,'uv',difference)
        for key in ['faces','materials','material_indices']:
            assert want[key]==got[key],(gear,name,key)
    assert max(errors)<2e-6,(gear,max(errors))
    return {'gear':gear,'original_source_sha256':hashlib.sha256((source/'v9'/gear/'hero.blend').read_bytes()).hexdigest(),
            'generated_snapshot_sha256':fingerprint(generated),
            'source_inputs':input_hashes(gear),
            'mesh_layout':{name:{'vertices':len(row['coords']),'faces':len(row['faces']),'uv_corners':len(row['uv'])} for name,row in generated.items()},
            'maximum_position_difference':max(errors),'topology_uv_materials_identical':True,'meshes':len(expected)}

def fingerprint(value):
    # Opening an archived scene can change the last float32 bits in Blender's
    # cylinder UV math. Original parity above uses the unrounded 1e-6 UV and
    # 2e-6 position bounds; CI's reproducibility digest normalizes those bits.
    def normalize(v):
        if isinstance(v,dict): return {k:normalize(x) for k,x in v.items()}
        if isinstance(v,(list,tuple)): return [normalize(x) for x in v]
        return round(v,5) if isinstance(v,float) else v
    return hashlib.sha256(json.dumps(normalize(value),sort_keys=True,separators=(',',':')).encode()).hexdigest()

def input_hashes(gear):
    files=[HERE/name for name in ['build_tools.py','build_hero_v3.py','gear_v3.py','drill_v2.py','gear_profiles.json','bindings.json']]
    files += sorted(HERE.parent.glob('motion_v*.py'))
    files += [REPO/'assets/tools'/gear_v3.PROFILES[gear]['asset']]
    return {str(path.relative_to(REPO)):hashlib.sha256(path.read_bytes()).hexdigest() for path in files}


def main():
    p=argparse.ArgumentParser();p.add_argument('--verify-source',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:]); args.output.mkdir(parents=True,exist_ok=True)
    bindings=json.loads((HERE/'bindings.json').read_text()); inverse=Matrix(bindings['rest']['tool']).inverted()
    report=[verify(gear,args.verify_source,args.output,inverse) for gear in bindings['gears']]
    (args.output/'original-tool-parity.json').write_text(json.dumps(report,indent=2)+'\n')
    print('ORIGINAL_TOOL_PARITY_COMPLETE',len(report),flush=True)

if __name__=='__main__': main()
