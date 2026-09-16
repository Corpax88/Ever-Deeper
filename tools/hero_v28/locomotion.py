"""Isolated native gait trial, never a production override.

Load in Blender after tools/hero_v28 is on sys.path.  Call
sample_walk(gear, phase, ground_per_pixel, profile='run').  Apply the
returned world-space foot_rotations in native_pose (see FOOT_MATRIX_NOTE).
The original mesh, bone lengths, camera, and sprite scale are untouched.
This is a continuous locomotion trial, not a completed transition graph.
"""
import math
from dataclasses import dataclass
from functools import lru_cache

GROUND = .012
ANKLE_BIND_Z = .14
HIP_BIND_Z = .466042
LEG_LENGTH = .180 + .184

# Convex hull of the approved v28 right boot's raw visible vertices in
# sagittal (native y, native z - bind ankle z). The left boot is mirrored in x.
BOOT_HULL = (
    (-.3179999887943268, -.12000000044703485),
    (-.30851998925209045, -.12799999989569188),
    (.1465200036764145, -.12799999989569188),
    (.15600000321865082, -.12000000044703485),
    (.15600000321865082, -.07299999833106996),
    (.14664000272750854, .029880166649818407),
    (-.13596472144126892, .19369332551956175),
    (-.13647788763046265, .19392298221588133),
    (-.13699999451637268, .19399999141693114),
    (-.13752210140228271, .19392298221588133),
    (-.13803526759147644, .19369332551956175),
    (-.14769989252090454, .18793959975242613),
    (-.29882344603538513, .02265994310379027),
    (-.3071286082267761, .009077549576759325),
    (-.3099198639392853, -.005199998021125807),
    (-.3179999887943268, -.07299999833106996),
)

GROUND_PER_PIXEL = {
    'down': (.009506835602223873, -.03505644574761391, 0.),
    'left': (-.0026886712294071913, -.0179244764149189, 0.),
    'up': (-.02208799682557583, -.022456128150224686, 0.),
    'right': (.002688670763745904, -.01792447455227375, 0.),
}

FOOT_MATRIX_NOTE = '''
For each side, before convert_local_to_pose:
    n = 'foot.' + side
    target[n] = p['foot_rotations'][side].to_4x4() @ mats[n]
    target[n].translation = p['legs'][side][2]
This equals T(new_ankle) @ R_world @ T(-bind_ankle) @ rest_bone_matrix.
R_world is applied on the LEFT, and new ankle translation is set afterwards.
Do not multiply by the shin again; convert_local_to_pose accounts for it.
Exporter head_offset is still applied once by the existing exporter.
'''


def smoother(u):
    u = min(1., max(0., u))
    return u*u*u*(10. + u*(-15. + 6.*u))


def hermite(a, da, b, db, u, span):
    return ((2*u**3 - 3*u*u + 1)*a + (u**3 - 2*u*u + u)*span*da
            + (-2*u**3 + 3*u*u)*b + (u**3 - u*u)*span*db)


def support_height(angle):
    """Ankle z that puts the actual sole on native plane z=.012."""
    si, co = math.sin(angle), math.cos(angle)
    return GROUND - min(y*si + z*co for y, z in BOOT_HULL)


class SoleRoll:
    """Exact piecewise integral of ankle height ABOVE the contact plane.

    Using absolute ankle z would introduce slip of GROUND * angular speed.
    Contact vertex height and rolling advance both use the actual boot hull.
    """
    def __init__(self, start_angle, end_angle):
        self.start = start_angle
        self.end = end_angle
        cuts = [start_angle, end_angle]
        for (ay, az), (by, bz) in zip(BOOT_HULL, BOOT_HULL[1:] + BOOT_HULL[:1]):
            dy, dz = by-ay, bz-az
            base = math.atan2(-dz, dy)
            for k in range(-3, 4):
                x = base + k*math.pi
                if start_angle < x < end_angle:
                    cuts.append(x)
        cuts = sorted(set(cuts))
        self.segments = []
        total = 0.
        for a, b in zip(cuts, cuts[1:]):
            m = (a+b)*.5
            v = min(BOOT_HULL, key=lambda yz: yz[0]*math.sin(m) + yz[1]*math.cos(m))
            self.segments.append((a, b, v, total))
            total += self.integral(v, a, b)
        self.total = total

    @staticmethod
    def integral(vertex, a, b):
        y, z = vertex
        return y*(math.cos(b)-math.cos(a)) - z*(math.sin(b)-math.sin(a))

    def advance(self, angle):
        angle = max(self.start, min(self.end, angle))
        if angle >= self.end:
            return self.total
        for a, b, vertex, prior in self.segments:
            if angle <= b:
                return prior + self.integral(vertex, a, angle)
        raise AssertionError('angle not covered')


