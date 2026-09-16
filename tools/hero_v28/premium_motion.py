"""Native motion pilot on the approved proportions; never deforms rendered sprites.

Every sample is a complete rigid-tool pose with solved arms and legs. The exporter
supplies the active camera's ground-plane Jacobian for screen-aligned locomotion.
Production atlases change only after the rendered pilot passes review.
"""
import math
from mathutils import Vector, Matrix

TAU = math.tau
T = Matrix.Translation
WEIGHT = dict(worn=.66, iron=.75, runed=.82, moonglass=.68, ember=.85,
              crusher=1., comet=.43, crown=.83)
ROTOR = dict(burrower=2., pulse=3., deepcore=4.)
STRIDE_PIXELS = 120.
CONTACT_FRACTION = .10
HIP_Z = .465


def smooth(x):
    x = max(0., min(1., x))
    return x*x*(3.-2.*x)


def solve(a, c, pole, upper, lower):
    distance = (c-a).length
    if not abs(upper-lower)+1e-5 < distance < upper+lower-1e-5:
        raise ValueError(('Unreachable native limb', distance, upper+lower, tuple(a), tuple(c)))
    axis = (c-a)/distance
    radial = pole-a
    radial = (radial-axis*axis.dot(radial)).normalized()
    along = (upper*upper-lower*lower+distance*distance)/(2.*distance)
    return a+axis*along+radial*math.sqrt(max(0., upper*upper-along*along))


def _body(lean, twist, translation):
    return T(translation)@T((0,0,.6))@Matrix.Rotation(twist,4,'Z')@Matrix.Rotation(lean,4,'X')@T((0,0,-.6))


def tool_frame(axis, normal):
    return Matrix((axis, normal.cross(axis).normalized(), normal)).transposed()


def heading_matrix(ground_per_pixel):
    ground = Vector(ground_per_pixel)
    return Matrix.Rotation(math.atan2(ground.x, -ground.y), 3, 'Z')


def orient_pose(p, ground_per_pixel):
    """One heading operation for every native state, including its feet."""
    h = heading_matrix(ground_per_pixel)
    out = dict(p)
    out['torso'], out['head'] = h.to_4x4()@p['torso'], h.to_4x4()@p['head']
    for name in ('rear', 'axis', 'tool_normal'):
        out[name] = h@p[name]
    for name in ('grips', 'hand_axes', 'radials'):
        out[name] = {side: h@v for side, v in p[name].items()}
    for name in ('arms', 'legs'):
        out[name] = {side: tuple(h@v for v in chain) for side, chain in p[name].items()}
    rotations = p.get('foot_rotations', {s: Matrix.Identity(3) for s in ('R', 'L')})
    out['foot_rotations'] = {side: h@rotation for side, rotation in rotations.items()}
    return out


def translate_pose(p, offset):
    offset = Vector(offset)
    out = dict(p)
    out['torso'], out['head'] = T(offset)@p['torso'], T(offset)@p['head']
    out['rear'] = p['rear']+offset
    out['grips'] = {side: v+offset for side, v in p['grips'].items()}
    for name in ('arms', 'legs'):
        out[name] = {side: tuple(v+offset for v in chain) for side, chain in p[name].items()}
    return out


def _assemble(gear, torso, head, rear, axis, normal, hips, feet, bit=0., contacts=None, leg_poles=None):
    drill = gear in ROTOR
    rot = torso.to_3x3()
    if drill:
        tool_rot = tool_frame(axis, normal)@tool_frame(Vector((0,-1,0)), Vector((0,0,-1))).transposed()
        grips = {'R':rear, 'L':rear+tool_rot@Vector((.065,-.140,.060))}
        hand_axes = {'R':tool_rot@Vector((0,-.2,.98)).normalized(), 'L':axis}
        radials = {'R':tool_rot@Vector((-1,0,0)), 'L':normal}
    else:
        grips = {'R':rear, 'L':rear+axis*.145}
        lateral = axis.cross(normal).normalized()
        hand_axes = dict(R=axis,L=axis)
        radials = {s:(lateral*sign*math.cos(math.radians(angle))+normal*math.sin(math.radians(angle))).normalized()
                   for s,sign,angle in [('R',-1,-16.),('L',1,-18.)]}
    arms,legs = {},{}
    for side,sign in [('R',-1),('L',1)]:
        wrist = grips[side]+radials[side]*.122-hand_axes[side].cross(radials[side])*sign*.015-hand_axes[side]*.005
        shoulder = torso@Vector((sign*.355,-.08 if drill else -.04,1.05))
        approach = (grips[side]-wrist).normalized()
        elbow = solve(shoulder,wrist,wrist-approach*.35,.36,.35)
        arms[side] = (shoulder,elbow,wrist)
        hip,foot = hips[side],feet[side]
        pole = leg_poles[side] if leg_poles is not None else Vector((sign*.205,-.6,.30))
        knee = solve(hip,foot,pole,.180,.184)
        legs[side] = (hip,knee,foot)
    return dict(torso=torso,head=head,rear=rear,axis=axis,tool_normal=normal,
                grips=grips,hand_axes=hand_axes,radials=radials,arms=arms,legs=legs,
                bit_angle=bit,contacts=contacts or dict(R=True,L=True))


