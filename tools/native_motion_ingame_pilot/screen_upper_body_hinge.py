"""Conservative complete-head footprint screening from closed actual vertices.

No mesh is rendered or replaced. A convex cover can overestimate the head; a
point inside this cover is NOT proof of occlusion. Points outside it still need
the actual full-scene arm/body/tool test and native-image readability review.
"""
from pathlib import Path
import argparse
import hashlib
import json
import time
import numpy as np
from scipy.spatial import ConvexHull
from scipy.spatial.transform import Rotation

parser = argparse.ArgumentParser()
for name in ('head-report','hinge-report','shaft-report','output'):
    parser.add_argument('--'+name,type=Path,required=True)
args = parser.parse_args()
sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
head = json.loads(args.head_report.read_text())
hinge = json.loads(args.hinge_report.read_text())
shaft = json.loads(args.shaft_report.read_text())
assert head['complete'] and hinge['complete'] and shaft['complete']
assert args.head_report.name == 'head-geometry-final.json', 'Use the closed immutable receipt, not progress snapshots'
assert len(head['objects']) == 179 and head['evaluated_triangles'] == 2217334
assert head['actual_evaluated_transport_check']['maximum_world_vertex_error'] < 1e-5
assert head['source_hashes']['upper_body_hinge_pose.py'] == hinge['source_hashes']['upper_body_hinge_pose.py']
assert head['source_hashes']['fixed_cap_pivot_pose.py'] == shaft['source_hashes']['fixed_cap_pivot_pose.py']
assert shaft['executed_source_sha'] == '66bb10e1d821268ecda8a00a4048e6612874ed00'
cache = args.head_report.parent/'complete-head-vertices.npz'
assert sha(cache) == head['cache_sha256']
vertices = np.load(cache)['world_vertices']
assert vertices.shape == (head['cached_vertices'],3) and np.isfinite(vertices).all()
transport = head['actual_evaluated_transport_check']
checked_path = args.head_report.parent/transport['actual_vertices_file']
assert sha(checked_path) == transport['actual_vertices_sha256']
checked = np.load(checked_path)['world_vertices']
assert checked.shape == vertices.shape and np.isfinite(checked).all()
check_matrix = np.asarray(transport['reference_to_checked_head_matrix'])
errors = np.linalg.norm(checked-(vertices@check_matrix[:3,:3].T+check_matrix[:3,3]),axis=1)
actual_transport_error = float(np.max(errors))
assert actual_transport_error < 1e-5
assert abs(actual_transport_error-transport['maximum_world_vertex_error']) < 1e-12
assert len(transport['objects']) == len(head['objects']) == 179
for metadata, measured in zip(head['objects'],transport['objects']):
    start,count = metadata['cache_vertex_offset'],metadata['cache_vertex_count']
    assert measured['name'] == metadata['name'] and measured['vertices'] == count
    assert abs(float(np.max(errors[start:start+count]))-measured['maximum_world_vertex_error']) < 1e-12
started = time.monotonic()
hull3 = ConvexHull(vertices)  # All actual vertices, no thinning or random jitter.
cover = vertices[hull3.vertices]
reference_head_inverse = np.linalg.inv(np.asarray(head['reference_head_matrix']))
camera = head['camera']
camera_rotation = Rotation.from_euler('xyz',camera['rotation']).as_matrix()
camera_position = np.asarray(camera['position'])
pixel_scale = 200/camera['ortho_scale']


def project(points):
    local = (np.asarray(points)-camera_position)@camera_rotation
    return np.column_stack((100+local[:,0]*pixel_scale,100-local[:,1]*pixel_scale))


def signed_halfspace_distance(points,hull):
    # Positive means outside the conservative projected convex cover; negative
    # is an interior halfspace margin. This is not scene-depth visibility.
    return np.max(np.asarray(points)@hull.equations[:,:2].T+hull.equations[:,2],axis=1)


