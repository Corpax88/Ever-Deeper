import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { analyzeIdentity,CAPS,METADATA_METHODS } from './identity.mjs';
import { fixture,ALL_METHODS } from './fixture.mjs';
const plain=x=>JSON.parse(JSON.stringify(x));
const close=f=>{f.api.stop();return plain(f.api.capture());};
let validCapture;
{
  const f=fixture();f.warm();f.api.start();
  const text=['#define VERTEX 1\n// æ \ud83e\udd16\nvoid main(){}','#define FRAGMENT 1\n#undef OLD\nvoid main(){}'];
  const beforeCalls=f.calls.length,beforeReads=f.reads;
  const p=f.pair(text);f.gl.texImage2D({});
  assert.equal(f.calls.length-beforeCalls,11); // All eleven original calls, no added query.
  assert.equal(f.reads-beforeReads,14); // Seven selected calls; source/attach add no clock read.
  validCapture=close(f);const a=analyzeIdentity(validCapture);
  assert.equal(a.program_count,2);assert.equal(a.shader_count,4);assert.equal(a.sources.length,4);
  assert.equal(a.timed_program_status.length,1);assert.equal(a.timed_program_status[0].link.program,2);
  assert.deepEqual(a.sources[2].raw_define_undef_lines,['#define VERTEX 1']);
  assert.equal(validCapture.identity.sources[2].glsl,text[0]);
  assert.equal(a.sources[2].sha256_utf16le,createHash('sha256').update(text[0],'utf16le').digest('hex'));
  const frozen=JSON.stringify(validCapture.identity),count=f.calls.length;
  f.gl.shaderSource(p.shaders[0],'changed after stop');f.gl.linkProgram(p.program);
  assert.equal(f.calls.length,count+2);assert.equal(JSON.stringify(plain(f.api.capture()).identity),frozen);
  assert.equal(f.api.restore().method_count,9);
}
{
  // A source assignment without compile must not rewrite an existing compiled
  // version; relinking the same program snapshots the then-compiled sources.
  const f=fixture(),p=f.warm();f.api.start();
  f.gl.shaderSource(p.shaders[0],'#define NEW_SOURCE\nvoid main(){}');
  f.gl.linkProgram(p.program);f.gl.getProgramParameter(p.program,0x8b82);
  f.gl.compileShader(p.shaders[0]);f.gl.getShaderParameter(p.shaders[0],0x8b81);
  f.gl.linkProgram(p.program);f.gl.getProgramParameter(p.program,0x8b82);
  f.pair(['#define NEW_SOURCE\nvoid main(){}','#define FRAGMENT\nvoid main(){}']);
  const a=analyzeIdentity(close(f)),q=a.timed_program_status;
  assert.equal(q.length,3);assert.equal(q[0].link.program,1);assert.equal(q[1].link.program,1);assert.equal(q[2].link.program,2);
  assert.equal(q[0].link.shaders[0].source,1);assert.equal(q[1].link.shaders[0].source,3);
  assert.notEqual(q[0].link.source_pair_sha256,q[1].link.source_pair_sha256);
  assert.equal(q[1].link.source_pair_sha256,q[2].link.source_pair_sha256);
  assert.ok(q[0].link.previous_link_event<q[0].link.event);
  assert.equal(a.repeated_source_pairs.length,2);f.api.restore();
}
for(const name of METADATA_METHODS) {
  const f=fixture();f.warm();f.api.start();
  const receiver={},args=[{},name==='shaderSource'?'exact original string':{},Symbol('tail'),undefined];
  const before=f.calls.length,reads=f.reads;
  assert.equal(Reflect.apply(f.gl[name],receiver,args),f.returned);
  assert.equal(f.calls.length,before+1);assert.equal(f.reads,reads);
  assert.equal(f.calls.at(-1).receiver,receiver);
  args.forEach((arg,index)=>assert.equal(f.calls.at(-1).args[index],arg));
  f.throwName=name;
  assert.throws(()=>Reflect.apply(f.gl[name],receiver,args),error=>error===f.thrown);
  assert.equal(f.calls.length,before+2);assert.equal(f.reads,reads);
  assert.equal(close(f).identity.events.at(-1).success,0);f.api.restore();
}
{
  const f=fixture(),p=f.warm();f.api.start();let coercions=0;
  const original={toString(){coercions++;return 'native coercion';}};
  assert.equal(f.gl.shaderSource(p.shaders[0],original),f.returned);
  assert.equal(coercions,1); // Only the original native/mock implementation coerces.
  const c=close(f);assert.ok(c.identity.error_mask&64);assert.ok(c.error_mask&64);
  assert.throws(()=>analyzeIdentity(c),/incomplete/);f.api.restore();
}
const overflows=[
  {bit:1,calls:CAPS.shaders+1,run:(f,p,i)=>f.gl.compileShader({})},
  {bit:2,calls:CAPS.programs+1,run:(f,p,i)=>f.gl.linkProgram({})},
  {bit:4,calls:CAPS.sources+1,run:(f,p,i)=>f.gl.shaderSource(p.shaders[0],'a')},
  {bit:8,calls:CAPS.events+1,run:(f,p,i)=>f.gl.getShaderParameter(p.shaders[0],0x8b81)},
  {bit:16,calls:1,run:(f,p,i)=>f.gl.shaderSource(p.shaders[0],'x'.repeat(CAPS.max_source_code_units+1))},
  {bit:32,calls:65,run:(f,p,i)=>f.gl.shaderSource(p.shaders[0],'x'.repeat(CAPS.max_source_code_units))},
];
for(const config of overflows) {
  const f=fixture(),p=f.warm(),before=f.calls.length;
  for(let i=0;i<config.calls;i++)assert.equal(config.run(f,p,i),f.returned);
  assert.equal(f.calls.length-before,config.calls); // Overflow never drops an original call.
  const ready=f.api.ready();assert.ok(ready.identity.error_mask&config.bit);assert.ok(ready.error_mask&64);
  assert.throws(()=>f.api.start(),/installation/);
  const c=close(f);assert.ok(c.identity.dropped>0);assert.ok(c.identity.event_count<=CAPS.events);
  assert.ok(c.identity.source_count<=CAPS.sources);assert.ok(c.identity.source_code_units<=CAPS.total_source_code_units);
  assert.throws(()=>analyzeIdentity(c),/incomplete/);f.api.restore();
}
{
  const f=fixture(),p=f.warm();f.api.start();
  for(let i=0;i<CAPS.events;i++)f.gl.getShaderParameter(p.shaders[0],0x8b81);
  const c=close(f);assert.ok(c.identity.error_mask&8);assert.ok(c.error_mask&64);
  assert.throws(()=>analyzeIdentity(c),/incomplete/);f.api.restore();
}
for(const name of METADATA_METHODS) {
  const f=fixture({missing:name});assert.ok(f.api.ready().error_mask&2);
  assert.throws(()=>f.api.start(),/installation/);
  ALL_METHODS.forEach((method,index)=>{
    assert.equal(f.gl[method],f.native[method]);
    assert.deepEqual(Object.getOwnPropertyDescriptor(f.gl,method),f.nativeDescriptors[index]);
  });
}
{
  const f=fixture();f.warm();f.gl.attachShader=()=>{};
  assert.throws(()=>f.api.start(),/installation/);
}
for(const mutate of [
  c=>{c.identity.sources[0].code_units++;},
  c=>{c.identity.sources[0].shader=4;},
  c=>{c.identity.events[0].other=2;},
  c=>{c.identity.events[1].kind=3;},
  c=>{c.start_receipt.identity_at_start.event_count++;},
  c=>{c.rows.find(x=>x.method===6).identity_event=0;},
  c=>{c.rows.find(x=>x.method===0).identity_event=1;},
  c=>{c.identity.events.find(x=>x.kind===2).other=0;},
  c=>{c.identity.tracking=true;},
]) {
  const c=plain(validCapture);mutate(c);assert.throws(()=>analyzeIdentity(c),/Shader identity/);
}
console.log('WEBKIT_SHADER_IDENTITY_FORWARDING_BOUNDS_ASSOCIATIONS_CHECKS_OK');
