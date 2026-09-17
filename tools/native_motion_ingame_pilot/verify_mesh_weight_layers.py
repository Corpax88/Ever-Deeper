"""Tiny synthetic Blender API check; no game model, asset or rendering."""
from pathlib import Path
import argparse
import json
import sys
import bpy

parser = argparse.ArgumentParser()
parser.add_argument('--output',type=Path,required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.object.armature_add()
rig = bpy.context.object
rig.data.bones[0].name = 'head'
report = {'complete':False,'rendered':False,'native_game_asset_loaded':False,
          'engine':bpy.app.version_string,
          'local_api_description':bpy.types.Object.bl_rna.functions['to_mesh'].parameters['preserve_all_data_layers'].description,
          'cases':[]}
for kind in ('NONE','BEVEL','SOLIDIFY','SUBSURF'):
    bpy.ops.mesh.primitive_cube_add()
    obj = bpy.context.object
    group = obj.vertex_groups.new(name='head'); group.add(list(range(len(obj.data.vertices))),1.,'REPLACE')
    if kind != 'NONE':
        modifier = obj.modifiers.new('Fixture geometry',kind)
        if kind == 'BEVEL':modifier.width=.1;modifier.segments=3
        if kind == 'SUBSURF':modifier.levels=2
    arm = obj.modifiers.new('Fixture head skin','ARMATURE'); arm.object=rig
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get(); evaluated = obj.evaluated_get(depsgraph)
    for keep in (False,True):
        mesh = evaluated.to_mesh(preserve_all_data_layers=keep,depsgraph=depsgraph)
        values = [g.weight for v in mesh.vertices for g in v.groups]
        report['cases'].append({'modifier':kind,'preserve_all_data_layers':keep,'vertices':len(mesh.vertices),
            'vertices_without_weights':sum(not v.groups for v in mesh.vertices),
            'minimum_weight':min(values) if values else None,'maximum_weight':max(values) if values else None,
            'maximum_difference_from_one':max(abs(v-1.) for v in values) if values else None})
        evaluated.to_mesh_clear()
report['complete'] = True
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps(report,indent=2)+'\n')
print('MESH_WEIGHT_LAYER_CHECK_COMPLETE',len(report['cases']),flush=True)
