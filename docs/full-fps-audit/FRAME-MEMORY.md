# FPS round 2 — frame scheduling, synchronization, audio, and memory

2026-09-28. Read-only investigation. No game/runtime edits, CI runs, or publication by this agent.
Reference: immutable DEV15.16 `surface-probe-candidate`, run 36380070907, source 0225855d5b243fadf75c5267898ac2cd6edb3d0b. Exact baseline engine glue SHA256 `4cb9a7427e6528dd04c42bfad1433fd88ddd4f27e49450cced41694ee54cda7f`; extracted current source is `/workspace/scratch/4359e2537c52/baseline/sources`.

## New leads, ranked

### 1. Validate unchanged 3D backbuffer only after its attachments change

**Confirmed code cost, unconfirmed current bottleneck.** Earlier accepted render-profile evidence (`docs/performance-diagnosis/render-profile/evidence/report.json`, run 36111016427) measured one `checkFramebufferStatus` per rendered frame, about 0.44 ms of CPU/native-call wall time on that Mac. This is not GPU execution time, not current DEV15.16 cost, and not an iPhone prediction. Empty-canvas and shared-UI work reduced fence/sync pairs but retained this check.

Exact baseline engine glue directly calls `GLctx.checkFramebufferStatus(x0)`, without caching or suppression. Godot 4.7.2 source `drivers/gles3/storage/render_scene_buffers_gles3.cpp`, `check_backbuffer` (lines 463–544), allocates/attaches each missing color/depth texture conditionally, but unconditionally checks framebuffer completeness at line 535 even when both existing attachments remain unchanged. The caller in `drivers/gles3/rasterizer_scene_gles3.cpp:2881–2882` is reached when the native scene uses a screen or depth texture; it subsequently copies color/depth into that backbuffer. That provides a plausible source of both a synchronous validation and an otherwise hidden copy. It does **not** establish which current material causes it. The project's `native_surface.gdshader` itself requests neither screen nor depth textures.

**First experiment:** read-only attachment/lifetime trace on exact DEV15.16, first in surface idle, then hub and active mining, using `frame-memory-fbo-trace.js`. Install before engine startup; preserve all native calls. Capture actual target, FBO, return status, attachment identities and dimensions, mutation versions, call stack, and count of checks with unchanged configuration. Do not combine instrumented timing with normal FPS timing. If repeated checks point at changing textures, a different FBO, or startup allocations, the narrow hypothesis is falsified.

