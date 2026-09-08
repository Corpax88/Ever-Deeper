"""Shared, deterministic poses for the two native Blender studies.

World Z is height; map-forward is -Y. Anatomical R is -X, L is +X.
"""
import math
from mathutils import Vector,Matrix
DRILL_OFFSET=Vector((0,-.10,-.025))

def smooth(x):
    x=max(0,min(1,x));return x*x*(3-2*x)
def translate(v):return Matrix.Translation(Vector(v))
def solve(a,c,pole,u,l):
    d=(c-a).length
    if not abs(u-l)+1e-4<d<u+l-1e-4:raise ValueError(f'Unreachable chain: {d} vs {u+l}')
    n=(c-a)/d;q=pole-a;nq=(q-n*n.dot(q)).normalized()
    along=(u*u-l*l+d*d)/(2*d)
    return a+n*along+nq*math.sqrt(max(0,u*u-along*along))
def frame_matrix(axis,radial):
    return Matrix((axis,axis.cross(radial).normalized(),radial)).transposed()

def sample(time,kind='iron',mode='demo'):
    if mode=='rest':walk=mine=phase=0
    elif mode=='strike':
        walk=0;mine=1;phase=time%1
    else:
        walk=smooth((time-.6)/.16)*(1-smooth((time-2.0)/.16))
        mine=smooth((time-2.3)/.16)*(1-smooth((time-4.3)/.16))
        phase=max(0,time-2.3)%1
    stride=time/0.80
    idle=math.sin(time*math.tau/3.6)*.003 if mode!='rest' else 0
    gaitbob=.011*(1-math.cos(stride*math.tau*2))*.5*walk
    sway=.014*math.sin(stride*math.tau)*walk
    if kind=='iron':
        stages=[(0,.60,(-.03,-.23,1.01),.17,0),(.30,.82,(0,-.35,1.10),.13,0),(.46,-.22,(-.04,-.29,.97),.14,1),(1,.60,(-.03,-.23,1.01),.17,0)]
        for a,b in zip(stages,stages[1:]):
            if phase<=b[0]:
                f=smooth((phase-a[0])/(b[0]-a[0]));theta=a[1]*(1-f)+b[1]*f
                rear=Vector(a[2]).lerp(Vector(b[2]),f);spread=a[3]*(1-f)+b[3]*f;comp=a[4]*(1-f)+b[4]*f;break
        theta=.60+(theta-.60)*mine;rear=Vector(stages[0][2]).lerp(rear,mine)
        spread=.17+(spread-.17)*mine;comp*=mine
        axis=Vector((0,-math.cos(theta),math.sin(theta)))
        normal=Vector((0,-math.sin(theta),-math.cos(theta)))
        grips={'R':rear,'L':rear+axis*spread}
        radials={'R':(Vector((-1,0,0))*.88+normal*.48).normalized(), 'L':(Vector((1,0,0))*.28+normal*.96).normalized()}
        hand_axes={'R':axis,'L':axis}
        wrists={s:grips[s]+radials[s]*.05-axis*.10 for s in ['R','L']}
    else:
        comp=.20*mine
        shake=math.sin(time*math.tau*12)*.0015*mine
        rear=Vector((-.035,-.235+shake,.89))+DRILL_OFFSET
        axis=Vector((0,-1,0));normal=Vector((0,0,-1))
        grips={'R':rear,'L':Vector((-.035,-.43+shake,.950))+DRILL_OFFSET}
        radials={'R':Vector((-1,0,0)),'L':Vector((0,0,-1))}
        hand_axes={'R':Vector((0,-.2,.98)).normalized(),'L':axis}
        wrists={'R':rear+Vector((-.055,.06,-.035)), 'L':grips['L']+Vector((.055,.095,-.04))}
    lean=.055*comp+.025*walk
    twist=.028*math.sin(phase*math.tau)*mine if kind=='iron' else 0
    torso=translate((sway,-.012*comp,-.025*comp+gaitbob+idle))@translate((0,0,.65))@Matrix.Rotation(twist,4,'Z')@Matrix.Rotation(lean,4,'X')@translate((0,0,-.65))
    head=torso@translate((0,0,1.2))@Matrix.Rotation(-lean*.55,4,'X')@Matrix.Rotation(-twist*.65,4,'Z')@translate((0,0,-1.2))
    rot=torso.to_3x3();rear=torso@rear;axis=rot@axis;normal=rot@normal
    grips={s:torso@v for s,v in grips.items()};radials={s:rot@v for s,v in radials.items()}
    hand_axes={s:rot@v for s,v in hand_axes.items()};wrists={s:torso@v for s,v in wrists.items()}
    arms={};legs={};foot_lifts={}
    for side,sign in [('R',-1),('L',1)]:
        shoulder=torso@Vector((sign*.255,0,1.115));wrist=wrists[side]
        elbow=solve(shoulder,wrist,torso@Vector((sign*.7,.035,.62)),.30,.275)
        arms[side]=(shoulder,elbow,wrist)
        ph=(stride+(0 if side=='R' else .5))%1
        if ph<.55:y=-.10+.20*ph/.55;lift=0
        else:
            f=(ph-.55)/.45;y=.10-.20*smooth(f);lift=.065*math.sin(math.pi*f)
        foot_y=y*walk;foot_lift=lift*walk
        # Settle the two feet one at a time when stopping. Interpolating both
        # planted feet to neutral would visibly slide them across the floor.
        if mode=='demo' and 2.0<=time<2.28:
            start=2.0 if side=='L' else 2.14
            u=max(0,min(1,(time-start)/.14))
            start_y=-.10 if side=='L' else (-.10+.20*.5/.55)
            foot_y=start_y*(1-smooth(u));foot_lift=.040*math.sin(math.pi*u)
        foot=Vector((sign*.16,foot_y,.14+foot_lift))
        hip=Vector((sign*.16+sway*.55,0,.53-.020*comp+gaitbob))
        knee=solve(hip,foot,Vector((sign*.16,-.6,.32)),.215,.205)
        legs[side]=(hip,knee,foot);foot_lifts[side]=foot_lift
    return dict(time=time,walk=walk,mine=mine,phase=phase,compression=comp,torso=torso,head=head,
                rear=rear,axis=axis,tool_normal=normal,grips=grips,radials=radials,hand_axes=hand_axes,
                arms=arms,legs=legs,foot_lifts=foot_lifts,bit_angle=0)

def rest(kind):return sample(0,kind,'rest')
