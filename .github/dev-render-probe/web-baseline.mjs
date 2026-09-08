import {webkit} from '@playwright/test';
import http from 'node:http';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import path from 'node:path';
const [rootArg,outputArg,mode='menu']=process.argv.slice(2);
const root=path.resolve(rootArg),output=path.resolve(outputArg),logs=[],errors=[];
await mkdir(output,{recursive:true});
const minimal=`<!doctype html><canvas id="canvas" width="2532" height="1170" style="width:844px;height:390px"></canvas><script>
const canvas=document.querySelector('canvas'),gl=canvas.getContext('webgl2',{alpha:false,antialias:false,preserveDrawingBuffer:true});
const fbo=gl.createFramebuffer(),texture=gl.createTexture();
gl.bindTexture(gl.TEXTURE_2D,texture);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,2532,1170,0,gl.RGBA,gl.UNSIGNED_BYTE,null);
gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.NEAREST);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.NEAREST);
gl.bindFramebuffer(gl.FRAMEBUFFER,fbo);gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,texture,0);
window.control={frames:0,errors:[],pixel:[]};
function tick(){gl.bindFramebuffer(gl.FRAMEBUFFER,fbo);gl.clearColor(0,1,0,1);gl.clear(gl.COLOR_BUFFER_BIT);
gl.bindFramebuffer(gl.READ_FRAMEBUFFER,fbo);gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER,null);
gl.blitFramebuffer(0,0,2532,1170,0,0,2532,1170,gl.COLOR_BUFFER_BIT,gl.NEAREST);
const error=gl.getError();if(error)control.errors.push(error);control.frames++;requestAnimationFrame(tick);}
window.readControl=()=>{gl.bindFramebuffer(gl.READ_FRAMEBUFFER,null);const pixel=new Uint8Array(4);gl.readPixels(20,20,1,1,gl.RGBA,gl.UNSIGNED_BYTE,pixel);control.pixel=Array.from(pixel);return control;};
requestAnimationFrame(tick);</script>`;
const server=http.createServer(async(req,res)=>{
 try{
  const name=new URL(req.url,'http://localhost').pathname;
  const file=path.resolve(root,'.'+(name==='/'?'/index.html':name));
  if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
  let data=await readFile(file);
  if(file.endsWith('.html')){
   if(mode==='minimal')data=Buffer.from(minimal);
   else data=Buffer.from(data.toString().replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{
    const c=JSON.parse(raw);if(mode==='menu_adaptive')c.canvasResizePolicy=2;c.args=mode==='probe'?['--audio-driver','Dummy','--','--qa-mobile-performance','--perf-render-probe-review','--probe-area=hub']:['--audio-driver','Dummy'];
    return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';
   }));
  }
  res.writeHead(200,{'Content-Type':file.endsWith('.wasm')?'application/wasm':file.endsWith('.js')?'text/javascript':file.endsWith('.html')?'text/html':'application/octet-stream','Cross-Origin-Opener-Policy':'same-origin','Cross-Origin-Embedder-Policy':'require-corp'}).end(data);
 }catch{res.writeHead(404).end();}
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const browser=await webkit.launch({headless:true});
try{
 const page=await browser.newPage({viewport:{width:844,height:390},deviceScaleFactor:3,isMobile:true,hasTouch:true});
 page.on('pageerror',e=>errors.push(String(e)));
 page.on('console',m=>{logs.push({time:Date.now(),text:m.text()});if(/ERROR:|INVALID_OPERATION|INVALID_FRAMEBUFFER_OPERATION/.test(m.text()))errors.push(m.text());});
 await page.goto('http://127.0.0.1:'+server.address().port+'/');
 await page.waitForFunction(()=>!document.getElementById('status'),null,{timeout:120000});
 await page.waitForTimeout(20000);
 const state=await page.evaluate(()=>window.readControl?window.readControl():({canvas:[document.querySelector('canvas').width,document.querySelector('canvas').height],probe:window.everDeeperRenderProbe?.snapshot()}));
 await writeFile(path.join(output,'baseline.json'),JSON.stringify({mode,state,errors,logs},null,2));
 console.log('WEBGL_BASELINE '+JSON.stringify({mode,state,errors}));
 // An observation, not certification: every warning is retained for comparison.
}finally{await browser.close();server.close();}
