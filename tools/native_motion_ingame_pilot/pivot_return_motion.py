"""Study 16B: clear the ore by turning the rigid pick around its rear grip.

The amplitude is derived from the evaluated study15 head mesh and the actual
ore's conservative filtered-alpha support planes in the original up view.
Body, feet, rear grip, .30-.625 strike path and game clock are unchanged.
This remains a study until native rig, actual game and video review pass.
"""
import math
from mathutils import Quaternion, Vector
import premium_motion as pm
from complete_return_motion import smoother
from coordinated_body_motion import CoordinatedBodyMotion


class PivotReturnMotion(CoordinatedBodyMotion):
    ANGLE_DEGREES = 72.01487926079041

    def __init__(self, *args):
        super().__init__(*args)
        self.pivot_axis = (Vector((0., -.10, .98))-Vector((6., 6., 7.))).normalized()

    @staticmethod
    def clearance_weight(phase):
        q = phase % 1.
        if q <= .08 or q >= .86:
            return 1.
        if q < .30:
            return 1.-smoother((q-.08)/.22)
        if q > .625:
            return smoother((q-.625)/.235)
        return 0.

    def sample(self, state, phase, speed=340.):
        original = super().sample(state, phase, speed)
        weight = self.clearance_weight(phase) if state == 'mine' else 0.
        if not weight:
            return original
        frame = pm.tool_frame(original['axis'], original['tool_normal']).to_quaternion()
        turn = Quaternion(self.pivot_axis, -math.radians(self.ANGLE_DEGREES)*weight)
        return self._with_tool(original, original['rear'], turn@frame)

    def selection(self):
        result = super().selection()
        result.update(
            pivot_return_study=True, pivot='Original rear/right grip',
            rotation_axis=list(self.pivot_axis), angle_degrees=-self.ANGLE_DEGREES,
            weight_knots=[.625, .86, 1.08, 1.30],
            protected='Body, feet, right grip, .30-.625 complete tool pose and unchanged game clock',
            changed='Rigid tool rotation during return and early preparation; both wrists and elbows re-solved',
            visual_accepted=False, production_accepted=False)
        return result
