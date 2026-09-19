"""16J: one baseline-orientation translation solve with visible head clearance.

16I passed arm motion but hid the pick against the hero. Remove the extra
16G tool/body turns: baseline15 already clears the ore after phase.21.
Reuse the four stable original-arm transports, now with no extra torso turn.
Constrain the whole head outside the ore envelope AND the main body/head
occluders, rather than asking rendered previews to discover overlap again.
"""
from pathlib import Path
setup=Path('/tmp/pivot-return-16H-plan/fit_translation.py')
code=setup.read_text().split('result=minimize')[0]
needle="d=np.load(SRC/'analytic-kinematics.npz')"
replacement=needle+"\nd={key:d[key] for key in d.files}\nfor key in list(d):\n if key.startswith('new_') and 'old_'+key[4:] in d:d[key]=d['old_'+key[4:]].copy()\nd['body_yaws']=np.zeros_like(d['body_yaws'])\nd['turn_angles']=np.zeros_like(d['turn_angles'])"
assert needle in code
exec(compile(code.replace(needle,replacement,1),str(setup),'exec'))
OUT=Path('/tmp/pivot-return-16J-plan')
# Choose ore support planes from the previously clear left-withdrawal side.
# The old25px path is only a topological guide, never an accepted candidate.
def smoother(x):return x*x*x*(10+x*(-15+6*x))
q=phases
guide=np.where((q<=.08)|(q>=.86),1.,np.where(q<.30,1-smoother(np.clip((q-.08)/.22,0,1)),np.where(q>.625,smoother(np.clip((q-.625)/.235,0,1)),0.)))
ore_edges=np.roll(ore,-1,axis=0)-ore
ore_normals=np.stack([ore_edges[:,1],-ore_edges[:,0]],axis=1)
ore_normals/=np.linalg.norm(ore_normals,axis=1)[:,None]
trial=head_uv+np.stack([-25*guide,np.zeros(N)],axis=1)[:,None]
gaps=np.min(np.einsum('nvi,ki->nvk',trial,ore_normals),axis=1)-np.max(ore@ore_normals.T,axis=0)
normals=ore_normals[np.argmax(gaps,axis=1)]
required=margin+np.max(normals@ore.T,axis=1)-np.min(np.sum(head_uv*normals[:,None],axis=2),axis=1)
normal3=normals@P
Aore=np.einsum('ni,nj->nij',B[guard],normal3[guard]).reshape((-1,nf*3))
lore=required[guard]+1e-4

# These bounding boxes come from the evaluated baseline native meshes.
# They cover the large occluders implicated by the actual16I preview.
# Arms deliberately remain in the subsequent actual rendered visual gate.
body_names=['coat body','coat lower hem','leather backpack','backpack lid',
 'rolled blanket','neck','iron dome','helmet broad rim','helmet visor edge',
 'v17 unified expressive face','v17 rounded jaw beard','v26 swept short hair fibers',
 'lamp bracket','lamp bezel','convex amber lens','v24 rounded brow frame -1',
 'v24 rounded brow frame 1','v24 curved spectacle arm -1','v24 curved spectacle arm 1']
native=json.loads(Path('/tmp/pivot-return-16G-native/native-report.json').read_text())
body_constraints=[];body_rows=[]
for r in native['route']:
 q=r['phase']
 if r['state']!='mine' or not(q>=.72 or q<=curve16G['end_phase']):continue
 objects=r['baseline_framing']['objects']
 corners=[]
 for name in body_names:
  lo,hi=np.array(objects[name]);corners.extend([[lo[0],lo[1]],[lo[0],hi[1]],[hi[0],lo[1]],[hi[0],hi[1]]])
 corners=np.array(corners);body_hull=corners[ConvexHull(corners).vertices]
 head_original=projections['old'][r['frame']]
 edges=np.roll(body_hull,-1,axis=0)-body_hull
 normals_body=np.stack([edges[:,1],-edges[:,0]],axis=1)
 normals_body/=np.linalg.norm(normals_body,axis=1)[:,None]
 sep=np.min(head_original@normals_body.T,axis=0)-np.max(body_hull@normals_body.T,axis=0)
 nb=normals_body[np.argmax(sep)]
 rhs=2.+np.max(body_hull@nb)-np.min(head_original@nb)
 seconds=.68*(q/.55*.42 if q<=.55 else .42+(q-.55)/.45*.58)
 if q<curve16G['end_phase']:seconds+=.68
 bb=basis(np.clip((seconds-start)/duration,0,1))[free]
 body_constraints.append((np.outer(bb,nb@P).ravel(),rhs+1e-4))
 body_rows.append(dict(frame=r['frame'],phase=q,normal=nb.tolist(),required=rhs,
                       baseline_separation=float(np.max(sep)),occluder_hull=body_hull.tolist()))
Abody=np.array([row[0] for row in body_constraints]);lbody=np.array([row[1] for row in body_constraints])
A=np.concatenate([Aore,Abody]);low=np.r_[lore,lbody]

# Reuse the independently checked complete-frame kinematics and unchanged
# speed limits from16I. This does not run that prior solve a second time.
prior=Path('/tmp/pivot-return-16I-plan/fit_full_arm_translation.py')
definitions=prior.read_text().split('from scipy.spatial.transform import Rotation',1)[1].split('result=minimize',1)[0]
definitions='from scipy.spatial.transform import Rotation'+definitions
definitions=definitions.replace("OUT=Path('/tmp/pivot-return-16I-plan')","OUT=Path('/tmp/pivot-return-16J-plan')")
exec(compile(definitions,str(prior),'exec'))
x0=np.zeros(nf*3)
result=minimize(lambda x:float(.5*x@H3@x+lin@x),x0,
 jac=lambda x:H3@x+lin,method='SLSQP',
 constraints=[LinearConstraint(A,low,np.inf),{'type':'ineq','fun':movement_constraints}],
 callback=progress,options={'maxiter':150,'ftol':1e-10})
co=np.zeros((nc,3));co[free]=result.x.reshape(nf,3)
frames,rho,den,length=arms_and_frames(result.x);delta=B@co[free]
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
 rotation_caps_active_interval=caps_report,body_clearance_rows=body_rows,
 body_occluder_names=body_names,body_clearance_pixels=2.,
 tool_angle_radians=0.,body_yaw_radians=0.,
 prior_visual_report_sha256=hashlib.sha256(Path('/tmp/pivot-return-16I-visual-review/visual-report.json').read_bytes()).hexdigest(),
 native_occluder_source_sha256=hashlib.sha256(Path('/tmp/pivot-return-16G-native/native-report.json').read_bytes()).hexdigest(),
 projection_calibration_error_px=calibration,
 limitations='One deterministic constrained solve. Bounding-box silhouettes cover specified main occluders at recorded poses only. Arms, rendered recognition and actual gameplay remain unverified.')
(OUT/'translation-fit.json').write_text(json.dumps(report,indent=2)+'\n')
np.savez_compressed(OUT/'translation-fit-data.npz',translation=delta,frames=frames,times=times,phases=phases)
print(json.dumps({k:v for k,v in report.items() if k not in ('coefficients','spline_knots','ore_hull_relative','method','body_clearance_rows')},indent=2),flush=True)
