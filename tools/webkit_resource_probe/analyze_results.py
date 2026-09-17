#!/usr/bin/env python3
"""Post-run independent arithmetic only; never imported by the measured harness."""
import argparse
import csv
import hashlib
import json
import math
import statistics
from pathlib import Path

SHA = lambda b: hashlib.sha256(b).hexdigest()
US = lambda ms: round(ms * 1000)
METHODS = ['texImage2D', 'compressedTexImage2D', 'texStorage2D', 'compileShader',
           'linkProgram', 'getShaderParameter', 'getProgramParameter']


def union(spans):
    result = 0
    start = end = None
    for a, b in sorted((a, b) for a, b in spans if b > a):
        if start is None:
            start, end = a, b
        elif a <= end:
            end = max(end, b)
        else:
            result += end - start
            start, end = a, b
    return result + (end - start if start is not None else 0)


def stats(values, thresholds):
    ordered = sorted(values)
    return {'count': len(values), 'sum_ms': sum(values)/1000,
            'mean_ms': statistics.mean(values)/1000, 'median_ms': statistics.median(values)/1000,
            'p95_ms': ordered[math.ceil(len(ordered)*.95)-1]/1000,
            'p99_ms': ordered[math.ceil(len(ordered)*.99)-1]/1000, 'max_ms': max(values)/1000,
            'strict_threshold_counts': {str(t): sum(x > t*1000 for x in values) for t in thresholds}}


