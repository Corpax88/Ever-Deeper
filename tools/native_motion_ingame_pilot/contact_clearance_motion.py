"""One contact-local, cap-fixed lateral-clearance study on the exact09 body."""
import math
from mathutils import Quaternion,Vector
import premium_motion as pm
from body_weight_motion import BodyWeightMotion
from complete_return_motion import smoother

AXIS=(0.4038478136062622,0.07409423589706421,0.9118207693099976)
ANGLE_DEGREES=5.494004596863262

class ContactClearanceMotion(BodyWeightMotion):
    def __init__(self,*args):
        super().__init__(*args,contact_turn=True)

    @staticmethod
    def contact_weight(q):
        if q<=.40 or q>=.70:return 0.
        if q<.55:return smoother((q-.40)/.15)
        if q<=.625:return 1.
        return 1.-smoother((q-.625)/.075)

    def sample(self,state,phase,speed=340.):
        original=super().sample(state,phase,speed)
        if state!='mine':return original
        weight=self.contact_weight(phase%1.)
        if not weight:return original
        frame=pm.tool_frame(original['axis'],original['tool_normal'])
        cap=original['rear']+frame@self.local_cap
        delta=Quaternion(Vector(AXIS).normalized(),math.radians(ANGLE_DEGREES)*weight).to_matrix()
        changed=delta@frame
        return self._with_tool(original,cap-changed@self.local_cap,changed.to_quaternion())

    def selection(self):
        r=super().selection()
        r.update(proposal='one-contact-local-lateral-clearance',axis_world=AXIS,
                 angle_degrees=ANGLE_DEGREES,weight_knots=[[.40,0],[.55,1],[.625,1],[.70,0]],
                 derivation='Minimum-norm angular Jacobian for3px rightward grip-midpoint motion at160px',
                 protected='Exact09 torso/head/feet, working-cap centroid path, clock, first-entry endpoint and cycle seam',
                 limits='Changes contact-region arms and tool orientation; cap centroid alone does not prove full-surface contact',
                 visual_accepted=False,production_accepted=False)
        return r
