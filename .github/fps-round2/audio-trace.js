/* Observational counter only. Init script before AudioWorkletNode creation.
 * No postMessage/cadence/audio-graph changes; use outside normal FPS timings.
 */
(() => {
  if (globalThis.AUDIO_POSITION_AUDIT) return;
  const Native = globalThis.AudioWorkletNode;
  const records = [], listeners = [];
  let active = false, started = 0, label = '', proxy = null;
  function zero(record) { Object.assign(record,{messages:0,first_position:null,last_position:null,nonmonotonic:0,other_messages:0}); }
  if (typeof Native === 'function') {
    proxy = new Proxy(Native, { construct(target,args,newTarget) {
      const node = Reflect.construct(target,args,newTarget);
      if (args[1] === 'godot-position-reporting-processor') {
        const record={id:records.length+1,processor:args[1],context_sample_rate:args[0]?.sampleRate};zero(record);records.push(record);
        const listener=event=>{
          if(!active)return;
          if(event.data?.type!=='position'){record.other_messages++;return;}
          const position=Number(event.data.data);
          if(record.last_position!==null && position<record.last_position)record.nonmonotonic++;
          if(record.first_position===null)record.first_position=position;
          record.last_position=position;record.messages++;
        };
        node.port.addEventListener('message',listener);
        // The engine already sets port.onmessage, which starts this port.
        listeners.push({port:node.port,listener});
      }
      return node;
    }});
    globalThis.AudioWorkletNode=proxy;
  }
  globalThis.AUDIO_POSITION_AUDIT={
    begin(name){label=name;for(const row of records)zero(row);started=performance.now();active=true;},
    end(){const elapsed=performance.now()-started;active=false;const nodes=records.map(row=>({...row,messages_per_second:row.messages*1000/Math.max(1,elapsed)}));return{label,supported:!!proxy,elapsed_ms:elapsed,total_messages:nodes.reduce((s,r)=>s+r.messages,0),nodes,note:'Added passive MessagePort listeners; report cadence and original handlers unchanged. Diagnostic observer cost; not an FPS or audio-time measurement.'};},
    uninstall(){active=false;for(const {port,listener} of listeners)port.removeEventListener('message',listener);if(proxy && globalThis.AudioWorkletNode===proxy)globalThis.AudioWorkletNode=Native;}
  };
})();
