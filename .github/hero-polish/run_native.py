from pathlib import Path
import json,os,subprocess,sys
godot,pack,script,output=sys.argv[1:]
out=Path(output);out.mkdir(parents=True,exist_ok=True)
empty=out/'empty';empty.mkdir(exist_ok=True)
env=dict(os.environ,HERO_OUT=str(out),XDG_DATA_HOME=str(out/'user'))
with (out/'godot.log').open('w') as log:
 result=subprocess.run([godot,'--path',str(empty),'--main-pack',pack,'--script',script,'--rendering-method','gl_compatibility','--audio-driver','Dummy','--resolution','1696x780'],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
assert result.returncode==0,result.returncode
assert json.loads((out/'review.json').read_text())['passed']
assert 'SCRIPT ERROR' not in (out/'godot.log').read_text()
print('HERO_NATIVE_RENDER_PASS')
