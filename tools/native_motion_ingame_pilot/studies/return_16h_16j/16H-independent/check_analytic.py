"""Independent16H full-frame gate; fixed G rotations plus declared translation.

All previous frame-rate, IK/pole and protected-pose limits remain unchanged.
The intentional rear translation is checked against an independent SciPy spline.
No rig application, rendering, solver or change to candidate code occurs here.
"""
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from scipy.spatial.transform import Rotation
from scipy.interpolate import BSpline
import ast

OUT = Path('/tmp/pivot-return-16H-independent')
ROOT = Path('/workspace/scratch/eb19e34b942d/ever-deeper')
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
meta = json.loads((OUT / 'analytic-export.json').read_text())
assert sha(OUT / 'analytic-kinematics.npz') == meta['data_sha256']
assert sha(meta['candidate_source_path']) == meta['candidate_sha256']
assert meta['candidate_sha256']=='b36388c96ac5ded535d88aff4bbb6bf07594cca39fb61e2de09a6cced4983993'
assert meta['frame_helper_sha256']==sha(OUT/'inputs'/'transported_forearm_frame_pose.py')=='5958d0561396daf2abcc2e28c81e75c3132b1dfc03f0b48aceb9e2892f9b4477'
d = np.load(OUT / 'analytic-kinematics.npz')
phase, times, weights = d['phases'], d['times'], d['weights']
N = meta['regular_time_samples']
unit = lambda x: x / np.linalg.norm(x, axis=-1, keepdims=True)

# Independently reconstruct every exported scalar/vector curve from fit data.
# Read candidate constants through AST; do not import the implementation.
tree=ast.parse(Path(meta['candidate_source_path']).read_text())
cls=next(n for n in tree.body if isinstance(n,ast.ClassDef) and n.name=='PivotReturnMotion')
constants={n.targets[0].id:ast.literal_eval(n.value) for n in cls.body if isinstance(n,ast.Assign)}
fit=json.loads((OUT/'inputs'/'translation-fit.json').read_text())
angle_fit=json.loads((OUT/'inputs'/'curve-report.json').read_text())
body_fit=json.loads((OUT/'inputs'/'body-curve-report.json').read_text())
assert sha(OUT/'inputs'/'translation-fit.json')==constants['TRANSLATION_FIT_SHA256']==meta['selection']['translation_fit_sha256']
assert sha(OUT/'inputs'/'curve-report.json')==constants['FIT_SHA256']==meta['fit_sha256']
assert sha(OUT/'inputs'/'body-curve-report.json')==constants['BODY_FIT_SHA256']==meta['body_fit_sha256']
assert constants['DEGREE']==fit['spline_degree']==angle_fit['degree']==5
assert np.array_equal(constants['KNOTS'],fit['spline_knots'])
assert np.array_equal(constants['TRANSLATION_COEFFICIENTS'],fit['coefficients'])
assert np.array_equal(constants['COEFFICIENTS'],angle_fit['coefficients'])
assert np.array_equal(constants['BODY_COEFFICIENTS'],body_fit['coefficients'])
assert [constants['START_SECONDS'],constants['END_SECONDS']]==fit['seconds']==angle_fit['interval_seconds']
Gtree=ast.parse(Path('/tmp/pivot-return-16G-independent/inputs/pivot_return_motion.py').read_text())
Gcls=next(n for n in Gtree.body if isinstance(n,ast.ClassDef) and n.name=='PivotReturnMotion')
Gconstants={n.targets[0].id:ast.literal_eval(n.value) for n in Gcls.body if isinstance(n,ast.Assign)}
for key in Gconstants:
    assert constants[key]==Gconstants[key],('Changed original G scalar constant',key)
