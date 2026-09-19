"""Trial12: expose the head at impact, unwind roll during early recovery."""
import math
from mathutils import Quaternion
import premium_motion as pm
from lower_contact_motion import LowerContactMotion
from complete_return_motion import smoother

ANGLE_DEGREES = 32.604042

class ContactRollMotion(LowerContactMotion):
    @staticmethod
    def roll_weight(q):
        q %= 1.
        if q <= .40 or q >= .70: return 0.
        if q < .55: return smoother((q-.40)/.15)
        return 1.-smoother((q-.55)/.15)

    def sample(self,state,phase,speed=340.):
        original=super().sample(state,phase,speed)
        if state!='mine': return original
        weight=self.roll_weight(phase)
        if not weight: return original
        frame=pm.tool_frame(original['axis'],original['tool_normal'])
        cap=original['rear']+frame@self.local_cap
        changed=Quaternion(original['axis'],math.radians(ANGLE_DEGREES)*weight).to_matrix()@frame
        return self._with_tool(original,cap-changed@self.local_cap,changed.to_quaternion())

    def selection(self):
        r=super().selection()
        r.update(proposal='lower-contact-with-early-unwinding-axial-roll',
                 roll_degrees=ANGLE_DEGREES,roll_weight_knots=[[.40,0],[.55,1],[.70,0]],
                 derivation='Positive axial branch exposes12.639px transverse head at impact and preserves hand clearance',
                 recovery='Independent early roll release avoids arm overextension of the.625-.86 hold/release proposal',
                 protected='Exact09 body/feet,11 cap path, tool shaft direction, clock and cycle seam',
                 limits='Impact normal/incoming cosine.4812 versus.8132 before roll; broader head is temporary. Still study only',
                 visual_accepted=False,production_accepted=False)
        return r