@dataclass(frozen=True)
class Profile:
    speed: float
    stride: float
    contact_distance: float
    heel_degrees: float = -12.
    toe_degrees: float = 28.
    back_clearance: float = .065
    middle_clearance: float = .100
    front_clearance: float = .065
    front_overshoot_pixels: float = 1.5
    hip_edge: float = .420
    walking: bool = False

    @property
    def contact(self):
        return self.contact_distance/self.stride

    @property
    def period(self):
        return self.stride/self.speed


PROFILES = {
    'run': Profile(200., 88., 16.),
    'sprint': Profile(230., 88., 16.),
    'jog': Profile(120., 56., 16.),
    'walk': Profile(60., 26., 14.04, -8., 12., .03, .055, .03, .45, .423, True),
}


@lru_cache(maxsize=4)
def roll_for(profile):
    return SoleRoll(math.radians(profile.heel_degrees), math.radians(profile.toe_degrees))


def hip_height(q, profile):
    if profile.walking:
        return profile.hip_edge + .012*math.sin(q*math.tau)**2
    c, period = profile.contact, profile.period
    support_time = c*period
    flight_time = (.5-c)*period
    launch_velocity = 9.81*flight_time*.5
    compression = launch_velocity*support_time/math.pi
    f = q % .5
    if f < c:
        return profile.hip_edge - compression*math.sin(math.pi*f/c)
    t = (f-c)*period
    return profile.hip_edge + launch_velocity*t - .5*9.81*t*t


def foot_trajectory(phase, ground_units_per_pixel, profile):
    """Returns forward distance, ankle z, roll angle, and real contact state.

    Forward distance is along native -Y. Derivatives at stance joins include
    root motion, so each foot lands and leaves with zero world contact speed.
    """
    f = phase % 1.
    g, c, stride = ground_units_per_pixel, profile.contact, profile.stride
    roll = roll_for(profile)
    d = profile.contact_distance*g
    start = .48*(d-roll.total)
    end = start + roll.total-d
    if f < c:
        u = f/c
        if u < .22:
            angle = roll.start*(1.-smoother(u/.22))
        elif u > .58:
            angle = roll.end*smoother((u-.58)/.42)
        else:
            angle = 0.
        forward = start + roll.advance(angle) - d*u
        return forward, support_height(angle), angle, True
    delta = .055
    back_overshoot = .5*stride*g*delta
    front_overshoot = profile.front_overshoot_pixels*g
    mid = (c+1.)*.5
    mid_speed = ((start-end+back_overshoot+front_overshoot)
                 /(1.-c-2.*delta)*1.5)
    # phase, forward, forward derivative, rotation, clearance.
    # Rotation and clearance derivatives are zero at these swing knots.
    knots = (
        (c, end, -stride*g, roll.end, 0.),
        (c+delta, end-back_overshoot, 0., roll.end, profile.back_clearance),
        (mid, 0., mid_speed, 0., profile.middle_clearance),
        (1.-delta, start+front_overshoot, 0., roll.start, profile.front_clearance),
        (1., start, -stride*g, roll.start, 0.),
    )
    for a, b in zip(knots, knots[1:]):
        if f <= b[0]:
            span = b[0]-a[0]
            u = (f-a[0])/span
            forward = hermite(a[1], a[2], b[1], b[2], u, span)
            angle = hermite(a[3], 0., b[3], 0., u, span)
            clearance = hermite(a[4], 0., b[4], 0., u, span)
            return forward, support_height(angle)+clearance, angle, False
    raise AssertionError('phase not covered')


