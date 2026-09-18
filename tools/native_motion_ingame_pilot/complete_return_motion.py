"""One complete mining cycle using the original idle tool pose as its rest.

The accepted study load at .40 and original contact/hold at .55--.625 stay
fixed. The tool returns rigidly to the same rest used at the next cycle's
start. Original body/feet, two-hand grip, arm solver and game clock remain.
This is an unaccepted native proposal; affected bridges need new checks.
"""
import native_motion as native
import premium_motion as pm
from cross_shoulder_load_motion import CrossShoulderLoadMotion


RETURN_START = .625


def smoother(value):
    value = max(0., min(1., value))
    return value ** 3 * (10. + value * (-15. + 6. * value))


class CompleteReturnMotion(CrossShoulderLoadMotion):
    def __init__(self, surface, hinge, pivot_report):
        super().__init__(surface, hinge, pivot_report)
        rest = self.original.sample('idle', 0.)
        self.rest_rear = rest['rear'].copy()
        self.rest_rotation = pm.tool_frame(rest['axis'], rest['tool_normal']).to_quaternion()
        self.contact_rotation = pm.tool_frame(
            self.contact_pose['axis'], self.contact_pose['tool_normal']).to_quaternion()
        self.start = self._with_tool(self.original.sample('mine', 0.),
                                     self.rest_rear, self.rest_rotation)

    @staticmethod
    def _with_tool(original, rear, rotation):
        frame = rotation.to_matrix()
        solved = pm._assemble(
            'worn', original['torso'], original['head'], rear, frame.col[0], frame.col[2],
            {s: original['legs'][s][0] for s in native.SIDES},
            {s: original['legs'][s][2] for s in native.SIDES},
            original['bit_angle'], original['contacts'],
            {s: original['legs'][s][1] for s in native.SIDES})
        result = dict(original)
        for key in ('rear', 'axis', 'tool_normal', 'grips', 'hand_axes', 'radials', 'arms'):
            result[key] = solved[key]
        return result

    def sample(self, state, phase, speed=340.):
        q = phase % 1.
        if state != 'mine' or 0. < q <= RETURN_START:
            return super().sample(state, phase, speed)
        original = self.original.sample(state, phase, speed)
        if q == 0.:
            return self._with_tool(original, self.rest_rear, self.rest_rotation)
        amount = smoother((q - RETURN_START) / (1. - RETURN_START))
        rear = self.contact_pose['rear'].lerp(self.rest_rear, amount)
        rotation = self.contact_rotation.slerp(self.rest_rotation, amount)
        return self._with_tool(original, rear, rotation)

    def selection(self):
        out = super().selection()
        out.pop('contact_and_recovery_unchanged', None)
        out.update(
            rest_rule='Original idle phase zero rigid tool pose at mining phases zero and one',
            return_start=RETURN_START,
            return_end=1.,
            return_rule='Quintic rear-grip interpolation and shortest rigid quaternion slerp',
            rest_rear=list(self.rest_rear), rest_rotation=list(self.rest_rotation),
            changed_ranges='[0,.40) preparation and (.625,1] recovery',
            unchanged_range='[.40,.625] load, downstroke, contact and hold',
            visual_accepted=False, production_accepted=False)
        return out
