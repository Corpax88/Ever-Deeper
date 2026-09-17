#!/usr/bin/env python3
"""Two exact packages, unchanged existing buffer trace; diagnostic reproduction only."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SHA = lambda data: hashlib.sha256(data).hexdigest()


def write(path, value):
    temporary = path.with_suffix(path.suffix + '.tmp')
    with temporary.open('w') as handle:
        json.dump(value, handle, indent=2)
        handle.write('\n')
        handle.flush()
        os.fsync(handle.fileno())
    temporary.replace(path)


def verify_package(folder, pin):
    identity_bytes = (folder / 'artifact-identity.json').read_bytes()
    assert SHA(identity_bytes) == pin['identity_sha256'], 'Artifact identity mismatch'
    identity = json.loads(identity_bytes)
    assert identity['sourceSha'] == pin['source'] and identity['runId'] == str(pin['run_id'])
    assert identity['runAttempt'] == '1' and identity['devFiles'] == pin['files'] and len(pin['files']) == 9
    verified = {}
    for name, expected in pin['files'].items():
        assert Path(name).name == name
        data = (folder / name).read_bytes()
        assert len(data) == expected['size'] and SHA(data) == expected['sha256'], name
        verified[name] = expected
    return {'identity_sha256': SHA(identity_bytes), 'source': pin['source'], 'files': verified}


def verify_completion(messages, log, label, original_exit_code):
    section_events = [line for line in messages if line.startswith('EVER_DEEPER_MENU_TOUCH_SECTION_')]
    assert len(section_events) == 2
    assert section_events[0].startswith('EVER_DEEPER_MENU_TOUCH_SECTION_BEGIN ')
    assert json.loads(section_events[0].split(' ', 1)[1]) == {'section': 'pause'}
    assert section_events[1].startswith('EVER_DEEPER_MENU_TOUCH_SECTION_COMPLETE ')
    assert json.loads(section_events[1].split(' ', 1)[1]) == {'checks': 9, 'failures': [], 'section': 'pause'}
    final = [line for line in messages if line.startswith('EVER_DEEPER_OVERHAUL_GAMEPLAY_')]
    assert final == ['EVER_DEEPER_OVERHAUL_GAMEPLAY_OK checks=9 failures=[]']
    assert messages.index(section_events[0]) < messages.index(section_events[1]) < messages.index(final[0])
    error_pattern = r'SCRIPT ERROR|Parse Error|^ERROR:|Failed to load|INVALID_OPERATION|INVALID_FRAMEBUFFER_OPERATION|ED_GL_BIND_CONFLICT'
    errors = [line for line in messages if re.search(error_pattern, line)]
    expected = {
        'WebGL: INVALID_OPERATION: bindBuffer: element array buffers can not be bound to a different target',
        'WebGL: INVALID_OPERATION: bufferSubData: no buffer',
    }
    if label == 'baseline':
        assert original_exit_code == 0 and errors == [], 'Baseline error gate failed'
    else:
        assert original_exit_code == 1, 'Unexpected candidate exit'
        assert errors and all(line in expected or line.startswith('ED_GL_BIND_CONFLICT ') for line in errors), 'Unrelated browser console failure'
        # Byte-bound original runner line 530 joins every pageErrors entry.
        # Exact reconciliation also rejects unjournalled uncaught page errors.
        match = re.search(r'(?:^|\n)Error: (.*?)\n    at captureSuite \(file://[^\n]+/tools/capture-web\.mjs:530:36\)\n    at async main \(file://[^\n]+/tools/capture-web\.mjs:675:3\)\n?\Z', log, re.S)
        assert match and match.group(1) == '\n'.join(errors), 'Final failure is not exactly the expected pageErrors gate'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--baseline', required=True, type=Path)
    parser.add_argument('--candidate', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    result = {'schema': 1, 'complete': False, 'diagnostic_only': True, 'candidate_approved': False,
              'physical_iphone': False, 'performance_claim': False, 'cases': {},
              'limits': ['Existing TRACE_GL_BUFFERS observes API object/target history and JS/WASM stacks.',
                         'It does not attribute the caller to a source-level node without additional evidence.',
                         'Expected candidate failure is retained; diagnostic completion is not a green game gate.']}
    try:
        assert os.environ.get('GITHUB_REF') == 'refs/heads/codex/warmup-buffer-diagnostic-20260917'
        assert os.environ.get('GITHUB_RUN_ATTEMPT') == '1'
        pins = json.loads((HERE / 'pins.json').read_text())
        request = json.loads((HERE / 'REQUEST.json').read_text())
        parent = subprocess.check_output(['git', 'rev-parse', 'HEAD^'], cwd=ROOT).decode().strip()
        diff = subprocess.check_output(['git', 'diff-tree', '--no-commit-id', '--name-status', '-r', 'HEAD'], cwd=ROOT).decode().strip()
        assert diff == 'A\ttools/warmup_buffer_diagnostic/REQUEST.json'
        assert request['preparation_sha'] == parent and request['probe'] == 'existing_buffer_trace_two_packages_v1'
        assert request['sessions'] == 2 and request['order'] == ['baseline', 'candidate'] and request['diagnostic_only'] is True
        assert request['pins_sha256'] == SHA((HERE / 'pins.json').read_bytes())
        for filename, key in [('tools/capture-web.mjs', 'capture_runner_sha256'),
                              ('package.json', 'package_json_sha256'), ('package-lock.json', 'package_lock_sha256')]:
            assert SHA((ROOT / filename).read_bytes()) == pins[key], filename
        result['request'] = request
        result['study_commit'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
        result['source_hashes'] = {p.name: SHA(p.read_bytes()) for p in HERE.iterdir() if p.is_file()}
        env = os.environ.copy()
        for key in ['CAPTURE_SCOPE', 'TOUCH_BROWSER', 'HERO_MOTION', 'HERO_V28_CAPTURE', 'SMALL_IPHONE', 'PET_REACTIONS']:
            env.pop(key, None)
        env.update(TRACE_GL_BUFFERS='1', OVERHAUL_GAMEPLAY='1', MENU_TOUCH='1', MENU_TOUCH_SECTION='pause',
                   CAPTURE_VIEWPORT='848x390', CAPTURE_DPR='2', CAPTURE_START='1', CAPTURE_END='14')
        for label in ['baseline', 'candidate']:
            folder = args.output / label
            folder.mkdir()
            binding = verify_package(getattr(args, label), pins['packages'][label])
            write(folder / 'verified-package.json', binding)
            command = ['node', str(ROOT / 'tools/capture-web.mjs'), '--web-dir', str(getattr(args, label).resolve()),
                       '--output-dir', str(folder.resolve())]
            case = {'source': binding['source'], 'started_unix': time.time(), 'command': command,
                    'original_exit_code': None, 'expected_game_gate_success': label == 'baseline'}
            result['cases'][label] = case
            write(args.output / 'result.json', result)
            with (folder / 'runner.log').open('wb') as log:
                process = subprocess.Popen(command, env=env, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
                try:
                    case['original_exit_code'] = process.wait(timeout=240)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait()
                    case['timed_out'] = True
                    raise RuntimeError(label + ' timed out; diagnostic is inconclusive')
            case['ended_unix'] = time.time()
            log = (folder / 'runner.log').read_text()
            journal = (folder / 'browser-console.ndjson').read_bytes()
            messages = [json.loads(line)['text'] for line in journal.splitlines() if line]
            # The final exception repeats console errors in runner.log. Use each
            # original browser event once; retain the unmodified runner log too.
            conflicts = [json.loads(line.split('ED_GL_BIND_CONFLICT ', 1)[1]) for line in messages
                         if line.startswith('ED_GL_BIND_CONFLICT ')]
            sections = [json.loads(line.split('EVER_DEEPER_MENU_TOUCH_SECTION_COMPLETE ', 1)[1]) for line in messages
                        if line.startswith('EVER_DEEPER_MENU_TOUCH_SECTION_COMPLETE ')]
            original_console = '\n'.join(messages)
            verify_completion(messages, log, label, case['original_exit_code'])
            case.update(conflicts=conflicts, pause_sections=sections,
                        console_journal_sha256=SHA(journal),
                        raw_bind_error='WebGL: INVALID_OPERATION: bindBuffer: element array buffers can not be bound to a different target' in original_console,
                        raw_subdata_error='WebGL: INVALID_OPERATION: bufferSubData: no buffer' in original_console)
            assert sections == [{'checks': 9, 'failures': [], 'section': 'pause'}], 'Actual nine pause checks missing'
            assert not re.search(r'SCRIPT ERROR|Parse Error|^ERROR:|Assertion failed', log, re.M), 'Unrelated runtime failure'
            browser = json.loads((folder / 'browser-run.json').read_text())
            assert browser['traceGLBuffers'] is True and browser['browserEngine'] == 'chromium'
            assert browser['pckSha256'] == binding['files']['index.pck']['sha256']
            assert browser['htmlSha256'] == binding['files']['index.html']['sha256']
            assert browser['viewport'] == {'width': 848, 'height': 390} and browser['dpr'] == 2
            case['browser_run'] = browser
            if label == 'baseline':
                assert case['original_exit_code'] == 0 and not conflicts and not case['raw_bind_error'] and not case['raw_subdata_error'], 'Original baseline did not pass cleanly'
            else:
                assert case['original_exit_code'] != 0 and case['raw_bind_error'] and case['raw_subdata_error'], 'Expected candidate failure was not reproduced'
                assert conflicts and len(conflicts) <= 16, 'No bounded actual conflicting bind trace'
                assert all(c['stack'] and c['method'] in ['bindBuffer', 'bindBufferBase', 'bindBufferRange'] and
                           ((c['firstTarget'] == 34963) != (c['target'] == 34963)) for c in conflicts), 'Invalid buffer conflict attribution'
            write(args.output / 'result.json', result)
        result['complete'] = True
        result['reproduction_confirmed'] = True
    except Exception as error:
        result['error'] = repr(error)
    finally:
        result['finished_unix'] = time.time()
        write(args.output / 'result.json', result)
        print(('BUFFER_DIAGNOSTIC_COMPLETE' if result['complete'] else 'BUFFER_DIAGNOSTIC_INCONCLUSIVE') + ' ' + json.dumps(result))
    return 0 if result['complete'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
