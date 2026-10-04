"""Native focused regressions against exact production PCK in isolated save roots."""
from pathlib import Path
import json,os,re,subprocess,sys,time
engine,pck,out=map(Path,sys.argv[1:4]);out.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[2]
cases=[
 ('save-retry','tools/review_save_retry.gd','EVER_DEEPER_SAVE_RETRY_OK'),
 ('save-status','tools/review_save_status.gd','EVER_DEEPER_SAVE_STATUS_OK'),
 ('mod-lifecycle','tools/review_mod_lifecycle.gd','EVER_DEEPER_MOD_LIFECYCLE_OK'),
 ('laser-stamina','tools/review_laser_stamina.gd','LASER_STAMINA_OK'),
 ('completed-goals','tools/review_treasury_goal_completion.gd','TREASURY_GOAL_COMPLETION_OK'),
 ('pickup-bonus','tools/review_deep_pickup_bonus.gd','DEEP_PICKUP_BONUS_OK'),
 ('corebreaker-burst','tools/review_corebreaker_burst.gd','COREBREAKER_BURST_OK'),
 ('retained-five-mechanics','tools/review_five_mechanics.gd','FIVE_MECHANICS_OK'),
 ('running-achievements','tools/review_running_achievements.gd','EVER_DEEPER_RUNNING_ACHIEVEMENTS_OK'),
]
overrides=json.loads((root/'.github/full-quality/overrides.json').read_text())
if 'scripts/state/achievement_service.gd' not in overrides:
    cases=[c for c in cases if c[0]!='running-achievements']
report=[]
for name,script,marker in cases:
    dest=out/name;dest.mkdir(parents=True,exist_ok=True)
    env=dict(os.environ,XDG_DATA_HOME=str(dest/'isolated-data'),MODS_OUT=str(dest))
    command=[str(engine),'--headless','--path',str(root),'--main-pack',str(pck),'--script',str(root/script),'--','--output='+str(dest)]
    started=time.monotonic()
    try:
        result=subprocess.run(command,cwd=root,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=100)
        log=result.stdout
        passed=result.returncode==0 and marker in log and not re.search(r'SCRIPT ERROR|Parse Error',log)
        entry={'name':name,'passed':passed,'exit_code':result.returncode,'seconds':time.monotonic()-started,'script':script,'marker':marker}
    except subprocess.TimeoutExpired as exc:
        log=(exc.stdout or b'').decode() if isinstance(exc.stdout,bytes) else exc.stdout or ''
        entry={'name':name,'passed':False,'timeout':True,'seconds':time.monotonic()-started,'script':script}
    (dest/'godot.log').write_text(log)
    report.append(entry);(out/'report.json').write_text(json.dumps({'passed':all(x['passed'] for x in report),'checks':report},indent=2))
    print(json.dumps(entry),flush=True)
sys.exit(0 if all(x['passed'] for x in report) else 1)
