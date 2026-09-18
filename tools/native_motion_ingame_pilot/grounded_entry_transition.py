"""One study entry: quick native foot stop, longer direct first wind-up.

Only the recorded walk.625 -> Worn/up mining entry is supported. The normal
loop keeps its side return. This bridge bypasses that return on the first
swing, and reaches the unchanged07 load at the original gameplay time.
"""
from mathutils import Matrix,Vector
import premium_motion as pm
from return_tool_offset_motion import ReturnTransition
from loop_flow_motion import CYCLE_SECONDS,game_progress,hermite,log_rotation,exp_rotation


class GroundedEntryTransition:
    def __init__(self,motion,source_phase):
        assert abs(source_phase-.625)<1e-8, 'Only the recorded walk.625 entry is studied'
        self.motion=motion
        self.lower=ReturnTransition(motion,'walk',source_phase,'mine')
        self.source=self.lower.source
        self.load_phase=.40
        self.duration=game_progress(self.load_phase)*CYCLE_SECONDS
        self.body_duration=self.duration
        self.joint=motion.body_joint.copy()
        self.head_joint=Vector((0.,0.,1.135))
        self.destination=pm.translate_pose(motion.sample('mine',self.load_phase),self.lower.destination_offset)
        self.start=self._relative(self.source)
        self.end=self._relative(self.destination)
        self.charts={name:self.start[name].copy() for name in ('torso','head_relative','tool')}
        h=.0001
        start_pair=[self._relative(motion.sample('walk',source_phase+t/self.lower.source_duration)) for t in (-h,h)]
        end_pair=[self._relative(self._canonical(self.duration+t)) for t in (-h,h)]
        self.curves={}
        for name in ('rear_relative','torso','head_relative','tool'):
            def value(p):
                return p[name] if name=='rear_relative' else log_rotation(self.charts[name].inverted()@p[name])
            self.curves[name]=(value(self.start),value(self.end),
                               (value(start_pair[1])-value(start_pair[0]))/(2*h),
                               (value(end_pair[1])-value(end_pair[0]))/(2*h))

    def __getattr__(self,name):
        return getattr(self.lower,name)

    def _canonical(self,t):
        q=self.lower.phase_at('mine',self.lower.target_phase,t)
        return pm.translate_pose(self.motion.sample('mine',q),self.lower.destination_offset)

    def lower_pose(self,t):
        return self.lower.sample(t) if t<=self.lower.duration else self._canonical(t)

    def _relative(self,p):
        joint=p['torso']@self.joint
        relative=p['torso'].inverted()@p['head']
        assert (relative@self.head_joint-self.head_joint).length<2e-6, 'Head pivot changed'
        return dict(rear_relative=p['rear']-joint,torso=p['torso'].to_quaternion().normalized(),
                    head_relative=relative.to_quaternion().normalized(),
                    tool=pm.tool_frame(p['axis'],p['tool_normal']).to_quaternion().normalized())

    def sample(self,seconds):
        t=min(self.duration,max(0.,seconds))
        u=t/self.duration
        lower=self.lower_pose(t)
        joint=lower['torso']@self.joint
        values={name:hermite(*curve,u,self.duration) for name,curve in self.curves.items()}
        rotations={name:(self.charts[name]@exp_rotation(values[name])).to_matrix()
                   for name in self.charts}
        torso=(Matrix.Translation(joint)@rotations['torso'].to_4x4()@Matrix.Translation(-self.joint))
        head=(torso@Matrix.Translation(self.head_joint)@rotations['head_relative'].to_4x4()
              @Matrix.Translation(-self.head_joint))
        tool=rotations['tool']
        solved=pm._assemble('worn',torso,head,joint+values['rear_relative'],tool.col[0],tool.col[2],
                            {s:v[0] for s,v in lower['legs'].items()},
                            {s:v[2] for s,v in lower['legs'].items()},
                            lower['bit_angle'],lower['contacts'],
                            {s:v[1] for s,v in lower['legs'].items()})
        out=dict(lower)
        out.update(solved)
        return out

    def metadata(self):
        out=self.lower.metadata()
        out.update(duration=self.duration,body_duration=self.duration,destination_phase=self.load_phase,
                   lower_body_duration=self.lower.duration,
                   entry_study='Direct first wind-up; original quick lower-body stop, torso pivot anchored to lower pose',
                   upper_curve='Hermite in seconds, fixed quaternion-log charts, original endpoint velocities',
                   gameplay_contact_seconds=.42*CYCLE_SECONDS,visual_accepted=False,production_accepted=False)
        return out
