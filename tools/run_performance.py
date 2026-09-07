#!/usr/bin/env python3
"""Repeatable isolated FPS capture; never confuse headless timing with GPU FPS."""
import argparse, json, os, re, subprocess, tempfile, time
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--headless', action='store_true')
    parser.add_argument('--capture', action='store_true')
    parser.add_argument('--review', action='store_true')
    parser.add_argument('--pack', type=Path)
    args = parser.parse_args()
    args.output = args.output.resolve(); args.output.mkdir(parents=True, exist_ok=True)
    log_path = args.output/'run.log'
    command = [args.godot, '--path', str(args.project.resolve()), '--resolution', '844x390', '--audio-driver', 'Dummy']
    if args.headless: command.append('--headless')
    command += ['--', '--qa-mobile-performance', '--perf-output='+str(args.output)]
    if args.capture: command.append('--perf-capture')
    if args.review: command.append('--perf-review')
    with tempfile.TemporaryDirectory(prefix='ever-deeper-perf-') as save_dir, log_path.open('w') as log:
        if args.pack:
            command[command.index('--path')+1] = save_dir
            separator = command.index('--')
            command[separator:separator] = ['--main-pack', str(args.pack.resolve())]
        started = time.monotonic()
        proc = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, env=dict(os.environ, XDG_DATA_HOME=save_dir))
        failure = ''
        while proc.poll() is None:
            text = log_path.read_text(errors='replace')
            if re.search(r'SCRIPT ERROR|Parse Error|(^|\n)ERROR:|Assertion failed', text): failure = 'runtime error'; break
            if time.monotonic()-started > 360: failure = 'timeout'; break
            time.sleep(.2)
        if failure:
            proc.terminate()
            try: proc.wait(timeout=5)
            except subprocess.TimeoutExpired: proc.kill(); proc.wait()
        text = log_path.read_text(errors='replace')
        marker = 'EVER_DEEPER_MOBILE_REVIEW_COMPLETE' if args.review else 'EVER_DEEPER_MOBILE_PERFORMANCE_COMPLETE'
        if failure or proc.returncode != 0 or marker not in text:
            print(text[-6000:]); raise SystemExit('Performance capture failed: '+failure)
    if args.review:
        print((args.output/'review.json').read_text()); return
    report = json.loads((args.output/'results.json').read_text())
    print('Rendered:', report['rendered'], '| Physical iPhone:', report['physical_iphone'])
    print('Stage | FPS | frame p95 | CPU p95 | draw calls | MiB')
    for r in report['stages']:
        print(f"{r['stage']} | {r['average_fps']:.1f} | {r['p95_ms']:.2f} | {r['process_p95_ms']:.2f} | {r['draw_calls_p95']:.0f} | {r['static_mib']:.1f}")

if __name__ == '__main__': main()
