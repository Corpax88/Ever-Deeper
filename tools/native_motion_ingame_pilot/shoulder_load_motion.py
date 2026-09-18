"""One study-only backswing, with the frozen contact and recovery unchanged.

The load is defined anatomically from the existing .40 grip midpoint: pull it
back one authored grip span and lift half a span. The shaft leans 45 degrees
away from the target. Its roll follows the shortest real rigid rotation from
the old shaft, rather than a bitmap or camera adjustment. Both arms are solved
from the original moving shoulders. This is a single proposal, not approval.
"""
from mathutils import Vector
import native_motion as native
import premium_motion as pm
from return_tool_offset_motion import FrozenReturnMotion

GRIP_SPAN = .145
LOAD_PHASE = .40
CONTACT_PHASE = .55


class ShoulderLoadMotion(FrozenReturnMotion):
    def __init__(self, surface, hinge, pivot_report):
        super().__init__(surface, hinge, pivot_report)
        self.original = FrozenReturnMotion(surface, hinge, pivot_report)
        self.start = self.original.sample('mine', 0.)
        self.contact_pose = self.original.sample('mine', CONTACT_PHASE)
        old_load = self.original.sample('mine', LOAD_PHASE)
        away = -Vector((self.target.x, self.target.y, 0.)).normalized()
        self.load_axis = (away + Vector((0., 0., 1.))).normalized()
        turn = old_load['axis'].rotation_difference(self.load_axis)
        self.load_normal = (turn @ old_load['tool_normal']).normalized()
        old_midpoint = (old_load['grips']['R'] + old_load['grips']['L']) * .5
        self.load_midpoint = old_midpoint + away * GRIP_SPAN + Vector((0., 0., GRIP_SPAN * .5))
        self.load_rear = self.load_midpoint - self.load_axis * (GRIP_SPAN * .5)
        self.load_rotation = pm.tool_frame(self.load_axis, self.load_normal).to_quaternion()

    def selection(self):
        return {'load_phase': LOAD_PHASE, 'contact_phase': CONTACT_PHASE,
                'pullback': GRIP_SPAN, 'lift': GRIP_SPAN * .5,
                'shaft_back_lean_degrees': 45., 'grip_span': GRIP_SPAN,
                'load_midpoint': list(self.load_midpoint), 'load_rear': list(self.load_rear),
                'load_axis': list(self.load_axis), 'load_normal': list(self.load_normal),
                'timing': 'smooth preparation to .40; quadratic acceleration to .55',
                'contact_and_recovery_unchanged': True}

    def sample(self, state, phase, speed=340.):
        original = self.original.sample(state, phase, speed)
        q = phase % 1.
        if state != 'mine' or q == 0. or q >= CONTACT_PHASE:
            return original
        if q < LOAD_PHASE:
            amount = pm.smooth(q / LOAD_PHASE)
            rear = self.start['rear'].lerp(self.load_rear, amount)
            rotation = pm.tool_frame(self.start['axis'], self.start['tool_normal']).to_quaternion().slerp(self.load_rotation, amount)
        else:
            amount = ((q - LOAD_PHASE) / (CONTACT_PHASE - LOAD_PHASE)) ** 2
            rear = self.load_rear.lerp(self.contact_pose['rear'], amount)
            rotation = self.load_rotation.slerp(pm.tool_frame(self.contact_pose['axis'], self.contact_pose['tool_normal']).to_quaternion(), amount)
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
