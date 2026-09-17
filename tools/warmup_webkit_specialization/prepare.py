#!/usr/bin/env python3
"""Read-only binding checks; no export, browser, game launch or request creation."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SHA = lambda data: hashlib.sha256(data).hexdigest()


def verify(candidate=None):
    pins = json.loads((HERE / 'package-pins.json').read_text())
    tree = subprocess.check_output(['git', 'ls-tree', 'HEAD', '--', *pins['runtime_paths']], cwd=ROOT)
    assert SHA(tree) == pins['runtime_tree_sha256'], 'Runtime tree changed'
    subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--', *pins['runtime_paths']], cwd=ROOT, check=True, capture_output=True)
    extra = subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard', '--', *pins['runtime_paths']], cwd=ROOT)
    assert not extra, 'Unexpected untracked runtime files'
    assert SHA((HERE / 'observer.js').read_bytes()) == pins['observer_sha256'], 'Raw observer changed'
    source_binding = json.loads((HERE / 'source-bindings.json').read_text())
    for name, expected in source_binding['unchanged_resource_preparation_files'].items():
        assert SHA((HERE / name).read_bytes()) == expected, 'Changed original helper: ' + name
    runner = (HERE / 'run.mjs').read_text()
    block = source_binding['unchanged_measurement_block']
    assert runner.count(block['start']) == 1 and runner.count(block['end']) == 1
    assert SHA(runner[runner.index(block['start']):runner.index(block['end'])].encode()) == block['sha256'], 'Raw measurement block changed'
    sections = {}
    for name, rule in pins['unchanged_sections'].items():
        assert runner.count(rule['start']) == 1 and runner.count(rule['end']) == 1, name
        data = runner[runner.index(rule['start']):runner.index(rule['end'])]
        if rule['exclude_suffix']:
            data = data[:data.index(rule['exclude_suffix'])]
        sections[name] = SHA(data.encode())
        if name == 'route':
            insertion = (HERE / rule['only_insertion_file']).read_text()
            assert SHA(insertion.encode()) == rule['insertion_sha256']
            assert data.count(insertion) == 1
            assert SHA(data.replace(insertion, '').encode()) == rule['sha256'], 'Changed original route after removing only new receipt'
            assert sections[name] == rule['reviewed_new_sha256'], 'Changed reviewed new route'
        else:
            assert sections[name] == rule['sha256'], 'Changed reviewed section: ' + name
    files = None
    if candidate:
        identity_bytes = (candidate / 'artifact-identity.json').read_bytes()
        assert SHA(identity_bytes) == pins['candidate_identity_sha256'], 'Wrong artifact identity'
        identity = json.loads(identity_bytes)
        assert identity['sourceSha'] == pins['source'] and identity['runId'] == pins['candidate_run'] and identity['runAttempt'] == '1'
        assert identity['devFiles'] == pins['files'] and len(pins['files']) == 9
        files = {}
        for name, expected in pins['files'].items():
            raw = (candidate / name).read_bytes()
            assert len(raw) == expected['size'] and SHA(raw) == expected['sha256'], name
            files[name] = expected
        shipped_bytes = (candidate / 'index.js').read_bytes()
        shipped = shipped_bytes.decode()
        assert SHA(shipped_bytes) == source_binding['actual_shipped_js']['sha256']
        assert len(shipped_bytes) == source_binding['actual_shipped_js']['bytes']
        binding = json.loads((HERE / 'source-bindings.json').read_text())['actual_shipped_js']
        for method in binding['verified_dispatches']:
            assert 'GLctx.' + method in shipped, method
        for method in binding['absent_2d_subimage_names'] + binding['absent_attachment_mutator_names']:
            assert method not in shipped, method
        for method, dispatch in binding['identity_dispatch_receipts'].items():
            assert shipped.count(dispatch) == 1, 'Changed original dispatch: ' + method
    return {'schema': 1, 'production_source': pins['source'], 'runtime_tree_sha256': SHA(tree),
            'observer_sha256': pins['observer_sha256'], 'unchanged_sections': sections,
            'candidate_identity_sha256': pins['candidate_identity_sha256'], 'candidate_files': files,
            'unchanged_original_helpers': source_binding['unchanged_resource_preparation_files'],
            'unchanged_measurement_block_sha256': block['sha256'], 'no_build_or_runtime_mutation': True}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--candidate', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = json.dumps(verify(args.candidate), indent=2) + '\n'
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(result)
    print(result, end='')
