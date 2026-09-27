import {PNG} from 'pngjs';
import {webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const [candidate,output]=process.argv.slice(2);const original=candidate;fs.mkdirSync(output,{recursive:true});
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
const browser=await webkit.launch({headless:true}),checks=[],windows=[],captures=[],runtimes=[],messages=[];
const order=['candidate'];
let failed=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
function check(name,passed,details={}){checks.push({name,passed:!!passed,...details});if(!passed)throw Error(name);}
try{
 for(const [block,side] of order.entries()){
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
  const page=await context.newPage();let id=0;const localMessages=[];
  page.on('console',m=>{localMessages.push(m.type()+': '+m.text());messages.push({block,side,message:m.type()+': '+m.text()})});
  page.on('pageerror',e=>localMessages.push('PAGEERROR '+e.message));
  const state=()=>page.evaluate(()=>window.DEV14_STATE);
  async function wait(label,predicate,timeout=90000){let s;for(let end=Date.now()+timeout;Date.now()<end;){s=await state();if(s?.error||s?.native?.failed)throw Error(label+JSON.stringify(s));if(predicate(s))return s;if(localMessages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error('Runtime '+label);await delay(150)}throw Error(label+' timeout '+JSON.stringify(s));}
  async function command(kind,extra={}){const wanted=++id;await page.evaluate(v=>window.DEV14_COMMAND=JSON.stringify(v),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
  try{
   await page.goto('http://127.0.0.1:'+server.address().port+'/'+side+'/',{waitUntil:'domcontentloaded',timeout:90000});await wait('menu',s=>s?.menu,180000);
   const runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER),browser:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]}});runtimes.push({side,block,...runtime});
   check('Apple GPU '+block,process.platform==='darwin'&&/Apple|Metal/.test(runtime.renderer));check('full resolution '+block,runtime.canvas[0]===2328&&runtime.canvas[1]===1260);
   await command('setup',{mine:'emberMine',cached:true,durable:true,stable:false});await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(3000);
   check('version', (await state()).version==='1.0.0-dev.15.10');
   async function parity(tag){
    await command('freeze');await page.mouse.move(0,0);await delay(300);
    const buffers=[];
    for(const enabled of [false,true,false]){
     await command('stable',{enabled});await delay(300);
     const name=block+'-'+tag+'-'+buffers.length+'.png';
     buffers.push(await page.screenshot({path:path.join(output,name),timeout:60000}));captures.push(name);
    }
    const imgs=buffers.map(b=>PNG.sync.read(b));let different=0,max=0;
    for(let i=0;i<imgs[0].data.length;i++){const d=Math.abs(imgs[0].data[i]-imgs[1].data[i]);if(d)different++;max=Math.max(max,d)}
    check('restore exact '+block+'-'+tag,imgs[0].data.equals(imgs[2].data));
    check('stable exact '+block+'-'+tag,different===0,{different,max});
    await command('stable',{enabled:side==='candidate'});await command('unfreeze');
   }
   const before=await state();await page.mouse.move(before.mine_button[0]/before.viewport[0]*776,before.mine_button[1]/before.viewport[1]*420);await page.mouse.down();
   await command('audio_mode',{cached:true});await delay(15000);
   const pairs=process.env.REPEAT==='2'?['BA','AB','AB','BA','AB','BA','BA','AB']:['AB','BA','BA','AB','BA','AB','AB','BA'];
   const modes=pairs.join('').split('').map(v=>v==='A'?'original':'candidate');
   for(const [index,mode] of modes.entries()){
    await page.evaluate(v=>globalThis.__reuseImmutableMusicBuffers=v,mode==='candidate');
    await command('audio_mode',{cached:mode==='candidate'});await delay(1500);
    const start=await state();await command('begin',{instrument:true});await delay(8000);const end=await command('end');
    check('same native mining workload '+index,end.native.active&&end.result.frames>150&&end.impact-start.impact>=10&&JSON.stringify(start.position)===JSON.stringify(end.position));
    const liveBuffers=await page.evaluate(()=>window.__audioProbe.live());
    const processes=execFileSync('ps',['-axo','pid=,rss=,comm='],{encoding:'utf8'}).split('\n').filter(v=>/WebKit|MiniBrowser/.test(v));
    windows.push({liveBuffers,processes,block,index,side:mode,impacts:end.impact-start.impact,...end.result,native:end.native,position:end.position});
    fs.writeFileSync(path.join(output,'windows.json'),JSON.stringify(windows,null,2));
   }
   await page.mouse.up();
   await command('freeze');await delay(300);const name=block+'-'+side+'.png';await page.screenshot({path:path.join(output,name)});captures.push(name);
   check('no runtime errors '+block,!localMessages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
  }finally{await context.close();}
 }
}catch(e){failed=String(e.stack||e);console.error(failed);}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,candidate_source:process.env.GITHUB_SHA,original_source:'ab0c12ff579134e0a092946bd92973e4599a073c',repeat:process.env.REPEAT,files,order,runtimes,checks,windows,captures,messages,physical_iphone_verified:false,scope:'Same-context steady mining isolates only immutable PCM reuse versus copy; both modes use the same three cached streams, same position and track0. 15s warmup and eight balanced adjacent AB/BA pairs, sixteen8s windows; original duplicates MP3 as real legacy code, candidate caches. All three preparatory buffers are common. Each restart is outside the measured window. Not a physical phone result. Prior test: Music sample registration/caching trial: all three unmodified MP3s pre-registered before menu; reference duplicates every transition, candidate reuses private cached sample. Two balanced contexts across workers; one natural90s route and six near-end transitions per mode, plus volume/mute. QA-only DEV15.10 package, measured actual movement and block destruction; shared profiling overhead, fresh balanced contexts. Candidate reuses immutable long WebAudio buffers; width6 terrain, assets, lights and resolution unchanged. CPU wrapper wall time not GPU time. Save uses isolated fixture namespace. Includes all windows/stalls. No physical phone claim.'},null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;

