"""Bind successful exported core/Skills results to the candidate build record."""
import hashlib,json,sys
from pathlib import Path
work=Path(sys.argv[1]);core=work/'core/results.json';skills=work/'skills-core.log'
results=json.loads(core.read_text());log=skills.read_text()
assert results['passed'] and all(c['passed'] for c in results['cases'])
assert 'MINER_SKILLS_COMPLETE' in log and 'ERROR' not in log
build_path=work/'build.json';build=json.loads(build_path.read_text())
build['core_results_sha256']=hashlib.sha256(core.read_bytes()).hexdigest()
build['skills_core_log_sha256']=hashlib.sha256(skills.read_bytes()).hexdigest()
build_path.write_text(json.dumps(build,indent=2)+'\n')
