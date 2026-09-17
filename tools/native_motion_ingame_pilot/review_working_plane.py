"""Target-pose constraints against the exact rejected native source; no render.

The exporter --validate-only separately checks evaluated native bone matrices
and hand/tool attachment. Neither result establishes visual readability.
"""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import math
import sys
import bpy
from mathutils import Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parents[1] / 'hero_v28'
sys.path.insert(0, str(ROOT))
import native_motion as candidate
import premium_motion as pm

parser = argparse.ArgumentParser()
parser.add_argument('--baseline-native', required=True, type=Path)
parser.add_argument('--output', required=True, type=Path)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
assert hashlib.sha256(args.baseline_native.read_bytes()).hexdigest() == '54b2eae8ecc6b335b8c4bccdff26c2700ce4009e7215d6397d698cfd7c0f86a3'
spec = importlib.util.spec_from_file_location('rejected_native_baseline', args.baseline_native)
baseline = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = baseline
spec.loader.exec_module(baseline)


def difference(a, b):
    if isinstance(a, dict):
        assert a.keys() == b.keys(), (a.keys(), b.keys())
        return max((difference(a[k], b[k]) for k in a), default=0.)
    if isinstance(a, (tuple, list, Vector, Matrix)):
        assert len(a) == len(b)
        return max((difference(x, y) for x, y in zip(a, b)), default=0.)
    if isinstance(a, (int, float)):
        return abs(a-b)
    assert a == b, (a, b)
    return 0.


scene = bpy.context.scene
scene.render.resolution_x = scene.render.resolution_y = 200
scene.render.resolution_percentage = 100
camera_data = bpy.data.cameras.new('ConstraintCamera')
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 2.9
camera = bpy.data.objects.new('ConstraintCamera', camera_data)
scene.collection.objects.link(camera)
scene.camera = camera


def ground(direction):
    camera.location = (6, 6, 7) if direction == 'up' else (-6, -1, 4.5)
    camera.rotation_euler = (Vector((0, -.10, .98))-camera.location).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    zero = world_to_camera_view(scene, camera, Vector())
    x = (world_to_camera_view(scene, camera, Vector((1, 0, 0)))-zero)*160
    y = (world_to_camera_view(scene, camera, Vector((0, 1, 0)))-zero)*160
    g = Matrix(((x.x, y.x), (-x.y, -y.y))).inverted()@Vector((0, -1) if direction == 'up' else (1, 0))
    return Vector((g.x, g.y, 0))


report = {'passed': False, 'rendered_frames': 0, 'evaluated_native_rigs': 0,
          'baseline_source_sha': 'f34bf7486f560ba104c137009a5affe50d2a642b',
          'native_offset': list(candidate.UP_WORKING_PLANE_OFFSET),
          'controls': {}, 'transitions': [], 'canonical_samples': 0,
          'maximum_preserved_field_difference': 0., 'maximum_arm_length_error': 0.,
          'maximum_shoulder_wrist_distance': 0., 'minimum_raw_sole_z': math.inf,
          'maximum_transition_endpoint_error': 0.,
          'limitations': ['Target poses do not certify evaluated skin/grip attachment.',
                          'A translated rigid tool has a translated tip; actual ore contact needs images.',
                          'Unchanged phase counts do not address the rejected bank sampling-density limit.',
                          'No arbitrary input interrupts, other directions or gears receive visual approval.']}
preserved = ('torso', 'head', 'axis', 'tool_normal', 'legs', 'foot_rotations', 'contacts', 'bit_angle')
phases = sorted(set([i/128 for i in range(129)]+[.24, .40, .55, .575, .625, .68, .82]))


def inspect(original, changed, g):
    error = difference({k:original[k] for k in preserved}, {k:changed[k] for k in preserved})
    report['maximum_preserved_field_difference'] = max(report['maximum_preserved_field_difference'], error)
    assert error == 0., ('Changed protected pose fields', error)
    for shoulder, elbow, wrist in changed['arms'].values():
        reach = (wrist-shoulder).length
        report['maximum_shoulder_wrist_distance'] = max(report['maximum_shoulder_wrist_distance'], reach)
        error = max(abs((elbow-shoulder).length-.36), abs((wrist-elbow).length-.35))
        report['maximum_arm_length_error'] = max(report['maximum_arm_length_error'], error)
        assert error < 2e-6 and reach < .71-1e-5
    feet = candidate.frame_metadata(changed, g)['feet']
    original_feet = baseline.frame_metadata(original, g)['feet']
    assert difference(feet, original_feet) == 0.
    report['minimum_raw_sole_z'] = min(report['minimum_raw_sole_z'], *[v['sole_point'][2] for v in feet.values()])


