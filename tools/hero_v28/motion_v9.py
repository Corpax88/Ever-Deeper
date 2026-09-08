"""Game export poses on the accepted round dad rig; map-forward is -Y."""
import math
from mathutils import Vector,Matrix
import motion_v8 as dad
import motion_v2 as base
T=Matrix.Translation

def sample(t,mode='mine',family='pickaxe'):
    p=dad.sample(t,mode)
    if family=='pickaxe':return p
    if mode=='mine':
        p=dad.sample(0,'rest')
        torso=T((0,-.008,-.010))@T((0,0,.6))@Matrix.Rotation(.045,4,'X')@T((0,0,-.6))
        p['torso']=torso;p['head']=torso
    torso=p['torso'];rot=torso.to_3x3()
    shake=.0015*math.sin(t*math.tau*12) if mode=='mine' else 0
    rear=Vector((-.035,-.455+shake,.8));support=Vector((.030,-.595+shake,.860))
    p['rear']=torso@rear;p['axis']=rot@Vector((0,-1,0));p['tool_normal']=rot@Vector((0,0,-1))
    p['grips']={'R':torso@rear,'L':torso@support}
    p['hand_axes']={'R':rot@Vector((0,-.2,.98)).normalized(),'L':p['axis']}
    p['radials']={'R':rot@Vector((-1,0,0)),'L':rot@Vector((0,0,-1))}
    for side,sign in [('R',-1),('L',1)]:
        axis=p['hand_axes'][side];radial=p['radials'][side];tangent=axis.cross(radial)*sign
        wrist=p['grips'][side]+radial*.122-tangent*.015-axis*.005
        shoulder=torso@Vector((sign*.355,-.08,1.05));approach=(p['grips'][side]-wrist).normalized()
        elbow=base.solve(shoulder,wrist,wrist-approach*dad.LOWER,dad.UPPER,dad.LOWER)
        p['arms'][side]=(shoulder,elbow,wrist)
    p['bit_angle']=t*math.tau*4 if mode=='mine' else 0
    return p

def rest(family='pickaxe'):return sample(0,'rest',family)

def directional_sample(t,mode,family,direction):
    # Direction is an authored camera view of the same physically valid pose.
    return sample(t,mode,family)
