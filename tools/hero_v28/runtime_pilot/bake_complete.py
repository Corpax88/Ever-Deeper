"""Complete the private native feasibility bake using the audited RGB writer.

Run with prepared.blend loaded. Existing completed channels can be resumed only
when their report binds the same prepared bytes and exact output contract.
"""
import argparse
import json
from pathlib import Path
import shutil
import sys
from types import SimpleNamespace

import bpy

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import constant_donor_probe as probe
import export_runtime as exporter


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--threads', type=int, default=2)
    p.add_argument('--channel', choices=exporter.CHANNELS)
    p.add_argument('--assemble-only', action='store_true')
    args = p.parse_args(sys.argv[sys.argv.index('--')+1:])
    output = args.output.resolve()
    assert Path(bpy.data.filepath).resolve() == output/'prepared.blend'
    prep = json.loads((output/'preparation.json').read_text())
    assert prep['source_sha256'] == '94304c12a042b168c0d655dc0ceacffe2efb08997039a7a26c1ed0cc1770bc91'
    prepared_sha = probe.digest(output/'prepared.blend')
    reports = {}
    binding = {'prepared_sha256': prepared_sha,
               'probe_sha256': probe.digest(HERE/'constant_donor_probe.py'),
               'exporter_sha256': probe.digest(HERE/'export_runtime.py'),
               'size': prep['texture_size'], 'samples': 8, 'threads': args.threads,
               'mode': 'merged', 'scope': 'full', 'contract': probe.RGB_OUTPUT_CONTRACT}
    channels = [args.channel] if args.channel else exporter.CHANNELS
    for channel in channels:
        directory = output/('transfer-'+channel)
        binding_path = output/('transfer-'+channel+'-input.json')
        channel_binding = dict(binding, channel=channel)
        if not directory.exists():
            assert not args.assemble_only, ('missing channel', channel)
            if binding_path.exists(): assert json.loads(binding_path.read_text()) == channel_binding
            else: binding_path.write_text(json.dumps(channel_binding,indent=2)+'\n')
            probe.bake_probe(SimpleNamespace(output=directory, scope='full', mode='merged',
                donor=None, channel=channel, size=prep['texture_size'], samples=8,
                threads=args.threads))
        assert json.loads(binding_path.read_text()) == channel_binding
        report = json.loads((directory/'report.json').read_text())
        assert report['status'] == 'complete'
        sig = report['signature']
        assert sig['prepared_sha256'] == prepared_sha and sig['scope'] == 'full'
        assert sig['channel'] == channel and sig['size'] == prep['texture_size']
        assert sig['script_sha256'] == probe.digest(HERE/'constant_donor_probe.py')
        assert report['opacity_audit']['all_sources_opaque']
        assert report['original_target_data_restored']
        assert report['rgb_output']['contract'] == probe.RGB_OUTPUT_CONTRACT
        source = directory/(channel+'.png')
        assert probe.digest(source) == report['rgb_output']['png_sha256']
        target = output/source.name
        if target.exists(): assert probe.digest(target) == probe.digest(source)
        else: shutil.copyfile(source, target)
        reports[channel] = {'report_sha256': probe.digest(directory/'report.json'),
                            'png_sha256': probe.digest(source)}
    if args.channel:
        print('NATIVE_CHANNEL_COMPLETE', args.channel, flush=True)
        return
    assert not (output/'worn-native-runtime.glb').exists()
    exporter.bake(SimpleNamespace(output=output, threads=args.threads))
    (output/'transfer-proof.json').write_text(json.dumps({
        'prepared_sha256': prepared_sha, 'script_sha256': probe.digest(__file__),
        'channels': reports, 'production_accepted': False,
        'limits': 'Export only. Native-reference image fidelity and runtime cost are unproven.'
    }, indent=2)+'\n')


if __name__ == '__main__':
    main()
