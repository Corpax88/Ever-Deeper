"""Four authored poses, independent of the previous correction curves."""
import json
import math
from pathlib import Path

from mathutils import Matrix, Quaternion, Vector
import premium_motion as pm
import native_motion as native

CYCLE = .68
HIT = .42


def progress(q):
    return q/.55*HIT if q <= .55 else HIT+(q-.55)/.45*(1-HIT)


def phase(t):
    return t/HIT*.55 if t <= HIT else .55+(t-HIT)/(1-HIT)*.45


class SimpleSwing:
    def __init__(self, anchors):
        self.data = anchors
        self.ground = Vector(anchors['ground'])
        self.body_joint = Vector(anchors['body_joint'])
        self.local_cap = Vector(anchors['local_cap'])
        self.contact = self.decode(anchors['contact'])
        self.neutral = self.decode(anchors['neutral'])
        # Turn into the raised grip so the short original arms can reach it.
        joint=self.neutral['torso']@self.body_joint
        turn=Matrix.Translation(joint)@Matrix.Rotation(math.radians(35),4,'Z')@Matrix.Translation(-joint)
        self.neutral['torso']=turn@self.neutral['torso']
        self.neutral['head']=turn@self.neutral['head']
        camera_axis = Vector((6.,6.1,6.02)).normalized()
        contact_rotation = pm.tool_frame(self.contact['axis'], self.contact['tool_normal']).to_quaternion()
        left = Vector((.7129,-.7013,0.))
        self.keys = [
            (0., Vector((-.30,.10,1.30)), 0., 0.),
            # Left-arm .68 reach gives z <= 1.41656; keep a small margin.
            (.29, Vector((-.30,.05,1.41)), 0., 0.),
            (HIT, self.contact['rear'], 0., 1.),
            (.60, Vector((-.40,.08,1.24)), 0., .35),
            (1., Vector((-.30,.10,1.30)), 0., 0.),
        ]
        screen_up=Vector((-.403,-.410,.818)).normalized()
        # The rejected sideways arc put the entire head behind the backpack.
        # A single vertical working plane keeps the head above the helmet;
        # its positive camera depth puts the retreat on the visible side.
        raised_cap=(screen_up+left*.35+camera_axis*.22).normalized()
        old_cap=contact_rotation@self.local_cap.normalized()
        raised_rotation=old_cap.rotation_difference(raised_cap)@contact_rotation
        self.rotations=[raised_rotation,raised_rotation,contact_rotation,raised_rotation,raised_rotation]
        inv = self.contact['torso'].inverted()
        self.poles = {s: inv@self.contact['arms'][s][1] for s in native.SIDES}

    @staticmethod
    def decode(d):
        p = dict(d)
        for k in ('torso','head'): p[k] = Matrix(d[k])
        for k in ('rear','axis','tool_normal'): p[k] = Vector(d[k])
        for k in ('grips','hand_axes','radials'): p[k] = {s:Vector(v) for s,v in d[k].items()}
        for k in ('arms','legs'): p[k] = {s:tuple(Vector(v) for v in c) for s,c in d[k].items()}
        p['foot_rotations'] = {s:Matrix(v) for s,v in d['foot_rotations'].items()}
        return p

    def sample(self, state, q, speed=340.):
        if state != 'mine':
            return native.sample('worn',state,q,self.ground,speed,direction='up')
        t=progress(q%1.)
        i=next(i for i in range(4) if self.keys[i][0] <= t <= self.keys[i+1][0])
        a,b=self.keys[i],self.keys[i+1]
        u=(t-a[0])/(b[0]-a[0])
        # Slow preparation; accelerating strike; quick departure from impact.
        w = u*u if i==1 else (1-(1-u)**2 if i==2 else u*u*(3-2*u))
        rear=a[1].lerp(b[1],w)
        rotation=self.rotations[i].slerp(self.rotations[i+1],w).to_matrix()
        weight=a[3]+(b[3]-a[3])*w
        p=dict(self.neutral)
        for k in ('torso','head'):
            start,end=self.neutral[k],self.contact[k]
            p[k]=start.to_quaternion().slerp(end.to_quaternion(),weight).to_matrix().to_4x4()
            p[k].translation=start.translation.lerp(end.translation,weight)
        p['legs']={s:tuple(a.lerp(b,weight) for a,b in zip(self.neutral['legs'][s],self.contact['legs'][s]))
                   for s in native.SIDES}
        solved=pm._assemble('worn',p['torso'],p['head'],rear,rotation.col[0],rotation.col[2],
            {s:c[0] for s,c in p['legs'].items()}, {s:c[2] for s,c in p['legs'].items()},
            0.,dict(R=True,L=True),{s:c[1] for s,c in p['legs'].items()})
        p.update(solved)
        for s,(shoulder,_,wrist) in p['arms'].items():
            pole=p['torso']@self.poles[s]
            elbow=pm.solve(shoulder,wrist,pole,.36,.35)
            p['arms'][s]=(shoulder,elbow,wrist)
        return p

    def selection(self):
        return dict(proposal='four-authored-poses',cycle=CYCLE,impact_progress=HIT,
                    key_progress=[k[0] for k in self.keys],visual_accepted=False,production_accepted=False)
