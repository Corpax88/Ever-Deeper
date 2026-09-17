"""One genuine native tool pivot about an unchanged working-cap trajectory."""
import native_motion as native
import premium_motion as pm
import working_surface_arc


def sample(q, ground, target, base_contact, local_cap, rotation):
    original, protected = working_surface_arc.sample(q, ground, target, base_contact)
    frame = pm.tool_frame(original['axis'], original['tool_normal'])
    cap = original['rear']+frame@local_cap
    frame = rotation@frame
    rear = cap-frame@local_cap
    solved = pm._assemble('worn', original['torso'], original['head'], rear, frame.col[0], frame.col[2],
                          {s:original['legs'][s][0] for s in native.SIDES},
                          {s:original['legs'][s][2] for s in native.SIDES},
                          original['bit_angle'], original['contacts'],
                          {s:original['legs'][s][1] for s in native.SIDES})
    result = dict(original)
    for key in ('rear', 'axis', 'tool_normal', 'grips', 'hand_axes', 'radials', 'arms'):
        result[key] = solved[key]
    return result, original, protected, cap
