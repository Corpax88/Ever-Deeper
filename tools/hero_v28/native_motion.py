"""Native v28 motion graph pilot. No runtime mesh or sprite deformation.

Phases are normalized, durations are seconds and root distances are screen
pixels. All body/limb/tool samples remain genuine poses of the approved rig.
Transition clips are phase-indexed; a pilot bank is not a universal bridge.
"""
import math
from dataclasses import dataclass
from mathutils import Matrix, Vector
import locomotion as gait
import premium_motion as pm

SCHEMA_VERSION = 2
SIDES = ('R', 'L')
T = Matrix.Translation
UP_WORKING_PLANE_OFFSET = (-.20, .10, 0.)


def state_duration(state, speed=340., mine_duration=1.45):
    return gait.game_profile(speed).period if state == 'walk' else 3.6 if state == 'idle' else mine_duration


def sample(gear, state, phase, ground_per_pixel, speed=340., *, direction='', up_working_plane=False):
    """Shared map heading for idle, carrying run and complete-body mining."""
    if state == 'walk':
        return gait.sample_walk(gear, phase, ground_per_pixel, gait.game_profile(speed))
    p = pm.sample(gear, state, phase)
    p = pm.orient_pose(p, ground_per_pixel)
    if up_working_plane and gear == 'worn' and direction == 'up' and state == 'mine':
        # A native arm/tool working plane, not a camera or bitmap adjustment.
        # Keep the complete original lower-body pose, including sole matrices.
        delta = pm.heading_matrix(ground_per_pixel)@Vector(UP_WORKING_PLANE_OFFSET)
        solved = pm._assemble(gear, p['torso'], p['head'], p['rear']+delta,
                              p['axis'], p['tool_normal'],
                              {s:p['legs'][s][0] for s in SIDES},
                              {s:p['legs'][s][2] for s in SIDES},
                              p['bit_angle'], p['contacts'],
                              {s:p['legs'][s][1] for s in SIDES})
        p = dict(p)
        for field in ('rear', 'grips', 'hand_axes', 'radials', 'arms'):
            p[field] = solved[field]
    return p


def foot_angle(p, side, heading):
    local = heading.transposed()@p['foot_rotations'][side]
    return math.atan2(local[2][1], local[1][1])


def rolling_advance(a, b):
    if abs(a-b) < 1e-12:
        return 0.
    return gait.SoleRoll(min(a, b), max(a, b)).total*(1. if b > a else -1.)


def flat_entry_phase(ground_per_pixel, speed):
    cfg = gait.game_profile(speed)
    roll = gait.roll_for(cfg)
    d = cfg.contact_distance*Vector(ground_per_pixel).length
    u = (.48*(d-roll.total)+roll.advance(0.))/d
    assert .22 < u < .58, ('No flat native run entry', u)
    return cfg.contact*u


def canonical_coast(gear, phase, minimum_duration=.10):
    omega = math.tau*pm.ROTOR[gear]
    theta = phase*omega
    end = math.ceil((theta + omega*minimum_duration*.5)/math.tau)*math.tau
    duration = 2.*(end-theta)/omega
    return dict(theta=theta, omega=omega, end=end, duration=duration)


def _matrix_blend(a, b, w):
    rotation = a.to_quaternion().normalized().slerp(b.to_quaternion().normalized(), w).normalized()
    return T(a.translation.lerp(b.translation, w))@rotation.to_matrix().to_4x4()


