"""Study-only forearm frame correction; preserve all authored joint positions."""
import math
import bpy
from mathutils import Matrix


def align_right_forearm(rig,rest,pose):
    """Apply after the native atomic pose; never accumulate frame-to-frame twist."""
    before={b.name:b.matrix.copy() for b in rig.pose.bones}
    bone=rig.data.bones['lower.R']
    rest_axis=(bone.tail_local-bone.head_local).normalized()
    axis=(pose['arms']['R'][2]-pose['arms']['R'][1]).normalized()
    transported=rest_axis.rotation_difference(axis)@rest['radials']['R']
    desired=pose['radials']['R']
    a=transported-axis*transported.dot(axis)
    b=desired-axis*desired.dot(axis)
    projection=min(a.length,b.length)
    assert projection>.05, ('Unstable forearm radial projection',projection)
    a.normalize();b.normalize()
    angle=math.atan2(axis.dot(a.cross(b)),a.dot(b))
    target={name:matrix.copy() for name,matrix in before.items()}
    target['lower.R']=Matrix.Rotation(angle,4,axis)@before['lower.R']
    target['lower.R'].translation=before['lower.R'].translation
    for pb in rig.pose.bones:
        parent=pb.parent
        pb.matrix_basis=pb.bone.convert_local_to_pose(
            target[pb.name],pb.bone.matrix_local,
            parent_matrix=target[parent.name] if parent else Matrix.Identity(4),
            parent_matrix_local=parent.bone.matrix_local if parent else Matrix.Identity(4),
            invert=True)
    bpy.context.view_layer.update()
    protected=max(abs(rig.pose.bones[n].matrix[i][j]-m[i][j])
                  for n,m in before.items() if n!='lower.R'
                  for i in range(4) for j in range(4))
    assert protected<1e-5, ('Forearm correction moved another bone',protected)
    endpoints=max((rig.pose.bones['lower.R'].head-pose['arms']['R'][1]).length,
                  (rig.pose.bones['lower.R'].tail-pose['arms']['R'][2]).length)
    assert endpoints<1e-5, ('Forearm correction moved elbow/wrist',endpoints)
    return dict(angle_degrees=math.degrees(angle),minimum_radial_projection=projection,
                protected_matrix_error=protected,joint_position_error=endpoints)
