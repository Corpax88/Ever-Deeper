"""Pack real rendered frames and encode previews without interpolated frames."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('--native', type=Path, required=True)
parser.add_argument('--game', type=Path)
parser.add_argument('--video', type=Path)
args = parser.parse_args()
report = json.loads((args.native/'report.json').read_text())
assert report['complete'] and len(report['renders']) == 50
atlas = Image.new('RGBA', (1600, 800))
for i, sample in enumerate(report['renders']):
    assert abs(sample['progress']-i/50) < 1e-8
    with Image.open(args.native/sample['file']) as frame:
        atlas.paste(frame.convert('RGBA').resize((160,160), Image.Resampling.LANCZOS),
                    (i%10*160, i//10*160))
atlas.save(args.native/'atlas.png')
metadata = dict(count=50, columns=10, cell=160, cycle=.68, hit=.42,
                anchor=report['ground_anchor_160'],
                atlas_sha256=hashlib.sha256((args.native/'atlas.png').read_bytes()).hexdigest())
(args.native/'atlas.json').write_text(json.dumps(metadata,indent=2)+'\n')
if args.video:
    args.video.parent.mkdir(parents=True,exist_ok=True)
    if args.game:
        game = json.loads((args.game/'report.json').read_text())
        assert game['complete'] and len(game['samples']) == 150
        assert game['atlas_sha256'] == metadata['atlas_sha256']
        source, rate, frames = args.game, '60', 328
        # Two complete recorded cycles after the initial camera settling,
        # repeated four times. Keep every original frame and normal timing.
        repeat_input = []
        effect = ('trim=start_frame=41:end_frame=123,setpts=PTS-STARTPTS,'
                  'loop=loop=3:size=82:start=0,'
                  'crop=320:280:830:290,scale=640:560:flags=lanczos')
        excerpt = dict(first_frame=41,last_frame=122,repetitions=4)
    else:
        source, rate, frames = args.native, '1250/17', 400
        repeat_input = ['-stream_loop','-1']
        effect = 'scale=600:600:flags=lanczos'
        excerpt = dict(first_frame=0,last_frame=49,repetitions=8)
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y',
                    *repeat_input,'-framerate',rate,
                    '-i',str(source/'frame-%04d.png'),'-frames:v',str(frames),
                    '-vf',effect,'-an','-c:v','libx264','-crf','18',
                    '-pix_fmt','yuv420p','-movflags','+faststart',str(args.video)],check=True)
    subprocess.run(['ffmpeg','-v','error','-i',str(args.video),'-f','null','-'],check=True)
    args.video.with_suffix('.json').write_text(json.dumps(dict(
        source=str(source),rate=rate,output_frames=frames,interpolated_frames=False,
        excerpt=excerpt,sha256=hashlib.sha256(args.video.read_bytes()).hexdigest()),indent=2)+'\n')
print('SIMPLE_SWING_PACKAGED',metadata['atlas_sha256'])
