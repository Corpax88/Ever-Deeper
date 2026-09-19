"""Apply explicit transported arm frames; retain the original fallback."""
import bpy
from mathutils import Matrix
from forearm_frame_pose import align_right_forearm as legacy_align_right_forearm


def align_right_forearm(rig, rest, pose):
    if 'right_forearm_basis' not in pose:
        return legacy_align_right_forearm(rig, rest, pose)
    before = {b.name: b.matrix.copy() for b in rig.pose.bones}
    bone = rig.data.bones['lower.R']
    rest_axis = (bone.tail_local-bone.head_local).normalized()
    radial = rest['radials']['R']
    radial = radial-rest_axis*radial.dot(rest_axis)
    assert radial.length > .05, ('Unstable rest forearm frame', radial.length)
    rest_basis = Matrix((rest_axis, radial.normalized(),
                         rest_axis.cross(radial.normalized()))).transposed()
    frame = pose['right_forearm_basis']
    axis = (pose['arms']['R'][2]-pose['arms']['R'][1]).normalized()
    error = (frame.col[0]-axis).length
    product = frame.transposed() @ frame
    orthogonal = max(abs(product[i][j]-float(i == j)) for i in range(3) for j in range(3))
    assert max(error, orthogonal, abs(frame.determinant()-1.)) < 1e-5
    assert pose['right_forearm_reference_denominator'] > .05
    assert pose['right_forearm_original_radial_projection'] > .05
    target = {name: matrix.copy() for name, matrix in before.items()}
    target['lower.R'] = (frame @ rest_basis.transposed() @ bone.matrix_local.to_3x3()).to_4x4()
    target['lower.R'].translation = before['lower.R'].translation
    left = rig.data.bones['upper.L']
    old_axis = pose['left_upper_original_axis']
    left_rest_axis = (left.tail_local-left.head_local).normalized()
    original_denominator = 1.+left_rest_axis.dot(old_axis)
    assert original_denominator > .01, ('Unstable original left-upper frame', original_denominator)
    assert pose['left_upper_reference_denominator'] > .05
    old_frame = left_rest_axis.rotation_difference(old_axis).to_matrix() @ left.matrix_local.to_3x3()
    new_frame = pose['left_upper_transport'] @ old_frame
    target['upper.L'] = new_frame.to_4x4()
    target['upper.L'].translation = before['upper.L'].translation
    new_left_axis = (pose['arms']['L'][1]-pose['arms']['L'][0]).normalized()
    assert ((new_frame @ left.matrix_local.to_3x3().inverted()) @ left_rest_axis-new_left_axis).length < 1e-5
    extra_names = tuple(pose.get('extra_arm_transports', {}))
    for name in extra_names:
        native_bone = rig.data.bones[name]
        rest_axis = (native_bone.tail_local-native_bone.head_local).normalized()
        prior_axis = pose['extra_arm_original_axes'][name]
        assert 1.+rest_axis.dot(prior_axis) > .01, ('Unstable original arm frame', name)
        assert pose['extra_arm_reference_denominators'][name] > .05
        prior_frame = rest_axis.rotation_difference(prior_axis).to_matrix() @ native_bone.matrix_local.to_3x3()
        carried_frame = pose['extra_arm_transports'][name] @ prior_frame
        target[name] = carried_frame.to_4x4()
        target[name].translation = before[name].translation
    changed_names = ('lower.R', 'upper.L') + extra_names
    for pb in rig.pose.bones:
        parent = pb.parent
        pb.matrix_basis = pb.bone.convert_local_to_pose(
            target[pb.name], pb.bone.matrix_local,
            parent_matrix=target[parent.name] if parent else Matrix.Identity(4),
            parent_matrix_local=parent.bone.matrix_local if parent else Matrix.Identity(4),
            invert=True)
    bpy.context.view_layer.update()
    protected = max(abs(rig.pose.bones[n].matrix[i][j]-m[i][j])
                    for n, m in before.items() if n not in changed_names
                    for i in range(4) for j in range(4))
    endpoints = max((rig.pose.bones['lower.R'].head-pose['arms']['R'][1]).length,
                    (rig.pose.bones['lower.R'].tail-pose['arms']['R'][2]).length)
    endpoints = max(endpoints,
                    (rig.pose.bones['upper.L'].head-pose['arms']['L'][0]).length,
                    (rig.pose.bones['upper.L'].tail-pose['arms']['L'][1]).length)
    applied = max(abs(rig.pose.bones[name].matrix[i][j]-target[name][i][j])
                  for name in changed_names for i in range(4) for j in range(4))
    for name in extra_names:
        side = name[-1]
        part = 0 if name.startswith('upper.') else 1
        endpoints = max(endpoints, (rig.pose.bones[name].head-pose['arms'][side][part]).length,
                        (rig.pose.bones[name].tail-pose['arms'][side][part+1]).length)
    assert max(protected, endpoints, applied) < 1e-5
    return dict(method='torso-carried original full frame with shortest axis alignment',
                transported_arm_bones=list(changed_names),
                reference_denominator=pose['right_forearm_reference_denominator'],
                left_reference_denominator=pose['left_upper_reference_denominator'],
                original_left_rest_denominator=original_denominator,
                original_radial_projection=pose['right_forearm_original_radial_projection'],
                frame_axis_error=error, orthogonality_error=orthogonal,
                protected_matrix_error=protected, joint_position_error=endpoints,
                applied_matrix_error=applied)
