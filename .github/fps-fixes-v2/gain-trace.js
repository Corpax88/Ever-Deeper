/* Observes every AudioParam.value setter, not only music gain parameters. */
(() => {
 const proto=globalThis.AudioParam?.prototype,descriptor=proto&&Object.getOwnPropertyDescriptor(proto,'value');
 let active=false,values=new WeakMap(),writes=0,repeated=0,parameters=0,started=0;
 if(!descriptor?.set||!descriptor?.get)throw Error('AudioParam descriptor unavailable');
 const setter=function(value){
  if(active){writes++;if(values.has(this)){if(Object.is(values.get(this),value))repeated++;}else parameters++;values.set(this,value);}
  return descriptor.set.call(this,value);
 };
 Object.defineProperty(proto,'value',{...descriptor,set:setter});
 globalThis.FPS_GAIN_TRACE={
  begin(){values=new WeakMap();writes=0;repeated=0;parameters=0;started=performance.now();active=true;},
  end(){active=false;return{writes,repeated,parameters,elapsed_ms:performance.now()-started,scope:'all AudioParam.value setters; no music-only attribution'};},
  uninstall(){active=false;if(Object.getOwnPropertyDescriptor(proto,'value').set!==setter)throw Error('Gain observer ownership changed');Object.defineProperty(proto,'value',descriptor);}
 };
})();