def sample_walk(gear, phase, ground_per_pixel, profile='run'):
    """Blender/mathutils-only full rigid-tool pose, facing actual map travel."""
    from mathutils import Vector, Matrix
    import premium_motion as pm
    import motion_v9
    cfg = PROFILES[profile] if isinstance(profile, str) else profile
    q = phase % 1.
    ground = Vector(ground_per_pixel)
    assert abs(ground.z) < 1e-8 and ground.length > 0
    beta = math.atan2(ground.x, -ground.y)
    heading = Matrix.Rotation(beta, 3, 'Z')
    h4 = heading.to_4x4()
    T = Matrix.Translation
    hip = hip_height(q, cfg)
    lean = .035 if not cfg.walking else .015
    twist = .018*math.sin(q*math.tau)
    # Pivot at the real hip center so the body/leg roots do not detach.
    torso = (T((0, 0, hip-HIP_BIND_Z)) @ T((0, 0, HIP_BIND_Z))
             @ Matrix.Rotation(twist, 4, 'Z') @ Matrix.Rotation(lean, 4, 'X')
             @ T((0, 0, -HIP_BIND_Z)))
    head = (torso @ T((0, 0, 1.135)) @ Matrix.Rotation(-lean*.40, 4, 'X')
            @ Matrix.Rotation(-twist*.75, 4, 'Z') @ T((0, 0, -1.135)))
    family = 'drill' if gear in pm.ROTOR else 'pickaxe'
    rest = motion_v9.rest(family)
    rear = torso @ rest['rear']
    axis = torso.to_3x3() @ rest['axis']
    normal = torso.to_3x3() @ rest['tool_normal']
    hips, feet, contacts, angles = {}, {}, {}, {}
    for side, sign, offset in (('R', -1, 0.), ('L', 1, .5)):
        forward, z, angle, contact = foot_trajectory(q+offset, ground.length, cfg)
        hips[side] = torso @ Vector((sign*.205, 0, HIP_BIND_Z))
        feet[side] = Vector((sign*.205, -forward, z))
        contacts[side], angles[side] = contact, angle
    p = pm._assemble(gear, torso, head, rear, axis, normal, hips, feet, 0., contacts)
    # Rotate the entire solved pose, not just the feet under a sideways torso.
    p['torso'], p['head'] = h4 @ p['torso'], h4 @ p['head']
    for name in ('rear', 'axis', 'tool_normal'):
        p[name] = heading @ p[name]
    for name in ('grips', 'hand_axes', 'radials'):
        p[name] = {s: heading @ v for s, v in p[name].items()}
    for name in ('arms', 'legs'):
        p[name] = {s: tuple(heading @ v for v in chain) for s, chain in p[name].items()}
    p['foot_rotations'] = {s: heading @ Matrix.Rotation(angles[s], 3, 'X') for s in angles}
    p['trial_metadata'] = dict(profile=profile if isinstance(profile, str) else 'custom',
                               speed=cfg.speed, stride=cfg.stride,
                               contact_ms=1000.*cfg.contact*cfg.period,
                               period=cfg.period, heading_radians=beta)
    return p


def inertial_position(target_position, delta_position, delta_velocity, t, duration):
    """Add to an ONGOING target; endpoints match position AND velocity."""
    u = max(0., min(1., t/duration))
    return (target_position + delta_position*(2*u**3-3*u*u+1)
            + delta_velocity*(duration*(u**3-2*u*u+u)))


def forward_coast(theta0, omega0, t, duration):
    """Unwrapped positive rotor angle; never interpolate angle back to zero."""
    assert omega0 >= 0. and duration > 0.
    u = min(1., max(0., t/duration))
    theta = theta0 + omega0*duration*(u-u**3+.5*u**4)
    omega = omega0*(1.-3*u*u+2*u**3)
    return theta, omega


def self_check():
    """Light metadata check. This proves neither rendered fidelity nor FPS."""
    result = {}
    for name, cfg in PROFILES.items():
        summary = dict(speed=cfg.speed, stride=cfg.stride,
                       contact_ms=1000.*cfg.contact*cfg.period,
                       steps_per_second=2./cfg.period,
                       roll_advance=roll_for(cfg).total, directions={})
        for direction, ground in GROUND_PER_PIXEL.items():
            g = math.sqrt(sum(v*v for v in ground))
            min_margin, min_clearance = float('inf'), float('inf')
            low_hip, high_hip = float('inf'), -float('inf')
            for i in range(2001):
                q = i/2001.
                hip = hip_height(q, cfg)
                low_hip, high_hip = min(low_hip, hip), max(high_hip, hip)
                twist = .018*math.sin(q*math.tau)
                for sign, offset in ((-1, 0.), (1, .5)):
                    forward, z, angle, contact = foot_trajectory(q+offset, g, cfg)
                    hip_x = sign*.205*math.cos(twist)
                    hip_y = sign*.205*math.sin(twist)
                    length = math.sqrt((sign*.205-hip_x)**2 + (-forward-hip_y)**2 + (z-hip)**2)
                    min_margin = min(min_margin, LEG_LENGTH-length)
                    min_clearance = min(min_clearance, z-support_height(angle))
            assert min_margin > 0. and min_clearance >= -1e-12
            summary['directions'][direction] = dict(min_leg_margin=min_margin,
                min_sole_clearance=min_clearance, hip_range=[low_hip, high_hip])
        result[name] = summary
    return result


if __name__ == '__main__':
    import json
    print(json.dumps(self_check(), indent=2))
