"""Measure a single whole-body candidate against its exact fixed tool/foot paths."""
import argparse,hashlib,json,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[1]
sys.path[:0]=[str(HERE),str(ROOT/'tools/hero_v28')]
from side_return_motion import SideReturnMotion
from body_weight_motion import BodyWeightMotion
from loop_flow_motion import native_phase
p=argparse.ArgumentParser(description=__doc__)
for n in ('pivot','output'):p.add_argument('--'+n,type=Path,required=True)
p.add_argument('--contact-turn',action='store_true')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);assert not a.output.exists()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(a.pivot)=='cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
args=[json.loads((HERE/'working-surface-selection.json').read_text()),json.loads((HERE/'upper-body-hinge-selection.json').read_text()),json.loads(a.pivot.read_text())]
before,after=SideReturnMotion(*args,True),BodyWeightMotion(*args,a.contact_turn)
r={'complete':False,'passed':False,'selection':after.selection(),'samples':[],
   'source_hashes':{str(p.relative_to(ROOT)):sha(p) for p in (Path(__file__),HERE/'body_weight_motion.py',HERE/'side_return_motion.py',HERE/'loop_flow_motion.py')},
   'scope':'401 analytic whole-body samples; no mesh/collision or visual approval'}
try:
    for i in range(401):
        q=native_phase(i/400)
        old,new=before.sample('mine',q),after.sample('mine',q)
        tool=max((old[n]-new[n]).length for n in ('rear','axis','tool_normal'))
        tool=max(tool,max((old['grips'][s]-new['grips'][s]).length for s in ('R','L')))
        feet=max((old['legs'][s][2]-new['legs'][s][2]).length for s in ('R','L'))
        feet=max(feet,max(abs(old['foot_rotations'][s][i][j]-new['foot_rotations'][s][i][j]) for s in ('R','L') for i in range(3) for j in range(3)))
        lengths=max(abs((b-a).length-u) for k,lens in [('arms',(.36,.35)),('legs',(.180,.184))] for chain in new[k].values() for a,b,u in zip(chain,chain[1:],lens))
        assert tool<1e-6 and feet<1e-6 and lengths<1e-6,(q,tool,feet,lengths)
        r['samples'].append({'phase':q,'fixed_tool_error':tool,'fixed_sole_error':feet,'length_error':lengths,
                             'maximum_arm_reach':max((w-s).length for s,e,w in new['arms'].values()),
                             'maximum_leg_reach':max((w-s).length for s,e,w in new['legs'].values())})
    r.update(complete=True,passed=True)
except Exception as e:
    r.update(failed_phase=q,error=str(e));raise
finally:a.output.write_text(json.dumps(r,indent=2)+'\n')
print('BODY_WEIGHT_KINEMATICS',len(r['samples']),flush=True)
