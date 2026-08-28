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
#ed-wtf-root .ed-wtf-msg{position:absolute;max-width:min(78vw,620px);padding:12px 17px;border-radius:12px;background:rgba(3,7,5,.93);border:2px solid rgba(255,222,143,.58);color:rgba(255,248,229,.99);font-size:clamp(15px,2.15vw,20px);font-weight:800;letter-spacing:.035em;line-height:1.3;text-shadow:0 2px 6px #000;box-shadow:0 10px 34px rgba(0,0,0,.68),0 0 20px rgba(255,214,120,.08);opacity:0;transform:translateY(8px);transition:opacity .28s ease,transform .28s ease}
#ed-wtf-root .ed-wtf-msg.show{opacity:1;transform:translateY(0)}
#ed-wtf-root .ed-wtf-whisper{position:absolute;color:rgba(255,244,216,.78);font-size:clamp(12px,1.55vw,16px);font-weight:750;letter-spacing:.12em;text-transform:uppercase;text-shadow:0 2px 6px #000,0 0 12px rgba(0,0,0,.8);opacity:0;transition:opacity .55s ease}
#ed-wtf-root .ed-wtf-whisper.show{opacity:1}
#ed-wtf-root .ed-wtf-glint{position:absolute;width:9px;height:9px;border-radius:50%;background:#ffe37d;box-shadow:0 0 12px #ffd04f,0 0 30px rgba(255,198,55,.68);opacity:0;animation:edWtfGlint 1.8s ease both}
#ed-wtf-root .ed-wtf-eye{position:absolute;width:28px;height:15px;border-radius:60% 60% 55% 55%;background:rgba(238,217,163,.76);box-shadow:0 0 14px rgba(255,222,148,.46);opacity:0;animation:edWtfEye 3.1s ease both}
#ed-wtf-root .ed-wtf-eye:after{content:"";position:absolute;left:10px;top:3px;width:7px;height:7px;border-radius:50%;background:#101712}
#ed-wtf-root .ed-wtf-word{position:absolute;left:0;right:0;top:27%;text-align:center;color:rgba(255,238,190,.14);font-size:clamp(64px,17vw,170px);font-weight:950;letter-spacing:.06em;opacity:0;animation:edWtfWord 4s ease both;text-shadow:0 2px 16px rgba(0,0,0,.35)}
#ed-wtf-root .ed-wtf-door{position:absolute;width:27px;height:44px;border:2px solid rgba(245,211,132,.68);border-bottom:0;border-radius:7px 7px 0 0;opacity:0;animation:edWtfEye 3.5s ease both;box-shadow:0 0 12px rgba(245,211,132,.12)}
#ed-wtf-root .ed-wtf-door:after{content:"";position:absolute;right:4px;top:21px;width:4px;height:4px;border-radius:50%;background:#f5d384}
#ed-wtf-root .ed-wtf-echo{position:absolute;width:38px;height:38px;margin:-19px;border:2px solid rgba(255,214,120,.55);border-radius:50%;opacity:0;animation:edWtfEcho 1.55s ease-out both}
#ed-wtf-root .ed-wtf-tint{position:absolute;inset:0;background:radial-gradient(circle at 50% 55%,transparent 28%,rgba(45,22,55,.24) 100%);opacity:0;transition:opacity 1.1s ease}
#ed-wtf-root .ed-wtf-tint.show{opacity:1}
@keyframes edWtfGlint{0%,100%{opacity:0;transform:scale(.35)}35%{opacity:1;transform:scale(1.1)}68%{opacity:.62;transform:scale(.72)}}
@keyframes edWtfEye{0%,100%{opacity:0}20%,78%{opacity:.9}}
@keyframes edWtfWord{0%,100%{opacity:0;transform:scale(.98)}22%,76%{opacity:1;transform:scale(1)}}
@keyframes edWtfEcho{0%{opacity:.78;transform:scale(.25)}100%{opacity:0;transform:scale(2.5)}}
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
  nextAt: performance.now() + random(26000, 40000), recent: [], readyAt: 0
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
function message(text, where='bottom', ttl=4600) {
  ttl = Math.max(ttl, 4200);
  const el = document.createElement('div'); el.className = 'ed-wtf-msg'; el.textContent = text;
  const x = where === 'left' ? 5 : where === 'right' ? 95 : 50;
  el.style.left = `${x}%`; el.style.bottom = where === 'top' ? 'auto' : 'max(12vh, calc(env(safe-area-inset-bottom, 0px) + 58px))';
  if (where === 'top') el.style.top = 'max(10vh, calc(env(safe-area-inset-top, 0px) + 44px))';
  el.style.transform = `translate(${x === 50 ? '-50%' : x > 50 ? '-100%' : '0'},8px)`;
  add(el, ttl + 650);
  requestAnimationFrame(() => { el.classList.add('show'); el.style.transform = `translate(${x === 50 ? '-50%' : x > 50 ? '-100%' : '0'},0)`; });
  setTimeout(() => el.classList.remove('show'), ttl);
}
function whisper(text, x=random(10,78), y=random(18,72), ttl=3600) {
  ttl = Math.max(ttl, 3400);
  const el = document.createElement('div'); el.className = 'ed-wtf-whisper'; el.textContent = text; el.style.left = `${x}%`; el.style.top = `${y}%`;
  add(el, ttl + 850); requestAnimationFrame(()=>el.classList.add('show')); setTimeout(()=>el.classList.remove('show'), ttl);
}
function glints(count=6) { for (let i=0;i<count;i++) { const el=document.createElement('div'); el.className='ed-wtf-glint'; el.style.left=`${random(8,92)}%`; el.style.top=`${random(15,84)}%`; el.style.animationDelay=`${i*0.09}s`; add(el, 2700+i*100); } }
function eye(side) { const el=document.createElement('div'); el.className='ed-wtf-eye'; el.style.top=`${random(18,76)}%`; if (side==='right') el.style.right='7px'; else el.style.left='7px'; add(el,3800); }
function word(text) { const el=document.createElement('div'); el.className='ed-wtf-word'; el.textContent=text; add(el,4400); }
function door() { const el=document.createElement('div'); el.className='ed-wtf-door'; el.style.bottom=`${random(8,28)}%`; el.style.left=Math.random()<.5?'7px':'calc(100% - 34px)'; add(el,4100); }
function echoes() { state.points.slice(-5).forEach((p,i)=>{ const el=document.createElement('div');el.className='ed-wtf-echo'; el.style.left=`${p.x}px`;el.style.top=`${p.y}px`;el.style.animationDelay=`${i*0.09}s`;add(el,2000); }); }
function tint() { const el=document.createElement('div');el.className='ed-wtf-tint';add(el,4300); requestAnimationFrame(()=>el.classList.add('show')); setTimeout(()=>el.classList.remove('show'),3000); }
function temporaryTitle(text) { const old=document.title; document.title=text; setTimeout(()=>{document.title=old;},4200); }
function fakeCounter() {
  let n = 3; const el=document.createElement('div');el.className='ed-wtf-msg';el.style.left='50%';el.style.top='18%';el.style.transform='translate(-50%,0)';el.textContent=String(n);add(el,5000);requestAnimationFrame(()=>el.classList.add('show'));
  const id=setInterval(()=>{n--; if(n>0) el.textContent=String(n); else {el.textContent='never mind.';clearInterval(id);}},780); setTimeout(()=>el.classList.remove('show'),4400);
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
  {id:'fake_achievement', profiles:['steady','busy'], run:()=>message('ACHIEVEMENT: Definitely intentional.', 'top', 4600)},
  {id:'fake_pickup', profiles:['busy','rapid'], run:()=>message('Pocket lint +1', 'left', 4300)},
  {id:'inspection', profiles:['holder','steady'], run:()=>message('Safety inspection: failed successfully.', 'right', 4700)},
  {id:'coordinates', profiles:['steady','idle'], run:()=>message('X: probably   Y: down', 'left', 4300)},
  {id:'countdown', profiles:['rapid','busy'], run:()=>fakeCounter()},
  {id:'returning', profiles:['steady','busy','holder','idle'], onceSession:true, run:()=>message(saved.sessions > 1 ? 'It remembers this device.' : 'Nothing to worry about.', 'top', 4700)},
  {id:'note_below', profiles:['holder','steady'], run:()=>message('Note from below: keep digging. Probably.', 'right', 4900)},
  {id:'rhythm', profiles:['rapid','busy'], run:()=>message('You have a rhythm. That seems exploitable.', 'top', 4700)}
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
  const base = p === 'rapid' ? random(38000,60000) : random(46000,76000); state.nextAt = performance.now() + base;
}

window.addEventListener('pointerdown', e => {
  if (!gameReady()) return; const now=performance.now(); state.lastActivity=now; state.taps.push(now); if(state.taps.length>40) state.taps.shift(); state.points.push({x:e.clientX,y:e.clientY,t:now}); if(state.points.length>12) state.points.shift(); state.downs.set(e.pointerId, now);
}, {capture:true, passive:true});
window.addEventListener('pointerup', e => {
  const start=state.downs.get(e.pointerId); if(start){state.holds.push(performance.now()-start);if(state.holds.length>16)state.holds.shift();state.downs.delete(e.pointerId);} state.lastActivity=performance.now();
}, {capture:true, passive:true});
window.addEventListener('pointercancel', e => state.downs.delete(e.pointerId), {capture:true, passive:true});

const tick=setInterval(()=>{
  if (!gameReady()) return; if (!state.readyAt) state.readyAt=performance.now(); const now=performance.now(); if(now-state.readyAt<16000) return; if(now>=state.nextAt) fire();
},1000);
window.addEventListener('pagehide',()=>clearInterval(tick),{once:true});
}());
