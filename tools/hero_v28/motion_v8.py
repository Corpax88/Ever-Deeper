"""Retarget the accepted Crusher motion to the round dad proportions.

No gameplay timings are changed. Directions are camera views of real poses.
"""
import math
from mathutils import Vector, Matrix
import motion_v2 as base
import motion_v6

DROP=.065
WIDTH=1.38
HIP_X=.205
TOOL_FORWARD=.19
UPPER=.36
LOWER=.35
T=Matrix.Translation

def height(z):
    return z-DROP*base.smooth((z-.16)/.40)

def body_point(q):
    q=q.copy()
    belly=math.exp(-((q.z-.79)/.29)**2)
    q.x*=WIDTH
    q.y=q.y*(1.48 if q.y<0 else 1.12)-.038*belly*base.smooth(-q.y/.12)
    q.z=height(q.z)
    return q

def leg_point(q,sign):
    q=q.copy();q.x=sign*HIP_X+(q.x-sign*.16)*1.09
    q.y*=1.04;q.z=height(q.z)
    return q

def sample(time,mode='mine'):
    # Mine uses seconds; the inherited study uses normalized cycle phase.
    if mode=='mine':
        p=motion_v6.sample(time/1.45)
    else:
        p=motion_v6.rest()
        if mode=='walk':
            gait=base.sample(.8+time%.8,'iron','demo')
            p['torso']=gait['torso'];p['head']=gait['head'];p['legs']=gait['legs']
        elif mode=='idle':
            breathe=T((0,0,.004*math.sin(time*math.tau/3.6)))
            p['torso']=breathe;p['head']=breathe
        else:
            assert mode=='rest'
        p['rear']=p['torso']@motion_v6.rest()['rear']
        p['axis']=p['torso'].to_3x3()@motion_v6.rest()['axis']
        p['tool_normal']=p['torso'].to_3x3()@motion_v6.rest()['tool_normal']
    old_torso=p['torso'].copy()
    down=T((0,0,-DROP));up=T((0,0,DROP))
    p['torso']=down@p['torso']@up;p['head']=down@p['head']@up
    p['rear']+=old_torso.to_3x3()@Vector((0,-TOOL_FORWARD,0))+Vector((0,0,-DROP))
    axis=p['axis'];normal=p['tool_normal'];lateral=axis.cross(normal).normalized()
    p['grips']={'R':p['rear'],'L':p['rear']+axis*.145}
    p['radials']={side:(lateral*sign*math.cos(math.radians(motion_v6.RADIAL_PHI[side]))+normal*math.sin(math.radians(motion_v6.RADIAL_PHI[side]))).normalized() for side,sign in [('R',-1),('L',1)]}
    p['hand_axes']={'R':axis,'L':axis}
    for side,sign in [('R',-1),('L',1)]:
        radial=p['radials'][side];tangent=axis.cross(radial)*sign
        wrist=p['grips'][side]+radial*.122-tangent*.015-axis*.005
        shoulder=p['torso']@Vector((sign*.355,-.04,1.115-DROP))
        approach=(p['grips'][side]-wrist).normalized()
        elbow=base.solve(shoulder,wrist,wrist-approach*LOWER,UPPER,LOWER)
        p['arms'][side]=(shoulder,elbow,wrist)
        hip,knee,foot=p['legs'][side]
        # Consistent deformation of all leg geometry and ankle attachments.
        hip=leg_point(hip,sign);foot=leg_point(foot,sign)
        # Two fixed shortened bone lengths, with poles forward of knees.
        knee=base.solve(hip,foot,Vector((sign*HIP_X,-.6,.30)),.180,.184)
        p['legs'][side]=(hip,knee,foot)
    return p

def rest():return sample(0,'rest')
