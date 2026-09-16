"""Endpoint/world-contact velocity evidence for the native pilot, without renders."""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
from mathutils import Vector
import locomotion as gait
import native_motion as native
import premium_motion as pm


def points(p):
    result = {key: p[key].translation for key in ('torso', 'head')}
    for key in ('torso', 'head'):
        for col in range(3):
            result[f'{key}_axis{col}'] = p[key].to_3x3().col[col]
    for key in ('rear', 'axis', 'tool_normal'):
        result[key] = p[key]
    for key in ('arms', 'legs'):
        for side, chain in p[key].items():
            for i, point in enumerate(chain):
                result[f'{key}_{side}_{i}'] = point
    return result


def velocity(a, b, h):
    aa, bb = points(a), points(b)
    return {key: (bb[key]-aa[key])/h for key in aa}


def endpoint_velocity(origin, first, second, h, backwards=False):
    a, b, c = points(origin), points(first), points(second)
    sign = -1. if backwards else 1.
    return {key: ((b[key]-a[key])*2.-(c[key]-a[key])*.5)*(sign/h) for key in a}


def run(args):
    eps = .0001
    worst_velocity = dict(error=0.)
    worst_slip = dict(error=0.)
    count = 0
    contacts = 0
    failures = []
    source_hashes = {name: hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in
                     ('native_motion.py', 'locomotion.py', 'premium_motion.py', 'review_native_continuity.py')}
    for gear in ('worn', 'crusher', 'deepcore'):
        for direction, ground in gait.GROUND_PER_PIXEL.items():
            for source, target in (('idle', 'walk'), ('walk', 'idle'), ('walk', 'mine'), ('mine', 'walk'), ('mine', 'idle')):
                for phase in ([0.] if source == 'idle' else [0., .125, .25, .375, .5, .625, .75, .875]):
                    clip = native.Transition(gear, source, phase, target, ground, args.speed)
                    label = f'{gear}:{direction}:{source}:{phase:g}:{target}'
                    source_v = Vector(ground)*(args.speed if source == 'walk' else 0.)
                    target_v = Vector(ground)*(args.speed if target == 'walk' else 0.)
                    before = pm.translate_pose(native.sample(gear, source, clip.phase_at(source, phase, -eps), ground, args.speed), -source_v*eps)
                    before2 = pm.translate_pose(native.sample(gear, source, clip.phase_at(source, phase, -2.*eps), ground, args.speed), -source_v*(2.*eps))
                    start = clip.sample(0.)
                    next_pose = pm.translate_pose(clip.sample(eps), target_v*eps)
                    next2 = pm.translate_pose(clip.sample(2.*eps), target_v*(2.*eps))
                    first = endpoint_velocity(start, before, before2, eps, True)
                    second = endpoint_velocity(start, next_pose, next2, eps)
                    end = clip.sample(clip.duration)
                    previous = pm.translate_pose(clip.sample(clip.duration-eps), -target_v*eps)
                    previous2 = pm.translate_pose(clip.sample(clip.duration-2.*eps), -target_v*(2.*eps))
                    after = pm.translate_pose(native.sample(gear, target,
                        clip.phase_at(target, clip.target_phase, clip.duration+eps), ground, args.speed),
                        clip.destination_offset+target_v*eps)
                    after2 = pm.translate_pose(native.sample(gear, target,
                        clip.phase_at(target, clip.target_phase, clip.duration+2.*eps), ground, args.speed),
                        clip.destination_offset+target_v*(2.*eps))
                    pairs = [('entry', first, second), ('exit', endpoint_velocity(end, previous, previous2, eps, True), endpoint_velocity(end, after, after2, eps))]
                    for endpoint, a, b in pairs:
                        for key in a:
                            difference = (a[key]-b[key]).length
                            if difference > worst_velocity['error']:
                                worst_velocity = dict(case=label, endpoint=endpoint, point=key, error=difference)
                    for i in range(1, 32):
                        t = clip.duration*i/32.
                        p = clip.sample(t)
                        a, b = clip.sample(t-eps), clip.sample(t+eps)
                        for side in native.SIDES:
                            if not (p['contacts'][side] and a['contacts'][side] and b['contacts'][side]):
                                continue
                            angle = native.foot_angle(p, side, clip.heading)
                            y, z = min(gait.BOOT_HULL, key=lambda yz: yz[0]*math.sin(angle)+yz[1]*math.cos(angle))
                            vertex = Vector((0., y, z))
                            pa = a['legs'][side][2]+a['foot_rotations'][side]@vertex-target_v*eps
                            pb = b['legs'][side][2]+b['foot_rotations'][side]@vertex+target_v*eps
                            slip = ((pb-pa)/(2.*eps)).length
                            contacts += 1
                            if slip > worst_slip['error']:
                                worst_slip = dict(case=label, time=t, side=side, error=slip)
                    count += 1
    if worst_velocity['error'] > .1:
        failures.append('Endpoint finite-difference velocity exceeds0.1native units/s (or basis units/s).')
    if worst_slip['error'] > .02:
        failures.append('Ground contact material-point speed exceeds0.02native units/s.')
    report = dict(passed=not failures, transition_cases=count, sampled_sole_contacts=contacts,
        epsilon_seconds=eps, finite_difference_order=2, worst_endpoint_velocity=worst_velocity, worst_contact_speed=worst_slip,
        source_sha256=source_hashes, failures=failures, rendered_frames=0, evaluated_meshes=0,
        limitations=['Finite differences contain float32 and curvature residuals.',
                     'This samples the raw sole hull; evaluated bevels and gameplay frame quantization are separate gates.',
                     'No interrupted-transition or arbitrary-speed certification.'])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report), flush=True)
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--speed', type=float, default=340.)
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    if not run(args)['passed']:
        sys.exit(1)
