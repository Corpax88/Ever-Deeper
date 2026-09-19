"""One lower strike on the same ore face; retain original09 tool orientation."""
from mathutils import Vector
import premium_motion as pm
from body_weight_motion import BodyWeightMotion
from complete_return_motion import smoother

class LowerContactMotion(BodyWeightMotion):
    def __init__(self,*args):
        super().__init__(*args,contact_turn=True)

    @staticmethod
    def contact_offset(q):
        q%=1.
        if q<=.40 or q>=.86:return Vector((0.,0.,0.))
        if q<.55:w=smoother((q-.40)/.15)
        elif q<=.625:w=1.
        else:w=1.-smoother((q-.625)/.235)
        return Vector((0.,0.,-.30*w))

    def sample(self,state,phase,speed=340.):
        original=super().sample(state,phase,speed)
        if state!='mine':return original
        shift=self.contact_offset(phase)
        if shift.length_squared==0:return original
        rotation=pm.tool_frame(original['axis'],original['tool_normal']).to_quaternion()
        return self._with_tool(original,original['rear']+shift,rotation)

    def selection(self):
        r=super().selection()
        r.update(proposal='one-lower-working-point',contact_translation=[0,0,-.30],
                 weight_knots=[[.40,0],[.55,1],[.625,1],[.86,0]],
                 rationale='Lower both grips away from face while the translated working patch still overlaps the existing ore face',
                 recovery='Spread offset release to.86; avoid returning.30native units in the short.625-.70 interval',
                 protected='Exact09 torso/head/feet, rigid tool orientation, clock, entry endpoint and cycle seam',
                 changed='Contact target and tool/grip translation over.40-.86; later bridges require new validation',
                 limits='Native still study only; alpha overlap is not physical3D contact or toolhead readability',
                 visual_accepted=False,production_accepted=False)
        return r
