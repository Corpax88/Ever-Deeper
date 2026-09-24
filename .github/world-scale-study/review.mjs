import {PNG} from 'pngjs';
import {chromium,webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const browserName=process.env.REVIEW_BROWSER||'chromium';
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
const browser=browserName==='webkit'?await webkit.launch({headless:true}):await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true});
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
const page=await context.newPage();page.setDefaultTimeout(90000);
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
const captures=[],parity=[];let initial=null;
async function mode(factor){
 await command('worldscale',{factor});await delay(2200);const s=await state();
 check('camera-and-framing',s.position.every((v,i)=>Math.abs(v-initial.position[i])<0.02)&&s.viewport.every((v,i)=>Math.abs(v-initial.viewport[i])<0.02));
 check('render-mode',factor===0?Object.keys(s.render_scale).length===0:s.render_scale.scale===factor&&s.render_scale.root_size[0]===2328&&s.render_scale.root_size[1]===1260);
 return s;
}
function compare(a,b,label){
 const x=PNG.sync.read(fs.readFileSync(path.join(output,a+'.png'))),y=PNG.sync.read(fs.readFileSync(path.join(output,b+'.png')));let changed=0,max=0;
 check('size-'+label,x.width===y.width&&x.height===y.height);
 for(let i=0;i<x.data.length;i++){const d=Math.abs(x.data[i]-y.data[i]);if(d)changed++;max=Math.max(max,d);}
 parity.push({label,max,changed});return max;
}
async function measure(scenario,order){
 for(const [index,factor]of order.entries()){
  await mode(factor);const before=await state();await command('begin');await delay(12000);const ended=await command('end');const impacts=ended.impact-before.impact;
  check(scenario+'-work-'+index,ended.result.frames>200&&(scenario==='mining'?impacts>=20&&ended.mining:impacts===0&&!ended.mining));
  windows.push({scenario,index,factor,...ended.result,impacts,render_scale:ended.render_scale});
  console.log(JSON.stringify({scenario,index,factor,fps:ended.result.frames/ended.result.seconds,p95:ended.result.frame.p95_ms}));
 }
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:90000});await wait('menu',s=>s?.menu,180000);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER),browser:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]};});
 check('apple-gpu',process.platform==='darwin'&&/Apple|Metal/.test(runtime.renderer),{runtime});check('native-root-size',runtime.canvas[0]===2328&&runtime.canvas[1]===1260);
 await command('setup',{mine:'emberMine',cached:true,durable:true});await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(2000);initial=await state();await command('freeze');
 for(const [i,factor]of [0,1,0.8,0].entries()){const s=await mode(factor),name='frozen-'+i+'-scale'+factor;captures.push({name,sha:await shot(name),state:s});}
 check('full-scale-composite-parity',compare('frozen-0-scale0','frozen-1-scale1','original-vs-full-composite')<=1);
 check('restoration-parity',compare('frozen-0-scale0','frozen-3-scale0','restored')===0);
 await command('unfreeze');for(const factor of [0,0.8,0]){await mode(factor);await delay(5000);}await delay(60000);
 const order=process.env.REPEAT==='2'?[0.8,0,0,0.8,0,0.8]:[0,0.8,0.8,0,0.8,0];await measure('stationary',order);
 const s=await state();await page.mouse.move(s.mine_button[0]/s.viewport[0]*776,s.mine_button[1]/s.viewport[1]*420);await page.mouse.down();await wait('held mining',v=>v.mining&&v.impact>s.impact);await delay(15000);await measure('mining',order);await page.mouse.up();await wait('release',v=>!v.mining);
 await mode(0.8);const before=await state();await page.keyboard.down('ArrowDown');await delay(650);await page.keyboard.up('ArrowDown');await delay(300);const after=await state();check('movement-in-scaled-world',Math.hypot(after.position[0]-before.position[0],after.position[1]-before.position[1])>10);
 captures.push({name:'moved-scale08',sha:await shot('moved-scale08'),state:after});
 await command('worldscale',{factor:0});await delay(2500);check('restore-mode',Object.keys((await state()).render_scale).length===0);check('no-script-errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
}catch(e){failed=String(e);console.error(e);}finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,files,repeat:process.env.REPEAT,runtime,checks,windows,parity,captures,physical_iphone_verified:false,scope:'QA-only world framebuffer80percent per axis; full-resolution root HUD. Original and full-scale composite parity before repeated original/scaled measurements. No release.'},null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;
