"""One revised16I solve after the frozen16H axis/twist diagnosis.

Carry all original arm frames with the torso and shortest axis alignment.
Retain the rigid whole-return translation family, but constrain its actual
complete arm rotations at60/120/1200Hz inside the original baseline bounds.
Minimize complete wrist path velocity and acceleration, not just the size
of the correction, which compressed the previous lift in time.
"""
from pathlib import Path
setup=Path('/tmp/pivot-return-16H-plan/fit_translation.py')
exec(compile(setup.read_text().split('result=minimize')[0],str(setup),'exec'))
from scipy.spatial.transform import Rotation

OUT=Path('/tmp/pivot-return-16I-plan')
baseline_report=json.loads(Path('/tmp/pivot-return-16H-independent/analytic-report.json').read_text())
prior_fit=json.loads(Path('/tmp/pivot-return-16H-plan/translation-fit.json').read_text())
unit=lambda x:x/np.linalg.norm(x,axis=-1,keepdims=True)

def shortest(a,b):
 a=unit(np.broadcast_to(a,b.shape));b=unit(b)
 cross=np.cross(a,b);den=1+np.sum(a*b,axis=-1)
 K=np.zeros((*b.shape[:-1],3,3))
 K[...,0,1]=-cross[...,2];K[...,0,2]=cross[...,1]
 K[...,1,0]=cross[...,2];K[...,1,2]=-cross[...,0]
 K[...,2,0]=-cross[...,1];K[...,2,1]=cross[...,0]
 return np.eye(3)+K+K@K/np.maximum(den,1e-12)[...,None,None],den

oldarms=d['old_arms'][:N]
oldaxes=np.stack([unit(oldarms[:,j,k+1]-oldarms[:,j,k])
                  for j,k in [(0,0),(0,1),(1,0),(1,1)]],axis=1)
names=['upper.R','lower.R','upper.L','lower.L']
oldframes=[]
for j,name in enumerate(names):
 if name=='lower.R':
  ax=oldaxes[:,j];radial=d['old_radials'][:N,0]
  radial=unit(radial-ax*np.sum(radial*ax,axis=1)[:,None])
  f=np.stack([ax,radial,np.cross(ax,radial)],axis=2)
 else:f=shortest(np.array(meta['rest_axes'][name]),oldaxes[:,j])[0]
 oldframes.append(f)
oldframes=np.stack(oldframes,axis=1)
body=Rotation.from_rotvec(np.c_[np.zeros(N),np.zeros(N),d['body_yaws'][:N]]).as_matrix()
refaxes=np.einsum('nij,nkj->nki',body,oldaxes)
refframes=body[:,None]@oldframes
local_joint=np.r_[meta['body_joint_local'],1.]
joint=np.einsum('nij,j->ni',d['old_body'][:N,0],local_joint)[:,:3]
reference=joint[:,None]+np.einsum('nij,nsj->nsi',body,oldarms[:,:,1]-joint[:,None])
pole=reference-shoulders

def arms_and_frames(x):
 delta=B@x.reshape(nf,3)
 w=wrists+delta[:,None];direction=w-shoulders
 length=np.linalg.norm(direction,axis=2);axis=direction/length[:,:,None]
 radial=pole-axis*np.sum(axis*pole,axis=2)[:,:,None]
 rho=np.linalg.norm(radial,axis=2)
 along=(.36**2-.35**2+length**2)/(2*length)
 height=np.sqrt(np.maximum(.36**2-along**2,1e-12))
 e=shoulders+axis*along[:,:,None]+radial/np.maximum(rho,1e-12)[:,:,None]*height[:,:,None]
 axes=np.stack([unit(e[:,0]-shoulders[:,0]),unit(w[:,0]-e[:,0]),
                unit(e[:,1]-shoulders[:,1]),unit(w[:,1]-e[:,1])],axis=1)
 align,den=shortest(refaxes,axes)
 frames=align@refframes
 frames[~active]=oldframes[~active]
 return frames,rho,den,length

steps=[]
for hz in (60,120,1200):
 clock=np.array(sorted(set(min(.68,j/hz) for j in range(math.ceil(.68*hz)+1))))
 ids=np.array([int(np.argmin(abs(times-t))) for t in clock])
 assert np.max(abs(times[ids]-clock))<1e-12
 relevant=active[ids[:-1]]|active[ids[1:]]
 i0,i1=ids[:-1][relevant],ids[1:][relevant]
 caps=np.radians([baseline_report['rotation_caps'][str(hz)][name]['control_max_step_degrees'] for name in names])
 # A0.01 degree/second internal guard absorbs float32 evaluation noise. This
 # tightens rather than changes the original independently enforced caps.
 cap_targets=caps-math.radians(.01)/hz
 steps.append((hz,i0,i1,cap_targets,1-np.cos(cap_targets)))

