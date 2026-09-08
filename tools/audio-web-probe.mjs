import {webkit} from '@playwright/test';
import http from 'node:http';
import {readFile, writeFile} from 'node:fs/promises';
import path from 'node:path';
const [root, output] = process.argv.slice(2).map(p => path.resolve(p));
const audioEnabled = process.argv[4] === 'audio';
const rows = [], errors = [], logs = [], shutdownErrors = [], webglWarnings = [];
let complete = false;
const server = http.createServer(async (req,res) => {
  try {
    const name = new URL(req.url,'http://localhost').pathname;
    const file = path.resolve(root, '.'+(name==='/'?'/index.html':name));
    if (!file.startsWith(root+path.sep)) {res.writeHead(403).end();return;}
    let data = await readFile(file);
    if (file.endsWith('.html')) data = Buffer.from(data.toString().replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/, (_,raw) => {
      const config=JSON.parse(raw); config.args=[...(audioEnabled?[]:['--audio-driver','Dummy']),'--','--qa-mobile-performance','--perf-meter-review'];
      return 'const GODOT_CONFIG = '+JSON.stringify(config)+';';
    }));
    res.writeHead(200,{'Content-Type':file.endsWith('.wasm')?'application/wasm':file.endsWith('.js')?'text/javascript':file.endsWith('.html')?'text/html':'application/octet-stream','Cross-Origin-Opener-Policy':'same-origin','Cross-Origin-Embedder-Policy':'require-corp'}).end(data);
  } catch {res.writeHead(404).end();}
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await webkit.launch({headless:true});
try {
  const page=await browser.newPage({viewport:{width:844,height:390},deviceScaleFactor:3,isMobile:true,hasTouch:true});
  await page.addInitScript(() => {
    window.audioProbe={contexts:[],starts:0,samples:[],frames:0,last:performance.now(),elapsed:0};
    const Original=window.AudioContext||window.webkitAudioContext;
    if(Original) {
      const Wrapped=class extends Original {
        constructor(...args) {
          super(...args);window.audioProbe.contexts.push(this);
          const create=this.createBufferSource.bind(this);
          this.createBufferSource=(...a)=>{const source=create(...a);const start=source.start.bind(source);source.start=(...v)=>{window.audioProbe.starts++;return start(...v);};return source;};
        }
      };
      window.AudioContext=Wrapped;
      if(window.webkitAudioContext)window.webkitAudioContext=Wrapped;
    }
    const frame=()=>{window.audioProbe.frames++;requestAnimationFrame(frame);};requestAnimationFrame(frame);
    setInterval(()=>{const p=window.audioProbe;const now=performance.now();p.elapsed+=(now-p.last)/1000;p.samples.push({seconds:p.elapsed,raf_fps:p.frames*1000/(now-p.last),contexts:p.contexts.map(c=>({state:c.state,time:c.currentTime})),starts:p.starts});p.frames=0;p.last=now;},5000);
  });
  page.on('pageerror',e=>(complete?shutdownErrors:errors).push(String(e)));
  page.on('console',msg=>{const s=msg.text();logs.push(s);if(s.includes('WebGL:')) webglWarnings.push({afterComplete:complete,message:s});if(s.startsWith('METER_READING ')) rows.push(JSON.parse(s.slice(14)));if(s.includes('METER_REVIEW_OK')) complete=true;if(/SCRIPT ERROR|Parse Error/.test(s)) errors.push(s);});
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  if(audioEnabled) {
    await page.waitForFunction(()=>window.audioProbe.contexts.length>0,{},{timeout:45000});
    await page.evaluate(()=>{const b=document.createElement('button');b.id='audio-unlock-probe';b.textContent='Start audio test';b.style='position:fixed;left:0;top:0;z-index:99999';b.onclick=()=>window.audioProbe.contexts.forEach(c=>c.resume());document.body.appendChild(b);});
    await page.locator('#audio-unlock-probe').click();
    await page.evaluate(()=>document.querySelector('#audio-unlock-probe').remove());
  }
  const deadline=Date.now()+200000;
  while(!complete && !errors.length && Date.now()<deadline) await page.waitForTimeout(250);
  await page.screenshot({path:path.join(output,'browser-final.png')});
  await writeFile(path.join(output,'browser-console.json'),JSON.stringify({complete,errors,shutdownErrors,webglWarnings,logs},null,2));
  if(!complete||errors.length||rows.length!==2) throw new Error(JSON.stringify({complete,errors,rows}));
  const audioState=await page.evaluate(()=>{const p=window.audioProbe;return {starts:p.starts,contexts:p.contexts.map(c=>({state:c.state,time:c.currentTime})),samples:p.samples};});
  await writeFile(path.join(output,'audio-probe.json'),JSON.stringify({audioEnabled,...audioState,rows,shutdownErrors,webglWarnings},null,2));
  if(audioEnabled && !(audioState.starts>0 && audioState.samples.some(s=>s.contexts.some(c=>c.state==='running' && c.time>30)))) throw new Error('Real audio was not exercised for >30 seconds');
  const canvas=await page.locator('canvas').evaluate(c=>({w:c.width,h:c.height,dpr:devicePixelRatio}));
  const last=rows.at(-1);
  if(last.canvas_width!==canvas.w||last.canvas_height!==canvas.h||last.dpr!==canvas.dpr) throw new Error('Incorrect physical canvas diagnostics');
  await page.screenshot({path:path.join(output,'meter-webkit.png')});
  await writeFile(path.join(output,'webkit.json'),JSON.stringify({passed:true,canvas,rows},null,2));
  console.log('METER_WEBKIT_OK '+JSON.stringify(canvas));
} finally {await browser.close();server.close();}
