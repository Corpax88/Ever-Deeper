import { chromium } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { createHash } from 'node:crypto';

const [web, output, chrome] = process.argv.slice(2);
fs.mkdirSync(output, {recursive:true});
const mime = {'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server = http.createServer((req,res)=>{
  const name = new URL(req.url,'http://localhost').pathname;
  const file = path.resolve(web,'.'+(name==='/'?'/index.html':name));
  if (!file.startsWith(path.resolve(web)+path.sep) || !fs.existsSync(file)) {res.writeHead(404).end();return;}
  res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
  fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser = await chromium.launch({headless:true, executablePath:chrome || undefined,
  args:process.platform==='darwin'?['--use-gl=angle','--use-angle=metal','--enable-gpu']:
    process.platform==='linux'?['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']:[]});
const context = await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2,hasTouch:true});
const page = await context.newPage();
const cdp=await context.newCDPSession(page);
await page.addInitScript(()=>Object.defineProperty(window,'EVER_DEEPER_TRIAL',{get:()=>window.EVER_DEEPER_TRIAL_JSON?JSON.parse(window.EVER_DEEPER_TRIAL_JSON):undefined}));
page.setDefaultTimeout(120000);
const messages=[],checks=[];
let runtime=null;
page.on('console', m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror', e=>{
  messages.push('PAGEERROR: '+e.message);
  fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));
  page.evaluate(message=>window.__TRIAL_ERROR=message,e.message).catch(()=>{});
});
const state = ()=>page.evaluate(()=>window.EVER_DEEPER_TRIAL);
// Software-rendered Godot can starve rAF-based observers while still updating
// its telemetry. Poll from Node, without overlapping screenshot requests.
async function waitState(label, predicate, timeout=180000){
  const started=Date.now();
  let current;
  while(Date.now()-started<timeout){
    current=await state();
    fs.appendFileSync(path.join(output,'telemetry.jsonl'),JSON.stringify({label,elapsed_ms:Date.now()-started,state:current})+'\n');
    if(current?.failed)throw new Error('Native pose rejected during '+label+': '+JSON.stringify(current.errors));
    if(predicate(current))return current;
    await new Promise(resolve=>setTimeout(resolve,1000));
  }
  throw new Error(label+' timed out: '+JSON.stringify(current));
}
async function screenshot(name){
  const started=Date.now();
  const image=await cdp.send('Page.captureScreenshot',{format:'png',fromSurface:true,captureBeyondViewport:false});
  const png=Buffer.from(image.data,'base64');
  fs.writeFileSync(path.join(output,name+'.png'),png);
  return {duration_ms:Date.now()-started,size:[png.readUInt32BE(16),png.readUInt32BE(20)]};
}
async function capture(name){
  const stateBefore=await state();
  const screenshot_info=await screenshot(name);
  const s=await state();
  checks.push({name,state:s,state_before_capture:stateBefore,screenshot_info});
  console.log(name,JSON.stringify(s));
  if(s?.failed)throw new Error('Native pose rejected');
}
async function stationary(label){
  const released=await state();
  const settled=await waitState(label+'-settle',s=>s.frames>=released.frames+5);
  const later=await waitState(label+'-stable',s=>s.frames>=settled.frames+10);
  if(Math.hypot(later.position[0]-settled.position[0],later.position[1]-settled.position[1])>0.1 || later.mining || later.impact_serial!==settled.impact_serial)
    throw new Error(label+' did not stop movement/mining');
  return {settled,later};
}
try {
  await page.goto('http://127.0.0.1:'+server.address().port,{timeout:120000,waitUntil:'domcontentloaded'});
  await waitState('startup',s=>s?.ready,240000);
  runtime=await page.evaluate(()=>{
    const canvas=document.querySelector('canvas'),gl=canvas?.getContext('webgl2');
    const ext=gl?.getExtension('WEBGL_debug_renderer_info');
    return {viewport:[innerWidth,innerHeight],dpr:devicePixelRatio,
      webgl:gl?{version:gl.getParameter(gl.VERSION),renderer:gl.getParameter(gl.RENDERER),
        unmaskedRenderer:ext?gl.getParameter(ext.UNMASKED_RENDERER_WEBGL):null,
        drawingBuffer:[gl.drawingBufferWidth,gl.drawingBufferHeight],lost:gl.isContextLost()}:null};
  });
  runtime={...runtime,browser:browser.version(),os:process.platform,arch:process.arch,headless:true};
  fs.writeFileSync(path.join(output,'runtime.json'),JSON.stringify(runtime,null,2));
  console.log('TRIAL_RENDERER',JSON.stringify(runtime));
  if(!runtime.webgl || runtime.webgl.lost)throw new Error('Missing live WebGL2 renderer');
  if(process.platform==='darwin' && /SwiftShader|llvmpipe|software/i.test(runtime.webgl.unmaskedRenderer||''))
    throw new Error('Mac QA did not obtain its required hardware renderer');
  const startupError=await page.evaluate(()=>window.__TRIAL_ERROR);
  if(startupError)throw new Error(startupError);
  await capture('01-ready');
  let before=await state();
  if(before.save_path!=="user://native-flow-trial/isolated-save.json")throw new Error('Trial save is not isolated');
  await page.keyboard.down('Space');
  await waitState('held-mining',s=>s.hp17<before.hp17-20);
  await capture('02-held-mining');
  await page.keyboard.up('Space');
  await waitState('keyboard-release',s=>!s.mining);
  before=await state();
  await page.keyboard.down('ArrowLeft');
  await waitState('keyboard-walk',s=>s.position[0]<before.position[0]-12);
  await page.keyboard.up('ArrowLeft');
  const keyboardRelease=await stationary('keyboard-movement-release');
  await capture('03-walk-exit');
  // Reset is a real canvas button; map its logical position to CSS pixels.
  before=await state();
  await page.mouse.click(before.reset_button[0]/before.viewport[0]*844,before.reset_button[1]/before.viewport[1]*390);
  await waitState('reset',s=>s.resets===1 && s.hp17===500 && s.hp18===500 && !s.mining && s.position[0]===1696 && s.position[1]===1648);
  await capture('04-reset');
  before=await state();
  const css=p=>({x:p[0]/before.viewport[0]*844,y:p[1]/before.viewport[1]*390});
  let button=css(before.mine_button);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{...button,id:1}]});
  await waitState('touch-mining',s=>s.hp17<before.hp17);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await waitState('touch-release',s=>!s.mining);
  await capture('05-touch-mining');
  // The pad Control spans the viewport; its center lies outside its active
  // movement zone (x<=46%, y>=36%). Start in the actual floating-joystick zone.
  const center=css([before.viewport[0]*.22,before.viewport[1]*.72]);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{...center,id:2}]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:center.x+34,y:center.y,id:2}]});
  await waitState('touch-walk',s=>s.position[0]>before.position[0]+12);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  const touchRelease=await stationary('touch-movement-release');
  await capture('06-touch-walk');
  // Godot emits this retained editor-UID warning through console.error. The
  // exact fallback script is valid and exercised above; keep both lines as
  // disclosed diagnostics. Every other console error still fails the gate.
  const uidWarning="error: WARNING: 'res://scripts/dev/native_trial/entry.tscn': In external resource #0, invalid UID: 'uid://dq7f6jx1rkmto' - using text path instead: 'res://scripts/dev/native_trial/capture_motion.gd'.";
  const uidStack='error:    at: open (core/io/resource_format_binary.cpp:1028)';
  const knownWarnings=[];
  const errors=messages.filter((m,i)=>{
    if(m===uidWarning || (m===uidStack && messages[i-1]===uidWarning)){knownWarnings.push(m);return false;}
    return /SCRIPT ERROR|Parse Error|PAGEERROR:|Assertion failed|^error: (?!Failed to load resource.*favicon)/.test(m);
  });
  if(errors.length)throw new Error(errors.join('\n'));
  const files=Object.fromEntries(fs.readdirSync(web).filter(n=>n.startsWith('index.')).map(n=>{const bytes=fs.readFileSync(path.join(web,n));return [n,{size:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')}];}));
  fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:true,browser:browser.version(),os:process.platform,viewport:[844,390],dpr:2,runtime,known_warnings:knownWarnings,pck_sha256:files['index.pck'].sha256,files,checks,movement_release:{keyboard:keyboardRelease,touch:touchRelease},capture_method:'CDP Page.captureScreenshot; state before and after, not frame-synchronized',physical_device:false},null,2));
} catch(e) {
  fs.writeFileSync(path.join(output,'failure.json'),JSON.stringify({error:String(e),state:await state().catch(()=>null),runtime,checks,messages},null,2));
  await screenshot('failure').catch(()=>{});
  throw e;
} finally {await browser.close();server.close();}
