"""One shared native bone application path for building and exporting."""
import bpy
from mathutils import Vector,Matrix
import motion_v3 as motion_v2

def create_applier(rig,rest):
    rest_mats={b.name:b.matrix_local.copy() for b in rig.data.bones}
    def apply_pose(p):
        for name in ['root','hips']:rig.pose.bones[name].matrix=rest_mats[name]
        rig.pose.bones['body'].matrix=p['torso']@rest_mats['body']
        rig.pose.bones['head'].matrix=p['head']@rest_mats['head']
        bpy.context.view_layer.update()
        old=motion_v2.frame_matrix(rest['axis'],rest['tool_normal'])
        new=motion_v2.frame_matrix(p['axis'],p['tool_normal'])
        tool_delta=(new@old.inverted()).to_4x4()
        mat=tool_delta@rest_mats['tool'];mat.translation=p['rear'];rig.pose.bones['tool'].matrix=mat
        bpy.context.view_layer.update()
        if 'bit' in rig.pose.bones:
            delta=rig.pose.bones['tool'].matrix@rest_mats['tool'].inverted()
            bit=delta@rest_mats['bit'];origin=bit.translation.copy()
            spin=Matrix.Rotation(p['bit_angle'],4,p['axis'])
            bit=spin@bit;bit.translation=origin;rig.pose.bones['bit'].matrix=bit
        for side in ['R','L']:
            a,b,c=p['arms'][side];hip,knee,foot=p['legs'][side]
            for name,start,end in [('thigh.'+side,hip,knee),('shin.'+side,knee,foot),('upper.'+side,a,b),('lower.'+side,b,c)]:
                ob=rig.data.bones[name];delta=(ob.tail_local-ob.head_local).rotation_difference(end-start).to_matrix().to_4x4()
                mat=delta@rest_mats[name];mat.translation=start
                rig.pose.bones[name].matrix=mat;bpy.context.view_layer.update()
            mat=rest_mats['foot.'+side].copy();mat.translation=foot;rig.pose.bones['foot.'+side].matrix=mat
            old=motion_v2.frame_matrix(rest['hand_axes'][side],rest['radials'][side])
            new=motion_v2.frame_matrix(p['hand_axes'][side],p['radials'][side])
            mat=(new@old.inverted()).to_4x4()@rest_mats['hand.'+side];mat.translation=c
            rig.pose.bones['hand.'+side].matrix=mat;bpy.context.view_layer.update()

    return apply_pose
