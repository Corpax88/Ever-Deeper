"""Bounded timing correction: preserve18B poses/contact, remove long holds."""
from simple_swing import SimpleSwing


class FlowSwing(SimpleSwing):
    def __init__(self, anchors):
        super().__init__(anchors)
        # Keep one short compression after contact, then continue withdrawal.
        self.keys[4] = (.445, *self.keys[4][1:])
        # Reach ready at the cycle boundary; do not hold it for82ms each time.
        self.keys[6] = (1.0, *self.keys[6][1:])
        self.keys = self.keys[:7]
        self.rotations = self.rotations[:7]
        self.bodies = self.bodies[:7]

    def selection(self):
        result=super().selection()
        result.update(proposal='continuous-return20',contact_hold_seconds=.025*.68,
                      ready_hold_seconds=0.,ready_progress=1.0)
        return result
