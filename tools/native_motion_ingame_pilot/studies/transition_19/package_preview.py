"""Package genuine13-frame bridge and encode actual captured gameplay."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import shutil
import tempfile
from PIL import Image

p=argparse.ArgumentParser()
p.add_argument('--walk-native',type=Path,required=True)
p.add_argument('--game',type=Path)
p.add_argument('--video',type=Path)
p.add_argument('--gif',type=Path)
a=p.parse_args()
r=json.loads((a.walk_native/'report.json').read_text())
assert r['complete'] and len(r['renders'])==13
atlas=Image.new('RGBA',(1600,320))
for i,s in enumerate(r['renders']):
    with Image.open(a.walk_native/s['file']) as im:
        atlas.paste(im.resize((160,160),Image.Resampling.LANCZOS),(i%10*160,i//10*160))
atlas.save(a.walk_native/'atlas.png')
r['atlas_sha256']=hashlib.sha256((a.walk_native/'atlas.png').read_bytes()).hexdigest()
(a.walk_native/'atlas.json').write_text(json.dumps(r,indent=2)+'\n')
if a.video or a.gif:
    assert a.game
    report=json.loads((a.game/'report.json').read_text())
    assert report['complete']
    count=len(report['samples'])
    assert all((a.game/'crops'/f'frame-{i:04d}.png').is_file() for i in range(count))
    def install(source,target):
        target.parent.mkdir(parents=True,exist_ok=True)
        staged=target.with_name(target.name+'.complete')
        shutil.copy2(source,staged)
        staged.replace(target)
        assert hashlib.sha256(source.read_bytes()).digest()==hashlib.sha256(target.read_bytes()).digest()
    # Never expose an actively written delivery. A previous workspace GIF was
    # truncated despite its intended-frame metadata; decode and count bytes
    # in a closed temporary file before installing the finished result.
    with tempfile.TemporaryDirectory(prefix='ever-deeper19-media-') as directory:
        temporary=Path(directory)
        video=temporary/'complete.mp4'
        subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y',
            '-framerate','60','-i',str(a.game/'crops/frame-%04d.png'),'-frames:v',str(count),
            '-vf','scale=640:560:flags=lanczos','-an','-c:v','libx264','-crf','18',
            '-pix_fmt','yuv420p','-movflags','+faststart',str(video)],check=True)
        subprocess.run(['ffmpeg','-v','error','-i',str(video),'-f','null','-'],check=True)
        probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-count_frames',
            '-show_entries','stream=nb_read_frames,r_frame_rate','-of','json',str(video)]))
        assert int(probe['streams'][0]['nb_read_frames'])==count
        assert probe['streams'][0]['r_frame_rate']=='60/1'
        if a.video:install(video,a.video)
        if a.gif:
            gif=temporary/'complete.gif'
            subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(video),
                '-vf','fps=30,scale=480:420:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse=dither=sierra2_4a',
                '-loop','0',str(gif)],check=True)
            with Image.open(gif) as im:
                assert abs(im.n_frames-count/2)<=.5
                duration=0
                for i in range(im.n_frames):
                    im.seek(i);im.load();duration+=im.info['duration']
                assert abs(duration-count/60*1000)<35
            install(gif,a.gif)
    for f in [a.video,a.gif]:
        if f:f.with_suffix(f.suffix+'.json').write_text(json.dumps({'source':str(a.game),
            'source_frames':len(report['samples']),'normal_speed':True,'interpolated_frames':False,
            'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()},indent=2)+'\n')
print('TRANSITION_PACKAGED',r['atlas_sha256'])
