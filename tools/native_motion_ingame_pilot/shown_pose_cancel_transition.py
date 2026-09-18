"""One C0 cancellation study from the actually shown late-windup cell.

The cancelled mining source does not continue toward its old impact. The
complete shown pose is held as the source while the original idle clock and
120 ms blend advance. This intentionally interrupts incoming source velocity;
it is neither a C1 bridge nor a general policy for other phases or input.
"""
from return_tool_offset_motion import ReturnTransition


class ShownPoseCancelTransition(ReturnTransition):
    def __init__(self, motion, source_phase):
        assert abs(source_phase - .5238095238095238) < 1e-12
        self.shown_source = motion.sample('mine', source_phase)
        super().__init__(motion, 'mine', source_phase, 'idle')

    def _state_sample(self, state, phase):
        if state == 'mine':
            return self.shown_source
        return super()._state_sample(state, phase)

    def phase_at(self, state, initial_phase, elapsed):
        if state == 'mine':
            return initial_phase
        return super().phase_at(state, initial_phase, elapsed)

    def metadata(self):
        info = super().metadata()
        info.update(source_continuation='complete displayed pose held; cancelled mine clock stopped',
                    interpolation='quintic blend from held source to advancing idle; C0 at release',
                    incoming_source_velocity_continuous=False,
                    scope='only the observed .5238095238095238 mine-to-idle cancellation')
        return info
