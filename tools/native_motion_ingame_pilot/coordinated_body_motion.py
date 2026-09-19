"""Study 15: settle the body at load, then turn into the existing contact.

Tool, feet, body pivot and gameplay clock remain owned by ContactRollMotion.
Only torso orientation changes; the head keeps its original relative pose.
The recorded entry reaches that orientation before the tool completes its lift.
This is a diagnostic candidate, not production or visual approval.
"""
import math

import numpy as np
from mathutils import Matrix, Vector

import premium_motion as pm
from contact_roll_motion import ContactRollMotion
from grounded_entry_transition import GroundedEntryTransition
from loop_flow_motion import CYCLE_SECONDS, exp_rotation, game_progress, hermite, log_rotation


def log_rate_bound(curve, duration):
    """Maximum norm of the cubic log-chart derivative, in radians/second.

    The differential of the SO(3) exponential has norm at most one, so this
    bounds angular speed. Evaluate endpoints and stationary squared speeds.
    """
    a, b, va, vb = [np.array(value, dtype=float) for value in curve]
    aa = 6*a - 6*b + 3*duration*(va + vb)
    bb = -6*a + 6*b - 4*duration*va - 2*duration*vb
    cc = duration*va
    roots = np.roots([2*np.dot(aa, aa), 3*np.dot(aa, bb),
                      np.dot(bb, bb) + 2*np.dot(aa, cc), np.dot(bb, cc)])
    times = [0., 1.] + [float(r.real) for r in roots
                        if abs(r.imag) < 1e-8 and 0 < r.real < 1]
    return max(float(np.linalg.norm(aa*u*u + bb*u + cc))/duration for u in times)


class CoordinatedBodyMotion(ContactRollMotion):
    def __init__(self, *args):
        super().__init__(*args)
        self.body_curves = []
        for qa, qb in ((.20, .40), (.40, .55)):
            chart = super().sample('mine', qa)['torso'].to_quaternion()
            end = super().sample('mine', qb)['torso'].to_quaternion()
            duration = (game_progress(qb) - game_progress(qa))*CYCLE_SECONDS

            def velocity(q):
                if q == .40:
                    return Vector()
                h = .0001
                before = super(CoordinatedBodyMotion, self).sample('mine', q-h)['torso'].to_quaternion()
                after = super(CoordinatedBodyMotion, self).sample('mine', q+h)['torso'].to_quaternion()
                seconds = (game_progress(q+h) - game_progress(q-h))*CYCLE_SECONDS
                return (log_rotation(chart.inverted() @ after)
                        - log_rotation(chart.inverted() @ before))/seconds

            curve = (Vector(), log_rotation(chart.inverted() @ end), velocity(qa), velocity(qb))
            self.body_curves.append((qa, qb, chart, curve, duration))

    def with_torso(self, pose, rotation):
        joint = pose['torso'] @ self.body_joint
        torso = Matrix.Translation(joint) @ rotation.to_4x4() @ Matrix.Translation(-self.body_joint)
        head = torso @ pose['torso'].inverted() @ pose['head']
        solved = pm._assemble(
            'worn', torso, head, pose['rear'], pose['axis'], pose['tool_normal'],
            {s: v[0] for s, v in pose['legs'].items()},
            {s: v[2] for s, v in pose['legs'].items()},
            pose['bit_angle'], pose['contacts'],
            {s: v[1] for s, v in pose['legs'].items()})
        result = dict(pose)
        result.update(solved)
        return result

    def sample(self, state, phase, speed=340.):
        pose = super().sample(state, phase, speed)
        q = phase % 1.
        if state != 'mine' or not .20 <= q <= .55:
            return pose
        for qa, qb, chart, curve, duration in self.body_curves:
            if qa <= q <= qb:
                u = (game_progress(q) - game_progress(qa))/(game_progress(qb) - game_progress(qa))
                rotation = (chart @ exp_rotation(hermite(*curve, u, duration))).to_matrix()
                return self.with_torso(pose, rotation)
        raise AssertionError('Missing coordinated torso segment')

    def selection(self):
        result = super().selection()
        result.update(coordinated_body_study=True, body_orientation_knots=[.20, .40, .55],
                      settled_load_phase=.40, unchanged='Tool, feet, pivot and clock; body contact pose',
                      visual_accepted=False, production_accepted=False)
        return result


class CoordinatedEntryTransition(GroundedEntryTransition):
    def __init__(self, motion, source_phase):
        super().__init__(motion, source_phase)
        # The rejected 170ms candidate peaked at 457deg/s. Derive the earliest
        # completion satisfying the measured original entry's 404deg/s bound.
        low, high = .17, self.duration
        target = math.radians(404.)
        assert log_rate_bound(self.curves['torso'], high) <= target
        for _ in range(50):
            middle = (low + high)*.5
            if log_rate_bound(self.curves['torso'], middle) > target:
                low = middle
            else:
                high = middle
        self.body_seconds = high

    def sample(self, seconds):
        t = min(self.duration, max(0., seconds))
        pose = super().sample(t)
        u = min(1., t/self.body_seconds)
        rotation = (self.charts['torso'] @ exp_rotation(
            hermite(*self.curves['torso'], u, self.body_seconds))).to_matrix()
        return self.motion.with_torso(pose, rotation)

    def metadata(self):
        result = super().metadata()
        result.update(coordinated_body_study=True, torso_completion_seconds=self.body_seconds,
                      torso_log_rate_bound_degrees=404.,
                      entry_study='Body leads unchanged tool lift; settled load before contact turn')
        return result
