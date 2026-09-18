"""Study-only visible side return with one anatomical torso turn.

One projected side waypoint is fitted within the original arms' reach. The
torso turns at its real body joint, while hips, feet and contact stay fixed.
No accepted animation or bank is implied by this authored proposal.
"""
import math
from mathutils import Matrix,Vector
import premium_motion as pm
from complete_return_motion import smoother
from loop_flow_motion import LoopFlowMotion,game_progress,hermite,log_rotation,exp_rotation,CYCLE_SECONDS


class SideReturnMotion(LoopFlowMotion):
    def __init__(self,surface,hinge,pivot_report,overhead_load=False):
        super().__init__(surface,hinge,pivot_report,.70,.30,not overhead_load)
        self.overhead_load=overhead_load
        # Native200 target [142,108], beyond the observed wrap silhouette.
        # Depth minimizes the greater wrist distance to the turned shoulders.
        self.side_midpoint=Vector((-.4748423993587494,.2857058644294739,.7973606586456299))
        self.side_axis=Vector((-.2505798637866974,.6612183451652527,.7071067690849304))
        self.side_normal=Vector((-.9620493650436401,-.2515866756439209,-.10566496849060059))
        self.side_rear=self.side_midpoint-self.side_axis*.0725
        self.side_rotation=pm.tool_frame(self.side_axis,self.side_normal).to_quaternion()
        self.side_log=log_rotation(self.chart.inverted()@self.side_rotation)
        self.side_rear_rate=Vector((0.,0.,1.))
        self.side_log_rate=(self.round_logs[1]-self.round_logs[0])/self.round_duration
        self.side_time=(1.-self.round_start_progress)*CYCLE_SECONDS

    def waypoint_pose(self):
        original=self.original.sample('mine',0.)
        original=self._turn(original,1.)
        return self._with_tool(original,self.side_rear,self.side_rotation)

    def _turn(self,pose,amount):
        out=dict(pose)
        joint=self.body_joint
        out['torso']=(pose['torso']@Matrix.Translation(joint)
                      @Matrix.Rotation(math.radians(-40)*amount,4,'Z')@Matrix.Translation(-joint))
        out['head']=(out['torso']@pose['torso'].inverted())@pose['head']
        return out

    def sample(self,state,phase,speed=340.):
        q=phase%1.
        if state!='mine' or self.round_end<=q<=self.round_start:
            return super().sample(state,phase,speed)
        elapsed=((game_progress(q)-self.round_start_progress)%1.)*CYCLE_SECONDS
        if elapsed<=self.side_time:
            duration=self.side_time;u=elapsed/duration
            rears=(self.round_rears[0],self.side_rear)
            rates=(self.round_rear_rates[0],self.side_rear_rate)
            logs=(self.round_logs[0],self.side_log)
            angular=(self.round_log_rates[0],self.side_log_rate)
            turn=smoother(u)
        else:
            duration=self.round_duration-self.side_time;u=(elapsed-self.side_time)/duration
            rears=(self.side_rear,self.round_rears[1])
            rates=(self.side_rear_rate,self.round_rear_rates[1])
            logs=(self.side_log,self.round_logs[1])
            angular=(self.side_log_rate,self.round_log_rates[1])
            turn=1.-smoother(u)
        rear=hermite(*rears,*rates,u,duration)
        rotation=self.chart@exp_rotation(hermite(*logs,*angular,u,duration))
        original=self._turn(self.original.sample(state,phase,speed),turn)
        return self._with_tool(original,rear,rotation)

    def selection(self):
        out=super().selection()
        out.update(proposal='one-visible-side-return',overhead_load=self.overhead_load,side_midpoint=list(self.side_midpoint),
                   side_axis=list(self.side_axis),side_normal=list(self.side_normal),
                   side_rear_velocity=list(self.side_rear_rate),
                   body_turn_degrees=-40,body_turn_joint=list(self.body_joint),
                   body_changed_ranges='(.70,1) and [0,.30)',
                   protected='Original hips, legs, feet, clock and .55-.70 contact/early recovery',
                   visual_accepted=False,production_accepted=False)
        return out
