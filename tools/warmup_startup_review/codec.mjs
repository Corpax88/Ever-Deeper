import { createHash } from 'node:crypto';
export const hash = bytes => createHash('sha256').update(bytes).digest('hex');
// Read-only subset of Godot 4.7.2 var_to_bytes. Never constructs Objects.
export function decodeSave(bytes) {
  const b = Buffer.from(bytes);
  if (b.length < 52 || b.readUInt32LE(0) !== 0x52445645 || b.readUInt32LE(4) !== 3 ||
      b.readUInt32LE(8) !== b.length - 44 || hash(b.subarray(44)) !== b.subarray(12,44).toString('hex')) throw Error('Save envelope/checksum invalid');
  let p = 44, nodes = 0;
  const need = n => { if (n < 0 || p + n > b.length) throw Error('Truncated Variant'); };
  const u32 = () => { need(4); const v=b.readUInt32LE(p); p+=4; return v; };
  const string = () => { const n=u32(); need((n+3)&~3); const v=b.subarray(p,p+n).toString('utf8'); p+=(n+3)&~3; return v; };
  const containerType = k => { if (k === 1) { if (u32() === 24) throw Error('Object type refused'); } else if (k !== 0) throw Error('Object/script container refused'); };
  function read(depth=0) {
    if (depth>100 || ++nodes>1000000) throw Error('Variant bounds');
    const h=u32(), t=h&255, wide=!!(h&65536);
    if (t===0) return null;
    if (t===1) return u32()!==0;
    if (t===2) { need(wide?8:4); const v=wide?Number(b.readBigInt64LE(p)):b.readInt32LE(p); p+=wide?8:4; if(!Number.isSafeInteger(v)) throw Error('Unsafe integer'); return v; }
    if (t===3) { need(wide?8:4); const v=wide?b.readDoubleLE(p):b.readFloatLE(p); p+=wide?8:4; if(!Number.isFinite(v)) throw Error('Nonfinite number'); return v; }
    if (t===4 || t===21) return string();
    if (t===27) {
      containerType((h>>>16)&3); containerType((h>>>18)&3);
      const n=u32()&0x7fffffff, value=Object.create(null);
      if(n>100000) throw Error('Dictionary bound');
      for(let i=0;i<n;i++) { const k=read(depth+1); if(typeof k!=='string' || Object.hasOwn(value,k)) throw Error('Unexpected/duplicate dictionary key'); value[k]=read(depth+1); }
      return value;
    }
    if (t===28) {
      containerType((h>>>16)&3); const n=u32()&0x7fffffff;
      if(n>100000) throw Error('Array bound');
      return Array.from({length:n},()=>read(depth+1));
    }
    if (t===34) { const n=u32(); if(n>100000) throw Error('String-array bound'); return Array.from({length:n},()=>string().replace(/\0$/,'')); }
    throw Error('Unsupported Variant type '+t+' at '+(p-4));
  }
  const result=read();
  if(p!==b.length || result.schema!=='ever_deeper_run_state' || result.version!==3 || !result.state) throw Error('Save document/trailing bytes invalid');
  return result;
}
export function summarize(raw) {
  if(raw.metric!=='engine_loop_callback_cadence' || raw.error || raw.count<3 ||
     raw.rows.length!==raw.count || raw.seconds<60 || raw.seconds>70) throw Error('Incomplete real-time cadence receipt');
  const values=raw.rows.slice(1).map((row,i)=>row.start-raw.rows[i].start);
  if(values.some(x=>!Number.isFinite(x)||x<=0)) throw Error('Nonmonotonic frame evidence');
  const stats=xs=>{const sorted=[...xs].sort((a,b)=>a-b), total=xs.reduce((a,b)=>a+b,0);return {intervals:xs.length,total_ms:total,cadence_hz:xs.length*1000/total,p95_ms:sorted[Math.ceil(xs.length*.95)-1],p99_ms:sorted[Math.ceil(xs.length*.99)-1],max_ms:sorted.at(-1)};};
  const windows=[0,30000].map(start=>stats(values.filter((v,i)=>{const t=raw.rows[i+1].start-raw.rows[0].start;return t>start&&t<=start+30000;})));
  if(windows.some(x=>x.intervals<2)) throw Error('Missing 30-second window');
  const all=stats(values);
  return {metric:raw.metric,all,windows,meets_callback_budget:windows.every(x=>x.cadence_hz>=50&&x.p95_ms<=20),
    rendered_fps_verified:false,limit:'Callback cadence is not a presentation counter; callback duration includes synchronous waits.'};
}