q=phase%1.
seconds=np.where(q<=.55,q/.55*.42,.42+(q-.55)/.45*.58)*meta['cycle_seconds']
seconds=np.where(q<constants['END_PHASE'],seconds+meta['cycle_seconds'],seconds)
duration=constants['END_SECONDS']-constants['START_SECONDS']
u=(seconds-constants['START_SECONDS'])/duration
curve_active=(u>0)&(u<1)&~((q>=constants['END_PHASE'])&(q<=.625))
curve_errors={};endpoints={};reference_curves={}
for name,coeff,data_key in [('tool',angle_fit['coefficients'],'turn_angles'),('body',body_fit['coefficients'],'body_yaws'),('translation',fit['coefficients'],'return_translations')]:
    curve=BSpline(fit['spline_knots'],np.array(coeff),5)
    target=np.zeros_like(d[data_key]);target[curve_active]=curve(u[curve_active])
    reference_curves[name]=target
    curve_errors[name+'_export_vs_scipy']=float(np.max(abs(d[data_key]-target)))
    endpoints[name]={str(order):np.asarray(curve([0.,1.],nu=order)/duration**order).tolist() for order in (0,1,2)}
    curve_errors[name+'_endpoint_C2_zero']=max(float(np.max(abs(curve([0.,1.],nu=order)/duration**order))) for order in (0,1,2))
    # One ordinary spline spans the wrapped seam in game seconds. Its value and
    # two derivatives at that interior parameter are single-valued, not reset.
    assert all(np.isfinite(curve((meta['cycle_seconds']-constants['START_SECONDS'])/duration,nu=o)).all() for o in (0,1,2))
    internal=np.array(sorted(set(fit['spline_knots'])))[1:-1]
    assert all(list(fit['spline_knots']).count(float(x))<=3 for x in internal)
P=np.array(fit['projection'])
forward=np.array([-6.,-6.1,-6.02]);forward/=np.linalg.norm(forward)
right=np.cross(forward,[0.,0.,1.]);right/=np.linalg.norm(right)
up=np.cross(right,forward)
curve_errors['projection_from_camera']=float(np.max(abs(P-np.stack((right,-up))*160/2.9)))
curve_report=dict(independent_method='SciPy degree5 BSpline from SHA-bound fit JSON versus all actual exported DeBoor results; candidate coefficients read by AST; all G constants exact. C2 zero endpoint derivatives and knot multiplicity checked.',
    translation_fit_sha256=sha(OUT/'inputs'/'translation-fit.json'),samples=len(phase),errors=curve_errors,endpoint_derivatives=endpoints,
    maximum_exported_translation_native=float(np.linalg.norm(d['return_translations'],axis=1).max()),
    maximum_exported_translation_logical_px=float(np.linalg.norm(d['return_translations']@P.T,axis=1).max()),
    seam_note='No branch reset: both sides map continuously through unwrapped game time T inside the same degree5 spline. Native phase itself is not a constant-speed clock.')

def shortest(axis0, axis):
    axis0 = unit(np.broadcast_to(axis0, axis.shape)); axis = unit(axis)
    v = np.cross(axis0, axis); den = 1 + np.sum(axis0 * axis, axis=1)
    K = np.zeros((len(axis), 3, 3))
    K[:, 0, 1] = -v[:, 2]; K[:, 0, 2] = v[:, 1]
    K[:, 1, 0] = v[:, 2]; K[:, 1, 2] = -v[:, 0]
    K[:, 2, 0] = -v[:, 1]; K[:, 2, 1] = v[:, 0]
    return np.eye(3) + K + K @ K / np.maximum(den, 1e-14)[:, None, None], den

def frames(prefix):
    arms = d[prefix + '_arms']; result = {}; denominators = {}
    for side, j in [('R', 0), ('L', 1)]:
        upper = unit(arms[:, j, 1] - arms[:, j, 0])
        lower = unit(arms[:, j, 2] - arms[:, j, 1])
        result['upper.' + side], denominators['upper.' + side] = shortest(meta['rest_axes']['upper.' + side], upper)
        if side == 'L':
            explicit_left = d[prefix+'_has_left_upper_transport'].astype(bool)
            prior_left, _ = shortest(meta['rest_axes']['upper.L'],d[prefix+'_left_upper_original_axis'][explicit_left])
            result['upper.L'][explicit_left] = d[prefix+'_left_upper_transport'][explicit_left] @ prior_left
        base, denominators['lower.' + side] = shortest(meta['rest_axes']['lower.' + side], lower)
        if side == 'R':
            radial = d[prefix + '_radials'][:, j]
            desired = radial - lower * np.sum(lower * radial, axis=1)[:, None]
            rho = np.linalg.norm(desired, axis=1)
            b = desired / np.maximum(rho, 1e-14)[:, None]
            result['lower.R'] = np.stack((lower, b, np.cross(lower, b)), axis=2)
            explicit = d[prefix+'_has_right_forearm_basis'].astype(bool)
            result['lower.R'][explicit] = d[prefix+'_right_forearm_basis'][explicit]
            transported = np.einsum('nij,j->ni', base, meta['rest_radials']['R'])
            transported -= lower * np.sum(lower * transported, axis=1)[:, None]
            transport_rho = np.linalg.norm(transported, axis=1)
        else:
            result['lower.L'] = base
    for j, name in enumerate(('torso', 'head')):
        result[name] = d[prefix + '_body'][:, j, :3, :3]
    return result, denominators, rho, transport_rho

