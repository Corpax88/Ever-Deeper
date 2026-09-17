"""Target-bound upper-body contact reach; no evaluated mesh or visual claim."""
from pathlib import Path
import argparse
import hashlib
import json
import math
import sys
import bpy
from mathutils import Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view

parser = argparse.ArgumentParser()
parser.add_argument('--projection', type=Path, required=True)
parser.add_argument('--texture', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
ROOT = Path(__file__).resolve().parents[1]/'hero_v28'
sys.path.insert(0, str(ROOT))
import native_motion as native
import premium_motion as pm
sys.path.insert(0,str(Path(__file__).resolve().parent))
import target_contact_pose

mapping = json.loads(args.projection.read_text())
assert mapping['complete'] and len(mapping['cases']) == 4
assert hashlib.sha256(args.texture.read_bytes()).hexdigest() == mapping['texture_sha256']
scene = bpy.context.scene
camera_data = bpy.data.cameras.new('ProjectionOnly')
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 2.9
camera = bpy.data.objects.new('ProjectionOnly', camera_data)
scene.collection.objects.link(camera)
camera.location = (6,6,7)
camera.rotation_euler = (Vector((0,-.10,.98))-camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera = camera
scene.render.resolution_x = scene.render.resolution_y = 200
bpy.context.view_layer.update()


def project(v):
    q = world_to_camera_view(scene,camera,v)
    return Vector((q.x*200,(1-q.y)*200))


zero = project(Vector())
gx, gy = project(Vector((1,0,0)))-zero, project(Vector((0,1,0)))-zero
j = Matrix(((gx.x*.8,gy.x*.8),(gx.y*.8,gy.y*.8)))
up2 = j.inverted()@Vector((0,-1))
ground = Vector((-.02208799682557583,-.022456128150224686,0))
assert (ground-Vector((up2.x,up2.y,0))).length < 1e-7
offset = Vector(mapping['mechanical_target']['target'])-Vector(mapping['mechanical_target']['contact'])
target2 = j.inverted()@offset
target_ground = Vector((target2.x,target2.y,0))
direction = target_ground.normalized()
yaw = math.atan2(direction.x,-direction.y)-math.atan2(ground.x,-ground.y)
original_contact = native.sample('worn','mine',.55,ground,340.)
mapped = next(c for c in mapping['cases'] if c['label']=='original_native')
assert (project(original_contact['rear'])-Vector(mapped['rear_native_pixel'])).length < .0001
head = next(p for p in mapped['parts'] if 'head' in p['object'])
original_frame = pm.tool_frame(original_contact['axis'],original_contact['tool_normal'])
tip_local = {v['selector']:original_frame.transposed()@(Vector(v['native_world'])-original_contact['rear']) for v in head['head_normal_extrema_not_collision_contacts']}
image = bpy.data.images.load(str(args.texture))
tw,th = image.size
rgba = list(image.pixels)
rx,ry,rw,rh = mapping['actual_target_rect']
hx,hy,hw,hh = mapping['native_candidate_rect']
ore_native_rect = ((rx-hx)*200/hw,(ry-hy)*200/hh,rw*200/hw,rh*200/hh)
ore_points = []
for y in range(th):
    for x in range(tw):
        if rgba[((th-1-y)*tw+x)*4+3]>.5:
            ore_points.append(Vector((ore_native_rect[0]+(x+.5)*ore_native_rect[2]/tw,ore_native_rect[1]+(y+.5)*ore_native_rect[3]/th)))


def target_pose(q, specification):
    return target_contact_pose.sample(q,ground,target_ground,specification)


def geometry(p):
    frame = pm.tool_frame(p['axis'],p['tool_normal'])
    tips = {name:project(p['rear']+frame@local) for name,local in tip_local.items()}
    tip_distance = {name:min((point-v).length for point in ore_points) for name,v in tips.items()}
    return {'shaft_projection_px_per_native_unit':(project(p['rear']+p['axis'])-project(p['rear'])).length,
            'head_extrema_native_pixels':{name:list(v) for name,v in tips.items()},
            'nearest_ore_alpha_pixel_distance':tip_distance,
            'head_extrema_span':(tips['minimum_normal']-tips['maximum_normal']).length,
            'rear_native_pixel':list(project(p['rear']))}


phases = sorted(set([i/128 for i in range(129)]+[.24,.4,.55,.575,.625,.68,.82]))
report = {'complete':False,'rendered':False,'evaluated_native_rig_or_mesh':False,'visually_accepted':False,
          'purpose':'Assess a genuine target-facing upper body and contact arc against the existing selected ore; no runtime changes',
          'projection_sha256':hashlib.sha256(args.projection.read_bytes()).hexdigest(),
          'executed_source_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
          'pose_helper_sha256':hashlib.sha256((Path(__file__).resolve().parent/'target_contact_pose.py').read_bytes()).hexdigest(),
          'selected_world_target_offset':list(offset),'up_native_heading_degrees':math.degrees(math.atan2(ground.x,-ground.y)),
          'target_native_heading_degrees':math.degrees(math.atan2(direction.x,-direction.y)),
          'upper_body_yaw_delta_degrees':math.degrees(yaw),'ground_per_logical_pixel':list(ground),
          'native_target_vector':list(target_ground),'native_ore_rect':list(ore_native_rect),
          'contract_change':'Presentation would need the existing committed target position; cardinal up alone cannot identify this contact arc.',
          'cases':[]}
for lateral in (-.12,0.,.12):
    for forward in (-.4,-.55,-.7):
        for height in (.85,1.,1.15):
            for pitch in (-10,10,30):
                for roll in (0,30):
                    spec = dict(lateral=lateral,forward=forward,height=height,pitch_degrees=pitch,roll_degrees=roll)
                    row = {'specification':spec,'passed':False,'dense_samples':0,'max_reach':0.,'max_segment_error':0.}
                    try:
                        p,_ = target_pose(.55,spec)
                        row['contact_geometry'] = geometry(p)
                        # Geometry here is only a shortlist for dense reach, never visual acceptance.
                        if min(row['contact_geometry']['nearest_ore_alpha_pixel_distance'].values())>1.5:
                            row['rejection']='Both candidate head extrema are outside the actual ore alpha by >1.5 native pixels'
                        else:
                            for q in phases:
                                p,protected = target_pose(q,spec)
                                for field in ('legs','foot_rotations','contacts'): assert p[field] is protected[field]
                                for a,b,c in p['arms'].values():
                                    row['max_reach']=max(row['max_reach'],(c-a).length)
                                    row['max_segment_error']=max(row['max_segment_error'],abs((b-a).length-.36),abs((c-b).length-.35))
                                row['dense_samples']+=1
                            row['passed']=True
                    except Exception as error:
                        row['rejection']=repr(error)
                    report['cases'].append(row)
report['complete']=True
report['passed_count']=sum(c['passed'] for c in report['cases'])
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps(report,indent=2)+'\n')
print('TARGET_CONTACT_REACH_COMPLETE',len(report['cases']),report['passed_count'],flush=True)
