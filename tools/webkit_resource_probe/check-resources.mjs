import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';
import { METHODS,analyzeResources } from './resources.mjs';
const observer=await readFile(new URL('observer.js',import.meta.url),'utf8');
const probe=await readFile(new URL('resources.js',import.meta.url),'utf8');
const plain=x=>JSON.parse(JSON.stringify(x));
const status=name=>name==='getShaderParameter'?0x8b81:name==='getProgramParameter'?0x8b82:0;
function fixture({missing,locked}={}) {
  let clock=100,reads=0,throwName=null,nest=false;
  const calls=[],events={},queued=[],returned={},thrown={native_exception:true};
  const native={},proto={};
  for(const name of METHODS) {
    if(name===missing)continue;
    native[name]=function() {
      calls.push({name,receiver:this,args:Array.from(arguments)});clock+=2;
      if(nest&&name==='texImage2D')gl.compileShader(arguments[0]);
      if(name===throwName)throw thrown;
      return returned;
    };
    proto[name]=native[name];
  }
  const gl=Object.create(proto);
  Object.defineProperty(gl,'texStorage2D',{value:native.texStorage2D,writable:!locked,configurable:false,enumerable:true});
  Object.assign(gl,{drawingBufferWidth:1696,drawingBufferHeight:780,getParameter:()=> 'mock',
    drawArrays(){},drawElements(){},drawArraysInstanced(){},drawElementsInstanced(){}});
  function Canvas(){}
  const nativeGet=function(){return this.otherContext||gl;};
  Canvas.prototype.getContext=nativeGet;Canvas.prototype.addEventListener=()=>{};
  const canvas=new Canvas();canvas.id='canvas';canvas.width=1696;canvas.height=780;canvas.getBoundingClientRect=()=>({width:848,height:390});gl.canvas=canvas;
  const nativeGetDescriptor=Object.getOwnPropertyDescriptor(Canvas.prototype,'getContext');
  const nativeDescriptors=METHODS.map(name=>Object.getOwnPropertyDescriptor(gl,name));
  const raf=callback=>{queued.push(callback);return queued.length;};
  const sandbox={performance:{now:()=>{reads++;return clock;},timeOrigin:1234000},HTMLCanvasElement:Canvas,
    requestAnimationFrame:raf,devicePixelRatio:2,document:{hidden:false,visibilityState:'visible',addEventListener(){}},
    addEventListener:(name,fn)=>{events[name]=fn;}};
  sandbox.window=sandbox;vm.createContext(sandbox);
  vm.runInContext(observer,sandbox);
  const observerGet=Canvas.prototype.getContext,observerDescriptor=Object.getOwnPropertyDescriptor(Canvas.prototype,'getContext');
  vm.runInContext(probe,sandbox);assert.equal(canvas.getContext('webgl2'),gl);
  const api=sandbox.__webkitResourceProbe;
  function warm(){gl.texImage2D({});gl.compileShader({});gl.getShaderParameter({},0x8b81);}
  return {gl,native,api,sandbox,calls,returned,thrown,canvas,Canvas,events,queued,raf,nativeGet,nativeGetDescriptor,nativeDescriptors,observerGet,observerDescriptor,warm,
    get clock(){return clock;},set clock(v){clock=v;},get reads(){return reads;},set throwName(v){throwName=v;},set nest(v){nest=v;}};
}
{
  const f=fixture();f.warm();
  const ready=plain(f.api.ready());assert.equal(ready.error_mask,0);assert.equal(ready.installed,7);
  const start=f.api.start();assert.equal(start.capacity,8192);
  const receiver={},data=new Uint8Array([2,3,4]),token=Symbol('argument');
  for(const name of METHODS) {
    const args=[data,status(name),token,undefined,null,17];
    const before=f.calls.length,reads=f.reads;
    assert.equal(Reflect.apply(f.gl[name],receiver,args),f.returned);
    assert.equal(f.calls.length,before+1);assert.equal(f.reads,reads+2);
    const last=f.calls.at(-1);assert.equal(last.receiver,receiver);
    assert.equal(last.args.length,args.length);for(let i=0;i<args.length;i++)assert.equal(last.args[i],args[i]);
  }
  const before=f.api.stop();assert.equal(before.count,7);
  assert.deepEqual(plain(f.api.capture()).counts,[1,1,1,1,1,1,1]);
  const r=f.api.restore();assert.equal(r.error_mask,0);assert.equal(r.all_methods_restored,true);
  assert.equal(f.Canvas.prototype.getContext,f.observerGet);
  assert.deepEqual(Object.getOwnPropertyDescriptor(f.Canvas.prototype,'getContext'),f.observerDescriptor);
  METHODS.forEach((name,i)=>{assert.equal(f.gl[name],f.native[name]);assert.deepEqual(Object.getOwnPropertyDescriptor(f.gl,name),f.nativeDescriptors[i]);});
  assert.equal(f.sandbox.__webkitMovingStudy.restore().get_context_restored,true);
  assert.equal(f.Canvas.prototype.getContext,f.nativeGet);
  assert.deepEqual(Object.getOwnPropertyDescriptor(f.Canvas.prototype,'getContext'),f.nativeGetDescriptor);
  assert.throws(()=>f.api.start(),/only once/);
}
{
  const f=fixture();f.warm();f.api.start();
  for(const name of ['getShaderParameter','getProgramParameter']) {
    const before=f.calls.length,reads=f.reads;
    assert.equal(f.gl[name]({},0x8b84),f.returned); // INFO_LOG_LENGTH is outside the selected status.
    assert.equal(f.calls.length,before+1);assert.equal(f.reads,reads);
  }
  f.throwName='linkProgram';const before=f.calls.length;
  assert.throws(()=>f.gl.linkProgram({}),e=>e===f.thrown);
  assert.equal(f.calls.length,before+1);f.api.stop();
  assert.equal(f.api.capture().rows[0].success,0);f.api.restore();
}
{
  const f=fixture();f.warm();f.api.start();f.nest=true;f.gl.texImage2D({});f.api.stop();
  const rows=plain(f.api.capture()).rows;
  assert.equal(rows.length,2);assert.equal(rows[0].method,0);assert.equal(rows[1].method,3);
  assert.ok(rows[0].start<=rows[1].start&&rows[0].end>=rows[1].end);f.api.restore();
}
{
  const f=fixture();f.warm();f.api.start();const before=f.calls.length;
  for(let i=0;i<8193;i++)assert.equal(f.gl.texImage2D({}),f.returned);
  const stop=f.api.stop(),capture=f.api.capture();
  assert.equal(f.calls.length-before,8193);assert.equal(stop.count,8192);assert.equal(stop.dropped,1);
  assert.equal(capture.rows.length,8192);assert.equal(capture.counts[0],8193);f.api.restore();
}
for(const config of [{missing:'linkProgram'},{locked:true}]) {
  const f=fixture(config);assert.ok(f.api.ready().error_mask&2);assert.throws(()=>f.api.start(),/installation/);
  for(const name of METHODS)assert.equal(f.gl[name],f.native[name]);
}
{
  const f=fixture();assert.throws(()=>f.api.start(),/not exercised/);f.warm();
  f.canvas.otherContext={};assert.equal(f.canvas.getContext('webgl2'),f.canvas.otherContext);
  assert.throws(()=>f.api.start(),/installation/);
}
{
  // Full observer lifecycle with both wrappers, a census and one simulated 60 s window.
  const f=fixture();f.warm();
  function MainLoop_runner(){f.gl.drawArrays();f.gl.texImage2D({});}
  f.sandbox.requestAnimationFrame(MainLoop_runner);f.queued.shift()(0);
  const o=f.sandbox.__webkitMovingStudy,census=o.census(),draw=f.gl.drawArrays;
  f.sandbox.requestAnimationFrame(MainLoop_runner);f.queued.shift()(1);
  assert.equal((await census).all_restored,true);assert.equal(f.gl.drawArrays,draw);
  f.events.keydown({code:'ArrowDown',isTrusted:true,repeat:false});f.events.keydown({code:'Space',isTrusted:true,repeat:false});
  f.clock=200;const before=f.api.clock();f.api.start();const pending=o.begin();
  for(let i=0;i<=3600;i++){f.clock=200+i*1000/60;f.sandbox.requestAnimationFrame(MainLoop_runner);f.queued.shift()(f.clock);}
  const raw=plain(await pending);f.api.stop();const after=f.api.clock(),capture=plain(f.api.capture());
  const analysis=analyzeResources(capture,raw,{before,after});
  assert.equal(capture.count,3601);assert.ok(Math.abs(analysis.selected_in_callbacks_union_ms-7202)<1e-6);
  assert.equal(f.api.restore().get_context_restored_to_observer,true);assert.equal(o.restore().raf_restored,true);
  assert.equal(f.sandbox.requestAnimationFrame,f.raf);
}
const raw={metric:'engine_loop_callback_cadence',count:3601,seconds:60,rows:Array.from({length:3601},(_,i)=>({start:100+i*1000/60,end:108+i*1000/60,raf:i*1000/60}))};
const capture={schema:1,clock:'window.performance.now',time_origin:1234,capacity:8192,count:3,dropped:0,error_mask:0,started_ms:90,stopped_ms:60120,
  methods:METHODS,counts:[1,0,0,1,1,0,0],rows:[{method:0,start:100.5,end:106.5,success:1},{method:3,start:102,end:104,success:1},{method:4,start:110,end:112,success:1}],
  start_receipt:{clock:'window.performance.now',time_origin:1234,start_ms:90,capacity:8192,methods:METHODS,untimed_counts_before:[1,0,0,1,0,1,0]}};