def movement_constraints(x):
 frames,rho,den,length=arms_and_frames(x)
 result=[]
 for hz,i0,i1,caps,scale in steps:
  cosine=(np.einsum('nkij,nkij->nk',frames[i0],frames[i1])-1)/2
  result.append(((cosine-np.cos(caps))/scale).ravel())
 result.extend([(rho[active]/.05-1).ravel(),(den[active]/.05-1).ravel(),
                (reach**2-length[active]**2).ravel(),(length[active]-.05).ravel()])
 return np.concatenate(result)

wmean=wrists.mean(axis=1)
wvelocity=np.gradient(wmean,times,axis=0)
wacceleration=np.gradient(wvelocity,times,axis=0)
tau=1/60.
H=V.T@(dt[:,None]*V)+tau**2*Acc.T@(dt[:,None]*Acc)
linear=V.T@(dt[:,None]*wvelocity)+tau**2*Acc.T@(dt[:,None]*wacceleration)
scale=np.linalg.eigvalsh(H).max();H/=scale;linear/=scale
H3=np.kron(H,np.eye(3));lin=linear.ravel()
x0=np.array(prior_fit['coefficients'])[free].ravel()
calls=0
def progress(x):
 global calls
 calls+=1
 if calls%10==0:print('16I_ITERATION',calls,'minimum_motion_constraint',float(movement_constraints(x).min()),flush=True)

result=minimize(lambda x:float(.5*x@H3@x+lin@x),x0,
 jac=lambda x:H3@x+lin,method='SLSQP',
 constraints=[LinearConstraint(A,low,np.inf),{'type':'ineq','fun':movement_constraints}],
 callback=progress,options={'maxiter':150,'ftol':1e-10})
co=np.zeros((nc,3));co[free]=result.x.reshape(nf,3)
frames,rho,den,length=arms_and_frames(result.x)
delta=B@co[free]
lm=float(np.min(A@result.x-low));mm=float(movement_constraints(result.x).min())
passed=bool(result.success and lm>=-1e-7 and mm>=-1e-7)
caps_report={}
for hz,i0,i1,caps,scale in steps:
 rel=np.swapaxes(frames[i0],2,3)@frames[i1]
 angles=np.degrees(Rotation.from_matrix(rel.reshape(-1,3,3)).magnitude()).reshape(-1,4)
 caps_report[str(hz)]={name:dict(maximum_degrees=float(angles[:,j].max()),
  baseline_cap_degrees=baseline_report['rotation_caps'][str(hz)][name]['control_max_step_degrees']) for j,name in enumerate(names)}
report=dict(complete=True,passed_fit=passed,passed_geometry=False,visual_accepted=False,rendered=False,
 method=__doc__,iterations=int(result.nit),message=str(result.message),
 spline_degree=degree,spline_knots=knots.tolist(),coefficients=co.tolist(),seconds=[start,end],
 end_phase=curve16G['end_phase'],clearance_start_phase=.72,
 minimum_separation_margin=lm,minimum_movement_constraint=mm,
 maximum_translation_native=float(np.linalg.norm(delta,axis=1).max()),
 maximum_translation_px=float(np.linalg.norm(delta@P.T,axis=1).max()),
 maximum_reach=float(length.max()),minimum_pole_projection=float(rho[active].min()),
 minimum_frame_transport_denominator=float(den[active].min()),
 projection=P.tolist(),ore_hull_relative=ore.tolist(),samples=N,guard_samples=int(guard.sum()),
 rotation_caps_active_interval=caps_report,
 prior_candidate_sha256=baseline_report['candidate_sha256'],
 prior_failure_report_sha256=hashlib.sha256(Path('/tmp/pivot-return-16H-independent/analytic-report.json').read_bytes()).hexdigest(),
 projection_calibration_error_px=calibration,
 limitations='One deterministic constrained solve. Native float32 implementation, full rig, contact, previews and actual gameplay still unverified.')
(OUT/'translation-fit.json').write_text(json.dumps(report,indent=2)+'\n')
np.savez_compressed(OUT/'translation-fit-data.npz',translation=delta,frames=frames,times=times,phases=phases)
print(json.dumps({k:v for k,v in report.items() if k not in ('coefficients','spline_knots','ore_hull_relative','method')},indent=2),flush=True)
