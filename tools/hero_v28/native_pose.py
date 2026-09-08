"""Set a complete pose atomically, without reading last frame's parent transforms."""
import bpy
from mathutils import Matrix
import motion_v3

def create_applier(rig,rest):
    mats={b.name:b.matrix_local.copy() for b in rig.data.bones}
    def apply(p):
        target={n:m.copy() for n,m in mats.items()}
        target['body']=p['torso']@mats['body']
        target['head']=p['head']@mats['head']
        old=motion_v3.frame_matrix(rest['axis'],rest['tool_normal'])
        new=motion_v3.frame_matrix(p['axis'],p['tool_normal'])
        target['tool']=(new@old.inverted()).to_4x4()@mats['tool']
        target['tool'].translation=p['rear']
        if 'bit' in mats:
            bit=target['tool']@mats['tool'].inverted()@mats['bit']
            origin=bit.translation.copy()
            target['bit']=Matrix.Rotation(p['bit_angle'],4,p['axis'])@bit
            target['bit'].translation=origin
        for side in ['R','L']:
            a,b,c=p['arms'][side];hip,knee,foot=p['legs'][side]
            for name,start,end in [('thigh.'+side,hip,knee),('shin.'+side,knee,foot),('upper.'+side,a,b),('lower.'+side,b,c)]:
                ob=rig.data.bones[name]
                target[name]=(ob.tail_local-ob.head_local).rotation_difference(end-start).to_matrix().to_4x4()@mats[name]
                target[name].translation=start
            target['foot.'+side].translation=foot
            old=motion_v3.frame_matrix(rest['hand_axes'][side],rest['radials'][side])
            new=motion_v3.frame_matrix(p['hand_axes'][side],p['radials'][side])
            target['hand.'+side]=(new@old.inverted()).to_4x4()@mats['hand.'+side]
            target['hand.'+side].translation=c
        for b in rig.pose.bones:
            parent=b.parent
            b.matrix_basis=b.bone.convert_local_to_pose(target[b.name],mats[b.name],parent_matrix=target[parent.name] if parent else Matrix.Identity(4),parent_matrix_local=mats[parent.name] if parent else Matrix.Identity(4),invert=True)
        bpy.context.view_layer.update()
        error=max(max(abs(b.matrix[i][j]-target[b.name][i][j]) for i in range(4) for j in range(4)) for b in rig.pose.bones)
        assert error<1e-5,('pose matrix mismatch',error)
    return apply
