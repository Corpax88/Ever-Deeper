"""Read-only native contact projection; no new pose design or image rendering.

Bind the actual up replay and generated ore identity, then distinguish shaft
foreshortening, head occlusion and projected ore contact. New anatomical poses
are counterfactual projections into the retained draw, not an in-game trial.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import runpy
import sys
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector
from mathutils.bvhtree import BVHTree

parser = argparse.ArgumentParser()
parser.add_argument('--native-tools', type=Path, required=True)
parser.add_argument('--project', type=Path, required=True)
parser.add_argument('--recorded', type=Path, required=True)
parser.add_argument('--target-identity', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--setup-only', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
HERE = Path(__file__).resolve().parent
args.output.mkdir(parents=True, exist_ok=True)
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(args.recorded) == '011703e1f3c9af140d169e550b5b88828fce09a7214811c5e58ebb1d295267fd'
recorded = json.loads(args.recorded.read_text())
identity = json.loads(args.target_identity.read_text())
assert identity['world_identity_matches_rendered_case'] and identity['route'] == recorded['route']
assert identity['original_capture_sha256'] == sha(args.recorded)
sample = recorded['samples'][50]
assert sample['target_hp'] == 946 and sample['visual']['sample_phase'] == .55
baseline_path = args.recorded.parent.parent/'up-baseline/native-ingame.json'
assert sha(baseline_path) == '8c300e7fc8a962d999479df1d6812e5c400b293884a095b6295e47dafe608594'
baseline = json.loads(baseline_path.read_text())['samples'][50]
texture = args.project/identity['texture_path'].removeprefix('res://')
assert sha(texture) == identity['texture_sha256']
ore_image = bpy.data.images.load(str(texture), check_existing=False)
tw, th = ore_image.size
rgba = list(ore_image.pixels)

sys.argv = ['blender', '--', '--output', str(args.output/'target-controls.json')]
envelope = runpy.run_path(str(HERE/'probe_contact_envelope.py'))
anatomy = envelope['anatomy']
sys.argv = ['blender', '--', '--native-tools', str(args.native_tools), '--output', str(args.output/'scene-load'), '--setup-only']
loaded = runpy.run_path(str(HERE/'probe_up_occlusion.py'))
env, ground = loaded['env'], anatomy['GROUND']
scene, camera, rig, rest = env['s'], env['c'], env['r'], env['rest']
production_manifest_path = args.project/'assets/hero/dad/worn/manifest.json'
assert sha(production_manifest_path) == '50670d57498efa5dd2b07006d1dff7823bf86520761924e59061b852143f8832'
production_manifest = json.loads(production_manifest_path.read_text())
production_time = production_manifest['states']['mine']['times'][26]
assert production_time == .7975 and baseline['visual']['local_frame'] == 26
selection = json.loads((HERE/'anatomical-probe-selection.json').read_text())['specification']


def project(v):
    q = world_to_camera_view(scene, camera, v)
    return [q.x*200, (1-q.y)*200]


def scene_point(native_xy, draw):
    x, y, w, h = draw['framing']['subjects']['hero_and_tool']
    return [x+native_xy[0]*w/200, y+native_xy[1]*h/200]


def ore_alpha(point, draw):
    x, y, w, h = draw['framing']['subjects']['actual_resource_sprite']
    u, v = (point[0]-x)/w, (point[1]-y)/h
    if not (0 <= u < 1 and 0 <= v < 1):
        return 0.
    # Blender image pixels start at the lower-left; recorded screen Y points down.
    return rgba[(min(th-1, int((1-v)*th))*tw+min(tw-1, int(u*tw)))*4+3]


def measure_parts(p, draw):
    for modifier in env['skin']:
        modifier.show_viewport = False
    posed = dict(p)
    posed['head'] = posed['head']@env['head_offset']
    env['apply'](posed)
    grip = max(((rig.pose.bones['hand.'+side].matrix@rig.data.bones['hand.'+side].matrix_local.inverted())@rest['grips'][side]-p['grips'][side]).length for side in ('R', 'L'))
    assert grip < 1e-5
    for modifier in env['skin']:
        modifier.show_viewport = True
    bpy.context.view_layer.update()
    full, _, owners, objects = loaded['mesh_trees']()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    cam = camera.matrix_world.copy()
    ray_direction = (cam.to_3x3()@Vector((0, 0, -1))).normalized()
    parts = []
    for obj in scene.objects:
        if obj.type != 'MESH' or obj.hide_render or not any(g.name == 'tool' for g in obj.vertex_groups):
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        vertices = [evaluated.matrix_world@v.co for v in mesh.vertices]
        triangles = [tuple(t.vertices) for t in mesh.loop_triangles]
        tree = BVHTree.FromPolygons(vertices, triangles, all_triangles=True)
        points = [project(v) for v in vertices]
        box = [min(p[0] for p in points), min(p[1] for p in points), max(p[0] for p in points), max(p[1] for p in points)]
        pixels, visible, occluders = [], [], {}
        for y in range(max(0, math.floor(box[1])), min(200, math.ceil(box[3]))):
            for x in range(max(0, math.floor(box[0])), min(200, math.ceil(box[2]))):
                origin = cam@Vector((((x+.5)/200-.5)*camera.data.ortho_scale, (.5-(y+.5)/200)*camera.data.ortho_scale, 0))
                hit = tree.ray_cast(origin, ray_direction, 100)
                if hit[0] is None:
                    continue
                pixels.append([x, y])
                first = full.ray_cast(origin, ray_direction, 100)
                assert first[0] is not None
                owner = owners[first[2]][0]
                if owner == obj.name or abs(first[3]-hit[3]) < 1e-5:
                    visible.append([x, y])
                else:
                    occluders[owner] = occluders.get(owner, 0)+1
        tips = []
        if 'head' in obj.name.lower():
            for label, picker in [('minimum_normal', min), ('maximum_normal', max)]:
                vertex = picker(vertices, key=lambda v:(v-p['rear']).dot(p['tool_normal']))
                xy = project(vertex)
                tips.append({'selector':label, 'native_world':list(vertex), 'native_pixel':xy, 'recorded_screen_projection':scene_point(xy, draw), 'ore_alpha_at_projection':ore_alpha(scene_point(xy, draw), draw)})
        parts.append({'object':obj.name, 'vertices':len(vertices), 'triangles':len(triangles), 'projected_bounds':box,
                      'projected_pixel_centers':len(pixels), 'visible_pixel_centers':len(visible),
                      'visible_fraction':len(visible)/len(pixels) if pixels else None,
                      'occluders':dict(sorted(occluders.items(), key=lambda item:-item[1])),
                      'projected_pixels':pixels, 'visible_pixels':visible, 'head_normal_extrema_not_collision_contacts':tips,
                      'ore_alpha_overlap_projected':sum(ore_alpha(scene_point([x+.5,y+.5],draw),draw)>.5 for x,y in pixels),
                      'ore_alpha_overlap_visible':sum(ore_alpha(scene_point([x+.5,y+.5],draw),draw)>.5 for x,y in visible)})
        evaluated.to_mesh_clear()
    assert len(parts) >= 3
    shaft_start, shaft_unit_end = project(p['rear']), project(p['rear']+p['axis'])
    return {'actual_grip_error':grip, 'parts':parts, 'object_count':len(objects), 'evaluated_triangles':sum(o['triangles'] for o in objects),
            'rear':list(p['rear']), 'axis':list(p['axis']), 'tool_normal':list(p['tool_normal']),
            'rear_native_pixel':shaft_start, 'shaft_unit_end_native_pixel':shaft_unit_end,
            'shaft_projection_px_per_native_unit':math.dist(shaft_start, shaft_unit_end),
            'shaft_dot_view_ray':p['axis'].dot(ray_direction),
            'grips_native_pixels':{s:project(v) for s,v in p['grips'].items()},
            'native_feet':env['native_motion'].frame_metadata(p, ground)['feet'] if 'foot_rotations' in p else None,
            'foot_metadata_schema':'native complete feet' if 'foot_rotations' in p else 'legacy pose; native foot schema absent',
            'evaluated_foot_matrices':{side:[list(row) for row in rig.pose.bones['foot.'+side].matrix] for side in ('R','L')}}


report = {'complete':False, 'rendered':False, 'new_pose_design':False,
          'purpose':'Native contact projection and actual mesh occlusion only; no visual, physical collision or gameplay acceptance',
          'executed_source_base':'7f1b22c42301cd6c6f7d3d7c446c728d66a73839',
          'executed_diagnostic_sha256':sha(Path(__file__)), 'recorded_sha256':sha(args.recorded),
          'target_identity_sha256':sha(args.target_identity), 'texture_sha256':sha(texture),
          'production_manifest_sha256':sha(production_manifest_path),
          'model_sha256':loaded['report']['model_sha256'], 'gear_sha256':loaded['report']['gear_sha256'],
          'mechanical_target':recorded['route'], 'actual_hp_change_frame':50,
          'actual_target_rect':sample['framing']['subjects']['actual_resource_sprite'],
          'native_candidate_rect':sample['framing']['subjects']['hero_and_tool'],
          'production_baseline_rect':baseline['framing']['subjects']['hero_and_tool'],
          'retained_offset':sample['visual']['retained_offset'],
          'sampling':'200px orthographic pixel-center BVH rays; ore alpha > .5 nearest pixel. This omits lighting, filtering and scene visibility.',
          'head_extrema_caveat':'Tool-normal mesh extrema are geometric candidate tip samples, not asserted collision/contact points.',
          'cases':[]}
original = env['native_motion'].sample('worn', 'mine', .55, ground, 340.)
anatomical = anatomy['anatomical_pose'](original, selection['yaw_degrees'], selection['contact_lateral'], selection['contact_retreat'], selection['tool_roll_degrees'])
cases = [('original_native', original, sample),
         ('rejected_constant_plane_v1', env['native_motion'].sample('worn','mine',.55,ground,340.,direction='up',up_working_plane=True), sample),
         ('rejected_anatomical_probe', anatomical, sample),
         ('production_DEV11', env['motion_v9'].directional_sample(production_time,'mine','pickaxe','up'), baseline)]
for label, p, draw in ([] if args.setup_only else cases):
    measured = measure_parts(p, draw)
    report['cases'].append({'label':label, 'recorded_pose':label in ('original_native','production_DEV11'),
                            'counterfactual_projection_only':label.startswith('rejected_'), **measured})
    (args.output/'contact-projection.json').write_text(json.dumps(report,indent=2)+'\n')
    print('CONTACT_PROJECTION_CASE', label, measured['actual_grip_error'], flush=True)
if not args.setup_only:
    report['complete'] = True
    (args.output/'contact-projection.json').write_text(json.dumps(report,indent=2)+'\n')
    print('CONTACT_PROJECTION_COMPLETE', len(report['cases']), flush=True)
