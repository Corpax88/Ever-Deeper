"""Body-led overhead study, informed by observed Valheim footage.

The approved large helmet prevents a literal human-proportioned hand path.
The dominant hand travels beside it; the pick head travels behind/above it.
The support hand deliberately releases before the loaded pose, and regrips
late in recovery. No production animation or gameplay clock is changed.
"""
import math
from mathutils import Matrix, Vector
import premium_motion as pm
import native_motion as native

CYCLE = .68
HIT = .42

def progress(q):
    return q/.55*HIT if q <= .55 else HIT+(q-.55)/.45*(1-HIT)

def phase(t):
    return t/HIT*.55 if t <= HIT else .55+(t-HIT)/(1-HIT)*.45

def blend_matrix(a,b,w):
    m=a.to_quaternion().slerp(b.to_quaternion(),w).to_matrix().to_4x4()
    m.translation=a.translation.lerp(b.translation,w)
    return m

class SimpleSwing:
    review_times=[.24,.34,HIT,.70]

    @staticmethod
    def decode(d):
        p=dict(d)
        for k in ('torso','head'): p[k]=Matrix(d[k])
        for k in ('rear','axis','tool_normal'): p[k]=Vector(d[k])
        for k in ('grips','hand_axes','radials'):p[k]={s:Vector(v) for s,v in d[k].items()}
        for k in ('arms','legs'):p[k]={s:tuple(Vector(v) for v in c) for s,c in d[k].items()}
        p['foot_rotations']={s:Matrix(v) for s,v in d['foot_rotations'].items()}
        return p

    def __init__(self,anchors):
        self.ground=Vector(anchors['ground'])
        self.body_joint=Vector(anchors['body_joint'])
        self.local_cap=Vector(anchors['local_cap'])
        self.contact=self.decode(anchors['contact'])
        self.neutral=self.decode(anchors['neutral'])
        self.camera=Vector((0.,math.sqrt(72)+.1,6.02)).normalized()
        original=pm.tool_frame(self.contact['axis'],self.contact['tool_normal'])
        self.contact_cap=self.contact['rear']+original@self.local_cap
        contact_rotation=self.frame(self.contact['axis'])
        contact_rear=self.contact_cap-contact_rotation@self.local_cap
        # Keyed world-space tool path. The explicit apex enforces an overhead
        # arc, rather than allowing a quaternion shortcut through the helmet.
        self.keys=[
            (0.,Vector((-.30,.10,1.15)),Vector((.15,0.,1.)),0.,0.),
            (.24,Vector((.48,.42,1.46)),Vector((1.,0.,.12)),22.,0.),
            (.34,Vector((.05,.49,1.47)),Vector((-.10,0.,1.)),5.,.20),
            (HIT,contact_rear,self.contact['axis'],-12.,1.),
            (.52,contact_rear,self.contact['axis'],-12.,1.),
            (.70,Vector((-.36,.36,1.04)),Vector((-.35,0.,1.)),-5.,.65),
            (.88,Vector((-.30,.10,1.15)),Vector((.15,0.,1.)),0.,0.),
            (1.,Vector((-.30,.10,1.15)),Vector((.15,0.,1.)),0.,0.),
        ]
        self.rotations=[self.frame(k[2]).to_quaternion() for k in self.keys]
        self.bodies=[]
        for _,_,_,lean,weight in self.keys:
            body={k:blend_matrix(self.neutral[k],self.contact[k],weight) for k in ('torso','head')}
            pivot=body['torso']@self.body_joint
            bend=Matrix.Translation(pivot)@Matrix.Rotation(math.radians(lean),4,'Y')@Matrix.Translation(-pivot)
            self.bodies.append({k:bend@m for k,m in body.items()})

    def frame(self,axis):
        axis=Vector(axis).normalized()
        face=(self.camera-axis*self.camera.dot(axis)).normalized()
        return pm.tool_frame(axis,axis.cross(face).normalized())

    def sample(self,state,q,speed=340.):
        if state!='mine':return native.sample('worn',state,q,self.ground,speed,direction='up')
        t=progress(q%1.)
        i=next(j for j in range(len(self.keys)-1) if self.keys[j][0]<=t<=self.keys[j+1][0])
        a,b=self.keys[i:i+2];u=(t-a[0])/(b[0]-a[0])
        w=u*u if i==2 else pm.smooth(u)
        rear=a[1].lerp(b[1],w)
        rotation=self.rotations[i].slerp(self.rotations[i+1],w).to_matrix()
        axis,normal=rotation.col[0],rotation.col[2]
        p=dict(self.neutral)
        for k in ('torso','head'):p[k]=blend_matrix(self.bodies[i][k],self.bodies[i+1][k],w)
        weight=a[4]+(b[4]-a[4])*w
        p.update(rear=rear,axis=axis,tool_normal=normal,contacts=dict(R=True,L=True))
        lateral=axis.cross(normal).normalized()
        p['grips']={'R':rear,'L':rear+axis*.145}
        p['hand_axes']=dict(R=axis,L=axis)
        p['radials']={s:(lateral*sign*math.cos(math.radians(angle))+normal*math.sin(math.radians(angle))).normalized()
                      for s,sign,angle in [('R',-1,-16.),('L',1,-18.)]}
        # Deliberate support-hand release; contacts above refer to the feet.
        release=pm.smooth((t-.05)/.13)*(1.-pm.smooth((t-.75)/.13))
        free_grip=p['torso']@Vector((.30,-.31,.81))
        p['grips']['L']=p['grips']['L'].lerp(free_grip,release)
        free_axis=(p['torso'].to_3x3()@Vector((0.,0.,1.))).normalized()
        free_radial=(p['torso'].to_3x3()@Vector((1.,0.,0.))).normalized()
        hand_rotation=pm.tool_frame(axis,p['radials']['L']).to_quaternion().slerp(pm.tool_frame(free_axis,free_radial).to_quaternion(),release).to_matrix()
        p['hand_axes']['L']=hand_rotation.col[0]
        p['radials']['L']=hand_rotation.col[2]
        p['hand_contact']=dict(R=True,L=release<1e-7)
        p['support_release']=release
        p['arms'],p['legs']={},{}
        for s,sign in [('R',-1),('L',1)]:
            h,r=p['hand_axes'][s],p['radials'][s]
            wrist=p['grips'][s]+r*.122-h.cross(r)*sign*.015-h*.005
            shoulder=p['torso']@Vector((sign*.355,-.04,1.05))
            pole=p['torso']@Vector((sign*.60,-.12,1.05))
            elbow=pm.solve(shoulder,wrist,pole,.36,.35)
            p['arms'][s]=(shoulder,elbow,wrist)
            leg=tuple(x.lerp(y,weight) for x,y in zip(self.neutral['legs'][s],self.contact['legs'][s]))
            knee=pm.solve(leg[0],leg[2],leg[1],.180,.184)
            p['legs'][s]=(leg[0],knee,leg[2])
        return p

    def selection(self):
        return dict(proposal='reference-led-overhead',cycle=CYCLE,impact_progress=HIT,
                    review_progress=self.review_times,hand_release='before load; regrip late recovery',
                    visual_accepted=False,production_accepted=False)
