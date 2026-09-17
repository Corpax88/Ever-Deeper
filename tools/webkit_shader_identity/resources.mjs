export const METHODS=['texImage2D','compressedTexImage2D','texStorage2D','compileShader',
  'linkProgram','getShaderParameter','getProgramParameter'];
const fail=message=>{throw Error(message);};
const finite=n=>Number.isFinite(n);
function union(spans) {
  const sorted=spans.filter(([a,b])=>b>a).sort((a,b)=>a[0]-b[0]);
  let total=0,start=0,end=0,open=false;
  for(const [a,b]of sorted){if(!open){start=a;end=b;open=true;}else if(a<=end)end=Math.max(end,b);else{total+=end-start;start=a;end=b;}}
  return total+(open?end-start:0);
}
export function analyzeResources(capture,raw,clocks) {
  if(capture.schema!==1||capture.clock!=='window.performance.now'||capture.capacity!==8192||capture.dropped!==0||capture.error_mask!==0||
     !Number.isInteger(capture.count)||capture.count<0||capture.count>capture.capacity||capture.rows.length!==capture.count||
     JSON.stringify(capture.methods)!==JSON.stringify(METHODS)||capture.counts.length!==METHODS.length)fail('Incomplete resource capture');
  if(raw.metric!=='engine_loop_callback_cadence'||raw.error||raw.count!==raw.rows.length||raw.count<3||raw.seconds<60||raw.seconds>70)fail('Incomplete observer window');
  if(!clocks||![clocks.before,clocks.after].every(x=>x.clock==='window.performance.now'&&finite(x.now_ms)&&x.time_origin===capture.time_origin)||!finite(capture.time_origin)||
     !finite(capture.started_ms)||!finite(capture.stopped_ms)||clocks.before.now_ms>capture.started_ms||capture.stopped_ms>clocks.after.now_ms||
     capture.started_ms>raw.rows[0].start||capture.stopped_ms<raw.rows.at(-1).end)fail('Shared clock/window binding failed');
  const startup=capture.start_receipt;
  if(!startup||startup.clock!==capture.clock||startup.time_origin!==capture.time_origin||startup.start_ms!==capture.started_ms||
     startup.capacity!==capture.capacity||JSON.stringify(startup.methods)!==JSON.stringify(METHODS)||startup.untimed_counts_before.length!==METHODS.length||
     !startup.untimed_counts_before.every(n=>Number.isInteger(n)&&n>=0)||
     startup.untimed_counts_before[0]+startup.untimed_counts_before[1]+startup.untimed_counts_before[2]===0||
     startup.untimed_counts_before[3]+startup.untimed_counts_before[4]===0||startup.untimed_counts_before[5]+startup.untimed_counts_before[6]===0)fail('Startup hook non-vacuity failed');
  let previous=-Infinity;
  const counts=METHODS.map(()=>0),perMethod=METHODS.map(name=>({name,calls:0,inclusive_ms:0,max_ms:0}));
  for(const row of capture.rows) {
    if(!Number.isInteger(row.method)||row.method<0||row.method>=METHODS.length||row.success!==1||!finite(row.start)||!finite(row.end)||
       row.start<previous||row.end<row.start||row.start<capture.started_ms||row.end>capture.stopped_ms)fail('Malformed resource span');
    previous=row.start;counts[row.method]++;
    const m=perMethod[row.method];m.calls++;m.inclusive_ms+=row.end-row.start;m.max_ms=Math.max(m.max_ms,row.end-row.start);
  }
  if(JSON.stringify(counts)!==JSON.stringify(capture.counts))fail('Resource counter mismatch');
  previous=-Infinity;
  let previousEnd=-Infinity;
  const callbacks=raw.rows.map((frame,index)=>{
    if(!finite(frame.start)||!finite(frame.end)||frame.start<=previous||frame.end<frame.start||frame.start<previousEnd)fail('Malformed callback');
    previous=frame.start;previousEnd=frame.end;
    const spans=capture.rows.map((row,i)=>({row,i})).filter(({row})=>row.end>frame.start&&row.start<frame.end);
    const covered=union(spans.map(({row})=>[Math.max(row.start,frame.start),Math.min(row.end,frame.end)]));
    return {index,start_ms:frame.start,end_ms:frame.end,relative_start_ms:frame.start-raw.rows[0].start,
      callback_ms:frame.end-frame.start,next_interval_ms:index+1<raw.rows.length?raw.rows[index+1].start-frame.start:null,
      selected_call_union_ms:covered,outside_selected_calls_ms:Math.max(0,frame.end-frame.start-covered),span_indices:spans.map(x=>x.i)};
  });
  const start=raw.rows[0].start,end=raw.rows.at(-1).end;
  const overlap=capture.rows.filter(row=>row.end>start&&row.start<end);
  const callbackUnion=union(raw.rows.map(x=>[x.start,x.end]));
  const selectedUnion=union(overlap.map(row=>[Math.max(start,row.start),Math.min(end,row.end)]));
  const inCallbackUnion=callbacks.reduce((n,x)=>n+x.selected_call_union_ms,0);
  return {schema:1,clock:'same window.performance.now as unchanged observer',time_origin:capture.time_origin,
    overhead_bearing:true,rendered_fps_verified:false,exclusive_gpu_time:false,
    window:{start_ms:start,end_ms:end,seconds:raw.seconds},capacity:capture.capacity,records:capture.count,
    per_method:perMethod,window_selected_union_ms:selectedUnion,callback_union_ms:callbackUnion,
    selected_in_callbacks_union_ms:inCallbackUnion,outside_selected_calls_ms:Math.max(0,callbackUnion-inCallbackUnion),
    selected_outside_callbacks_ms:Math.max(0,selectedUnion-inCallbackUnion),
    spans_outside_window:capture.rows.map((r,i)=>r.end<=start||r.start>=end?i:-1).filter(i=>i>=0),
    callbacks,hitches:callbacks.filter(x=>x.callback_ms>100||x.next_interval_ms>100),
    limits:'Synchronous selected WebGL host-call wall time includes instrumentation and possible validation, driver work or waits. Unwrapped work is unattributed, not simulation or exclusive GPU time. Nested spans use interval unions.'};
}
