"""Equipment motion profiles layered on the accepted working rig.

Visual timing only. Gameplay economy and damage intervals are not changed.
"""
import json,math
from pathlib import Path
from mathutils import Vector,Matrix
import motion_v2 as base
DRILL_OFFSET=base.DRILL_OFFSET
smooth=base.smooth
frame_matrix=base.frame_matrix
PROFILES=json.loads((Path(__file__).parent/'gear_profiles.json').read_text())

def sample(time,kind='iron',mode='demo'):
    cfg=PROFILES[kind];family='deepcore' if cfg['family']=='drill' else 'iron'
    # Reuse walking and foot settling exactly; replace upper body with the
    # equipment's mining cycle only once walking has fully stopped.
    p=base.sample(time,family,mode)
    if mode=='rest':return p
    if mode=='idle':
        p=base.rest(family)
        breath=Matrix.Translation((0,0,.003*math.sin(time*math.tau/3.6)))
        for key in ['torso','head']:p[key]=breath@p[key]
        p['rear']=breath@p['rear']
        p['grips']={s:breath@g for s,g in p['grips'].items()}
        p['arms']={s:tuple(breath@v for v in chain) for s,chain in p['arms'].items()}
        return p
    if mode=='walk':
        # Extract an uninterrupted gait with its real time parameter.
        p=base.sample(.80+time%.80,family,'demo')
        p['mine']=0
        return p
    mine=p['mine']
    if family=='deepcore':return p
    if mode=='strike':mine=1.;phase=time%1
    else:phase=(max(0,time-2.3)/cfg['cycle'])%1
    if not mine:return p
    # Warp the actual contact to each profile's authored phase, preserving
    # continuity at both loop endpoints and at the impact.
    hit=cfg['impact'] or .46
    qphase=phase*.46/hit if phase<hit else .46+(phase-hit)*.54/(1-hit)
    pose=base.sample(qphase,family,'strike')
    neutral=base.rest(family)
    # Interpolate tool and torso transforms through genuine poses; re-solve
    # elbows so both palms remain anchored after a state blend.
    def matblend(a,b,w):
        loc=a.translation.lerp(b.translation,w)
        rot=a.to_quaternion().slerp(b.to_quaternion(),w)
        return Matrix.Translation(loc)@rot.to_matrix().to_4x4()
    torso=matblend(neutral['torso'],pose['torso'],mine)
    head=matblend(neutral['head'],pose['head'],mine)
    p['torso']=torso;p['head']=head
    for key in ['rear','axis','tool_normal']:
        p[key]=neutral[key].lerp(pose[key],mine)
        if key!='rear':p[key].normalize()
    p['tool_normal']=(p['tool_normal']-p['axis']*p['tool_normal'].dot(p['axis'])).normalized()
    # Tool-aligned pickaxe grip definition ensures interpolation never
    # shortens grip spacing or shears a hand away from the rigid shaft.
    if family=='iron':
        spread=(neutral['grips']['L']-neutral['rear']).length*(1-mine)+(pose['grips']['L']-pose['rear']).length*mine
        p['grips']={'R':p['rear'],'L':p['rear']+p['axis']*spread}
        p['hand_axes']={'R':p['axis'],'L':p['axis']}
        normal=p['tool_normal'];side_axis=p['axis'].cross(normal).normalized()
        p['radials']={'R':(-side_axis*.88+normal*.48).normalized(),'L':(side_axis*.28+normal*.96).normalized()}
        wrists={s:p['grips'][s]+p['radials'][s]*.05-p['axis']*.10 for s in ['R','L']}
    else:
        # Continuous time drives rotor/vibration, never the warped pick phase.
        pose=base.sample(time,'deepcore','strike')
        pose['mine']=mine
        for key in ['rear','axis','tool_normal','grips','hand_axes','radials','arms','torso','head']:p[key]=pose[key]
        return p
    for side,sign in [('R',-1),('L',1)]:
        a=torso@Vector((sign*.255,0,1.115));c=wrists[side]
        b=base.solve(a,c,torso@Vector((sign*.7,.035,.62)),.30,.275)
        p['arms'][side]=(a,b,c)
    p['phase']=phase
    return p

def rest(kind):return sample(0,kind,'rest')
