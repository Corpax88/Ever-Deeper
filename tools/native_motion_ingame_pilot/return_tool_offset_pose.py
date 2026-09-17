"""One study-only rigid return translation on the original Worn/up pose.

No model, torso, root, foot, contact, tool orientation or elbow-pole change.
The original .125-.625 work window returns the original pose by identity.
"""
from mathutils import Vector
import native_motion as native
import premium_motion as pm

GRIP_SPAN = .145


def weight(q):
    q %= 1.
    if q < .125:
        return 1. - pm.smooth(q / .125)
    if q <= .625:
        return 0.
    if q < .8125:
        return pm.smooth((q - .625) / (.8125 - .625))
    return 1.


def sample(original, q, frozen_target_ground):
    amount = weight(q)
    right = pm.heading_matrix(frozen_target_ground) @ Vector((-1., 0., 0.))
    offset = (right * (GRIP_SPAN * .5) + Vector((0., 0., GRIP_SPAN))) * amount
    if amount == 0.:
        return original, offset
    solved = pm._assemble(
        'worn', original['torso'], original['head'], original['rear'] + offset,
        original['axis'], original['tool_normal'],
        {s: original['legs'][s][0] for s in native.SIDES},
        {s: original['legs'][s][2] for s in native.SIDES},
        original['bit_angle'], original['contacts'],
        {s: original['legs'][s][1] for s in native.SIDES})
    result = dict(original)
    for key in ('rear', 'grips', 'arms'):
        result[key] = solved[key]
    return result, offset
