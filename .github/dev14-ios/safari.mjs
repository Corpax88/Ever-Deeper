// Focused ordinary New Game check in the actual Safari app, iPhone Simulator.
// The served HTML gets a read-only heartbeat; game package/config/save are unchanged.
import {createServer} from 'node:http';
import fs from 'node:fs';
import {resolve,extname} from 'node:path';
import {spawn,execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const [dir,outArg]=process.argv.slice(2),root=resolve(dir),out=resolve(outArg);fs.mkdirSync(out,{recursive:true});
const files=JSON.parse(fs.readFileSync(root+'/manifest.json'));
for(const [name,want] of Object.entries(files)){const hash=createHash('sha256');for await(const b of fs.createReadStream(root+'/'+name))hash.update(b);assert.equal(hash.digest('hex'),want.sha256);assert.equal(fs.statSync(root+'/'+name).size,want.size);}
const report={version:'1.0.0-dev.14.1',files,source_commit:process.env.CANDIDATE_SOURCE,physical_iphone:false,fixture_args:[],scope:'Safari app in iOS Simulator, XCTest native touches. HTML-only read-only heartbeat observes viewport/version/RAF. No game-state injection.',captures:[],taps:[],documents:[],heartbeats:[]};
let latest=null,driver,session,device,video,driverLog='';
const pause=ms=>new Promise(r=>setTimeout(r,ms));
const heartbeat=`<script>(()=>{const id=Date.now()+':'+Math.random();let frames=0;function tick(){frames++;requestAnimationFrame(tick)}requestAnimationFrame(tick);setInterval(()=>{const c=document.querySelector('canvas'),r=c?.getBoundingClientRect();fetch('/__heartbeat',{method:'POST',body:JSON.stringify({id,version:window.everDeeperVersion,frames,width:innerWidth,height:innerHeight,dpr:devicePixelRatio,canvas:r?{x:r.x,y:r.y,width:r.width,height:r.height}:null})}).catch(()=>{})},1000)})();</script>`;
const server=createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname;
 if(name==='/__heartbeat'){let b='';req.on('data',p=>b+=p);req.on('end',()=>{latest={...JSON.parse(b),at:Date.now()};report.heartbeats.push(latest);res.writeHead(204).end();});return;}
 const file=resolve(root,'.'+(name==='/'?'/index.html':name));
 if(!file.startsWith(root+'/')||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':{'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.png':'image/png'}[extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(extname(file)==='.html'){report.documents.push({url:req.url,at:Date.now()});res.end(fs.readFileSync(file,'utf8').replace('</body>',heartbeat+'</body>'));}else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'0.0.0.0',r));const origin='http://127.0.0.1:'+server.address().port;
async function wd(method,path,body,timeout=240000){const r=await fetch('http://127.0.0.1:4723'+path,{method,headers:{'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(timeout)});const d=await r.json();if(!r.ok||d.value?.error)throw Error(JSON.stringify(d));return d.value;}
const command=(method,path,body)=>wd(method,'/session/'+session+path,body,45000);
const mobile=(script,arg)=>command('POST','/execute/sync',{script:'mobile: '+script,args:[arg]});
async function capture(name){const png=await command('GET','/screenshot');fs.writeFileSync(out+'/'+name+'.png',Buffer.from(png,'base64'));fs.writeFileSync(out+'/'+name+'.xml',await command('GET','/source'));report.captures.push({name,at:Date.now()});console.log('SAFARI_CAPTURE '+name);}
async function ready(previousId=null){const until=Date.now()+180000;while(Date.now()<until){if(latest?.version===report.version&&latest.canvas?.height>0&&latest.id!==previousId&&Date.now()-latest.at<3000)return latest;await pause(500);}throw Error('Ordinary Safari game did not become ready');}
async function touch(kind){
 const views=await command('POST','/elements',{using:'-ios predicate string',value:'visible == 1 AND type == "XCUIElementTypeWebView"'});assert.ok(views.length,'Native Safari viewport');
 const box=await command('GET','/element/'+views[0]['element-6066-11e4-a52e-4f735466cecf']+'/rect');
 const c=latest.canvas,wide=c.width/c.height>=1.95,scale=wide?c.height/(720/1.1):Math.min(c.width/(1280/1.1),c.height/(720/1.1));
 const delta=kind==='confirm'?(wide?[155,108]:[122,88]):(wide?[263,-113]:[249,-108]);
 const point={x:Math.round(box.x+(c.x+c.width/2+delta[0]*scale)*box.width/latest.width),y:Math.round(box.y+(c.y+c.height/2+delta[1]*scale)*box.height/latest.height)};
 report.taps.push({kind,box,heartbeat:latest,point});await mobile('tap',point);
}
async function observe(stage,seconds){const id=latest.id,frames=latest.frames;await pause(seconds*1000);assert.equal(latest.id,id,'New Game must not restart Safari page');assert.ok(Date.now()-latest.at<4000,'Safari heartbeat remains responsive');assert.ok(latest.frames>frames+20,'Animation frames continue after New Game');await capture(stage);}
try{
 report.environment={xcode:execFileSync('xcodebuild',['-version'],{encoding:'utf8'}),node:process.version};
 const list=JSON.parse(execFileSync('xcrun',['simctl','list','devices','available','-j'],{encoding:'utf8'}));
 device=Object.entries(list.devices).filter(([r])=>r.endsWith('iOS-26-2')).flatMap(([runtime,ds])=>ds.filter(d=>d.isAvailable&&d.name.startsWith('iPhone')).map(d=>({...d,runtime})))[0];assert.ok(device,'Installed iPhone runtime');report.device={name:device.name,udid:device.udid,runtime:device.runtime};
 driver=spawn(process.execPath,[resolve('node_modules/appium/index.js'),'--address','127.0.0.1','--port','4723','--log',out+'/appium.log','--log-no-colors'],{detached:true});driver.stdout.on('data',b=>driverLog+=b);driver.stderr.on('data',b=>driverLog+=b);
 console.log('SAFARI_BOOT '+new Date().toISOString());
 if(device.state!=='Booted')execFileSync('xcrun',['simctl','boot',device.udid],{timeout:120000});execFileSync('xcrun',['simctl','bootstatus',device.udid,'-b'],{timeout:240000});execFileSync('open',['-a','Simulator','--args','-CurrentDeviceUDID',device.udid]);
 let available=false;for(const until=Date.now()+240000;Date.now()<until;){try{available=!!(await wd('GET','/status',undefined,5000)).ready;if(available)break;}catch{}await pause(750);}assert.ok(available,'Appium ready');
 console.log('SAFARI_SESSION '+new Date().toISOString());
 const created=await wd('POST','/session',{capabilities:{alwaysMatch:{platformName:'iOS','appium:automationName':'XCUITest','appium:bundleId':'com.apple.mobilesafari','appium:udid':device.udid,'appium:platformVersion':'26.2','appium:noReset':true,'appium:autoWebview':false,'appium:orientation':'LANDSCAPE','appium:waitForIdleTimeout':0,'appium:wdaLaunchTimeout':180000,'appium:showXcodeLog':true}}});session=created.sessionId;report.context=await command('GET','/context');assert.equal(report.context,'NATIVE_APP');
 await command('POST','/orientation',{orientation:'LANDSCAPE'});await mobile('deepLink',{url:origin,bundleId:'com.apple.mobilesafari'});await pause(2500);
 const tips=await command('POST','/elements',{using:'-ios predicate string',value:'visible == 1 AND type == "XCUIElementTypeButton" AND label == "Close" AND name != "CloseTabBarItemButton"'});if(tips.length)await command('POST','/element/'+tips[0]['element-6066-11e4-a52e-4f735466cecf']+'/click',{});
 video=spawn('xcrun',['simctl','io',device.udid,'recordVideo','--codec=h264',out+'/safari-new-game.mp4']);video.stderr.on('data',()=>{});
 console.log('SAFARI_GAME_LOADING '+new Date().toISOString());
 await ready();await pause(1000);await capture('01-ordinary-menu');await touch('new-game');await observe('02-new-game',15);
 const old=latest.id;await mobile('deepLink',{url:origin+'/?saved-run=1',bundleId:'com.apple.mobilesafari'});await ready(old);await pause(1000);await capture('03-saved-run-menu');
 await touch('new-game');await pause(800);await capture('04-replace-confirmation');await touch('confirm');await observe('05-confirmed-new-game',15);
 assert.equal(report.documents.length,2,'Only initial and requested reload');report.completed_observation=true;
}catch(e){report.failure=String(e.stack||e);process.exitCode=1;console.error(report.failure);if(session)await capture('failure').catch(()=>{});}
finally{if(video){video.kill('SIGINT');await Promise.race([new Promise(r=>video.once('exit',r)),pause(8000)]);}fs.writeFileSync(out+'/report.json',JSON.stringify(report,null,2));fs.writeFileSync(out+'/driver-stdout.log',driverLog);if(session)await command('DELETE','').catch(()=>{});if(driver?.pid)try{process.kill(-driver.pid,'SIGTERM');}catch{}server.closeAllConnections();await new Promise(r=>server.close(r));}
