"""Encode real native cycle frames at the authored clock, without gameplay claims."""
import argparse,hashlib,json,subprocess
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
p=argparse.ArgumentParser(description=__doc__)
for n in ('input','frames','normal','slow','report'):p.add_argument('--'+n,type=Path,required=True)
a=p.parse_args()
assert all(not p.exists() for p in (a.frames,a.normal,a.slow,a.report))
r=json.loads((a.input/'report.json').read_text())
assert r['complete'] and len(r['renders'])==50 and r['cycle_seconds']==.68
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
a.frames.mkdir(parents=True)
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',14)
for i,row in enumerate(r['renders']):
    path=a.input/row['path'];assert sha(path)==row['sha256']
    im=Image.open(path).convert('RGBA').resize((160,160),Image.Resampling.LANCZOS)
    canvas=Image.new('RGB',(512,360),(36,36,36))
    canvas.paste(im,(8,184),im)
    zoom=im.resize((320,320),Image.Resampling.NEAREST)
    canvas.paste(zoom,(184,24),zoom)
    d=ImageDraw.Draw(canvas)
    d.text((8,8),'160 px',font=font,fill='white')
    d.text((184,8),'Samme bilder, 2x',font=font,fill='white')
    canvas.save(a.frames/f'frame-{i:03}.png')
normal=['ffmpeg','-v','error','-framerate','1250/17','-stream_loop','2','-i',str(a.frames/'frame-%03d.png'),'-frames:v','150','-c:v','libx264','-crf','16','-pix_fmt','yuv420p','-movflags','+faststart',str(a.normal)]
subprocess.run(normal,check=True)
slow=['ffmpeg','-v','error','-i',str(a.normal),'-map','0:v:0','-c:v','copy','-an','-bsf:v','setts=pts=PTS*24:dts=DTS*24:duration=DURATION*24','-video_track_timescale','60000','-movflags','+faststart',str(a.slow)]
subprocess.run(slow,check=True)
def hashes(path):
    rows=subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','framemd5','-'],text=True)
    return [r.split(',')[-1].strip() for r in rows.splitlines() if r and not r.startswith('#')]
decoded=hashes(a.normal)
assert len(decoded)==150 and decoded==hashes(a.slow)
result={'scope':'Original rig native animation preview only; no ore, input, transitions or gameplay acceptance',
        'source_report_sha256':sha(a.input/'report.json'),'native_cell':200,'game_cell':160,
        'frames':150,'unique_input_poses':50,'cycles':3,'cycle_seconds':.68,
        'duration_seconds':2.04,'slow_duration_seconds':48.96,'slow_factor':24,
        'normal_sha256':sha(a.normal),'slow_sha256':sha(a.slow),
        'identical_decoded_frames_and_order':True,'interpolation':False,
        'visual_accepted':False,'production_accepted':False,'normal_command':normal,'slow_command':slow}
a.report.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
