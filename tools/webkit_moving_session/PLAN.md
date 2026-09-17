# Exact DEV11 WebKit: ownership finding and bounded measurement plan

Prepared 2026-09-17. Root subsequently authorized preparing, checkpointing and triggering this single isolated Mac session once its source/tree/ref are verified. No browser session had run when this preparation was written.

## What the retained evidence establishes

The native Mac sample is not a browser profile. Its 810/1179 main-thread blocked snapshots belong to Godot's bundled native ANGLE/Metal path. The actual exported package calls the browser's WebGL methods through Emscripten. Playwright's macOS launcher loads its own Playwright.app and WebKit frameworks.

The exact DEV11 Mac WebKit gameplay artifact (QA run 35186932201, source 8f5680defb9083bbe1e044d39a10612f2186e7f3) reports WebKit 26.5, Apple GPU, WebGL 2.0, CSS 848×390, DPR 2 and a 1696×780 drawing buffer. It passed 1265 functional checks. Its retained console, gameplay and browser receipts contain **no sustained frame-time samples**. Its video/functional QA does not establish a current Deep FPS failure or success.

Playwright 1.62.0 pins WebKit revision 2336 on macOS 15, upstream WebKit 343e13bf22dca9d0ec227801419aab0f9001a32f. At that source, ProvokingVertexHelper initializes its index pool with maximum zero; BufferPool's bounded-pool flush/wait is conditional on a maximum greater than zero. The complete Playwright bootstrap patch changes no ANGLE files. It also leaves the macOS GPU-process WebGL defaults intact. Godot's native ANGLE distribution applies the separate zero-to-ten pool patch. **The sampled native bounded-pool wait must not be assigned to this browser or used to justify another game optimization.**

Source ownership predicts WebProcess → remote WebGL IPC → GPUProcess work queue → WebKit ANGLE/Metal. WebChromeClient has a local-context fallback. Retained QA contains no process/binary-image trace, so actual process placement and loaded libraries still require runtime evidence. This is Playwright WebKit, not the installed Safari application or a physical iPhone.

## Exact package and existing metric limitations

Use the existing candidate artifact from QA run 35186932201, artifact 10481858878. Do not re-export.

| File | SHA256 |
|---|---|
| artifact-identity.json | 027b128fe5fa70d7814c0f0952ee06549f447afc9769426c3b5696c631579a7a |
| index.html | 64a64a8d4c516e8ad5a1892077ccad2068d72f251a518d1ef513360fb037324a |
| index.js | 33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba |
| index.wasm | fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0 |
| index.pck | 5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9 |

The shipped DEV FrameMeter stores two-second process-interval summaries/history in GDScript. It does not expose Engine.get_frames_drawn() or Engine.get_frames_per_second() through JavaScript. Its JS call only reads canvas dimensions. The shipped RenderProbe rejects endless play, locks the fixed lighting field, requests standing still and later performs light ablations; its browser helper returns only the last eight seconds. The existing render-probe-web.mjs uses Chromium, DPR 3 and a DEV9 version gate. None is a suitable unchanged Deep 60-second browser measurement.

Do not assume that preloading an external GDScript and passing --script works in this web template. Godot 4.7.2 SConstruct defaults disable_path_overrides to true; main.cpp clears script overrides when that build capability is absent. The current official web build script does not override that default, but no exact release build-command receipt was retained. Native editor-binary success does not establish web-template support. The proposed browser route uses shipped controls and needs no such override.

## One practical session to prepare

1. Use one isolated macos-15 runner with the locked Playwright 1.62.0 WebKit installation. Verify every candidate file against its artifact identity and retain browser executable/version, package-lock, host, architecture and WebKit installation metadata. Use ordinary WebKit launch defaults, headless mode as in retained Mac QA, CSS 848×390 and DPR 2. Use one fresh context and one game page. Keep normal audio, assets, effects, camera, frame cap and persistence; obtain a trusted initial interaction. No video, tracing, encoding, extra probe page or screenshots inside the timed window.

2. Start the ordinary DEV page without QA/graphics flags. Use its DEV menu to choose ENDLESS · LAYER 12; close the drawer. This invokes the same _dev_jump_endless(12) entry as the native route. Use a fresh isolated browser save; record its real generated world_seed rather than invent seed equivalence with native seed 4608. Wait for a persisted baseline save, then four seconds of ordinary warmup. Preserve the entry screenshot and source-derived UI action log. Before timing, require the stored save to report active endless depth 12 and normal approved loadout. A route/identity/save failure stops before timing.

3. Observe the exact package's stable Emscripten MainLoop_runner callback through a narrowly scoped requestAnimationFrame wrapper that forwards the original callback, arguments, return ID and cancellation behavior. Select it by its source-bound identity; fail if the expected engine callback is absent or ambiguous. Store chronological start timestamps and callback-return durations in bounded preallocated arrays. Do not serialize, poll, compute percentiles, take screenshots or wrap GL calls in the measured interval. This metric is **engine-loop callback cadence**, not automatically rendered/presented-frame FPS; the Emscripten runner can skip an iteration according to timing mode. Callback duration includes JavaScript/WASM and synchronous browser waits; it is not exclusive engine CPU or GPU time. Preserve raw arrays and callback identity.

