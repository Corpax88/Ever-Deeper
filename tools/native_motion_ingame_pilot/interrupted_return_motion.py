"""One authored restart from the actually presented 50 ms stop-bridge cell.

The old native stop keeps moving as the source of the new blend. Its idle
clock continues after its own endpoint. The target follows the new mining
clock immediately; this module neither delays input nor edits gameplay.
"""
import premium_motion as pm
from return_tool_offset_motion import ReturnTransition


class InterruptedReturnTransition(ReturnTransition):
    def __init__(self, motion, source_clip, source_name, source_phase):
        assert source_clip.source_state == 'mine' and source_clip.target_state == 'idle'
        assert source_name == 'mine_to_idle-392857'
        assert abs(source_clip.source_phase - .392857142857143) < 1e-12
        assert abs(source_phase * source_clip.duration - .05) < 1e-12
        self.previous = source_clip
        self.previous_name = source_name
        self.presented_source_phase = source_phase
        self.previous_elapsed = source_phase * source_clip.duration
        # Virtual idle supplies an elapsed-time parameter to the unchanged
        # native blend. It is never substituted for the presented source pose.
        super().__init__(motion, 'idle', 0., 'mine')

    def continued_source(self, elapsed):
        old_elapsed = self.previous_elapsed + elapsed
        if old_elapsed <= self.previous.duration:
            return self.previous.sample(old_elapsed)
        phase = self.previous.phase_at('idle', self.previous.target_phase, old_elapsed)
        return pm.translate_pose(self.motion.sample('idle', phase),
                                 self.previous.destination_offset)

    def _state_sample(self, state, phase):
        if state == 'idle':
            return self.continued_source(phase * 3.6)
        return self.motion.sample(state, phase, self.speed)

    def metadata(self):
        info = super().metadata()
        info.update(source_state=self.previous_name,
                    source_phase=self.presented_source_phase,
                    source_logical_state='idle', source_is_bridge=True,
                    source_elapsed=self.previous_elapsed,
                    source_bridge_duration=self.previous.duration,
                    source_continuation='old bridge then its advancing canonical idle',
                    source_endpoint_after=self.previous.duration - self.previous_elapsed)
        return info
