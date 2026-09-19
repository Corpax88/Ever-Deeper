"""Study 16: withdraw the pick to camera-left before the next lift.

Only the original Worn/up camera is studied. A 25px horizontal offset was
derived from the actual ore-alpha contour: 24.494px was the largest required
amplitude after weighting the curve, including a 2px clearance margin.
The .625 contact/hold endpoint and .30 preparation endpoint remain unchanged.
The old overlapping side-carry pose moves; continuity across phase zero stays.
This candidate still requires rig, image and actual-video verification.
"""
from mathutils import Vector

import premium_motion as pm
from complete_return_motion import smoother
from coordinated_body_motion import CoordinatedBodyMotion


class ClearReturnMotion(CoordinatedBodyMotion):
    PIXELS = 25.
    ORTHO_SCALE = 2.9
    LOGICAL_FRAME_SIZE = 160.

    def __init__(self, *args):
        super().__init__(*args)
        # Exact camera authored by export_hero.view('up', (6, 6)). Orthographic
        # screen-horizontal translation is independent of depth and elevation.
        eye, target = Vector((6., 6., 7.)), Vector((0., -.10, .98))
        camera_rotation = (target-eye).to_track_quat('-Z', 'Y')
        self.clearance_direction = camera_rotation @ Vector((-1., 0., 0.))
        self.clearance_offset = self.clearance_direction*(self.PIXELS*self.ORTHO_SCALE/self.LOGICAL_FRAME_SIZE)

    @staticmethod
    def clearance_weight(phase):
        q = phase % 1.
        if q <= .08 or q >= .86:
            return 1.
        if q < .30:
            return 1.-smoother((q-.08)/(.30-.08))
        if q > .625:
            return smoother((q-.625)/(.86-.625))
        return 0.

    def sample(self, state, phase, speed=340.):
        pose = super().sample(state, phase, speed)
        weight = self.clearance_weight(phase) if state == 'mine' else 0.
        if weight == 0.:
            return pose
        rotation = pm.tool_frame(pose['axis'], pose['tool_normal']).to_quaternion()
        return self._with_tool(pose, pose['rear']+self.clearance_offset*weight, rotation)

    def selection(self):
        result = super().selection()
        result.update(clear_return_study=True, clearance_pixels=self.PIXELS,
                      clearance_direction=list(self.clearance_direction),
                      clearance_offset_native=list(self.clearance_offset),
                      clearance_knots=[.625, .86, 1.08, 1.30],
                      changed='Rigid tool translation during return and early preparation; exact grips re-solved',
                      protected='Body, feet, tool orientation, .30-.625 tool path and game clock',
                      visual_accepted=False, production_accepted=False)
        return result
