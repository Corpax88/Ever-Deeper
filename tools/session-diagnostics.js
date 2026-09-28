// Opt-in diagnostics for the exact DEV runtime. No gameplay/quality changes.
// Wall time in a GL call includes driver waiting; it is NOT GPU execution time.
(() => {
  'use strict';
  const clock = () => performance.now(), round = x => Math.round(Math.max(0,x)*100)/100;
  const summary = a => {if(!a.length)return null; const b=[...a].sort((x,y)=>x-y);return [a.length,round(a.reduce((s,x)=>s+x,0)/a.length),round(b[Math.ceil(b.length*.95)-1]),round(b[b.length-1])];};
  const groups = {
    sync:['fenceSync','getSyncParameter','clientWaitSync','waitSync','checkFramebufferStatus','getBufferSubData','readPixels','finish','flush'],
    draw:['drawArrays','drawElements','drawArraysInstanced','drawElementsInstanced','clear','blitFramebuffer'],
    upload:['bufferData','bufferSubData','texImage2D','texSubImage2D','compressedTexImage2D','compressedTexSubImage2D','texStorage2D','generateMipmap'],
    state:['bindFramebuffer','useProgram','bindTexture','bindBuffer','viewport','scissor']
  };
  let active=false, sampling=false, serial=0, first=0,lastStart=0,lastEnd=0,frame=null, windowData=null,previousFrame=null;
  let contexts=new Map(), sources=null, capabilities=null, observer=[], timer=0, timerDue=0, pausedForSnapshot=false;
  const fresh = () => ({callback:[],interval:[],gap:[],plain:[],sampled:[],gpu:[],gpuRejected:0,gpuSkipped:0,gl:{},worst:[],seconds:[],bins:new Map(),lag:[],longtask:[],loaf:[],snapMs:0,persistMs:[],errors:0});
  const boundedPush=(a,x,n=1800)=>{if(a.length<n&&Number.isFinite(x)&&x>=0)a.push(x);};
  const safe = fn => {try{return fn();}catch {if(windowData)windowData.errors++;return null;}};
  function restore() {
    for(const [gl,c] of contexts){
      for(const w of c.wrappers)if(gl[w.name]===w.wrapped)gl[w.name]=w.original;
      safe(()=>{if(c.open){gl.endQuery(c.ext.TIME_ELAPSED_EXT);c.open=false;}for(const q of c.pending)gl.deleteQuery(q.query);});
      c.pending=[];c.wrappers=[];
    }
    contexts.clear();
  }
  function attach(gl) {
    if(!gl||contexts.has(gl))return;
    const c={wrappers:[],pending:[],ext:null,open:false};contexts.set(gl,c);
    c.ext=safe(()=>gl.getExtension('EXT_disjoint_timer_query_webgl2'));
    capabilities.gpu_timer=c.ext?'available':'unavailable';
    capabilities.webgl=2;
    for(const [group,names] of Object.entries(groups))for(const name of names){
      const original=gl[name];if(typeof original!=='function')continue;
      const wrapped=function(...args){
        if(!active||!sampling||!frame)return Reflect.apply(original,this,args);
        const t=clock();try{return Reflect.apply(original,this,args);}finally{
          const ms=clock()-t;const v=frame.gl[name]||(frame.gl[name]=[0,0,group]);v[0]++;v[1]+=ms;
        }
      };
      safe(()=>{gl[name]=wrapped;if(gl[name]===wrapped)c.wrappers.push({name,original,wrapped});});
    }
  }
  function pollGpu(gl,c){
    if(!c.ext||gl.isContextLost())return;
    if(gl.getParameter(c.ext.GPU_DISJOINT_EXT)){
      windowData.gpuRejected+=c.pending.length;
      for(const q of c.pending)gl.deleteQuery(q.query);c.pending=[];return;
    }
    const keep=[];
    for(const q of c.pending){
      if(gl.getQueryParameter(q.query,gl.QUERY_RESULT_AVAILABLE)){
        const ms=gl.getQueryParameter(q.query,gl.QUERY_RESULT)/1e6;
        // Delayed results retain originating window identity. Never attribute to a later window.
        if(q.owner===windowData&&Number.isFinite(ms)&&ms>0&&ms<10000)boundedPush(windowData.gpu,ms);
        else windowData.gpuRejected++;
        gl.deleteQuery(q.query);
      }else if(clock()-q.at>2000){windowData.gpuRejected++;gl.deleteQuery(q.query);}
      else keep.push(q);
    }
    c.pending=keep;
  }
  function lagTick(){if(!active)return;boundedPush(windowData.lag,clock()-timerDue);timerDue=clock()+250;timer=setTimeout(lagTick,250);}
  function start(){
    stop();active=true;serial=0;first=clock();lastStart=lastEnd=0;previousFrame=null;windowData=fresh();
    const ua=globalThis.navigator?.userAgent||'';
    capabilities={browser_version:(ua.match(/(?:Version|CriOS|Chrome|FxiOS|Firefox)\/([0-9.]+)/)||[])[1]||'unknown',os_version:((ua.match(/(?:CPU (?:iPhone )?OS|iPhone OS|Mac OS X) ([0-9_]+)/)||[])[1]||'unknown').replaceAll('_','.'),revision:2,gpu_timer:'not_observed',webgl:0,longtask:false,long_animation_frame:false,js_heap:!!performance.memory,temperature:false,power_state:false};
    for(const [type,key] of [['longtask','longtask'],['long-animation-frame','loaf']]){
      if(!globalThis.PerformanceObserver?.supportedEntryTypes?.includes(type))continue;
      safe(()=>{const o=new PerformanceObserver(list=>{if(active)for(const e of list.getEntries())boundedPush(windowData[key],e.duration,128);});o.observe({type,buffered:false});observer.push(o);capabilities[type==='longtask'?'longtask':'long_animation_frame']=true;});
    }
    timerDue=clock()+250;timer=setTimeout(lagTick,250);
  }
  function stop(){active=false;sampling=false;clearTimeout(timer);for(const o of observer)o.disconnect();observer=[];restore();frame=null;sources=null;previousFrame=null;lastStart=lastEnd=0;}
  function before(gl,audio,memory){
    if(!active)return;
    safe(()=>{
      const entry=clock();sources={audio,memory};attach(gl);
      const c=contexts.get(gl);if(c&&serial%15===0)pollGpu(gl,c);
      // One detailed frame in thirty. Other frames are controls, not GPU samples.
      sampling=(++serial%30===0);const start=clock();
      frame={start:entry,interval:lastStart?entry-lastStart:0,gap:lastEnd?entry-lastEnd:0,gl:{},sampled:sampling,setup:start-entry,gpu:null};lastStart=entry;
      if(sampling&&c?.ext&&!gl.isContextLost()&&c.pending.length<4){
        if(!gl.getQuery(c.ext.TIME_ELAPSED_EXT,gl.CURRENT_QUERY)){
          const q=gl.createQuery();if(q){gl.beginQuery(c.ext.TIME_ELAPSED_EXT,q);c.open=true;frame.gpu={gl,c,q};}
        }else windowData.gpuSkipped++;
      }
    });
  }
  function after(){
    if(!active||!frame)return;
    safe(()=>{
      const end=clock(),f=frame;sampling=false;
      if(f.gpu){const {gl,c,q}=f.gpu;gl.endQuery(c.ext.TIME_ELAPSED_EXT);c.open=false;c.pending.push({query:q,at:end,owner:windowData});}
      const ms=end-f.start;boundedPush(windowData.callback,ms);boundedPush(f.sampled?windowData.sampled:windowData.plain,ms);
      if(f.interval)boundedPush(windowData.interval,f.interval);if(f.gap)boundedPush(windowData.gap,f.gap);
      const sec=Math.floor((f.start-first)/1000);let b=windowData.bins.get(sec);
      if(!b&&windowData.bins.size<8){b=[sec,0,0,0,0,0];windowData.bins.set(sec,b);}
      if(b){b[1]++;b[2]+=ms;b[3]=Math.max(b[3],ms);b[4]+=f.gap;b[5]=Math.max(b[5],f.gap);}
      let glMs=0;
      for(const [name,v] of Object.entries(f.gl)){
        const a=windowData.gl[name]||(windowData.gl[name]=[0,0]);a[0]+=v[0];a[1]+=v[1];glMs+=v[1];
      }
      if(f.interval>25){windowData.worst.push([round(f.start-first),round(f.interval),round(previousFrame?.ms||0),round(f.gap),previousFrame?.sampled?1:0,round(previousFrame?.glMs||0)]);windowData.worst.sort((a,b)=>b[1]-a[1]);windowData.worst.length=Math.min(4,windowData.worst.length);}
      previousFrame={ms,sampled:f.sampled,glMs};lastEnd=end;frame=null;
    });
  }
  function snapshot(){
    if(!active||!windowData)return null;
    const t=clock(),w=windowData;let result;
    safe(()=>{
      const a=sources?.audio,ctx=a?.ctx;
      result={revision:2,capabilities:{...capabilities},callback_ms:summary(w.callback),interval_ms:summary(w.interval),outside_ms:summary(w.gap),control_ms:summary(w.plain),instrumented_ms:summary(w.sampled),gpu_ms:summary(w.gpu),gpu_rejected:w.gpuRejected,gpu_skipped:w.gpuSkipped,
        gl:Object.fromEntries(Object.entries(w.gl).map(([k,v])=>[k,[v[0],round(v[1])]])),
        seconds:[...w.bins.values()].map(b=>b.map(round)),worst:w.worst,
        timer_lag_ms:summary(w.lag),longtask_ms:summary(w.longtask),long_animation_frame_ms:summary(w.loaf),
        wasm_mib:sources?.memory?.buffer?round(sources.memory.buffer.byteLength/1048576):null,
        js_heap_mib:performance.memory?round(performance.memory.usedJSHeapSize/1048576):null,
        audio:{state:ctx?.state||'absent',nodes:a?.sampleNodes?.size??0,buffers:a?.samples?.size??0,worklets:a?.audioPositionWorkletNodes?.length??0,base_latency_ms:ctx?.baseLatency==null?null:round(ctx.baseLatency*1000)},
        persist_ms:summary(w.persistMs),errors:w.errors,collector_ms:0};
    });
    windowData=fresh();if(result)result.collector_ms=round(clock()-t);return result??null;
  }
  const api={start,stop,before,after,snapshot,get active(){return active;},persist(ms){if(active&&windowData)boundedPush(windowData.persistMs,ms,128);}};
  window.everDeeperDiagnostics=api;
})();
