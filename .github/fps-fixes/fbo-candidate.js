/* Ever-Deeper FBO validation cache v1.
 * Load before index.js. Only caches a native COMPLETE result for the observed
 * 400x400, level-zero, depth-stencil-only WebGL2 framebuffer configuration.
 * Every GL mutation still reaches the browser. Unknown state fails to native.
 */
(() => {
  'use strict';
  if (globalThis.EVER_DEEPER_FBO) return;
  const P = globalThis.WebGL2RenderingContext?.prototype;
  const G = { FB:36160, READ:36008, DRAW:36009, COMPLETE:36053, DS:33306,
    T2:3553, CUBE:34067, T3:32879, ARRAY:35866, TEXTURE0:33984, RB:36161 };
  const contexts = new WeakMap(), originals = new Map(), installed = [];
  let enabled = globalThis.EVER_DEEPER_FBO_START_ENABLED !== false, toggleEpoch = 0;
  let totals = {}, lastFallback = '', supported = !!P;
  const inc = key => { totals[key]=(totals[key]||0)+1; };
  const safeExtensions = new Set([
    'WEBGL_multi_draw','EXT_polygon_offset_clamp','EXT_clip_control','WEBGL_polygon_mode',
    'EXT_color_buffer_float','EXT_color_buffer_half_float','EXT_conservative_depth','EXT_depth_clamp',
    'EXT_float_blend','EXT_texture_compression_bptc','EXT_texture_compression_rgtc',
    'EXT_texture_filter_anisotropic','MOZ_EXT_texture_filter_anisotropic','WEBKIT_EXT_texture_filter_anisotropic',
    'EXT_texture_norm16','KHR_parallel_shader_compile','NV_shader_noperspective_interpolation',
    'OES_texture_float_linear','WEBGL_blend_func_extended','WEBGL_clip_cull_distance',
    'WEBGL_compressed_texture_astc','WEBGL_compressed_texture_etc','WEBGL_compressed_texture_etc1',
    'WEBGL_compressed_texture_s3tc','WEBGL_compressed_texture_s3tc_srgb','WEBGL_compressed_texture_pvrtc',
    'WEBKIT_WEBGL_compressed_texture_pvrtc','WEBGL_debug_renderer_info','EXT_disjoint_timer_query_webgl2',
    'WEBGL_lose_context','WEBGL_debug_shaders','EXT_texture_mirror_clamp_to_edge',
    'WEBGL_render_shared_exponent','WEBGL_render_snorm','EXT_render_snorm','EXT_texture_compression_astc_hdr',
  ]);
  function unsafe(c,reason) { c.unsafe=reason; lastFallback=reason; inc('unsafeEvents'); }
  const native = (name,gl,args) => Reflect.apply(originals.get(name),gl,args);
  function initializeBindings(c,gl) {
    try {
      c.maxUnits=native('getParameter',gl,[35661]);
      c.unit=native('getParameter',gl,[34016])-G.TEXTURE0;
      c.draw=native('getParameter',gl,[36006]);
      c.read=native('getParameter',gl,[36010]);
      c.rb=native('getParameter',gl,[36007]);
      if(!Number.isInteger(c.maxUnits)||c.maxUnits<1||!Number.isInteger(c.unit)||c.unit<0||c.unit>=c.maxUnits)unsafe(c,'unknown initial bindings');
    } catch { unsafe(c,'initial binding query failed'); }
  }
  function reset(c,gl,reason) {
    c.fbos=new WeakMap();c.resources=new WeakMap();c.bindings=[];c.epoch++;
    c.unsafe=c.unsupportedExtension||'';c.draw=undefined;c.read=undefined;c.rb=undefined;
    c.width=gl.canvas?.width;c.height=gl.canvas?.height;
    inc(reason);
  }
  function state(gl) {
    let c=contexts.get(gl);if(c)return c;
    c={fbos:new WeakMap(),resources:new WeakMap(),bindings:[],epoch:0,unsafe:'',unsupportedExtension:'',wasLost:false,
      unit:0,maxUnits:0,width:gl.canvas?.width,height:gl.canvas?.height};
    contexts.set(gl,c);inc('contexts');initializeBindings(c,gl);
    gl.canvas?.addEventListener('webglcontextlost',()=>{c.wasLost=true;reset(c,gl,'contextLossResets');});
    gl.canvas?.addEventListener('webglcontextrestored',()=>{reset(c,gl,'contextRestoreResets');c.wasLost=false;initializeBindings(c,gl);});
    return c;
  }
  function fb(c,target) { return c.fbos.get(target===G.READ?c.read:c.draw); }
  const fbTarget = target => target===G.FB||target===G.READ||target===G.DRAW;
  function slot(target,image=false) {
    if(target===G.T2)return 0;if(target===G.CUBE||(image&&target>=34069&&target<=34074))return 1;
    if(target===G.T3)return 2;if(target===G.ARRAY)return 3;return -1;
  }
  function boundResource(c,target,image=false) {
    const index=slot(target,image),obj=index<0?undefined:c.bindings[c.unit]?.[index];
    const r=obj?c.resources.get(obj):null;
    if(index<0||obj===undefined||(obj&&!r)){unsafe(c,'unobserved texture binding');return null;}
    return r;
  }
  function dirty(r) { if(r){r.version++;inc('resourceInvalidations');} }
  function touchFbo(c,target) {
    if(!fbTarget(target)){unsafe(c,'unknown framebuffer target');return null;}
    const object=target===G.READ?c.read:c.draw;
    if(object===null)return null;
    const f=object?c.fbos.get(object):null;
    if(!f){unsafe(c,'unobserved framebuffer binding');return null;}
    f.version++;f.cached=false;inc('framebufferInvalidations');return f;
  }
  function candidate(c,f) {
    if(!f||!f.alive||f.attachments.size!==1)return null;
    const a=f.attachments.get(G.DS);
    if(!a||a.kind!=='texture2D'||a.target!==G.T2||a.level!==0)return null;
    const r=c.resources.get(a.object),im=r?.images.get(0);
    if(!r?.alive||r.kind!=='texture'||r.target!==G.T2||!im||im.width!==400||im.height!==400)return null;
    if(im.format!==34041&&im.format!==35056)return null;
    return r;
  }
  function hook(name,after) {
    const original=P[name];if(typeof original!=='function'){supported=false;return;}
    if(!originals.has(name))originals.set(name,original);
    const own=Object.getOwnPropertyDescriptor(P,name);
    const wrapper=function(...args){const c=state(this),result=Reflect.apply(original,this,args);after(c,args,result);return result;};
    Object.defineProperty(P,name,{configurable:true,writable:true,value:wrapper,enumerable:own?.enumerable??false});
    installed.push({name,own,wrapper});
  }
  // Binding calls occur hundreds of times per frame. Fixed arity avoids a new
  // rest-argument array on each tracked bind; binding itself never invalidates.
  function hookBinding(name,arity,after) {
    const original=P[name];if(typeof original!=='function'){supported=false;return;}
    originals.set(name,original);const own=Object.getOwnPropertyDescriptor(P,name);
    const wrapper=arity===1?function(a){const c=state(this),r=original.call(this,a);after(c,a);return r;}
      :function(a,b){const c=state(this),r=original.call(this,a,b);after(c,a,b);return r;};
    Object.defineProperty(P,name,{configurable:true,writable:true,value:wrapper,enumerable:own?.enumerable??false});
    installed.push({name,own,wrapper});
  }
  if(P) {
    for(const name of ['getParameter','isContextLost','checkFramebufferStatus'])if(typeof P[name]==='function')originals.set(name,P[name]);else supported=false;
    if(supported) {
      for(const name of ['createTexture','createRenderbuffer'])hook(name,(c,a,result)=>{
        if(result)c.resources.set(result,{kind:name==='createTexture'?'texture':'renderbuffer',target:0,alive:true,version:0,images:new Map()});
      });
      hook('createFramebuffer',(c,a,result)=>{if(result)c.fbos.set(result,{alive:true,version:0,attachments:new Map(),cached:false});});
      hookBinding('bindFramebuffer',2,(c,target,object)=>{
        if(!fbTarget(target)||(object!==null&&(!c.fbos.has(object)||!c.fbos.get(object).alive))){unsafe(c,'unobserved or invalid framebuffer bind');c.draw=undefined;c.read=undefined;return;}
        if(target===G.FB||target===G.DRAW)c.draw=object;if(target===G.FB||target===G.READ)c.read=object;
      });
      hookBinding('activeTexture',1,(c,value)=>{
        const unit=value-G.TEXTURE0;
        if(!Number.isInteger(unit)||unit<0||unit>=c.maxUnits){unsafe(c,'invalid active texture');return;}c.unit=unit;
      });
      hookBinding('bindTexture',2,(c,target,object)=>{
        const index=slot(target),r=object?c.resources.get(object):null;
        if(index<0||(object!==null&&(!r?.alive||r.kind!=='texture'||(r.target&&r.target!==target)))){unsafe(c,'unobserved or invalid texture bind');return;}
        if(r)r.target=target;if(!c.bindings[c.unit])c.bindings[c.unit]=[];c.bindings[c.unit][index]=object;
      });
      hookBinding('bindRenderbuffer',2,(c,target,object)=>{
        const r=object?c.resources.get(object):null;
        if(target!==G.RB||(object!==null&&(!r?.alive||r.kind!=='renderbuffer'))){unsafe(c,'unobserved or invalid renderbuffer bind');return;}c.rb=object;
      });
      const attach=(kind,c,a,objectIndex,descriptor)=>{
        const f=touchFbo(c,a[0]);if(!f)return;
        const object=a[objectIndex];
        if(object!==null&&!c.resources.has(object)){unsafe(c,'unobserved attachment resource');return;}
        if(object===null)f.attachments.delete(a[1]);else f.attachments.set(a[1],{kind,object,...descriptor});
      };
      hook('framebufferTexture2D',(c,a)=>attach('texture2D',c,a,3,{target:a[2],level:a[4]}));
      hook('framebufferTextureLayer',(c,a)=>attach('textureLayer',c,a,2,{level:a[3],layer:a[4]}));
      hook('framebufferRenderbuffer',(c,a)=>attach('renderbuffer',c,a,3,{target:a[2]}));
      hook('texImage2D',(c,a)=>{const r=boundResource(c,a[0],true);dirty(r);if(r)r.images.set(a[1],a.length>=9?{format:a[2],width:a[3],height:a[4]}:{format:a[2],width:null,height:null});});
      hook('texImage3D',(c,a)=>{const r=boundResource(c,a[0]);dirty(r);if(r)r.images.set(a[1],{format:a[2],width:a[3],height:a[4],depth:a[5]});});
      hook('texStorage2D',(c,a)=>{const r=boundResource(c,a[0]);dirty(r);if(r)r.images.set(0,{format:a[2],width:a[3],height:a[4]});});
      hook('texStorage3D',(c,a)=>{const r=boundResource(c,a[0]);dirty(r);if(r)r.images.set(0,{format:a[2],width:a[3],height:a[4],depth:a[5]});});
      for(const name of ['compressedTexImage2D','compressedTexImage3D','copyTexImage2D','generateMipmap'])hook(name,(c,a)=>{const r=boundResource(c,a[0],true);dirty(r);if(r&&name!=='generateMipmap')r.images.clear();});
      for(const name of ['texParameteri','texParameterf'])hook(name,(c,a)=>dirty(boundResource(c,a[0])));
      for(const name of ['renderbufferStorage','renderbufferStorageMultisample'])hook(name,(c,a)=>{
        const r=c.rb?c.resources.get(c.rb):null;if(a[0]!==G.RB||c.rb===undefined||(c.rb&&!r))unsafe(c,'unobserved renderbuffer storage');dirty(r);
      });
      for(const name of ['deleteTexture','deleteRenderbuffer'])hook(name,(c,a)=>{
        if(a[0]===null)return;const r=c.resources.get(a[0]);if(!r){unsafe(c,'unobserved resource delete');return;}dirty(r);r.alive=false;
        if(name==='deleteTexture')for(const unit of c.bindings)if(unit)for(let i=0;i<unit.length;i++)if(unit[i]===a[0])unit[i]=null;
        if(c.rb===a[0])c.rb=null;
      });
      hook('deleteFramebuffer',(c,a)=>{
        if(a[0]===null)return;const f=c.fbos.get(a[0]);if(!f){unsafe(c,'unobserved framebuffer delete');return;}f.alive=false;f.cached=false;
        if(c.read===a[0])c.read=null;if(c.draw===a[0])c.draw=null;inc('framebufferDeletes');
      });
      hook('drawBuffers',c=>touchFbo(c,G.DRAW));
      hook('readBuffer',c=>touchFbo(c,G.READ));
      hook('getExtension',(c,a,result)=>{
        if(result&&!safeExtensions.has(a[0])){c.unsupportedExtension='unsupported extension: '+a[0];unsafe(c,c.unsupportedExtension);}
      });
      const original=originals.get('checkFramebufferStatus'),own=Object.getOwnPropertyDescriptor(P,'checkFramebufferStatus');
      const wrapper=function(target) {
        const c=state(this);inc('checks');
        const lost=native('isContextLost',this,[]);
        if(lost){if(!c.wasLost){reset(c,this,'contextLossResets');c.wasLost=true;}inc('lostFallbacks');inc('nativeChecks');return Reflect.apply(original,this,[target]);}
        if(c.wasLost){reset(c,this,'contextRestoreResets');c.wasLost=false;initializeBindings(c,this);}
        if(c.width!==this.canvas?.width||c.height!==this.canvas?.height){c.width=this.canvas?.width;c.height=this.canvas?.height;c.epoch++;inc('resizeInvalidations');}
        const f=target===G.FB?fb(c,target):null,r=enabled&&supported&&!c.unsafe?candidate(c,f):null;
        if(r&&f.cached&&f.cachedFbVersion===f.version&&f.cachedResource===r&&f.cachedResourceVersion===r.version&&f.cachedEpoch===c.epoch&&f.cachedToggleEpoch===toggleEpoch){inc('hits');return G.COMPLETE;}
        inc('nativeChecks');
        if(!enabled)inc('disabledFallbacks');else if(c.unsafe){inc('unsafeFallbacks');lastFallback=c.unsafe;}else if(!r)inc('ineligibleFallbacks');else inc('misses');
        const result=Reflect.apply(original,this,[target]);
        if(r&&result===G.COMPLETE){f.cached=true;f.cachedFbVersion=f.version;f.cachedResource=r;f.cachedResourceVersion=r.version;f.cachedEpoch=c.epoch;f.cachedToggleEpoch=toggleEpoch;inc('stores');}
        else if(f)f.cached=false;
        return result;
      };
      Object.defineProperty(P,'checkFramebufferStatus',{configurable:true,writable:true,value:wrapper,enumerable:own?.enumerable??false});
      installed.push({name:'checkFramebufferStatus',own,wrapper});
    }
  }
  globalThis.EVER_DEEPER_FBO={
    version:1,
    setEnabled(value){enabled=!!value;toggleEpoch++;return enabled;},
    resetCounters(){totals={};lastFallback='';},
    snapshot(){return{version:1,supported,enabled,...totals,lastFallback,scope:'Only observed 400x400 depth-stencil-only FBOs; no timings or GPU claims'};},
    uninstall(){enabled=false;toggleEpoch++;for(const {name,own,wrapper} of installed){if(P[name]!==wrapper){inc('uninstallConflicts');continue;}if(own)Object.defineProperty(P,name,own);else delete P[name];}return this.snapshot();},
  };
})();
