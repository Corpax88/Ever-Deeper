import assert from 'node:assert/strict';

const FIELDS=['kind','start_usec','end_usec','process_frame','physics_frame','depth_before','depth_after','window_before','window_after','requested_depth','result','parent','end_process_frame','end_physics_frame','error_code'];
function union(intervals) {
  const sorted=intervals.filter(([a,b])=>b>a).sort((a,b)=>a[0]-b[0]);let total=0,start=null,end=null;
  for(const [a,b] of sorted){if(start===null){start=a;end=b;}else if(a<=end)end=Math.max(end,b);else{total+=end-start;start=a;end=b;}}
  return total+(start===null?0:end-start);
}
export function analyzePhases(capture,clocks,raw) {
  assert.equal(capture.schema,1);assert.equal(capture.diagnostic_only,true);assert.deepEqual(capture.fields,FIELDS);
  assert.equal(capture.active,false);assert.equal(capture.dropped,0);assert.equal(capture.integrity_errors,0);assert.equal(capture.open_parent,-1);
  assert.equal(capture.count,capture.rows.length);assert.ok(capture.count>0&&capture.count<=capture.capacity);
  assert.equal(clocks.before.length,5);assert.equal(clocks.after.length,5);
  const pairs=[...clocks.before,...clocks.after];
  for(const p of pairs){assert.ok(p.js_after>=p.js_before);assert.ok(p.receipt.tick_usec>0);assert.equal(p.receipt.active,false);}
  // Explicit 0.05ms allowance for browser timestamp quantization, not measured precision.
  const allowance=.05;
  const lower=Math.max(...pairs.map(p=>p.js_before-p.receipt.tick_usec/1000-allowance));
  const upper=Math.min(...pairs.map(p=>p.js_after-p.receipt.tick_usec/1000+allowance));
  assert.ok(upper>=lower,'Paired clock brackets disagree; attribution refused');
  assert.ok(upper-lower<5,'Clock uncertainty too wide');
  const offset=(lower+upper)/2,uncertainty=(upper-lower)/2;
  const spans=capture.rows.map((row,index)=>{
    assert.equal(row.length,FIELDS.length);assert.ok(row.every(Number.isSafeInteger));
    const span=Object.fromEntries(FIELDS.map((field,i)=>[field,row[i]]));
    assert.ok([1,2,3].includes(span.kind));assert.ok(span.end_usec>=span.start_usec);
    assert.ok(span.start_usec>=capture.started_usec&&span.end_usec<=capture.stopped_usec);
    assert.ok(span.parent>=-1&&span.parent<index);assert.equal(span.result,1);assert.equal(span.error_code,0);
    if(span.parent>=0){const parent=capture.rows[span.parent];assert.ok(span.start_usec>=parent[1]&&span.end_usec<=parent[2]);}
    return {...span,index,start_ms:span.start_usec/1000+offset,end_ms:span.end_usec/1000+offset,duration_ms:(span.end_usec-span.start_usec)/1000};
  });
  for(const kind of [1,2,3])assert.ok(spans.some(s=>s.kind===kind),'No real owner event of kind '+kind);
  const callbacks=raw.rows.map((row,index)=>{
    const matching=spans.filter(s=>s.start_ms<row.end&&s.end_ms>row.start);
    const covered=union(matching.map(s=>[Math.max(s.start_ms,row.start),Math.min(s.end_ms,row.end)]));
    return {index,start_relative_ms:row.start-raw.started,callback_ms:row.end-row.start,following_interval_ms:index+1<raw.rows.length?raw.rows[index+1].start-row.start:null,
      spans:matching.map(s=>s.index),phase_union_ms:covered,outside_selected_spans_ms:Math.max(0,row.end-row.start-covered),
      possible_spans:spans.filter(s=>s.start_ms-uncertainty<row.end&&s.end_ms+uncertainty>row.start).map(s=>s.index)};
  });
  const kinds={};for(const kind of [1,2,3]){const own=spans.filter(s=>s.kind===kind);kinds[kind]={count:own.length,sum_inclusive_ms:own.reduce((n,s)=>n+s.duration_ms,0),max_ms:Math.max(...own.map(s=>s.duration_ms))};}
  return {diagnostic_only:true,overhead_bearing:true,exclusive_gpu_time_available:false,clock:{offset_ms:offset,lower_ms:lower,upper_ms:upper,uncertainty_ms:uncertainty,quantization_allowance_ms:allowance,all_pairs:pairs},
    kinds,all_phase_union_ms:union(spans.map(s=>[s.start_ms,s.end_ms])),spans,callbacks,
    slow_callbacks:callbacks.filter(s=>s.callback_ms>20||s.following_interval_ms>33.3),
    limits:['New random run; not a before/after optimization benchmark.','Spans include recorder/wrapper overhead and synchronous waits.','Nested spans use interval unions, never summed as exclusive totals.','No attribution of unspanned time or GPU execution.','Engine callback cadence is not presented FPS.']};
}
