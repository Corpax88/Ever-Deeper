import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const source=fs.readFileSync(new URL('./fbo-candidate.js',import.meta.url),'utf8');
const C={FB:36160,READ:36008,DRAW:36009,TEX:3553,DS:33306,COLOR:36064,COMPLETE:36053};
let tests=0;
function environment() {
  class GL {
    constructor(){this.canvas={width:2328,height:1260,events:{},addEventListener(n,f){(this.events[n]??=[]).push(f);}};this.draw=null;this.read=null;this.rb=null;this.unit=0;this.units=[];this.lost=false;this.calls=0;this.gets=0;this.objects=[];}
    getParameter(p){this.gets++;return({35661:16,34016:33984+this.unit,36006:this.draw,36010:this.read,36007:this.rb})[p];}
    isContextLost(){return this.lost;}
    getExtension(name){return name==='ABSENT_extension'?null:{};}
    make(kind){const o={kind,owner:this,alive:true,target:0,images:new Map(),attachments:new Map()};this.objects.push(o);return o;}
    createFramebuffer(){return this.make('fbo');}createTexture(){return this.make('texture');}createRenderbuffer(){return this.make('rb');}
    bindFramebuffer(t,o){if(![C.FB,C.READ,C.DRAW].includes(t)||o&&(o.owner!==this||!o.alive||o.kind!=='fbo'))return;if(t!==C.READ)this.draw=o;if(t!==C.DRAW)this.read=o;}
    activeTexture(v){if(v>=33984&&v<34000)this.unit=v-33984;}
    bindTexture(t,o){if(![3553,34067,32879,35866].includes(t)||o&&(o.owner!==this||!o.alive||o.kind!=='texture'||o.target&&o.target!==t))return;if(o)o.target=t;(this.units[this.unit]??={})[t]=o;}
    bound(t){return this.units[this.unit]?.[t];}
    bindRenderbuffer(t,o){if(t===36161&&(!o||o.owner===this&&o.alive&&o.kind==='rb'))this.rb=o;}
    framebufferTexture2D(t,a,tt,o,l){const f=t===C.READ?this.read:this.draw;if(f){if(o)f.attachments.set(a,{o,l});else f.attachments.delete(a);}}
    framebufferTextureLayer(t,a,o,l){this.framebufferTexture2D(t,a,0,o,l);}
    framebufferRenderbuffer(t,a,tt,o){this.framebufferTexture2D(t,a,0,o,0);}
    texImage2D(t,l,format,w,h){const o=this.bound(t);if(o)o.images.set(l,{format,w,h});}
    texImage3D(t,l,format,w,h){this.texImage2D(t,l,format,w,h);}
    texStorage2D(t,l,format,w,h){this.texImage2D(t,0,format,w,h);}
    texStorage3D(t,l,format,w,h){this.texImage2D(t,0,format,w,h);}
    compressedTexImage2D(t,l,format,w,h){this.texImage2D(t,l,format,w,h);}
    compressedTexImage3D(t,l,format,w,h){this.texImage2D(t,l,format,w,h);}
    copyTexImage2D(t,l,format,x,y,w,h){this.texImage2D(t,l,format,w,h);}
    generateMipmap(){}texParameteri(){}texParameterf(){}drawBuffers(){}readBuffer(){}
    renderbufferStorage(t,format,w,h){if(this.rb)this.rb.images.set(0,{format,w,h});}
    renderbufferStorageMultisample(t,s,format,w,h){this.renderbufferStorage(t,format,w,h);}
    deleteTexture(o){if(o)o.alive=false;}deleteRenderbuffer(o){if(o)o.alive=false;}deleteFramebuffer(o){if(o){o.alive=false;if(this.draw===o)this.draw=null;if(this.read===o)this.read=null;}}
    truth(t=C.FB){if(this.lost)return 36061;if(![C.FB,C.READ,C.DRAW].includes(t))return 0;const f=t===C.READ?this.read:this.draw;if(!f)return C.COMPLETE;if(!f.alive||!f.attachments.size)return 36055;for(const {o,l} of f.attachments.values()){const im=o.images.get(l);if(!o.alive||!im||im.w<=0||im.h<=0)return 36054;}return C.COMPLETE;}
    checkFramebufferStatus(t){this.calls++;return this.truth(t);}
    event(name){for(const fn of this.canvas.events[name]??[])fn();}
    restore(){this.lost=false;for(const o of this.objects)o.alive=false;this.draw=null;this.read=null;this.rb=null;this.units=[];this.unit=0;this.event('webglcontextrestored');}
  }
  const sandbox={WebGL2RenderingContext:GL};vm.runInNewContext(source,sandbox);return{GL,api:sandbox.EVER_DEEPER_FBO};
}
function setup(e,gl=new e.GL()) {
  const f=gl.createFramebuffer(),t=gl.createTexture();gl.bindFramebuffer(C.FB,f);gl.bindTexture(C.TEX,t);gl.texImage2D(C.TEX,0,35056,400,400,0,34041,34042,null);gl.framebufferTexture2D(C.FB,C.DS,C.TEX,t,0);
  return{gl,f,t};
}
function correct(gl,target=C.FB){assert.equal(gl.checkFramebufferStatus(target),gl.truth(target));}
function warm(gl){correct(gl);const before=gl.calls;correct(gl);assert.equal(gl.calls,before,'unchanged eligible FBO should hit');}
function test(name,fn){fn();tests++;console.log('PASS',name);}

