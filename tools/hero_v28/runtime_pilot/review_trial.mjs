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
const browser = await chromium.launch({headless:true, executablePath:chrome,
  args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const context = await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2,hasTouch:true});
const page = await context.newPage();
await page.addInitScript(()=>Object.defineProperty(window,'EVER_DEEPER_TRIAL',{get:()=>window.EVER_DEEPER_TRIAL_JSON?JSON.parse(window.EVER_DEEPER_TRIAL_JSON):undefined}));
page.setDefaultTimeout(120000);
const messages=[],checks=[];
const timer=setInterval(()=>page.screenshot({path:path.join(output,'latest.png')}).catch(()=>{}),20000);
page.on('console', m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror', e=>{
  messages.push('PAGEERROR: '+e.message);
  fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));
  page.evaluate(message=>window.__TRIAL_ERROR=message,e.message).catch(()=>{});
});
const state = ()=>page.evaluate(()=>window.EVER_DEEPER_TRIAL);
async function capture(name){await page.screenshot({path:path.join(output,name+'.png')});const s=await state();checks.push({name,state:s});console.log(name,JSON.stringify(s));if(s?.failed)throw new Error('Native pose rejected');}
try {
  await page.goto('http://127.0.0.1:'+server.address().port,{timeout:120000,waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>window.EVER_DEEPER_TRIAL?.ready || window.__TRIAL_ERROR,{},{timeout:240000});
  const startupError=await page.evaluate(()=>window.__TRIAL_ERROR);
  if(startupError)throw new Error(startupError);
  await capture('01-ready');
  let before=await state();
  if(before.save_path!=="user://native-flow-trial/isolated-save.json")throw new Error('Trial save is not isolated');
  await page.keyboard.down('Space');
  await page.waitForFunction(h=>window.EVER_DEEPER_TRIAL?.failed || window.EVER_DEEPER_TRIAL?.hp17<h-20,before.hp17);
  await capture('02-held-mining');
  await page.keyboard.up('Space');
  await page.waitForFunction(()=>!window.EVER_DEEPER_TRIAL.mining);
  before=await state();
  await page.keyboard.down('ArrowLeft');
  await page.waitForFunction(x=>window.EVER_DEEPER_TRIAL.position[0]<x-12,before.position[0]);
  await page.keyboard.up('ArrowLeft');
  await capture('03-walk-exit');
  // Reset is a real canvas button; map its logical position to CSS pixels.
  before=await state();
  await page.mouse.click(before.reset_button[0]/before.viewport[0]*844,before.reset_button[1]/before.viewport[1]*390);
  await page.waitForFunction(()=>window.EVER_DEEPER_TRIAL.resets===1);
  await capture('04-reset');
  before=await state();
  const cdp=await context.newCDPSession(page);
  const css=p=>({x:p[0]/before.viewport[0]*844,y:p[1]/before.viewport[1]*390});
  let button=css(before.mine_button);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{...button,id:1}]});
  await page.waitForFunction(h=>window.EVER_DEEPER_TRIAL.failed || window.EVER_DEEPER_TRIAL.hp17<h,before.hp17);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await page.waitForFunction(()=>!window.EVER_DEEPER_TRIAL.mining);
  await capture('05-touch-mining');
  const center=css(before.pad);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{...center,id:2}]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:center.x+34,y:center.y,id:2}]});
  await page.waitForFunction(x=>window.EVER_DEEPER_TRIAL.position[0]>x+12,before.position[0]);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await capture('06-touch-walk');
  const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR:|Assertion failed|^error: (?!Failed to load resource.*favicon)/.test(m));
  if(errors.length)throw new Error(errors.join('\n'));
  const files=Object.fromEntries(fs.readdirSync(web).filter(n=>n.startsWith('index.')).map(n=>{const bytes=fs.readFileSync(path.join(web,n));return [n,{size:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')}];}));
  fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:true,browser:browser.version(),viewport:[844,390],dpr:2,pck_sha256:files['index.pck'].sha256,files,checks,physical_device:false},null,2));
} catch(e) {
  await page.screenshot({path:path.join(output,'failure.png')}).catch(()=>{});
  fs.writeFileSync(path.join(output,'failure.json'),JSON.stringify({error:String(e),state:await state().catch(()=>null),checks,messages},null,2));
  throw e;
} finally {clearInterval(timer);await browser.close();server.close();}
