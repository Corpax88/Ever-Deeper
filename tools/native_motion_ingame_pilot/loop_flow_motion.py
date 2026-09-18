"""One bounded tool-path rounding trial; no production adoption.

Replace only the rest corner of CompleteReturnMotion. Boundary tangents use
seconds on the unchanged game clock and a single quaternion-log chart. The
original pose owns torso, head, legs and contacts; both hands solve on one tool.
"""
import math
from mathutils import Quaternion, Vector
import premium_motion as pm
from complete_return_motion import CompleteReturnMotion

CYCLE_SECONDS = .68
HIT_PROGRESS = .42
CONTACT_PHASE = .55
ROUND_START = .85
ROUND_END = .15


def game_progress(phase):
    if phase <= CONTACT_PHASE:
        return phase / CONTACT_PHASE * HIT_PROGRESS
    return HIT_PROGRESS + (phase - CONTACT_PHASE) / (1. - CONTACT_PHASE) * (1. - HIT_PROGRESS)


def native_phase(progress):
    if progress <= HIT_PROGRESS:
        return progress / HIT_PROGRESS * CONTACT_PHASE
    return CONTACT_PHASE + (progress - HIT_PROGRESS) / (1. - HIT_PROGRESS) * (1. - CONTACT_PHASE)


def log_rotation(rotation):
    q = rotation.normalized()
    if q.w < 0.:
        q = -q
    v = Vector((q.x, q.y, q.z))
    n = v.length
    return v * (2. * math.atan2(n, q.w) / n) if n > 1e-12 else v * 2.


def exp_rotation(value):
    angle = value.length
    return Quaternion(value / angle, angle) if angle > 1e-12 else Quaternion()


def hermite(a, b, va, vb, u, duration):
    return ((2.*u**3-3.*u**2+1.)*a + (u**3-2.*u**2+u)*duration*va
            + (-2.*u**3+3.*u**2)*b + (u**3-u**2)*duration*vb)


class LoopFlowMotion(CompleteReturnMotion):
    def __init__(self, surface, hinge, pivot_report):
        super().__init__(surface, hinge, pivot_report)
        self.round_start_progress = game_progress(ROUND_START)
        self.round_end_progress = game_progress(ROUND_END)
        self.round_duration = (1. - self.round_start_progress + self.round_end_progress) * CYCLE_SECONDS
        self.chart = self.rest_rotation.copy()
        self.round_rears, self.round_logs = [], []
        self.round_rear_rates, self.round_log_rates = [], []
        h = .0001
        for phase in (ROUND_START, ROUND_END):
            progress = game_progress(phase)
            values = [self._chart_sample(native_phase(progress + seconds/CYCLE_SECONDS))
                      for seconds in (-h, 0., h)]
            self.round_rears.append(values[1][0])
            self.round_logs.append(values[1][1])
            self.round_rear_rates.append((values[2][0]-values[0][0])/(2.*h))
            self.round_log_rates.append((values[2][1]-values[0][1])/(2.*h))

    def _chart_sample(self, phase):
        pose = super().sample('mine', phase)
        rotation = pm.tool_frame(pose['axis'], pose['tool_normal']).to_quaternion()
        return pose['rear'], log_rotation(self.chart.inverted() @ rotation)

    def sample(self, state, phase, speed=340.):
        original = super().sample(state, phase, speed)
        q = phase % 1.
        if state != 'mine' or ROUND_END <= q <= ROUND_START:
            return original
        elapsed = ((game_progress(q) - self.round_start_progress) % 1.) * CYCLE_SECONDS
        u = max(0., min(1., elapsed/self.round_duration))
        rear = hermite(*self.round_rears, *self.round_rear_rates, u, self.round_duration)
        rotation_log = hermite(*self.round_logs, *self.round_log_rates, u, self.round_duration)
        rotation = self.chart @ exp_rotation(rotation_log)
        return self._with_tool(original, rear, rotation)

    def selection(self):
        out = super().selection()
        out.update(proposal='one-local-rest-corner-rounding', round_native_phases=[ROUND_START, ROUND_END],
                   round_duration_seconds=self.round_duration,
                   round_rule='Cubic Hermite in game seconds; fixed quaternion-log chart',
                   rest_rule='Loop bypasses exact idle rest; entry and stop bridges require fresh checks',
                   changed_ranges='(.85,1) and [0,.15)', unchanged_range='[.15,.85]',
                   visual_accepted=False, production_accepted=False)
        return out
