"""One diagnostic Worn/up target arc, not a runtime animation controller."""
import math
from mathutils import Matrix, Vector
import native_motion as native
import premium_motion as pm


def contact_weight(q):
    q %= 1.
    if q < .4: return 0.
    if q < .55: return pm.smooth((q-.4)/.15)
    if q <= .625: return 1.
    return pm.smooth((.82-q)/(.82-.625)) if q < .82 else 0.


def sample(q, ground, target_ground, specification):
    protected = native.sample('worn','mine',q,ground,340.)
    aimed = native.sample('worn','mine',q,target_ground,340.)
    direction = Vector(target_ground).normalized()
    w = contact_weight(q)
    target_rear = aimed['torso']@Vector((specification['lateral'],specification['forward'],specification['height']))
    pitch = math.radians(specification['pitch_degrees'])
    axis = Vector((direction.x*math.cos(pitch),direction.y*math.cos(pitch),math.sin(pitch)))
    normal = Vector((direction.x*math.sin(pitch),direction.y*math.sin(pitch),-math.cos(pitch)))
    normal = Matrix.Rotation(math.radians(specification['roll_degrees']),3,axis)@normal
    rotation = pm.tool_frame(aimed['axis'],aimed['tool_normal']).to_quaternion().slerp(pm.tool_frame(axis,normal).to_quaternion(),w).to_matrix()
    solved = pm._assemble('worn',aimed['torso'],aimed['head'],aimed['rear'].lerp(target_rear,w),rotation.col[0],rotation.col[2],
                          {s:protected['legs'][s][0] for s in native.SIDES},{s:protected['legs'][s][2] for s in native.SIDES},
                          protected['bit_angle'],protected['contacts'],{s:protected['legs'][s][1] for s in native.SIDES})
    result = dict(protected)
    for key in ('torso','head','rear','axis','tool_normal','grips','hand_axes','radials','arms'):
        result[key] = solved[key]
    return result, protected
