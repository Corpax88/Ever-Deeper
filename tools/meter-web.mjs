import {webkit} from '@playwright/test';
import http from 'node:http';
import {readFile, writeFile} from 'node:fs/promises';
import path from 'node:path';
const [root, output] = process.argv.slice(2).map(p => path.resolve(p));
const rows = [], errors = [];
let complete = false;
const server = http.createServer(async (req,res) => {
  try {
    const name = new URL(req.url,'http://localhost').pathname;
    const file = path.resolve(root, '.'+(name==='/'?'/index.html':name));
    if (!file.startsWith(root+path.sep)) {res.writeHead(403).end();return;}
    let data = await readFile(file);
    if (file.endsWith('.html')) data = Buffer.from(data.toString().replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/, (_,raw) => {
      const config=JSON.parse(raw); config.args=['--qa-mobile-performance','--perf-meter-review'];
      return 'const GODOT_CONFIG = '+JSON.stringify(config)+';';
    }));
    res.writeHead(200,{'Content-Type':file.endsWith('.wasm')?'application/wasm':file.endsWith('.js')?'text/javascript':file.endsWith('.html')?'text/html':'application/octet-stream','Cross-Origin-Opener-Policy':'same-origin','Cross-Origin-Embedder-Policy':'require-corp'}).end(data);
  } catch {res.writeHead(404).end();}
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await webkit.launch({headless:true});
try {
  const page=await browser.newPage({viewport:{width:844,height:390},deviceScaleFactor:3,isMobile:true,hasTouch:true});
  page.on('pageerror',e=>errors.push(String(e)));
  page.on('console',msg=>{const s=msg.text();if(s.startsWith('METER_READING ')) rows.push(JSON.parse(s.slice(14)));if(s.includes('METER_REVIEW_OK')) complete=true;if(/SCRIPT ERROR|Parse Error/.test(s)) errors.push(s);});
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  const deadline=Date.now()+150000;
  while(!complete && !errors.length && Date.now()<deadline) await page.waitForTimeout(250);
  if(!complete||errors.length||rows.length!==2) throw new Error(JSON.stringify({complete,errors,rows}));
  const canvas=await page.locator('canvas').evaluate(c=>({w:c.width,h:c.height,dpr:devicePixelRatio}));
  const last=rows.at(-1);
  if(last.canvas_width!==canvas.w||last.canvas_height!==canvas.h||last.dpr!==canvas.dpr) throw new Error('Incorrect physical canvas diagnostics');
  await page.screenshot({path:path.join(output,'meter-webkit.png')});
  await writeFile(path.join(output,'webkit.json'),JSON.stringify({passed:true,canvas,rows},null,2));
  console.log('METER_WEBKIT_OK '+JSON.stringify(canvas));
} finally {await browser.close();server.close();}
