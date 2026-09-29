import {webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [original,candidate,output]=process.argv.slice(2);
fs.mkdirSync(output,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(candidate,'manifest.json')));
for(const [name,want] of Object.entries(manifest)){
 const b=fs.readFileSync(path.join(candidate,name));
 if(b.length!==want.size||createHash('sha256').update(b).digest('hex')!==want.sha256)throw Error('Wrong candidate '+name);
}
const report={source:process.env.GITHUB_SHA,files:manifest,version:'1.0.2',physical_iphone:false,checks:[],images:[],errors:[],samples:[]};
const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2));
function check(name,ok,data){report.checks.push({name,passed:!!ok,data});save();if(!ok)throw Error(name);}
let releases=[];
const mime={'.html':'text/html','.js':'application/javascript','.png':'image/png','.wasm':'application/wasm'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost'),m=url.pathname.match(/^\/(original|candidate)\/(.*)$/);
 if(!m){res.writeHead(404).end();return;}
 const root=path.resolve(m[1]==='original'?original:candidate),file=path.resolve(root,m[2]||'index.html');
 if(!file.startsWith(root+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store','Content-Length':fs.statSync(file).size});
 if(file.endsWith('index.pck')){
  // Real engine/download held after the first MB, to inspect rotation reliably.
  const fd=fs.openSync(file,'r'),first=Buffer.alloc(1024*1024);fs.readSync(fd,first);fs.closeSync(fd);res.write(first);
  releases.push(()=>{if(!res.destroyed)fs.createReadStream(file,{start:first.length}).pipe(res);});
 }else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await webkit.launch({headless:true});report.browser=browser.version();
async function state(page){return page.evaluate(()=>{
 const rect=n=>{const b=document.getElementById(n)?.getBoundingClientRect();return b?{x:b.x,y:b.y,w:b.width,h:b.height,bottom:b.bottom,right:b.right}:null;};
 const v=visualViewport;
 return {overlay:rect('status'),image:rect('status-splash'),bar:rect('status-progress'),viewport:{x:v.offsetLeft,y:v.offsetTop,w:v.width,h:v.height},imageLoaded:document.getElementById('status-splash')?.naturalWidth>0,visible:getComputedStyle(document.getElementById('status')).visibility};
});}
async function shot(page,name){await page.screenshot({path:path.join(output,name+'.png')});report.images.push(name+'.png');save();}
function contained(s){const b=s.bar,v=s.viewport;return b&&b.w>0&&b.h>0&&b.x>=v.x-1&&b.y>=v.y-1&&b.right<=v.x+v.w+1&&b.bottom<=v.y+v.h+1;}
async function inspect(page,name){await page.waitForTimeout(200);const s=await state(page);report.samples.push({name,...s});check(name+'-bar-visible',contained(s),s);check(name+'-image-centered',s.imageLoaded&&Math.abs(s.image.y+s.image.h/2-s.viewport.y-s.viewport.h/2)<2,s);await shot(page,name);}
try{
 // Deterministic layout/visual viewport mismatch isolates the Safari toolbar
 // problem. This is a fixture, explicitly distinct from real resize checks.
 for(const flavor of ['original','candidate']){
  const c=await browser.newContext({viewport:{width:844,height:390},isMobile:true,hasTouch:true});
  await c.addInitScript(()=>{
   const v=new EventTarget();Object.assign(v,{width:844,height:280,offsetLeft:0,offsetTop:20});
   Object.defineProperty(window,'visualViewport',{value:v,configurable:true});
  });
  const p=await c.newPage();await p.goto(`http://127.0.0.1:${server.address().port}/${flavor}/`,{waitUntil:'domcontentloaded'});
  await p.waitForFunction(()=>document.getElementById('status-progress')?.getBoundingClientRect().height>0);
  await p.waitForTimeout(200);const s=await state(p);report.samples.push({name:flavor+'-toolbar-fixture',...s});await shot(p,flavor+'-toolbar-fixture');
  check(flavor+'-toolbar-fixture',flavor==='original'?!contained(s):contained(s),s);
  if(flavor==='candidate'){
   await p.evaluate(()=>{Object.assign(visualViewport,{width:780,height:250,offsetLeft:20,offsetTop:40});visualViewport.dispatchEvent(new Event('resize'));visualViewport.dispatchEvent(new Event('scroll'));});
   await inspect(p,'candidate-toolbar-change');
  }
  await c.close();releases=[];
 }
 const context=await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:3,isMobile:true,hasTouch:true});
 const page=await context.newPage();page.setDefaultTimeout(120000);
 page.on('pageerror',e=>report.errors.push(e.message));
 page.on('console',m=>{if(/SCRIPT ERROR|^ERROR:/.test(m.text()))report.errors.push(m.text());});
 for(const cycle of ['cold','reload']){
  await page.setViewportSize({width:390,height:844});
  if(cycle==='cold')await page.goto(`http://127.0.0.1:${server.address().port}/candidate/`,{waitUntil:'domcontentloaded'});
  else await page.reload({waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>document.getElementById('status-progress')?.getBoundingClientRect().height>0);
  await inspect(page,cycle+'-portrait');
  await page.setViewportSize({width:844,height:390});await inspect(page,cycle+'-landscape');
  await page.setViewportSize({width:390,height:844});await inspect(page,cycle+'-portrait-return');
  await page.setViewportSize({width:844,height:390});await inspect(page,cycle+'-landscape-return');
  await page.waitForTimeout(500);for(const release of releases)release();releases=[];
  await page.waitForFunction(()=>window.everDeeperVersion==='1.0.2');
  await page.waitForFunction(()=>!document.getElementById('status'));
  await page.waitForTimeout(800);await shot(page,cycle+'-ready');
  const gpu=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio};});
  check(cycle+'-ready',!gpu.lost&&!!gpu.renderer,gpu);
  await page.setViewportSize({width:390,height:844});await page.setViewportSize({width:844,height:390});await page.waitForTimeout(300);
  check(cycle+'-overlay-stays-removed',await page.evaluate(()=>!document.getElementById('status')));
 }
 check('no-runtime-errors',report.errors.length===0,report.errors);
 report.passed=true;
}catch(e){report.failure=String(e.stack||e);console.error(report.failure);process.exitCode=1;}
finally{save();await browser.close();await new Promise(r=>server.close(r));}