def main(root):
    mac = root/'mac'
    read = lambda p: json.loads(p.read_text())
    result, raw, capture = [read(mac/n) for n in ['result.json', 'raw-loop.json', 'resource-capture.json']]
    clocks, host = [read(mac/n) for n in ['resource-clocks.json', 'host.json']]
    prep, request = [read(root/n) for n in ['preparation-remote.json', 'request-commit-awaiting-root.json']]
    expected = {Path(name).name: value['sha256'] for name, value in prep['files'].items() if name.startswith('tools/')}
    expected['REQUEST.json'] = request['files']['tools/webkit_resource_probe/REQUEST.json']['sha256']
    assert host['source_hashes'] == expected and host['study_sha'] == request['sha']
    assert host['request']['preparation_sha'] == prep['sha'] and host['request']['sessions'] == 1
    assert host['platform'] == 'darwin' and host['uid'] != 0
    pins = json.loads((Path(__file__).parent/'package-pins.json').read_text())
    identity_bytes = (mac/'artifact-identity.json').read_bytes()
    assert SHA(identity_bytes) == pins['candidate_identity_sha256']
    assert json.loads(identity_bytes)['devFiles'] == pins['files']
    verified = read(mac/'candidate-verified.json')
    assert verified['identity_sha256'] == pins['candidate_identity_sha256'] and verified['source'] == pins['source']
    assert verified['files'] == {n: {'bytes': v['size'], 'sha256': v['sha256']} for n, v in pins['files'].items()}
    assert result['source'] == pins['source'] and result['pck_sha256'] == pins['files']['index.pck']['sha256']
    run = read(root/'run-api.json')
    assert run['head_sha'] == request['sha'] and run['run_attempt'] == 1 and run['conclusion'] == 'success'
    assert result['complete'] and result['functional'] and result['unchanged_export']
    assert not result.get('error') and not result.get('cleanup_error') and not read(mac/'console.json')['errors']
    assert result['browser_exit']['code'] == 0 and result['browser_exit']['signal'] is None
    log = (mac/'runner.log').read_text()
    assert log.count('WEBKIT_RESOURCE_PROBE_COMPLETE ') == 1 and 'WEBKIT_RESOURCE_PROBE_FAILED ' not in log
    rr = result['resource_restoration']
    assert rr['all_methods_restored'] and rr['descriptors_restored'] and rr['get_context_restored_to_observer']
    assert rr['method_count'] == 7 and rr['error_mask'] == 0
    assert all(result['observer']['restoration'].values())
    assert raw['error'] is None and raw['visibility'] == 'visible' and all(raw['keys_at_end'].values())
    assert not any(result['observer']['ready']['keys'].values())
    events = result['observer']['events']
    assert all(e['kind'] in ['keydown', 'keyup'] and e['trusted'] for e in events)
    for code in ['Space', 'ArrowDown']:
        assert any(e['kind'] == 'keydown' and e['code'] == code and e['time'] <= raw['started'] for e in events)
        assert any(e['kind'] == 'keyup' and e['code'] == code and e['time'] >= raw['finished'] for e in events)
    for label in ['draw-before', 'draw-after']:
        draw = read(mac/(label+'.json'))
        assert draw['all_restored'] and all(r['restored'] for r in draw['rows']) and sum(r['draw_calls'] for r in draw['rows']) > 0
        assert draw['canvas']['buffer'] == {'width': 1696, 'height': 780} and draw['canvas']['dpr'] == 2
    for name in ['save-surface', 'save-before', 'save-after']:
        b = (mac/(name+'.sav')).read_bytes()
        receipt = read(mac/(name+'.json'))
        assert len(b) == receipt['bytes'] and SHA(b) == receipt['sha256']
        assert int.from_bytes(b[:4], 'little') == 0x52445645 and int.from_bytes(b[4:8], 'little') == 3
        assert int.from_bytes(b[8:12], 'little') == len(b)-44 and SHA(b[44:]) == b[12:44].hex()
    before, after = [read(mac/(n+'.json'))['document']['state'] for n in ['save-before', 'save-after']]
    assert before['world_seed'] == after['world_seed'] and before['endless_descent']['current_depth'] == 12
    assert after['endless_descent']['current_depth'] > 12 and after['location']['scene'] == 'endless'
    mined = lambda s: sum(max(0, n) for n in s['mined'].values())
    assert mined(after)-mined(before) == result['progress']['mined_delta'] > 0
    assert after['total_swings']-before['total_swings'] == result['progress']['swings_delta'] > 0
    assert capture['methods'] == METHODS and capture['capacity'] == 8192
    assert capture['dropped'] == capture['error_mask'] == 0 and capture['count'] == len(capture['rows'])
    assert clocks['before']['time_origin'] == clocks['after']['time_origin'] == capture['time_origin']
    assert clocks['before']['now_ms'] <= capture['started_ms'] <= raw['started']
    assert raw['finished'] <= capture['stopped_ms'] <= clocks['after']['now_ms']
    assert raw['count'] == len(raw['rows']) and 60 <= raw['seconds'] <= 70
    frames = [(US(r['start']), US(r['end'])) for r in raw['rows']]
    spans = [(US(r['start']), US(r['end']), r['method']) for r in capture['rows']]
    assert all(a <= b for a, b in frames) and all(frames[i][1] <= frames[i+1][0] for i in range(len(frames)-1))
    assert all(r['success'] == 1 and 0 <= r['method'] < 7 for r in capture['rows'])
    assert all(a <= b and US(capture['started_ms']) <= a <= b <= US(capture['stopped_ms']) for a, b, _ in spans)
    assert [sum(m == i for _, _, m in spans) for i in range(7)] == capture['counts']
    intervals = [frames[i+1][0]-frames[i][0] for i in range(len(frames)-1)]
    durations = [b-a for a, b in frames]
    assert sum(intervals) == US(raw['seconds']*1000)
    covered = [union([(max(a, x), min(b, y)) for x, y, _ in spans if x < b and y > a]) for a, b in frames]
    selected = union([(a, b) for a, b, _ in spans])
    assert sum(covered) == selected  # All selected spans are inside actual callbacks in this run.
    analysis = read(mac/'resource-analysis.json')
    assert abs(analysis['selected_in_callbacks_union_ms']-selected/1000) < 1e-6
    assert abs(analysis['outside_selected_calls_ms']-(sum(durations)-selected)/1000) < 1e-6
    hitches = []
    for i, (a, b) in enumerate(frames[:-1]):
        if max(durations[i], intervals[i]) <= 100000:
            continue
        by = {name: union([(max(a, x), min(b, y)) for x, y, m in spans if m == j and x < b and y > a])/1000 for j, name in enumerate(METHODS)}
        hitches.append({'callback_index': i, 'relative_start_s': (a-frames[0][0])/1e6,
                        'interval_ms': intervals[i]/1000, 'callback_ms': durations[i]/1000,
                        'gap_after_callback_ms': (intervals[i]-durations[i])/1000,
                        'selected_union_ms': covered[i]/1000,
                        'outside_selected_calls_ms': (durations[i]-covered[i])/1000,
                        'selected_callback_fraction': covered[i]/durations[i], 'by_method_ms': by})
    for actual, expected_hitch in zip(hitches, analysis['hitches']):
        assert actual['callback_index'] == expected_hitch['index']
        assert abs(actual['selected_union_ms']-expected_hitch['selected_call_union_ms']) < 1e-6
    assert len(hitches) == len(analysis['hitches'])
    per_method = [{'name': name, 'calls': capture['counts'][i],
                   'inclusive_ms': sum(b-a for a, b, m in spans if m == i)/1000,
                   'max_ms': max([b-a for a, b, m in spans if m == i] or [0])/1000} for i, name in enumerate(METHODS)]
    review = {'schema': 1, 'run_id': run['id'], 'measured_request_sha': request['sha'], 'preparation_sha': prep['sha'],
              'source': result['source'], 'pck_sha256': result['pck_sha256'], 'gates_passed': True,
              'metric': 'engine_loop_callback_cadence', 'presented_fps_verified': False, 'exclusive_gpu_time': False,
              'callbacks': len(frames), 'seconds': raw['seconds'], 'cadence_hz': len(intervals)*1e6/sum(intervals),
              'interval_stats': stats(intervals, [20, 25, 33.3, 50, 100, 250]),
              'callback_stats': stats(durations, [16.667, 20, 33.3, 50, 100, 250]),
              'callback_wall_fraction_of_window': sum(durations)/sum(intervals),
              'wall_fraction_is_cpu_utilization': False, 'selected_records': len(spans),
              'selected_union_ms': selected/1000, 'selected_fraction_of_callback_wall': selected/sum(durations),
              'selected_fraction_of_window': selected/sum(intervals), 'per_method': per_method, 'hitches': hitches,
              'startup_counts': capture['start_receipt']['untimed_counts_before'], 'progress': result['progress'],
              'browser_pid': result['browser_server_pid'], 'browser_exit': result['browser_exit'],
              'arithmetic': 'Raw millisecond timestamps rounded to integer microseconds for independent union arithmetic; no extra measurement precision is claimed.',
              'limits': ['Overhead-bearing single diagnostic with a different random seed and runner conditions; no regression or improvement comparison.',
                         'LINK_STATUS host-call wall time may include validation, driver work or synchronization; it is not compiler-only or exclusive GPU time.',
                         'The third major callback and all unwrapped time remain unattributed.',
                         'No shader/program identity or exact depth at each hitch was recorded, so shader variant and biome causality are unknown.',
                         'Before/after save and image receipts bracket a slightly wider period than the exact timed window.']}
    (root/'review.json').write_text(json.dumps(review, indent=2)+'\n')
    with (root/'slow-intervals.csv').open('w', newline='') as f:
        w = csv.writer(f);w.writerow(['callback_index', 'relative_start_s', 'interval_ms', 'callback_ms', 'selected_union_ms', 'outside_selected_calls_ms'])
        for i, value in enumerate(intervals):
            if value > 20000:
                w.writerow([i, (frames[i][0]-frames[0][0])/1e6, value/1000, durations[i]/1000, covered[i]/1000, (durations[i]-covered[i])/1000])
    with (root/'resource-spans.csv').open('w', newline='') as f:
        w = csv.writer(f);w.writerow(['record', 'method', 'relative_start_s', 'relative_end_s', 'duration_ms', 'callback_indices'])
        for i, (a, b, m) in enumerate(spans):
            indices = [j for j, (x, y) in enumerate(frames) if x <= a and b <= y]
            w.writerow([i, METHODS[m], (a-frames[0][0])/1e6, (b-frames[0][0])/1e6, (b-a)/1000, '|'.join(map(str, indices))])
    print(json.dumps(review, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('evidence', type=Path)
    main(parser.parse_args().evidence)
