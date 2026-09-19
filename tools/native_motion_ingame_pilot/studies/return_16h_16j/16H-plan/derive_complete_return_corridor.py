"""Derive a whole-return angular corridor against every permitted ore pulse.

Reuses exact evaluated baseline geometry. This is planning, not a candidate,
render, or visual acceptance. No curve parameters are tried here.
"""
import math
from pathlib import Path

SETUP = Path('/tmp/shoulder-arc-16/prepare_arc.py')
exec(compile(SETUP.read_text().split('rows=[]')[0], str(SETUP), 'exec'))
OUT = Path('/tmp/pivot-return-16H-plan')
ACTUAL = Path('/tmp/ever-deeper-loop-flow-20260919/pivot-game-16G/native-ingame.json')
actual = json.loads(ACTUAL.read_text())
assert sha(ACTUAL) == 'e539b5b0308825210e4a2842dda86a70062d6afb1a1075953f013adccf9e56d4'
assert identity['sprite_local_position'] == [0., -3.]
assert identity['sprite_local_scale'] == [.25, .25]
scales = np.array([.91, 1.035])
size = np.array(identity['texture_dimensions'])
sprite_scale = np.array(identity['sprite_local_scale'])
offset = np.array(identity['sprite_local_position'])
local = (ore_hull - size / 2) * sprite_scale + offset
both = np.concatenate([local * s for s in scales])
envelope = both[ConvexHull(both).vertices]

def merge(intervals):
    result = []
    for lo, hi in sorted(intervals):
        if result and lo <= result[-1][1] + 1e-12:
            result[-1] = (result[-1][0], max(result[-1][1], hi))
        else:
            result.append((lo, hi))
    return result

def intersect(a, b):
    return merge([(max(x, u), min(y, v)) for x, y in a for u, v in b
                  if max(x, u) <= min(y, v)])

def scalar(a, b, c):
    radius = math.hypot(a, b)
    if c > radius:
        return []
    if c <= -radius:
        return [(0., math.pi)]
    center = math.atan2(b, a)
    span = math.acos(c / radius)
    return intersect([(0., math.pi)],
                     [(center-span+2*math.pi*k, center+span+2*math.pi*k)
                      for k in (-1, 0, 1)])

rows = []
for z in meta['route']:
    if not (z['phase'] >= .72 or z['phase'] <= .392857142857143):
        continue
    frame = z['frame']
    sample = actual['samples'][frame]
    assert z['state'] == sample['visual']['state'] == 'mine'
    assert z['phase'] == sample['visual']['sample_phase']
    assert z['hero_rect'] == sample['framing']['subjects']['hero_and_tool']
    i = z['kinematics_index']
    hx, hy, hw, hh = z['hero_rect']
    ox, oy, ow, oh = sample['framing']['subjects']['actual_resource_sprite']
    pulse = np.array(sample['resource_hit_presentation']['scale'])
    global_scale = np.array([ow, oh]) / (size * sprite_scale * pulse)
    assert np.max(np.abs(global_scale - 1.)) < 1e-5
    resource_root = np.array([ox+ow/2, oy+oh/2]) - offset*pulse*global_scale
    ore = envelope*global_scale + resource_root
    head = proj['old'][frame]*[hw/160, hh/160]+[hx, hy]
    head = head[ConvexHull(head).vertices]
    pivot = ([80.,80.]+P@(data['grips'][i,0]-np.array([6.,6.,7.]))) * [hw/160,hh/160]+[hx,hy]
    edges = np.roll(ore,-1,axis=0)-ore
    normals = np.stack((edges[:,1],-edges[:,0]),axis=1)
    normals /= np.linalg.norm(normals,axis=1)[:,None]
    allowed = []
    x = head-pivot
    for n in normals:
        aa = x@n
        bb = x@np.array([n[1],-n[0]])
        c = np.max(ore@n)+2.-n@pivot
        one = [(0.,math.pi)]
        for a, b in zip(aa, bb):
            one = intersect(one, scalar(a,b,c))
            if not one:
                break
        allowed.extend(one)
    allowed = merge(allowed)
    rows.append(dict(frame=frame,phase=z['phase'],
                     resource_root=resource_root.tolist(),
                     angle_intervals_degrees=[[math.degrees(a),math.degrees(b)] for a,b in allowed]))

report = dict(complete=True,rendered=False,candidate_created=False,passed_geometry=False,
              source_animation_sha='005f16dace30747f66e87ef1ca049bffc3aeced8',
              actual_capture_sha256=sha(ACTUAL),texture_sha256=sha(texture),
              control_sha256=sha(Path('/tmp/shoulder-arc-16/control.npz')),
              baseline_projections_sha256=sha(PREV/'fixed-tool-projections.npz'),
              pulse_range=scales.tolist(),ore_hull_local=envelope.tolist(),
              margin_px=2.,return_scope='Recorded mine poses q>=.72 or q<=.392857142857143; includes the formerly missed lift.',
              method='Union of exact trigonometric inequalities over all ore-envelope support planes. Positive camera-axis tool rotation about original rear grip, theta in[0,pi].',
              rows=rows,infeasible_frames=[r['frame'] for r in rows if not r['angle_intervals_degrees']])
(OUT/'complete-return-corridor.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'samples':len(rows),'infeasible_frames':report['infeasible_frames'],
                  'rows':[{k:r[k] for k in ('frame','phase','angle_intervals_degrees')} for r in rows]}))
