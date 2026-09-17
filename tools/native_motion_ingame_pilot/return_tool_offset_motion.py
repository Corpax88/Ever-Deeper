"""Study-only Worn/up state resolver for the frozen hinge and return motion.

Canonical mining and both sides of a transition use the same native pose.
The original transition owns its blending, clock, sole contact and root math.
This does not provide arbitrary input, other targets/views, or runtime coverage.
"""
from mathutils import Matrix, Vector
import native_motion as native
import upper_body_hinge_pose
import return_tool_offset_pose


class FrozenReturnMotion:
    def __init__(self, surface, hinge, pivot_report):
        self.ground = Vector(surface['unchanged_ground'])
        self.target = Vector(surface['target_ground'])
        self.contact = surface['contact']
        self.local_cap = Vector(surface['working_surface']['surface_center_tool_local'])
        self.body_joint = Vector(hinge['body_joint_local'])
        assert hinge['side_lean_degrees'] == 10 and hinge['local_twist_degrees'] == -12
        selected = [p for p in pivot_report['cases']
                    if p['yaw_about_world_z_degrees'] == 15 and p['contact_pitch_degrees'] == 45]
        assert len(selected) == 1 and selected[0]['passed']
        self.tool_rotation = Matrix(selected[0]['rigid_rotation'])

    def sample(self, state, phase, speed=340.):
        if state != 'mine':
            return native.sample('worn', state, phase, self.ground, speed, direction='up')
        hinged, _, _, _, _ = upper_body_hinge_pose.sample(
            phase, self.ground, self.target, self.contact, self.local_cap,
            self.tool_rotation, self.body_joint, 10, -12)
        posed, _ = return_tool_offset_pose.sample(hinged, phase, self.target)
        return posed

    def transition(self, source_state, source_phase, target_state):
        return ReturnTransition(self, source_state, source_phase, target_state)


class ReturnTransition(native.Transition):
    def __init__(self, motion, source_state, source_phase, target_state):
        self.motion = motion
        super().__init__('worn', source_state, source_phase, target_state,
                         tuple(motion.ground), speed=340., mine_duration=.68,
                         mine_hit_phase=.42, direction='up')

    def _state_sample(self, state, phase):
        return self.motion.sample(state, phase, self.speed)
