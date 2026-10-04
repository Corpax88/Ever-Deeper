"""Native focused regressions against exact production PCK in isolated save roots."""
from pathlib import Path
import hashlib,json,os,re,subprocess,sys,time
engine,pck,out=map(Path,sys.argv[1:4]);out.mkdir(parents=True,exist_ok=True)
qa_pck=Path(sys.argv[4]) if len(sys.argv)>4 else None
root=Path(__file__).resolve().parents[2]
def identity(path):
    return {'size':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
metadata={'source':os.environ.get('GITHUB_SHA'),'production_pck':identity(pck),'qa_pck':identity(qa_pck) if qa_pck else None,'engine_version':subprocess.check_output([str(engine),'--version'],text=True).strip()}
def save_report():
    (out/'report.json').write_text(json.dumps(dict(metadata,passed=all(x['passed'] for x in report),checks=report),indent=2))
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
 ('achievement-recovery','tools/review_achievement_recovery.gd','EVER_DEEPER_ACHIEVEMENT_RECOVERY_OK'),
 ('companion-training','tools/review_companion_training.gd','COMPANION_TRAINING_OK'),
 ('companion-new-run','tools/review_companion_new_run.gd','EVER_DEEPER_COMPANION_NEW_RUN_OK'),
 ('treasury-seams','tools/review_treasury_seams.gd','TREASURY_SEAMS_OK'),
 ('treasury-seam-world','tools/review_treasury_seam_world.gd','TREASURY_SEAM_WORLD_OK'),
 ('notification-modals','tools/review_notification_modals.gd','NOTIFICATION_MODALS_OK'),
 ('treasury-seam-integrity','tools/review_treasury_seam_integrity.gd','TREASURY_SEAM_INTEGRITY_OK'),
 ('treasury-hunt-rate','tools/review_treasury_hunt_rate.gd','TREASURY_HUNT_RATE_OK'),
 ('completed-collection','tools/review_completed_collection.gd','COMPLETED_COLLECTION_OK'),
]
overrides=json.loads((root/'.github/full-quality/overrides.json').read_text())
if 'scripts/progression/achievement_service.gd' not in overrides:
    cases=[c for c in cases if c[0] not in ('running-achievements','achievement-recovery')]
report=[]
for name,script,marker in cases:
    dest=out/name;dest.mkdir(parents=True,exist_ok=True)
    env=dict(os.environ,XDG_DATA_HOME=str(dest/'isolated-data'),MODS_OUT=str(dest))
    command=[str(engine),'--headless','--path',str(root),'--main-pack',str(pck),'--script',str(root/script),'--','--output='+str(dest)]
    started=time.monotonic()
    log_path=dest/'godot.log';reason=''
    with log_path.open('w') as log_file:
        process=subprocess.Popen(command,cwd=root,env=env,stdout=log_file,stderr=subprocess.STDOUT)
        while process.poll() is None:
            log=log_path.read_text(errors='replace')
            if re.search(r'SCRIPT ERROR|Parse Error',log): reason='runtime error';break
            if time.monotonic()-started>100: reason='timeout';break
            time.sleep(.1)
        if reason:
            process.terminate()
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired: process.kill();process.wait()
    log=log_path.read_text(errors='replace')
    passed=not reason and process.returncode==0 and marker in log and not re.search(r'SCRIPT ERROR|Parse Error',log)
    entry={'name':name,'passed':passed,'exit_code':process.returncode,'reason':reason,'seconds':time.monotonic()-started,'script':script,'marker':marker}
    report.append(entry);save_report()
    print(json.dumps(entry),flush=True)
if qa_pck:
    # QA-only guarded repairs retain the premium/world assertions while
    # accounting for completed goals and excavating the buried ore target.
    dest=out/'mandatory-core';dest.mkdir(parents=True,exist_ok=True)
    result=subprocess.run([sys.executable,str(root/'tools/qa.py'),'--godot',str(engine),'--pack',str(qa_pck),'--cases','input','premium-core','endgame','one-point-zero-world','--output',str(dest)],cwd=root)
    results=json.loads((dest/'results.json').read_text()) if (dest/'results.json').exists() else {'cases':[]}
    for row in results['cases']: report.append(dict(row,name='retained-'+row['case']))
    if not results['cases']: report.append({'name':'mandatory-core','passed':False,'exit_code':result.returncode})
    save_report()
sys.exit(0 if all(x['passed'] for x in report) else 1)
