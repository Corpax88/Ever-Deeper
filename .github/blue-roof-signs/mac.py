import hashlib,json,os,re,subprocess,sys
from pathlib import Path
engine,pck,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[2]
for width,height in [(667,375),(844,390),(932,430)]:
 dest=out/str(width);dest.mkdir(exist_ok=True)
 env=dict(os.environ,WALL_OUT=str(dest),XDG_DATA_HOME=str(dest/'isolated-data'),WALL_EXPECTED_SIZE=f'{width},{height}')
 cmd=[str(engine),'--path',str(root),'--main-pack',str(pck),'--resolution',f'{width}x{height}','--script',str(root/'tools/review_text_signs.gd')]
 proc=subprocess.run(cmd,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
 (dest/'godot.log').write_text(proc.stdout)
 report=json.loads((dest/'report.json').read_text())
 report.update(source=os.environ.get('GITHUB_SHA'),production_pck={'size':pck.stat().st_size,'sha256':hashlib.sha256(pck.read_bytes()).hexdigest()},requested_viewport=[width,height],engine=subprocess.check_output([str(engine),'--version'],text=True).strip(),images=sorted(p.name for p in dest.glob('*.png')))
 report['passed']=report['passed'] and proc.returncode==0 and 'WALL_FOCUS_OK' in proc.stdout and not re.search(r'SCRIPT ERROR|Parse Error|^ERROR:',proc.stdout,re.M)
 (dest/'report.json').write_text(json.dumps(report,indent=2))
 assert report['passed'] and report['actual_viewport']==[width,height] and all(x==[width,height] for x in report['capture_sizes']),dest
