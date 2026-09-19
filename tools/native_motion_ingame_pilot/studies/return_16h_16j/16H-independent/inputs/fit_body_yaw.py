"""One convex torso-yaw fit; exact sampled reach and full-body rotation bounds."""
import hashlib,json,math
from pathlib import Path
import numpy as np
from scipy.interpolate import BSpline
from scipy.optimize import linprog,minimize,LinearConstraint
from scipy.spatial.transform import Rotation
OUT=Path('/tmp/pivot-return-16E-plan');SRC=Path('/tmp/pivot-return-16C-independent')
d=np.load(SRC/'analytic-kinematics.npz');meta=json.loads((SRC/'analytic-export.json').read_text())
tool=json.loads(Path('/tmp/pivot-return-16D-plan/curve-report.json').read_text());corridor=json.loads((OUT/'body-corridor.json').read_text())
assert corridor['infeasible_samples']==0 and all(len(r['yaw_intervals_degrees'])==1 for r in corridor['rows'])
q=d['phases']%1;times=d['times'];N=meta['regular_time_samples'];start,end=tool['interval_seconds'];duration=end-start
seconds=np.where(q<=.55,q/.55*.42,.42+(q-.55)/.45*.58)*.68;seconds=np.where(q<tool['end_phase'],seconds+.68,seconds)
active=(q<tool['end_phase'])|(q>.625);u=(seconds-start)/duration
knots=np.array(tool['knots']);degree=5;ncoeff=len(knots)-degree-1;free=np.arange(3,ncoeff-3);basis=BSpline(knots,np.eye(ncoeff),degree)
B=np.zeros((len(q),len(free)));B[active]=basis(u[active])[:,free]
limits=np.radians(np.array([r['yaw_intervals_degrees'][0] for r in corridor['rows']]))
As=[B[active]];los=[limits[active,0]+1e-7];his=[limits[active,1]-1e-7]
body=d['old_body'][:N,0,:3,:3];caps={}
# trace(Rz(phi_j) R_j R_i^T Rz(-phi_i)) equals
# trace(Rz(phi_j-phi_i) R_j R_i^T). Its quaternion scalar part is
# old_w*cos(delta/2)-old_z*sin(delta/2), so the exact angular cap gives
# one linear interval on delta=phi_j-phi_i around the baseline branch.
for hz in (60,120,1200):
 clock=sorted(set(min(.68,i/hz) for i in range(math.ceil(.68*hz)+1)))
 ids=np.array([int(np.argmin(abs(times-t))) for t in clock]);assert np.max(abs(times[ids]-clock))<1e-12
 rel=body[ids[1:]]@np.swapaxes(body[ids[:-1]],1,2);rotation=Rotation.from_matrix(rel)
 cap=float(rotation.magnitude().max());quat=rotation.as_quat();quat=np.where(quat[:,3:4]<0,-quat,quat)
 a,b=quat[:,3],-quat[:,2];radius=np.hypot(a,b);center=np.arctan2(b,a);threshold=np.cos((cap+1e-8)/2)
 assert (radius>=threshold-1e-12).all()
 span=np.arccos(np.clip(threshold/radius,-1,1));lo=2*(center-span);hi=2*(center+span)
 As.append(B[ids[1:]]-B[ids[:-1]]);los.append(lo);his.append(hi);caps[str(hz)]=math.degrees(cap)
A=np.concatenate(As);lo=np.concatenate(los);hi=np.concatenate(his)
dt=np.diff(times[:N]);mid=(times[:N-1]+times[1:N])/2;unwrapped=np.where(mid<end-.68,mid+.68,mid);inside=(unwrapped>start)&(unwrapped<end)
omega=Rotation.from_matrix(body[1:]@np.swapaxes(body[:-1],1,2)).as_rotvec()/dt[:,None]
mu=(unwrapped[inside]-start)/duration;B1=basis(mu,1)[:,free]/duration;B2=basis(mu,2)[:,free]/duration**2;w=dt[inside];tau=1/60
H=B1.T@(w[:,None]*B1)+tau**2*B2.T@(w[:,None]*B2);f=B1.T@(w*omega[inside,2]);scale=np.linalg.eigvalsh(H).max();H/=scale;f/=scale
lp=linprog(np.zeros(len(free)),A_ub=np.r_[-A,A],b_ub=np.r_[-lo,hi],bounds=[(-math.pi/2,math.pi/2)]*len(free),method='highs')
r=dict(complete=False,passed_fit=False,passed_geometry=False,rendered=False,method=__doc__,degree=degree,knots=knots.tolist(),interval_seconds=[start,end],start_phase=.625,end_phase=tool['end_phase'],pivot_local=corridor['pivot_local'],world_axis=[0,0,1],reach_limit=corridor['reach_limit'],original_body_maximum_steps_degrees=caps,linear_constraints=len(lo),linear_feasibility=dict(success=bool(lp.success),message=str(lp.message)),tool_curve_sha256=hashlib.sha256(Path('/tmp/pivot-return-16D-plan/curve-report.json').read_bytes()).hexdigest(),corridor_sha256=hashlib.sha256((OUT/'body-corridor.json').read_bytes()).hexdigest())
def save():(OUT/'body-curve-report.json').write_text(json.dumps(r,indent=2)+'\n')
save()
if not lp.success:raise SystemExit('No feasible body curve with original full-rotation limits; stop, no retry')
fit=minimize(lambda x:float(x@H@x/2+f@x),lp.x,jac=lambda x:H@x+f,method='SLSQP',bounds=[(-math.pi/2,math.pi/2)]*len(free),constraints=LinearConstraint(A,lo,hi),options=dict(maxiter=300,ftol=1e-11))
co=np.zeros(ncoeff);co[free]=fit.x;margin=float(min((A@fit.x-lo).min(),(hi-A@fit.x).min()))
r.update(complete=True,passed_fit=bool(fit.success and margin>=-1e-7),iterations=int(fit.nit),message=str(fit.message),coefficients=co.tolist(),minimum_constraint_margin=margin,maximum_absolute_yaw_degrees=float(np.degrees(abs(B@fit.x)).max()),objective='Integral of squared actual torso angular velocity plus (1/60s)^2 times squared correction angular acceleration. Same original full-matrix torso angular-step caps at60/120/1200Hz.')
save();print(json.dumps(r,indent=2))
