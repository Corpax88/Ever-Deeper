// Added after the byte-identical observer.js in the same init script.
// No game command or extra WebGL command is issued by this probe.
(() => {
  const capacity=8192;
  const methods=['texImage2D','compressedTexImage2D','texStorage2D','compileShader',
    'linkProgram','getShaderParameter','getProgramParameter'];
  const status=[0,0,0,0,0,0x8b81,0x8b82]; // COMPILE_STATUS / LINK_STATUS only.
  const metadataMethods=['shaderSource','attachShader'];
  const caps={shaders:1024,programs:512,sources:1024,events:8192,max_source_code_units:262144,total_source_code_units:16777216};
  // Weak keys do not retain deleted shader/program objects. All other records are
  // numbers or original immutable strings, never additional GL queries/objects.
  const shaderIds=new WeakMap(),programIds=new WeakMap();
  const sourceText=new Array(caps.sources),sourceShader=new Uint16Array(caps.sources);
  const eventKind=new Uint8Array(caps.events),eventObject=new Uint16Array(caps.events),eventOther=new Uint16Array(caps.events);
  const eventSuccess=new Uint8Array(caps.events),eventTimedRow=new Int32Array(caps.events),eventActive=new Uint8Array(caps.events);
  const rowEvent=new Uint16Array(capacity);
  let shaderCount=0,programCount=0,sourceCount=0,sourceUnits=0,eventCount=0,identityDropped=0,identityErrors=0,tracking=true;
  const ids=new Uint8Array(capacity),starts=new Float64Array(capacity),ends=new Float64Array(capacity),success=new Uint8Array(capacity);
  const counts=new Uint32Array(methods.length),untimed=new Uint32Array(methods.length);
  const now=performance.now.bind(performance),timeOrigin=performance.timeOrigin;
  const proto=HTMLCanvasElement.prototype,previousGet=proto.getContext;
  const previousDescriptor=Object.getOwnPropertyDescriptor(proto,'getContext');
  let gl=null,installed=[],active=false,everStarted=false,restored=false;
  let count=0,dropped=0,errorMask=0,extraContext=false,started=null,stopped=null,startReceipt=null;
  const api={};
  function identityError(bit) {identityErrors|=bit;identityDropped++;errorMask|=64;return 0;}
  function objectId(value,program) {
    if((typeof value!=='object'&&typeof value!=='function')||value===null)return identityError(64);
    const map=program?programIds:shaderIds;
    const found=map.get(value);if(found)return found;
    if(program?programCount>=caps.programs:shaderCount>=caps.shaders)return identityError(program?2:1);
    const id=program?++programCount:++shaderCount;map.set(value,id);return id;
  }
  function recordIdentity(kind,args,ok,timedRow) {
    if(!tracking)return 0;
    try {
      if(eventCount>=caps.events)return identityError(8);
      const object=objectId(args[0],kind===2||kind===3||kind===5);if(!object)return 0;
      let other=0;
      if(kind===0) {
        // No coercion or text hashing/copying in a hook. Forwarding has already
        // occurred. An unsupported non-string argument rejects only the probe.
        const text=args[1];
        if(typeof text!=='string')return identityError(64);
        if(sourceCount>=caps.sources)return identityError(4);
        if(text.length>caps.max_source_code_units)return identityError(16);
        if(sourceUnits+text.length>caps.total_source_code_units)return identityError(32);
        sourceText[sourceCount]=text;sourceShader[sourceCount]=object;
        sourceUnits+=text.length;other=++sourceCount;
      }else if(kind===2) {other=objectId(args[1],false);if(!other)return 0;}
      const i=eventCount++;
      eventKind[i]=kind;eventObject[i]=object;eventOther[i]=other;
      eventSuccess[i]=ok;eventTimedRow[i]=timedRow;eventActive[i]=active?1:0;
      return i+1;
    }catch {return identityError(128);}
  }
  // Completion-order events are sufficient for native WebGL calls from the
  // pinned dispatch: shaderSource receives a string, not a reentrant coercion.
  const kindForMethod=[-1,-1,-1,1,3,4,5];
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
          if(!active){
            untimed[id]++;
            if(id<3||!tracking)return Reflect.apply(fn,this,arguments);
            let ok=0;
            try {const value=Reflect.apply(fn,this,arguments);ok=1;return value;}
            finally {recordIdentity(kindForMethod[id],arguments,ok,-1);}
          }
          counts[id]++;
          if(count>=capacity){
            dropped++;let ok=0;
            try {const value=Reflect.apply(fn,this,arguments);ok=1;return value;}
            finally {if(id>=3)recordIdentity(kindForMethod[id],arguments,ok,-1);}
          }
          const i=count++;
          ids[i]=id;starts[i]=now();
          let ok=0;
          try {const value=Reflect.apply(fn,this,arguments);ok=1;return value;}
          finally {
            ends[i]=now();success[i]=ok;
            // Preserve the two original host-call clock boundaries. Identity
            // bookkeeping follows the end timestamp, inside the engine callback.
            if(id>=3)rowEvent[i]=recordIdentity(kindForMethod[id],arguments,ok,i);
          }
        };
        const entry={name,own,fn,wrapper};
        installed.push(entry);
        Object.defineProperty(ctx,name,own?{...own,value:wrapper}:{value:wrapper,writable:true,configurable:true,enumerable:false});
        if(ctx[name]!==wrapper)throw Error('Wrapper not installed');
      }
      for(let id=0;id<metadataMethods.length;id++) {
        const name=metadataMethods[id],own=Object.getOwnPropertyDescriptor(ctx,name),fn=ctx[name];
        if(typeof fn!=='function'||(own&&!Object.hasOwn(own,'value')))throw Error('Unsupported metadata method descriptor');
        const wrapper=function() {
          if(!tracking)return Reflect.apply(fn,this,arguments);
          let ok=0;
          try {const value=Reflect.apply(fn,this,arguments);ok=1;return value;}
          finally {recordIdentity(id===0?0:2,arguments,ok,-1);}
        };
        installed.push({name,own,fn,wrapper});
        Object.defineProperty(ctx,name,own?{...own,value:wrapper}:{value:wrapper,writable:true,configurable:true,enumerable:false});
        if(ctx[name]!==wrapper)throw Error('Metadata wrapper not installed');
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
    if(proto.getContext!==wrappedGetContext||installed.length!==methods.length+metadataMethods.length||installed.some(x=>gl[x.name]!==x.wrapper))errorMask|=8;
    if(!window.__webkitMovingStudy||window.__webkitMovingStudy.contexts.length!==1||window.__webkitMovingStudy.contexts[0]!==gl)errorMask|=32;
  }
  api.ready=()=>({active,ever_started:everStarted,restored,error_mask:errorMask,extra_context:extraContext,
    methods:[...methods],metadata_methods:[...metadataMethods],installed:installed.length,untimed_counts:Array.from(untimed),capacity,time_origin:timeOrigin,
    identity:{caps:{...caps},shader_count:shaderCount,program_count:programCount,source_count:sourceCount,event_count:eventCount,error_mask:identityErrors,dropped:identityDropped}});
  api.clock=()=>({clock:'window.performance.now',time_origin:performance.timeOrigin,now_ms:now()});
  api.start=()=>{
    if(active||everStarted||restored)throw Error('Resource probe can start only once');
    checkStable();
    if(errorMask||!gl)throw Error('Resource probe installation gate failed: '+errorMask);
    const startup=Array.from(untimed);
    if(startup[0]+startup[1]+startup[2]===0||startup[3]+startup[4]===0||startup[5]+startup[6]===0)throw Error('Startup texture/shader/status hooks were not exercised');
    startReceipt={clock:'window.performance.now',time_origin:timeOrigin,capacity,methods:[...methods],untimed_counts_before:startup,
      identity_at_start:{shader_count:shaderCount,program_count:programCount,source_count:sourceCount,event_count:eventCount}};
    everStarted=true;started=now();startReceipt.start_ms=started;active=true;
    return startReceipt;
  };
  api.stop=()=>{
    const wasActive=active;active=false;tracking=false;
    if(wasActive){stopped=now();checkStable();}
    return {was_active:wasActive,stopped_ms:stopped,count,dropped,error_mask:errorMask};
  };
  api.capture=()=>{
    if(active)throw Error('Capture outside timing only');
    return {schema:1,clock:'window.performance.now',time_origin:timeOrigin,capacity,count,dropped,error_mask:errorMask,
      started_ms:started,stopped_ms:stopped,start_receipt:startReceipt,methods:[...methods],counts:Array.from(counts),
      rows:Array.from({length:count},(_,i)=>({method:ids[i],start:starts[i],end:ends[i],success:success[i],identity_event:rowEvent[i]})),
      identity:{schema:1,caps:{...caps},metadata_methods:[...metadataMethods],error_mask:identityErrors,dropped:identityDropped,tracking,
        shader_count:shaderCount,program_count:programCount,source_count:sourceCount,source_code_units:sourceUnits,event_count:eventCount,
        sources:Array.from({length:sourceCount},(_,i)=>({id:i+1,shader:sourceShader[i],code_units:sourceText[i].length,glsl:sourceText[i]})),
        events:Array.from({length:eventCount},(_,i)=>({kind:eventKind[i],object:eventObject[i],other:eventOther[i],success:eventSuccess[i],timed_row:eventTimedRow[i],during_window:eventActive[i]}))}};
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
