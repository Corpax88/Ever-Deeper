"""Analytical check of one direct first wind-up before any native images."""
import argparse,hashlib,json,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[1]
sys.path[:0]=[str(HERE),str(ROOT/'tools/hero_v28')]
from body_weight_motion import BodyWeightMotion
from grounded_entry_transition import GroundedEntryTransition
p=argparse.ArgumentParser(description=__doc__)
for n in ('pivot','output'):p.add_argument('--'+n,type=Path,required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);assert not a.output.exists()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(a.pivot)=='cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
args=[json.loads((HERE/'working-surface-selection.json').read_text()),json.loads((HERE/'upper-body-hinge-selection.json').read_text()),json.loads(a.pivot.read_text())]
r={'complete':False,'passed':False,'scope':'One recorded walk.625 to mine entry, analytical only; not visual or production approval',
   'source_hashes':{str(p.relative_to(ROOT)):sha(p) for p in (Path(__file__),HERE/'grounded_entry_transition.py',HERE/'body_weight_motion.py',HERE/'side_return_motion.py',HERE/'loop_flow_motion.py')},'samples':[]}
t=None
try:
    motion=BodyWeightMotion(*args,contact_turn=True)
    clip=GroundedEntryTransition(motion,.625)
    r['metadata']=clip.metadata()
    for i in range(401):
        t=clip.duration*i/400
        pose=clip.sample(t);lower=clip.lower_pose(t)
        soles=max((pose['legs'][s][2]-lower['legs'][s][2]).length for s in ('R','L'))
        legs=max((v-w).length for s in ('R','L') for v,w in zip(pose['legs'][s],lower['legs'][s]))
        rotations=max(abs(pose['foot_rotations'][s][i][j]-lower['foot_rotations'][s][i][j]) for s in ('R','L') for i in range(3) for j in range(3))
        anchor=(pose['torso']@motion.body_joint-lower['torso']@motion.body_joint).length
        lengths=max(abs((b-a).length-u) for k,lens in [('arms',(.36,.35)),('legs',(.180,.184))] for chain in pose[k].values() for a,b,u in zip(chain,chain[1:],lens))
        assert max(soles,legs,rotations,anchor,lengths)<2e-6,(t,soles,legs,rotations,anchor,lengths)
        r['samples'].append({'seconds':t,'sole_error':soles,'lower_chain_error':legs,'sole_rotation_error':rotations,
                             'body_joint_anchor_error':anchor,'limb_length_error':lengths,
                             'maximum_arm_reach':max((w-s).length for s,e,w in pose['arms'].values()),
                             'maximum_leg_reach':max((w-s).length for s,e,w in pose['legs'].values())})
    r['endpoints']=[]
    for t,expected in [(0.,clip.source),(clip.duration,clip.destination)]:
        pose=clip.sample(t)
        error=max(abs(pose[n][i][j]-expected[n][i][j]) for n in ('torso','head') for i in range(4) for j in range(4))
        error=max(error,max((pose[n]-expected[n]).length for n in ('rear','axis','tool_normal')))
        error=max(error,max((v-w).length for k in ('arms','legs') for s in ('R','L') for v,w in zip(pose[k][s],expected[k][s])))
        assert error<2e-6,(t,error)
        r['endpoints'].append({'seconds':t,'maximum_pose_error':error})
    # Compare against the independent ongoing canonical pose, rather than just
    # checking that the authored Hermite coefficients match each other.
    h=.001
    center=clip.sample(clip.duration)
    left=[clip.sample(clip.duration-k*h) for k in (1,2)]
    right=[clip._canonical(clip.duration+k*h) for k in (1,2)]
    def coordinates(pose):
        return [v for n in ('torso','head') for row in pose[n] for v in row]+[v for n in ('rear','axis','tool_normal') for v in pose[n]]+[v for k in ('arms','legs') for chain in pose[k].values() for point in chain for v in point]
    c,l1,l2,r1,r2=map(coordinates,[center,*left,*right])
    lv=[(3*a-4*b+d)/(2*h) for a,b,d in zip(c,l1,l2)]
    rv=[(-3*a+4*b-d)/(2*h) for a,b,d in zip(c,r1,r2)]
    velocity_error=max(abs(v-w) for v,w in zip(lv,rv))
    r['canonical_handoff_velocity']={'method':'Three-point one-sided derivatives, h=.001seconds, native pose coordinates/matrix elements',
                                     'maximum_component_difference_per_second':velocity_error,
                                     'limit_per_second':.01,
                                     'meaning':'Numerical endpoint continuity check; not visual acceptance'}
    assert velocity_error<.01,('Canonical handoff velocity mismatch',velocity_error)
    r.update(complete=True,passed=True)
except Exception as e:
    r.update(failed_seconds=t,error=str(e));raise
finally:a.output.write_text(json.dumps(r,indent=2)+'\n')
print('GROUNDED_ENTRY_KINEMATICS',len(r['samples']),max(x['maximum_arm_reach'] for x in r['samples']),flush=True)
