"""Summarize wall-clock windows; compare only within the same runner/job."""
import json, sys
from pathlib import Path
from statistics import mean
root=Path(sys.argv[1]); out=Path(sys.argv[2]); out.mkdir(parents=True,exist_ok=True)
rows=[]
for p in sorted(root.rglob('result.json')):
    d=json.loads(p.read_text())
    for t in d['trials']:
        for phase in ['idle','active']:
            b=t[phase]
            def fps(items):
                return sum(x['frames'] for x in items)/sum(x['end_seconds']-x['start_seconds'] for x in items)
            early=[x for x in b if x['start_seconds']<20]
            late=[x for x in b if x['start_seconds']>=30]
            r={'area':d['area'],'skill':d['skill'],'state':t['state'],'phase':phase,
               'fps':fps(b),'early_fps':fps(early),'late_fps':fps(late),'late_early_ratio':fps(late)/fps(early),
               'max_p95_ms':max(x['p95_ms'] for x in b),'sim_seconds':sum(x['sim_seconds'] for x in b),
               'pet_cpu_ms_per_second':sum(x['profile']['physics_usec'] for x in b)/1000/sum(x['end_seconds']-x['start_seconds'] for x in b),
               'path_calls':sum(x['profile']['path_calls'] for x in b),'ore_calls':sum(x['profile']['ore_calls'] for x in b),
               'max_path_ms':max(x['profile']['path_max_usec'] for x in b)/1000,
               'node_change':b[-1]['nodes']-b[0]['nodes'],'memory_change_mib':b[-1]['static_mib']-b[0]['static_mib'],
               'collected_delta':b[-1]['pet']['collected']-(t['initial']['collected'] if phase=='idle' else t['idle'][-1]['pet']['collected']),
               'dug_delta':b[-1]['pet']['dug']-(t['initial']['dug'] if phase=='idle' else t['idle'][-1]['pet']['dug']),
               'exercise_supported':t['exercise_supported'],'commands':t['commands'] if phase=='active' else []}
            rows.append(r)
(out/'summary.json').write_text(json.dumps(rows,indent=2))
lines=['# Pet skill sustained performance','', 'Native Linux software rendering at 844×390; not physical iPhone measurements. Each state has 60 seconds idle and 45 seconds exercised. Other skills remain learned; all toggles every skill. Core Lantern/Fetch use synthetic QA off controls.','', '| Area | Skill | Phase | Off FPS | On FPS | Restored FPS | On late/early | On pet CPU ms/s |','|---|---|---|---:|---:|---:|---:|---:|']
for area in ['hub','mossvein']:
    for skill in ['lantern','fetch','trailrunner','big_paws','ore_nose','long_beam','shake','teamwork','echo','homeward','all']:
        for phase in ['idle','active']:
            q={r['state']:r for r in rows if r['area']==area and r['skill']==skill and r['phase']==phase}
            if len(q)!=3: continue
            a,b,c=[q[s] for s in ['off','on','restored_off']]
            lines.append(f"| {area} | {skill} | {phase} | {a['fps']:.2f} | {b['fps']:.2f} | {c['fps']:.2f} | {b['late_early_ratio']:.3f} | {b['pet_cpu_ms_per_second']:.2f} |")
(out/'summary.md').write_text('\n'.join(lines)+'\n')
print('\n'.join(lines))
