"""Retain every measured window and summarize paired production comparisons."""
from pathlib import Path
import json, math, sys

def summarize(report):
    groups = {}
    windows = []
    for stage_index, stage in enumerate(report['stages']):
        if stage['purpose'] != 'original-package-vs-production-fixes':
            continue
        for window in stage['windows']:
            row = {'stage':stage_index,'label':stage['label'],'scene':window['scene'], **window['raf']}
            windows.append(row)
            groups.setdefault((stage['label'],window['scene']),[]).append(row)
    def aggregate(rows):
        values=sorted(x for row in rows for x in row['intervals_ms'])
        frames=sum(r['frames'] for r in rows)
        elapsed=sum(r['elapsed_ms'] for r in rows)
        return {'windows':len(rows),'frames':frames,'elapsed_ms':elapsed,'fps':frames*1000/elapsed,
            'p95_ms':values[math.ceil(len(values)*.95)-1],'max_ms':max(values),
            'over_33ms':sum(x>33.333333 for x in values),'over_50ms':sum(x>50 for x in values)}
    result={label:{scene:aggregate(groups[(label,scene)]) for scene in ['surface','mining']} for label in ['baseline','candidate']}
    result['total']={label:aggregate([row for row in windows if row['label']==label]) for label in ['baseline','candidate']}
    return {'source':report['source'],'worker':report['worker'],'error':report['error'],
        'checks':len(report['checks']),'checks_passed':all(c['passed'] for c in report['checks']),
        'summary':result,'windows':windows,'outliers_removed':False,
        'scope':'Mac Apple GPU / WebKit. Includes all measured intervals; not physical iPhone acceptance.'}

if __name__=='__main__':
    source,target=map(Path,sys.argv[1:])
    target.write_text(json.dumps(summarize(json.loads(source.read_text())),indent=2)+'\n')
