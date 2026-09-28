import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const source = fs.readFileSync(new URL('./sync-candidate.js', import.meta.url), 'utf8');
const STATUS=37140, UNSIGNALED=37144, SIGNALED=37145, COMPLETE=37143, TYPE=37138;
// Independent native oracle: fences belong to one context and generation,
// cannot signal in their creation task, and become ready in a later task.
function environment({install=true, queue=true}={}) {
  let task=0;
  const pending=[], objects=new WeakMap();
  class Canvas {
    listeners=new Map();
    addEventListener(n,f){if(!this.listeners.has(n))this.listeners.set(n,new Set());this.listeners.get(n).add(f);}
    removeEventListener(n,f){this.listeners.get(n)?.delete(f);}
    dispatch(n){for(const f of this.listeners.get(n)||[])f();}
  }
  class Sync {}
  class GL {
    canvas=new Canvas();lost=false;generation=0;calls=0;fences=0;error=0;override=undefined;
    fenceSync(condition,flags){
      if(arguments.length<2)throw new TypeError('2 arguments required');
      this.fences++;
      if(this.lost)return null;
      if(Number(condition)!==COMPLETE||Number(flags)!==0){this.error=1280;return null;}
      const sync=new Sync();objects.set(sync,{owner:this,generation:this.generation,born:task,dead:false});return sync;
    }
    getSyncParameter(sync,pname){
      if(arguments.length<2)throw new TypeError('2 arguments required');
      this.calls++;
      if(this.lost)return null;
      const s=objects.get(sync);
      if(!s||s.owner!==this||s.dead||s.generation!==this.generation){this.error=1282;return null;}
      if(Number(pname)===TYPE)return 37142;
      if(Number(pname)!==STATUS){this.error=1280;return null;}
      if(this.override!==undefined)return this.override;
      return task===s.born?UNSIGNALED:SIGNALED;
    }
    deleteSync(sync){
      if(arguments.length<1)throw new TypeError('1 argument required');
      if(sync===null||this.lost)return;
      const s=objects.get(sync);
      if(!s||s.owner!==this){this.error=1282;return;}
      s.dead=true;
    }
    isContextLost(){return this.lost;}
    getError(){const e=this.error;this.error=0;return e;}
    finish(){} // WebGL must still hide same-task completion.
    lose(event=true){this.lost=true;if(event)this.canvas.dispatch('webglcontextlost');}
    restore(){this.generation++;this.lost=false;this.canvas.dispatch('webglcontextrestored');}
  }
  const original={fence:GL.prototype.fenceSync,get:GL.prototype.getSyncParameter,del:GL.prototype.deleteSync};
  const global={WebGL2RenderingContext:GL};
  if(queue)global.queueMicrotask=f=>pending.push(f);
  const sandbox=vm.createContext(global);
  const load=()=>vm.runInContext(source,sandbox);
  if(install)load();
  return {GL,global,original,load,pending,api:()=>global.EVER_DEEPER_SYNC,
    checkpoint(){while(pending.length)pending.shift()();},
    nextTask(){this.checkpoint();task++;}};
}
let passed=0;
function test(name,run){run();passed++;process.stdout.write(`ok ${passed} - ${name}\n`);}
const fence=gl=>gl.fenceSync(COMPLETE,0);

