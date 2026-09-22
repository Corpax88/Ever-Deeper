"""Bake the verified original tool surfaces into portable native PBR assets.

Only equipment is built; the accepted hero, skeleton and motion remain pinned.
The original per-object procedural coordinates and source-image UVs survive
joining. Godot imports only these tool meshes into the existing tool-bone frame.
"""
import argparse, hashlib, json, math, sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Matrix, Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_tools import HERE, REPO, construct, snapshot, fingerprint, input_hashes


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()


def portable_mesh(objects,inverse):
    dg=bpy.context.evaluated_depsgraph_get()
    copies=[]
    cap=None
    for obj in objects:
        evaluated=obj.evaluated_get(dg)
        mesh=bpy.data.meshes.new_from_object(evaluated,preserve_all_data_layers=True,depsgraph=dg)
        if mesh.uv_layers.active: mesh.uv_layers.active.name='OriginalUV'
        local=np.array([v.co[:] for v in mesh.vertices])
        low=local.min(axis=0);extent=local.max(axis=0)-low
        generated=(local-low)/np.where(extent>1e-10,extent,1)
        attr=mesh.attributes.new('NativeGenerated','FLOAT_VECTOR','POINT')
        attr.data.foreach_set('vector',generated.astype(np.float32).ravel())
        for i,mat in enumerate(mesh.materials):
            mat=mat.copy();mesh.materials[i]=mat
            nodes=mat.node_tree.nodes;links=mat.node_tree.links
            uv=nodes.new('ShaderNodeUVMap');uv.uv_map='OriginalUV'
            coords=nodes.new('ShaderNodeAttribute');coords.attribute_name='NativeGenerated'
            for node in list(nodes):
                if node.type=='TEX_IMAGE' and not node.inputs['Vector'].is_linked:
                    links.new(uv.outputs['UV'],node.inputs['Vector'])
                if node.type=='TEX_NOISE' and not node.inputs['Vector'].is_linked:
                    links.new(coords.outputs['Vector'],node.inputs['Vector'])
                if node.type=='TEX_COORD':
                    for link in list(node.outputs['Generated'].links): links.new(coords.outputs['Vector'],link.to_socket)
        mesh.transform(inverse@evaluated.matrix_world)
        if obj.name.startswith('original relief head'):
            vertices=[v.co.copy() for v in mesh.vertices]
            edge=max(v.z for v in vertices)
            points=[v for v in vertices if v.z>=edge-1e-5]
            cap=sum(points,Vector())/len(points)
        clone=bpy.data.objects.new(obj.name+' portable',mesh)
        bpy.context.collection.objects.link(clone);copies.append(clone)
    for obj in objects:bpy.data.objects.remove(obj,do_unlink=True)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in copies:obj.select_set(True)
    bpy.context.view_layer.objects.active=copies[0]
    bpy.ops.object.join()
    joined=copies[0];joined.name='Original native pickaxe'
    joined.data.uv_layers.new(name='BakeUV')
    joined.data.uv_layers.active=joined.data.uv_layers['BakeUV']
    joined.data.uv_layers['BakeUV'].active_render=True
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.006)
    bpy.ops.object.mode_set(mode='OBJECT')
    return joined,list(cap)


def bake(obj,kind,folder):
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=8
    scene.render.bake.margin=6;scene.render.bake.use_clear=True
    scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True
    image=bpy.data.images.new(kind,1024,1024,alpha=False,float_buffer=False)
    image.colorspace_settings.name='sRGB' if kind=='albedo' else 'Non-Color'
    temporary=[]
    for mat in obj.data.materials:
        nodes=mat.node_tree.nodes;links=mat.node_tree.links
        target=nodes.new('ShaderNodeTexImage');target.image=image;nodes.active=target
        if kind in ('roughness','metallic'):
            output=next(n for n in nodes if n.type=='OUTPUT_MATERIAL' and n.is_active_output)
            original=output.inputs['Surface'].links[0].from_socket
            principled=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
            field=principled.inputs[kind.title()]
            emission=nodes.new('ShaderNodeEmission')
            if field.is_linked:links.new(field.links[0].from_socket,emission.inputs['Color'])
            else:emission.inputs['Color'].default_value=(*([field.default_value]*3),1)
            links.new(emission.outputs[0],output.inputs['Surface'])
            temporary.append((mat,target,output,original,emission))
        else:temporary.append((mat,target,None,None,None))
    bpy.ops.object.bake(type={'albedo':'DIFFUSE','normal':'NORMAL'}.get(kind,'EMIT'))
    image.filepath_raw=str(folder/(kind+'.png'));image.file_format='PNG';image.save()
    for mat,target,output,original,emission in temporary:
        if output:mat.node_tree.links.new(original,output.inputs['Surface']);mat.node_tree.nodes.remove(emission)
        mat.node_tree.nodes.remove(target)
    return image


