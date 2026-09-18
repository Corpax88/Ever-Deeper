"""Inspect the actual source rig without changing or saving its Blender scene."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

import bpy

p = argparse.ArgumentParser()
p.add_argument('--output', type=Path, required=True)
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
source = Path(bpy.data.filepath)
rigs = []
for ob in bpy.data.objects:
    if ob.type != 'ARMATURE':
        continue
    meshes = [m for m in bpy.data.objects if m.type == 'MESH' and any(
        x.type == 'ARMATURE' and x.object == ob for x in m.modifiers)]
    rigs.append({
        'name': ob.name,
        'matrix_world': [list(row) for row in ob.matrix_world],
        'bound_meshes': len(meshes),
        'bound_vertices': sum(len(m.data.vertices) for m in meshes),
        'bones': [{
            'name': b.name, 'parent': b.parent.name if b.parent else None,
            'head': list(b.head_local), 'tail': list(b.tail_local),
            'length': b.length, 'deform': b.use_deform,
            'rest_matrix': [list(row) for row in b.matrix_local],
            'constraints': [c.type for c in ob.pose.bones[b.name].constraints],
        } for b in ob.data.bones],
    })
result = {'source': str(source), 'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
          'blender': bpy.app.version_string, 'rigs': rigs,
          'actions': [{'name': x.name, 'range': list(x.frame_range)} for x in bpy.data.actions],
          'render_engine': bpy.context.scene.render.engine,
          'changed_source': False}
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'rigs': [{k: v for k, v in r.items() if k not in ('bones', 'matrix_world')}
                         | {'bone_names': [b['name'] for b in r['bones']]} for r in rigs],
                  'report': str(a.output)}))
