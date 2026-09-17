"""Measure the frozen return candidate across late/end poses before images.

Replays the reviewed dense rig and unchanged control first. This observer adds
no pose variant and never renders, changes production assets, or accepts motion.
"""
from pathlib import Path
import hashlib
import json
import os
import runpy
import sys

HERE = Path(__file__).resolve().parent
arguments = sys.argv[sys.argv.index('--') + 1:]
reference_index = arguments.index('--reference-result')
reference_path = Path(arguments[reference_index + 1])
del arguments[reference_index:reference_index + 2]
reference_bytes = reference_path.read_bytes()
reference_sha = hashlib.sha256(reference_bytes).hexdigest()
assert reference_sha == 'ee653f7b14212dcce2ba039cd10d5a69cf329824452bb5c975208601fa8d3982'
reference = json.loads(reference_bytes)
assert reference['complete'] and not reference['rendered']
assert reference['executed_source_sha'] == 'eb61cefc1b6a593c0faa7d46fb2e7fdfd073d1d5'
assert reference['candidate_count'] == 1 and reference['amplitude'] == 1.

output = Path(arguments[arguments.index('--output') + 1])
assert not output.exists(), 'Use a fresh output directory'
base_arguments = list(arguments)
base_arguments[base_arguments.index('--output') + 1] = str(output / 'replay')
sys.argv = ['blender', '--', *base_arguments]
base = runpy.run_path(str(HERE / 'probe_return_tool_offset.py'))
replay_path = output / 'replay/return-offset-final.json'
replay_bytes = replay_path.read_bytes()
replay = json.loads(replay_bytes)
for key in ('source_hashes', 'control_source_hashes', 'model_sha256',
            'gear_sha256', 'candidate_count', 'amplitude', 'grip_span',
            'target_ground', 'protected_bones', 'dense_evaluated_poses',
            'critical_poses', 'unchanged_control_recovery',
            'all_bone_endpoint_0_1_error', 'original_recovery_restore_matrix_error'):
    assert replay[key] == reference[key], ('Frozen replay differs', key)
assert sorted(replay['input_reports'].values()) == sorted(reference['input_reports'].values())

control = base['control']
candidate = base['candidate']
rig, mapped, captured = base['rig'], base['mapped'], base['captured']
sample, apply = base['sample'], base['apply']
phases = [0., .125, .375, .55, .625, .6875, .75, .78125, .8125,
          .82, .828125, .875, .90625, .9375, .9921875]
original_critical = {row['phase']: row for row in control['report']['critical_poses']}
before = {bone.name: bone.matrix.copy() for bone in rig.pose.bones}
report = {
    'complete': False, 'rendered': False, 'readability_accepted': False,
    'executed_source_sha': replay['executed_source_sha'],
    'source_tree': replay['source_tree'],
    'observer_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'reference_path': str(reference_path), 'reference_sha256': reference_sha,
    'replay_final_sha256': hashlib.sha256(replay_bytes).hexdigest(),
    'frozen_candidate_replay_exact': True,
    'source_hashes': replay['source_hashes'],
    'control_source_hashes': replay['control_source_hashes'],
    'input_reports': replay['input_reports'],
    'model_sha256': replay['model_sha256'], 'gear_sha256': replay['gear_sha256'],
    'candidate_count': 1, 'amplitude': 1., 'phases': phases,
    'critical_poses': [],
    'scope': 'Same original-model Worn/up candidate across frozen late/end phases. '
             'All original objects, materials and geometry retained. '
             'Pixel-center geometry is not native-image or motion acceptance.',
}
progress = output / 'late-geometry-progress.json'
for q in phases:
    original, _, _, _, _ = sample(q)
    posed, offset = candidate.sample(original, q, control['target'])
    apply(posed)
    captured.clear()
    parts = mapped['measure_parts'](posed, mapped['sample'])
    assert len(captured) == 1
    full, _, owners, objects = captured[0]
    assert {row['name']: row for row in objects} == control['expected_objects']
    assert parts['object_count'] == 629 and parts['evaluated_triangles'] == 2714340
    hands = {side: control['hand_visibility'](side, full, owners)
             for side in control['native'].SIDES}
    measured = {'phase': q, 'parts': parts, 'hands': hands,
                'connections': control['connections'](parts['parts'], hands, posed)}
    if .125 <= q <= .625:
        assert posed is original and offset.length == 0.
        assert measured == original_critical[q], ('Unchanged work geometry differs', q)
    if q == .8125:
        assert {**measured, 'offset': list(offset)} == replay['critical_poses'][0]
    report['critical_poses'].append({**measured, 'offset': list(offset),
                                     'weight': candidate.weight(q)})
    progress.write_text(json.dumps(report, indent=2) + '\n')
    shaft = next(row for row in parts['parts']
                 if row['object'] == 'round source-textured shaft')
    print('RETURN_LATE_GEOMETRY', q,
          'shaft', shaft['visible_pixel_centers'], shaft['projected_pixel_centers'],
          'hands', [(s, hands[s]['visible_pixel_centers'], hands[s]['projected_pixel_centers'])
                    for s in control['native'].SIDES],
          'components', [row['pixel_count'] for row in measured['connections']['components']],
          flush=True)
    captured.clear()
    del full, owners, objects

original, _, _, _, _ = sample(.8125)
apply(original)
restore_error = max(control['matrix_error'](before[n], rig.pose.bones[n].matrix)
                    for n in before)
assert restore_error < 1e-5
report['original_recovery_restore_matrix_error'] = restore_error
report['original_recovery_pose_restored'] = True
report['next_gate'] = ('Independent full late/end geometry review before native images; '
                       'record all occlusion and disconnected components. '
                       'Idle/walk transitions, other tools and targets remain open.')
report['complete'] = True
pending = output / 'late-geometry-final.json.pending'
final = output / 'late-geometry-final.json'
data = (json.dumps(report, indent=2) + '\n').encode()
with pending.open('xb') as handle:
    handle.write(data)
    handle.flush()
    os.fsync(handle.fileno())
os.replace(pending, final)
fd = os.open(output, os.O_RDONLY)
try:
    os.fsync(fd)
finally:
    os.close(fd)
assert final.read_bytes() == data
print('RETURN_LATE_FINAL_SHA256', hashlib.sha256(data).hexdigest(), len(data), flush=True)
