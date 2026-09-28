/* Diagnostic only. Preserve EVERY native GL call and result; never cache status.
 * Add as init script before engine startup. Use begin/end only for inventories;
 * call uninstall before uninstrumented FPS windows. Wall time is not GPU time.
 * Tracks attempted WebGL2 calls without adding getParameter/getError/readback.
 * State observed after late injection is explicitly incomplete.
 */
(() => {
  const proto = globalThis.WebGL2RenderingContext?.prototype;
  if (!proto || globalThis.FBO_AUDIT) return;
  const originals = new Map(), wrappers = new Map(), contexts = new WeakMap();
  const ids = new WeakMap(); let nextId = 1, installed = false, enabled = false, timed = false;
  let label = '', groups = new Map(), counters = {}, droppedGroups = 0;
  const id = value => { if (!value) return 0; if (!ids.has(value)) ids.set(value, nextId++); return ids.get(value); };
  const count = name => { if (enabled) counters[name] = (counters[name] || 0) + 1; };
  const valueKey = value => JSON.stringify(value);
  function context(gl) {
    if (!contexts.has(gl)) {
      const c = { id:id(gl), gl, read:undefined, draw:undefined, rb:null, unit:33984,
        textures:new Map(), fbos:new WeakMap(), resources:new WeakMap(), epoch:0, extensions:new Set(), previous:new Map() };
      contexts.set(gl,c);
      gl.canvas?.addEventListener('webglcontextlost', () => { c.epoch++; c.previous.clear(); count('contextlost'); });
      gl.canvas?.addEventListener('webglcontextrestored', () => { c.epoch++; c.previous.clear(); c.read=undefined; c.draw=undefined; count('contextrestored'); });
    }
    return contexts.get(gl);
  }
  function resource(c,obj,created=false) {
    if (!obj) return null;
    if (!c.resources.has(obj)) c.resources.set(obj,{id:id(obj),version:0,created_observed:created,images:{},params:{},last:'unknown'});
    return c.resources.get(obj);
  }
  function fbo(c,obj,created=false) {
    if (!obj) return null;
    if (!c.fbos.has(obj)) c.fbos.set(obj,{id:id(obj),created_observed:created,version:0,attachments:{},read:undefined,draw:undefined,last:'unknown'});
    return c.fbos.get(obj);
  }
  const boundFbo = (c,target) => target===36008 ? c.read : c.draw;
  const normalizedTarget = target => target>=34069 && target<=34074 ? 34067 : target;
  const boundTexture = (c,target) => c.textures.get(c.unit+':'+normalizedTarget(target));
  function mutateResource(c,obj,name,detail) {
    const r=resource(c,obj); if (!r) return;
    r.version++; r.last=name;
    if (detail) r.images[detail.level??0]=detail;
  }
  function attach(c,target,attachment,descriptor,obj,name) {
    const fb=fbo(c,boundFbo(c,target)); if (!fb) return;
    const old=fb.attachments[attachment];
    if (old && old.obj===obj && valueKey(old.descriptor)===valueKey(descriptor)) { count('identical_reattachment'); return; }
    fb.attachments[attachment]={obj,descriptor}; fb.version++; fb.last=name;
  }
  function summary(c,fb) {
    if (!fb) return null;
    return {id:fb.id,created_observed:fb.created_observed,version:fb.version,last:fb.last,read:fb.read,draw:fb.draw,
      attachments:Object.fromEntries(Object.entries(fb.attachments).map(([k,a])=>[k,{...a.descriptor,resource:resource(c,a.obj)}]))};
  }
  function install() {
    if (installed) return;
    installed=true;
    const hook=(name,after) => {
      const native=proto[name]; if (typeof native!=='function') return;
      originals.set(name,native);
      const wrapper=function(...args) {
        const c=context(this);
        const start=enabled && timed && name==='checkFramebufferStatus' ? performance.now() : 0;
        const result=Reflect.apply(native,this,args);
        const elapsed=start ? performance.now()-start : null;
        count(name); after(c,args,result,elapsed); return result;
      };
      wrappers.set(name,wrapper); proto[name]=wrapper;
    };
    hook('createFramebuffer',(c,a,result)=>fbo(c,result,true));
    hook('createTexture',(c,a,result)=>resource(c,result,true));
    hook('createRenderbuffer',(c,a,result)=>resource(c,result,true));
    hook('bindFramebuffer',(c,a)=>{if(a[0]===36160 || a[0]===36008)c.read=a[1];if(a[0]===36160 || a[0]===36009)c.draw=a[1];});
    hook('bindRenderbuffer',(c,a)=>{c.rb=a[1];});
    hook('activeTexture',(c,a)=>{c.unit=a[0];});
    hook('bindTexture',(c,a)=>{c.textures.set(c.unit+':'+normalizedTarget(a[0]),a[1]);});
    hook('framebufferTexture2D',(c,a)=>attach(c,a[0],a[1],{kind:'texture2D',target:a[2],level:a[4]},a[3],'framebufferTexture2D'));
    hook('framebufferTextureLayer',(c,a)=>attach(c,a[0],a[1],{kind:'textureLayer',level:a[3],layer:a[4]},a[2],'framebufferTextureLayer'));
    hook('framebufferRenderbuffer',(c,a)=>attach(c,a[0],a[1],{kind:'renderbuffer',target:a[2]},a[3],'framebufferRenderbuffer'));
    hook('texImage2D',(c,a)=>mutateResource(c,boundTexture(c,a[0]),'texImage2D',a.length>=9?{target:a[0],level:a[1],format:a[2],width:a[3],height:a[4]}:{target:a[0],level:a[1],format:a[2],width:a[5]?.width,height:a[5]?.height}));
    hook('texImage3D',(c,a)=>mutateResource(c,boundTexture(c,a[0]),'texImage3D',{target:a[0],level:a[1],format:a[2],width:a[3],height:a[4],depth:a[5]}));
    hook('texStorage2D',(c,a)=>mutateResource(c,boundTexture(c,a[0]),'texStorage2D',{target:a[0],levels:a[1],format:a[2],width:a[3],height:a[4]}));
    hook('texStorage3D',(c,a)=>mutateResource(c,boundTexture(c,a[0]),'texStorage3D',{target:a[0],levels:a[1],format:a[2],width:a[3],height:a[4],depth:a[5]}));
    for(const name of ['compressedTexImage2D','compressedTexImage3D','copyTexImage2D','generateMipmap'])hook(name,(c,a)=>mutateResource(c,boundTexture(c,a[0]),name));
    for(const name of ['texParameteri','texParameterf'])hook(name,(c,a)=>{const r=resource(c,boundTexture(c,a[0]));if(r && r.params[a[1]]!==a[2]){r.params[a[1]]=a[2];r.version++;r.last=name;}});
    hook('renderbufferStorage',(c,a)=>mutateResource(c,c.rb,'renderbufferStorage',{format:a[1],width:a[2],height:a[3],samples:0}));
    hook('renderbufferStorageMultisample',(c,a)=>mutateResource(c,c.rb,'renderbufferStorageMultisample',{samples:a[1],format:a[2],width:a[3],height:a[4]}));
    for(const name of ['deleteTexture','deleteRenderbuffer'])hook(name,(c,a)=>mutateResource(c,a[0],name));
    hook('deleteFramebuffer',(c,a)=>{const fb=fbo(c,a[0]);if(fb){fb.version++;fb.last='deleteFramebuffer';}if(c.read===a[0])c.read=null;if(c.draw===a[0])c.draw=null;});
    hook('readBuffer',(c,a)=>{const fb=fbo(c,c.read);if(fb && fb.read!==a[0]){fb.read=a[0];fb.version++;fb.last='readBuffer';}});
    hook('drawBuffers',(c,a)=>{const fb=fbo(c,c.draw),list=Array.from(a[0]);if(fb && valueKey(fb.draw)!==valueKey(list)){fb.draw=list;fb.version++;fb.last='drawBuffers';}});
    hook('getExtension',(c,a,result)=>{if(result)c.extensions.add(a[0]);});
    hook('checkFramebufferStatus',(c,a,result,elapsed)=>{
      if(!enabled)return;
      const obj=boundFbo(c,a[0]),fb=fbo(c,obj),snapshot=summary(c,fb);
      const signature=valueKey({target:a[0],fbo:snapshot,epoch:c.epoch,width:c.gl.canvas?.width,height:c.gl.canvas?.height});
      const previousKey=c.id+':'+a[0]+':'+id(obj);
      const unchanged=c.previous.get(previousKey)===signature;c.previous.set(previousKey,signature);
      const key=c.id+':'+a[0]+':'+id(obj)+':'+result;
      let row=groups.get(key);
      if(!row){if(groups.size>=128){droppedGroups++;return;}row={context:c.id,target:a[0],fbo:obj===undefined?'unobserved_binding':id(obj),status:result,calls:0,unchanged_since_previous_check:0,changed_since_previous_check:0,native_wall_ms:0,max_native_wall_ms:0,first:snapshot,last:snapshot,dimensions:[c.gl.canvas?.width,c.gl.canvas?.height],first_stack:new Error().stack?.split('\n').slice(0,12),extensions:[...c.extensions]};groups.set(key,row);}
      row.calls++;row[unchanged?'unchanged_since_previous_check':'changed_since_previous_check']++;
      if(elapsed!==null){row.native_wall_ms+=elapsed;row.max_native_wall_ms=Math.max(row.max_native_wall_ms,elapsed);}
      // Clone at record time: later attachment/storage updates must not change historical evidence.
      row.last=JSON.parse(valueKey(snapshot));if(row.calls===1)row.first=row.last;
    });
  }
  function uninstall(){enabled=false;for(const [name,native] of originals)if(proto[name]===wrappers.get(name))proto[name]=native;installed=false;}
  globalThis.FBO_AUDIT={install,uninstall,
    begin(name,withWallTiming=false){label=name;groups=new Map();counters={};droppedGroups=0;timed=withWallTiming;enabled=true;},
    end(){enabled=false;return {label,wall_timing:timed,note:'Attempted-call trace; every original GL call/result retained. Native wall time is not GPU time. Unknown initial state and extension attachment APIs prohibit caching from this trace alone.',counters,dropped_groups:droppedGroups,groups:[...groups.values()]};}
  };
  install();
})();