const clocks={before:{clock:'window.performance.now',time_origin:1234,now_ms:80},after:{clock:'window.performance.now',time_origin:1234,now_ms:60130}};
const a=analyzeResources(capture,raw,clocks);
assert.equal(a.window_selected_union_ms,8);assert.equal(a.selected_in_callbacks_union_ms,6);assert.equal(a.selected_outside_callbacks_ms,2);
assert.equal(a.callbacks[0].outside_selected_calls_ms,2);assert.equal(a.per_method[0].inclusive_ms,6);
const zero=structuredClone(capture);zero.rows=[];zero.count=0;zero.counts=METHODS.map(()=>0);
assert.equal(analyzeResources(zero,raw,clocks).window_selected_union_ms,0);
for(const mutate of [c=>c.dropped=1,c=>c.rows[0].success=0,c=>c.rows[0].end=NaN,c=>c.counts[0]++,c=>c.start_receipt.untimed_counts_before[0]=0,c=>c.stopped_ms=200]) {
  const c=structuredClone(capture);mutate(c);assert.throws(()=>analyzeResources(c,raw,clocks));
}
assert.throws(()=>analyzeResources(capture,raw,{...clocks,after:{...clocks.after,time_origin:1235}}),/clock/);
console.log('WEBKIT_RESOURCE_FORWARDING_RESTORATION_PARSER_CHECKS_OK');
