"""Bind the genuine working surface and investigate one native strike arc.

This uses the actual rig and unchanged approved ore PNG. The ore has no native
3D collision surface: its alpha rim is a projected presentation boundary only.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import runpy
import sys
import bpy
from mathutils import Matrix, Vector

parser = argparse.ArgumentParser()
parser.add_argument('--native-tools', type=Path, required=True)
parser.add_argument('--project', type=Path, required=True)
parser.add_argument('--recorded', type=Path, required=True)
parser.add_argument('--target-identity', type=Path, required=True)
parser.add_argument('--head-topology', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--measure-occlusion', action='store_true')
parser.add_argument('--contact-pitch-degrees', type=float, default=30.)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
args.output.mkdir(parents=True, exist_ok=True)
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
topology = json.loads(args.head_topology.read_text())
assert topology['complete'] and topology['diagnostic_consistent_orientation']['closed_orientable']
assert topology['source_sha256'] == '0f90a49329acfd6db5b62cfbe6361efce1c79bea4a9d57a93fab130d46ac5b2b'
surface = topology['intended_working_surface']
assert len(surface['triangle_indices']) == 18 and len(surface['vertex_indices']) == 20
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools), '--project', str(args.project),
            '--recorded', str(args.recorded), '--target-identity', str(args.target_identity),
            '--output', str(args.output/'scene-load'), '--setup-only']
mapped = runpy.run_path(str(HERE/'map_up_contact.py'))
sys.path.insert(0, str(HERE))
import target_contact_pose
import working_surface_arc
env, ground = mapped['env'], mapped['ground']
native, pm = env['native_motion'], env['premium_motion']
rig, rest = env['r'], env['rest']
ready = json.loads((HERE/'contact-arc-readiness.json').read_text())
target = Vector(ready['target_ground_vector'])
draw = mapped['sample']
project = lambda p: Vector(mapped['project'](p))
alpha = lambda xy: mapped['ore_alpha'](mapped['scene_point'](xy, draw), draw)
spec = dict(lateral=-.12, forward=-.4, height=1.15, pitch_degrees=10, roll_degrees=0)
center_rest = Vector(surface['area_centroid_native_rest_world'])
normal_rest = Vector(surface['geometric_outward_normal_native_rest_world'])


def apply(p):
    for modifier in env['skin']: modifier.show_viewport = False
    pose = dict(p)
    pose['head'] = pose['head']@env['head_offset']
    env['apply'](pose)
    return rig.pose.bones['tool'].matrix@rig.data.bones['tool'].matrix_local.inverted()


# Bind the complete source surface through the evaluated approved rig's tool
# matrix. A source-gear rest frame alone is insufficient for this combined rig.
p, _ = target_contact_pose.sample(.55, ground, target, spec)
delta = apply(p)
frame = pm.tool_frame(p['axis'], p['tool_normal'])
local_center = frame.transposed()@(delta@center_rest-p['rear'])
local_normal = frame.transposed()@(delta.to_3x3()@normal_rest)
local_vertices = {int(v):frame.transposed()@(delta@Vector(co)-p['rear']) for v,co in surface['rest_vertices'].items()}


def center(p):
    return p['rear']+pm.tool_frame(p['axis'], p['tool_normal'])@local_center


def surface_points(p):
    frame = pm.tool_frame(p['axis'], p['tool_normal'])
    return [p['rear']+frame@point for point in local_vertices.values()]


def surface_alpha(p):
    return max(alpha(project(point)) for point in [center(p), *surface_points(p)])


# Locate the first genuine lower-cap projection entering the frozen ore alpha
# along the explicitly rejected earlier trial. This binds a specific rim entry,
# rather than selecting an arbitrary interior opaque pixel or another target.
previous = .40
assert surface_alpha(target_contact_pose.sample(previous, ground, target, spec)[0]) <= .5
first = None
for i in range(1, 601):
    q = .40+.15*i/600
    if surface_alpha(target_contact_pose.sample(q, ground, target, spec)[0]) > .5:
        first = q
        break
    previous = q
assert first is not None
for _ in range(20):
    middle = (previous+first)/2
    if surface_alpha(target_contact_pose.sample(middle, ground, target, spec)[0]) > .5: first = middle
    else: previous = middle
entry_pose, _ = target_contact_pose.sample(first, ground, target, spec)
entry_center = project(center(entry_pose))
contact_spec = dict(spec, pitch_degrees=args.contact_pitch_degrees)
contact_pose, _ = target_contact_pose.sample(.55, ground, target, contact_spec)
contact_frame = pm.tool_frame(contact_pose['axis'], contact_pose['tool_normal'])
direction = target.normalized()
z = Vector((0,0,1))
origin = project(center(contact_pose))
along = project(center(contact_pose)+direction)-origin
up = project(center(contact_pose)+z)-origin
coefficients = Matrix(((along.x,up.x),(along.y,up.y))).inverted()@(entry_center-origin)
rear = contact_pose['rear']+direction*coefficients.x+z*coefficients.y
contact = {'rear':list(rear), 'tool_frame':[list(row) for row in contact_frame]}

report = {'complete':False, 'rendered':False, 'visually_accepted':False,
          'source_base':'bbf18271b6fdb760f3567bf60c960188d5e0f1a6',
          'source_hashes':{name:sha(HERE/name) for name in ['probe_working_surface_arc.py','working_surface_arc.py','target_contact_pose.py','map_up_contact.py']},
          'topology_sha256':sha(args.head_topology), 'working_surface':surface,
          'model_sha256':mapped['loaded']['report']['model_sha256'], 'gear_sha256':topology['source_sha256'],
          'target_identity_sha256':sha(args.target_identity), 'recorded_sha256':sha(args.recorded),
          'all_phases_projected_into_fixed_recorded_impact_rectangle':True,
          'runtime_or_3d_ore_contact_proof':False,
          'unchanged_ground':list(ground), 'target_ground':list(target),
          'previous_trial_first_cap_alpha_phase':first,
          'previous_trial_first_cap_entry_center':list(entry_center),
          'native_rear_correction_along_target_and_vertical':list(coefficients),
          'contact_pitch_degrees':args.contact_pitch_degrees,
          'contact':contact, 'surface_center_tool_local':list(local_center), 'surface_normal_tool_local':list(local_normal),
          'surface_vertices_tool_local':{str(k):list(v) for k,v in local_vertices.items()},
          'max_surface_transport_error':0., 'max_grip_error':0., 'max_reach':0.,
          'max_segment_error':0., 'max_evaluated_foot_matrix_difference':0.,
          'dense_evaluated_poses':0, 'trajectory':[], 'occlusion':[]}
phases = sorted(set([i/128 for i in range(129)]+[.24,.4,.55,.575,.625,.68,.82]))
(args.output/'working-surface-arc.json').write_text(json.dumps(report,indent=2)+'\n')
for q in phases:
    try:
        p, original = working_surface_arc.sample(q, ground, target, contact)
    except Exception as error:
        report['failed_phase'] = q
        report['failure'] = repr(error)
        (args.output/'working-surface-arc.json').write_text(json.dumps(report,indent=2)+'\n')
        raise
    for key in ('legs','foot_rotations','contacts'): assert p[key] is original[key]
    assert native.frame_metadata(p,ground)['feet'] == native.frame_metadata(original,ground)['feet']
    apply(original)
    feet = {s:rig.pose.bones['foot.'+s].matrix.copy() for s in native.SIDES}
    delta = apply(p)
    report['max_surface_transport_error'] = max(report['max_surface_transport_error'], (delta@center_rest-center(p)).length)
    for s in native.SIDES:
        report['max_grip_error'] = max(report['max_grip_error'], ((rig.pose.bones['hand.'+s].matrix@rig.data.bones['hand.'+s].matrix_local.inverted())@rest['grips'][s]-p['grips'][s]).length)
        report['max_evaluated_foot_matrix_difference'] = max(report['max_evaluated_foot_matrix_difference'], max(abs(rig.pose.bones['foot.'+s].matrix[i][j]-feet[s][i][j]) for i in range(4) for j in range(4)))
    for a,b,c in p['arms'].values():
        report['max_reach'] = max(report['max_reach'], (c-a).length)
        report['max_segment_error'] = max(report['max_segment_error'],abs((b-a).length-.36),abs((c-b).length-.35))
    report['dense_evaluated_poses'] += 1
assert report['dense_evaluated_poses'] == 135
for key in ('max_surface_transport_error','max_grip_error','max_segment_error','max_evaluated_foot_matrix_difference'): assert report[key] < 1e-5, (key,report[key])
for i in range(301):
    q = .40+.15*i/300
    p, _ = working_surface_arc.sample(q, ground, target, contact)
    report['trajectory'].append({'phase':q,'working_surface_center_native_pixel':list(project(center(p))),
                                  'maximum_cap_vertex_or_center_ore_alpha':surface_alpha(p)})
p, _ = working_surface_arc.sample(.55,ground,target,contact)
before, _ = working_surface_arc.sample(.55-.0001,ground,target,contact)
velocity = (center(p)-center(before))/(.0001*.68*.42/.55)
normal = pm.tool_frame(p['axis'],p['tool_normal'])@local_normal
report['contact_approach'] = {'native_velocity':list(velocity),'geometric_outward_surface_normal':list(normal),
                             'outward_surface_normal_dot_incoming_velocity':normal.dot(velocity),
                             'native_pixel_velocity':list((project(center(p))-project(center(before)))/(.0001*.68*.42/.55)),
                             'cap_alpha_at_contact':surface_alpha(p)}
report['first_new_cap_alpha_phase'] = next((row['phase'] for row in report['trajectory'] if row['maximum_cap_vertex_or_center_ore_alpha']>.5),None)
(args.output/'working-surface-arc.json').write_text(json.dumps(report,indent=2)+'\n')
if args.measure_occlusion:
    for q in (.375,.55,.625):
        p,_ = working_surface_arc.sample(q,ground,target,contact)
        measurement = mapped['measure_parts'](p,draw)
        assert measurement['object_count']==629 and measurement['evaluated_triangles']==2714340
        report['occlusion'].append({'phase':q,**measurement})
        (args.output/'working-surface-arc.json').write_text(json.dumps(report,indent=2)+'\n')
report['complete'] = True
report['limits'] = ['The exact cap is bound; an alpha rim is not a 3D ore surface.',
                    'Native images, adjacent runtime poses and real ore draw contraction remain required.',
                    'Only Worn/up and one frozen ordinarily selected target; no runtime controller or universal target solver.']
(args.output/'working-surface-arc.json').write_text(json.dumps(report,indent=2)+'\n')
print('WORKING_SURFACE_ARC_COMPLETE',report['max_grip_error'],report['first_new_cap_alpha_phase'],report['contact_approach'],flush=True)
