import assert from 'node:assert/strict';
import { analyzePhases } from './phases.mjs';
const fields=['kind','start_usec','end_usec','process_frame','physics_frame','depth_before','depth_after','window_before','window_after','requested_depth','result','parent','end_process_frame','end_physics_frame','error_code'];
const capture={schema:1,diagnostic_only:true,fields,active:false,dropped:0,integrity_errors:0,open_parent:-1,capacity:512,count:3,started_usec:900000,stopped_usec:1200000,rows:[
 [2,1000000,1100000,10,10,13,13,11,12,12,1,-1,10,10,0],
 [1,1010000,1080000,10,10,13,13,11,12,12,1,0,10,10,0],
 [3,1120000,1125000,11,11,13,13,12,12,-1,1,-1,11,11,0],
]};
const pair=tick=>({js_before:tick/1000+100,js_after:tick/1000+100.02,receipt:{tick_usec:tick,active:false}});
const clocks={before:Array.from({length:5},()=>pair(900000)),after:Array.from({length:5},()=>pair(1200000))};
const raw={started:1099,rows:[{start:1099,end:1201},{start:1202,end:1230},{start:1240,end:1245}]};
const report=analyzePhases(capture,clocks,raw);
assert.ok(Math.abs(report.all_phase_union_ms-105)<1e-6); // Nested70ms cannot inflate total to175ms.
assert.ok(Math.abs(report.callbacks[0].phase_union_ms-100)<1e-6);
assert.ok(Math.abs(report.callbacks[1].phase_union_ms-5)<1e-6);
assert.equal(report.callbacks[2].phase_union_ms,0);
assert.deepEqual(report.callbacks[0].spans,[0,1]);
assert.equal(report.kinds[1].sum_inclusive_ms,70);
assert.throws(()=>analyzePhases({...capture,dropped:1},clocks,raw));
assert.throws(()=>analyzePhases({...capture,active:true},clocks,raw));
const wrong=structuredClone(capture);wrong.rows[1][2]=1100001;
assert.throws(()=>analyzePhases(wrong,clocks,raw));
const drift=structuredClone(clocks);drift.after[0].js_before+=10;drift.after[0].js_after+=10;
assert.throws(()=>analyzePhases(capture,drift,raw),/brackets disagree/);
console.log('HITCH_PHASE_PARSER_CHECKS_OK nested_union=105ms unmatched_preserved=1 clock_disagreement_rejected=1');
