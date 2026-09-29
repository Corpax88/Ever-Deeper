import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output,flavor]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version=flavor==='live'?'1.0.2':'1.0.0-dev.15.22',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [name,want] of Object.entries(files)){
 const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))h.update(b);
 if(h.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost'),name=url.pathname==='/'?'/index.html':url.pathname,file=path.resolve(web,'.'+name);
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--',flavor==='live'?'--qa-production-browser':'--qa-skills-browser','--expected-version='+version];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:3,hasTouch:true});
const page=await context.newPage(),cdp=await context.newCDPSession(page);page.setDefaultTimeout(90000);
const checks=[],messages=[];let failed=null,runtime=null,id=0;
const save=()=>fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify(checks,null,2));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR: '+e.message));
const state=()=>page.evaluate(()=>window.DEV14_STATE),delay=ms=>new Promise(r=>setTimeout(r,ms));
async function wait(label,predicate,timeout=30000){
 const start=Date.now();let s;
 while(Date.now()-start<timeout){s=await state();if(s?.error||s?.native?.failed)throw Error(label+': '+JSON.stringify(s));if(predicate(s))return s;if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error(label+': runtime error');await delay(150);}
 throw Error(label+' timeout: '+JSON.stringify(s));
}
function check(name,ok,details){checks.push({name,passed:!!ok,...details});save();if(!ok)throw Error(name);}
async function command(kind,extra={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
async function point(name){const s=await state(),v=page.viewportSize(),r=s.buttons[name];if(!r)throw Error('Missing button '+name);return {x:(r[0]+r[2]/2)/s.viewport[0]*v.width,y:(r[1]+r[3]/2)/s.viewport[1]*v.height};}
async function tap(name){const p=await point(name);await page.touchscreen.tap(p.x,p.y);await delay(250);}
async function touch(type,p){await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:type==='touchEnd'?[]:[{id:7,...p,radiusX:5,radiusY:5,force:1}]});}
async function shot(name){await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});checks.push({name,passed:true,state:await state()});save();console.log('SKILLS_CAPTURE',name);}
function inside(r,s){return r[0]>=0&&r[1]>=0&&r[0]+r[2]<=s.viewport[0]+1&&r[1]+r[3]<=s.viewport[1]+1;}
function overlap(a,b){return a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1];}

async function ready(){return wait('active game',s=>!s?.menu&&s?.native?.active&&s.native.updates>3);}
async function resting(label,full=false){
 await command('menu_stamina_reset');const before=await state();
 await delay(1400);const after=await state();
 const expected=25*Math.max(0,after.stamina_rest-.4);
 check('recovery-rate-'+label,after.stamina>10&&after.stamina<70&&Math.abs(after.stamina-expected)<.01&&Math.abs((after.physics_frame-before.physics_frame)/60-(after.stamina_rest-before.stamina_rest))<.05,{before,after,expected});
 check('no-training-or-motion-'+label,['mining','running','carrying','prospecting'].every(k=>after.skill_xp[k]===before.skill_xp[k])&&after.position.every((p,i)=>Math.abs(p-before.position[i])<.01)&&after.impact===before.impact,{before,after});
 if(full){await wait('full stamina '+label,s=>s.stamina===100,10000);await delay(400);let end=await state();check('full-and-visible-'+label,end.stamina===100&&end.stamina_bar===100,{state:end});}
 await shot(label);
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('fixture ready',s=>s?.version===version&&s.buttons,180000);
 await command('menu_stamina_reset');await delay(900);check('no-start-screen-recovery',!(await state()).game_started&&(await state()).stamina===0,{});
 await tap('new_game');await ready();await command('surface');
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio};});
 check('graphical-renderer',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});
 await tap('hud_menu');await wait('Skills opened',s=>s.skills_open&&s.menu);await resting('skills',true);
 await tap('map');await wait('Map opened',s=>s.map_open);await resting('map');
 await tap('skills');await wait('Skills returned',s=>s.skills_open&&!s.map_open);await tap('inventory');await wait('Inventory opened',s=>s.inventory_open);await resting('inventory');await tap('inventory_close');await ready();
 await tap('hud_menu');await wait('Skills before settings',s=>s.skills_open);await tap('settings');await wait('Settings opened',s=>s.settings_open);await resting('settings');await tap('settings_back');await wait('Pause menu',s=>s.menu&&!s.settings_open);await resting('pause');await tap('continue');await ready();
 await tap('hud_mole');await wait('Mole menu opened',s=>s.mole_open);await resting('mole');await tap('mole_close');await ready();
 await command('menu_stamina_forge');await wait('Forge opened',s=>s.shop_open);await resting('forge');await tap('shop_close');await wait('Forge closed',s=>!s.shop_open);await ready();
 await resting('ordinary-idle');
 await command('moss',{direction:'right',gear:'worn'});await ready();
 await tap('hud_menu');await wait('Mine Skills opened',s=>s.skills_open);await resting('mine-skills',true);await tap('skills_close');await ready();
 const before=await state(),v=page.viewportSize(),p={x:before.mine_button[0]/before.viewport[0]*v.width,y:before.mine_button[1]/before.viewport[1]*v.height};
 await touch('touchStart',p);const hit=await wait('mining resumes',s=>s.impact>=before.impact+2&&s.stamina<before.stamina-1);await touch('touchEnd');await wait('release',s=>!s.mining);
 check('mining-spends-stamina-and-earns-xp',hit.skill_xp.mining>before.skill_xp.mining&&hit.impact_target_valid,{before,hit});await shot('mining-resumed');
 if(flavor==='live'){
  await command('checkpoint');await delay(800);const saved=await state();await page.reload({waitUntil:'domcontentloaded',timeout:180000});await wait('saved menu',s=>s?.version===version&&s.save_available&&s.menu,180000);
  check('save-compatible',!(await state()).dev_feature&&(await state()).skill_xp.mining===saved.skill_xp.mining,{});await tap('continue');await ready();
 }
 const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m));check('no-runtime-errors',errors.length===0,{errors});
}catch(e){failed=String(e.stack||e);console.error(failed);try{await shot('failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,flavor,files,runtime,checks,physical_iphone_verified:false},null,2));
 await context.close();await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;
