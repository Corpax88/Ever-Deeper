#!/usr/bin/env python3
"""Post-run source comparison only; no renderer or game mutation."""
import argparse
import hashlib
import json
from pathlib import Path

root = argparse.ArgumentParser()
root.add_argument('evidence', type=Path)
root = root.parse_args().evidence
capture = json.loads((root/'mac/resource-capture.json').read_text())
analysis = json.loads((root/'mac/shader-identity-analysis.json').read_text())
sources = {s['id']: s['glsl'] for s in capture['identity']['sources']}
flags = ['#define DISABLE_LIGHTING\n', '#define USE_ATTRIBUTES\n', '#define USE_PRIMITIVE\n']


def normalize(text):
    prefix, body = text.split('#define FRAGMENT_CODE_USED', 1)
    for flag in flags:
        prefix = prefix.replace(flag, '')
    return prefix + '#define FRAGMENT_CODE_USED' + body


queries = analysis['timed_program_status']
assert len(queries) == 1 and queries[0]['link']['program'] == 45
target = [s['source'] for s in queries[0]['link']['shaders']]
assert target == [89, 90]
matches = []
for link in analysis['program_links']:
    ids = [s['source'] for s in link['shaders']]
    if 'if ((color.a == 0.0))' not in sources[ids[1]]:
        continue
    assert len(ids) == 2
    assert all(normalize(sources[ids[i]]) == normalize(sources[target[i]]) for i in range(2))
    matches.append({'program': link['program'], 'sources': ids, 'link_event': link['event'],
                    'during_window': link['during_window'],
                    'prefix_defines': [x for x in sources[ids[0]].split('#define FRAGMENT_CODE_USED')[0].splitlines() if x.startswith('#define ')],
                    'normalized_utf8_sha256': [hashlib.sha256(normalize(sources[i]).encode()).hexdigest() for i in ids],
                    'source_pair_sha256': link['source_pair_sha256']})
assert [m['program'] for m in matches] == [40, 41, 42, 43, 45]
state = json.loads((root/'mac/save-before.json').read_text())['document']['state']
result = {'schema': 1, 'normalization': 'Remove only DISABLE_LIGHTING, USE_PRIMITIVE and USE_ATTRIBUTES define lines from the leading prefix before FRAGMENT_CODE_USED; all remaining text in both shader stages must match byte-for-byte.',
          'programs': matches, 'no_exact_pair_repetition': len(analysis['repeated_source_pairs']) == 0,
          'saved_starforge_variant': state['starforge_variant'], 'saved_drill_level': state['drill_level']}
(root/'source-family-comparison.json').write_text(json.dumps(result, indent=2)+'\n')
print('BOTH_STAGES_MATCH_IN_FIVE_PROGRAMS_AFTER_ONLY_RECORDED_PREFIX_DEFINES')