def sample(gear, state, phase, ground_per_pixel=None):
    """phase is normalized for a cycle; rest is exactly the approved bind pose."""
    drill = gear in ROTOR
    q = phase % 1.
    lean = twist = hy = hz = sx = 0.
    pitch,y,z = .60,-.42,.945
    feet = {s:Vector((sign*.205,0,.14)) for s,sign in [('R',-1),('L',1)]}
    contacts = dict(R=True,L=True)
    if state == 'mine' and not drill:
        weight = WEIGHT[gear]
        # Wind-up, acceleration, contact, compression, recoil, full recovery.
        keys = [(0., .60,-.42,.945,0.,0.,0.,0.),
                (.24,.87,-.44,1.060,-.075,-.05,.015,-.022),
                (.40,1.17,-.40,1.150,-.115,-.085,.028,-.018),
                (.55,-.37,-.50,.900,.20,.075,-.037,-.062),
                (.575,-.38,-.50,.896,.21,.075,-.037,-.065),
                (.68,-.15,-.47,.924,.12,.038,-.014,-.035),
                (.82,.22,-.435,.938,.045,0.,0.,-.012),
                (1.,.60,-.42,.945,0.,0.,0.,0.)]
        for a,b in zip(keys,keys[1:]):
            if q <= b[0]:
                t=(q-a[0])/(b[0]-a[0])
                w=t*t if a[0]==.40 else smooth(t)
                pitch,y,z,lean,twist,hy,hz=[u+(v-u)*w for u,v in zip(a[1:],b[1:])]
                break
        amplitude=.62+.38*weight
        pitch=.60+(pitch-.60)*amplitude
        y=-.42+(y+.42)*amplitude
        z=.945+(z-.945)*amplitude
        lean*=amplitude;twist*=amplitude;hy*=amplitude;hz*=amplitude
    elif state == 'mine':
        load=dict(burrower=.80,pulse=1.,deepcore=1.18)[gear]
        recoil=.0015*math.sin(q*TAU*12.)
        lean=.045*load+recoil
        hy=-.008*load;hz=-.010*load
    elif state == 'walk':
        assert ground_per_pixel is not None
        # A short grounded push and airborne recovery fit the approved short
        # legs at the existing game speed. Review this as a carrying run.
        sx=.006*math.sin(q*TAU)
        hz=-.050+.012*math.sin(q*TAU*2.)**2
        lean=.040
        twist=.025*math.sin(q*TAU)
        for side,offset in [('R',0.),('L',.5)]:
            f=(q+offset)%1.
            contact=f<CONTACT_FRACTION
            if contact:
                distance=STRIDE_PIXELS*(CONTACT_FRACTION*.5-f)
                lift=0.
            else:
                t=(f-CONTACT_FRACTION)/(1.-CONTACT_FRACTION)
                distance=STRIDE_PIXELS*CONTACT_FRACTION*(-.5+smooth(t))
                lift=.055*math.sin(math.pi*t)
            feet[side]+=ground_per_pixel*distance+Vector((0,0,lift))
            contacts[side]=contact
    elif state == 'idle':
        hz=.004*math.sin(q*TAU)
    else:
        assert state == 'rest'
    torso=_body(lean,twist,(sx,hy,hz))
    head=torso@T((0,0,1.135))@Matrix.Rotation(-lean*.40,4,'X')@Matrix.Rotation(-twist*.75,4,'Z')@T((0,0,-1.135))
    hips={s:Vector((sign*.205+sx*.55,hy,HIP_Z+hz)) for s,sign in [('R',-1),('L',1)]}
    if drill:
        shake=.0015*math.sin(q*TAU*12.) if state=='mine' else 0.
        rear=torso@Vector((-.035,-.455+shake,.8))
        axis=torso.to_3x3()@Vector((0,-1,0))
        normal=torso.to_3x3()@Vector((0,0,-1))
    else:
        rear=torso@Vector((-.03,y,z))
        axis=torso.to_3x3()@Vector((0,-math.cos(pitch),math.sin(pitch)))
        normal=torso.to_3x3()@Vector((0,-math.sin(pitch),-math.cos(pitch)))
    return _assemble(gear,torso,head,rear,axis,normal,hips,feet,
                     q*TAU*ROTOR[gear] if drill and state=='mine' else 0.,contacts)


def blend(gear, source, target, weight):
    """Blend native rigid transforms, then re-solve every limb and grip."""
    w=smooth(weight)
    def matrix(a,b):
        return T(a.translation.lerp(b.translation,w))@a.to_quaternion().normalized().slerp(b.to_quaternion().normalized(),w).normalized().to_matrix().to_4x4()
    def frame(p):
        axis=p['axis'];normal=p['tool_normal']
        return Matrix((axis,normal.cross(axis).normalized(),normal)).transposed().to_quaternion()
    tool=frame(source).normalized().slerp(frame(target).normalized(),w).normalized().to_matrix()
    hips,feet={},{}
    for side in ['R','L']:
        hips[side]=source['legs'][side][0].lerp(target['legs'][side][0],w)
        a,b=source['legs'][side][2],target['legs'][side][2]
        feet[side]=a.lerp(b,w)
        if (a-b).length>.005:
            feet[side].z+=.026*math.sin(math.pi*w)
    return _assemble(gear,matrix(source['torso'],target['torso']),matrix(source['head'],target['head']),
                     source['rear'].lerp(target['rear'],w),tool.col[0],tool.col[2],hips,feet,
                     source['bit_angle']+(target['bit_angle']-source['bit_angle'])*w,
                     {side:abs(feet[side].z-.14)<1e-5 for side in ['R','L']})
