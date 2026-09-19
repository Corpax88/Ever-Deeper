"""Analytic reach diagnosis, not a new motion candidate or visual acceptance."""
import hashlib,json,math
from pathlib import Path
import numpy as np
from scipy.interpolate import BSpline
from scipy.spatial.transform import Rotation
OUT=Path('/tmp/pivot-return-16E-plan');SRC=Path('/tmp/pivot-return-16C-independent');FIT=Path('/tmp/pivot-return-16D-plan/curve-report.json')
r=json.loads(FIT.read_text());d=np.load(SRC/'analytic-kinematics.npz');q=d['phases']%1
seconds=np.where(q<=.55,q/.55*.42,.42+(q-.55)/.45*.58)*.68
seconds=np.where(q<r['end_phase'],seconds+.68,seconds)
u=(seconds-r['interval_seconds'][0])/(r['interval_seconds'][1]-r['interval_seconds'][0])
angle=np.zeros(len(q));active=(q<r['end_phase'])|(q>.625)
curve=BSpline(r['knots'],r['coefficients'],r['degree']);angle[active]=curve(u[active])
fwd=np.array([-6.,-6.1,-6.02]);fwd/=np.linalg.norm(fwd);rot=Rotation.from_rotvec(angle[:,None]*fwd).as_matrix()
wrists=d['old_rear'][:,None]+np.einsum('nij,nsj->nsi',rot,d['old_arms'][:,:,2]-d['old_rear'][:,None])
local=np.array([0.,0.,.5849999785423279,1.]);joint=np.einsum('nij,j->ni',d['old_body'][:,0],local)[:,:3]
shoulders=d['old_arms'][:,:,0];reach=.699
# Intersect exact cosine inequalities within a single anatomical yaw range.
def intersect(a,b):return [(max(x,u),min(y,v)) for x,y in a for u,v in b if max(x,u)<=min(y,v)]
def feasible(a,b,c):
 radius=math.hypot(a,b)
 if c>radius:return []
 if c<=-radius:return [(-math.pi/2,math.pi/2)]
 center=math.atan2(b,a);span=math.acos(c/radius)
 return intersect([(-math.pi/2,math.pi/2)],[(center-span+2*k*math.pi,center+span+2*k*math.pi) for k in (-1,0,1)])
rows=[]
for i in range(len(q)):
 vals=[(-math.pi/2,math.pi/2)]
 for j in (0,1):
  s=shoulders[i,j]-joint[i];v=wrists[i,j]-joint[i]
  a=np.dot(s[:2],v[:2]);b=-s[1]*v[0]+s[0]*v[1];c=(np.dot(s,s)+np.dot(v,v)-reach**2)/2-s[2]*v[2]
  vals=intersect(vals,feasible(a,b,c))
 nearest=min((min(max(0.,lo),hi) for lo,hi in vals),key=abs) if vals else None
 rows.append(dict(sample=i,phase=float(q[i]),tool_angle_degrees=float(np.degrees(angle[i])),yaw_intervals_degrees=[[math.degrees(a),math.degrees(b)] for a,b in vals],nearest_zero_degrees=math.degrees(nearest) if nearest is not None else None))
report=dict(complete=True,diagnosis_only=True,passed_geometry=False,rendered=False,fit_sha256=hashlib.sha256(FIT.read_bytes()).hexdigest(),baseline_data_sha256=hashlib.sha256((SRC/'analytic-kinematics.npz').read_bytes()).hexdigest(),world_axis=[0,0,1],pivot_local=local[:3].tolist(),reach_limit=reach,samples=len(rows),infeasible_samples=sum(not x['yaw_intervals_degrees'] for x in rows),largest_nearest_zero_degrees=max((abs(x['nearest_zero_degrees']) for x in rows if x['nearest_zero_degrees'] is not None),default=0),rows=rows)
(OUT/'body-corridor.json').write_text(json.dumps(report,indent=2)+'\n')
np.savez_compressed(OUT/'diagnostic-geometry.npz',phases=q,wrists=wrists,joint=joint,shoulders=shoulders,angles=angle)
print(json.dumps({k:v for k,v in report.items() if k!='rows'},indent=2))
print('INFEASIBLE_EXAMPLES',json.dumps([x for x in rows if not x['yaw_intervals_degrees']][:5]))
print('PHASE_ZERO',json.dumps(rows[0]))
