// Node-only post-window decoding. This module never runs in the page or calls GL.
import { createHash } from 'node:crypto';
export const CAPS={shaders:1024,programs:512,sources:1024,events:8192,max_source_code_units:262144,total_source_code_units:16777216};
export const METADATA_METHODS=['shaderSource','attachShader'];
const KINDS=['source','compile','attach','link','shader_status','program_status'];
const METHOD_KIND={3:1,4:3,5:4,6:5};
const fail=message=>{throw Error('Shader identity: '+message);};
const integer=(value,min,max)=>Number.isInteger(value)&&value>=min&&value<=max;
const digest=(text,encoding='utf8')=>createHash('sha256').update(text,encoding).digest('hex');
export function analyzeIdentity(capture) {
  const data=capture.identity,start=capture.start_receipt?.identity_at_start;
  if(!data||data.schema!==1||data.tracking!==false||data.error_mask!==0||data.dropped!==0||capture.error_mask!==0||capture.dropped!==0||
     JSON.stringify(data.caps)!==JSON.stringify(CAPS)||JSON.stringify(data.metadata_methods)!==JSON.stringify(METADATA_METHODS))fail('recorder incomplete or unsupported');
  for(const [name,cap]of [['shader_count',CAPS.shaders],['program_count',CAPS.programs],['source_count',CAPS.sources],['event_count',CAPS.events]]) {
    if(!integer(data[name],1,cap)||!start||!integer(start[name],1,data[name]))fail('missing/bounded '+name);
  }
  if(data.sources.length!==data.source_count||data.events.length!==data.event_count||!integer(data.source_code_units,0,CAPS.total_source_code_units))fail('storage counts');
  let units=0;
  const sources=data.sources.map((source,index)=>{
    if(source.id!==index+1||!integer(source.shader,1,data.shader_count)||typeof source.glsl!=='string'||source.code_units!==source.glsl.length||source.code_units>CAPS.max_source_code_units)fail('malformed original source');
    units+=source.code_units;
    return {id:source.id,shader:source.shader,code_units:source.code_units,utf8_bytes:Buffer.byteLength(source.glsl,'utf8'),
      sha256_utf8:digest(source.glsl),sha256_utf16le:digest(source.glsl,'utf16le'),
      raw_define_undef_lines:source.glsl.match(/^[\t ]*#(?:define|undef)\b[^\r\n]*/gm)||[]};
  });
  if(units!==data.source_code_units)fail('source storage sum');
  const latestSource=new Map(),compiledSource=new Map(),attached=new Map(),latestLink=new Map();
  const seenShader=new Set(),seenProgram=new Set(),seenSources=new Set(),seenRows=new Set();
  const programLinks=[],timedAssociations=[];
  function useId(id,program) {
    const seen=program?seenProgram:seenShader,max=program?data.program_count:data.shader_count;
    if(!integer(id,1,max))fail('object ID out of range');
    if(!seen.has(id)) {if(id!==seen.size+1)fail('object IDs not dense in first-observed order');seen.add(id);}
  }
  function shaderVersion(shader) {
    const source=compiledSource.get(shader);
    if(!source)fail('compiled shader has no preceding original shaderSource');
    return {shader,source,sha256_utf8:sources[source-1].sha256_utf8,sha256_utf16le:sources[source-1].sha256_utf16le};
  }
  for(let index=0;index<data.events.length;index++) {
    const event=data.events[index],number=index+1;
    if(!integer(event.kind,0,KINDS.length-1)||event.success!==1||!integer(event.other,0,Math.max(CAPS.sources,CAPS.shaders))||
       !integer(event.timed_row,-1,capture.count-1)||event.during_window!==(index>=start.event_count?1:0))fail('malformed event or startup/window boundary');
    const isProgram=[2,3,5].includes(event.kind);useId(event.object,isProgram);
    if(event.kind!==0&&event.kind!==2&&event.other!==0)fail('unexpected associated argument');
    let association;
    if(event.kind===0) {
      if(event.other!==seenSources.size+1||event.other>sources.length||sources[event.other-1].shader!==event.object)fail('source version association');
      seenSources.add(event.other);latestSource.set(event.object,event.other);
    }else if(event.kind===1) {
      const source=latestSource.get(event.object);if(!source)fail('compile without a captured source');
      compiledSource.set(event.object,source);association={shader:shaderVersion(event.object)};
    }else if(event.kind===2) {
      useId(event.other,false);
      if(!attached.has(event.object))attached.set(event.object,new Set());
      attached.get(event.object).add(event.other);
    }else if(event.kind===3) {
      const shaders=attached.get(event.object);
      if(!shaders||shaders.size!==2)fail('link does not have the original two attached shader objects');
      const versions=Array.from(shaders,shaderVersion).sort((a,b)=>a.shader-b.shader);
      const link={event:number,program:event.object,during_window:!!event.during_window,shaders:versions,
        source_pair_sha256:digest(JSON.stringify(versions.map(x=>x.sha256_utf16le).sort())),
        previous_link_event:latestLink.get(event.object)?.event??null};
      programLinks.push(link);latestLink.set(event.object,link);association={link};
    }else if(event.kind===4)association={shader:shaderVersion(event.object)};
    else {
      const link=latestLink.get(event.object);if(!link)fail('LINK_STATUS without original attachment/link history');
      association={link};
    }
    if(event.timed_row>=0) {
      const row=capture.rows[event.timed_row];
      if(!row||seenRows.has(event.timed_row)||!event.during_window||row.success!==1||row.identity_event!==number||METHOD_KIND[row.method]!==event.kind)fail('timed span/event binding');
      seenRows.add(event.timed_row);
      timedAssociations.push({row:event.timed_row,event:number,method:row.method,kind:KINDS[event.kind],
        start_ms:row.start,end_ms:row.end,host_call_ms:row.end-row.start,...association});
    }else if(event.during_window&&[1,3,4,5].includes(event.kind))fail('timed shader/program call missing raw span');
    if(number===start.event_count&&(seenShader.size!==start.shader_count||seenProgram.size!==start.program_count||seenSources.size!==start.source_count))fail('startup identity count mismatch');
  }
  if(seenShader.size!==data.shader_count||seenProgram.size!==data.program_count||seenSources.size!==data.source_count)fail('final identity count mismatch');
  capture.rows.forEach((row,index)=>{
    if(Object.hasOwn(METHOD_KIND,row.method)){if(!seenRows.has(index))fail('shader/program span lacks identity');}
    else if(row.identity_event!==0)fail('texture row gained unrelated identity');
  });
  const pairs=new Map();
  for(const link of programLinks) {
    if(!pairs.has(link.source_pair_sha256))pairs.set(link.source_pair_sha256,[]);
    pairs.get(link.source_pair_sha256).push({program:link.program,event:link.event,during_window:link.during_window});
  }
  return {schema:1,shader_count:data.shader_count,program_count:data.program_count,event_count:data.event_count,
    source_code_units:data.source_code_units,sources,program_links:programLinks,timed_associations:timedAssociations,
    timed_program_status:timedAssociations.filter(x=>x.kind==='program_status'),
    repeated_source_pairs:Array.from(pairs,([source_pair_sha256,links])=>({source_pair_sha256,links})).filter(x=>x.links.length>1),
    overhead_bearing:true,extra_gl_queries:0,texture_identity_collected:false,shader_stage_queried:false,
    limits:'IDs describe observed JavaScript shader/program object identity only. GLSL and raw define/undef lines are original text, not a resolved variant/material name. Compiled source versions are snapshotted at the original link. Host-call wall time is not exclusive compiler/GPU time. Metadata bookkeeping and retained strings can affect timing/GC. No warmup or performance benefit is established.'};
}