def maximum_row(values, mask=None):
    ids = np.arange(len(values)) if mask is None else np.flatnonzero(mask)
    k = int(ids[np.argmax(values[ids])])
    return dict(value=float(values[k]),phase=float(phase[k]),sample=k)

def minimum_row(values):
    k = int(np.argmin(values))
    return dict(value=float(values[k]),phase=float(phase[k]),sample=k)

old, oldden, oldrho, oldtransport = frames('old')
new, newden, newrho, newtransport = frames('new')
rotation_caps = {}; violations = []
rate_arrays = {}
for hz in (60, 120, 1200):
    clock = sorted(set(min(meta['cycle_seconds'], i / hz) for i in range(math.ceil(meta['cycle_seconds'] * hz) + 1)))
    ids = np.array([int(np.argmin(abs(times - t))) for t in clock])
    assert np.max(abs(times[ids] - clock)) < 1e-12
    rotation_caps[str(hz)] = {}
    for bone in old:
        values = []
        for f in (old[bone], new[bone]):
            relative = np.swapaxes(f[ids[:-1]], 1, 2) @ f[ids[1:]]
            values.append(np.degrees(Rotation.from_matrix(relative).magnitude()))
        control, actual = values; k = int(np.argmax(actual))
        cap = float(control.max())
        passed = bool(actual.max() <= cap + 1e-5)
        row = dict(control_max_step_degrees=cap, candidate_max_step_degrees=float(actual[k]),
                   passed=passed, numeric_tolerance_degrees=1e-5,
                   phases=[float(phase[ids[k]]), float(phase[ids[k+1]])],
                   times=[float(times[ids[k]]), float(times[ids[k+1]])])
        rotation_caps[str(hz)][bone] = row
        rate_arrays[f'{hz}_{bone}_old'] = control
        rate_arrays[f'{hz}_{bone}_new'] = actual
        if not passed: violations.append(dict(kind='full_bone_rotation', hz=hz, bone=bone, **row))

axis = unit(np.array(meta['selection']['rotation_axis']))
angle = d['turn_angles']
turn = Rotation.from_rotvec(angle[:, None] * axis).as_matrix()
expected_tool = turn @ d['old_tool']
expected_grips = (d['old_rear'] + d['return_translations'])[:, None] + np.einsum('nij,nsj->nsi', turn, d['old_grips'] - d['old_rear'][:, None])
expected_wrists = (d['old_rear'] + d['return_translations'])[:, None] + np.einsum('nij,nsj->nsi', turn, d['old_arms'][:, :, 2] - d['old_rear'][:, None])
protected = (phase % 1 >= .3928571428571429) & (phase % 1 <= .625)
errors = {}
for key in ('legs', 'foot_rotations', 'contacts'):
    errors[key] = float(np.max(abs(d['new_' + key].astype(float) - d['old_' + key].astype(float))))
