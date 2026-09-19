"""One read-only swing/twist decomposition of the frozen16H rejection."""
from pathlib import Path
import hashlib,json,math
import numpy as np
from scipy.spatial.transform import Rotation

OUT=Path(__file__).resolve().parent
SRC=Path('/tmp/pivot-return-16H-independent')
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(SRC/'analytic-report.json')=='f8ff91bdf766304045f6ba8f3a072e0230c5d0a73e125edbc3800174981e5121'
assert sha(SRC/'manifest.json')=='e3d380149b1e0a19b7908fcaab51e8c3aa761f82647799a7b1e9f8fa2da5fa5e'
report=json.loads((SRC/'analytic-report.json').read_text())
meta=json.loads((SRC/'analytic-export.json').read_text())
d=np.load(SRC/'analytic-kinematics.npz');f=np.load(SRC/'analytic-frames-and-rates.npz')
phase=d['phases'];times=d['times'];unit=lambda a:a/np.linalg.norm(a,axis=-1,keepdims=True)

def shortest(a,b):
    v=np.cross(a,b);den=1.+np.sum(a*b,axis=1)
    assert den.min()>.05
    K=np.zeros((len(a),3,3));K[:,0,1]=-v[:,2];K[:,0,2]=v[:,1];K[:,1,0]=v[:,2];K[:,1,2]=-v[:,0];K[:,2,0]=-v[:,1];K[:,2,1]=v[:,0]
    return np.eye(3)+K+K@K/den[:,None,None]

def timing(i,j):
    return dict(samples=[int(i),int(j)],phases=[float(phase[i]),float(phase[j])],cycle_seconds=[float(times[i]),float(times[j])])

out=dict(complete=False,candidate_sha256=report['candidate_sha256'],frozen_analytic_report_sha256=sha(SRC/'analytic-report.json'),frozen_manifest_sha256=sha(SRC/'manifest.json'),data_sha256=sha(SRC/'analytic-kinematics.npz'),frames_sha256=sha(SRC/'analytic-frames-and-rates.npz'),script_sha256=sha(__file__),method='For each exact sampled time pair: total R=F1 F0^T. Minimal swing S maps actual segment axis a0 to a1. Residual twist is R S^T about a1. SO(3) projection removes exported float roundoff. Direction and twist angles are not additive; total full-frame gates stay unchanged.',new_parameter_trials=0,engine_used=False,bones={})
for bone,side,joint0,joint1 in [('lower.L',1,1,2),('lower.R',0,1,2),('upper.R',0,0,1)]:
    axes=unit(d['new_arms'][:,side,joint1]-d['new_arms'][:,side,joint0])
    rest=unit(np.array(meta['rest_axes'][bone]));den=1+axes@rest;k=int(np.argmin(den))
    raw=f['new_'+bone];u,_,vt=np.linalg.svd(raw);frames=u@vt
    assert np.max(abs(frames-raw))<1e-5 and np.linalg.det(frames).min()>.999999
    one=dict(absolute_rest_denominator_minimum=dict(value=float(den[k]),phase=float(phase[k]),sample=k),absolute_rest_map_used=(bone!='lower.R'),rates={})
    for hz in (60,120,1200):
        clock=sorted(set(min(meta['cycle_seconds'],i/hz) for i in range(math.ceil(meta['cycle_seconds']*hz)+1)))
        ids=np.array([int(np.argmin(abs(times-t))) for t in clock]);assert np.max(abs(times[ids]-clock))<1e-12
        a,b=axes[ids[:-1]],axes[ids[1:]]
        R=frames[ids[1:]]@frames[ids[:-1]].transpose(0,2,1)
        S=shortest(a,b);twist=R@S.transpose(0,2,1)
        full=np.degrees(Rotation.from_matrix(R).magnitude())
        direction=np.degrees(np.arccos(np.clip(np.sum(a*b,axis=1),-1,1)))
        rv=Rotation.from_matrix(twist).as_rotvec();twist_degrees=np.degrees(np.linalg.norm(rv,axis=1));signed=np.degrees(np.sum(rv*b,axis=1))
        index=int(np.argmax(full));axis_index=int(np.argmax(direction));twist_index=int(np.argmax(twist_degrees))
        cap=report['rotation_caps'][str(hz)][bone]['control_max_step_degrees']
        assert abs(full[index]-report['rotation_caps'][str(hz)][bone]['candidate_max_step_degrees'])<1e-4
        def details(k):
            return dict(**timing(ids[k],ids[k+1]),full_degrees=float(full[k]),axis_degrees=float(direction[k]),residual_twist_degrees=float(twist_degrees[k]),signed_residual_twist_degrees=float(signed[k]),absolute_rest_denominators=[float(den[ids[k]]),float(den[ids[k+1]])])
        one['rates'][str(hz)]=dict(original_full_rotation_cap_degrees=cap,full_peak=details(index),axis_peak=details(axis_index),twist_peak=details(twist_index),axis_maximum_exceeds_full_cap=bool(direction.max()>cap+1e-5),maximum_residual_axis_error=float(np.linalg.norm(np.einsum('nij,nj->ni',twist,b)-b,axis=1).max()))
    out['bones'][bone]=one
out['complete']=True
(OUT/'frame-diagnosis.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps(out,indent=2))
