"""Review the complete-return bank against a prior closed input route.

This checks mechanical equivalence and actual captured contact/squash order.
It does not approve readability, collision, arbitrary inputs or publication.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path

from PIL import Image

MECHANICS = ('relative_physics_tick', 'position', 'direction', 'mining_active',
             'mining_elapsed', 'mining_progress', 'relative_impact_serial',
             'target', 'target_hp')
INPUT = ('label', 'movement', 'mine', 'position', 'relative_physics_tick')
POSE = ('state', 'sample_phase', 'local_frame', 'is_bridge', 'retained_offset',
        'requested_phase', 'state_elapsed', 'sprite_position', 'presenting_impact')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def project(record, keys):
    return {key: record[key] for key in keys}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source-sha', required=True)
    p.add_argument('--manifest-sha', required=True)
    p.add_argument('--old-report-sha', required=True)
    p.add_argument('--old', type=Path, required=True)
    p.add_argument('--new', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--entry-report', type=Path)
    p.add_argument('--new-manifest', type=Path)
    a = p.parse_args()
    assert not a.output.exists(), 'Preserve prior results; choose a new path.'
    old = json.loads((a.old / 'native-ingame.json').read_text())
    new = json.loads((a.new / 'native-ingame.json').read_text())
    assert new['source_sha'] == a.source_sha and new['verify_contact_frames']
    assert old['passed'] and new['passed'] and not new['failures']
    assert old['mode'] == new['mode'] == 'candidate'
    assert new['complete_return'] and new['asset_hashes']['manifest.json'] == a.manifest_sha
    assert sha(a.old / 'native-ingame.json') == a.old_report_sha
    entry = None
    if a.entry_report:
        entry = json.loads(a.entry_report.read_text())
        assert entry['complete'] and entry['source_sha'] == a.source_sha
        assert entry['reference_report_sha256'] == a.old_report_sha
        assert new['grounded_entry_probe'] and old['consumer_sha256'] == new['consumer_sha256']
        assert a.new_manifest and sha(a.new_manifest) == a.manifest_sha
        manifest = json.loads(a.new_manifest.read_text())
        assert manifest['loop_flow_study']['report_sha256'] == sha(a.entry_report)
        assert len(entry['planned_draws']) == len(new['samples']) == 119
        projection = entry['projection']
        def projected(point):
            return [projection['origin'][j] + sum(projection['basis'][k][j]*point[k] for k in range(3)) for j in range(2)]
    phase_changes = []
    selection_changes = []
    common = tuple(k for k in POSE if all(k in x['visual'] for x in old['samples'] + new['samples']))
    stable = ('is_bridge', 'retained_offset', 'sprite_position', 'presenting_impact')
    assert len(old['samples']) == len(new['samples']) == len(new['captures'])
    for sample_index, (left, right) in enumerate(zip(old['samples'], new['samples'])):
        assert project(left, MECHANICS) == project(right, MECHANICS)
        if entry is None:
            assert project(left['visual'], stable) == project(right['visual'], stable)
        else:
            plan = entry['planned_draws'][sample_index]
            shown = right['visual']
            assert plan['sample'] == sample_index and shown['state'] == plan['state'] and shown['local_frame'] == plan['local_frame']
            for key in ('sample_phase', 'requested_phase'):
                assert abs(shown[key]-plan[key]) < 1e-7, (sample_index, key)
            for key in ('sprite_position', 'retained_offset'):
                assert max(abs(v-w) for v,w in zip(shown[key],plan[key])) < .00002, (sample_index,key)
            assert shown['is_bridge'] == (shown['state'] in manifest['directions']['up']['transitions'])
            assert shown['presenting_impact'] == left['visual']['presenting_impact']
            frame = manifest['sample_metadata']['up'][shown['state']][shown['local_frame']]
            for point in plan['projected_lower_body_points']:
                xy = projected(frame['native']['feet'][point['side']][point['point']])
                xy = [v+w for v,w in zip(xy,shown['sprite_position'])]
                assert max(abs(v-w) for v,w in zip(xy,point['before'])) < .0003, (sample_index,point['side'],point['point'])
        changes = {k: [left['visual'][k], right['visual'][k]] for k in common if left['visual'][k] != right['visual'][k]}
        if changes: selection_changes.append({'sample': sample_index, 'changes': changes})
        if left['visual']['sample_phase'] != right['visual']['sample_phase']:
            phase_changes.append({'sample': sample_index, 'tick': right['relative_physics_tick'], 'old': left['visual']['sample_phase'], 'new': right['visual']['sample_phase']})
        if entry is None:
            assert left['framing']['subjects']['hero_and_tool'] == right['framing']['subjects']['hero_and_tool']
        else:
            # During the longer entry the retained plant is baked into its
            # native images, then moves to sprite placement at the handoff.
            # Compare effective feet above, and account for that exact rect shift.
            old_rect = left['framing']['subjects']['hero_and_tool']
            new_rect = right['framing']['subjects']['hero_and_tool']
            delta = [v-w for v,w in zip(right['visual']['sprite_position'],left['visual']['sprite_position'])]
            expected = [old_rect[0]+delta[0],old_rect[1]+delta[1],*old_rect[2:]]
            assert max(abs(v-w) for v,w in zip(expected,new_rect)) < .001, (sample_index,'entry rectangle')
    assert [project(x, INPUT) for x in old['events']] == [project(x, INPUT) for x in new['events']]
    world = {}
    for filename in ('setup-world.json', 'final-world.json'):
        left, right = a.old / filename, a.new / filename
        assert json.loads(left.read_text()) == json.loads(right.read_text())
        world[filename] = {'old_sha256': sha(left), 'new_sha256': sha(right), 'equal': True}
    records = [json.loads(line) for line in (a.new / 'frames.jsonl').read_text().splitlines()]
    assert len(records) == len(new['samples'])
    for i, (sample, capture) in enumerate(zip(new['samples'], new['captures'])):
        assert records[i] == {'sample': sample, 'capture': capture}
        assert capture['sample'] == i
        assert sha(a.new / capture['path']) == capture['sha256']
        with Image.open(a.new / capture['path']) as image:
            image.load()
            assert image.size == (1696, 780)
    hits = []
    for i in range(1, len(new['samples']) - 2):
        before, hit, squash, release = new['samples'][i-1:i+3]
        if hit['target_hp'] >= before['target_hp']:
            continue
        b, h, s, r = (x['resource_hit_presentation'] for x in (before, hit, squash, release))
        assert h['phase'] == 'contact' and h['scale'] == b['scale']
        assert s['phase'] == 'squash' and max(abs(v-.91) for v in s['scale']) < 1e-6
        assert s['phase_after_draw'] > h['phase_after_draw']
        assert r['phase'] == 'pulse'
        assert hit['visual']['sample_phase'] == .55 and hit['visual']['presenting_impact']
        hits.append({'hit_sample': i, 'hp': [before['target_hp'], hit['target_hp']],
                     'old_hit_resource_rectangle': old['samples'][i]['framing']['subjects']['actual_resource_sprite'],
                     'draws': [{'sample': j, 'hp': new['samples'][j]['target_hp'],
                                'presentation': new['samples'][j]['resource_hit_presentation'],
                                'resource_rectangle': new['samples'][j]['framing']['subjects']['actual_resource_sprite'],
                                'png_sha256': new['captures'][j]['sha256']}
                               for j in range(i-1, min(i+5, len(new['samples'])))]})
    assert len(hits) == (1 if new['bridge_restart_cycle'] or new['cancel_cycle'] else 2)
    result = {'schema': 1, 'helper_sha256': sha(Path(__file__)),
              'source_sha': a.source_sha, 'runtime_world_sha256': new['runtime_world_sha256'],
              'old_report_sha256': sha(a.old / 'native-ingame.json'),
              'new_report_sha256': sha(a.new / 'native-ingame.json'),
              'old_capture_path': str(a.old), 'new_capture_path': str(a.new),
              'frame_count': len(new['captures']), 'mechanics_equal': True,
              'mechanical_keys': MECHANICS, 'input_equal': True, 'input_keys': INPUT,
              'native_pose_equal': False, 'hero_bounds_equal': entry is None, 'selection_keys_compared': stable,
              'selected_phase_changes': phase_changes, 'selected_state_and_clock_changes': selection_changes, 'changed_pose_bank': True,
              'selection_keys_absent_from_prior_schema': [k for k in POSE if k not in common],
              'world': world, 'jsonl_and_all_new_png_hashes_and_decodes_verified': True,
              'contact_order_verified_in_actual_draws': True, 'hits': hits,
              'scope': 'Both old and new actual input runs closed. Pulse phase means '
                       'recovery is released; the unchanged 30 Hz owner may lerp on a later draw. '
                       'No proof of physical or unoccluded contact, readability, arbitrary inputs or production acceptance.',
              'visual_approved': False, 'production_approved': False}
    if entry:
        result.update(entry_report_sha256=sha(a.entry_report),exact_planned119_selections_verified=True,
                      actual_packed_ankle_and_sole_projections_match_prior=True,
                      hero_rectangles_follow_exact_retained_offset_placement=True,
                      entry_duration=entry['entry_duration'])
    with a.output.open('w') as f:
        json.dump(result, f, indent=2); f.write('\n'); f.flush(); os.fsync(f.fileno())
    print(json.dumps({'output': str(a.output), 'sha256': sha(a.output),
                      'frames': len(new['captures']), 'hit_samples': [h['hit_sample'] for h in hits]}))


if __name__ == '__main__':
    main()
