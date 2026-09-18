"""Cheap paired pose measurement before deciding whether to render a trial."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(ROOT/'tools/hero_v28')]
import premium_motion as pm
from complete_return_motion import CompleteReturnMotion
from loop_flow_motion import LoopFlowMotion, native_phase, CYCLE_SECONDS

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--pivot', type=Path, required=True)
p.add_argument('--recorded', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--round-start', type=float, default=.85)
p.add_argument('--round-end', type=float, default=.15)
p.add_argument('--outward-load', action='store_true')
p.add_argument('--side-return', action='store_true')
a = p.parse_args(sys.argv[sys.argv.index('--')+1:])
assert not a.output.exists()
sha = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
assert sha(a.pivot) == 'cd5f57f327395a2ee4cfc81716a5e2fe8ef8fe93ec45ec13203c94cc76e16f86'
surface = json.loads((HERE/'working-surface-selection.json').read_text())
hinge = json.loads((HERE/'upper-body-hinge-selection.json').read_text())
pivot = json.loads(a.pivot.read_text())
motions = {'baseline': CompleteReturnMotion(surface, hinge, pivot),
           'candidate': LoopFlowMotion(surface, hinge, pivot, a.round_start, a.round_end,a.outward_load)}
if a.side_return:
    from side_return_motion import SideReturnMotion
    motions['candidate']=SideReturnMotion(surface,hinge,pivot)
report = {'complete':False, 'rendered':False, 'visual_accepted':False,
          'scope':'Worn/up kinematics only; no actual mesh, collision or temporal visual acceptance',
          'selection':motions['candidate'].selection(), 'inputs':{str(a.pivot):sha(a.pivot),str(a.recorded):sha(a.recorded)},
          'source_hashes':{str(path.relative_to(ROOT)):sha(path) for path in
                           (Path(__file__), HERE/'loop_flow_motion.py', HERE/'complete_return_motion.py')},
          'frames':[], 'dense':[], 'seams':[]}
if a.side_return:
    report['source_hashes']['tools/native_motion_ingame_pilot/side_return_motion.py']=sha(HERE/'side_return_motion.py')


def features(pose):
    frame = pm.tool_frame(pose['axis'], pose['tool_normal'])
    return {'rear':pose['rear'], 'cap':pose['rear'] + frame@motions['baseline'].local_cap,
            'grip_R':pose['grips']['R'], 'grip_L':pose['grips']['L']}


def project(point, angle):
    target = Vector((0.,-.10,.98))
    camera = target + Matrix.Rotation(math.radians(angle),3,'Z')@(Vector((6.,6.,7.))-target)
    rotation = (target-camera).to_track_quat('-Z','Y')
    point = rotation.inverted()@(point-camera)
    return Vector(((.5+point.x/2.9)*160.,(.5-point.y/2.9)*160.))


def compare(q):
    poses = {k:m.sample('mine',q) for k,m in motions.items()}
    points = {k:features(v) for k,v in poses.items()}
    body_error = max(abs(poses['baseline'][n][i][j]-poses['candidate'][n][i][j])
                    for n in ('torso','head') for i in range(4) for j in range(4))
    protected = max((poses['baseline']['legs'][s][i]-poses['candidate']['legs'][s][i]).length
                                  for s in ('R','L') for i in range(3))
    if not a.side_return or .30<=q%1.<=.70: assert body_error<1e-6
    if a.side_return:
        joint=motions['candidate'].body_joint
        assert ((poses['baseline']['torso']@joint)-(poses['candidate']['torso']@joint)).length<1e-6
    reach = max((wrist-shoulder).length for shoulder,elbow,wrist in poses['candidate']['arms'].values())
    grip_span = (poses['candidate']['grips']['R']-poses['candidate']['grips']['L']).length
    assert protected < 1e-6 and reach < .70999 and abs(grip_span-.145)<1e-6
    if (.55 if a.outward_load or a.side_return else a.round_end) <= q%1. <= a.round_start:
        assert max((points['baseline'][k]-points['candidate'][k]).length for k in points['baseline']) == 0.
    return {'phase':q,'maximum_reach':reach,'protected_error':protected,'intentional_body_matrix_difference':body_error,
            'points':{k:{n:list(v) for n,v in values.items()} for k,values in points.items()},
            'projected':{str(angle):{k:{n:list(project(v,angle)) for n,v in values.items()}
                                     for k,values in points.items()} for angle in (0,25)}}


try:
    for index in range(401):
        report['dense'].append(compare(native_phase(index/400.)))
    recorded = json.loads(a.recorded.read_text())
    for index in range(60,84):
        q = recorded['samples'][index]['visual']['sample_phase']
        row = compare(q)
        row.update(video_frame=index,video_time=index/60.)
        report['frames'].append(row)
    for boundary in (motions['candidate'].round_start_progress,1.,1.+motions['candidate'].round_end_progress):
        for h in (.001,.0005):
            samples = [features(motions['candidate'].sample('mine',native_phase((boundary+dt/CYCLE_SECONDS)%1.)))
                       for dt in (-h,0.,h)]
            report['seams'].append({'game_progress':boundary,'step_seconds':h,
                'left_velocity':{k:list((samples[1][k]-samples[0][k])/h) for k in samples[0]},
                'right_velocity':{k:list((samples[2][k]-samples[1][k])/h) for k in samples[0]}})
    report['complete'] = True
finally:
    a.output.parent.mkdir(parents=True,exist_ok=True)
    a.output.write_text(json.dumps(report,indent=2)+'\n')
print('LOOP_FLOW_KINEMATICS',len(report['dense']),len(report['frames']),flush=True)
