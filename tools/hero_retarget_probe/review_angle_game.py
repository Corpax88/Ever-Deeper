"""Verify one actual angle-study route against its closed mechanics control."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools/native_motion_ingame_pilot'))
from review_complete_return_game import MECHANICS, INPUT, project

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--old', type=Path, required=True)
p.add_argument('--new', type=Path, required=True)
p.add_argument('--bank', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
assert not a.output.exists()
sha = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
old = json.loads((a.old/'native-ingame.json').read_text())
new = json.loads((a.new/'native-ingame.json').read_text())
identity = json.loads((a.bank/'identity.json').read_text())
manifest = json.loads((a.bank/'manifest.json').read_text())
assert old['passed'] and new['passed'] and not new['failures']
assert new['view_angle_probe'] and new['complete_return'] and new['verify_contact_frames']
assert new['view_angle_identity_sha256'] == sha(a.bank/'identity.json')
assert new['asset_hashes'] == identity['asset_hashes']
for name, digest in identity['asset_hashes'].items(): assert sha(a.bank/name) == digest
assert len(old['samples']) == len(new['samples']) == len(new['captures']) == 119
presented = set()
for before, after, capture in zip(old['samples'], new['samples'], new['captures']):
    assert project(before, MECHANICS) == project(after, MECHANICS)
    for key in ('state', 'sample_phase', 'local_frame', 'presenting_impact', 'is_bridge', 'retained_offset'):
        assert before['visual'][key] == after['visual'][key], key
    cell = '%s:%d' % (after['visual']['state'], after['visual']['local_frame'])
    assert cell in identity['rendered_cells']
    presented.add(cell)
    assert max(abs(x-y) for x,y in zip(after['visual']['ground_anchor'],
                                      manifest['directions']['up']['ground_anchor'])) < 1e-5
    png = a.new/capture['path']
    assert sha(png) == capture['sha256']
    with Image.open(png) as image:
        image.load()
        assert image.size == (1696, 780)
assert [project(s, INPUT) for s in old['events']] == [project(s, INPUT) for s in new['events']]
for name in ('setup-world.json', 'final-world.json'):
    assert json.loads((a.old/name).read_text()) == json.loads((a.new/name).read_text())
hits = [i for i in range(1,119) if new['samples'][i]['target_hp'] < new['samples'][i-1]['target_hp']]
assert hits == [50, 90]
report = {'passed': True, 'captured_frames': 119, 'presented_unique_cells': len(presented),
          'hit_samples': hits, 'mechanics_inputs_world_unchanged': True,
          'original_report_sha256': sha(a.old/'native-ingame.json'),
          'new_report_sha256': sha(a.new/'native-ingame.json'),
          'manifest_sha256': sha(a.bank/'manifest.json'),
          'visual_accepted': False, 'production_accepted': False,
          'limits': 'Actual angle test only; view-dependent sprite placement may differ. No proof of tool contact, readability, all states or physical-device FPS.'}
a.output.write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report))
