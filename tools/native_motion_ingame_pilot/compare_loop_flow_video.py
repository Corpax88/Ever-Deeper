"""Build a labelled pair from verified actual captures, with no invented frames."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

p=argparse.ArgumentParser(description=__doc__)
for name in ('before','after','normal','slow','report'):
    p.add_argument('--'+name,type=Path,required=True)
p.add_argument('--angle-degrees',type=int,choices=(0,25),default=25)
a=p.parse_args()
assert all(not x.exists() for x in (a.normal,a.slow,a.report))
reports=[json.loads((folder/'native-ingame.json').read_text()) for folder in (a.before,a.after)]
assert all(r['passed'] and r['rendered'] and len(r['captures'])==119 for r in reports)
assert reports[0]['consumer_sha256']==reports[1]['consumer_sha256']
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
for folder,report in zip((a.before,a.after),reports):
    for item in report['captures']: assert sha(folder/item['path'])==item['sha256']
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
filters=[]
for i,label in enumerate(('A','B')):
    filters.append(f'[{i}:v]crop=310:230:790:300,pad=310:258:0:28:color=0x20252d,'
                   f'drawtext=fontfile={font}:text={label}:fontsize=18:fontcolor=white:x=10:y=5[v{i}]')
filters.append('[v0][v1]hstack=inputs=2,format=yuv420p[v]')
command=['ffmpeg','-hide_banner','-loglevel','error','-framerate','60','-i',str(a.before/'frame-%04d.png'),
         '-framerate','60','-i',str(a.after/'frame-%04d.png'),'-filter_complex',';'.join(filters),
         '-map','[v]','-frames:v','119','-c:v','libx264','-crf','18','-movflags','+faststart',str(a.normal)]
a.normal.parent.mkdir(parents=True,exist_ok=True)
subprocess.run(command,check=True)
slow_command=['ffmpeg','-hide_banner','-loglevel','error','-i',str(a.normal),'-map','0:v:0','-c:v','copy','-an',
              '-bsf:v','setts=pts=PTS*24:dts=DTS*24:duration=DURATION*24',
              '-video_track_timescale','60000','-movflags','+faststart',str(a.slow)]
subprocess.run(slow_command,check=True)
def frames(path):
    text=subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','framemd5','-'],text=True)
    return [line.split(',')[-1].strip() for line in text.splitlines() if line and not line.startswith('#')]
assert len(frames(a.normal))==119 and frames(a.normal)==frames(a.slow)
report={'normal_sha256':sha(a.normal),'slow_sha256':sha(a.slow),'before_sha256':sha(a.before/'native-ingame.json'),
        'after_sha256':sha(a.after/'native-ingame.json'),'frames':119,'normal_fps':60,'slow_fps':2.5,
        'duration_seconds':[119/60,119/2.5],'identical_decoded_frames_and_order':True,
        'crop_xywh':[790,300,310,230],'labels':{'A':f'baseline {a.angle_degrees} degrees','B':f'loop rounding {a.angle_degrees} degrees'},
        'interpolation':False,'command':command,'slow_command':slow_command,'device_fps_claim':False}
a.report.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ('frames','duration_seconds','normal_sha256','slow_sha256')}))