errors['declared_rear_translation'] = float(np.max(abs(d['new_rear'] - d['old_rear'] - d['return_translations'])))
errors['translated_right_grip'] = float(np.max(abs(d['new_grips'][:, 0] - d['old_grips'][:, 0] - d['return_translations'])))
errors['planned_tool_rotation_matrix'] = float(np.max(abs(d['new_tool'] - expected_tool)))
errors['planned_grip_transform'] = float(np.max(abs(d['new_grips'] - expected_grips)))
errors['planned_wrist_transform'] = float(np.max(abs(d['new_arms'][:, :, 2] - expected_wrists)))
errors['planned_radial_transform'] = float(np.max(abs(d['new_radials'] - np.einsum('nij,nsj->nsi',turn,d['old_radials']))))
errors['planned_hand_axis_transform'] = float(np.max(abs(d['new_hand_axes'] - np.einsum('nij,nsj->nsi',turn,d['old_hand_axes']))))
local_joint = np.r_[meta['body_joint_local'], 1.]
joint = np.einsum('nij,j->ni',d['old_body'][:,0],local_joint)[:,:3]
body_rotation = Rotation.from_rotvec(np.c_[np.zeros(len(phase)),np.zeros(len(phase)),d['body_yaws']]).as_matrix()
body_turn = np.broadcast_to(np.eye(4),(len(phase),4,4)).copy()
body_turn[:,:3,:3] = body_rotation
body_turn[:,:3,3] = joint - np.einsum('nij,nj->ni',body_rotation,joint)
expected_body = body_turn[:,None] @ d['old_body']
expected_shoulders = joint[:,None]+np.einsum('nij,nsj->nsi',body_rotation,d['old_arms'][:,:,0]-joint[:,None])
errors['declared_body_head_transform'] = float(np.max(abs(d['new_body']-expected_body)))
errors['declared_shoulder_transform'] = float(np.max(abs(d['new_arms'][:,:,0]-expected_shoulders)))
errors['fixed_body_joint'] = float(np.max(abs(np.einsum('nij,j->ni',d['new_body'][:,0],local_joint)[:,:3]-joint)))
reference = joint+np.einsum('nij,nj->ni',body_rotation,d['old_arms'][:,1,1]-joint)
left_axis = unit(d['new_arms'][:,1,2]-d['new_arms'][:,1,0])
left_hint = reference-d['new_arms'][:,1,0]
left_projection = left_hint-left_axis*np.sum(left_hint*left_axis,axis=1)[:,None]
left_projection_length = np.linalg.norm(left_projection,axis=1)
left_distance = np.linalg.norm(d['new_arms'][:,1,2]-d['new_arms'][:,1,0],axis=1)
left_along=(.36**2-.35**2+left_distance**2)/(2*left_distance)
left_radius=np.sqrt(np.maximum(0,.36**2-left_along**2))
expected_left_elbow=d['new_arms'][:,1,0]+left_axis*left_along[:,None]+unit(left_projection)*left_radius[:,None]
errors['declared_left_elbow_reference'] = float(np.max(abs(d['new_arms'][:,1,1]-expected_left_elbow)))
errors['protected_complete_pose'] = max(float(np.max(abs(d['new_' + key][protected].astype(float) - d['old_' + key][protected].astype(float))))
                                      for key in ('arms', 'legs', 'radials', 'grips', 'hand_axes', 'rear', 'body', 'foot_rotations', 'tool', 'contacts'))
reach = np.linalg.norm(d['new_arms'][:, :, 2] - d['new_arms'][:, :, 0], axis=2)
length_error = max(float(abs(np.linalg.norm(d['new_arms'][:, :, 1] - d['new_arms'][:, :, 0], axis=2) - .36).max()),
                   float(abs(np.linalg.norm(d['new_arms'][:, :, 2] - d['new_arms'][:, :, 1], axis=2) - .35).max()))
