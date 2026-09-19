"""Encode completed real-game captures at their original60Hz, without tweening."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from PIL import Image, ImageDraw

p=argparse.ArgumentParser()
p.add_argument('--entry',type=Path,required=True)
p.add_argument('--interrupt',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
a=p.parse_args()
a.output.mkdir(parents=True,exist_ok=True)
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
sources=[]
for directory,label in [(a.entry,'Gange til hakking'),(a.interrupt,'Avbrudd og stopp')]:
    report=json.loads((directory/'report.json').read_text())
    verify=json.loads((directory/'verification.json').read_text())
    assert report['complete'] and verify['mechanics_identical']
    assert verify['report_sha256']==sha(directory/'report.json')
    sources.append({'directory':str(directory),'report_sha256':sha(directory/'report.json'),
                    'frames':len(report['samples']),'label':label})
count=sum(s['frames'] for s in sources)
with tempfile.TemporaryDirectory(prefix='ever-deeper21-preview-') as tmp:
    temporary=Path(tmp);sequence=temporary/'frames';sequence.mkdir()
    n=0
    for s in sources:
        for i in range(s['frames']):
            with Image.open(Path(s['directory'])/'crops'/f'frame-{i:04d}.png') as im:
                canvas=Image.new('RGB',(320,304),(25,29,33))
                canvas.paste(im,(0,24))
                ImageDraw.Draw(canvas).text((8,6),s['label'],fill='white')
                canvas.save(sequence/f'frame-{n:04d}.png')
                n+=1
    video=temporary/'Ever-Deeper-overganger-21.mp4'
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y',
        '-framerate','60','-i',str(sequence/'frame-%04d.png'),'-frames:v',str(count),
        '-vf','scale=640:608:flags=lanczos','-an','-c:v','libx264','-crf','18',
        '-pix_fmt','yuv420p','-movflags','+faststart',str(video)],check=True)
    subprocess.run(['ffmpeg','-v','error','-i',str(video),'-f','null','-'],check=True)
    probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-count_frames',
        '-show_entries','stream=nb_read_frames,r_frame_rate','-of','json',str(video)]))
    assert int(probe['streams'][0]['nb_read_frames'])==count
    assert probe['streams'][0]['r_frame_rate']=='60/1'
    gif=temporary/'Ever-Deeper-overganger-21.gif'
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(video),
        '-vf','fps=50,scale=480:456:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse=dither=sierra2_4a',
        '-loop','0',str(gif)],check=True)
    with Image.open(gif) as im:
        assert abs(im.n_frames-count*50/60)<=1
        duration=0
        for i in range(im.n_frames):
            im.seek(i);im.load();duration+=im.info['duration']
        assert abs(duration-count/60*1000)<35
    artifacts=[]
    for source in (video,gif):
        staged=a.output/(source.name+'.complete')
        shutil.copy2(source,staged)
        target=a.output/source.name
        staged.replace(target)
        assert sha(target)==sha(source)
        artifacts.append({'file':target.name,'bytes':target.stat().st_size,'sha256':sha(target)})
    (a.output/'preview-evidence.json').write_text(json.dumps({
        'sources':sources,'artifacts':artifacts,'source_frames':count,
        'duration_seconds':count/60,'normal_speed':True,'interpolated_frames':False,
        'video_fps':60,'gif_fps':50},indent=2)+'\n')
print('TRANSITION21_PREVIEW_COMPLETE',count)
