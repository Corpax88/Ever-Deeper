import {PNG} from 'pngjs';
import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version='1.0.0-dev.15.9',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
const digest=b=>createHash('sha256').update(b).digest('hex');
for(const [name,want] of Object.entries(files)){
 const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))h.update(b);
 if(h.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const server=http.createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname,file=path.resolve(web,'.'+(name==='/'?'/index.html':name));
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(file.endsWith('index.html'))res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:3,hasTouch:true});
await context.addInitScript(() => {
 const meter={active:false,available:null,pending:[],rows:[],disjoint:0,armed:false,query:null,gl:null,ext:null,draws:0,tick:0};
 window.__gpuMeter=meter;
 function poll(){
  if(!meter.gl||!meter.ext)return;
  const g=meter.gl,e=meter.ext;
  if(g.getParameter(e.GPU_DISJOINT_EXT)){meter.disjoint++;for(const q of meter.pending)g.deleteQuery(q);meter.pending=[];return;}
  meter.pending=meter.pending.filter(q=>{if(!g.getQueryParameter(q,g.QUERY_RESULT_AVAILABLE))return true;meter.rows.push(g.getQueryParameter(q,g.QUERY_RESULT)/1e6);g.deleteQuery(q);return false;});
 }
 for(const name of ['drawArrays','drawElements','drawArraysInstanced','drawElementsInstanced','drawRangeElements']){
  const original=WebGL2RenderingContext.prototype[name];
  WebGL2RenderingContext.prototype[name]=function(...args){
   if(meter.armed&&this===meter.gl){
    if(!meter.query&&!this.getQuery(meter.ext.TIME_ELAPSED_EXT,this.CURRENT_QUERY)){meter.query=this.createQuery();this.beginQuery(meter.ext.TIME_ELAPSED_EXT,meter.query);}
    meter.draws++;
   }
   return original.apply(this,args);
  };
 }
 const raf=window.requestAnimationFrame;
 window.requestAnimationFrame=function(callback){return raf.call(window,function(t){
  poll();
  if(meter.active&&++meter.tick%3===0&&!meter.armed){
   const g=document.querySelector('canvas')?.getContext('webgl2');
   if(g){meter.gl=g;meter.ext=g.getExtension('EXT_disjoint_timer_query_webgl2');meter.available=!!meter.ext;}
   meter.armed=!!meter.ext;
   try{return callback(t);}finally{
    if(meter.query){meter.gl.endQuery(meter.ext.TIME_ELAPSED_EXT);meter.pending.push(meter.query);meter.query=null;}
    meter.armed=false;
   }
  }
  return callback(t);
 });};
 meter.begin=()=>{meter.rows=[];meter.disjoint=0;meter.draws=0;meter.active=true;};
 meter.stop=()=>{meter.active=false;poll();return {available:meter.available,disjoint:meter.disjoint,draws:meter.draws,values:meter.rows};};
});
const page=await context.newPage(),cdp=await context.newCDPSession(page);page.setDefaultTimeout(90000);
const checks=[],messages=[],windows=[];let failed=null,runtime=null,id=0;
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR: '+e.message));
const state=()=>page.evaluate(()=>window.DEV14_STATE),delay=ms=>new Promise(r=>setTimeout(r,ms));
function check(name,ok,details={}){checks.push({name,passed:!!ok,...details});fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify(checks,null,2));if(!ok)throw Error(name);}
async function wait(label,predicate,timeout=60000){
 const start=Date.now();let s;
 while(Date.now()-start<timeout){s=await state();if(s?.error||s?.native?.failed)throw Error(label+': '+JSON.stringify(s));if(predicate(s))return s;if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error(label+': runtime error');await delay(150);}
 throw Error(label+' timeout: '+JSON.stringify(s));
}
async function command(kind,extra={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
async function shot(name){await delay(350);const bytes=await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});return digest(bytes);}
const pairs=[];
async function parity(label){
 await command('reference');const reference=await shot(label+'-reference');
 await command('cached');const candidate=await shot(label+'-cached');
 await command('reference'); const restored=await shot(label+'-restored-reference');
 const a=PNG.sync.read(fs.readFileSync(path.join(output,label+'-reference.png'))),b=PNG.sync.read(fs.readFileSync(path.join(output,label+'-cached.png')));
 let max=0,changed=0;for(let i=0;i<a.data.length;i++){const d=Math.abs(a.data[i]-b.data[i]);max=Math.max(max,d);if(d)changed++;}
 pairs.push({label,reference,candidate,restored,max_channel_difference:max,changed_channels:changed});
 check('restored-parity-'+label,reference===restored,{reference,restored});
 check('candidate-parity-'+label,max<=1,{max_channel_difference:max,changed_channels:changed});
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:90000});
 await wait('menu',s=>s?.menu,180000);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e.UNMASKED_RENDERER_WEBGL),user_agent:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]};});
 check('apple-gpu',/Apple|Metal/.test(runtime.renderer),{runtime});
 check('version',(await state()).version===version);
 for(const mine of ['emberMine','mossMine','moonMine','starMine']){
  await command('setup',{mine});await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(1200);
  await command('freeze');await parity(mine+'-intact');
  await command('damage');await parity(mine+'-damaged');
  await command('break');await parity(mine+'-broken');
  await command('restore');await parity(mine+'-restored');
 }
 await command('setup',{mine:'emberMine'});await delay(1500);await command('freeze');
 for(const style of ['standard','focused','wide','prismatic','deepheart']){await command('style',{style});await parity('stress-'+style);}
 // One shared scene, same durable mining target; A/B/B/A/B/A mitigates warm-up/order.
 await command('setup',{mine:'emberMine',durable:true,cached:false});await wait('native',s=>s?.native?.active&&s.native.updates>3);
 let before=await state();const p={x:before.mine_button[0]/before.viewport[0]*844,y:before.mine_button[1]/before.viewport[1]*390};
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{id:7,...p,radiusX:5,radiusY:5,force:1}]});
 await wait('mining contact',s=>s?.impact>before.impact);await delay(20000);
 for(const [index,cached] of [false,true,true,false,true,false].entries()){
  await command(cached?'cached':'reference');await delay(1500);before=await state();
  await page.evaluate(()=>window.__gpuMeter.begin());await command('begin');await delay(12000);const ended=await command('end');
  await page.evaluate(()=>window.__gpuMeter.active=false);await delay(400);const gpu=await page.evaluate(()=>window.__gpuMeter.stop());
  windows.push({index,cached,...ended.result,impacts:ended.impact-before.impact,gpu});
  check('held-mining-'+index,ended.impact>=before.impact+5&&ended.result.frames>200,{impacts:ended.impact-before.impact});
 }
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await wait('release',s=>!s.mining);
 await command('setup',{mine:'emberMine',cached:true});await delay(1000);
 const a=await state();await page.keyboard.down('ArrowDown');await delay(650);await page.keyboard.up('ArrowDown');const b=await state();
 check('movement-after-mining',Math.hypot(a.position[0]-b.position[0],a.position[1]-b.position[1])>10);
 await command('freeze');await parity('ember-after-camera-move');
 check('no-script-errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
}catch(e){failed=String(e);console.error(e);}finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,files,runtime,checks,windows,pairs,physical_iphone_verified:false,scope:'Depth-one native shader vs existing alpha-discard; frozen A/B/A images, identical held mining and optional GPU command interval. No physical iPhone FPS claim.'},null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;
