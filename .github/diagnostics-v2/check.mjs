import vm from 'node:vm';import fs from 'node:fs';import assert from 'node:assert/strict';
let now=0;const context={window:{},performance:{now:()=>now},setTimeout:()=>1,clearTimeout(){},console};context.globalThis=context;
vm.runInNewContext(fs.readFileSync('tools/session-diagnostics.js','utf8'),context);
const d=context.window.everDeeperDiagnostics;
assert.equal(d.active,false);d.start();
const original=function(){now+=4;return 17};const gl={getExtension:()=>null,drawArrays:original};
for(let i=0;i<60;i++){now+=i===40?100:10;d.before(gl,{ctx:{state:'running'},sampleNodes:new Map(),samples:new Map()},{buffer:{byteLength:64*1048576}});now+=i===20?60:2;assert.equal(gl.drawArrays(),17);d.after();}
const s=d.snapshot();assert.equal(s.callback_ms[0],60);assert.equal(s.callback_ms[3],64);assert.equal(s.outside_ms[3],100);assert.equal(s.instrumented_ms[0],2);assert.equal(s.control_ms[0],58);assert.equal(s.gl.drawArrays[0],2);assert.equal(s.gl.drawArrays[1],8);assert.equal(s.gpu_ms,null);assert.equal(s.capabilities.gpu_timer,'unavailable');assert.equal(s.wasm_mib,64);assert(s.worst.some(x=>x[2]===64));assert(s.worst.some(x=>x[3]===100));
d.stop();assert.equal(gl.drawArrays,original);assert.equal(d.active,false);assert.equal(d.snapshot(),null);
// Query completion is asynchronous, rejected on disjoint, never waited for.
let ready=false,disjoint=false,deleted=0,current=null,query=0;
const g={...gl,TIME_ELAPSED_EXT:1,CURRENT_QUERY:2,QUERY_RESULT_AVAILABLE:3,QUERY_RESULT:4,getExtension:()=>({TIME_ELAPSED_EXT:1,GPU_DISJOINT_EXT:5}),isContextLost:()=>false,getParameter:()=>disjoint,getQuery:()=>current,createQuery:()=>++query,beginQuery:(t,q)=>{current=q},endQuery:()=>{current=null},deleteQuery:()=>deleted++,getQueryParameter:(q,p)=>p===3?ready:5000000};
d.start();for(let i=0;i<31;i++){now+=16;d.before(g,{},null);now+=2;d.after();}ready=true;for(let i=0;i<16;i++){now+=16;d.before(g,{},null);d.after();}const good=d.snapshot();assert.equal(good.gpu_ms[1],5);assert(deleted>0);
ready=false;for(let i=0;i<30;i++){now+=16;d.before(g,{},null);d.after();}disjoint=true;for(let i=0;i<16;i++){now+=16;d.before(g,{},null);d.after();}const bad=d.snapshot();assert.equal(bad.gpu_ms,null);assert(bad.gpu_rejected>0);d.stop();assert.equal(current,null);
console.log('DIAGNOSTIC_ATTRIBUTION_AND_QUERY_LIFECYCLE_PASS');
