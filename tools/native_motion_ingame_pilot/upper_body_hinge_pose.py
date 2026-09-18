"""Study-only anatomical body hinge with the saved fixed-cap tool arc intact.

The approved body joint is supplied from measured rig data. The torso and head
share one rigid delta around that joint; both arms are solved again against the
unchanged real grips. No object, camera, actor root or lower-body field moves.
"""
import math
from mathutils import Matrix
import native_motion as native
import premium_motion as pm
import fixed_cap_pivot_pose


def action_weight(q):
    q %= 1.
    if q < .125:
        return pm.smooth(q/.125)
    if q <= .625:
        return 1.
    if q < .82:
        return 1.-pm.smooth((q-.625)/(.82-.625))
    return 0.


def sample(q, ground, target, contact, local_cap, tool_rotation,
           body_joint, lean_degrees, twist_degrees):
    original, _, protected, cap = fixed_cap_pivot_pose.sample(
        q, ground, target, contact, local_cap, tool_rotation)
    weight = action_weight(q)
    if weight == 0. or (lean_degrees == 0. and twist_degrees == 0.):
        return original, original, protected, cap, Matrix.Identity(4)
    # Local twist is applied first, followed by local side lean. Translation to
    # and from the actual body bone head makes that anatomical joint invariant.
    bend = (Matrix.Translation(body_joint)
            @ Matrix.Rotation(math.radians(lean_degrees)*weight, 4, 'Y')
            @ Matrix.Rotation(math.radians(twist_degrees)*weight, 4, 'Z')
            @ Matrix.Translation(-body_joint))
    torso = original['torso']@bend
    delta = torso@original['torso'].inverted()
    head = delta@original['head']
    solved = pm._assemble(
        'worn', torso, head, original['rear'], original['axis'],
        original['tool_normal'],
        {s:original['legs'][s][0] for s in native.SIDES},
        {s:original['legs'][s][2] for s in native.SIDES},
        original['bit_angle'], original['contacts'],
        {s:original['legs'][s][1] for s in native.SIDES})
    result = dict(original)
    for key in ('torso', 'head', 'arms'):
        result[key] = solved[key]
    return result, original, protected, cap, delta
