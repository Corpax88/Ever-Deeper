import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,previous,output]=process.argv.slice(2);
const digest=data=>createHash('sha256').update(data).digest('hex');
const oldBytes=fs.readFileSync(path.join(previous,'report.json'));
const old=JSON.parse(oldBytes),manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
if(old.passed!==false||!old.error?.includes('ordinary resume timeout:')||JSON.stringify(old.files)!==JSON.stringify(manifest))throw Error('Unexpected preceding evidence');
const required=['00-normal-dev14-menu','moss-up','moss-right','moss-down','moss-left','moss-held-rush','moss-walk-exit','endless-up','endless-right','endless-down','endless-left','iron-restored','drill-restored','worn-outfit-reentry','surface-ordinary','depth-ordinary','hub-ordinary','deepheart-ordinary','surface-touch-release','dev14-pause'];
for(const name of required)if(!old.checks.some(c=>c.name===name))throw Error('Missing completed preceding check '+name);
for(const c of old.checks){const s=c.after||c.hit;if(s?.native?.failed||s?.error)throw Error('Actual runtime failure in preceding evidence');}
for(const [name,want] of Object.entries(manifest)){
 const file=path.join(web,name),h=createHash('sha256');for await(const chunk of fs.createReadStream(file))h.update(chunk);
 if(h.digest('hex')!==want.sha256||fs.statSync(file).size!==want.size)throw Error('Candidate identity '+name);
}
fs.mkdirSync(output,{recursive:true});fs.cpSync(previous,path.join(output,'prior'),{recursive:true});
const checks=old.checks.filter(c=>c.name!=='failure').map(c=>({...c,evidence_run:35596622855,image:fs.existsSync(path.join(previous,c.name+'.png'))?'prior/'+c.name+'.png':null}));
const messages=[],mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname,file=path.resolve(web,'.'+(name==='/'?'/index.html':name));
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(path.extname(file)==='.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-dev14-review','--expected-version=1.0.0-dev.14'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2,hasTouch:true});
const page=await context.newPage();page.setDefaultTimeout(120000);
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR: '+e.message));
const state=()=>page.evaluate(()=>window.DEV14_STATE),delay=ms=>new Promise(r=>setTimeout(r,ms));
let id=0,runtime=null,failed=null;
async function wait(label,predicate,timeout=60000){const start=Date.now();let s;while(Date.now()-start<timeout){s=await state();if(s?.error||s?.native?.failed)throw Error(label+' runtime failure '+JSON.stringify(s));if(predicate(s))return s;if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|ERROR:/.test(m)))throw Error(label+' runtime console error');await delay(200);}throw Error(label+' timeout '+JSON.stringify(s));}
async function command(kind){const next=++id;await page.evaluate(data=>window.DEV14_COMMAND=JSON.stringify(data),{kind,id:next});await wait(kind,s=>s?.id===next);await delay(400);return state();}
async function capture(name){const before=await state();await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});const after=await state();checks.push({name,before,after,image:name+'.png',evidence_run:process.env.GITHUB_RUN_ID});console.log('DEV14_CAPTURE',name);}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});
 await wait('explicit QA startup',s=>s?.version==='1.0.0-dev.14',240000);
 await command('surface');await wait('Worn ready',s=>s?.native?.active&&s.gear==='worn'&&s.native.updates>3);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas')?.getContext('webgl2'),e=g?.getExtension('WEBGL_debug_renderer_info');return {viewport:[innerWidth,innerHeight],dpr:devicePixelRatio,renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g?.isContextLost()};});runtime.browser=browser.version();runtime.platform=process.platform;
 if(!runtime.renderer||runtime.lost||/SwiftShader|llvmpipe|software/i.test(runtime.renderer))throw Error('Required graphical renderer unavailable');
 await command('pause');await wait('ordinary pause',s=>s?.menu===true&&!s.native.active);await capture('dev14-pause-confirmed');
 await command('resume');
 // Surface has no universal `active` field. Verify visible native state and actual input instead.
 const before=await wait('ordinary resume',s=>s?.menu===false&&s.native.active&&s.gear==='worn');
 await page.keyboard.down('ArrowDown');await delay(400);await page.keyboard.up('ArrowDown');
 const moved=await wait('real movement after resume',s=>s?.position[1]>before.position[1]+2&&!s.mining,10000);
 await delay(350);await capture('dev14-resumed');
 checks.push({name:'resume-real-input',before,after:moved,evidence_run:process.env.GITHUB_RUN_ID});
 if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|ERROR:/.test(m)))throw Error('Runtime console error');
 console.log('DEV14_FINAL_REVIEW_PASSED same_candidate=true remaining_gate=resume_real_input');
}catch(e){failed=String(e.stack||e);console.error(failed);try{await capture('supplement-failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,version:'1.0.0-dev.14',source_commit:'9989805a329373af6c19dc5cde21e23205d87ea5',files:manifest,runtime,checks,preceding_run:35596622855,preceding_report_sha256:digest(oldBytes),preceding_observer_failure:'Surface has no active property; prior failure and all original evidence retained in prior/',supplement:'Only remaining resume gate rerun; actual keyboard movement required; no re-export',bootstrap_fixture:old.bootstrap_fixture,physical_iphone_verified:false,continuous_motion_or_fps_certified:false},null,2));
 await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;
