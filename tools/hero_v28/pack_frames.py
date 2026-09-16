"""Pack real native RGBA/mask frames; schema-v2 pilots use bounded pages.

Legacy production packing remains layout-compatible. A new motion pilot requires
an explicit nonproduction output directory; packing is not visual approval.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
from PIL import Image


def atomic_png(im, target):
    temporary = target.with_name(target.name+'.partial')
    im.save(temporary, format='PNG', optimize=True)
    with Image.open(temporary) as check:
        check.verify()
    temporary.replace(target)


def pack(args):
    source = args.frames/args.gear
    m = json.loads((source/args.manifest).read_text())
    native = int(m.get('schema_version', 1)) >= 2
    game = (args.game or Path(__file__).resolve().parents[2]).resolve()
    production = game/'assets/hero/dad'/args.gear
    out = (args.output_dir or production).resolve()
    old = json.loads((production/'manifest.json').read_text())
    if native:
        assert args.output_dir is not None and not out.is_relative_to(game/'assets/hero/dad'), 'Native pilots must be packed outside the production hero atlases'
        assert m.get('rendered') is True, 'Pose-only manifests are not rendered assets'
        assert m.get('pilot_only') is True and not m['motion']['production_approved']
    else:
        assert m['states'] == old['states'], 'Legacy packing must retain its approved state layout'
    assert m['max_grip_error'] < 1e-5
    out.mkdir(parents=True, exist_ok=True)
    cell, cols = 160, 8
    pages = [0]
    for info in m['states'].values():
        count = int(info['count'])
        if native:
            assert count <= 200, 'A single clip must fit within one bounded atlas page'
            if pages[-1]+count > 200:
                pages.append(0)
            info['source_offset'] = info['offset']
            info['page'] = len(pages)-1
            info['offset'] = pages[-1]
            pages[-1] += count
        else:
            info['page'] = 0
            pages[0] = max(pages[0], int(info['offset'])+count)
    page_rows = [math.ceil(count/cols) for count in pages]
    count = sum(int(v['count']) for v in m['states'].values())
    stats, retained = {}, {}
    directions = list(m['directions']) if native else ['down', 'left', 'up', 'right']
    for direction in directions:
        beauties = [Image.new('RGBA', (cols*cell, rows*cell)) for rows in page_rows]
        masks = [Image.new('L', im.size) for im in beauties]
        hashes, boxes = set(), []
        frames = [f for f in m['frames'] if f['direction'] == direction]
        assert len(frames) == count, (direction, 'Missing rendered frames', len(frames), count)
        metadata = {name: [None]*int(info['count']) for name, info in m['states'].items()}
        seen = set()
        for frame in frames:
            identity = (frame['state'], frame['index'])
            assert identity not in seen, ('Duplicate native frame', direction, identity)
            seen.add(identity)
            png, mask_png = source/frame['path'], source/frame['mask']
            if native:
                assert hashlib.sha256(png.read_bytes()).hexdigest() == frame['png_sha256']
                assert hashlib.sha256(mask_png.read_bytes()).hexdigest() == frame['mask_sha256']
            with Image.open(png) as opened:
                im = opened.convert('RGBA')
            with Image.open(mask_png) as opened:
                mask = opened.convert('L')
            assert im.size == mask.size == (200, 200)
            bbox = im.getchannel('A').point(lambda v: 255 if v > 32 else 0).getbbox()
            assert bbox and bbox[0] > 0 and bbox[1] >= 2 and bbox[2] < 200 and bbox[3] <= 198, (args.gear, frame['path'], bbox)
            assert im.getchannel('A').getextrema()[0] == 0
            hashes.add(hashlib.sha256(im.tobytes()).hexdigest())
            boxes.append(bbox)
            info = m['states'][frame['state']]
            index, page = int(info['offset'])+int(frame['index']), int(info['page'])
            pos = ((index % cols)*cell, (index//cols)*cell)
            beauties[page].paste(im.resize((cell, cell), Image.Resampling.LANCZOS), pos)
            masks[page].paste(mask.resize((cell, cell), Image.Resampling.LANCZOS), pos)
            if native:
                metadata[frame['state']][int(frame['index'])] = {key: frame[key] for key in
                    ('phase', 'time', 'contacts', 'native', 'ground_root_pixels')}
        assert len(hashes) > count*.5
        direction_pages = []
        for page, (beauty, cloth) in enumerate(zip(beauties, masks)):
            assert cloth.getextrema()[1] > 200
            suffix = '' if page == 0 else f'-p{page:03}'
            names = (direction+suffix+'.png', direction+suffix+'-cloth.png')
            atomic_png(beauty, out/names[0])
            atomic_png(cloth, out/names[1])
            direction_pages.append(dict(page=page, texture=names[0], cloth=names[1], size=list(beauty.size)))
        stats[direction] = dict(frames=count, unique=len(hashes), edge_clipping=[],
            atlas_pages=direction_pages, silhouette_bounds=[min(b[0] for b in boxes), min(b[1] for b in boxes),
                                                           max(b[2] for b in boxes), max(b[3] for b in boxes)])
        m['directions'][direction]['ground_anchor'] = [v*.8 for v in m['directions'][direction]['ground_anchor']]
        assert all(0 < v < cell for v in m['directions'][direction]['ground_anchor'])
        stats[direction]['previous_ground_anchor'] = old.get('qa', {}).get(direction, {}).get('previous_ground_anchor', old['directions'][direction]['ground_anchor'])
        stats[direction]['ground_anchor'] = m['directions'][direction]['ground_anchor']
        if native:
            m['directions'][direction]['pages'] = direction_pages
            retained[direction] = metadata
        else:
            stats[direction]['atlas_size'] = list(beauties[0].size)
    m.pop('frames')
    m['cell'] = [cell, cell]
    m['columns'] = cols
    m['qa'] = stats
    m['visual_model'] = 'Gruvepappa v28, approved by Mats'
    m['runtime_3d'] = False
    if native:
        m['sample_metadata'] = retained
        m['atlas_page_budget'] = dict(max_frames=200, max_dimension=max(max(im['size']) for d in stats.values() for im in d['atlas_pages']),
                                      loading='Load the active direction/state page; do not preload the entire transition bank.')
    else:
        for info in m['states'].values():
            info.pop('page', None)
    temporary = out/'manifest.json.partial'
    temporary.write_text(json.dumps(m, indent=2)+'\n')
    temporary.replace(out/'manifest.json')
    print('PACKED_V28', args.gear, json.dumps(dict(native_schema=native, directions=directions, frames_per_direction=count, pages=len(pages))), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--frames', type=Path, required=True)
    parser.add_argument('--game', type=Path)
    parser.add_argument('--gear', required=True)
    parser.add_argument('--manifest', default='manifest.json')
    parser.add_argument('--output-dir', type=Path)
    pack(parser.parse_args())