try:
    up = ground('up')
    displacement = pm.heading_matrix(up)@Vector(candidate.UP_WORKING_PLANE_OFFSET)
    origin = world_to_camera_view(scene, camera, Vector())
    screen = world_to_camera_view(scene, camera, displacement)-origin
    report['up_heading_degrees'] = math.degrees(math.atan2(up.x, -up.y))
    report['native_displacement'] = list(displacement)
    report['projected_displacement_160px'] = [screen.x*160, -screen.y*160]
    for phase in phases:
        original = baseline.sample('worn', 'mine', phase, up, 340.)
        changed = candidate.sample('worn', 'mine', phase, up, 340., direction='up', up_working_plane=True)
        inspect(original, changed, up)
        assert ((changed['rear']-original['rear'])-displacement).length < 1e-7
        report['canonical_samples'] += 1
    for direction, gear, samples, enabled in [('up', 'worn', phases, False), ('right', 'worn', phases, True)] + [
            ('up', gear, [i/32 for i in range(33)], True) for gear in (*pm.WEIGHT, *pm.ROTOR) if gear != 'worn']:
        g = ground(direction)
        count = 0
        for state in ('idle', 'walk', 'mine'):
            for phase in samples:
                original = baseline.sample(gear, state, phase, g, 340.)
                changed = candidate.sample(gear, state, phase, g, 340., direction=direction, up_working_plane=enabled)
                assert difference(original, changed) == 0., (gear, direction, state, phase)
                count += 1
        report['controls'][f'{gear}/{direction}/enabled={enabled}'] = {'exact_equal_poses': count}
    for state in ('idle', 'walk'):
        for phase in phases:
            assert difference(baseline.sample('worn', state, phase, up, 340.),
                              candidate.sample('worn', state, phase, up, 340., direction='up', up_working_plane=True)) == 0.
        report['controls'][f'worn/up/{state}/enabled=True'] = {'exact_equal_poses': len(phases)}
    for direction in ('up', 'right'):
        g = ground(direction)
        for source, phase, target in [('idle', 0., 'walk'), ('walk', .625, 'mine'), ('mine', .625, 'walk')]:
            old = baseline.Transition('worn', source, phase, target, tuple(g), 340., .68, .42)
            new = candidate.Transition('worn', source, phase, target, tuple(g), 340., .68, .42,
                                       direction=direction, up_working_plane=True)
            assert difference(old.metadata(), new.metadata()) == 0.
            for i in range(129):
                a, b = old.sample(old.duration*i/128), new.sample(new.duration*i/128)
                inspect(a, b, g)
                if direction == 'right' or source == 'idle':
                    assert difference(a, b) == 0.
            expected_start = candidate.sample('worn', source, phase, g, 340., direction=direction, up_working_plane=True)
            expected_end = pm.translate_pose(candidate.sample('worn', target,
                new.phase_at(target, new.target_phase, new.duration), g, 340., direction=direction, up_working_plane=True), new.destination_offset)
            fields = ('torso', 'head', 'rear', 'axis', 'tool_normal', 'grips', 'arms', 'legs', 'foot_rotations', 'contacts', 'bit_angle')
            endpoint = max(difference({k:p[k] for k in fields}, {k:e[k] for k in fields})
                           for p, e in [(new.sample(0.), expected_start), (new.sample(new.duration), expected_end)])
            assert endpoint < 2e-5
            report['maximum_transition_endpoint_error'] = max(report['maximum_transition_endpoint_error'], endpoint)
            report['transitions'].append({'direction':direction, 'source':source, 'source_phase':phase, 'target':target,
                                           'duration':new.duration, 'samples':129, 'unchanged_timing_and_offsets':True})
    assert report['minimum_raw_sole_z'] >= -.000002
    report['passed'] = True
except Exception as error:
    report['failure'] = repr(error)
finally:
    report['source_hashes'] = {str(p.relative_to(ROOT.parent.parent)): hashlib.sha256(p.read_bytes()).hexdigest()
                             for p in [ROOT/'native_motion.py', ROOT/'export_hero.py', Path(__file__)]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report), flush=True)
if not report['passed']:
    raise SystemExit(1)
