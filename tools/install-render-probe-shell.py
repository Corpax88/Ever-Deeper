"""Install the DEV-only diagnostic shell before reviewing or publishing its exact bytes."""
import json
from pathlib import Path
import re
import sys

page = Path(sys.argv[1])
html = page.read_text()
script = Path(__file__).with_name('render-probe-browser.js').read_text()
assert 'window.everDeeperRenderProbe = api' not in html, 'Shell already installed'
match = re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});', html)
assert match, 'Unexpected Godot export shell'
config = json.loads(match.group(1))
assert config['canvasResizePolicy'] == 2, 'Unexpected baseline resize policy'
config['canvasResizePolicy'] = 0
html = html[:match.start()] + script + '\nconst GODOT_CONFIG = ' + json.dumps(config, separators=(',', ':')) + ';' + html[match.end():]
page.write_text(html)
print('DEV rendering diagnostic shell installed; native DPR retained outside the test')
