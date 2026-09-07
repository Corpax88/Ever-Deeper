#!/usr/bin/env python3
"""Verify the protected v0.46.8 surface and QA registry after structural cleanup."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[1]
def main():
    expected=json.loads((ROOT/'docs/unchanged-files.json').read_text())
    failures=[]
    for name,digest in expected.items():
        path=ROOT/name
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=digest:failures.append(name)
    text=(ROOT/'scripts/qa/qa_launcher.gd').read_text()
    raw=text.split('const CASES: Array[Dictionary] = ',1)[1].split('\n\nvar main:',1)[0]
    cases=json.loads(re.sub(r',\s*\]',']',raw))
    documented=json.loads((ROOT/'docs/qa-extraction.json').read_text())['ordered_cases']
    assert cases==documented,'QA flag order or arguments changed'
    for entry in cases:
        path=ROOT/('scripts/main.gd' if entry['suite']=='main' else 'scripts/qa/suites/'+entry['suite']+'.gd')
        assert re.search(r'^func '+re.escape(entry['method'])+r'\(',path.read_text(),re.M),entry
    catalog=(ROOT/'scripts/world/world_catalog.gd').read_text()
    assert 'const MINE_ORDER: = ["mossMine", "moonMine", "emberMine", "starMine"]' in catalog
    for name in ['main.gd','state/run_state.gd','world/surface_world.gd','world/depth/rootwound_world.gd']:
        assert 'WorldCatalog.MINE_ORDER' in (ROOT/'scripts'/name).read_text(),name
    assert not failures,'Protected files changed: '+', '.join(failures)
    print(f'INVARIANTS_OK protected_files={len(expected)} qa_cases={len(cases)}')
if __name__=='__main__':main()
