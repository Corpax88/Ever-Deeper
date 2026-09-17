// Init-script observer. Original HTML, JS, WASM and PCK responses are unchanged.
(() => {
  const originalRAF=window.requestAnimationFrame;
  let gameGL=null, selected=null, selectedSource='', calls=0, census=null, active=null;
  const events=[], contexts=[];
  let keyState={ArrowDown:false,Space:false};
  const api={events,contexts};
  const oldGetContext=HTMLCanvasElement.prototype.getContext;
  HTMLCanvasElement.prototype.getContext=function(...args) {
    const ctx=Reflect.apply(oldGetContext,this,args);
    if(this.id==='canvas' && ['webgl','webgl2','experimental-webgl'].includes(args[0]) && ctx && !contexts.some(x=>x===ctx)) {
      contexts.push(ctx); if(!gameGL) {gameGL=ctx;this.addEventListener('webglcontextlost',()=>event('contextlost'));}
    }
    return ctx;
  };
  function event(kind,detail={}) {
    const row={kind,time:performance.now(),...detail}; events.push(row);
    if(active && ['blur','hidden','pagehide','resize','contextlost'].includes(kind)) active.error=kind;
  }
  window.addEventListener('blur',()=>event('blur'));
  window.addEventListener('pagehide',()=>event('pagehide'));
  window.addEventListener('resize',()=>event('resize'));
  document.addEventListener('visibilitychange',()=>{if(document.hidden)event('hidden');});
  for(const name of ['keydown','keyup']) window.addEventListener(name,e=>{
    if(['ArrowDown','Space'].includes(e.code)) {keyState[e.code]=name==='keydown';event(name,{code:e.code,trusted:e.isTrusted,repeat:e.repeat});}
  },true);
  function wrapDraws() {
    const originals=[], result={draw_calls:0,by_method:{},restored:false};
    for(const method of ['drawArrays','drawElements','drawArraysInstanced','drawElementsInstanced']) {
      const own=Object.getOwnPropertyDescriptor(gameGL,method), fn=gameGL[method];
      if(typeof fn!=='function') throw Error('Missing GL method '+method);
      originals.push({method,own,fn});
      gameGL[method]=function(...args) { result.draw_calls++;result.by_method[method]=(result.by_method[method]||0)+1;return Reflect.apply(fn,this,args); };
    }
    return {result,restore() {for(const {method,own,fn}of originals){if(own)Object.defineProperty(gameGL,method,own);else delete gameGL[method];if(gameGL[method]!==fn)throw Error('GL method not restored');} result.restored=true;}};
  }
  window.requestAnimationFrame=function(callback) {
    if(callback.name!=='MainLoop_runner') return Reflect.apply(originalRAF,window,[callback]);
    if(!selected) {selected=callback;selectedSource=Function.prototype.toString.call(callback);}
    if(selected!==callback) {event('engine_callback_changed');if(active)active.error='engine_callback_changed';}
    return Reflect.apply(originalRAF,window,[function(timestamp) {
      calls++;
      const drawCheck=census?wrapDraws():null;
      const began=performance.now();
      try { return Reflect.apply(callback,this,[timestamp]); }
      finally {
        const ended=performance.now();
        if(drawCheck) {
          drawCheck.restore();census.attempts++;census.rows.push(drawCheck.result);
          if(drawCheck.result.draw_calls>0 || census.attempts>=8) {const c=census;census=null;c.resolve({attempts:c.attempts,rows:c.rows,all_restored:true,canvas:api.surface()});}
        }
        if(active) {
          const a=active;
          if(!a.count)a.started=began;
          if(a.count>=a.capacity) a.error='overflow';
          else {const i=a.count++;a.starts[i]=began;a.ends[i]=ended;a.raf[i]=timestamp;}
          if(began-a.started>=60000 || a.error) {
            active=null;
            const rows=Array.from({length:a.count},(_,i)=>({start:a.starts[i],end:a.ends[i],raf:a.raf[i]}));
            a.resolve({metric:'engine_loop_callback_cadence',error:a.error||null,started:a.started,finished:ended,
              seconds:(began-a.started)/1000,count:a.count,rows,callback_source:selectedSource,
              keys_at_end:{...keyState},visibility:document.visibilityState});
          }
        }
      }
    }]);
  };
  api.surface=()=>{
    if(!gameGL||contexts.length!==1)throw Error('Expected one actual game WebGL context');
    const canvas=gameGL.canvas,r=canvas.getBoundingClientRect();
    return {css:{width:r.width,height:r.height},canvas:{width:canvas.width,height:canvas.height},
      buffer:{width:gameGL.drawingBufferWidth,height:gameGL.drawingBufferHeight},dpr:devicePixelRatio,
      vendor:gameGL.getParameter(gameGL.VENDOR),renderer:gameGL.getParameter(gameGL.RENDERER),version:gameGL.getParameter(gameGL.VERSION)};
  };
  api.ready=()=>({calls,selected:!!selected,contexts:contexts.length,version:window.everDeeperVersion,hidden:document.hidden,keys:{...keyState}});
  api.census=()=>new Promise(resolve=>{
    if(active||census||!selected||!gameGL)throw Error('Draw check outside timing only');
    census={resolve,attempts:0,rows:[]};
  });
  api.begin=()=>new Promise(resolve=>{
    if(active||census||!selected||document.hidden||!keyState.ArrowDown||!keyState.Space)throw Error('Invalid measurement entry');
    const capacity=20000; active={resolve,capacity,count:0,started:0,starts:new Float64Array(capacity),ends:new Float64Array(capacity),raf:new Float64Array(capacity)};
  });
  api.partial=()=>active?{count:active.count,error:active.error,started:active.started,rows:Array.from({length:active.count},(_,i)=>({start:active.starts[i],end:active.ends[i],raf:active.raf[i]}))}:null;
  api.restore=()=>{
    if(active||census)throw Error('Observer still active');
    window.requestAnimationFrame=originalRAF;HTMLCanvasElement.prototype.getContext=oldGetContext;
    return {raf_restored:window.requestAnimationFrame===originalRAF,get_context_restored:HTMLCanvasElement.prototype.getContext===oldGetContext};
  };
  window.__webkitMovingStudy=api;
})();