grip_span_error = float(abs(np.linalg.norm(d['new_grips'][:, 1] - d['new_grips'][:, 0], axis=1) - .145).max())
desired_floor = float(oldrho.min())
explicit = d['new_has_right_forearm_basis'].astype(bool)
assert np.array_equal(explicit,weights!=0.)
frame = d['new_right_forearm_basis'][explicit]
new_lower_axis = unit(d['new_arms'][:,0,2]-d['new_arms'][:,0,1])
old_lower_axis = unit(d['old_arms'][:,0,2]-d['old_arms'][:,0,1])
carried_axis = np.einsum('nij,nj->ni',body_rotation,old_lower_axis)
alignment, alignment_denominator = shortest(carried_axis,new_lower_axis)
expected_basis = alignment @ body_rotation @ old['lower.R']
errors['declared_forearm_basis'] = float(np.max(abs(frame-expected_basis[explicit])))
errors['forearm_axis'] = float(np.max(abs(frame[:,:,0]-new_lower_axis[explicit])))
errors['forearm_orthogonality'] = float(np.max(abs(np.swapaxes(frame,1,2)@frame-np.eye(3))))
errors['forearm_determinant'] = float(np.max(abs(np.linalg.det(frame)-1.)))
errors['reported_alignment_denominator'] = float(np.max(abs(d['new_right_forearm_reference_denominator'][explicit]-alignment_denominator[explicit])))
errors['reported_original_radial'] = float(np.max(abs(d['new_right_forearm_original_radial_projection'][explicit]-oldrho[explicit])))
right_reference = joint+np.einsum('nij,nj->ni',body_rotation,d['old_arms'][:,0,1]-joint)
right_axis = unit(d['new_arms'][:,0,2]-d['new_arms'][:,0,0])
right_hint = right_reference-d['new_arms'][:,0,0]
right_projection = right_hint-right_axis*np.sum(right_hint*right_axis,axis=1)[:,None]
right_projection_length=np.linalg.norm(right_projection,axis=1)
right_distance=np.linalg.norm(d['new_arms'][:,0,2]-d['new_arms'][:,0,0],axis=1)
right_along=(.36**2-.35**2+right_distance**2)/(2*right_distance)
right_radius=np.sqrt(np.maximum(0.,.36**2-right_along**2))
expected_right_elbow=d['new_arms'][:,0,0]+right_axis*right_along[:,None]+unit(right_projection)*right_radius[:,None]
errors['declared_right_elbow_reference']=float(np.max(abs(d['new_arms'][:,0,1]-expected_right_elbow)))
rest_axis=unit(np.array(meta['rest_axes']['lower.R']))
rest_radial=np.array(meta['rest_radials']['R'])
rest_projection=float(np.linalg.norm(rest_radial-rest_axis*np.dot(rest_axis,rest_radial)))
explicit_left=d['new_has_left_upper_transport'].astype(bool)
assert np.array_equal(explicit_left,explicit)
old_left_upper_axis=unit(d['old_arms'][:,1,1]-d['old_arms'][:,1,0])
new_left_upper_axis=unit(d['new_arms'][:,1,1]-d['new_arms'][:,1,0])
carried_left_axis=np.einsum('nij,nj->ni',body_rotation,old_left_upper_axis)
left_alignment,left_alignment_denominator=shortest(carried_left_axis,new_left_upper_axis)
expected_left_transport=left_alignment@body_rotation
left_transport=d['new_left_upper_transport'][explicit]
errors['left_original_axis']=float(np.max(abs(d['new_left_upper_original_axis'][explicit]-old_left_upper_axis[explicit])))
errors['left_transport']=float(np.max(abs(left_transport-expected_left_transport[explicit])))
errors['left_axis']=float(np.max(abs(np.einsum('nij,nj->ni',left_transport,old_left_upper_axis[explicit])-new_left_upper_axis[explicit])))
errors['left_transport_orthogonality']=float(np.max(abs(np.swapaxes(left_transport,1,2)@left_transport-np.eye(3))))
errors['left_transport_determinant']=float(np.max(abs(np.linalg.det(left_transport)-1.)))
errors['reported_left_denominator']=float(np.max(abs(d['new_left_upper_reference_denominator'][explicit]-left_alignment_denominator[explicit])))
errors['declared_left_upper_frame']=float(np.max(abs(new['upper.L'][explicit]-(expected_left_transport@old['upper.L'])[explicit])))
basic_checks = dict(independent_curves=max(curve_errors.values()) < 1e-7,finite_data=all(np.isfinite(d[k]).all() for k in d.files),reach=bool(reach.max() < .70),segment_lengths=length_error < 1e-5,
                    rigid_grip_span=grip_span_error < 1e-6,
                    protected_fields=all(errors[k] == 0 for k in ('legs', 'foot_rotations', 'contacts', 'protected_complete_pose')),
                    planned_rigid_rotation=max(errors[k] for k in ('planned_tool_rotation_matrix','planned_grip_transform','planned_wrist_transform','declared_rear_translation','translated_right_grip','planned_radial_transform','planned_hand_axis_transform')) < 1e-6,
                    nonmine_unchanged=max(meta['nonmine_maximum_error'].values()) == 0.,
                    declared_torso_head=max(errors[k] for k in ('declared_body_head_transform','declared_shoulder_transform','fixed_body_joint')) < 1e-6,
                    declared_left_elbow=errors['declared_left_elbow_reference'] < 1e-6,
                    left_pole_guard=bool(left_projection_length.min() > .05),
                    legacy_forearm_fallback_guard=bool(min(newrho[~explicit].min(),newtransport[~explicit].min()) > .05),
                    original_corrected_frame_guard=bool(oldrho.min() >= desired_floor-1e-6 and oldrho.min()>.05 and rest_projection>.05),
                    forearm_transport_axis_guard=bool(alignment_denominator.min()>.05),
                    declared_forearm_frame=max(errors[k] for k in ('declared_forearm_basis','forearm_axis','forearm_orthogonality','forearm_determinant','reported_alignment_denominator','reported_original_radial'))<1e-5,
                    protected_forearm_fallback=bool(not np.any(explicit[protected])),
                    right_elbow_reference=errors['declared_right_elbow_reference']<1e-6,
                    right_pole_guard=bool(right_projection_length.min()>.05),
                    native_axis_maps=bool(min(v.min() for k,v in newden.items() if k not in ('lower.R','upper.L')) > .01 and newden['upper.L'][~explicit_left].min()>.01),
                    original_left_upper_rest_map=bool(oldden['upper.L'].min()>.01),
                    left_transport_axis_guard=bool(left_alignment_denominator.min()>.05),
                    declared_left_transport=max(errors[k] for k in ('left_original_axis','left_transport','left_axis','left_transport_orthogonality','left_transport_determinant','reported_left_denominator','declared_left_upper_frame'))<1e-5,
                    protected_left_fallback=bool(not np.any(explicit_left[protected])))
