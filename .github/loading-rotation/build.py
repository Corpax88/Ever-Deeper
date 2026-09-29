"""Loading-only hotfix, preserving the verified LIVE1.0.2 engine and PCK."""
from pathlib import Path
import hashlib,json,os,shutil,sys
here=Path(__file__).resolve().parent
def identity(p):return {'size':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
src,out=map(Path,sys.argv[1:3]);baseline=json.loads((here/'baseline.json').read_text())
assert all(identity(src/n)==v for n,v in baseline.items()),'Wrong LIVE baseline'
out.mkdir(parents=True,exist_ok=False)
for n in baseline:shutil.copy2(src/n,out/n)
html=(src/'index.html').read_text()
css='''
/* Keep the loader inside Safari's visible viewport during rotation/toolbars. */
#status {
 position: fixed;
 right: auto;
 bottom: auto;
 width: 100%;
 height: 100vh;
 height: 100dvh;
 overflow: hidden;
 z-index: 1;
}
#status-progress {
 bottom: max(10%, calc(env(safe-area-inset-bottom, 0px) + 12px));
}
'''
script='''
        <script>
// Only the loading overlay follows visualViewport; the game owns its canvas.
const disposeLoadingViewport = (() => {
 const overlay = document.getElementById('status');
 const viewport = window.visualViewport;
 let frame = 0;
 function sync() {
  frame = 0;
  const width = viewport ? viewport.width : window.innerWidth;
  const height = viewport ? viewport.height : window.innerHeight;
  if (width <= 0 || height <= 0) return;
  overlay.style.width = width + 'px';
  overlay.style.height = height + 'px';
  overlay.style.left = (viewport ? viewport.offsetLeft : 0) + 'px';
  overlay.style.top = (viewport ? viewport.offsetTop : 0) + 'px';
 }
 function schedule() { if (!frame) frame = requestAnimationFrame(sync); }
 window.addEventListener('resize', schedule);
 window.addEventListener('orientationchange', schedule);
 viewport?.addEventListener('resize', schedule);
 viewport?.addEventListener('scroll', schedule);
 sync();
 return () => {
  cancelAnimationFrame(frame);
  window.removeEventListener('resize', schedule);
  window.removeEventListener('orientationchange', schedule);
  viewport?.removeEventListener('resize', schedule);
  viewport?.removeEventListener('scroll', schedule);
 };
})();
        </script>
'''
assert html.count('\t\t</style>')==1
html=html.replace('\t\t</style>',css+'\t\t</style>')
marker='\t\t<script>\n// Opt-in diagnostics'
assert html.count(marker)==1
html=html.replace(marker,script+marker)
marker="if (mode === 'hidden') {\n\t\t\tstatusOverlay.remove();"
assert html.count(marker)==1
html=html.replace(marker,"if (mode === 'hidden') {\n\t\t\tdisposeLoadingViewport();\n\t\t\tstatusOverlay.remove();")
(out/'index.html').write_text(html)
manifest={n:identity(out/n) for n in baseline}
assert [n for n in baseline if manifest[n]!=baseline[n]]==['index.html']
(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'build-receipt.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'files':manifest,'baseline':baseline,'changed_files':['index.html'],'version':'1.0.2','hotfix':'loading-rotation-1'},indent=2))
