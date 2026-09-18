"""One target-bound native Worn/up surface strike, never a runtime fallback.

The original target-facing windup reaches .40. A single accelerating rigid-tool
arc reaches the explicit contact transform at .55, then stops at that surface
through .625 before native recovery. Gameplay timing and lower body are external.
"""
from mathutils import Matrix, Vector
import native_motion as native
import premium_motion as pm


def sample(q, ground, target_ground, contact):
    q %= 1.
    protected = native.sample('worn', 'mine', q, ground, 340.)
    aimed = native.sample('worn', 'mine', q, target_ground, 340.)
    rear = Vector(contact['rear'])
    rotation = Matrix(contact['tool_frame'])
    if q < .40:
        rear = aimed['rear']
        rotation = pm.tool_frame(aimed['axis'], aimed['tool_normal'])
    elif q < .55:
        start = native.sample('worn', 'mine', .40, target_ground, 340.)
        w = ((q-.40)/.15)**2
        rear = start['rear'].lerp(rear, w)
        rotation = pm.tool_frame(start['axis'], start['tool_normal']).to_quaternion().slerp(rotation.to_quaternion(), w).to_matrix()
    elif q > .625:
        w = pm.smooth((q-.625)/(.82-.625))
        rear = rear.lerp(aimed['rear'], w)
        rotation = rotation.to_quaternion().slerp(pm.tool_frame(aimed['axis'], aimed['tool_normal']).to_quaternion(), w).to_matrix()
    solved = pm._assemble('worn', aimed['torso'], aimed['head'], rear, rotation.col[0], rotation.col[2],
                          {s:protected['legs'][s][0] for s in native.SIDES},
                          {s:protected['legs'][s][2] for s in native.SIDES},
                          protected['bit_angle'], protected['contacts'],
                          {s:protected['legs'][s][1] for s in native.SIDES})
    result = dict(protected)
    for key in ('torso', 'head', 'rear', 'axis', 'tool_normal', 'grips', 'hand_axes', 'radials', 'arms'):
        result[key] = solved[key]
    return result, protected