**Safe candidate shape if identity is confirmed:** change only the owning engine function so completeness is checked after it creates/re-attaches a color/depth attachment. Keep all startup/allocation checks and failure cleanup. Reset on render-buffer reconfiguration (the engine's `configure` calls `free_render_buffer_data`, which clears the backbuffer) and context recreation. Do not replace every `checkFramebufferStatus` with `FRAMEBUFFER_COMPLETE`, and do not ship a generic JavaScript cache based only on this trace. A real generic cache would also need complete accounting for texture/renderbuffer storage changes, attachment changes/deletion, read/draw buffers, relevant texture mip-level state, extensions, resize, and context loss. The supplied trace intentionally is **not** that cache.

**Gate:** show the target check disappears only while its exact configuration is stable; retain real checks on startup, resize/DPR change, hero/tool/menu/world lifecycle, and context recreation. Require exact full images plus control/candidate/control actual engine-frame windows with no profiler wrappers. Engine rebuild complexity makes this a candidate to rank against simpler fixes, not an immediate blanket patch.

### 2. Audio position worklet messages are sent at audio-block frequency

**New candidate distinct from the already-shipped music PCM reuse.** Godot's `platform/web/js/libs/audio.position.worklet.js:49–58` sends a `position` message after every nonempty input quantum, for every active sample playback. Exact baseline `index.js` creates/borrows a position AudioWorkletNode for each sample and its MessagePort handler processes every message. Baseline `scripts/audio/audio_director.gd:260–276` forces SAMPLE playback for ten sound-effect voices and two music players. The only project `get_playback_position()` caller found is music crossfade polling at line 102.

At 48 kHz and 128-frame quanta, **theoretical** message volume is 375 messages/second for one active music stream, 750 during a crossfade, plus active effects. At 44.1 kHz it is about 344.5/second/stream. Actual WebKit block size, whether all nodes are processed, task cost, and frequency require measurement. This could create main-thread wakeups/temporary messages despite PCM sharing; no evidence yet that it explains the surface FPS loss.

**Identity verified:** root obtained the exact public `index.audio.position.worklet.js`. Independent `sha256sum` matched baseline manifest hash `be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8`, and direct inspection confirms a `position` postMessage after every nonempty quantum. Read-only message counter is supplied as `frame-memory-audio-trace.js`; it preserves cadence, original MessagePort handlers, and the audio graph. Root is integrating a separate observation window before performance timing; no cadence-changing experiment is requested for this run.

**Bounded experiment:** count messages received per active audio stream with music on (control), a QA-only bounded position-report cadence (60 Hz), and control restoration; leave sample buffers, audible graph, volume, playback speed, audio-block position accumulation, and reset handling unchanged. Use a separate diagnostic count window and uninstrumented FPS windows. Control/candidate must use identical audio-on state and music track position. Also test a music transition, mute/resume, app pause/resume, and overlapping mining/pickup effects. Record maximum position lag and exact audio playback duration; throttling reports necessarily allows a small crossfade polling delay, which must be disclosed/tested. Reject if task frequency is already low, actual FPS/slow-frame results do not improve, or audio lifecycle/crossfade changes audibly.

**Safer scope:** reduce reporting frequency, not sound quality or music; do not disable the worklet entirely, because music crossfades depend on its position. SFX-position reporting may be separately avoidable only after confirming engine internal lifecycle does not need it.

### 3. Repeated assignment of unchanged music volume

**Confirmed redundant work; probably small.** Current `audio_director.gd:99` writes the same `active.volume_db` on every non-crossfade frame. Godot `scene/audio/audio_stream_player.cpp:71–80` has no same-value early return: it allocates/builds a four-pair volume vector and calls into AudioServer for current playbacks. `_get_volume_vector` at lines 185 onward constructs the vector and converts dB each time. Startup, environment change, user volume change, track start, and crossfade completion already explicitly apply the current mix.

**Small bounded candidate:** skip this assignment when its desired volume is already current (or remove the recurring write after proving all legitimate mix-changing events still write). Leave per-frame interpolation inside the actual three-second crossfade intact. Measure CPU helper time and setter count; preserve audible gains, especially user volume changes and mute/unmute. This is not a credible stand-alone explanation of a 20-FPS loss without measurement.

**Do not overclaim:** the exact sample path through AudioServer can return early if the playback is absent from its ordinary playback list, so the source alone does not establish six WebAudio gain setters every rendered frame. That must be counted at runtime before claiming browser audio-call savings.

## Findings that should not become repeat candidates

- `origin/codex/frame-pacing-audit-20260928` already compares `Engine.max_fps` 60 versus 0 with actual engine-frame and external rAF windows. Do not repeat a simple cap toggle as a new finding.
- `origin/codex/backdrop-audit-20260928` already has the alpha-crop comparison; it is separate from the above synchronization/audio leads.
- Music PCM sharing is present in exact current `index.js` (`duration > 10` returns the existing buffer). Do not resell that fix. Short SFX still duplicate PCM, but their small sizes and voice/cooldown bounds make that lower priority than measuring position-message traffic.
- FrameMeter processes only while explicitly enabled, clears samples every two seconds, and keeps at most 60 history rows. The session recorder is opt-in, caps a window at 1,800 frame samples, writes at five-second boundaries, and stops after ten minutes/120 report rows. IndexedDB persists the entire growing report on each append; this may create periodic **recording-only** stalls but cannot explain an always-on idle FPS loss when recording is off. Verify recorder on/off before attributing reported stutters to the game itself.
- No unbounded always-on browser telemetry allocation or growth was established. Current `Performance` memory counters should not be equated to total Safari process/GPU memory.

## Profiler usage and limitations

`frame-memory-fbo-trace.js` passed `node --check`. Add it before engine startup. `FBO_AUDIT.begin('surface', true)` starts a bounded inventory and optional native-call wall timing; `FBO_AUDIT.end()` returns the inventory. `FBO_AUDIT.uninstall()` restores its wrappers for timing windows. Avoid layering with other GL wrappers and expecting arbitrary uninstall order to work.

The profiler never suppresses native calls, adds no GL status queries/readbacks, and groups at most 128 FBO/target/status identities. It tracks attempted API calls, not success of those mutations. Late injection and untracked extension attachment APIs prohibit treating its state as a production cache. Its timing has observer overhead and is never GPU elapsed time. No local Linux FPS claim, Mac result, or physical iPhone verification has been produced in this second-pass subtask.

`frame-memory-audio-trace.js` also passed `node --check`. Install before AudioWorkletNode creation; `AUDIO_POSITION_AUDIT.begin('surface_music')` / `.end()` returns per-position-node counts, message rates, context sample rate, and position resets. `.uninstall()` removes passive event listeners and restores the constructor. It does not throttle or otherwise change playback. Root will observe before deciding whether this candidate deserves a later test.

## Primary engine references

- https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/render_scene_buffers_gles3.cpp
- https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_scene_gles3.cpp
- https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/js/libs/audio.position.worklet.js
- https://github.com/godotengine/godot/blob/4.7.2-stable/scene/audio/audio_stream_player.cpp
- https://github.com/godotengine/godot/blob/4.7.2-stable/servers/audio/audio_server.cpp
- https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/audio_driver_web.cpp
- MDN WebGL best practices confirms `checkFramebufferStatus` can flush/round-trip: https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices . The project's own prior trace is the evidence for measured cost, not this general guidance.