test('complete cache and actual disabled native reference',()=>{const e=environment(),{gl}=setup(e);warm(gl);assert.equal(e.api.snapshot().hits,1);e.api.setEnabled(false);const n=gl.calls;correct(gl);correct(gl);assert.equal(gl.calls,n+2);e.api.setEnabled(true);warm(gl);});
test('normal bindings and unrelated uploads do not invalidate',()=>{const e=environment(),{gl,f,t}=setup(e);warm(gl);const count=gl.calls,gets=gl.gets;gl.bindFramebuffer(C.FB,null);gl.bindFramebuffer(C.FB,f);gl.activeTexture(33985);const other=gl.createTexture();gl.bindTexture(C.TEX,other);gl.texImage2D(C.TEX,0,6408,16,16,0,6408,5121,null);gl.activeTexture(33984);gl.bindTexture(C.TEX,t);correct(gl);assert.equal(gl.calls,count);assert.equal(gl.gets,gets,'no continuous getParameter calls');});
test('storage change invalidates and native incomplete is never cached',()=>{const e=environment(),{gl}=setup(e);warm(gl);gl.texImage2D(C.TEX,0,35056,0,400,0,34041,34042,null);let n=gl.calls;correct(gl);correct(gl);assert.equal(gl.calls,n+2);gl.texImage2D(C.TEX,0,35056,400,400,0,34041,34042,null);warm(gl);});
for(const [name,mutate] of [
  ['texStorage2D',gl=>gl.texStorage2D(C.TEX,1,35056,400,400)],
  ['texImage3D',gl=>gl.texImage3D(C.TEX,0,35056,400,400,1,0,34041,34042,null)],
  ['texStorage3D',gl=>gl.texStorage3D(C.TEX,1,35056,400,400,1)],
  ['compressedTexImage2D',gl=>gl.compressedTexImage2D(C.TEX,0,35056,400,400,0,new Uint8Array())],
  ['compressedTexImage3D',gl=>gl.compressedTexImage3D(C.TEX,0,35056,400,400,1,0,new Uint8Array())],
  ['copyTexImage2D',gl=>gl.copyTexImage2D(C.TEX,0,35056,0,0,400,400,0)],
  ['generateMipmap',gl=>gl.generateMipmap(C.TEX)],
  ['base level',gl=>gl.texParameteri(C.TEX,33084,1)],
  ['max level',gl=>gl.texParameterf(C.TEX,33085,0)],
  ['drawBuffers',gl=>gl.drawBuffers([0])],['readBuffer',gl=>gl.readBuffer(0)],
])test(name+' invalidates prior native result',()=>{const e=environment(),{gl}=setup(e);warm(gl);const n=gl.calls;mutate(gl);correct(gl);assert.equal(gl.calls,n+1);});
test('attachment replacement, layer, color, detach and renderbuffer fallback',()=>{const e=environment(),{gl,t}=setup(e);warm(gl);const replacement=gl.createTexture();gl.bindTexture(C.TEX,replacement);gl.texImage2D(C.TEX,0,35056,400,400,0,34041,34042,null);let n=gl.calls;gl.framebufferTexture2D(C.FB,C.DS,C.TEX,replacement,0);correct(gl);assert.equal(gl.calls,n+1);warm(gl);gl.framebufferTextureLayer(C.FB,C.DS,replacement,0,0);n=gl.calls;correct(gl);correct(gl);assert.equal(gl.calls,n+2);gl.framebufferTexture2D(C.FB,C.DS,C.TEX,t,0);warm(gl);gl.framebufferTexture2D(C.FB,C.COLOR,C.TEX,replacement,0);n=gl.calls;correct(gl);correct(gl);assert.equal(gl.calls,n+2);gl.framebufferTexture2D(C.FB,C.COLOR,C.TEX,null,0);warm(gl);const rb=gl.createRenderbuffer();gl.bindRenderbuffer(36161,rb);gl.renderbufferStorage(36161,35056,400,400);gl.framebufferRenderbuffer(C.FB,C.DS,36161,rb);n=gl.calls;correct(gl);gl.renderbufferStorageMultisample(36161,4,35056,0,400);correct(gl);gl.deleteRenderbuffer(rb);correct(gl);assert.equal(gl.calls,n+3);});
test('texture and framebuffer deletion never return stale COMPLETE',()=>{const e=environment(),{gl,f,t}=setup(e);warm(gl);gl.deleteTexture(t);correct(gl);assert.notEqual(gl.truth(),C.COMPLETE);gl.deleteFramebuffer(f);correct(gl);assert.equal(gl.truth(),C.COMPLETE);});
test('resize requires a fresh native check',()=>{const e=environment(),{gl}=setup(e);warm(gl);let n=gl.calls;gl.canvas.width=1552;correct(gl);assert.equal(gl.calls,n+1);warm(gl);gl.canvas.height=840;n=gl.calls;correct(gl);assert.equal(gl.calls,n+1);});
test('context loss before event, restoration and new resources',()=>{const e=environment(),{gl}=setup(e);warm(gl);gl.lost=true;let n=gl.calls;correct(gl);assert.equal(gl.calls,n+1);assert.notEqual(gl.truth(),C.COMPLETE);gl.event('webglcontextlost');gl.restore();setup(e,gl);warm(gl);assert.ok(e.api.snapshot().contextRestoreResets);});
test('unknown supported extension fails closed permanently',()=>{const e=environment(),{gl,t}=setup(e);warm(gl);gl.getExtension('OVR_multiview2');const n=gl.calls;correct(gl);t.images.set(0,{format:35056,w:0,h:0});correct(gl);assert.equal(gl.calls,n+2);assert.match(e.api.snapshot().lastFallback,/unsupported extension/);});
test('known harmless and unavailable extensions keep cache',()=>{const e=environment(),{gl}=setup(e);warm(gl);const n=gl.calls;gl.getExtension('WEBGL_debug_renderer_info');gl.getExtension('ABSENT_extension');correct(gl);assert.equal(gl.calls,n);});
test('unobserved or foreign bindings fail safely to native',()=>{const e=environment(),{gl}=setup(e);warm(gl);const other=new e.GL(),foreign=other.createTexture();gl.bindTexture(C.TEX,foreign);const n=gl.calls;correct(gl);correct(gl);assert.equal(gl.calls,n+2);});
test('invalid active texture disables cache instead of following guessed state',()=>{const e=environment(),{gl}=setup(e);warm(gl);gl.activeTexture(999999);const n=gl.calls;correct(gl);correct(gl);assert.equal(gl.calls,n+2);});
test('READ and DRAW targets always call native, without cache reuse',()=>{const e=environment(),{gl}=setup(e);warm(gl);const n=gl.calls;correct(gl,C.READ);correct(gl,C.DRAW);assert.equal(gl.calls,n+2);});
test('nonmatching size and color-only framebuffers never cache',()=>{const e=environment(),{gl,t}=setup(e);gl.texImage2D(C.TEX,0,35056,200,200,0,34041,34042,null);let n=gl.calls;correct(gl);correct(gl);assert.equal(gl.calls,n+2);gl.framebufferTexture2D(C.FB,C.DS,C.TEX,null,0);gl.framebufferTexture2D(C.FB,C.COLOR,C.TEX,t,0);n=gl.calls;correct(gl);correct(gl);assert.equal(gl.calls,n+2);});
test('uninstall restores original native methods',()=>{const e=environment(),{gl}=setup(e);warm(gl);e.api.uninstall();const n=gl.calls;correct(gl);correct(gl);assert.equal(gl.calls,n+2);});
console.log(JSON.stringify({passed:true,tests,scope:'Semantic state/invalidation fixture, not real GPU/browser performance'}));
