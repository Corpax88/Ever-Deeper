"""Crusher expression study; keeps the existing model and rigid hand anchors.

Phase is normalized over the unchanged 1.45 second cycle. Only strike mode
is authored here; integration and transitions remain revision 3 work.
"""
import math
from mathutils import Matrix, Vector
import motion_v2 as base
import motion_v3 as previous

# phase, shaft pitch, rear grip Y/Z, torso lean/twist, hip Y/Z offset
# Broad anticipation, fast acceleration, short contact, recoil, slow recovery.
KEYS = [
    (0.00, .60, -.23, 1.01,  .00,  .00,  .000,  .000),
    (0.20, .73, -.37, 1.04, -.08, -.06,  .020, -.028),
    (0.39, .76,-.42, 1.10, -.12, -.10,  .035, -.018),
    (0.44, .75,-.42, 1.10, -.10, -.09,  .025, -.025),
    (0.55,-.37, -.31, .965,  .20,  .07, -.040, -.065),
    (0.57,-.37, -.31, .965,  .21,  .07, -.040, -.067),
    (0.64,-.20, -.30, .980,  .14,  .04, -.020, -.045),
    (0.79, .12, -.26, .990,  .07,  .00,  .000, -.018),
    (1.00, .60, -.23, 1.01,  .00,  .00,  .000,  .000),
]

def sample(time, kind='crusher', mode='strike'):
    if kind != 'crusher' or mode != 'strike':
        return previous.sample(time,kind,mode)
    phase=time%1
    for a,b in zip(KEYS,KEYS[1:]):
        if phase <= b[0]:
            t=(phase-a[0])/(b[0]-a[0])
            # Accelerate through the downswing; contact abruptly arrests it.
            w=t*t if a[0]==.44 else base.smooth(t)
            pitch,y,z,lean,twist,hy,hz=[u+(v-u)*w for u,v in zip(a[1:],b[1:])]
            break
    p=base.rest('iron')
    T=Matrix.Translation
    torso=T((0,hy,hz))@T((0,0,.65))@Matrix.Rotation(twist,4,'Z')@Matrix.Rotation(lean,4,'X')@T((0,0,-.65))
    p['torso']=torso
    p['head']=torso@T((0,0,1.2))@Matrix.Rotation(-lean*.35,4,'X')@Matrix.Rotation(-twist*.75,4,'Z')@T((0,0,-1.2))
    p['hips_offset']=Vector((0,hy,hz))
    axis=torso.to_3x3()@Vector((0,-math.cos(pitch),math.sin(pitch)))
    normal=torso.to_3x3()@Vector((0,-math.sin(pitch),-math.cos(pitch)))
    rear=torso@Vector((-.03,y,z))
    side_axis=axis.cross(normal).normalized()
    p.update(rear=rear,axis=axis,tool_normal=normal,phase=phase,mine=1.,walk=0.)
    # Fixed spacing: neither hand slides along the shaft in this study.
    p['grips']={'R':rear,'L':rear+axis*.14}
    p['hand_axes']={'R':axis,'L':axis}
    p['radials']={'R':(-side_axis*.88+normal*.48).normalized(),'L':(side_axis*.28+normal*.96).normalized()}
    for side,sign in [('R',-1),('L',1)]:
        shoulder=torso@Vector((sign*.255,0,1.115))
        wrist=p['grips'][side]+p['radials'][side]*.05-axis*.10
        elbow=base.solve(shoulder,wrist,torso@Vector((sign*.7,.035,.62)),.30,.275)
        p['arms'][side]=(shoulder,elbow,wrist)
        foot=Vector((sign*.16,0,.14))
        hip=Vector((sign*.16,hy,.53+hz))
        knee=base.solve(hip,foot,Vector((sign*.16,-.6,.32)),.215,.205)
        p['legs'][side]=(hip,knee,foot)
    return p

def rest(kind='crusher'):
    return previous.rest(kind)
