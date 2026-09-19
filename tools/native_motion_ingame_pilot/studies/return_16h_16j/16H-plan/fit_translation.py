"""One whole-return hand-translation solve; fixed16G tool and torso curves.

The fixed-grip angular corridor splits during lift. Add three-dimensional
translation of both hands as one rigid unit instead. Use fixed30Hz degree5
splines, zero endpoint value/velocity/acceleration, the full .91--1.035 ore
envelope, and the complete return/lift. This is a geometric candidate fit,
not native rig or visual acceptance. No parameter/seed sweep.
"""
import hashlib,json,math
from pathlib import Path
import numpy as np
from scipy.interpolate import BSpline
from scipy.spatial import ConvexHull
from scipy.optimize import minimize,LinearConstraint

OUT=Path('/tmp/pivot-return-16H-plan')
SRC=Path('/tmp/pivot-return-16G-independent')
d=np.load(SRC/'analytic-kinematics.npz')
meta=json.loads((SRC/'analytic-export.json').read_text())
record=json.loads(Path('/tmp/ever-deeper-loop-flow-20260919/pivot-game-16G/native-ingame.json').read_text())
projections=np.load('/tmp/pivot-return-16G-native/evaluated-head-projections.npz')
corridor=json.loads((OUT/'complete-return-corridor.json').read_text())
fwd=np.array([-6.,-6.1,-6.02]);fwd/=np.linalg.norm(fwd)
right=np.cross(fwd,[0,0,1]);right/=np.linalg.norm(right)
up=np.cross(right,fwd);P=np.stack((right,-up))*160/2.9
eye=np.array([6.,6.,7.])
# Reconstruct the rigid local head from several independently evaluated
# baseline projections; validate every exactly matched pose, not just a tip.
AA=[];BB=[];matches=[]
for f,s in enumerate(record['samples']):
 v=s['visual']
 if v['state']!='mine':continue
 i=int(np.argmin(abs(d['phases']-v['sample_phase'])))
 if abs(d['phases'][i]-v['sample_phase'])>1e-12:continue
 AA.append(P@d['old_tool'][i])
 BB.append((projections['old'][f]-80.-P@(d['old_rear'][i]-eye)).T)
 matches.append((f,i))
AA=np.concatenate(AA);BB=np.concatenate(BB)
local=np.linalg.lstsq(AA,BB,rcond=None)[0].T
calibration=float(np.max(np.abs(AA@local.T-BB)))
assert calibration<1e-4,calibration
local_hull=local[ConvexHull(local).vertices]
N=meta['regular_time_samples'];times=d['times'];phases=d['phases'][:N]%1
frame=d['new_tool'][:N];rear=d['new_rear'][:N]
head=np.einsum('nij,vj->nvi',frame,local_hull)+rear[:,None]
head_uv=80.+np.einsum('ij,nvj->nvi',P,head-eye)
center_uv=80.+np.einsum('ij,nj->ni',P,np.einsum('nij,j->ni',frame,local.mean(0))+rear-eye)
relative_roots=[]
for row in corridor['rows']:
 hr=record['samples'][row['frame']]['framing']['subjects']['hero_and_tool']
 assert hr[2:]==[160.,160.]
 relative_roots.append(np.array(row['resource_root'])-hr[:2])
allore=np.concatenate([np.array(corridor['ore_hull_local'])+p for p in relative_roots])
ore=allore[ConvexHull(allore).vertices]
normals=center_uv-ore.mean(0)
normals/=np.linalg.norm(normals,axis=1)[:,None]
margin=2.
required=margin+np.max(normals@ore.T,axis=1)-np.min(np.sum(head_uv*normals[:,None],axis=2),axis=1)