def export(gear,objects,inverse,output):
    folder=output/gear;folder.mkdir(parents=True,exist_ok=True)
    obj,cap=portable_mesh(objects,inverse)
    albedo=bake(obj,'albedo',folder);normal=bake(obj,'normal',folder)
    rough=bake(obj,'roughness',folder);metal=bake(obj,'metallic',folder)
    pixels=np.ones(1024*1024*4,dtype=np.float32).reshape((-1,4))
    rp=np.empty(pixels.size,dtype=np.float32);mp=rp.copy()
    rough.pixels.foreach_get(rp);metal.pixels.foreach_get(mp)
    pixels[:,1]=rp.reshape((-1,4))[:,0];pixels[:,2]=mp.reshape((-1,4))[:,0]
    orm=bpy.data.images.new('ORM',1024,1024,alpha=False)
    orm.colorspace_settings.name='Non-Color';orm.pixels.foreach_set(pixels.ravel())
    orm.filepath_raw=str(folder/'orm.png');orm.file_format='PNG';orm.save()
    mat=bpy.data.materials.new('Original baked '+gear);mat.use_nodes=True
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;p=nodes.get('Principled BSDF')
    p.inputs['Metallic'].default_value=1
    for label,img in [('albedo',albedo),('normal',normal),('orm',orm)]:
        tex=nodes.new('ShaderNodeTexImage');tex.image=img
        if label=='albedo':links.new(tex.outputs['Color'],p.inputs['Base Color'])
        elif label=='normal':
            n=nodes.new('ShaderNodeNormalMap');links.new(tex.outputs['Color'],n.inputs['Color']);links.new(n.outputs['Normal'],p.inputs['Normal'])
        else:
            sep=nodes.new('ShaderNodeSeparateColor');links.new(tex.outputs['Color'],sep.inputs[0])
            links.new(sep.outputs['Green'],p.inputs['Roughness']);links.new(sep.outputs['Blue'],p.inputs['Metallic'])
    obj.data.materials.clear();obj.data.materials.append(mat)
    for face in obj.data.polygons:face.material_index=0
    for layer in list(obj.data.uv_layers):
        if layer.name!='BakeUV':obj.data.uv_layers.remove(layer)
    raw=output/(gear+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(raw),export_format='GLB',use_selection=True,export_animations=False,export_extras=False,export_yup=True)
    obj.data.calc_loop_triangles()
    assert raw.stat().st_size>10000
    return {'file':raw.name+'.raw','sha256':sha(raw),'tool_cap_local':cap,'vertices':len(obj.data.vertices),'triangles':len(obj.data.loop_triangles),'original_surface_baked':True}


def main():
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--gear');args=p.parse_args(sys.argv[sys.argv.index('--')+1:])
    output=args.output.resolve();output.mkdir(parents=True,exist_ok=True)
    bindings=json.loads((HERE/'bindings.json').read_text());inverse=Matrix(bindings['rest']['tool']).inverted()
    accepted={v['gear']:v for v in json.loads((HERE/'original-tool-parity.json').read_text())}
    report={'schema':1,'source':'Original v9 authoring functions and production artwork; archived native parity checked','parity_sha256':sha(HERE/'original-tool-parity.json'),'tools':{}}
    for gear in [args.gear] if args.gear else bindings['gears']:
        objects=construct(gear,output)
        generated=snapshot(objects,inverse)
        # Exact source/PNG hashes bind CI to the locally compared native files.
        # Float UVs differ by final rounding bits across fresh Blender sessions.
        assert input_hashes(gear)==accepted[gear]['source_inputs'],gear+' original authoring inputs changed'
        layout={name:{'vertices':len(row['coords']),'faces':len(row['faces']),'uv_corners':len(row['uv'])} for name,row in generated.items()}
        assert layout==accepted[gear]['mesh_layout'],gear+' original mesh layout changed'
        report['tools'][gear]=export(gear,objects,inverse,output)
        (output/(gear+'.glb')).rename(output/(gear+'.glb.raw'))
        print('ORIGINAL_PICKAXE_BAKED',gear,flush=True)
    (output/'source-manifest.json').write_text(json.dumps(report,indent=2)+'\n')
    print('ORIGINAL_PICKAXES_COMPLETE',len(report['tools']),flush=True)

if __name__=='__main__':main()
