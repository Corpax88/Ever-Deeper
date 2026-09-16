"""Cheap Blender pose checks; never renders or changes the production atlases.

blender -b --factory-startup --python tools/hero_v28/review_native_motion.py --
    --output /absolute/native-motion-numeric.json --quick
The report explicitly separates target poses from evaluated meshes/gameplay.
"""
import argparse
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


def point_error(a, b):
    values = [(a[k].translation-b[k].translation).length for k in ('torso', 'head')]
    values += [(a['rear']-b['rear']).length]
    for field in ('arms', 'legs'):
        for side in native.SIDES:
            values += [(x-y).length for x, y in zip(a[field][side], b[field][side])]
    return max(values)


def run(args):
    failures = []
    samples = 0
    min_leg_margin = float('inf')
    min_sole_clearance = float('inf')
    endpoint_error = 0.
    rotor_decrease = 0.
    transition_count = 0
    cases = []
    gears = ('worn', 'crusher', 'deepcore') if args.quick else tuple(pm.WEIGHT)+tuple(pm.ROTOR)
    phase_count = 8 if args.quick else 48
    step_count = 9 if args.quick else 33
    speeds = [float(v) for v in args.speeds.split(',')]

    def inspect(p):
        nonlocal samples, min_leg_margin, min_sole_clearance
        samples += 1
        for side in native.SIDES:
            hip, _, foot = p['legs'][side]
            min_leg_margin = min(min_leg_margin, gait.LEG_LENGTH-(hip-foot).length)
        for side, data in native.frame_metadata(p, ground)['feet'].items():
            min_sole_clearance = min(min_sole_clearance, data['sole_point'][2]-gait.GROUND)

    for gear in gears:
        for direction, ground in gait.GROUND_PER_PIXEL.items():
            for speed in speeds:
                label = f'{gear}:{direction}:{speed:g}'
                for state in ('idle', 'walk', 'mine'):
                    for i in range(phase_count*2):
                        try:
                            inspect(native.sample(gear, state, i/(phase_count*2), ground, speed))
                        except (ValueError, AssertionError) as error:
                            failures.append(dict(case=label, state=state, phase=i/(phase_count*2), error=str(error)))
                for source, target in (('idle', 'walk'), ('walk', 'idle'), ('walk', 'mine'), ('mine', 'walk'), ('mine', 'idle')):
                    for i in range(phase_count):
                        if source == 'idle' and i:
                            continue
                        phase = i/phase_count
                        try:
                            clip = native.Transition(gear, source, phase, target, ground, speed)
                            previous = None
                            for j in range(step_count):
                                p = clip.sample(clip.duration*j/(step_count-1))
                                inspect(p)
                                if clip.coast and previous is not None:
                                    rotor_decrease = max(rotor_decrease, previous-p['bit_angle'])
                                previous = p['bit_angle']
                            start = clip.sample(0.)
                            expected = native.sample(gear, source, phase, ground, speed)
                            endpoint_error = max(endpoint_error, point_error(start, expected))
                            end = clip.sample(clip.duration)
                            expected = pm.translate_pose(native.sample(gear, target,
                                clip.phase_at(target, clip.target_phase, clip.duration), ground, speed), clip.destination_offset)
                            endpoint_error = max(endpoint_error, point_error(end, expected))
                            transition_count += 1
                        except (ValueError, AssertionError) as error:
                            failures.append(dict(case=label, source=source, target=target, phase=phase, error=str(error)))
                cases.append(label)
    if endpoint_error > 2e-5:
        failures.append(dict(check='transition endpoint pose', maximum_native_error=endpoint_error))
    if min_sole_clearance < -2e-6:
        failures.append(dict(check='raw sole penetration', minimum_native_clearance=min_sole_clearance))
    if rotor_decrease > 1e-8:
        failures.append(dict(check='rotor reverses', maximum_radians=rotor_decrease))
    report = dict(passed=not failures, schema_version=native.SCHEMA_VERSION,
        cases=cases, sampled_target_poses=samples, checked_transitions=transition_count,
        min_leg_margin=min_leg_margin, min_raw_sole_clearance=min_sole_clearance,
        maximum_endpoint_position_error=endpoint_error, maximum_rotor_decrease=rotor_decrease,
        failures=failures, rendered_frames=0, evaluated_meshes=0,
        gameplay_verified=False, production_atlases_changed=False, visual_score=None,
        limitations=['Target-pose/IK checks are not visual acceptance.',
                     'Game-speed cadence, velocity continuity and evaluated bevel support require further review.',
                     'Phase-indexed pilot clips do not cover arbitrary interrupted transitions.'])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({k: report[k] for k in ('passed', 'sampled_target_poses', 'checked_transitions',
                     'min_leg_margin', 'min_raw_sole_clearance', 'maximum_endpoint_position_error')}), flush=True)
    for failure in failures[:12]:
        print(json.dumps(failure), flush=True)
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--speeds', default='340')
    parser.add_argument('--quick', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    report = run(args)
    if not report['passed']:
        sys.exit(1)