test('default reference mode preserves native answer and coalesces expiry',()=>{
  const e=environment(),gl=new e.GL(),s=fence(gl);fence(gl);
  assert.equal(gl.getSyncParameter(s,STATUS),UNSIGNALED);
  assert.equal(gl.calls,1);assert.equal(e.pending.length,1);
  assert.equal(e.api().snapshot().nativeFreshUnsignaled,1);assert.equal(e.api().snapshot().hits,0);
});
test('only a current synchronous-burst status may skip native',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);const s=fence(gl);
  gl.finish();assert.equal(gl.getSyncParameter(s,STATUS),UNSIGNALED);assert.equal(gl.calls,0);
  assert.equal(e.api().snapshot().hits,1);assert.equal(gl.fences,1);
  e.nextTask();assert.equal(gl.getSyncParameter(s,STATUS),SIGNALED);assert.equal(gl.calls,1);
});
test('microtask checkpoint conservatively expires before native can signal',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);const s=fence(gl);e.checkpoint();
  assert.equal(gl.getSyncParameter(s,STATUS),UNSIGNALED);assert.equal(gl.calls,1);
  assert.equal(e.api().snapshot().staleChecks,1);
});
test('wrong pname and coercible numeric string remain native',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);const s=fence(gl);
  assert.equal(gl.getSyncParameter(s,TYPE),37142);
  assert.equal(gl.getSyncParameter(s,0),null);assert.equal(gl.getError(),1280);
  assert.equal(gl.getSyncParameter(s,String(STATUS)),UNSIGNALED);assert.equal(gl.calls,3);
});
test('foreign-context lookup preserves error and owner eligibility',()=>{
  const e=environment(),a=new e.GL(),b=new e.GL();e.api().setEnabled(true);const s=fence(a);
  assert.equal(b.getSyncParameter(s,STATUS),null);assert.equal(b.getError(),1282);
  assert.equal(a.getSyncParameter(s,STATUS),UNSIGNALED);assert.equal(a.calls,0);
});
test('successful delete expires status; failed foreign delete does not',()=>{
  const e=environment(),a=new e.GL(),b=new e.GL();e.api().setEnabled(true);const s=fence(a);
  b.deleteSync(s);assert.equal(b.getError(),1282);
  assert.equal(a.getSyncParameter(s,STATUS),UNSIGNALED);a.deleteSync(s);
  assert.equal(a.getSyncParameter(s,STATUS),null);assert.equal(a.getError(),1282);assert.equal(a.calls,1);
});
test('failed fence creation and unknown sync use native errors',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);
  assert.equal(gl.fenceSync(0,0),null);assert.equal(gl.getError(),1280);
  for(const s of [null,undefined,{},42]){assert.equal(gl.getSyncParameter(s,STATUS),null);assert.equal(gl.getError(),1282);}
  assert.equal(e.api().snapshot().hits,0);
});
test('preinstallation sync is always native',()=>{
  const e=environment({install:false}),gl=new e.GL(),s=fence(gl);e.load();e.api().setEnabled(true);
  assert.equal(gl.getSyncParameter(s,STATUS),UNSIGNALED);assert.equal(gl.calls,1);
});
test('context loss before event delivery is checked on a potential hit',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);const s=fence(gl);gl.lose(false);
  assert.equal(gl.getSyncParameter(s,STATUS),null);assert.equal(gl.calls,1);
  assert.equal(e.api().snapshot().lostFallbacks,1);
});
test('restoration invalidates every prior generation, including same-stack simulation',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);const s=fence(gl);gl.lose();gl.restore();
  assert.equal(gl.getSyncParameter(s,STATUS),null);assert.equal(gl.getError(),1282);
  const fresh=fence(gl);assert.equal(gl.getSyncParameter(fresh,STATUS),UNSIGNALED);assert.equal(gl.calls,1);
});
test('mode switches expire pending eligibility',()=>{
  const e=environment(),gl=new e.GL(),s=fence(gl);e.api().setEnabled(true);
  assert.equal(gl.getSyncParameter(s,STATUS),UNSIGNALED);assert.equal(gl.calls,1);
  const next=fence(gl);e.api().setEnabled(false);
  assert.equal(gl.getSyncParameter(next,STATUS),UNSIGNALED);assert.equal(gl.calls,2);
});
test('validation always executes native even when enabled',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);e.api().setValidation(true);const s=fence(gl);
  assert.equal(gl.getSyncParameter(s,STATUS),UNSIGNALED);assert.equal(gl.calls,1);
  const c=e.api().snapshot();assert.equal(c.validationChecks,1);assert.equal(c.validationMismatches,0);assert.equal(c.hits,0);
});
test('any observed mismatch permanently fails closed across toggle and counter reset',()=>{
  for(const unexpected of [SIGNALED,null,123]){
    const e=environment(),gl=new e.GL();gl.override=unexpected;const s=fence(gl);
    assert.equal(gl.getSyncParameter(s,STATUS),unexpected);assert.equal(e.api().snapshot().validationMismatches,1);
    e.api().resetCounters();e.api().setEnabled(true);gl.override=undefined;const next=fence(gl);
    assert.equal(gl.getSyncParameter(next,STATUS),UNSIGNALED);assert.equal(gl.calls,2);
    assert.equal(e.api().snapshot().failed,true);assert.equal(e.api().snapshot().hits,0);
  }
});
test('pending native errors are neither consumed nor rewritten on a hit',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);const s=fence(gl);gl.error=1280;
  assert.equal(gl.getSyncParameter(s,STATUS),UNSIGNALED);assert.equal(gl.getError(),1280);
});
test('native required-argument validation remains intact',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);
  assert.throws(()=>gl.fenceSync(),TypeError);assert.throws(()=>gl.getSyncParameter(),TypeError);assert.throws(()=>gl.deleteSync(),TypeError);
});
test('missing microtask capability installs no prototype changes',()=>{
  const e=environment({queue:false});assert.equal(e.api().snapshot().supported,false);
  assert.equal(e.GL.prototype.getSyncParameter,e.original.get);assert.equal(e.GL.prototype.fenceSync,e.original.fence);
});
test('bounded trace samples, counter reset and expiry do not retain all syncs',()=>{
  const e=environment(),gl=new e.GL();for(let i=0;i<40;i++){const s=fence(gl);gl.getSyncParameter(s,STATUS);gl.deleteSync(s);}
  assert.equal(e.api().snapshot().nativeFreshSamples.length,8);assert.equal(e.pending.length,1);
  e.api().resetCounters();assert.equal(e.api().snapshot().checks,0);e.checkpoint();assert.equal(e.api().snapshot().clearBatches,1);
});
test('uninstall restores natives and removes lifecycle listeners',()=>{
  const e=environment(),gl=new e.GL();e.api().setEnabled(true);const s=fence(gl);e.api().uninstall();
  assert.equal(e.GL.prototype.getSyncParameter,e.original.get);assert.equal(e.GL.prototype.fenceSync,e.original.fence);
  assert.equal(e.GL.prototype.deleteSync,e.original.del);assert.equal(gl.canvas.listeners.get('webglcontextlost').size,0);
  e.checkpoint();assert.equal(gl.getSyncParameter(s,STATUS),UNSIGNALED);assert.equal(gl.calls,1);
});
test('uninstall does not overwrite somebody else\'s later wrapper',()=>{
  const e=environment(),replacement=()=>0;e.GL.prototype.getSyncParameter=replacement;e.api().uninstall();
  assert.equal(e.GL.prototype.getSyncParameter,replacement);assert.equal(e.api().snapshot().uninstallConflicts,1);
});
process.stdout.write(JSON.stringify({passed, scope:'Independent task/lifecycle oracle; no browser-performance claim'})+'\n');
