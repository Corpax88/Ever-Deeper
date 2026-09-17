import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { decodeSave, summarize } from './codec.mjs';
import vm from 'node:vm';
const here=new URL('.',import.meta.url);
const row=(start)=>({start,end:start+2,raf:start});
const good={metric:'engine_loop_callback_cadence',count:3601,seconds:60,rows:Array.from({length:3601},(_,i)=>row(i*1000/60))};
assert.ok(summarize(good).all.cadence_hz>59.999);
assert.throws(()=>summarize({...good,seconds:59.99}),/Incomplete/);
const bad=structuredClone(good);bad.rows[100].start=bad.rows[99].start;assert.throws(()=>summarize(bad),/Nonmonotonic/);
let clock=0,queued=[],listener={},draws=0;
const gl={canvas:{id:'canvas',width:1696,height:780,getBoundingClientRect:()=>({width:848,height:390})},drawingBufferWidth:1696,drawingBufferHeight:780,
 getParameter:()=> 'mock',drawArrays(){draws++;},drawElements(){draws++;},drawArraysInstanced(){draws++;},drawElementsInstanced(){draws++;}};
gl.canvas.addEventListener=()=>{};
function Canvas(){} Canvas.prototype.getContext=function(){return gl;};Canvas.prototype.addEventListener=()=>{};
const original=cb=>{queued.push(cb);return queued.length;};
const sandbox={Float64Array,performance:{now:()=>clock},HTMLCanvasElement:Canvas,devicePixelRatio:2,document:{hidden:false,visibilityState:'visible',addEventListener(){}},requestAnimationFrame:original,addEventListener:(n,f)=>{listener[n]=f;}};
sandbox.window=sandbox;
vm.createContext(sandbox);vm.runInContext(await readFile(new URL('observer.js',here),'utf8'),sandbox);
const c=new sandbox.HTMLCanvasElement();c.id='canvas';c.getContext('webgl2');
function MainLoop_runner(){gl.drawArrays();}
sandbox.requestAnimationFrame(MainLoop_runner);queued.shift()(0);
const api=sandbox.__webkitMovingStudy;
const census=api.census();const old=gl.drawArrays;
sandbox.requestAnimationFrame(MainLoop_runner);queued.shift()(10);
assert.equal((await census).rows[0].draw_calls,1);assert.equal(gl.drawArrays,old);
listener.keydown({code:'ArrowDown',isTrusted:true,repeat:false});listener.keydown({code:'Space',isTrusted:true,repeat:false});
const measurement=api.begin();
for(let i=0;i<=3600;i++){clock=i*1000/60;sandbox.requestAnimationFrame(MainLoop_runner);queued.shift()(clock);}
const raw=await measurement;assert.equal(raw.count,3601);assert.equal(raw.seconds,60);assert.equal(raw.keys_at_end.Space,true);
assert.equal(api.restore().raf_restored,true);assert.equal(sandbox.requestAnimationFrame,original);
if(process.argv[2]) {
 const bytes=await readFile(process.argv[2]);const document=decodeSave(bytes);
 console.log('ACTUAL_SAVE_DECODED '+JSON.stringify({schema:document.schema,version:document.version,seed:document.state.world_seed,depth:document.state.endless_descent.current_depth}));
 const corrupted=Buffer.from(bytes);corrupted[corrupted.length-1]^=1;assert.throws(()=>decodeSave(corrupted),/checksum/);
 if(process.argv[3]){const native=JSON.parse(await readFile(process.argv[3],'utf8'));assert.deepEqual(JSON.parse(JSON.stringify(document)),native);}
}
console.log('WEBKIT_STUDY_PARSER_OBSERVER_CHECKS_OK');
