# DEV15.18 diagnostic report: measurements and limits

Task: replace repeated inconclusive FPS reports with a bounded trace of actual runtime work. This is instrumentation, not an FPS fix or a guarantee of root-cause attribution.

## Exact scope

The clean candidate starts from DEV15.17 artifact 10967022774/run36413947044 (ZIP SHA256 3d344ce6e9bc24edc92257ecd8ac2ec6a731c364e24b2f50ce18fb427e4b8db4). The pack builder validates all file hashes and every PCK resource digest. Only the menu version string becomes15.18; the diagnostics live in the browser shell and one guarded main-loop hook in index.js. Game logic, audio playback, approved hero, graphics, lights, quality, saves and WASM remain unchanged. The parked depth-prepass is not enabled. LIVE and Worn are preserved by publication.

Same opt-in START REPORT / SEND REPORT flow. No network while playing. One pending local report,120 windows/10-minute engine limit, and a conservative190000-byte recording cutoff under the existing196608-byte transport limit. Backgrounding ends the capture. No temperatures, power mode, screenshots, saves or identity are collected. The private receiver accepts optional diagnostic data and remains backwards-compatible with reports from previous DEV versions.

## What each window means

`diagnostics.revision=2`. Stats tuples are `[count,mean,p95,max]`, in milliseconds except count. Null means no valid observation, never zero-cost work.

- `callback_ms`: wall time of the actual Emscripten/Godot main-loop iteration. Includes engine CPU, JavaScript, WebGL calls, driver waits and observer overhead. NOT pure CPU execution.
- `interval_ms`: start-to-start interval between engine iterations. `outside_ms`: interval from the previous iteration's measurement end to the next entry; includes browser scheduling, other tasks, composition and observer housekeeping. NOT a direct GPU or OS-throttle metric.
- `control_ms` vs `instrumented_ms`: regular frames versus one-in-thirty detailed frames. Controls retain the light collector and GL-wrapper branch, so this is not an uninstrumented baseline. Separate ABBA recording-off/on review measures session-level overhead.
- `seconds`: up to8 one-second bins per exported5-second window, `[second_since_record_start,frames,total_callback_ms,max_callback_ms,total_outside_ms,max_outside_ms]`. Bins may split at export boundaries; combine duplicate second indexes when plotting, summing totals/counts and taking maxima. Never compute FPS from the count of a partial bin alone.
- `worst`: four largest start-to-start intervals over25ms, `[current_start_since_record_ms,interval_ms,PREVIOUS_callback_ms,outside_ms,previous_frame_detailed_0_or_1,previous_GL_wall_ms]`. The preceding callback belongs to the interval; pairing with the current callback would misattribute stalls. A window can retain a previous callback from its boundary.
- `gl`: selected detailed-frame methods mapped to `[calls,total_wall_ms]`; draw, upload, state and synchronization methods. Return values and arguments pass unchanged. One frame in30 is sampled; no multiplication into claimed full-window GPU cost. No gl.finish/flush is added. Every installed GL wrapper is restored on stop.
- `gpu_ms`: asynchronous elapsed-query samples only when EXT_disjoint_timer_query_webgl2 is offered by this actual context. Pending queries capped at4, polled every15 iterations, discarded after2s, on disjoint, or when results belong to an earlier exported window. Existing active queries are skipped. Results are GPU command intervals, not complete screen-presentation time. Unsupported capability and invalid/missing results are explicit.
- `wasm_mib`: allocated WebAssembly linear-memory capacity, not live allocated objects or all browser memory. `js_heap_mib` is optional browser-reported JS heap and null on unsupported browsers. Neither establishes a leak alone.
- `audio`: current AudioContext state, retained sample-node/sample-buffer/position-worklet counts and optional base latency. These are snapshots of retained objects, not claims that all are currently playing or a measurement of audio CPU cost.
- `timer_lag_ms`: lateness of a250ms callback; `longtask_ms` and `long_animation_frame_ms` are optional supported PerformanceObserver entries. No script URLs or page contents are gathered. Absence of an unsupported observer says nothing about the absence of stalls.
- `persist_ms`: asynchronous IndexedDB transaction latency, NOT CPU time spent saving. `collector_ms` times diagnostic snapshot construction. Both remain observer-cost indicators, not a complete profiler.
- Capability flags, rejected/skipped GPU queries and collector errors accompany every window. The original Godot five-second rows remain unchanged.

Window boundaries: the Godot recorder exports inside a main-loop iteration, before that iteration completes. The browser trace therefore contains completed iterations through the previous callback; the boundary iteration is assigned to the next browser window. Do not claim frame-for-frame equality with Godot monitor sample counts. No GPU result is falsely assigned to a later window.

## Ten questions and how to read the result

| Question | Evidence and remaining limit |
|---|---|
| When does the drop begin? | One-second callback/gap bins and worst intervals, within existing world/activity windows. |
| Does engine work increase? | Actual main-loop wall time plus original process monitor. Neither alone is a CPU profile. |
| Does physics increase? | Existing physics mean by matched phase/activity; still no per-function physics attribution. |
| Is GPU execution growing? | Valid timer queries only if available; otherwise explicitly unresolved. |
| Is time lost outside engine work? | Outside intervals and timer lag; cannot label this automatically as throttling. |
| Does memory/retained state grow? | WASM capacity, optional JS heap, original nodes/video memory and audio counts; stable capacity does not rule out churn/GC. |
| What do light tests show? | Existing stage marks and light snapshots align with callback/GL changes; intervention is still required for causality. |
| Is pet/hero responsible? | Existing activity/context and prior isolation evidence; this collector does not invent per-component CPU attribution. |
| Is heat or power management responsible? | Not directly observable from these browser APIs; explicitly unsupported. |
| Is the measuring apparatus causing the drop? | Detailed/control frame stats, collector costs and the separate ABBA off/on review, with drift and outliers retained. |

Do not ask for another phone session until the candidate's real-game recording, transfer, restoration, missing-query path, limits and observer-cost evidence have passed. After publication, one ordinary2–3minute session is the requested next input. If the new trace still leaves CPU/GPU/scheduling ambiguous, state the exact missing measurement; do not repeat the same controls or promise that a report can reveal hidden OS internals.

## Validation

`check.mjs` tests deterministic separation of an injected64ms engine callback from an independent100ms outside gap, plus forwarding/restoration and valid/delayed/disjoint GPU lifecycle. `review.mjs` exercises real exported gameplay, both Chromium and Apple WebKit, recording, mining, reload recovery, protected pending report, full popup payload equality, receipt, restart and clear. `overhead.mjs` records all four8-second ABBA windows. `startup.mjs` exercises ordinary new/save/reload startup and captures actual images. No physical-iPhone performance acceptance is implied by these Mac checks.
