# Music registry ownership — completed 27 September 2026
## Result
Run 36314151070, source b2ee2f260162da826d3390fc6301f5b64e194448 on codex/music-registry-20260927 completed successfully. This is a lifetime diagnostic, not an FPS acceptance run or a release.

Two fresh Mac WebKit contexts rendered the actual immutable DEV15.10-based QA package at 2328x1260/DPR3 with Apple GPU. Six explicit music restarts, a switch to cached playback, then 15 seconds muted were observed per context. No forced GC or PCM reads.

| State | Legacy duplicate/copy registry | Cached/shared registry |
|---|---:|---:|
| Startup | 3 | 3 |
| After six restarts | 9 | 3 |
| Switch to cached | 9 | 3 |
| Muted 15 seconds | 9 | 3 |

Every legacy restart added a distinct sample ID and 31,634,872 bytes of decoded PCM retained by GodotAudio.samples. The six new IDs persisted through cached playback and mute: 189,809,232 extra registered PCM bytes. Weakly observed live buffers ended at 10 / 313,884,208 bytes in legacy versus 3 / 92,440,104 bytes in cached/shared. The extra tenth legacy buffer is not classified as registered retention; delayed GC may explain it.

This directly establishes strong registry retention during the measured lifetime, beyond the previous WeakRef-only evidence. It does not prove infinite leakage or the cause of physical iPhone FPS. Both contexts preload three prepared samples; absolute memory is NOT an untouched DEV15.10-versus-DEV15.11 comparison.

## Implication for previous FPS experiment
Both raw paired archives were recovered and SHA/size/CRC verified. Recomputed means agree: worker1 -0.1380099%, worker2 +4.6973411%. All 32 windows retained.
The previous same-context AB/BA sequence allowed legacy-created registered PCM to remain in later candidate windows. Its failed noninferiority decision stays failed; do not retroactively approve it or infer the direction/size of FPS bias from memory alone.
Do not repeat same-context toggling as a release test.

## Provenance and review
Artifact 10929309834 (music-registry-1), 8,721,792 bytes.
SHA256 532caa597370b39f2717e74c0592d50b800c96d6393dd0c189cf1238d324763f.
ZIP CRC verified. report.json and windows.json contain all 18 ownership snapshots and exact sample/buffer IDs.
Both actual images 0-original.png and 1-candidate.png inspected: same Emberdeep scene, hero/pet/lighting/HUD visible; animation phase differs. This is not pixel-parity or independent critic approval.
Public DEV15.10 unchanged. Clean production candidate remains ba396beeed9e587a8dc700edef7b28b79f1095d6 on codex/music-dev15-11-20260927; no new export needed.

## Next distinct step
A release comparison must use separate fresh browser processes for each original/candidate observation, the exact unmodified original audio path versus the clean candidate, identical fixture/viewport and balanced launch order. Verify browser children exit before the next observation. Never toggle legacy into a candidate process.
Predeclare sample count and stopping rule; retain the existing -2% noninferiority margin and all outliers. Disable unnecessary per-frame profiling equally. Measure startup/memory separately from warmed active mining and transition stalls. Keep prior lifecycle/core results; no repeat of unchanged matrices.
No physical-iPhone request or publication until evidence supports readiness.
