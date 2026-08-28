(function () {
'use strict';

if (window.__EVER_DEEPER_WTF_DIRECTOR__) return;
window.__EVER_DEEPER_WTF_DIRECTOR__ = true;

const STORAGE_KEY = 'ever_deeper_wtf_director_v1';
const root = document.createElement('div');
root.id = 'ed-wtf-root';
root.setAttribute('aria-hidden', 'true');
root.style.cssText = ['position:fixed','inset:0','z-index:70','pointer-events:none','overflow:hidden','font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif'].join(';');
document.body.appendChild(root);

const style = document.createElement('style');
style.textContent = `
#ed-wtf-root .ed-wtf-msg{position:absolute;max-width:min(72vw,520px);padding:9px 13px;border-radius:10px;background:rgba(3,7,5,.76);border:1px solid rgba(255,222,143,.28);color:rgba(255,244,216,.94);font-size:clamp(12px,1.7vw,17px);font-weight:700;letter-spacing:.04em;text-shadow:0 2px 5px #000;box-shadow:0 8px 28px rgba(0,0,0,.32);opacity:0;transform:translateY(6px);transition:opacity .22s ease,transform .22s ease}
#ed-wtf-root .ed-wtf-msg.show{opacity:1;transform:translateY(0)}
#ed-wtf-root .ed-wtf-whisper{position:absolute;color:rgba(255,240,202,.55);font-size:clamp(10px,1.25vw,13px);font-weight:650;letter-spacing:.12em;text-transform:uppercase;text-shadow:0 2px 5px #000;opacity:0;transition:opacity .5s ease}
#ed-wtf-root .ed-wtf-whisper.show{opacity:1}
#ed-wtf-root .ed-wtf-glint{position:absolute;width:7px;height:7px;border-radius:50%;background:#ffe37d;box-shadow:0 0 10px #ffd04f,0 0 24px rgba(255,198,55,.55);opacity:0;animation:edWtfGlint 1.5s ease both}
#ed-wtf-root .ed-wtf-eye{position:absolute;width:24px;height:13px;border-radius:60% 60% 55% 55%;background:rgba(238,217,163,.64);box-shadow:0 0 10px rgba(255,222,148,.34);opacity:0;animation:edWtfEye 2.4s ease both}
#ed-wtf-root .ed-wtf-eye:after{content:"";position:absolute;left:9px;top:3px;width:6px;height:6px;border-radius:50%;background:#101712}
#ed-wtf-root .ed-wtf-word{position:absolute;left:0;right:0;top:28%;text-align:center;color:rgba(255,238,190,.085);font-size:clamp(56px,15vw,150px);font-weight:950;letter-spacing:.06em;opacity:0;animation:edWtfWord 3s ease both}
#ed-wtf-root .ed-wtf-door{position:absolute;width:23px;height:38px;border:2px solid rgba(245,211,132,.48);border-bottom:0;border-radius:7px 7px 0 0;opacity:0;animation:edWtfEye 2.8s ease both}
#ed-wtf-root .ed-wtf-door:after{content:"";position:absolute;right:4px;top:18px;width:3px;height:3px;border-radius:50%;background:#f5d384}
#ed-wtf-root .ed-wtf-echo{position:absolute;width:34px;height:34px;margin:-17px;border:1px solid rgba(255,214,120,.46);border-radius:50%;opacity:0;animation:edWtfEcho 1.25s ease-out both}
#ed-wtf-root .ed-wtf-tint{position:absolute;inset:0;background:radial-gradient(circle at 50% 55%,transparent 30%,rgba(45,22,55,.17) 100%);opacity:0;transition:opacity 1.1s ease}
#ed-wtf-root .ed-wtf-tint.show{opacity:1}
@keyframes edWtfGlint{0%,100%{opacity:0;transform:scale(.35)}35%{opacity:.95;transform:scale(1)}65%{opacity:.45;transform:scale(.65)}}
@keyframes edWtfEye{0%,100%{opacity:0}25%,72%{opacity:.78}}
@keyframes edWtfWord{0%,100%{opacity:0;transform:scale(.98)}25%,72%{opacity:1;transform:scale(1)}}
@keyframes edWtfEcho{0%{opacity:.65;transform:scale(.25)}100%{opacity:0;transform:scale(2.3)}}
`;
document.head.appendChild(style);

let saved = { seen: {}, sessions: 0 };
try {
  const parsed = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
  if (parsed && typeof parsed === 'object') saved = Object.assign(saved, parsed);
} catch (_) {}
saved.sessions = (saved.sessions || 0) + 1;
persist();

const state = {
  start: performance.now(), lastActivity: performance.now(), taps: [], holds: [], points: [], downs: new Map(), fired: 0,
  nextAt: performance.now() + random(32000, 50000), recent: [], readyAt: 0
};

function persist() { try { localStorage.setItem(STORAGE_KEY, JSON.stringify(saved)); } catch (_) {} }
function random(a, b) { return a + Math.random() * (b - a); }
function gameReady() { return !!document.getElementById('canvas') && !document.getElementById('status') && document.visibilityState === 'visible' && window.innerWidth > window.innerHeight; }
function remember(name) { saved.seen[name] = (saved.seen[name] || 0) + 1; persist(); state.recent.push(name); if (state.recent.length > 5) state.recent.shift(); }
function profile() {
  const now = performance.now();
  const recent = state.taps.filter(t => now - t < 9000);
  const gaps = [];
  for (let i = 1; i < recent.length; i++) gaps.push(recent[i] - recent[i - 1]);
  const avgGap = gaps.length ? gaps.reduce((a,b)=>a+b,0)/gaps.length : 9999;
  const recentHolds = state.holds.slice(-8);
  const avgHold = recentHolds.length ? recentHolds.reduce((a,b)=>a+b,0)/recentHolds.length : 0;
  if (now - state.lastActivity > 8500) return 'idle';
  if (avgHold > 850) return 'holder';
  if (gaps.length >= 5 && avgGap < 330) return 'rapid';
  if (gaps.length >= 3 && avgGap < 700) return 'busy';
  return 'steady';
}
function add(node, ttl) { root.appendChild(node); if (ttl) setTimeout(() => node.remove(), ttl); return node; }
function message(text, where='bottom', ttl=2600) {
  const el = document.createElement('div'); el.className = 'ed-wtf-msg'; el.textContent = text;
  const x = where === 'left' ? 5 : where === 'right' ? 95 : 50;
  el.style.left = `${x}%`; el.style.bottom = where === 'top' ? 'auto' : 'max(22px, env(safe-area-inset-bottom, 0px))';
  if (where === 'top') el.style.top = 'max(18px, env(safe-area-inset-top, 0px))';
  el.style.transform = `translate(${x === 50 ? '-50%' : x > 50 ? '-100%' : '0'},6px)`;
  add(el, ttl + 400);
  requestAnimationFrame(() => { el.classList.add('show'); el.style.transform = `translate(${x === 50 ? '-50%' : x > 50 ? '-100%' : '0'},0)`; });
  setTimeout(() => el.classList.remove('show'), ttl);
}
function whisper(text, x=random(8,82), y=random(12,80), ttl=2300) {
  const el = document.createElement('div'); el.className = 'ed-wtf-whisper'; el.textContent = text; el.style.left = `${x}%`; el.style.top = `${y}%`;
  add(el, ttl + 700); requestAnimationFrame(()=>el.classList.add('show')); setTimeout(()=>el.classList.remove('show'), ttl);
}
function glints(count=6) { for (let i=0;i<count;i++) { const el=document.createElement('div'); el.className='ed-wtf-glint'; el.style.left=`${random(8,92)}%`; el.style.top=`${random(15,84)}%`; el.style.animationDelay=`${i*0.09}s`; add(el, 2200+i*100); } }
function eye(side) { const el=document.createElement('div'); el.className='ed-wtf-eye'; el.style.top=`${random(18,76)}%`; if (side==='right') el.style.right='5px'; else el.style.left='5px'; add(el,3000); }
function word(text) { const el=document.createElement('div'); el.className='ed-wtf-word'; el.textContent=text; add(el,3300); }
function door() { const el=document.createElement('div'); el.className='ed-wtf-door'; el.style.bottom=`${random(5,24)}%`; el.style.left=Math.random()<.5?'5px':'calc(100% - 30px)'; add(el,3200); }
function echoes() { state.points.slice(-5).forEach((p,i)=>{ const el=document.createElement('div');el.className='ed-wtf-echo'; el.style.left=`${p.x}px`;el.style.top=`${p.y}px`;el.style.animationDelay=`${i*0.09}s`;add(el,1600); }); }
function tint() { const el=document.createElement('div');el.className='ed-wtf-tint';add(el,3500); requestAnimationFrame(()=>el.classList.add('show')); setTimeout(()=>el.classList.remove('show'),2200); }
function temporaryTitle(text) { const old=document.title; document.title=text; setTimeout(()=>{document.title=old;},2800); }
function fakeCounter() {
  let n = 3; const el=document.createElement('div');el.className='ed-wtf-msg';el.style.left='50%';el.style.top='18%';el.style.transform='translate(-50%,0)';el.textContent=String(n);add(el,3600);requestAnimationFrame(()=>el.classList.add('show'));
  const id=setInterval(()=>{n--; if(n>0) el.textContent=String(n); else {el.textContent='never mind.';clearInterval(id);}},620); setTimeout(()=>el.classList.remove('show'),3000);
}

const events = [
  {id:'notice1', profiles:['steady','busy'], run:()=>message('The mountain noticed that.', 'right')},
  {id:'notice2', profiles:['rapid'], run:()=>message('Easy. It has all day.', 'top')},
  {id:'notice3', profiles:['holder'], run:()=>message('Commitment detected.', 'left')},
  {id:'notice4', profiles:['idle'], run:()=>message('Nice break. Something kept moving.', 'top')},
  {id:'whisper1', profiles:['steady','busy'], run:()=>whisper('not a vein')},
  {id:'whisper2', profiles:['rapid','busy'], run:()=>whisper('too enthusiastic')},
  {id:'whisper3', profiles:['holder'], run:()=>whisper('still holding?')},
  {id:'glints', profiles:['steady','busy','holder'], run:()=>glints(7)},
  {id:'eye_left', profiles:['steady','idle'], run:()=>eye('left')},
  {id:'eye_right', profiles:['busy','rapid'], run:()=>eye('right')},
  {id:'word_deeper', profiles:['steady','holder'], run:()=>word('DEEPER?')},
  {id:'word_nope', profiles:['rapid'], run:()=>word('NOPE')},
  {id:'door', profiles:['steady','idle','holder'], run:()=>door()},
  {id:'echoes', profiles:['busy','rapid'], run:()=>echoes()},
  {id:'tint', profiles:['steady','idle'], run:()=>tint()},
  {id:'title', profiles:['steady','busy','holder'], run:()=>temporaryTitle('Ever Deeper — it noticed you')},
  {id:'fake_achievement', profiles:['steady','busy'], run:()=>message('ACHIEVEMENT: Definitely intentional.', 'top', 3200)},
  {id:'fake_pickup', profiles:['busy','rapid'], run:()=>message('Pocket lint +1', 'left', 1900)},
  {id:'inspection', profiles:['holder','steady'], run:()=>message('Safety inspection: failed successfully.', 'right', 3000)},
  {id:'coordinates', profiles:['steady','idle'], run:()=>message('X: probably   Y: down', 'left', 2200)},
  {id:'countdown', profiles:['rapid','busy'], run:()=>fakeCounter()},
  {id:'returning', profiles:['steady','busy','holder','idle'], onceSession:true, run:()=>message(saved.sessions > 1 ? 'It remembers this device.' : 'Nothing to worry about.', 'top', 2800)},
  {id:'note_below', profiles:['holder','steady'], run:()=>message('Note from below: keep digging. Probably.', 'right', 3200)},
  {id:'rhythm', profiles:['rapid','busy'], run:()=>message('You have a rhythm. That seems exploitable.', 'top', 3000)}
];

function chooseEvent(p) {
  let pool = events.filter(e => e.profiles.includes(p) && !state.recent.includes(e.id));
  if (!pool.length) pool = events.filter(e => !state.recent.includes(e.id));
  if (!pool.length) pool = events.slice();
  const weights = pool.map(e => { const seen = saved.seen[e.id] || 0; let w = 1 / (1 + seen * 0.8); if (e.profiles.includes(p)) w *= 2.2; if (e.onceSession && state.fired > 0) w *= 0.12; return w * random(.75,1.25); });
  let r=Math.random()*weights.reduce((a,b)=>a+b,0); for(let i=0;i<pool.length;i++){r-=weights[i];if(r<=0)return pool[i];} return pool[0];
}
function fire() {
  if (!gameReady()) { state.nextAt = performance.now() + 5000; return; }
  const p=profile(); const event=chooseEvent(p); if (!event) return; remember(event.id); state.fired++; try { event.run(); } catch (_) {}
  const base = p === 'rapid' ? random(42000,68000) : random(52000,92000); state.nextAt = performance.now() + base;
}

window.addEventListener('pointerdown', e => {
  if (!gameReady()) return; const now=performance.now(); state.lastActivity=now; state.taps.push(now); if(state.taps.length>40) state.taps.shift(); state.points.push({x:e.clientX,y:e.clientY,t:now}); if(state.points.length>12) state.points.shift(); state.downs.set(e.pointerId, now);
}, {capture:true, passive:true});
window.addEventListener('pointerup', e => {
  const start=state.downs.get(e.pointerId); if(start){state.holds.push(performance.now()-start);if(state.holds.length>16)state.holds.shift();state.downs.delete(e.pointerId);} state.lastActivity=performance.now();
}, {capture:true, passive:true});
window.addEventListener('pointercancel', e => state.downs.delete(e.pointerId), {capture:true, passive:true});

const tick=setInterval(()=>{
  if (!gameReady()) return; if (!state.readyAt) state.readyAt=performance.now(); const now=performance.now(); if(now-state.readyAt<18000) return; if(now>=state.nextAt) fire();
},1000);
window.addEventListener('pagehide',()=>clearInterval(tick),{once:true});
}());
