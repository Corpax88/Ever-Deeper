"""One grounded loading/compression experiment; original tool path is fixed."""
import math
from mathutils import Matrix,Vector
import premium_motion as pm
from side_return_motion import SideReturnMotion
from complete_return_motion import smoother

KEYS=((.20,0.,0.),
      (.38,.020,0.),
      (.55,-.030,8.),
      (.59,-.045,12.),
      (.68,-.020,4.),
      (.86,0.,0.))
WEIGHT_SHIFT_KEYS=((.20,0.,0.),(.38,.020,0.),(.55,-.030,.035),
                   (.59,-.045,.045),(.68,-.020,.025),(.86,0.,0.))


class BodyWeightMotion(SideReturnMotion):
    def __init__(self,surface,hinge,pivot_report,contact_turn=False,weight_shift=False):
        super().__init__(surface,hinge,pivot_report,True)
        assert not weight_shift or contact_turn
        self.contact_turn=contact_turn
        self.weight_shift=weight_shift
        rest=self.original.sample('mine',0.)
        self.stance_right=(rest['legs']['R'][2]-rest['legs']['L'][2]).normalized()

    @staticmethod
    def power_turn(q):
        keys=((0.,-40.),(.30,0.),(.55,-30.),(.70,-35.),(1.,-40.))
        for a,b in zip(keys,keys[1:]):
            if a[0]<=q<=b[0]:return a[1]+(b[1]-a[1])*smoother((q-a[0])/(b[0]-a[0]))

    def sample(self,state,phase,speed=340.):
        original=super().sample(state,phase,speed)
        q=phase%1.
        if state!='mine':return original
        if not self.contact_turn and (q<=KEYS[0][0] or q>=KEYS[-1][0]):return original
        dz=lean=lateral=0.
        keys=WEIGHT_SHIFT_KEYS if self.weight_shift else KEYS
        for a,b in zip(keys,keys[1:]):
            if a[0]<=q<=b[0]:
                t=pm.smooth((q-a[0])/(b[0]-a[0]))
                dz,second=[v+(w-v)*t for v,w in zip(a[1:],b[1:])]
                if self.weight_shift:lateral=second
                else:lean=second
                break
        shift=Vector((0.,0.,dz))+self.stance_right*lateral
        joint=self.body_joint
        twist=Matrix.Rotation(math.radians(self.power_turn(q)),4,'Z') if self.contact_turn else Matrix.Identity(4)
        body_source=self.original.sample(state,phase,speed) if self.contact_turn else original
        bend=(Matrix.Translation(joint)@twist@Matrix.Rotation(math.radians(lean),4,'X')
              @Matrix.Translation(-joint))
        torso=Matrix.Translation(shift)@body_source['torso']@bend
        head=(torso@body_source['torso'].inverted())@body_source['head']
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
        if self.contact_turn:
            out.update(proposal='one-powered-contact-turn',contact_turn=True,
                       turn_keys=[[0.,-40.],[.30,0.],[.55,-30.],[.70,-35.],[1.,-40.]],
                       body_changed_ranges='Whole mining cycle; original40-degree side-carry knot retained')
        if self.weight_shift:
            out.update(proposal='one-fixed-stance-weight-transfer',weight_shift=True,
                       body_weight_keys=WEIGHT_SHIFT_KEYS,
                       body_weight_columns=['native_phase','vertical_shift','shift_toward_original_right_sole'],
                       stance_right=list(self.stance_right),extra_forward_lean_degrees=0.,
                       hypothesis='Readable pelvis/knee compression without moving either sole or the tool')
        return out
