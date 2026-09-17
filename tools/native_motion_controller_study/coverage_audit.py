"""Enumerate the actual raster bank's route gaps. No invented transition closure."""
import argparse
import hashlib
import itertools
import json
from pathlib import Path

STATES = ('idle', 'walk', 'mine')
VIEWS = ('down', 'left', 'right', 'up')


def audit(path):
    data = path.read_bytes()
    bank = json.loads(data)
    assert bank['schema_version'] == 2
    rows = []
    for view, direction in bank['directions'].items():
        assert view in VIEWS
        for state, clip in bank['states'].items():
            assert len(clip['phases']) == clip['count'] > 0
            assert len(set(clip['phases'])) == clip['count']
            for index, phase in enumerate(clip['phases']):
                for target_view, target_state in itertools.product(VIEWS, STATES):
                    bridge = state not in STATES
                    matches = [name for name, edge in direction['transitions'].items()
                               if not bridge and view == target_view and edge['source_state'] == state
                               and edge['source_phase'] == phase and edge['target_state'] == target_state]
                    if bridge:
                        status = 'uncovered_bridge_policy'
                    elif view == target_view and state == target_state:
                        status = 'same_state_heading_only'
                    elif len(matches) == 1:
                        status = 'declared_edge_timing_not_validated'
                    elif len(matches) > 1:
                        status = 'ambiguous_edge'
                    else:
                        status = 'missing_edge'
                    rows.append({'source': {'view': view, 'state': state, 'index': index,
                                            'phase': phase, 'page': clip['page'], 'atlas_frame': clip['offset']+index},
                                 'goal': {'view': target_view, 'state': target_state},
                                 'status': status, 'matches': matches})
    counts = {status: sum(r['status'] == status for r in rows) for status in sorted({r['status'] for r in rows})}
    return {'schema': 1, 'kind': 'actual_bank_ordinary_intent_coverage_audit',
            'manifest_sha256': hashlib.sha256(data).hexdigest(), 'gear': bank['gear'],
            'actual_views': list(bank['directions']), 'missing_views': sorted(set(VIEWS)-set(bank['directions'])),
            'pose_intent_rows': len(rows), 'counts': counts, 'graph_closed': False,
            'ordinary_input_accepted': False, 'rows': rows,
            'limits': ['State/heading route enumeration only; same-state rows do not prove cycle/lifecycle behavior.',
                       'Declared edges do not prove speed, impact deadline, offset-release or visual quality.',
                       'Bridge interior policies are explicitly uncovered; this audit does not generate more art.',
                       'Missing views, other gear, variable timing and equipment/lifecycle events remain open.']}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    result = audit(args.manifest)
    args.output.write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k not in ('rows','limits')}))
