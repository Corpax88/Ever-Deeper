// DEV opt-in recorder. No network while playing; private top-level receiver on Send.
(() => {
  const receiver = 'https://ever-deeper-spillrapporter.corpax88.chatgpt.site';
  let report = null, active = false, ready = false, db = null, popup = null, saved = false, storageError = false;
  try {
  const open = indexedDB.open('ever-deeper-reports-v1', 1);
  open.onupgradeneeded = () => open.result.createObjectStore('pending');
  open.onerror = () => { ready = true; storageError = true; };
  open.onsuccess = () => {
    db = open.result;
    const request = db.transaction('pending').objectStore('pending').get('last');
    request.onsuccess = () => {
      report = request.result || null; ready = true;
      // A receiver return link also works if Safari severs window.opener during sign-in.
      const receipt = location.hash.match(/^#report-received=([0-9a-f-]{36})$/)?.[1];
      if (receipt && report?.id === receipt) {report=null;saved=true;persist();}
      if (receipt) history.replaceState(null,'',location.pathname+location.search);
    };
    request.onerror = () => { ready = true; storageError = true; };
  };
  } catch { ready=true; storageError=true; }
  function persist() {
    if (!db) { storageError = true; return; }
    try {
      const tx = db.transaction('pending','readwrite');
      if (report) tx.objectStore('pending').put(report,'last'); else tx.objectStore('pending').delete('last');
      tx.onerror = () => { storageError = true; };
    } catch { storageError = true; }
  }
  function event(kind) {
    if (!active || !report || report.events.length >= 64) return;
    report.events.push({seconds:report.duration_s,kind});
    persist();
  }
  const api = {
    begin(version) {
      if (!ready || active || (report && !saved)) return false;
      const ua = navigator.userAgent;
      report = {schema:1,id:crypto.randomUUID(),version,started_at:new Date().toISOString(),duration_s:0,reason:'recording',
        device:{browser:/CriOS|Chrome/.test(ua)?'Chromium':/Firefox|FxiOS/.test(ua)?'Firefox':'Safari-WebKit',platform:/iPhone|iPad/.test(ua)?'iOS':/Mac/.test(ua)?'macOS':'Other',css_width:innerWidth,css_height:innerHeight,dpr:devicePixelRatio||1},samples:[],events:[]};
      active = true; saved = false; persist(); return true;
    },
    append(row) {
      if (!active || !report) return false;
      if (report.samples.length >= 120) { api.finish('window_limit'); return false; }
      const c = document.getElementById('canvas');
      report.samples.push({...row,canvas_width:c.width,canvas_height:c.height,dpr:devicePixelRatio||1});
      report.duration_s = row.seconds; persist(); return true;
    },
    finish(reason='stopped') { if (report) { report.reason=reason; active=false; persist(); } },
    send() {
      if (!report?.samples.length) return 'Record for a few seconds first';
      api.finish();
      const bytes = new TextEncoder().encode(JSON.stringify(report));
      if (bytes.length > 196608) return 'Report too large';
      let raw=''; for (const b of bytes) raw+=String.fromCharCode(b);
      const fragment=btoa(raw).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
      // Fragment stays in the browser, never in the HTTP request or server access log.
      popup=window.open(receiver+'/#report='+fragment,'ever-deeper-report');
      if (!popup) {
        document.getElementById('report-transfer-link')?.remove();
        const link=document.createElement('a'); link.id='report-transfer-link'; link.textContent='Send rapport';
        link.href=receiver+'/#report='+fragment; link.target='ever-deeper-report'; link.rel='opener';
        link.style.cssText='position:fixed;z-index:10000;bottom:16px;left:50%;transform:translateX(-50%);padding:16px 24px;background:#eab478;color:#101820;border-radius:10px;font:600 18px system-ui';
        link.addEventListener('click',e=>{
          popup=window.open(link.href,'ever-deeper-report');
          if(popup)e.preventDefault();
          setTimeout(()=>link.remove(),1000);
        }); document.body.append(link);
      }
      return popup ? 'Report opened - wait for receipt' : 'Tap the Send rapport link to finish';
    },
    clear() { if (active) return false; report=null; saved=false; persist(); return true; },
    status() { return {ready,active,saved,storage_error:storageError,pending:!!report,windows:report?.samples.length||0,seconds:report?.duration_s||0}; },
  };
  window.addEventListener('message', e => {
    if (e.origin !== receiver || e.source !== popup || !report) return;
    if (e.data?.type === 'ever-deeper-report-ready') popup.postMessage({type:'ever-deeper-report',report},receiver);
    if (e.data?.type === 'ever-deeper-report-saved' && e.data.id === report.id) { saved=true; active=false; report=null; persist(); }
  });
  document.addEventListener('visibilitychange', () => event(document.hidden?'hidden':'visible'));
  window.addEventListener('pagehide', () => event('pagehide'));
  window.addEventListener('resize', () => event('resize'));
  document.getElementById('canvas').addEventListener('webglcontextlost', () => {event('context_lost');api.finish('context_lost');});
  window.everDeeperReports=api;
})();