report = {
    'complete':False,'rendered':False,'full_scene_occlusion_tested':False,'candidate_selected':False,
    'head_report_sha256':sha(args.head_report),'hinge_report_sha256':sha(args.hinge_report),
    'shaft_report_sha256':sha(args.shaft_report),'cache_sha256':sha(cache),
    'source_sha256':sha(Path(__file__)), 'actual_input_vertices':len(vertices),
    'all_actual_transport_vertices_rechecked':len(checked),
    'recomputed_maximum_transport_error':actual_transport_error,
    'convex_cover_vertices':len(cover),'convex_cover_triangles':len(hull3.simplices),
    'native_pixels':[200,200],'camera':camera,'maximum_projection_crosscheck_error':0.,
    'scope':'Complete evaluated head vertex convex cover, including ears/helmet/hair. It overestimates projection and has no scene-depth ordering. An inside point does not prove occlusion. Passing this screen is neither rig, full-body/tool visibility nor image/motion acceptance.',
    'cases':[]}
shaft_cases = {r['phase']:r['parts'] for r in shaft['occlusion']}
for case in hinge['cases']:
    if not case['passed']:
        continue
    result = {k:case[k] for k in ('side_lean_degrees','local_twist_degrees','max_reach')}
    result['poses'] = []
    for pose in case['poses']:
        change = np.asarray(pose['head_matrix'])@reference_head_inverse
        transformed = cover@change[:3,:3].T+change[:3,3]
        projected = project(transformed)
        hull2 = ConvexHull(projected)
        boundary = projected[hull2.vertices]
        rear, axis = np.asarray(pose['rear_world']), np.asarray(pose['axis_world'])
        unit_ends = project(np.vstack((rear,rear+axis)))
        direction = unit_ends[1]-unit_ends[0]
        grips = project(np.asarray([pose['grips_world'][s] for s in ('R','L')]))
        expected_grips = np.asarray([pose['grips_pixel'][s] for s in ('R','L')])
        error = float(np.max(np.abs(grips-expected_grips)))
        report['maximum_projection_crosscheck_error'] = max(report['maximum_projection_crosscheck_error'],error)
        assert error < 1e-4, error
        centerline_t = np.linspace(0.,.55,111)
        centerline = unit_ends[0]+centerline_t[:,None]*direction
        centerline_gap = signed_halfspace_distance(centerline,hull2)
        row = {'phase':pose['phase'],'head_convex_cover_native_pixels':boundary.tolist(),
            'head_cover_bounds':[float(np.min(boundary[:,0])),float(np.min(boundary[:,1])),float(np.max(boundary[:,0])),float(np.max(boundary[:,1]))],
            'grip_signed_halfspace_distance':dict(zip(('R','L'),signed_halfspace_distance(grips,hull2).tolist())),
            'shaft_centerline_native_range':[0.,.55],
            'centerline_minimum_signed_halfspace_distance':float(np.min(centerline_gap)),
            'centerline_samples_outside_cover':int(np.sum(centerline_gap>0.)),
            'centerline_sample_count':len(centerline_t)}
        if pose['phase'] in shaft_cases:
            actual = shaft_cases[pose['phase']]
            source = next(r for r in actual['parts'] if r['object'] == 'round source-textured shaft')
            pixels = np.asarray(source['projected_pixels'],dtype=float)+.5
            distances = signed_halfspace_distance(pixels,hull2)
            along = (pixels-unit_ends[0])@direction/np.dot(direction,direction)
            bins = []
            for center in (0.,.145,.25,.35,.45,.55):
                chosen = np.abs(along-center)<=.04
                bins.append({'shaft_coordinate':center,'half_width':.04,'actual_shaft_pixel_centers':int(np.sum(chosen)),
                             'outside_complete_head_cover':int(np.sum(distances[chosen]>0.)),
                             'outside_by_at_least_two_native_pixels':int(np.sum(distances[chosen]>=2.))})
            row['actual_unchanged_shaft_pixels'] = {
                'pixel_centers':len(pixels),'outside_complete_head_cover':int(np.sum(distances>0.)),
                'outside_by_at_least_two_native_pixels':int(np.sum(distances>=2.)), 'grip_and_shaft_bands':bins}
        result['poses'].append(row)
    report['cases'].append(result)
report['elapsed_seconds'] = time.monotonic()-started
report['complete'] = True
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps(report,indent=2)+'\n')
print('COMPLETE_HEAD_FOOTPRINT_SCREEN',len(report['cases']),len(cover),report['elapsed_seconds'],flush=True)