@dataclass
class Transition:
    gear: str
    source_state: str
    source_phase: float
    target_state: str
    ground_per_pixel: tuple
    speed: float = 340.
    mine_duration: float = .68
    mine_hit_phase: float = .42
    body_duration: float = 0.
    direction: str = ''
    up_working_plane: bool = False

    def _state_sample(self, state, phase):
        return sample(self.gear, state, phase, self.ground, self.speed,
                      direction=self.direction, up_working_plane=self.up_working_plane)

    def __post_init__(self):
        assert self.source_state in ('idle', 'walk', 'mine')
        assert self.target_state in ('idle', 'walk', 'mine')
        assert self.source_state != self.target_state
        assert self.mine_duration > 0. and 0. < self.mine_hit_phase < 1.
        self.ground = Vector(self.ground_per_pixel)
        self.heading = pm.heading_matrix(self.ground)
        self.source_phase %= 1.
        self.target_phase = flat_entry_phase(self.ground, self.speed) if self.target_state == 'walk' else 0.
        mine_clock = 1. if self.gear in pm.ROTOR else self.mine_duration
        self.source_duration = state_duration(self.source_state, self.speed, mine_clock)
        self.target_duration = state_duration(self.target_state, self.speed, mine_clock)
        if not self.body_duration:
            if self.target_state == 'walk':
                # Complete the pose bridge in flight, before the next plant.
                self.body_duration = (.40-self.target_phase)*self.target_duration
            elif self.source_state == 'walk':
                self.body_duration = min(.12, .55/(self.speed*self.ground.length))
            else:
                self.body_duration = .12
        if self.target_state == 'mine' and self.gear not in pm.ROTOR:
            self.body_duration = min(self.body_duration, self.mine_duration*self.mine_hit_phase*.7)
        self.source = self._state_sample(self.source_state, self.source_phase)
        self.destination_offset = Vector()
        self.support_side = None
        if self.source_state == 'walk' and self.target_state != 'walk':
            self.support_side = next((s for s in SIDES if self.source['contacts'][s]), None)
            if self.support_side is not None:
                side = self.support_side
                self.support_angle = foot_angle(self.source, side, self.heading)
                eps = 1e-4
                before = self._state_sample('walk', self.source_phase-eps/self.source_duration)
                after = self._state_sample('walk', self.source_phase+eps/self.source_duration)
                self.support_angular_velocity = (foot_angle(after, side, self.heading)-foot_angle(before, side, self.heading))/(2.*eps)
                final_ankle = self.source['legs'][side][2]+self.heading@Vector((0., -rolling_advance(self.support_angle, 0.), 0.))
                target = self._state_sample(self.target_state, self.target_phase)
                self.destination_offset = final_ankle-target['legs'][side][2]
                self.destination_offset.z = 0.
        self.coast = (canonical_coast(self.gear, self.source_phase)
                      if self.gear in pm.ROTOR and self.source_state == 'mine' and self.target_state != 'mine'
                      else None)
        self.duration = max(self.body_duration, self.coast['duration'] if self.coast else 0.)

    def phase_at(self, state, initial_phase, elapsed):
        if state == 'mine' and self.gear not in pm.ROTOR:
            q = initial_phase % 1.
            progress = (q/.55*self.mine_hit_phase if q <= .55 else
                        self.mine_hit_phase+(q-.55)/.45*(1.-self.mine_hit_phase))
            progress = (progress+elapsed/self.mine_duration) % 1.
            return (progress/self.mine_hit_phase*.55 if progress <= self.mine_hit_phase else
                    .55+(progress-self.mine_hit_phase)/(1.-self.mine_hit_phase)*.45)
        duration = state_duration(state, self.speed, 1. if self.gear in pm.ROTOR else self.mine_duration)
        return (initial_phase+elapsed/duration) % 1.

    def metadata(self):
        destination_phase = self.phase_at(self.target_state, self.target_phase, self.duration)
        return dict(source_state=self.source_state, source_phase=self.source_phase,
                    target_state=self.target_state, target_start_phase=self.target_phase,
                    destination_phase=destination_phase,
                    body_duration=self.body_duration, duration=self.duration,
                    source_speed=self.speed if self.source_state == 'walk' else 0.,
                    target_speed=self.speed if self.target_state == 'walk' else 0.,
                    destination_offset_native=list(self.destination_offset),
                    retained_support=self.support_side, rotor_coast=self.coast,
                    mining_timing={'cycle_seconds':self.mine_duration, 'gameplay_hit_phase':self.mine_hit_phase,
                                   'native_hit_phase':.55, 'drill_uses_independent_one_second_rotor_clock':self.gear in pm.ROTOR},
                    incoming_offset='add_constant_screen_translation_through_clip',
                    offset_release='quintic_only_during_complete_airborne_walk_interval',
                    root_motion_authority='gameplay', interpolation='ongoing native C1 pose targets')

    def sample(self, seconds):
        t = min(self.duration, max(0., seconds))
        u = min(1., t/self.body_duration)
        w = gait.smoother(u)
        source_root = self.ground*(self.speed*t if self.source_state == 'walk' else 0.)
        target_root = self.ground*(self.speed*t if self.target_state == 'walk' else 0.)
        source = pm.translate_pose(self._state_sample(self.source_state, self.phase_at(self.source_state, self.source_phase, t)), source_root)
        target = pm.translate_pose(self._state_sample(self.target_state, self.phase_at(self.target_state, self.target_phase, t)), target_root+self.destination_offset)
        torso = _matrix_blend(source['torso'], target['torso'], w)
        head = _matrix_blend(source['head'], target['head'], w)
        tool = pm.tool_frame(source['axis'], source['tool_normal']).to_quaternion().normalized().slerp(
            pm.tool_frame(target['axis'], target['tool_normal']).to_quaternion().normalized(), w).normalized().to_matrix()
        hips, feet, angles, contacts = {}, {}, {}, {}
        for side in SIDES:
            hips[side] = source['legs'][side][0].lerp(target['legs'][side][0], w)
            a, b = foot_angle(source, side, self.heading), foot_angle(target, side, self.heading)
            angle = a+(b-a)*w
            foot = source['legs'][side][2].lerp(target['legs'][side][2], w)
            clearance = ((source['legs'][side][2].z-gait.support_height(a))*(1.-w)
                         +(target['legs'][side][2].z-gait.support_height(b))*w)
            foot.z = gait.support_height(angle)+max(0., clearance)
            contact = source['contacts'][side] if u == 0. else target['contacts'][side] if u == 1. else False
            if self.support_side == side and u < 1.:
                # Roll the real sole into a flat plant without translating its
                # ground contact. Destination root offset retains that plant.
                angle = gait.hermite(self.support_angle, self.support_angular_velocity, 0., 0., u, self.body_duration)
                foot = self.source['legs'][side][2]+self.heading@Vector((0., -rolling_advance(self.support_angle, angle), 0.))
                foot.z = gait.support_height(angle)
                contact = True
            elif self.target_state == 'walk' and side == 'R':
                # The flat entry phase has exactly the current resting ankle;
                # it remains planted, then follows its actual authored toe-off.
                foot = target['legs'][side][2].copy()
                angle = b
                contact = target['contacts'][side]
            angles[side], feet[side], contacts[side] = angle, foot, contact
        bit = source['bit_angle']+(target['bit_angle']-source['bit_angle'])*w
        omega = None
        if self.coast:
            bit, omega = gait.forward_coast(self.coast['theta'], self.coast['omega'], t, self.coast['duration'])
        elif self.gear in pm.ROTOR and self.target_state == 'mine':
            # Starting the motor is monotone too; do not blend modulo angles.
            bit = w*(self.target_phase+t/self.target_duration)*math.tau*pm.ROTOR[self.gear]
        poles = {side: source['legs'][side][1].lerp(target['legs'][side][1], w) for side in SIDES}
        p = pm._assemble(self.gear, torso, head, source['rear'].lerp(target['rear'], w),
                         tool.col[0], tool.col[2], hips, feet, bit, contacts, poles)
        p['foot_rotations'] = {side: self.heading@Matrix.Rotation(angles[side], 3, 'X') for side in SIDES}
        p = pm.translate_pose(p, -target_root)
        p['transition_metadata'] = dict(elapsed=t, target_root_pixels=self.speed*t if self.target_state == 'walk' else 0.,
                                         rotor_angle=bit, rotor_speed=omega)
        return p


def frame_metadata(p, ground_per_pixel):
    heading = pm.heading_matrix(ground_per_pixel)
    feet = {}
    for side in SIDES:
        angle = foot_angle(p, side, heading)
        vertex = min(gait.BOOT_HULL, key=lambda yz: yz[0]*math.sin(angle)+yz[1]*math.cos(angle))
        point = p['legs'][side][2]+p['foot_rotations'][side]@Vector((0., *vertex))
        feet[side] = dict(ankle=list(p['legs'][side][2]), sole_point=list(point),
                          roll=angle, contact=bool(p['contacts'][side]))
    return dict(feet=feet, rotor_angle=p['bit_angle'], heading_radians=math.atan2(Vector(ground_per_pixel).x, -Vector(ground_per_pixel).y))
