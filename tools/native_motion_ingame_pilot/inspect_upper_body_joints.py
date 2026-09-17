"""Read only approved native rig joints; never load its mesh or render."""
from pathlib import Path
import argparse
import hashlib
import json
import sys
import bpy
from mathutils import Matrix

parser=argparse.ArgumentParser()
parser.add_argument('--model',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
digest=hashlib.sha256(args.model.read_bytes()).hexdigest()
assert digest=='94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
with bpy.data.libraries.load(str(args.model),link=False) as (source,destination):
    assert 'EverDeeper_Hero_Rig' in source.objects
    destination.objects=['EverDeeper_Hero_Rig']
rig=destination.objects[0]
assert rig.type=='ARMATURE'
assert max(abs(rig.matrix_world[i][j]-Matrix.Identity(4)[i][j]) for i in range(4) for j in range(4))<1e-8
names=['root','hips','body','head','upper.R','lower.R','hand.R','upper.L','lower.L','hand.L','thigh.R','thigh.L']
bones={name:{'parent':rig.data.bones[name].parent.name if rig.data.bones[name].parent else None,
             'head_local':list(rig.data.bones[name].head_local),
             'tail_local':list(rig.data.bones[name].tail_local),
             'matrix_local':[list(row) for row in rig.data.bones[name].matrix_local],
             'length':rig.data.bones[name].length} for name in names}
head_descendants=[]
for bone in rig.data.bones:
    current=bone
    while current:
        if current.name=='head':head_descendants.append(bone.name);break
        current=current.parent
report={'complete':True,'rendered':False,'loaded_native_mesh_objects':sum(o.type=='MESH' for o in destination.objects),
        'model_sha256':digest,'source_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'rig':rig.name,'body_joint_local':bones['body']['head_local'],'bones':bones,
        'head_bone_and_descendants':head_descendants,
        'scope':'Actual approved anatomical joint and ancestry metadata only; no pose, mesh occlusion, visibility or anatomy acceptance.'}
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps(report,indent=2)+'\n')
print('NATIVE_JOINT_READ_COMPLETE',report['body_joint_local'],len(head_descendants),flush=True)
