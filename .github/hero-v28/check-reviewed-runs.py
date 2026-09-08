"""Require successful, identified checks of the exact reviewed game package."""
import json
import sys
from pathlib import Path

review = json.loads(Path(__file__).with_name('review.json').read_text())
root = Path(sys.argv[1])
run = json.loads((root / 'package-run.json').read_text())
assert run['id'] == review['qa_run_id']
assert run['head_sha'] == review['source_commit']
assert run['status'] == 'completed'

jobs = {job['name']: job for job in json.loads((root / 'package-jobs.json').read_text())['jobs']}
required = {'build', 'gameplay', 'visual (1-48)', 'visual (49-96)',
            'visual (97-144)', 'visual (145-192)'}
assert required <= jobs.keys()
for name in required:
    assert jobs[name]['conclusion'] == 'success', name

# Two harness failures are retained as failures in the original run. Their
# replacements download its same candidate artifact: 216 real states (Starfall
# has no depth-two gate), and motion progress supplied by actual damage events.
for name in ['environment', 'motion']:
    evidence = review['supplemental_runs'][name]
    result = json.loads((root / (name + '-run.json')).read_text())
    assert result['id'] == evidence['run_id']
    assert result['head_sha'] == evidence['head_sha']
    assert result['conclusion'] == 'success', name
assert review['visual_reviewed'] and review['package_checks_passed']
assert review['visual_capture_count'] == 216
assert review['real_mining_combinations'] == 12
print('Required original checks and both exact-package replacements passed')
