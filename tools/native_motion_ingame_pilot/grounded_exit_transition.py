"""Study-only220ms upper-body recovery above the original fast walking legs."""
from mathutils import Matrix,Vector
import premium_motion as pm
from grounded_entry_transition import GroundedEntryTransition
from return_tool_offset_motion import ReturnTransition
from loop_flow_motion import hermite,log_rotation,exp_rotation


class GroundedExitTransition(GroundedEntryTransition):
    def __init__(self,motion,source_phase=.625):
        assert abs(source_phase-.625)<1e-8, 'Only the recorded mine.625 exit is studied'
        self.motion=motion
        self.lower=ReturnTransition(motion,'mine',source_phase,'walk')
        self.source=self.lower.source
        self.duration=.22
        self.body_duration=self.duration
        self.joint=motion.body_joint.copy()
        self.head_joint=Vector((0.,0.,1.135))
        self.destination=self._canonical(self.duration)
        self.start=self._relative(self.source)
        self.end=self._relative(self.destination)
        self.charts={n:self.start[n].copy() for n in ('torso','head_relative','tool')}
        h=.0005
        first=[self._relative(motion.sample('mine',self.lower.phase_at('mine',source_phase,t))) for t in (-h,h)]
        last=[self._relative(self._canonical(self.duration+t)) for t in (-h,h)]
        self.curves={}
        for name in ('rear_relative','torso','head_relative','tool'):
            def value(p):
                return p[name] if name=='rear_relative' else log_rotation(self.charts[name].inverted()@p[name])
            self.curves[name]=(value(self.start),value(self.end),
                               (value(first[1])-value(first[0]))/(2*h),
                               (value(last[1])-value(last[0]))/(2*h))

    def _canonical(self,t):
        phase=self.lower.phase_at('walk',self.lower.target_phase,t)
        # native.Transition.sample already removes gameplay target_root.
        # Sprite-local poses must not add movement a second time.
        return pm.translate_pose(self.motion.sample('walk',phase),self.lower.destination_offset)

    def sample(self,seconds,lower_override=None):
        t=min(self.duration,max(0.,seconds));u=t/self.duration
        # A packed bridge may retain the original bank's displayed lower pose.
        # Continuous analysis uses the exact original lower-body path instead.
        lower=self.lower_pose(t) if lower_override is None else lower_override
        joint=lower['torso']@self.joint
        values={name:hermite(*curve,u,self.duration) for name,curve in self.curves.items()}
        rotations={name:(self.charts[name]@exp_rotation(values[name])).to_matrix() for name in self.charts}
        torso=Matrix.Translation(joint)@rotations['torso'].to_4x4()@Matrix.Translation(-self.joint)
        head=torso@Matrix.Translation(self.head_joint)@rotations['head_relative'].to_4x4()@Matrix.Translation(-self.head_joint)
        tool=rotations['tool']
        solved=pm._assemble('worn',torso,head,joint+values['rear_relative'],tool.col[0],tool.col[2],
                            {s:v[0] for s,v in lower['legs'].items()},
                            {s:v[2] for s,v in lower['legs'].items()},
                            lower['bit_angle'],lower['contacts'],
                            {s:v[1] for s,v in lower['legs'].items()})
        out=dict(lower);out.update(solved)
        return out

    def metadata(self):
        out=self.lower.metadata()
        out.update(duration=self.duration,body_duration=self.duration,
                   destination_phase=self.lower.phase_at('walk',self.lower.target_phase,self.duration),
                   lower_body_duration=self.lower.duration,upper_exit_study=True,
                   upper_curve='Joint-relative Hermite with source/canonical endpoint rates',
                   lower_clock='Original fast walking bridge and canonical walk; original offset-release clock',
                   root_motion_authority='gameplay',visual_accepted=False,production_accepted=False)
        return out

    def quantized_lower_pose(self,t,reference):
        """Retain the exact lower cell that the existing consumer would show."""
        if t<self.lower.duration:
            state='mine_to_walk-625000';q=t/self.lower.duration
            phases=reference['states'][state]['phases']
            index=min(range(len(phases)),key=lambda i:abs(phases[i]-q))
            pose=self.lower.sample(phases[index]*self.lower.duration)
        else:
            state='walk';q=self.lower.phase_at('walk',self.lower.target_phase,t)
            phases=reference['states'][state]['phases']
            distance=lambda x:min(abs(x-q),1.-abs(x-q))
            index=min(range(len(phases)),key=lambda i:distance(phases[i]))
            pose=pm.translate_pose(self.motion.sample('walk',phases[index]),self.lower.destination_offset)
        return pose,state,index
