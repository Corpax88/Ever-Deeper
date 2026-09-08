"""Existing Crusher body motion with a corrected anatomical wrist approach."""
from mathutils import Vector
import math
import motion_v4, motion_v2
RADIAL_PHI={'R':-16.,'L':-18.}

def sample(phase):
    p=motion_v4.sample(phase)
    # A natural palm-to-wrist length needs room in the anticipation pose.
    # Bring the rear grip toward the chest while lowering shaft pitch enough
    # to keep the axe head forward of the helmet. Body/timing/contact stay v4.
    q=phase%1
    w=motion_v2.smooth(q/.39) if q<=.39 else 1 if q<=.44 else 1-motion_v2.smooth((q-.44)/.11) if q<.55 else 0
    rot=p['torso'].to_3x3();local=rot.inverted()@p['axis'];theta=math.atan2(local.z,-local.y)-.16*w
    p['rear']+=rot@Vector((0,.065*w,0))
    p['axis']=rot@Vector((0,-math.cos(theta),math.sin(theta)))
    p['tool_normal']=rot@Vector((0,-math.sin(theta),-math.cos(theta)))
    axis=p['axis'];normal=p['tool_normal'];lateral=axis.cross(normal).normalized()
    p['grips']={'R':p['rear'],'L':p['rear']+axis*.145}
    p['radials']={side:(lateral*sign*math.cos(math.radians(RADIAL_PHI[side]))+normal*math.sin(math.radians(RADIAL_PHI[side]))).normalized() for side,sign in [('R',-1),('L',1)]}
    p['hand_axes']={'R':axis,'L':axis}
    for side,sign in [('R',-1),('L',1)]:
        radial=p['radials'][side];tangent=axis.cross(radial)*sign
        # Wrist proximal to palm, perpendicular to the shaft. The old -axis*.10
        # approach placed the wrist along the knuckle row, twisting the hand.
        wrist=p['grips'][side]+radial*.122-tangent*.015-axis*.005
        shoulder=p['torso']@Vector((sign*.255,0,1.115))
        approach=(p['grips'][side]-wrist).normalized()
        elbow=motion_v2.solve(shoulder,wrist,wrist-approach*.275,.30,.275)
        p['arms'][side]=(shoulder,elbow,wrist)
    return p

def rest():return sample(0)