curve16G=json.loads(Path('/tmp/pivot-return-16D-plan/curve-report.json').read_text())
knots=np.array(curve16G['knots']);degree=curve16G['degree'];nc=len(knots)-degree-1
free=np.arange(3,nc-3);nf=len(free)
start,end=curve16G['interval_seconds'];duration=end-start
ts=np.where(times<end-.68,times+.68,times)
active=(ts>start)&(ts<end)
u=np.clip((ts-start)/duration,0,1)
basis=BSpline(knots,np.eye(nc),degree)
B=basis(u)[:,free];B[~active]=0.
V=basis(u,1)[:,free]/duration;V[~active]=0.
Acc=basis(u,2)[:,free]/duration**2;Acc[~active]=0.
guard=(phases>=.72)|(phases<=curve16G['end_phase'])
normal3=normals@P
A=np.einsum('ni,nj->nij',B[guard],normal3[guard]).reshape((-1,nf*3))
low=required[guard]+1e-4
# Zero translation can legitimately remain if already separated. A smooth
# minimum-displacement curve needs no arbitrary seed amplitude or angle.
dt=np.gradient(times)
tau=1/30.
H=B.T@(dt[:,None]*B)+tau**2*V.T@(dt[:,None]*V)+tau**4*Acc.T@(dt[:,None]*Acc)
H/=np.linalg.eigvalsh(H).max()
H3=np.kron(H,np.eye(3))
wrists=d['new_arms'][:N,:,2];shoulders=d['new_arms'][:N,:,0]
reach=.699
def reach_constraints(x):
 delta=B@x.reshape(nf,3)
 diff=wrists+delta[:,None]-shoulders
 return (reach**2-np.sum(diff*diff,axis=2)).ravel()
def reach_jac(x):
 delta=B@x.reshape(nf,3)
 diff=wrists+delta[:,None]-shoulders
 return (-2*np.einsum('ni,nsj->nsij',B,diff)).reshape((-1,nf*3))
result=minimize(lambda x:float(.5*x@H3@x),np.zeros(nf*3),
 jac=lambda x:H3@x,method='SLSQP',
 constraints=[LinearConstraint(A,low,np.inf),{'type':'ineq','fun':reach_constraints,'jac':reach_jac}],
 options={'maxiter':200,'ftol':1e-10})
co=np.zeros((nc,3));co[free]=result.x.reshape(nf,3)
delta=B@co[free]
linear_margin=float(np.min(A@result.x-low));reach_margin=float(np.min(reach_constraints(result.x)))
passed=bool(result.success and linear_margin>=-1e-7 and reach_margin>=-1e-7)
report=dict(complete=True,passed_fit=passed,passed_geometry=False,visual_accepted=False,rendered=False,
 method=__doc__,iterations=int(result.nit),message=str(result.message),
 spline_degree=degree,spline_knots=knots.tolist(),coefficients=co.tolist(),
 seconds=[start,end],end_phase=curve16G['end_phase'],clearance_start_phase=.72,
 minimum_separation_margin=linear_margin,minimum_squared_reach_margin=reach_margin,
 maximum_translation_native=float(np.linalg.norm(delta,axis=1).max()),
 maximum_translation_px=float(np.linalg.norm(delta@P.T,axis=1).max()),
 maximum_reach=float(np.linalg.norm(wrists+delta[:,None]-shoulders,axis=2).max()),
 projection_calibration_error_px=calibration,projection_calibration_poses=len(matches),
 baseline_projection_sha256=hashlib.sha256(Path('/tmp/pivot-return-16G-native/evaluated-head-projections.npz').read_bytes()).hexdigest(),
 fixed_animation_sha256=hashlib.sha256(Path('/workspace/scratch/eb19e34b942d/ever-deeper/tools/native_motion_ingame_pilot/pivot_return_motion.py').read_bytes()).hexdigest(),
 projection=P.tolist(),ore_hull_relative=ore.tolist(),samples=N,guard_samples=int(guard.sum()),
 limitations='Discrete1200Hz geometric constraints only. Full-bone temporal guards, evaluated native geometry, visibility and actual game capture are still required.')
(OUT/'translation-fit.json').write_text(json.dumps(report,indent=2)+'\n')
np.savez_compressed(OUT/'translation-fit-data.npz',local_head=local,ore=ore,times=times,phases=phases,translation=delta,normals=normals,required=required,guard=guard)
print(json.dumps({k:v for k,v in report.items() if k not in ('coefficients','spline_knots','ore_hull_relative','method')},indent=2))
