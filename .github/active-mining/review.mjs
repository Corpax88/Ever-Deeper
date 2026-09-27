import {PNG} from 'pngjs';
import {webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const [original,candidate,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const roots={original:path.resolve(original),candidate:path.resolve(candidate)},files={};
for(const [side,root] of Object.entries(roots)){
 files[side]=JSON.parse(fs.readFileSync(path.join(root,'manifest.json')));
 for(const [name,want] of Object.entries(files[side])){
  const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(root,name)))h.update(b);
  if(h.digest('hex')!==want.sha256||fs.statSync(path.join(root,name)).size!==want.size)throw Error('Package identity '+side+'/'+name);
 }
}
const server=http.createServer((req,res)=>{
 const bits=new URL(req.url,'http://localhost').pathname.split('/').filter(Boolean),side=bits.shift(),root=roots[side];
 if(!root){res.writeHead(404).end();return;}
 const file=path.resolve(root,bits.join('/')||'index.html');
 if(!file.startsWith(root+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(file.endsWith('index.html'))res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));

const checks=[],windows=[],captures=[],runtimes=[],messages=[],instances=[];
let failed=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
function check(name,passed,details={}){checks.push({name,passed:!!passed,...details});if(!passed)throw Error(name)}
function processes(){return execFileSync('ps',['-axo','pid=,stat=,comm='],{encoding:'utf8'}).split('\n').filter(v=>/ms-playwright.*(WebKit|MiniBrowser)/.test(v)).map(v=>{const m=v.trim().match(/^(\d+)\s+(\S+)\s+(.+)$/);return {pid:Number(m[1]),stat:m[2],command:m[3]}})}
function signal(instance,kind){
 const current=new Map(processes().map(p=>[p.pid,p]));
 for(const p of instance.pids){const found=current.get(p.pid);if(!found){if(kind==='SIGCONT')continue;throw Error('Browser child exited '+p.pid)}check('owned process identity '+p.pid,found.command===p.command);process.kill(p.pid,kind)}
}
async function initialize(side){
 const before=new Set(processes().map(p=>p.pid)),browser=await webkit.launch({headless:true});
 const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true});
  await context.addInitScript(({reuse})=>{
   globalThis.__reuseImmutableMusicBuffers=reuse;
   const probe=window.__audioProbe={buffers:[],starts:[],outputs:[],ids:new WeakMap(),weak:[],count:0};
   const create=BaseAudioContext.prototype.createBuffer;
   BaseAudioContext.prototype.createBuffer=function(...args){const b=create.apply(this,args),id=++probe.count;probe.ids.set(b,id);if(b.duration>10)probe.weak.push(new WeakRef(b));if(b.duration>10)probe.buffers.push({id,length:b.length,rate:b.sampleRate,channels:b.numberOfChannels,bytes:b.length*b.numberOfChannels*4});return b};
   const start=AudioBufferSourceNode.prototype.start;
   AudioBufferSourceNode.prototype.start=function(...args){if(this.buffer?.duration>10)probe.starts.push({id:probe.ids.get(this.buffer),at:performance.now(),args});return start.apply(this,args)};
   const connect=AudioNode.prototype.connect;
   AudioNode.prototype.connect=function(...args){const v=connect.apply(this,args);if(args[0] instanceof AudioDestinationNode&&!probe.outputs.some(o=>o.source===this))probe.outputs.push({source:this,context:this.context});return v};
   probe.live=()=>probe.weak.reduce((a,w)=>{const b=w.deref();if(b){a.count++;a.bytes+=b.length*b.numberOfChannels*4}return a},{count:0,bytes:0});
   probe.snapshot=()=>({buffers:probe.buffers,starts:probe.starts,contexts:probe.outputs.map(o=>({state:o.context.state,rate:o.context.sampleRate})),at:performance.now()});
   probe.capture=async()=>{
    const o=probe.outputs[0];if(!o)throw Error('No actual audio output');
    const destination=o.context.createMediaStreamDestination(),analyser=o.context.createAnalyser();analyser.fftSize=2048;
    connect.call(o.source,destination);connect.call(o.source,analyser);
    const mime=['audio/mp4','audio/webm'].find(t=>MediaRecorder.isTypeSupported(t));if(!mime)throw Error('No audio recorder');
    const recorder=new MediaRecorder(destination.stream,{mimeType:mime}),chunks=[],samples=new Float32Array(2048),rms=[];
    recorder.ondataavailable=e=>chunks.push(e.data);const ended=new Promise(r=>recorder.onstop=r);recorder.start();
    for(let i=0;i<30;i++){await new Promise(r=>setTimeout(r,100));analyser.getFloatTimeDomainData(samples);rms.push(Math.sqrt(samples.reduce((a,v)=>a+v*v,0)/samples.length))}
    recorder.stop();await ended;o.source.disconnect(destination);o.source.disconnect(analyser);
    const bytes=new Uint8Array(await new Blob(chunks,{type:mime}).arrayBuffer());let binary='';for(let i=0;i<bytes.length;i+=8192)binary+=String.fromCharCode(...bytes.subarray(i,i+8192));
    return {mime,data:btoa(binary),rms,context:o.context.state};
   };
  },{reuse:side==='candidate'});

 const page=await context.newPage(),localMessages=[];let id=0;
 const instance={side,browser,context,page,pids:[],suspended:false};instances.push(instance);
 page.on('console',m=>{localMessages.push(m.type()+': '+m.text());messages.push({side,message:m.type()+': '+m.text()})});
 page.on('pageerror',e=>localMessages.push('PAGEERROR '+e.message));
 const state=()=>page.evaluate(()=>window.DEV14_STATE);
 async function wait(label,predicate,timeout=90000){let s;for(let end=Date.now()+timeout;Date.now()<end;){s=await state();if(s?.error||s?.native?.failed)throw Error(label+JSON.stringify(s));if(predicate(s))return s;if(localMessages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error('Runtime '+label);await delay(100)}throw Error(label+' timeout '+JSON.stringify(s))}
 async function command(kind,extra={}){const wanted=++id;await page.evaluate(v=>window.DEV14_COMMAND=JSON.stringify(v),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted)}
 Object.assign(instance,{state,command,localMessages});
 await page.goto('http://127.0.0.1:'+server.address().port+'/'+side+'/',{waitUntil:'domcontentloaded',timeout:90000});await wait('menu',s=>s?.menu,180000);
 const runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER),browser:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]}});runtimes.push({side,...runtime});
 check('Apple GPU '+side,process.platform==='darwin'&&/Apple|Metal/.test(runtime.renderer));check('full resolution '+side,runtime.canvas[0]===2328&&runtime.canvas[1]===1260);
 await command('setup',{mine:'emberMine',cached:true,durable:true,stable:false});await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(3000);
 const s=await state();check('version '+side,s.version==='1.0.0-dev.15.10');
 await page.mouse.move(s.mine_button[0]/s.viewport[0]*776,s.mine_button[1]/s.viewport[1]*420);await page.mouse.down();await delay(15000);
 instance.pids=processes().filter(p=>!before.has(p.pid));
 check('dedicated browser children '+side,instance.pids.some(p=>/WebContent/.test(p.command))&&instance.pids.some(p=>/GPU/.test(p.command)));
 instance.startupBuffers=await page.evaluate(()=>window.__audioProbe.live());
 await suspend(instance);
 return instance;
}
async function suspend(instance){
 await instance.command('freeze');
 const contexts=await instance.page.evaluate(async()=>{const contexts=[...new Set(window.__audioProbe.outputs.map(o=>o.context))];await Promise.all(contexts.map(c=>c.suspend()));return contexts.map(c=>c.state)});
 check('audio suspended '+instance.side,contexts.length>0&&contexts.every(s=>s==='suspended'));
 const ownNow=processes().filter(p=>instance.pids.some(w=>w.pid===p.pid));
 check('all owned children remain '+instance.side,ownNow.length===instance.pids.length);
 signal(instance,'SIGSTOP');instance.suspended=true;
 for(let n=0;n<50;n++){const rows=processes().filter(p=>instance.pids.some(w=>w.pid===p.pid));if(rows.length===instance.pids.length&&rows.every(p=>p.stat.includes('T')))break;await delay(20)}
 check('OS stopped '+instance.side,processes().filter(p=>instance.pids.some(w=>w.pid===p.pid)).every(p=>p.stat.includes('T')));
}
async function resume(instance){
 signal(instance,'SIGCONT');instance.suspended=false;
 const contexts=await instance.page.evaluate(async()=>{const contexts=[...new Set(window.__audioProbe.outputs.map(o=>o.context))];await Promise.all(contexts.map(c=>c.resume()));return contexts.map(c=>c.state)});
 check('audio resumed '+instance.side,contexts.length>0&&contexts.every(s=>s==='running'));
 await instance.command('unfreeze');
 const state=await instance.state();await instance.page.mouse.up();await instance.page.mouse.move(state.mine_button[0]/state.viewport[0]*776,state.mine_button[1]/state.viewport[1]*420);await instance.page.mouse.down();
}
const base=process.env.REPEAT==='2'?['BA','AB','AB','BA','AB','BA','BA','AB']:['AB','BA','BA','AB','BA','AB','AB','BA'];
const pairs=Array.from({length:8},()=>base).flat();
const order=pairs.join('').split('').map(v=>v==='A'?'original':'candidate');
try{
 check('clean worker',processes().length===0);
 const originalInstance=await initialize('original'),candidateInstance=await initialize('candidate');
 check('disjoint process ownership',originalInstance.pids.every(a=>candidateInstance.pids.every(b=>a.pid!==b.pid)));
 for(const [index,side] of order.entries()){
  const active=instances.find(i=>i.side===side),inactive=instances.find(i=>i.side!==side);
  check('no untracked browser children '+index,processes().every(p=>instances.some(i=>i.pids.some(w=>w.pid===p.pid))));
  check('inactive renderer stopped '+index,inactive.suspended&&processes().filter(p=>inactive.pids.some(w=>w.pid===p.pid)).every(p=>p.stat.includes('T')));
  await resume(active);await delay(1500);
  const audioBefore=await active.page.evaluate(()=>window.__audioProbe.outputs[0].context.currentTime);
  const start=await active.state();await active.command('begin',{instrument:false});await delay(4000);const end=await active.command('end');
  const audioAfter=await active.page.evaluate(()=>window.__audioProbe.outputs[0].context.currentTime);
  const music=await active.command('audio_status');check('music player active '+index,music.result.players.some(p=>p.playing));
  check('audio clock advances '+index,audioAfter-audioBefore>3.5);
  check('same active workload '+index,end.native.active&&end.result.frames>60&&end.impact-start.impact>=5&&JSON.stringify(start.position)===JSON.stringify(end.position));
  const liveBuffers=await active.page.evaluate(()=>window.__audioProbe.live());
  windows.push({index,pair:Math.floor(index/2),side,music:music.result,audioElapsed:audioAfter-audioBefore,liveBuffers,startupBuffers:active.startupBuffers,impacts:end.impact-start.impact,...end.result,native:end.native,position:end.position});
  fs.writeFileSync(path.join(output,'windows.json'),JSON.stringify(windows,null,2));
  if(index<2||index>=order.length-2){await active.command('freeze');await delay(200);const name=index+'-'+side+'.png';await active.page.screenshot({path:path.join(output,name)});captures.push(name);await active.command('unfreeze')}
  check('no runtime errors '+index,!active.localMessages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
  await suspend(active);
  if(index%16===15)console.log('Completed',index+1,'of',order.length,'controlled windows');
 }
}catch(e){failed=String(e.stack||e);console.error(failed)}
finally{
 // Always resume our own children before closing Playwright transports.
 for(const instance of instances){if(instance.suspended){try{signal(instance,'SIGCONT');instance.suspended=false}catch(e){messages.push({cleanup:String(e)})}}}
 for(const instance of instances){await instance.context.close();await instance.browser.close()}
 for(let retry=0;retry<50&&processes().length;retry++)await delay(200);
 const exited=processes().length===0;checks.push({name:'all browser children exited',passed:exited});if(!exited&&!failed)failed='Browser child cleanup failed';
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,original_source:'ab0c12ff579134e0a092946bd92973e4599a073c',candidate_source:'ba396beeed9e587a8dc700edef7b28b79f1095d6',repeat:process.env.REPEAT,files,checks,windows,captures,runtimes,messages,order,processOwnership:instances.map(i=>({side:i.side,pids:i.pids})),physical_iphone_verified:false,scope:'Two separate browser processes resident per worker; inactive audio context suspended and all its owned browser children OS-stopped. 64 balanced adjacent pairs,4s measurement+1.5s settling, persistent exact audio paths without forced restarts. This controls launch-to-launch host variability; two-engine resident memory differs from a single game. Natural music transitions remain included. No physical phone claim.'},null,2));
 server.close();
}
if(failed)process.exitCode=1;
