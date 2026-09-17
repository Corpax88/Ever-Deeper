// Added after the byte-identical observer.js in the same init script.
// No game command or extra WebGL command is issued by this probe.
(() => {
  const capacity=8192;
  const methods=['texImage2D','compressedTexImage2D','texStorage2D','compileShader',
    'linkProgram','getShaderParameter','getProgramParameter'];
  const status=[0,0,0,0,0,0x8b81,0x8b82]; // COMPILE_STATUS / LINK_STATUS only.
  const ids=new Uint8Array(capacity),starts=new Float64Array(capacity),ends=new Float64Array(capacity),success=new Uint8Array(capacity);
  const counts=new Uint32Array(methods.length),untimed=new Uint32Array(methods.length);
  const now=performance.now.bind(performance),timeOrigin=performance.timeOrigin;
  const proto=HTMLCanvasElement.prototype,previousGet=proto.getContext;
  const previousDescriptor=Object.getOwnPropertyDescriptor(proto,'getContext');
  let gl=null,installed=[],active=false,everStarted=false,restored=false;
  let count=0,dropped=0,errorMask=0,extraContext=false,started=null,stopped=null,startReceipt=null;
  const api={};
  function sameDescriptor(a,b) {
    if(!a||!b)return a===b;
    const keys=['value','get','set','writable','enumerable','configurable'];
    return keys.every(k=>Object.hasOwn(a,k)===Object.hasOwn(b,k)&&a[k]===b[k]);
  }
  function undoMethods() {
    let all=true;
    for(const {name,own,fn} of installed) {
      try {if(own)Object.defineProperty(gl,name,own);else delete gl[name];}
      catch {all=false;}
      if(gl[name]!==fn||!sameDescriptor(Object.getOwnPropertyDescriptor(gl,name),own))all=false;
    }
    return all;
  }
  function install(ctx) {
    gl=ctx;
    try {
      for(let id=0;id<methods.length;id++) {
        const name=methods[id],own=Object.getOwnPropertyDescriptor(ctx,name),fn=ctx[name],pname=status[id];
        if(typeof fn!=='function'||(own&&!Object.hasOwn(own,'value')))throw Error('Unsupported method descriptor');
        const wrapper=function() {
          if(pname&&arguments[1]!==pname)return Reflect.apply(fn,this,arguments);
          if(!active){untimed[id]++;return Reflect.apply(fn,this,arguments);}
          counts[id]++;
          if(count>=capacity){dropped++;return Reflect.apply(fn,this,arguments);}
          const i=count++;
          ids[i]=id;starts[i]=now();
          let ok=0;
          try {const value=Reflect.apply(fn,this,arguments);ok=1;return value;}
          finally {ends[i]=now();success[i]=ok;}
        };
        const entry={name,own,fn,wrapper};
        installed.push(entry);
        Object.defineProperty(ctx,name,own?{...own,value:wrapper}:{value:wrapper,writable:true,configurable:true,enumerable:false});
        if(ctx[name]!==wrapper)throw Error('Wrapper not installed');
      }
    }catch {
      errorMask|=2;
      if(!undoMethods())errorMask|=16;
    }
  }
  function wrappedGetContext() {
    const ctx=Reflect.apply(previousGet,this,arguments);
    if(this.id==='canvas'&&['webgl','webgl2','experimental-webgl'].includes(arguments[0])&&ctx) {
      if(!gl)install(ctx);
      else if(ctx!==gl){extraContext=true;errorMask|=4;}
    }
    return ctx;
  }
  try {
    if(!previousDescriptor||!Object.hasOwn(previousDescriptor,'value'))throw Error('Unsupported getContext descriptor');
    Object.defineProperty(proto,'getContext',{...previousDescriptor,value:wrappedGetContext});
    if(proto.getContext!==wrappedGetContext)throw Error('getContext not installed');
  }catch {errorMask|=1;}
  function checkStable() {
    if(proto.getContext!==wrappedGetContext||installed.length!==methods.length||installed.some(x=>gl[x.name]!==x.wrapper))errorMask|=8;
    if(!window.__webkitMovingStudy||window.__webkitMovingStudy.contexts.length!==1||window.__webkitMovingStudy.contexts[0]!==gl)errorMask|=32;
  }
  api.ready=()=>({active,ever_started:everStarted,restored,error_mask:errorMask,extra_context:extraContext,
    methods:[...methods],installed:installed.length,untimed_counts:Array.from(untimed),capacity,time_origin:timeOrigin});
  api.clock=()=>({clock:'window.performance.now',time_origin:performance.timeOrigin,now_ms:now()});
  api.start=()=>{
    if(active||everStarted||restored)throw Error('Resource probe can start only once');
    checkStable();
    if(errorMask||!gl)throw Error('Resource probe installation gate failed: '+errorMask);
    const startup=Array.from(untimed);
    if(startup[0]+startup[1]+startup[2]===0||startup[3]+startup[4]===0||startup[5]+startup[6]===0)throw Error('Startup texture/shader/status hooks were not exercised');
    startReceipt={clock:'window.performance.now',time_origin:timeOrigin,capacity,methods:[...methods],untimed_counts_before:startup};
    everStarted=true;started=now();startReceipt.start_ms=started;active=true;
    return startReceipt;
  };
  api.stop=()=>{
    const wasActive=active;active=false;
    if(wasActive){stopped=now();checkStable();}
    return {was_active:wasActive,stopped_ms:stopped,count,dropped,error_mask:errorMask};
  };
  api.capture=()=>{
    if(active)throw Error('Capture outside timing only');
    return {schema:1,clock:'window.performance.now',time_origin:timeOrigin,capacity,count,dropped,error_mask:errorMask,
      started_ms:started,stopped_ms:stopped,start_receipt:startReceipt,methods:[...methods],counts:Array.from(counts),
      rows:Array.from({length:count},(_,i)=>({method:ids[i],start:starts[i],end:ends[i],success:success[i]}))};
  };
  api.restore=()=>{
    if(active)throw Error('Stop before restoration');
    if(restored)throw Error('Resource probe already restored');
    checkStable();
    const methodsRestored=undoMethods();
    if(previousDescriptor)Object.defineProperty(proto,'getContext',previousDescriptor);
    else delete proto.getContext;
    const getRestored=proto.getContext===previousGet&&sameDescriptor(Object.getOwnPropertyDescriptor(proto,'getContext'),previousDescriptor);
    restored=true;
    return {all_methods_restored:methodsRestored,get_context_restored_to_observer:getRestored,
      method_count:installed.length,error_mask:errorMask,descriptors_restored:methodsRestored};
  };
  window.__webkitResourceProbe=api;
})();
