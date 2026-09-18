"""One grounded loading/compression experiment; original tool path is fixed."""
import math
from mathutils import Matrix,Vector
import premium_motion as pm
from side_return_motion import SideReturnMotion

KEYS=((.20,0.,0.),
      (.38,.020,0.),
      (.55,-.030,8.),
      (.59,-.045,12.),
      (.68,-.020,4.),
      (.86,0.,0.))


class BodyWeightMotion(SideReturnMotion):
    def __init__(self,surface,hinge,pivot_report):
        super().__init__(surface,hinge,pivot_report,True)

    def sample(self,state,phase,speed=340.):
        original=super().sample(state,phase,speed)
        q=phase%1.
        if state!='mine' or q<=KEYS[0][0] or q>=KEYS[-1][0]:return original
        for a,b in zip(KEYS,KEYS[1:]):
            if a[0]<=q<=b[0]:
                t=pm.smooth((q-a[0])/(b[0]-a[0]))
                dz,lean=[v+(w-v)*t for v,w in zip(a[1:],b[1:])]
                break
        shift=Vector((0.,0.,dz))
        joint=self.body_joint
        bend=(Matrix.Translation(joint)@Matrix.Rotation(math.radians(lean),4,'X')
              @Matrix.Translation(-joint))
        torso=Matrix.Translation(shift)@original['torso']@bend
        head=(torso@original['torso'].inverted())@original['head']
        solved=pm._assemble('worn',torso,head,original['rear'],original['axis'],original['tool_normal'],
                            {s:v[0]+shift for s,v in original['legs'].items()},
                            {s:v[2] for s,v in original['legs'].items()},
                            original['bit_angle'],original['contacts'],
                            {s:v[1]+shift for s,v in original['legs'].items()})
        result=dict(original)
        result.update(solved)
        return result

    def selection(self):
        out=super().selection()
        out.update(proposal='one-grounded-body-weight-trial',body_weight_keys=KEYS,
                   body_weight_columns=['native_phase','vertical_shift','local_forward_lean_degrees'],
                   protected='Original05 rigid tool/grips/clock, fixed world soles, same limb lengths',
                   body_changed_ranges='Return turn plus coordinated loading/compression .20-.86',
                   visual_accepted=False,production_accepted=False)
        return out