4. Before and after the timed window only, perform a bounded one-callback draw census on the actual existing game WebGL context and then restore every original method. Require nonzero real draw submissions and the same 1696×780 context/buffer. Do not create another context, read pixels through GL during timing or leave per-draw wrappers installed. Original start/end screenshots and actual draw evidence establish non-vacuity, but do not turn callback counts into a per-frame presentation counter.

5. Through Playwright's real keyboard input, hold ArrowDown and Space for at least 60.000 monotonic seconds; these are the shipped move_down and mine actions. Record trusted key-down/up events. Produce full-session and chronological 0–30/30–60 second cadence/p95 summaries from raw observations after the window. No fixed-step clocks or render suppression. If callback cadence falls below 50/s, it establishes that the browser's engine loop misses that target; cadence at or above 50/s alone is not a rendered-50-FPS approval. Report stalls, visibility/focus/context-loss/resize events and the exact realized duration. Fail on interruptions or incomplete raw evidence.

6. If the 60-second cadence fails the target and process ownership is unambiguous, continue the same held-input play for a separately labelled diagnostic extension, bounded to 30 seconds. Use ordinary /usr/bin/sample once for the owned WebContent process and once for its owned GPU process, sequentially, each requesting 5 seconds at 5 ms. Record /usr/bin/time -l overhead and raw headers/stacks/binary images. Bind PIDs using browser-server child identity, before/after process inventory, process start time and executable/bundle paths; XPC reparenting means PPID alone is insufficient. Do not sample an arbitrary first matching process. If ownership or ordinary attachment is unavailable, retain that limitation and stop attribution; no sudo, flags, alternate attach method or second profile. No sample or symbolication overlaps the 60-second performance window. CPU stacks can identify browser/WASM/IPC/ANGLE waits, not exclusive GPU execution time.

7. Release both keys, wait for normal autosave synchronization, preserve the original final capture and read the isolated /userfs IndexedDB FILE_DATA save through a read-only transaction. Keep raw before/after save bytes and timestamps. Require the same seed, active endless state, a positive mined-resource and swing delta, and actual descent/progress (accounting for stream rebasing through persisted depth/anchor). No forced resource awards or scripted hit calls. Require no runtime/GL errors, explicit new harness completion receipt, all evidence closed/hashed, and graceful browser/server exit. The ordinary game has no native PREMIUM_SESSION_COMPLETE or externally accessible orphan/input-state counter: do not claim those native gates passed. Key-up events and settled post-run evidence are the available input-release checks.

## Limits and stop point

This is one browser baseline, with an optional post-measurement CPU-attribution extension. It is not an optimization A/B test. The route uses real shipped keyboard actions and the same Deep entry, but a recorded fresh seed and WebAudio mean it is not numerically interchangeable with the native Dummy-audio seed-4608 profile. The small loop observer has unquantified constant overhead; no gain can be claimed from it. A hosted Mac and desktop keyboard are not physical-iPhone heat, touch or Safari acceptance.

First prepare the isolated wrapper/workflow and source/metric parser checks. Root has authorized triggering once that exact preparation checkpoint is verified. If the shipped save cannot provide route proof, the expected callback is not identifiable, or ordinary process sampling cannot be attributed, retain the concrete limitation rather than modifying the PCK or weakening the label.

## Primary source bindings

Exact URLs and Git blob hashes are in webkit-source-bindings.json. Most relevant:
- [Playwright pinned browsers](https://github.com/microsoft/playwright/blob/v1.62.0/packages/playwright-core/browsers.json)
- [Playwright WebKit upstream revision](https://github.com/microsoft/playwright/blob/v1.62.0/browser_patches/webkit/UPSTREAM_CONFIG.sh)
- [Complete Playwright WebKit patch](https://github.com/microsoft/playwright/blob/v1.62.0/browser_patches/webkit/patches/bootstrap.diff)
- [WebKit index-pool constructor](https://github.com/WebKit/WebKit/blob/343e13bf22dca9d0ec227801419aab0f9001a32f/Source/ThirdParty/ANGLE/src/libANGLE/renderer/metal/ProvokingVertexHelper.mm)
- [WebKit bounded-pool branch](https://github.com/WebKit/WebKit/blob/343e13bf22dca9d0ec227801419aab0f9001a32f/Source/ThirdParty/ANGLE/src/libANGLE/renderer/metal/mtl_buffer_pool.mm)
- [WebKit WebGL process selection](https://github.com/WebKit/WebKit/blob/343e13bf22dca9d0ec227801419aab0f9001a32f/Source/WebKit/WebProcess/WebCoreSupport/WebChromeClient.cpp)
