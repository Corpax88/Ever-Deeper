import {webkit} from '@playwright/test';
import http from 'node:http';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import path from 'node:path';
const [rootArg,outputArg,mode='probe']=process.argv.slice(2);
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
  if(file.endsWith('/index.js'))data=Buffer.from(data.toString().replace('context.defaultFboForbidBlitFramebuffer=false','context.defaultFboForbidBlitFramebuffer=true'));
  if(file.endsWith('.html')){
   if(mode==='minimal')data=Buffer.from(minimal);
   else data=Buffer.from(data.toString().replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{
    const c=JSON.parse(raw);c.args=mode==='probe'?['--audio-driver','Dummy','--','--qa-mobile-performance','--perf-render-probe-review','--probe-area=hub']:['--audio-driver','Dummy'];
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
 await page.addInitScript(()=>{
  const proto=WebGL2RenderingContext.prototype, dims=new WeakMap(), ids=new WeakMap();let next=1;
  const id=o=>{if(!o)return null;if(!ids.has(o))ids.set(o,next++);return ids.get(o);};
  for(const name of ['texImage2D','renderbufferStorage','renderbufferStorageMultisample']){
   const original=proto[name];proto[name]=function(...a){
    const out=original.apply(this,a);
    if(name==='texImage2D' && a[0]===this.TEXTURE_2D && a.length>=9){const o=this.getParameter(this.TEXTURE_BINDING_2D);if(o)dims.set(o,[a[3],a[4]]);}
    if(name==='renderbufferStorage'){const o=this.getParameter(this.RENDERBUFFER_BINDING);if(o)dims.set(o,[a[2],a[3]]);}
    if(name==='renderbufferStorageMultisample'){const o=this.getParameter(this.RENDERBUFFER_BINDING);if(o)dims.set(o,[a[3],a[4]]);}
    return out;
   };
  }
  const original=proto.drawArrays;
  proto.drawArrays=function(...a){
   if(window.__traceResize && !window.__resizeBad){
    const status=this.checkFramebufferStatus(this.DRAW_FRAMEBUFFER);
    if(status!==this.FRAMEBUFFER_COMPLETE){
     const attachments={};
     for(const key of ['COLOR_ATTACHMENT0','DEPTH_ATTACHMENT','STENCIL_ATTACHMENT']){
      const type=this.getFramebufferAttachmentParameter(this.DRAW_FRAMEBUFFER,this[key],this.FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE);
      const o=type!==this.NONE?this.getFramebufferAttachmentParameter(this.DRAW_FRAMEBUFFER,this[key],this.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME):null;
      attachments[key]={type,id:id(o),size:o?dims.get(o):null};
     }
     const context=this.canvas.GLctxObject;
     window.__resizeBad={status,draw:id(this.getParameter(this.DRAW_FRAMEBUFFER_BINDING)),attachments,
      buffer:[this.drawingBufferWidth,this.drawingBufferHeight],canvas:[this.canvas.width,this.canvas.height],
      emscripten:{fbo:id(context.defaultFbo),color:id(context.defaultColorTarget),colorSize:dims.get(context.defaultColorTarget),depth:id(context.defaultDepthTarget),depthSize:dims.get(context.defaultDepthTarget)},stack:new Error().stack};
     console.log('RESIZE_BAD '+JSON.stringify(window.__resizeBad));
    }
   }
   return original.apply(this,a);
  };
 });
 await page.goto('http://127.0.0.1:'+server.address().port+'/');
 await page.waitForFunction(()=>!document.getElementById('status'),null,{timeout:120000});
 await page.waitForFunction(()=>window.everDeeperRenderProbe?.snapshot().active);
 await page.waitForTimeout(2000);
 await page.evaluate(()=>{window.__traceResize=true;window.everDeeperRenderProbe.stage(0.5);});
 await page.waitForTimeout(4000);
 const state=await page.evaluate(()=>window.__resizeBad?window.__resizeBad:({canvas:[document.querySelector('canvas').width,document.querySelector('canvas').height],probe:window.everDeeperRenderProbe?.snapshot()}));
 await writeFile(path.join(output,'baseline.json'),JSON.stringify({mode,state,errors,logs},null,2));
 console.log('WEBGL_BASELINE '+JSON.stringify({mode,state,errors}));
 // An observation, not certification: every warning is retained for comparison.
}finally{await browser.close();server.close();}
