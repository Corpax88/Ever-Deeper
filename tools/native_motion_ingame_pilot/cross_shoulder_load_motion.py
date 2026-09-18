"""One contour-derived cross-shoulder load on the original native rig.

Only the previously rejected load target changes. The arm solver, original
start/contact/recovery, timing and protected body pose remain inherited. The
two-pixel projected head clearance is a study hypothesis, not visual approval.
"""
from pathlib import Path
import json
from mathutils import Vector
import premium_motion as pm
from shoulder_load_motion import ShoulderLoadMotion, GRIP_SPAN, LOAD_PHASE

SELECTION = json.loads((Path(__file__).with_name('cross-shoulder-load-selection.json')).read_text())


class CrossShoulderLoadMotion(ShoulderLoadMotion):
    def __init__(self, surface, hinge, pivot_report):
        super().__init__(surface, hinge, pivot_report)
        old_load = self.original.sample('mine', LOAD_PHASE)
        right = (old_load['arms']['R'][0] - old_load['arms']['L'][0]).normalized()
        axis = (Vector((0., 0., 1.)) - right).normalized()
        turn = self.load_axis.rotation_difference(axis)
        self.load_normal = (turn @ self.load_normal).normalized()
        self.load_axis = axis
        self.load_midpoint += Vector((0., 0., SELECTION['extra_world_z_lift']))
        self.load_rear = self.load_midpoint - axis * (GRIP_SPAN * .5)
        self.load_rotation = pm.tool_frame(axis, self.load_normal).to_quaternion()

    def selection(self):
        out = super().selection()
        del out['shaft_back_lean_degrees']
        del out['lift']
        out.update(SELECTION)
        out.update(original_world_z_lift=GRIP_SPAN * .5,
                   total_world_z_lift=GRIP_SPAN * .5 + SELECTION['extra_world_z_lift'],
                   axis_rule='normalize(world_up - normalize(original_shoulder_R - original_shoulder_L))',
                   roll_rule='shortest rigid rotation from rejected shoulder-load axis; carry its normal',
                   visual_accepted=False, production_accepted=False)
        return out
