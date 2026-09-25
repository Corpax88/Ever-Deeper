import json
from pathlib import Path
p=Path(__file__).parent;summary=[]
for repeat in (1,2):
 r=json.loads((p/f'webkit-{repeat}/report.json').read_text());print('REPEAT',repeat,'PASS',r['passed'],'ERROR',r['error'],'CHECKS',len(r['checks']),'PAIRS',len(r['pairs']),'MAXDIFF',max((x['max_channel_difference'] for x in r['pairs']),default=None))
 assert r['passed'] and all(x['passed'] for x in r['checks'])
 assert all(x['max_channel_difference']==0 for x in r['pairs'])
 assert r['source_commit']=='c9c26ef1f821ab36dc5cf17d94da69ff3d3f7914'
 assert len(r['windows'])==6
 inventory=r['windows'][0]['light_cost']['lights']
 assert all(w['light_cost']['lights']==inventory for w in r['windows'])
 for variant in (0,1):
  rows=[w for w in r['windows'] if w['variant']==variant]
  if not rows:continue
  frames=sum(w['frames'] for w in rows);seconds=sum(w['seconds'] for w in rows)
  item=dict(repeat=repeat,variant=variant,windows=len(rows),fps=frames/seconds,windows_fps=[w['frames']/w['seconds'] for w in rows],p95=[w['frame']['p95_ms'] for w in rows],refresh_ms_per_frame=sum(w['light_cost']['refresh_usec'] for w in rows)/1000/frames,rebuilds=[w['light_cost']['rebuilds'] for w in rows],calls=[w['light_cost']['refresh_calls'] for w in rows],impacts=[w['impacts'] for w in rows],draw_calls=[w['draw_calls'] for w in rows],mode_valid=all(w['light_cost']['mode']==('occupancy_revision' if variant else 'baseline') for w in rows))
  summary.append(item);print(json.dumps(item))
(p/'analysis.json').write_text(json.dumps(summary,indent=2)+'\n')
