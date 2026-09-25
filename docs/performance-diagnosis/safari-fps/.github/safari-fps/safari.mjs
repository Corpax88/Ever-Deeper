import {createServer} from 'node:http';
import fs from 'node:fs';
import {resolve,extname} from 'node:path';
import {spawn,execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const [dir,outArg]=process.argv.slice(2),root=resolve(dir),out=resolve(outArg);fs.mkdirSync(out,{recursive:true});
const files=JSON.parse(fs.readFileSync(root+'/manifest.json'));
for(const [name,want]of Object.entries(files)){const h=createHash('sha256');for await(const b of fs.createReadStream(root+'/'+name))h.update(b);assert.equal(h.digest('hex'),want.sha256);assert.equal(fs.statSync(root+'/'+name).size,want.size);}
const report={source_commit:process.env.GITHUB_SHA,physical_iphone:false,candidate_source:'7a236e5147fa4f12da023fb350ca7660479c622a',candidate_run:36110103989,scope:'Instrumented mining fixture in actual Simulator Safari app; synthetic Godot mining action, not a native touch acceptance test. Local HTTP bridge adds observation cost. No release.',files,checks:[],windows:[],captures:[],documents:[],errors:[]};
let latest=null,pending=null,seq=0,session,driver,device,driverLog='';
const pause=ms=>new Promise(r=>setTimeout(r,ms));
const bridge=`<script>(()=>{
 let busy=false,gl=null,info=null,events=[];
 const send=(kind,data)=>events.push({kind,data,at:Date.now()});
 for(const name of ['log','warn','error']){const fn=console[name];console[name]=function(...args){send('console-'+name,args.map(String).join(' '));return fn.apply(console,args)}}
 window.alert=message=>send('alert',String(message));
 window.addEventListener('error',e=>send('error',String(e.message)));
 window.addEventListener('unhandledrejection',e=>send('rejection',String(e.reason)));
 const original=HTMLCanvasElement.prototype.getContext;
 HTMLCanvasElement.prototype.getContext=function(...args){
  const result=original.apply(this,args);
  if(result&&args[0]==='webgl2'&&this.id==='canvas'&&!gl){
   gl=result;const e=gl.getExtension('WEBGL_debug_renderer_info');
   info={attributes:gl.getContextAttributes(),renderer:gl.getParameter(e?e.UNMASKED_RENDERER_WEBGL:gl.RENDERER),max_texture:gl.getParameter(gl.MAX_TEXTURE_SIZE),max_renderbuffer:gl.getParameter(gl.MAX_RENDERBUFFER_SIZE),extensions:gl.getSupportedExtensions()};send('context-created',info);
  }return result;
 };
 window.addEventListener('webglcontextlost',e=>{
  if(e.target.id!=='canvas')return;e.preventDefault();const attempts=Number(sessionStorage.getItem('qa-context-reloads')||0);send('context-lost',{message:e.statusMessage,reloads:attempts,info});
  if(attempts===0){sessionStorage.setItem('qa-context-reloads','1');setTimeout(()=>location.reload(),5000)}
 },true);
 setInterval(async()=>{if(busy)return;busy=true;try{
  await fetch('/__state',{method:'POST',body:JSON.stringify({events:events.splice(0),state:window.DEV14_STATE||null,ua:navigator.userAgent,width:innerWidth,height:innerHeight,dpr:devicePixelRatio,renderer:info?.renderer,context_lost:gl?.isContextLost(),canvas:gl?[gl.canvas.width,gl.canvas.height]:null})});
  const d=await(await fetch('/__command')).json();if(d)window.DEV14_COMMAND=JSON.stringify(d);
 }catch(e){}finally{busy=false}},200);
})();</script>`;
const server=createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname;
 if(name==='/__command'){res.writeHead(200,{'Content-Type':'application/json','Cache-Control':'no-store'}).end(JSON.stringify(pending));pending=null;return;}
 if(name==='/__state'||name==='/__error'){let b='';req.on('data',p=>b+=p);req.on('end',()=>{try{if(name==='/__state'){const data=JSON.parse(b);for(const e of data.events||[])report.errors.push(JSON.stringify(e));delete data.events;latest={...data,at:Date.now()}}else report.errors.push(b)}catch{}res.writeHead(204).end()});return;}
 const file=resolve(root,'.'+(name==='/'?'/index.html':name));if(!file.startsWith(root+'/')||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':{'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'}[extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(extname(file)==='.html'){report.documents.push({url:req.url,at:Date.now()});let s=fs.readFileSync(file,'utf8');s=s.replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{let c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';'});res.end(s.replace('<head>','<head>'+bridge));}else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'0.0.0.0',r));const origin='http://127.0.0.1:'+server.address().port;
function check(name,value){report.checks.push({name,passed:!!value});if(!value)throw Error(name);}
async function wait(label,predicate,timeout=90000){for(let end=Date.now()+timeout;Date.now()<end;){if(report.errors.filter(e=>e.includes('context-lost')).length>=2)throw Error('Repeated WebGL context loss after one reload');if(latest?.state?.error)throw Error(latest.state.error);if(predicate(latest))return latest;await pause(250)}throw Error(label+' timeout: '+JSON.stringify(latest));}
async function cmd(kind,extra={}){const id=++seq;pending={kind,id,...extra};const s=await wait(kind,v=>v?.state?.id===id);return s.state;}
async function wd(method,path,body,timeout=120000){const r=await fetch('http://127.0.0.1:4723'+path,{method,headers:{'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(timeout)});const d=await r.json();if(!r.ok||d.value?.error)throw Error(JSON.stringify(d));return d.value;}
const command=(method,path,body)=>wd(method,'/session/'+session+path,body);
async function shot(name){execFileSync('xcrun',['simctl','io',device.udid,'screenshot',out+'/'+name+'.png'],{timeout:30000});report.captures.push({name,state:latest});}
try{
 report.xcode=execFileSync('xcodebuild',['-version'],{encoding:'utf8'});
 const list=JSON.parse(execFileSync('xcrun',['simctl','list','devices','available','-j'],{encoding:'utf8'}));
 const phones=Object.entries(list.devices).filter(([r])=>r.endsWith('iOS-26-2')).flatMap(([runtime,ds])=>ds.filter(d=>d.isAvailable&&d.name.startsWith('iPhone')).map(d=>({...d,runtime})));
 device=phones.find(d=>d.name.includes('Air'))||phones.find(d=>d.name==='iPhone 17')||phones[0];assert.ok(device,'Installed iPhone runtime');report.device=device;
 driver=spawn(process.execPath,[resolve('node_modules/appium/index.js'),'--address','127.0.0.1','--port','4723','--log',out+'/appium.log','--log-no-colors'],{detached:true});driver.stdout.on('data',b=>driverLog+=b);driver.stderr.on('data',b=>driverLog+=b);
 if(device.state!=='Booted')execFileSync('xcrun',['simctl','boot',device.udid],{timeout:120000});execFileSync('xcrun',['simctl','bootstatus',device.udid,'-b'],{timeout:240000});execFileSync('open',['-a','Simulator','--args','-CurrentDeviceUDID',device.udid]);
 for(let end=Date.now()+90000;Date.now()<end;){try{if((await wd('GET','/status',undefined,5000)).ready)break}catch{}await pause(500)}
 const created=await wd('POST','/session',{capabilities:{alwaysMatch:{platformName:'iOS','appium:automationName':'XCUITest','appium:bundleId':'com.apple.mobilesafari','appium:udid':device.udid,'appium:platformVersion':'26.2','appium:newCommandTimeout':900,'appium:noReset':true,'appium:autoWebview':false,'appium:orientation':'LANDSCAPE','appium:waitForIdleTimeout':0,'appium:wdaLaunchTimeout':600000,'appium:usePreinstalledWDA':true,'appium:prebuiltWDAPath':process.env.WDA_APP}}},660000);session=created.sessionId;
 report.context=await command('GET','/context');check('native-session',report.context==='NATIVE_APP');await command('POST','/orientation',{orientation:'LANDSCAPE'});
 // Prior attempt used Appium deepLink and remained on Start Page. Open through simctl and verify HTTP requests + live fixture state.
 execFileSync('xcrun',['simctl','openurl',device.udid,origin],{timeout:30000});
 await wait('actual Safari fixture menu',v=>v?.state?.menu,300000);report.runtime={...latest,state:undefined};check('iphone-agent',/iPhone/.test(latest.ua));check('landscape',latest.width>latest.height);await shot('01-menu');
 await cmd('setup',{mine:'emberMine',cached:true,durable:true});await wait('native hero',v=>v?.state?.native?.active&&v.state.native.updates>3);await pause(4000);await shot('02-mining-world');
 const modes=['baseline','fixed_off','headlamps_off','lights_off'];for(const mode of modes){await cmd('lightmode',{mode});await pause(2500)}await cmd('lightmode',{mode:'baseline'});await pause(30000);
 await cmd('hold');await wait('real mining',v=>v?.state?.mining);await pause(10000);
 const order=['baseline','fixed_off','headlamps_off','lights_off','lights_off','headlamps_off','fixed_off','baseline'];
 for(const mode of order){await cmd('lightmode',{mode});await pause(2000);const before=latest.state;await cmd('begin');await pause(15000);const ended=await cmd('end');const impacts=ended.impact-before.impact;check('mining-'+report.windows.length,ended.mining&&impacts>=25&&ended.result.frames>100);check('lights-'+report.windows.length,ended.result.light_cost.lights.every(l=>l.enabled===!(mode==='lights_off'||(mode==='fixed_off'&&l.path.startsWith('WorkLight_'))||(mode==='headlamps_off'&&!l.path.startsWith('WorkLight_')))));report.windows.push({mode,...ended.result,impacts});fs.writeFileSync(out+'/windows.json',JSON.stringify(report.windows,null,2));}
 await cmd('release_hold');await cmd('lightmode',{mode:'baseline'});await shot('03-restored');report.passed=true;
}catch(e){report.passed=false;report.failure=String(e.stack||e);process.exitCode=1;console.error(report.failure);if(device)await shot('failure').catch(()=>{});}
finally{if(device){try{const log=execFileSync('xcrun',['simctl','spawn',device.udid,'log','show','--last','6m','--style','compact','--predicate','process CONTAINS "WebKit" OR eventMessage CONTAINS[c] "jetsam" OR eventMessage CONTAINS[c] "GPU process"'],{encoding:'utf8',timeout:45000,maxBuffer:12*1024*1024});fs.writeFileSync(out+'/webkit-system.log',log)}catch(e){fs.writeFileSync(out+'/system-log-error.txt',String(e))}}report.latest=latest;fs.writeFileSync(out+'/report.json',JSON.stringify(report,null,2));fs.writeFileSync(out+'/driver-stdout.log',driverLog);if(session)await command('DELETE','').catch(()=>{});if(driver?.pid)try{process.kill(-driver.pid,'SIGTERM')}catch{}server.closeAllConnections();await new Promise(r=>server.close(r));}
