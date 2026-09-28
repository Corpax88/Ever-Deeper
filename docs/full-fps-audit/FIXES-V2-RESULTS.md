# DEV15.17 candidate — revised CPU and audio fixes

Source: `21e415af523d497f6ec37706e42694b7f9c5302b`, branch `codex/fps-fixes-20260928`. Validation: run `36413947044`. Original is the exact nine-file DEV15.16 export from `0225855d5b243fadf75c5267898ac2cd6edb3d0b`, run `36380070907`.

## Production changes

| Change | Preserved behavior | Intended work reduction |
|---|---|---|
| Private fresh-pose ownership | Same sampled transforms, aiming, transitions, contact solving and public copy semantics; current stance runtime unchanged | Remove two redundant recursive pose copies in the private per-frame path |
| Exact music gain guard | Same requested and stored gain, crossfade formula and SFX; live property/bus edits invalidate | Avoid sending unchanged music gains through the engine and Web Audio every frame |
| Music position messages at 60 Hz | PCM buffer reuse, sample accumulation and playback graph; SFX original cadence | Reduce main-thread music position messages from roughly 375/s at 48 kHz to60/s |
| Per-search companion collision cache | Exact paths and fresh obstruction state between searches | Reuse collision answers within one synchronous search |

Music position freshness can lag by about one frame. The deterministic threshold fixture records 5–6 ms crossfade-trigger differences; position reporting is not bit-identical. The gain guard does preserve the exact stored values. These two audio changes must not be conflated.

The depth-prepass trial remains parked. The first-set FBO cache and contact pitch hoist are excluded after mixed/no gain and a measured contact regression. The new sync candidate is a read-only census only, removed before FPS measurements and absent from release. No visual assets, native rig, lights, quality, resolution, save identity or game rules are changed. The export still contains the original support resources; no unmeasured broad deletion was attempted.

## Validation and result

Both Mac WebKit26.5 jobs passed94 gates. Each retained21 exact native image pairs, with zero changed channels. The clean release PCK is262238744 bytes, SHA256 `be8aa8fc2ff2adf5726b6e8464415b7b6591f621b2c8e2e5b8ce5f69732b8f69`. Both worker build manifests match the local clean pack used for six passing gameplay/save cases. All original resource MD5 values were checked;1421 original entries remain byte-identical. No new QA scripts enter the clean release. Ordinary clean startup, new game, save reload and new-game confirmation pass with six actual screenshots. Independent visual review is recorded separately.

Exact motion checks cover680 sampled poses,11 aimed phases,15 mutation-isolation cases and public nested-copy contracts in each worker. Full-state replay covers364/237 real-input frames,327/209 mining/contour frames,11 impacts and two distinct valid mined resource IDs in each worker, with no clipping or parity differences. Both audio slots and both crossfade directions pass164 exact stored-value cases, and the fixture restores its initial state. Companion routes and obstacle add/remove replans remain exact.

| rAF measurement | Worker1 original → candidate | Worker2 original → candidate |
|---|---:|---:|
| Surface FPS |50.937 →52.371 (+2.82%)|50.526 →45.282 (−10.38%)|
| Mining FPS |40.186 →43.299 (+7.75%)|35.912 →39.637 (+10.37%)|
| Total weighted FPS |45.559 →47.835 (+5.00%)|43.219 →42.459 (−1.76%)|
| Total frames above33.33ms |112 →83|203 →178|
| Total frames above50ms |27 →23|44 →39|
| Overall p95 |34 →31ms|39 →39ms|
| Worst retained frame |88 →92ms|103 →101ms|

These are four fresh original/candidate pages per worker, ABBA/BAAB, each with12s surface and12s mining. Every window and interval is retained; no outlier was removed. Whole-game timing uses the original unwrapped browser engine against the complete production candidate. Startup observers and sync/gain census wrappers are removed before FPS windows. Timing varies substantially within workers, including baseline surface46.89→54.99 FPS in worker1. The two mining comparisons are encouraging; surface and total FPS are mixed. This is not an established general FPS or stutter fix.

The isolated full native advance benchmark is also mixed:580→497ms over6×364 packets (−14.31%, about38µs less per replay frame), but715→793ms over6×237 packets (+10.91%, about55µs more). Retain fresh-pose ownership only as verified allocation cleanup, not a demonstrated CPU speedup. For the current three-field pose shape, it removes two outer dictionaries, two bone dictionaries and one contacts dictionary per consumed fresh pose. It retains the same number of script calls and all tested ownership guarantees. No favorable rerun was sought.

During separate3s steady idle censuses, original pages made816/996 and906/828 AudioParam.value writes, of which768/936 and864/792 repeated the last value on that same parameter. All six candidate censuses made0 writes. This is an all-parameter census, not music-only attribution; production source changes only music gains. Music nodes acknowledge60Hz position reporting; first-set deterministic audio tests and the identical final JS/worklet bytes support playback/PCM/lifecycle preservation within their recorded latency limits. All2900 observed WebGL sync-status queries were stale, with zero eligible fresh queries; the sync candidate is excluded.

The unchanged protected-invariant script still has its pre-existing QA flag documentation assertion failure; this is not a passing invariant gate. PCK byte/resource preservation is a separate passing check. No phone, battery, heat or long-session acceptance is claimed.

Retain every measured window and outlier. Describe full-game FPS separately from the isolated native-motion CPU benchmark and separately from removed audio/property/collision work. Mac WebKit on Apple GPU is not physical iPhone Safari validation.
