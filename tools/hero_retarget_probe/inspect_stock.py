"""Import the real donor and inspect actual action slots and rest skeleton."""
import argparse
import json
from pathlib import Path
import sys
import bpy

p = argparse.ArgumentParser()
p.add_argument('--glb', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--sample-actions', nargs='*', default=[])
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
bpy.ops.import_scene.gltf(filepath=str(a.glb))
rig = next(x for x in bpy.context.scene.objects if x.type == 'ARMATURE')
result = {'rig': rig.name, 'scale': list(rig.scale), 'matrix_world': [list(v) for v in rig.matrix_world],
          'fps': bpy.context.scene.render.fps,
          'bones': [{'name': b.name, 'parent': b.parent.name if b.parent else None,
                     'head': list(b.head_local), 'tail': list(b.tail_local),
                     'rest_matrix': [list(v) for v in b.matrix_local]} for b in rig.data.bones],
          'actions': [{'name': ac.name, 'frames': list(ac.frame_range),
                       'slots': [{'identifier': s.identifier, 'target_id_type': s.target_id_type} for s in ac.slots]}
                      for ac in bpy.data.actions]}
if a.sample_actions:
    result['pose_samples'] = []
    rig.animation_data_create()
    rig.animation_data.use_nla = False
    for name in a.sample_actions:
        action = bpy.data.actions[name]
        rig.animation_data.action = action
        rig.animation_data.action_slot = action.slots[0]
        lo, hi = action.frame_range
        for phase in (0., .125, .25, .5, .75, 1.):
            frame = lo + phase*(hi-lo)
            bpy.context.scene.frame_set(int(frame), subframe=frame-int(frame))
            result['pose_samples'].append({'action': name, 'phase': phase,
                'bones': {b.name: {'head': list(b.head), 'tail': list(b.tail),
                                   'matrix': [list(row) for row in b.matrix]}
                          for b in rig.pose.bones}})
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'rig': rig.name, 'bones': len(rig.data.bones), 'fps': result['fps'],
                  'core_bones': [x for x in result['bones'] if x['name'] in ('root','pelvis','spine_03','Head','upperarm_l','upperarm_r','hand_l','hand_r','thigh_l','calf_l','foot_l')],
                  'actions': [x for x in result['actions'] if x['name'] in ('Idle_Loop','Walk_Loop','A_TPose')]}))