for name, passed in basic_checks.items():
    if not passed: violations.append(dict(kind=name))
passed = not violations
report = dict(complete=True,passed_analytic=passed,passed_geometry=False,accepted_geometry=False,
              render_allowed=False,rendered=False,candidate_rig_evaluated=False,
              candidate_sha256=meta['candidate_sha256'],export_sha256=sha(OUT/'analytic-export.json'),
              data_sha256=meta['data_sha256'],script_sha256=sha(__file__),
              samples=dict(regular_time=N,dense_phase=501,total_mine=len(phase)),
              constraints_note='Complete native arm-bone rotations, identical baseline caps at60/120/1200Hz. Tool orientation is checked against planned pivot rotation, except protected .3928571428571429-.625 which is exact baseline; torso/head follow declared world-Z turn about the fixed body joint. Rear/grips/wrists intentionally move by the independently verified C2 translation. No unchanged-arm/body cap is relaxed.',
              basic_checks=basic_checks,errors=errors,curve_verification=curve_report,
              reach={s:maximum_row(reach[:,j]) for j,s in enumerate(('R','L'))},
              left_pole_projection_minimum=minimum_row(left_projection_length),
              right_pole_projection_minimum=minimum_row(right_projection_length),
              explicit_right_frame_samples=int(explicit.sum()),
              forearm_transport_minimum_denominator=minimum_row(alignment_denominator),
              rest_radial_projection=rest_projection,
              left_transport_minimum_denominator=minimum_row(left_alignment_denominator),
              original_left_upper_rest_minimum_denominator=minimum_row(oldden['upper.L']),
              frame_helper_sha256=meta['frame_helper_sha256'],
              maximum_segment_length_error=length_error,maximum_grip_span_error=grip_span_error,
              unused_new_hand_radial_projection_note='Changed poses use the explicitly exported transported forearm and upper.L frames. Their new hand radial and absolute upper.L rest-map denominator are diagnostic only because neither defines the applied changed frame. Original/fallback guards retain their old limits.',
              desired_right_radial=dict(control_minimum=minimum_row(oldrho),candidate_minimum=minimum_row(newrho)),
              transported_right_radial=dict(control_minimum=minimum_row(oldtransport),candidate_minimum=minimum_row(newtransport)),
              native_shortest_map_denominators={s:minimum_row(v) for s,v in newden.items()},
              rotation_caps=rotation_caps,violations=violations,
              next_action='Analytic gate only: root must decide the next bounded native/visual check; full geometry remains unpassed' if passed else 'STOP: candidate rejected before any actual rig application or alpha validation.')
(OUT/'analytic-report.json').write_text(json.dumps(report,indent=2)+'\n')
np.savez_compressed(OUT/'analytic-frames-and-rates.npz', **rate_arrays, **{'old_'+k:v for k,v in old.items()}, **{'new_'+k:v for k,v in new.items()},
                    old_right_radial=oldrho,new_right_radial=newrho)
print('ANALYTIC_GATE_COMPLETE',json.dumps(report),flush=True)
